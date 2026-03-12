import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/valley_provider.dart';
import '../models/valley_device.dart';
import '../widgets/position_indicator.dart';
import 'settings_screen.dart';

class ValleyDetailScreen extends StatelessWidget {
  final String deviceId;

  const ValleyDetailScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ValleyProvider>(
      builder: (context, provider, child) {
        final device = provider.getDevice(deviceId);
        if (device == null) return const Scaffold(body: Center(child: Text('Device not found')));

        return Scaffold(
          appBar: AppBar(
            title: Text(device.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(device: device),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Position Indicator
                PositionIndicator(angle: device.currentAngle),
                const SizedBox(height: 24),

                // Status Cards
                _buildStatusCard(device),
                const SizedBox(height: 16),

                // Control Panel
                _buildControlPanel(context, device, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(ValleyDevice device) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatusRow('Статус ESP32', device.isOnline ? 'Online' : 'Offline',
                device.isOnline ? Colors.green : Colors.red),
            const Divider(),
            _buildStatusRow('Статус мотора', device.motorRunning ? 'Работает' : 'Остановлен',
                device.motorRunning ? Colors.green : Colors.grey),
            const Divider(),
            _buildStatusRow('Направление', device.directionText,
                device.direction ? Colors.blue : Colors.orange),
            const Divider(),
            _buildStatusRow('Время работы', '${device.runtimeSeconds} сек', Colors.purple),
            const Divider(),
            _buildStatusRow('Давление', '${device.pressure.toStringAsFixed(1)} PSI', Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, ValleyDevice device, ValleyProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Управление',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: device.isOnline && !device.motorRunning
                        ? () => provider.sendCommand(device.id, 'START')
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('СТАРТ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: device.isOnline && device.motorRunning
                        ? () => provider.sendCommand(device.id, 'STOP')
                        : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('СТОП'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: device.isOnline
                    ? () => provider.sendCommand(device.id, 'CHANGE_DIRECTION')
                    : null,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('СМЕНА НАПРАВЛЕНИЯ'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}