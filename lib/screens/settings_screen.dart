import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/valley_device.dart';
import '../providers/valley_provider.dart';

class SettingsScreen extends StatefulWidget {
  final ValleyDevice device;

  const SettingsScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _startAngleController;
  late TextEditingController _rotationTimeController;

  @override
  void initState() {
    super.initState();
    _startAngleController = TextEditingController(text: widget.device.startAngle.toString());
    _rotationTimeController = TextEditingController(text: widget.device.rotationTimeMinutes.toString());
  }

  void _saveSettings() {
    final startAngle = double.tryParse(_startAngleController.text) ?? 220.0;
    final rotationTime = double.tryParse(_rotationTimeController.text) ?? 74.0;

    context.read<ValleyProvider>().updateCalibration(
      widget.device.id,
      startAngle,
      rotationTime,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки сохранены')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Калибровка'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Параметры калибровки',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _startAngleController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Начальный угол (градусы)',
                        hintText: 'Например: 220',
                        prefixIcon: const Icon(Icons.rotate_right),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _rotationTimeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Время одного оборота (минуты)',
                        hintText: 'Например: 74',
                        prefixIcon: const Icon(Icons.timer),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Эти параметры используются для расчета текущего положения стрелы.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Сохранить',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _startAngleController.dispose();
    _rotationTimeController.dispose();
    super.dispose();
  }
}