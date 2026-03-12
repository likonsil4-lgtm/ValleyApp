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

  // КЛЮЧЕВОЕ: флаг блокировки старых сообщений
  bool _ignoreOldMessages = true;
  Timer? _ignoreTimer;

  ValleyProvider() {
    _initializeDevices();
    _connectMqtt();
  }

  void _initializeDevices() {
    for (int i = 1; i <= 5; i++) {
      final id = 'valley_$i';
      _devices[id] = ValleyDevice(
        id: id,
        name: 'Valley $i',
        isOnline: false, // Явно false!
      );
      // Устанавливаем время в далеком прошлом
      _lastUpdateTime[id] = DateTime(2000, 1, 1);
    }
  }

  List<ValleyDevice> get devices => _devices.values.toList();

  ValleyDevice? getDevice(String id) => _devices[id];

  Future<void> _connectMqtt() async {
    try {
      await _mqttService.connect();

      // БЛОКИРУЕМ все сообщения первые 3 секунды!
      _ignoreOldMessages = true;
      _ignoreTimer?.cancel();
      _ignoreTimer = Timer(const Duration(seconds: 3), () {
        _ignoreOldMessages = false;
        print('MQTT: Now accepting new messages');
      });

      _mqttSubscription = _mqttService.messageStream.listen(
        _handleMessage,
        onError: (error) => print('MQTT Stream Error: $error'),
      );

      _connectionSubscription = _mqttService.connectionStream.listen((connected) {
        if (connected && !_wasConnected) {
          print('MQTT: Reconnected, blocking old messages for 3s...');
          // При каждом переподключении снова блокируем!
          _ignoreOldMessages = true;
          _ignoreTimer?.cancel();
          _ignoreTimer = Timer(const Duration(seconds: 3), () {
            _ignoreOldMessages = false;
            print('MQTT: Now accepting new messages');
          });

          // Сбрасываем все в offline при переподключении
          _devices.forEach((id, device) {
            _devices[id] = device.copyWith(isOnline: false);
            _lastUpdateTime[id] = DateTime(2000, 1, 1);
          });
          notifyListeners();
        }
        _wasConnected = connected;
      });

      _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _checkDeviceStatus();
      });

    } catch (e) {
      print('MQTT Connection Error: $e');
    }
  }

  void _handleMessage(Map<String, dynamic> data) {
    // ИГНОРИРУЕМ если флаг установлен (первые 3 сек после подключения)
    if (_ignoreOldMessages) {
      print('MQTT: Ignoring message (blocking period): ${data['topic']}');
      return;
    }

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
        final isOnline = payload == 'true';
        _updateDevice(deviceId, isOnline: isOnline);
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
    _ignoreTimer?.cancel();
    _mqttService.dispose();
    super.dispose();
  }
}