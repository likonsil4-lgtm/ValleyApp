import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/valley_provider.dart';
import '../models/valley_device.dart';
import 'settings_screen.dart';

class ValleyDetailScreen extends StatefulWidget {
  final String deviceId;

  const ValleyDetailScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<ValleyDetailScreen> createState() => _ValleyDetailScreenState();
}

class _ValleyDetailScreenState extends State<ValleyDetailScreen>
    with TickerProviderStateMixin {
  bool _isDarkTheme = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late final Color color = _isDarkTheme ? Colors.cyanAccent : Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkTheme ? _darkTheme : _lightTheme,
      child: Consumer<ValleyProvider>(
        builder: (context, provider, child) {
          final device = provider.getDevice(widget.deviceId);
          if (device == null) {
            return Scaffold(
              body: Container(
                decoration: _buildBackground(),
                child: const Center(
                  child: Text(
                    'Устройство не найдено',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: _buildAppBar(device),
            body: Container(
              decoration: _buildBackground(),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Position Indicator with Animation
                        _buildPositionIndicator(device),
                        const SizedBox(height: 24),
                        // Status Cards
                        _buildStatusCard(device),
                        const SizedBox(height: 20),
                        // Control Panel
                        _buildControlPanel(device, provider),
                        const SizedBox(height: 20),
                        // Quick Stats
                        _buildQuickStats(device),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _buildBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDarkTheme
            ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]
            : [const Color(0xFFf5f7fa), const Color(0xFFc3cfe2)],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ValleyDevice device) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (_isDarkTheme ? Colors.white : Colors.black).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: _isDarkTheme ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Column(
        children: [
          Text(
            device.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isDarkTheme ? Colors.white : Colors.black87,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: device.isOnline ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (device.isOnline ? Colors.green : Colors.red).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                device.isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 12,
                  color: _isDarkTheme ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _toggleTheme,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isDarkTheme ? Icons.wb_sunny : Icons.nightlight_round,
              key: ValueKey(_isDarkTheme),
              color: _isDarkTheme ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (_isDarkTheme ? Colors.cyanAccent : Colors.deepPurple).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.settings,
              color: _isDarkTheme ? Colors.cyanAccent : Colors.deepPurple,
            ),
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      SettingsScreen(device: device),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPositionIndicator(ValleyDevice device) {
    // Выбор картинки по ID
    final String imagePath = _getImageForDevice(device.id);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkTheme
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Положение стрелы',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDarkTheme ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Картинка в зависимости от ID
                ClipOval(
                  child: Image.asset(
                    imagePath,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback если картинки нет
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getFallbackColor(device.id),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            device.name,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 2. Полупрозрачный оверлей
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_isDarkTheme ? Colors.black : Colors.white)
                        .withOpacity(0.25),
                    border: Border.all(
                      color: device.isOnline
                          ? color.withOpacity(0.6)
                          : Colors.grey.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                ),

                // 3. Индикатор со стрелкой
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: _PositionPainter(
                      angle: device.currentAngle,
                      isDarkTheme: _isDarkTheme,
                      color: device.isOnline ? color : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Цифровое значение
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDarkTheme
                    ? [Colors.cyanAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.2)]
                    : [Colors.deepPurple.withOpacity(0.1), Colors.purpleAccent.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${device.currentAngle.toStringAsFixed(1)}°',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: device.isOnline ? color : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Метод выбора картинки по ID
  String _getImageForDevice(String deviceId) {
    switch (deviceId) {
      case 'valley_1':
        return 'assets/images/field_1.png';
      case 'valley_2':
        return 'assets/images/field_2.png';
      case 'valley_3':
        return 'assets/images/field_3.png';
      case 'valley_4':
        return 'assets/images/field_4.png';
      case 'valley_5':
        return 'assets/images/field_5.png';
      default:
        return 'assets/images/field_default.png';
    }
  }

// Цвета для fallback
  Color _getFallbackColor(String deviceId) {
    switch (deviceId) {
      case 'valley_1':
        return Colors.green.withOpacity(0.4);
      case 'valley_2':
        return Colors.blue.withOpacity(0.4);
      case 'valley_3':
        return Colors.orange.withOpacity(0.4);
      case 'valley_4':
        return Colors.purple.withOpacity(0.4);
      case 'valley_5':
        return Colors.teal.withOpacity(0.4);
      default:
        return Colors.grey.withOpacity(0.4);
    }
  }

  Widget _buildStatusCard(ValleyDevice device) {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkTheme
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _buildStatusTile(
              icon: Icons.memory,
              label: 'Статус ESP32',
              value: device.isOnline ? 'Online' : 'Offline',
              color: device.isOnline ? Colors.green : Colors.red,
              isActive: device.isOnline,
            ),
            _buildDivider(),
            _buildStatusTile(
              icon: Icons.settings_suggest,
              label: 'Статус мотора',
              value: device.motorRunning ? 'Работает' : 'Остановлен',
              color: device.motorRunning ? Colors.green : Colors.grey,
              isActive: device.motorRunning,
            ),
            _buildDivider(),
            _buildStatusTile(
              icon: Icons.sync_alt,
              label: 'Направление',
              value: device.directionText,
              color: device.direction ? Colors.blue : Colors.orange,
              isActive: true,
            ),
            _buildDivider(),
            _buildStatusTile(
              icon: Icons.timer,
              label: 'Время работы',
              value: '${device.runtimeSeconds} сек',
              color: Colors.purple,
              isActive: device.motorRunning,
            ),
            _buildDivider(),
            _buildStatusTile(
              icon: Icons.speed,
              label: 'Давление',
              value: '${device.pressure.toStringAsFixed(1)} PSI',
              color: Colors.teal,
              isActive: device.pressure > 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: _isDarkTheme ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
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

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: _isDarkTheme ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
    );
  }

  Widget _buildControlPanel(ValleyDevice device, ValleyProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkTheme
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gamepad,
                color: _isDarkTheme ? Colors.cyanAccent : Colors.deepPurple,
              ),
              const SizedBox(width: 12),
              Text(
                'Управление',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isDarkTheme ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  icon: Icons.play_arrow,
                  label: 'СТАРТ',
                  color: Colors.green,
                  onPressed: device.isOnline && !device.motorRunning
                      ? () => provider.sendCommand(device.id, 'START')
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildControlButton(
                  icon: Icons.stop,
                  label: 'СТОП',
                  color: Colors.red,
                  onPressed: device.isOnline && device.motorRunning
                      ? () => provider.sendCommand(device.id, 'STOP')
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildControlButton(
            icon: Icons.swap_horiz,
            label: 'СМЕНА НАПРАВЛЕНИЯ',
            color: _isDarkTheme ? Colors.cyanAccent : Colors.deepPurple,
            onPressed: device.isOnline
                ? () => provider.sendCommand(device.id, 'CHANGE_DIRECTION')
                : null,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    bool isFullWidth = false,
  }) {
    final isDisabled = onPressed == null;

    return Container(
      height: 56,
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isDisabled
            ? null
            : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        color: isDisabled ? Colors.grey.withOpacity(0.3) : null,
        boxShadow: isDisabled
            ? null
            : [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isDisabled ? Colors.grey : Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isDisabled ? Colors.grey : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(ValleyDevice device) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkTheme
              ? [Colors.cyanAccent.withOpacity(0.1), Colors.blueAccent.withOpacity(0.1)]
              : [Colors.deepPurple.withOpacity(0.1), Colors.purpleAccent.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStat(
            icon: Icons.rotate_right,
            value: '${(device.currentAngle / 360 * 100).toStringAsFixed(0)}%',
            label: 'Прогресс',
          ),
          _buildQuickStat(
            icon: Icons.schedule,
            value: '${(device.runtimeSeconds / 60).toStringAsFixed(1)}',
            label: 'Минут',
          ),
          _buildQuickStat(
            icon: Icons.trending_up,
            value: device.pressure > 0 ? 'OK' : '--',
            label: 'Давление',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: _isDarkTheme ? Colors.cyanAccent : Colors.deepPurple,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _isDarkTheme ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _isDarkTheme ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  ThemeData get _darkTheme => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    cardColor: Colors.white.withOpacity(0.1),
  );

  ThemeData get _lightTheme => ThemeData.light().copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    cardColor: Colors.white,
  );

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Custom Painter for Position Indicator
class _PositionPainter extends CustomPainter {
  final double angle;
  final bool isDarkTheme;
  final Color color;

  _PositionPainter({
    required this.angle,
    required this.isDarkTheme,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Рисуем только шкалу и стрелку, фон теперь от картинки

    // Тонкий круг шкалы
    final ringPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, ringPaint);

    // Мелкие метки каждые 30 градусов
    final markerPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 360; i += 30) {
      final radian = i * math.pi / 180;
      final start = Offset(
        center.dx + (radius - 8) * math.cos(radian),
        center.dy + (radius - 8) * math.sin(radian),
      );
      final end = Offset(
        center.dx + radius * math.cos(radian),
        center.dy + radius * math.sin(radian),
      );
      canvas.drawLine(start, end, markerPaint);
    }

    // Крупные метки каждые 90 градусов (0, 90, 180, 270)
    final tickPaint = Paint()
      ..color = color.withOpacity(0.9)
      ..strokeWidth = 2.5;

    for (int i = 0; i < 360; i += 90) {
      final radian = i * math.pi / 180;
      final start = Offset(
        center.dx + (radius - 15) * math.cos(radian),
        center.dy + (radius - 15) * math.sin(radian),
      );
      final end = Offset(
        center.dx + radius * math.cos(radian),
        center.dy + radius * math.sin(radian),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    // Подписи градусов (0, 90, 180, 270)
    final textStyle = TextStyle(
      color: color.withOpacity(0.8),
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final labels = ['0°', '90°', '180°', '270°'];
    for (int i = 0; i < 4; i++) {
      final radian = (i * 90) * math.pi / 180;
      final offset = Offset(
        center.dx + (radius - 25) * math.cos(radian),
        center.dy + (radius - 25) * math.sin(radian),
      );

      textPainter.text = TextSpan(
        text: labels[i],
        style: textStyle,
      );
      textPainter.layout();

      // Центрируем текст
      final textOffset = Offset(
        offset.dx - textPainter.width / 2,
        offset.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    }

    // Стрелка (полоска от центра)
    final needleRadian = (angle - 90) * math.pi / 180;
    final needleEnd = Offset(
      center.dx + (radius - 25) * math.cos(needleRadian),
      center.dy + (radius - 25) * math.sin(needleRadian),
    );

    // Тень стрелки
    final shadowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, shadowPaint);

    // Тело стрелки
    final needlePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);

    // Центральная точка с glow эффектом
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, glowPaint);

    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, centerPaint);

    // Внутренняя белая/черная точка
    final innerPaint = Paint()
      ..color = isDarkTheme ? Colors.white : Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}