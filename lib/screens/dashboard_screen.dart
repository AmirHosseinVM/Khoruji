import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/server_config.dart';
import '../services/api_service.dart';
import '../services/vpn_service.dart';
import '../widgets/location_sheet.dart';
import 'login_screen.dart';

enum ConnState { idle, connecting, connected }

class DashboardScreen extends StatefulWidget {
  final String token;
  const DashboardScreen({super.key, required this.token});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const telegramUrl = 'https://t.me/your_channel'; // TODO: put your real channel

  PlanInfo _plan = const PlanInfo();
  List<ServerConfig> _servers = [];
  bool _loadingSub = true;
  String? _subError;

  bool _autoBest = true;
  ServerConfig? _selected;
  ServerConfig? _connectedServer;

  ConnState _state = ConnState.idle;
  V2RayStatus? _status;
  String? _ip;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    VpnService.onStatusChanged = _onVpnStatus;
    VpnService.init();
    _loadSub();
    // silent background refresh — nothing shown to the user, matches the
    // panel's own "keep the app's cached data fresh" expectation.
    _refreshTimer = Timer.periodic(const Duration(hours: 12), (_) => _loadSub(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _onVpnStatus(V2RayStatus status) {
    if (!mounted) return;
    setState(() {
      _status = status;
      final s = status.state.toUpperCase();
      if (s.contains('CONNECTED')) {
        _state = ConnState.connected;
        _fetchExitIp();
      } else if (s.contains('CONNECTING')) {
        _state = ConnState.connecting;
      } else {
        _state = ConnState.idle;
        _ip = null;
      }
    });
  }

  Future<void> _loadSub({bool silent = false}) async {
    if (!silent) setState(() { _loadingSub = true; _subError = null; });
    try {
      final raw = await ApiService.fetchRawSub(widget.token);
      final result = ApiService.parseSub(raw);
      if (!mounted) return;
      setState(() {
        _plan = result.plan;
        _servers = result.servers;
        _loadingSub = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'device_limit_reached' && !silent) {
        setState(() => _subError = 'این اشتراک روی حداکثر تعداد دستگاه مجاز فعال است');
      }
      if (!silent) setState(() => _loadingSub = false);
      // silent refresh failures are ignored on purpose — keep last known data
    } catch (_) {
      if (!silent) setState(() { _subError = 'دریافت اطلاعات ناموفق بود'; _loadingSub = false; });
    }
  }

  Future<void> _fetchExitIp() async {
    // Best-effort: read the exit IP through the local proxy the core just
    // opened (see the config's own inbounds: socks 10808 / http 10809).
    try {
      final client = HttpClient()
        ..findProxy = (uri) => 'PROXY 127.0.0.1:10809;';
      final req = await client.getUrl(Uri.parse('https://api.ipify.org')).timeout(const Duration(seconds: 6));
      final res = await req.close();
      final body = await res.transform(const SystemEncoding().decoder).join();
      if (mounted) setState(() => _ip = body.trim());
    } catch (_) {
      if (mounted) setState(() => _ip = null); // hide the IP box rather than show something wrong
    }
  }

  Future<void> _onConnectTap() async {
    if (_state != ConnState.idle) {
      await VpnService.disconnect();
      setState(() { _state = ConnState.idle; _ip = null; });
      return;
    }
    if (_servers.isEmpty) return;

    final granted = await VpnService.requestPermission();
    if (!granted) return;

    ServerConfig target;
    if (_autoBest) {
      setState(() => _state = ConnState.connecting);
      await Future.wait(_servers.map((s) async {
        s.pingMs = (await VpnService.getDelay(s))?.toDouble();
      }));
      _servers.sort((a, b) => (a.pingMs ?? 999999).compareTo(b.pingMs ?? 999999));
      target = _servers.first;
    } else {
      target = _selected ?? _servers.first;
    }

    setState(() { _connectedServer = target; _state = ConnState.connecting; });
    await VpnService.connect(target);
  }

  Future<void> _openLocationSheet() async {
    final result = await showLocationSheet(
      context,
      servers: _servers,
      currentAutoBest: _autoBest,
      currentSelected: _selected,
    );
    if (result == null) return;
    setState(() {
      _autoBest = result.autoBest;
      _selected = result.server;
    });
  }

  Future<void> _logout() async {
    if (_state != ConnState.idle) await VpnService.disconnect();
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _fmtSpeed(int? bytesPerSec) {
    if (bytesPerSec == null) return '0.0';
    return (bytesPerSec / (1024 * 1024)).toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final locationName = _autoBest
        ? 'بهترین سرور (خودکار)'
        : (_selected?.name ?? 'بهترین سرور (خودکار)');
    final locationFlag = _autoBest ? null : _selected?.flagCode;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _loadingSub
            ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
            : Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(onLogout: _logout, plan: _plan, telegramUrl: telegramUrl),
                    if (_subError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_subError!, style: const TextStyle(color: AppColors.red, fontSize: 10.5)),
                      ),
                    const SizedBox(height: 6),
                    _ConnectButton(state: _state, onTap: _onConnectTap),
                    const SizedBox(height: 22),
                    _StatsGrid(
                      downloadSpeed: _fmtSpeed(_status?.downloadSpeed),
                      uploadSpeed: _fmtSpeed(_status?.uploadSpeed),
                      days: _plan.daysText,
                      volume: _plan.volumeText,
                    ),
                    if (_state == ConnState.connected && _ip != null) ...[
                      const SizedBox(height: 8),
                      _IpBox(ip: _ip!),
                    ],
                    const Spacer(),
                    _LocationRow(
                      name: locationName,
                      flagCode: locationFlag,
                      isAuto: _autoBest,
                      onTap: _openLocationSheet,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onLogout;
  final PlanInfo plan;
  final String telegramUrl;
  const _TopBar({required this.onLogout, required this.plan, required this.telegramUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconChip(
          icon: Icons.send_rounded,
          color: const Color(0xFF29A9EB),
          onTap: () => launchUrl(Uri.parse(telegramUrl), mode: LaunchMode.externalApplication),
        ),
        Expanded(
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                child: const Text('OneSpeed',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const Text('SECURE · FAST · PRIVATE',
                  style: TextStyle(fontSize: 8, color: AppColors.muted2, letterSpacing: 1, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuButton<String>(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          icon: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.muted),
          ),
          itemBuilder: (ctx) => [
            _infoRow('پلن', plan.planName),
            _infoRow('روز باقی‌مانده', plan.daysText ?? '—'),
            _infoRow('حجم باقی‌مانده', plan.volumeText ?? '—'),
            _infoRow('تاریخ انقضا', plan.expiryDate ?? '—'),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(children: const [
                Icon(Icons.logout_rounded, size: 15, color: AppColors.red),
                SizedBox(width: 8),
                Text('خروج از سرویس', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700, fontSize: 11)),
              ]),
            ),
          ],
          onSelected: (v) { if (v == 'logout') onLogout(); },
        ),
      ],
    );
  }

  PopupMenuEntry<String> _infoRow(String k, String v) => PopupMenuItem(
        enabled: false,
        height: 34,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
            Text(v, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text)),
          ],
        ),
      );
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconChip({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  final ConnState state;
  final VoidCallback onTap;
  const _ConnectButton({required this.state, required this.onTap});

  String get _label => switch (state) {
        ConnState.idle => 'برای اتصال ضربه بزنید',
        ConnState.connecting => 'در حال اتصال...',
        ConnState.connected => 'متصل شد',
      };

  @override
  Widget build(BuildContext context) {
    final connected = state == ConnState.connected;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state == ConnState.connecting)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: SizedBox(width: 11, height: 11, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue)),
              ),
            Text(_label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: connected ? AppColors.aqua : AppColors.muted)),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: connected ? AppColors.brandGradient : null,
              color: connected ? null : AppColors.surface,
              border: Border.all(color: AppColors.line),
              boxShadow: connected
                  ? [BoxShadow(color: AppColors.aqua.withOpacity(.28), blurRadius: 26, offset: const Offset(0, 14))]
                  : [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 22, offset: const Offset(0, 12))],
            ),
            child: Icon(Icons.power_settings_new_rounded, size: 28,
                color: connected ? Colors.white : AppColors.muted),
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final String downloadSpeed, uploadSpeed;
  final String? days, volume;
  const _StatsGrid({required this.downloadSpeed, required this.uploadSpeed, this.days, this.volume});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _chip(Icons.arrow_downward_rounded, AppColors.blue, 'دانلود', '$downloadSpeed MB/s')),
          const SizedBox(width: 8),
          Expanded(child: _chip(Icons.arrow_upward_rounded, AppColors.aqua, 'آپلود', '$uploadSpeed MB/s')),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _chip(Icons.access_time_rounded, AppColors.blue, 'زمان', days ?? '—')),
          const SizedBox(width: 8),
          Expanded(child: _chip(Icons.storage_rounded, AppColors.aqua, 'حجم', volume ?? '—')),
        ]),
      ],
    );
  }

  Widget _chip(IconData icon, Color color, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
          ]),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _IpBox extends StatelessWidget {
  final String ip;
  const _IpBox({required this.ip});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line, style: BorderStyle.solid),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.aqua, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(ip, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
          const SizedBox(width: 6),
          const Text('· آی‌پی متصل', style: TextStyle(fontSize: 9, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final String name;
  final String? flagCode;
  final bool isAuto;
  final VoidCallback onTap;
  const _LocationRow({required this.name, required this.flagCode, required this.isAuto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: isAuto ? const Icon(Icons.bolt_rounded, size: 14, color: AppColors.blue) : flagWidget(flagCode),
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.muted2),
          ],
        ),
      ),
    );
  }
}
