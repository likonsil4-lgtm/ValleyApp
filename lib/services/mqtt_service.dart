import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:math';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  late MqttServerClient _client;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  // HiveMQ Cloud Configuration
  static const String _server = '03f3df8309314ebdaf9c2d78737996db.s1.eu.hivemq.cloud';
  static const int _port = 8883;
  static const String _username = 'Valley';
  static const String _password = '13042004qwW+';

  Future<void> connect() async {
    _reconnectAttempts = 0;
    await _connectInternal();
  }

  Future<void> _connectInternal() async {
    try {
      _client = MqttServerClient.withPort(
          _server,
          'flutter_client_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
          _port
      );

      _client.secure = true;
      _client.logging(on: false);
      _client.keepAlivePeriod = 60; // Увеличено до 60 секунд
      _client.autoReconnect = true; // Включен авто-реконнект
      _client.resubscribeOnAutoReconnect = true;
      _client.onDisconnected = _onDisconnected;
      _client.onConnected = _onConnected;
      _client.onSubscribed = _onSubscribed;
      _client.onAutoReconnect = _onAutoReconnect;
      _client.onAutoReconnected = _onAutoReconnected;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier('valley_app_${DateTime.now().millisecondsSinceEpoch}')
          .authenticateAs(_username, _password)
          .withWillTopic('willtopic')
          .withWillMessage('Client disconnected')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      _client.connectionMessage = connMessage;

      print('MQTT: Connecting...');
      await _client.connect();
    } on Exception catch (e) {
      print('MQTT Connection Exception: $e');
      _scheduleReconnect();
    }
  }

  void _subscribeToTopics() {
    // Subscribe to all valley topics with QoS 1
    for (int i = 1; i <= 5; i++) {
      final deviceId = 'valley_$i';
      _client.subscribe('valley/$deviceId/online', MqttQos.atLeastOnce);
      _client.subscribe('valley/$deviceId/pressure', MqttQos.atLeastOnce);
      _client.subscribe('valley/$deviceId/motor_status', MqttQos.atLeastOnce);
      _client.subscribe('valley/$deviceId/direction', MqttQos.atLeastOnce);
      _client.subscribe('valley/$deviceId/runtime', MqttQos.atLeastOnce);
      _client.subscribe('valley/$deviceId/position', MqttQos.atLeastOnce);
    }

    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      final topic = c[0].topic;

      _messageController.add({
        'topic': topic,
        'payload': payload,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    // Пинг каждые 20 секунд для поддержания соединения
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_isConnected) {
        _client.ping();
      }
    });
  }

  void _onConnected() {
    print('MQTT: Connected successfully');
    _isConnected = true;
    _reconnectAttempts = 0;
    _connectionController.add(true);
    _subscribeToTopics();
  }

  void _onDisconnected() {
    print('MQTT: Disconnected');
    _isConnected = false;
    _connectionController.add(false);
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  void _onAutoReconnect() {
    print('MQTT: Auto-reconnecting...');
  }

  void _onAutoReconnected() {
    print('MQTT: Auto-reconnected');
    _isConnected = true;
    _reconnectAttempts = 0;
    _connectionController.add(true);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = Duration(seconds: min(_reconnectAttempts * 2, 30));
      print('MQTT: Reconnecting in ${delay.inSeconds} seconds (attempt $_reconnectAttempts)');
      _reconnectTimer = Timer(delay, _connectInternal);
    } else {
      print('MQTT: Max reconnection attempts reached');
    }
  }

  void _onSubscribed(String topic) {
    print('MQTT: Subscribed to $topic');
  }

  void publish(String topic, String message, {bool retain = false}) {
    if (!_isConnected) {
      print('MQTT: Cannot publish, not connected');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    final result = _client.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: retain,
    );

    if (result == -1) {
      print('MQTT: Publish failed for $topic');
    }
  }

  void sendCommand(String deviceId, String command) {
    print('MQTT: Sending command $command to $deviceId');
    publish('valley/$deviceId/command', command, retain: false);
  }

  void sendCalibration(String deviceId, double startAngle, double rotationTime) {
    final data = jsonEncode({
      'startAngle': startAngle,
      'rotationTimeMinutes': rotationTime,
    });
    publish('valley/$deviceId/calibration', data, retain: true);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _client.disconnect();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}