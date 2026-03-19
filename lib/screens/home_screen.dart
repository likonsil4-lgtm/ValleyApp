import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/valley_provider.dart';
import '../widgets/valley_card.dart';
import '../screens/valley_detail_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../models/valley_device.dart';
import 'dart:async';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isDarkTheme = true;
  late AnimationController _fabController;

  // Для двойного нажатия назад
  bool _backPressedOnce = false;
  Timer? _backPressTimer;
  bool _showExitToast = false;

  // Для долгого нажатия на valley на карте
  bool _isLongPressing = false;
  String? _longPressedDeviceId;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
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
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // Основной контент
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isDarkTheme
                        ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]
                        : [const Color(0xFFf5f7fa), const Color(0xFFc3cfe2)],
                  ),
                ),
                child: SafeArea(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader()),
                      SliverToBoxAdapter(child: _buildConnectionStatus()),

                      // ═══════════════════════════════════════════════════
                      // НОВОЕ: Карта местности с расположением Valley
                      // ═══════════════════════════════════════════════════
                      SliverToBoxAdapter(child: _buildMapSection()),

                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: Consumer<ValleyProvider>(
                          builder: (context, provider, child) {
                            final devices = provider.devices;
                            return SliverList(
                              delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                  return AnimatedBuilder(
                                    animation: _fabController,
                                    builder: (context, child) {
                                      return TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: Duration(milliseconds: 400 + (index * 100)),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) {
                                          return Transform.translate(
                                            offset: Offset(0, 50 * (1 - value)),
                                            child: Opacity(opacity: value, child: child),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 16),
                                          child: ValleyCard(
                                            device: devices[index],
                                            isDarkTheme: _isDarkTheme,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: devices.length,
                              ),
                            );
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
              ),

              // Toast уведомление внизу
              if (_showExitToast)
                Positioned(
                  bottom: 100,
                  left: 24,
                  right: 24,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isDarkTheme
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.exit_to_app,
                            color: Colors.white.withOpacity(0.9),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Нажмите ещё раз для выхода',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: _buildFloatingMenu(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // НОВЫЙ ВИДЖЕТ: Карта местности с Valley
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMapSection() {
    return Consumer<ValleyProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            height: 350, // ← ВЫСОТА КАРТЫ (можно менять)
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Фоновая картинка карты
                  Image.asset(
                    'assets/images/map_terrain.png', // ← ПУТЬ К КАРТЕ
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback если картинки нет
                      return Container(
                        color: _isDarkTheme ? const Color(0xFF1a2f3a) : const Color(0xFFe0e5ec),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 64,
                                color: _isDarkTheme ? Colors.white30 : Colors.black26,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Карта местности',
                                style: TextStyle(
                                  color: _isDarkTheme ? Colors.white.withOpacity(0.4) : Colors.black38,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Добавьте assets/images/map_terrain.png',
                                style: TextStyle(
                                  color: _isDarkTheme ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // 2. Полупрозрачный оверлей для читаемости
                  Container(
                    color: (_isDarkTheme ? Colors.black : Colors.white).withOpacity(0.1),
                  ),

                  // 3. Valley на карте
                  // ═══════════════════════════════════════════════════════════
                  // ЗДЕСЬ РАСПОЛАГАЮТСЯ VALLEY - координаты в процентах от размера!
                  // ═══════════════════════════════════════════════════════════

                  // Valley 1 - левый верхний угол
                  _buildValleyOnMap(
                    device: provider.getDevice('valley_1'),
                    left: 0.22,   // ← 15% от левого края (0.0 - 1.0)
                    top: 0.71,    // ← 20% от верхнего края (0.0 - 1.0)
                    size: 79,     // ← Размер круга в пикселях
                  ),

                  // Valley 2 - правый верхний угол
                  _buildValleyOnMap(
                    device: provider.getDevice('valley_2'),
                    left: 0.50,   // ← 75% от левого края
                    top: 0.67,    // ← 15% от верхнего края
                    size: 108,
                  ),

                  // Valley 3 - центр
                  _buildValleyOnMap(
                    device: provider.getDevice('valley_3'),
                    left: 0.83,   // ← Центр по горизонтали
                    top: 0.62,    // ← Центр по вертикали
                    size: 118,     // ← Чуть больше, центральный
                  ),

                  // Valley 4 - левый нижний
                  _buildValleyOnMap(
                    device: provider.getDevice('valley_4'),
                    left: 0.55,   // ← 20% от левого
                    top: 0.29,    // ← 75% от верхнего (ниже)
                    size: 81,
                  ),

                  // Valley 5 - правый нижний
                  _buildValleyOnMap(
                    device: provider.getDevice('valley_5'),
                    left: 0.79,   // ← 80% от левого
                    top: 0.23,    // ← 70% от верхнего
                    size: 75,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Виджет Valley на карте
  Widget _buildValleyOnMap({
    ValleyDevice? device,
    required double left,    // 0.0 - 1.0 (процент от ширины)
    required double top,     // 0.0 - 1.0 (процент от высоты)
    required double size,    // Размер в пикселях
  }) {
    if (device == null) return const SizedBox.shrink();

    final isOnline = device.isOnline;
    final color = isOnline ? Colors.green : Colors.grey;
    final angle = device.currentAngle;

    return Positioned(
      left: left * 350 - size / 2,  // Центрируем по точке (350 - ширина карты)
      top: top * 350 - size / 2,     // Центрируем по точке (350 - высота карты)
      child: GestureDetector(
        // Долгое нажатие для перехода
        onLongPressStart: (_) {
          setState(() {
            _isLongPressing = true;
            _longPressedDeviceId = device.id;
          });
          HapticFeedback.heavyImpact(); // Вибрация при удержании
        },
        onLongPressEnd: (_) {
          setState(() {
            _isLongPressing = false;
            _longPressedDeviceId = null;
          });
          // Переход на детальный экран
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ValleyDetailScreen(deviceId: device.id),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
        // Обычное нажатие - только визуальный фидбек
        onTapDown: (_) => HapticFeedback.lightImpact(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
            border: Border.all(
              color: color,
              width: _longPressedDeviceId == device.id ? 4 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isOnline ? 0.6 : 0.2),
                blurRadius: isOnline ? 20 : 10,
                spreadRadius: isOnline ? 5 : 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Фоновый круг (опционально, для видимости)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                ),
              ),

              // ═══════════════════════════════════════════════════════════
              // СТРЕЛКА КАК ЧАСЫ - от центра к краю
              // ═══════════════════════════════════════════════════════════
              CustomPaint(
                size: Size(size, size),
                painter: _ValleyArrowPainter(
                  angle: angle,
                  color: color,
                  strokeWidth: 3,
                ),
              ),

              // Центральная точка (ось вращения)
              Container(
                width: size * 0.2,
                height: size * 0.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),

              // Номер Valley (мелкий текст внизу)
              Positioned(
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: (_isDarkTheme ? Colors.black : Colors.white).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    device.name.replaceAll('Valley ', 'V'),
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ОСТАЛЬНЫЕ МЕТОДЫ (без изменений)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> _onWillPop() async {
    if (_backPressedOnce) {
      _backPressTimer?.cancel();
      return true;
    }

    setState(() {
      _backPressedOnce = true;
      _showExitToast = true;
    });

    _backPressTimer?.cancel();
    _backPressTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _backPressedOnce = false;
          _showExitToast = false;
        });
      }
    });

    return false;
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Hero(
                tag: 'logo',
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isDarkTheme
                          ? [Colors.cyanAccent, Colors.blueAccent]
                          : [Colors.deepPurple, Colors.purpleAccent],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isDarkTheme ? Colors.cyanAccent : Colors.deepPurple)
                            .withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Irrigation',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isDarkTheme ? Colors.white : Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Система управления поливом',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isDarkTheme ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
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
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _showLogoutDialog(),
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer<ValleyProvider>(
      builder: (context, provider, child) {
        final devices = provider.devices;
        final onlineCount = devices.where((d) => d.isOnline).length;
        final runningCount = devices.where((d) => d.motorRunning).length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isDarkTheme
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.devices,
                  value: '${devices.length}',
                  label: 'Всего',
                  color: Colors.blue,
                ),
                _buildDivider(),
                _buildStatItem(
                  icon: Icons.wifi,
                  value: '$onlineCount',
                  label: 'Online',
                  color: Colors.green,
                ),
                _buildDivider(),
                _buildStatItem(
                  icon: Icons.play_circle,
                  value: '$runningCount',
                  label: 'Работают',
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
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

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: _isDarkTheme ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
    );
  }

  Widget _buildFloatingMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _fabController,
          child: FloatingActionButton.small(
            heroTag: 'refresh',
            onPressed: () {
              final provider = context.read<ValleyProvider>();
              for (int i = 1; i <= 5; i++) {
                provider.sendCommand('valley_$i', 'PING');
              }
            },
            backgroundColor: _isDarkTheme ? Colors.cyanAccent : Colors.deepPurple,
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.extended(
          heroTag: 'menu',
          onPressed: () {
            if (_fabController.status == AnimationStatus.completed) {
              _fabController.reverse();
            } else {
              _fabController.forward();
            }
          },
          backgroundColor: _isDarkTheme ? Colors.cyanAccent : Colors.deepPurple,
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _fabController,
            color: Colors.white,
          ),
          label: const Text(
            'Меню',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkTheme ? const Color(0xFF203A43) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Выход',
          style: TextStyle(
            color: _isDarkTheme ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Вы уверены, что хотите выйти?',
          style: TextStyle(
            color: _isDarkTheme ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: _isDarkTheme ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService().logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
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
    _fabController.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAINTER: Стрелка Valley как стрелка часов
// ═══════════════════════════════════════════════════════════════════════════
class _ValleyArrowPainter extends CustomPainter {
  final double angle;      // 0-360 градусов
  final Color color;
  final double strokeWidth;

  _ValleyArrowPainter({
    required this.angle,
    required this.color,
    this.strokeWidth = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final radians = (angle - 90) * math.pi / 180;

    // Конечная точка стрелки (от центра к краю)
    final endPoint = Offset(
      center.dx + radius * math.cos(radians),
      center.dy + radius * math.sin(radians),
    );

    // Рисуем стрелку
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Линия от центра к краю
    canvas.drawLine(center, endPoint, paint);

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}