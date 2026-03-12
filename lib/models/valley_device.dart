import 'dart:convert';

class ValleyDevice {
  final String id;
  final String name;
  bool isOnline;
  bool motorRunning;
  bool direction; // true = clockwise (left), false = counter-clockwise (right)
  double pressure;
  int runtimeSeconds;
  double currentAngle;
  double startAngle;
  double rotationTimeMinutes;
  DateTime? lastUpdate;

  ValleyDevice({
    required this.id,
    required this.name,
    this.isOnline = false,
    this.motorRunning = false,
    this.direction = true,
    this.pressure = 0.0,
    this.runtimeSeconds = 0,
    this.currentAngle = 0.0,
    this.startAngle = 220.0,
    this.rotationTimeMinutes = 74.0,
    this.lastUpdate,
  });

  String get directionText => direction ? 'По часовой' : 'Против часовой';

  String get statusText {
    if (!isOnline) return 'Offline';
    if (motorRunning) return 'Работает';
    return 'Остановлен';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startAngle': startAngle,
    'rotationTimeMinutes': rotationTimeMinutes,
  };

  factory ValleyDevice.fromJson(Map<String, dynamic> json) => ValleyDevice(
    id: json['id'],
    name: json['name'],
    isOnline: false,
    startAngle: json['startAngle'] ?? 220.0,
    rotationTimeMinutes: json['rotationTimeMinutes'] ?? 74.0,
  );

  ValleyDevice copyWith({
    String? id,
    String? name,
    bool? isOnline,
    bool? motorRunning,
    bool? direction,
    double? pressure,
    int? runtimeSeconds,
    double? currentAngle,
    double? startAngle,
    double? rotationTimeMinutes,
    DateTime? lastUpdate,
  }) {
    return ValleyDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      isOnline: isOnline ?? this.isOnline,
      motorRunning: motorRunning ?? this.motorRunning,
      direction: direction ?? this.direction,
      pressure: pressure ?? this.pressure,
      runtimeSeconds: runtimeSeconds ?? this.runtimeSeconds,
      currentAngle: currentAngle ?? this.currentAngle,
      startAngle: startAngle ?? this.startAngle,
      rotationTimeMinutes: rotationTimeMinutes ?? this.rotationTimeMinutes,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}