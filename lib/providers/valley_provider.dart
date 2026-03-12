import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/valley_device.dart';
import '../services/mqtt_service.dart';

class ValleyProvider extends ChangeNotifier {
  final MqttService _mqttService = MqttService();
  final Map<String, ValleyDevice> _devices = {};
  StreamSubscription? _mqttSubscription;
  Timer? _statusCheckTimer;

  ValleyProvider() {
    _initializeDevices();
    _connectMqtt();
  }

  void _initializeDevices() {
    for (int i = 1; i <= 5; i++) {
      _devices['valley_$i'] = ValleyDevice(
        id: 'valley_$i',
        name: 'Valley $i',
      );
    }
  }

  List<ValleyDevice> get devices => _devices.values.toList();

  ValleyDevice? getDevice(String id) => _devices[id];

  Future<void> _connectMqtt() async {
    try {
      await _mqttService.connect();
      _mqttSubscription = _mqttService.messageStream.listen(_handleMessage);

      // Check device status every 30 seconds
      _statusCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _checkDeviceStatus();
      });
    } catch (e) {
      print('MQTT Connection Error: $e');
      // Retry connection after 5 seconds
      Future.delayed(const Duration(seconds: 5), _connectMqtt);
    }
  }

  void _handleMessage(Map<String, dynamic> data) {
    final topic = data['topic'] as String;
    final payload = data['payload'] as String;

    final parts = topic.split('/');
    if (parts.length < 3) return;

    final deviceId = parts[1];
    final subtopic = parts[2];

    if (!_devices.containsKey(deviceId)) return;

    final device = _devices[deviceId]!;

    switch (subtopic) {
      case 'online':
        _devices[deviceId] = device.copyWith(
          isOnline: payload == 'true',
          lastUpdate: DateTime.now(),
        );
        break;
      case 'pressure':
        _devices[deviceId] = device.copyWith(
          pressure: double.tryParse(payload) ?? 0.0,
          lastUpdate: DateTime.now(),
        );
        break;
      case 'motor_status':
        _devices[deviceId] = device.copyWith(
          motorRunning: payload == 'running',
          lastUpdate: DateTime.now(),
        );
        break;
      case 'direction':
        _devices[deviceId] = device.copyWith(
          direction: payload == 'clockwise',
          lastUpdate: DateTime.now(),
        );
        break;
      case 'runtime':
        _devices[deviceId] = device.copyWith(
          runtimeSeconds: int.tryParse(payload) ?? 0,
          lastUpdate: DateTime.now(),
        );
        break;
      case 'position':
        final angle = double.tryParse(payload) ?? 0.0;
        _devices[deviceId] = device.copyWith(
          currentAngle: angle,
          lastUpdate: DateTime.now(),
        );
        break;
    }

    notifyListeners();
  }

  void _checkDeviceStatus() {
    final now = DateTime.now();
    bool hasChanges = false;

    _devices.forEach((id, device) {
      if (device.lastUpdate != null) {
        final diff = now.difference(device.lastUpdate!).inSeconds;
        if (diff > 60 && device.isOnline) {
          _devices[id] = device.copyWith(isOnline: false);
          hasChanges = true;
        }
      }
    });

    if (hasChanges) notifyListeners();
  }

  void sendCommand(String deviceId, String command) {
    _mqttService.sendCommand(deviceId, command);
  }

  void updateCalibration(String deviceId, double startAngle, double rotationTime) {
    _mqttService.sendCalibration(deviceId, startAngle, rotationTime);
    _devices[deviceId] = _devices[deviceId]!.copyWith(
      startAngle: startAngle,
      rotationTimeMinutes: rotationTime,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _mqttSubscription?.cancel();
    _statusCheckTimer?.cancel();
    _mqttService.dispose();
    super.dispose();
  }
}