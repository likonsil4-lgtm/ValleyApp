import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/valley_provider.dart';
import '../widgets/valley_card.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../models/valley_device.dart';
import 'dart:async';

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

  Future<bool> _onWillPop() async {
    if (_backPressedOnce) {
      // Второе нажатие - выходим
      _backPressTimer?.cancel();
      return true; // Разрешаем выход
    }

    // Первое нажатие - показываем уведомление
    setState(() {
      _backPressedOnce = true;
      _showExitToast = true;
    });

    // Таймер на 2 секунды для сброса
    _backPressTimer?.cancel();
    _backPressTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _backPressedOnce = false;
          _showExitToast = false;
        });
      }
    });

    // Не выходим
    return false;
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and Title
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

          // Theme & Logout buttons
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
        // Refresh button
        ScaleTransition(
          scale: _fabController,
          child: FloatingActionButton.small(
            heroTag: 'refresh',
            onPressed: () {
              // Request status update from all devices
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
        // Main FAB
        FloatingActionButton.extended(
          heroTag: 'menu',
          onPressed: () {
            if (_fabController.status == AnimationStatus.completed) {
              _fabController.reverse();
            } else {
              _fabController.forward();
            }
          },
          backgroundColor: _isDarkTheme
              ? Colors.cyanAccent
              : Colors.deepPurple,
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _fabController,
            color: Colors.white,
          ),
          label: Text(
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