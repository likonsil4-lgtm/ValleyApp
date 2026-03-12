import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _error;
  bool _isDarkTheme = true;

  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _logoScale;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _initAnimations();
  }

  void _initAnimations() {
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideUp = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _checkAuth() async {
    final isAuth = await _authService.isAuthenticated();
    if (isAuth && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await _authService.login(_passwordController.text);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() => _error = 'Неверный пароль');
      HapticFeedback.vibrate();
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isDarkTheme
                ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]
                : [const Color(0xFF667eea), const Color(0xFF764ba2)],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            _buildAnimatedBackground(),

            // Theme toggle button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: _toggleTheme,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _isDarkTheme ? Icons.wb_sunny : Icons.nightlight_round,
                    key: ValueKey(_isDarkTheme),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo
                      FadeTransition(
                        opacity: _fadeIn,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isDarkTheme
                                    ? [Colors.cyanAccent, Colors.blueAccent]
                                    : [Colors.orangeAccent, Colors.pinkAccent],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isDarkTheme ? Colors.cyanAccent : Colors.orangeAccent)
                                      .withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.water_drop,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title with animation
                      SlideTransition(
                        position: _slideUp,
                        child: FadeTransition(
                          opacity: _fadeIn,
                          child: Column(
                            children: [
                              Text(
                                'Irrigation',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Система управления поливом',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Login Card
                      SlideTransition(
                        position: _slideUp,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isDarkTheme
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: _isDarkTheme
                                  ? const ColorFilter.mode(Colors.transparent, BlendMode.srcOver)
                                  : const ColorFilter.mode(Colors.white, BlendMode.srcOver),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Password field with animation
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: _error != null
                                            ? [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.3),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                            : null,
                                      ),
                                      child: TextField(
                                        controller: _passwordController,
                                        obscureText: true,
                                        style: TextStyle(
                                          color: _isDarkTheme ? Colors.white : Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Пароль',
                                          labelStyle: TextStyle(
                                            color: _isDarkTheme
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.lock_outline,
                                            color: _isDarkTheme
                                                ? Colors.cyanAccent
                                                : Colors.deepPurple,
                                          ),
                                          suffixIcon: _error != null
                                              ? const Icon(Icons.error, color: Colors.red)
                                              : null,
                                          filled: true,
                                          fillColor: _isDarkTheme
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.grey.shade100,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(0.1),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: _isDarkTheme
                                                  ? Colors.cyanAccent
                                                  : Colors.deepPurple,
                                              width: 2,
                                            ),
                                          ),
                                          errorText: _error,
                                          errorStyle: const TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        onSubmitted: (_) => _login(),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Login button with gradient
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          gradient: LinearGradient(
                                            colors: _isLoading
                                                ? [Colors.grey, Colors.grey.shade600]
                                                : _isDarkTheme
                                                ? [Colors.cyanAccent, Colors.blueAccent]
                                                : [Colors.deepPurple, Colors.purpleAccent],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (_isDarkTheme
                                                  ? Colors.cyanAccent
                                                  : Colors.deepPurple)
                                                  .withOpacity(0.4),
                                              blurRadius: 15,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(16),
                                            onTap: _isLoading ? null : _login,
                                            child: Center(
                                              child: _isLoading
                                                  ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                                  : const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Войти',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                    Icons.arrow_forward,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedContainer(
      duration: const Duration(seconds: 5),
      child: CustomPaint(
        painter: _BackgroundPainter(
          isDarkTheme: _isDarkTheme,
          animation: _logoController,
        ),
        size: Size.infinite,
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// Custom painter for animated background
class _BackgroundPainter extends CustomPainter {
  final bool isDarkTheme;
  final Animation<double> animation;

  _BackgroundPainter({required this.isDarkTheme, required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDarkTheme ? Colors.cyanAccent : Colors.white)
          .withOpacity(0.03);

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide / 2;

    // Draw animated circles
    for (int i = 0; i < 5; i++) {
      final radius = maxRadius * (0.2 + (i * 0.2)) * (0.8 + animation.value * 0.2);
      canvas.drawCircle(center, radius, paint);
    }

    // Draw floating particles
    final random = math.Random(42);
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height + animation.value * 50) % size.height;
      final particleSize = random.nextDouble() * 4 + 2;

      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint..color = (isDarkTheme ? Colors.cyanAccent : Colors.white)
            .withOpacity(0.1),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}