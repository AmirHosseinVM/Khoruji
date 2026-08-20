import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import '../theme/app_theme.dart';
import '../models/server_config.dart';

class LocationSheetResult {
  final bool autoBest;
  final ServerConfig? server;
  LocationSheetResult({required this.autoBest, this.server});
}

Widget flagWidget(String? code, {double size = 22}) {
  if (code == null) {
    return Icon(Icons.public_rounded, size: size, color: AppColors.blue);
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: CountryFlag.fromCountryCode(
      code.toUpperCase(),
      height: size,
      width: size,
      shape: const RoundedRectangle(4),
    ),
  );
}

Future<LocationSheetResult?> showLocationSheet(
  BuildContext context, {
  required List<ServerConfig> servers,
  required bool currentAutoBest,
  required ServerConfig? currentSelected,
  required Future<int?> Function(ServerConfig) onPingRequest,
}) {
  return showModalBottomSheet<LocationSheetResult>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    isScrollControlled: true,
    builder: (ctx) {
      bool autoBest = currentAutoBest;
      ServerConfig? selected = currentSelected;
      return StatefulBuilder(builder: (ctx, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('انتخاب لوکیشن', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setSheetState(() { autoBest = true; selected = null; }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.blue.withOpacity(.08), AppColors.aqua.withOpacity(.08)
                    ]),
                    border: Border.all(
                      color: autoBest ? AppColors.aqua : AppColors.aqua.withOpacity(.3),
                      width: autoBest ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: AppColors.aqua, size: 18),
                      const SizedBox(width: 9),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('اتصال به بهترین سرور', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            Text('انتخاب خودکار بر اساس کمترین پینگ واقعی',
                                style: TextStyle(fontSize: 9.5, color: AppColors.aqua, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: servers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final s = servers[i];
                    final isSel = !autoBest && selected == s;
                    return GestureDetector(
                      onTap: () => setSheetState(() { autoBest = false; selected = s; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.blue.withOpacity(.05) : null,
                          border: Border.all(color: isSel ? AppColors.blue : Colors.transparent),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            flagWidget(s.flagCode),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(s.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                            GestureDetector(
                              onTap: () async {
                                if (s.pinging) return;
                                setSheetState(() => s.pinging = true);
                                final ms = await onPingRequest(s);
                                s.pingMs = ms?.toDouble();
                                if (ctx.mounted) setSheetState(() => s.pinging = false);
                              },
                              child: _PingBadge(server: s),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx, LocationSheetResult(autoBest: autoBest, server: selected)),
                  child: const Text('تغییر لوکیشن', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                ),
              ),
            ],
          ),
        );
      });
    },
  );
}

/// Shows real ping only once measured (parent screen fills in server.pingMs);
/// never shows protocol/encryption — just latency.
class _PingBadge extends StatelessWidget {
  final ServerConfig server;
  const _PingBadge({required this.server});

  @override
  Widget build(BuildContext context) {
    if (server.pinging) {
      return const SizedBox(
        width: 14, height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue),
      );
    }
    final ms = server.pingMs;
    String text;
    Color color;
    Color bg;
    if (ms == null) {
      text = '--';
      color = AppColors.muted2;
      bg = AppColors.surface2;
    } else if (ms < 150) {
      text = '${ms.round()}ms';
      color = AppColors.aqua;
      bg = AppColors.aqua.withOpacity(.12);
    } else {
      text = '${ms.round()}ms';
      color = AppColors.amber;
      bg = AppColors.amber.withOpacity(.12);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
