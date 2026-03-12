import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/valley_device.dart';
import '../services/mqtt_service.dart';

class ValleyProvider extends ChangeNotifier {
  final MqttService _mqttService = MqttService();
  final Map<String, ValleyDevice> _devices = {};
  final Map<String, DateTime> _lastUpdateTime = {};
  StreamSubscription? _mqttSubscription;
  StreamSubscription? _connectionSubscription;
  Timer? _statusCheckTimer;
  Timer? _connectionMonitorTimer;
  bool _wasConnected = false;

  ValleyProvider() {
    _initializeDevices();
    _connectMqtt();
  }

  void _initializeDevices() {
    for (int i = 1; i <= 5; i++) {
      final id = 'valley_$i';
      _devices[id] = ValleyDevice(id: id, name: 'Valley $i');
      _lastUpdateTime[id] = DateTime.now();
    }
  }

  List<ValleyDevice> get devices => _devices.values.toList();

  ValleyDevice? getDevice(String id) => _devices[id];

  Future<void> _connectMqtt() async {
    try {
      await _mqttService.connect();

      _mqttSubscription = _mqttService.messageStream.listen(
        _handleMessage,
        onError: (error) => print('MQTT Stream Error: $error'),
        onDone: () => print('MQTT Stream Done'),
      );

      _connectionSubscription = _mqttService.connectionStream.listen((connected) {
        if (connected && !_wasConnected) {
          print('MQTT: Connection restored, requesting updates...');
          // Запросить обновление статуса от всех устройств
          for (int i = 1; i <= 5; i++) {
            _mqttService.publish('valley/valley_$i/ping', 'request_status');
          }
        }
        _wasConnected = connected;
      });

      // Проверка статуса каждые 10 секунд (быстрее для отзывчивости)
      _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _checkDeviceStatus();
      });

      // Мониторинг соединения
      _connectionMonitorTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_mqttService.isConnected) {
          print('MQTT: Connection lost detected by monitor');
        }
      });

    } catch (e) {
      print('MQTT Connection Error: $e');
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

    _lastUpdateTime[deviceId] = DateTime.now();
    final device = _devices[deviceId]!;

    switch (subtopic) {
      case 'online':
        _updateDevice(deviceId, isOnline: payload == 'true');
        break;
      case 'pressure':
        final pressure = double.tryParse(payload) ?? 0.0;
        _updateDevice(deviceId, pressure: pressure);
        break;
      case 'motor_status':
        _updateDevice(deviceId, motorRunning: payload == 'running');
        break;
      case 'direction':
        _updateDevice(deviceId, direction: payload == 'clockwise');
        break;
      case 'runtime':
        final runtime = int.tryParse(payload) ?? 0;
        _updateDevice(deviceId, runtimeSeconds: runtime);
        break;
      case 'position':
        final angle = double.tryParse(payload) ?? 0.0;
        _updateDevice(deviceId, currentAngle: angle);
        break;
    }
  }

  void _updateDevice(String id, {
    bool? isOnline,
    bool? motorRunning,
    bool? direction,
    double? pressure,
    int? runtimeSeconds,
    double? currentAngle,
  }) {
    final device = _devices[id]!;
    _devices[id] = device.copyWith(
      isOnline: isOnline ?? device.isOnline,
      motorRunning: motorRunning ?? device.motorRunning,
      direction: direction ?? device.direction,
      pressure: pressure ?? device.pressure,
      runtimeSeconds: runtimeSeconds ?? device.runtimeSeconds,
      currentAngle: currentAngle ?? device.currentAngle,
      lastUpdate: DateTime.now(),
    );
    notifyListeners();
  }

  void _checkDeviceStatus() {
    final now = DateTime.now();
    bool hasChanges = false;

    _devices.forEach((id, device) {
      final lastUpdate = _lastUpdateTime[id];
      if (lastUpdate != null) {
        final diff = now.difference(lastUpdate).inSeconds;
        // Если нет обновлений более 30 секунд - считаем offline
        if (diff > 30 && device.isOnline) {
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
    final device = _devices[deviceId]!;
    _devices[deviceId] = device.copyWith(
      startAngle: startAngle,
      rotationTimeMinutes: rotationTime,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _mqttSubscription?.cancel();
    _connectionSubscription?.cancel();
    _statusCheckTimer?.cancel();
    _connectionMonitorTimer?.cancel();
    _mqttService.dispose();
    super.dispose();
  }
}