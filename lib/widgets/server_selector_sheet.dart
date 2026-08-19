import 'package:flutter/material.dart';
import '../models/server_config.dart';
import '../services/vpn_service.dart';

class ServerSelectorSheet extends StatefulWidget {
  final List<ServerConfig> servers;
  final ServerConfig? selectedServer;
  final Function(ServerConfig) onSelect;

  const ServerSelectorSheet({
    Key? key,
    required this.servers,
    required this.selectedServer,
    required this.onSelect,
  }) : super(key: key);

  @override
  State<ServerSelectorSheet> createState() => _ServerSelectorSheetState();
}

class _ServerSelectorSheetState extends State<ServerSelectorSheet> {
  bool _isPingingAll = false;

  Future<void> _pingAllServers() async {
    setState(() => _isPingingAll = true);
    for (var server in widget.servers) {
      if (server.port == 1) continue;
      final delay = await VpnService.getDelay(server);
      if (mounted) {
        setState(() {
          server.pingMs = delay > 0 ? delay.toDouble() : -1;
        });
      }
    }
    if (mounted) {
      setState(() => _isPingingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.65,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'انتخاب سرور / لوکیشن',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _isPingingAll ? null : _pingAllServers,
                icon: _isPingingAll
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.speed, size: 18),
                label: Text(_isPingingAll ? 'در حال تست...' : 'بررسی پینگ'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: widget.servers.length,
              itemBuilder: (context, index) {
                final server = widget.servers[index];
                if (server.port == 1) return const SizedBox.shrink();

                final isSelected = widget.selectedServer?.address == server.address &&
                    widget.selectedServer?.port == server.port;

                return ListTile(
                  leading: Icon(
                    Icons.dns,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  title: Text(server.name),
                  subtitle: Text('${server.address}:${server.port}'),
                  trailing: Text(
                    server.pingMs == null
                        ? '-- ms'
                        : (server.pingMs! < 0 ? 'خطا' : '${server.pingMs!.toInt()} ms'),
                    style: TextStyle(
                      color: server.pingMs == null || server.pingMs! < 0
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    widget.onSelect(server);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
