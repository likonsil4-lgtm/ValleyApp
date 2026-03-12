import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

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

  // HiveMQ Cloud Configuration
  static const String _server = '03f3df8309314ebdaf9c2d78737996db.s1.eu.hivemq.cloud';
  static const int _port = 8883;
  static const String _username = 'Valley';
  static const String _password = '13042004qwW+';

  Future<void> connect() async {
    _client = MqttServerClient.withPort(_server, 'flutter_client_${DateTime.now().millisecondsSinceEpoch}', _port);

    _client.secure = true;
    _client.logging(on: false);
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;
    _client.onSubscribed = _onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('valley_app_${DateTime.now().millisecondsSinceEpoch}')
        .authenticateAs(_username, _password)
        .withWillTopic('willtopic')
        .withWillMessage('Client disconnected')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client.connectionMessage = connMessage;

    try {
      await _client.connect();
    } on Exception catch (e) {
      print('MQTT Connection Exception: $e');
      _client.disconnect();
      throw Exception('Failed to connect to MQTT broker');
    }

    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      _isConnected = true;
      _connectionController.add(true);
      _subscribeToTopics();
    } else {
      throw Exception('MQTT Connection failed');
    }
  }

  void _subscribeToTopics() {
    // Subscribe to all valley topics
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
      });
    });
  }

  void publish(String topic, String message) {
    if (!_isConnected) return;

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void sendCommand(String deviceId, String command) {
    publish('valley/$deviceId/command', command);
  }

  void sendCalibration(String deviceId, double startAngle, double rotationTime) {
    final data = jsonEncode({
      'startAngle': startAngle,
      'rotationTimeMinutes': rotationTime,
    });
    publish('valley/$deviceId/calibration', data);
  }

  void _onConnected() {
    print('MQTT Connected');
    _isConnected = true;
    _connectionController.add(true);
  }

  void _onDisconnected() {
    print('MQTT Disconnected');
    _isConnected = false;
    _connectionController.add(false);
  }

  void _onSubscribed(String topic) {
    print('Subscribed to: $topic');
  }

  void disconnect() {
    _client.disconnect();
    _isConnected = false;
  }

  void dispose() {
    _messageController.close();
    _connectionController.close();
  }
}