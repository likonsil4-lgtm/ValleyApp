import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/valley_device.dart';
import '../providers/valley_provider.dart';

class SettingsScreen extends StatefulWidget {
  final ValleyDevice device;

  const SettingsScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late TextEditingController _startAngleController;
  late TextEditingController _rotationTimeController;
  bool _isDarkTheme = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _startAngleController = TextEditingController(
        text: widget.device.startAngle.toString());
    _rotationTimeController = TextEditingController(
        text: widget.device.rotationTimeMinutes.toString());

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

  void _saveSettings() {
    final startAngle = double.tryParse(_startAngleController.text) ?? 220.0;
    final rotationTime = double.tryParse(_rotationTimeController.text) ?? 74.0;

    context.read<ValleyProvider>().updateCalibration(
      widget.device.id,
      startAngle,
      rotationTime,
    );

    _showSuccessToast();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _showSuccessToast() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: _isDarkTheme
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.green.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Сохранено!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkTheme ? _darkTheme : _lightTheme,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
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
                    // Device Info Card
                    _buildDeviceInfoCard(),
                    const SizedBox(height: 20),
                    // Calibration Card
                    _buildCalibrationCard(),
                    const SizedBox(height: 20),
                    // Info Section
                    _buildInfoSection(),
                    const SizedBox(height: 32),
                    // Save Button
                    _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
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

  PreferredSizeWidget _buildAppBar() {
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
            'Калибровка',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _isDarkTheme ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            widget.device.name,
            style: TextStyle(
              fontSize: 12,
              color: _isDarkTheme ? Colors.white70 : Colors.black54,
            ),
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
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDeviceInfoCard() {
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
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (_isDarkTheme ? Colors.cyanAccent : Colors.deepPurple).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.settings_suggest,
              color: _isDarkTheme ? Colors.cyanAccent : Colors.deepPurple,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Текущая позиция',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isDarkTheme ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.device.currentAngle.toStringAsFixed(1)}°',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isDarkTheme ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.device.isOnline
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.device.isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                color: widget.device.isOnline ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationCard() {
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
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDarkTheme
                      ? [Colors.white.withOpacity(0.05), Colors.transparent]
                      : [Colors.grey.shade50, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: _isDarkTheme ? Colors.cyanAccent : Colors.deepPurple,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Параметры калибровки',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isDarkTheme ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Start Angle Field
            _buildInputField(
              controller: _startAngleController,
              label: 'Начальный угол',
              hint: 'Например: 220',
              unit: '°',
              icon: Icons.rotate_right,
              min: 0,
              max: 360,
            ),

            _buildDivider(),

            // Rotation Time Field
            _buildInputField(
              controller: _rotationTimeController,
              label: 'Время оборота',
              hint: 'Например: 74',
              unit: 'мин',
              icon: Icons.timer,
              min: 1,
              max: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String unit,
    required IconData icon,
    required double min,
    required double max,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _isDarkTheme ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 18,
                    color: _isDarkTheme ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: _isDarkTheme ? Colors.white30 : Colors.black26,
                    ),
                    prefixIcon: Icon(
                      icon,
                      color: _isDarkTheme ? Colors.cyanAccent : Colors.deepPurple,
                    ),
                    suffixText: unit,
                    suffixStyle: TextStyle(
                      color: _isDarkTheme ? Colors.white60 : Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
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
                        color: _isDarkTheme ? Colors.cyanAccent : Colors.deepPurple,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Диапазон: ${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)} $unit',
            style: TextStyle(
              fontSize: 11,
              color: _isDarkTheme ? Colors.white.withOpacity(0.4) : Colors.black38,
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

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (_isDarkTheme ? Colors.amber : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (_isDarkTheme ? Colors.amber : Colors.orange).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: _isDarkTheme ? Colors.amber : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Эти параметры используются для расчета текущего положения стрелы Valley. Убедитесь в правильности значений перед сохранением.',
              style: TextStyle(
                fontSize: 13,
                color: _isDarkTheme ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: _isDarkTheme
              ? [Colors.cyanAccent, Colors.blueAccent]
              : [Colors.deepPurple, Colors.purpleAccent],
        ),
        boxShadow: [
          BoxShadow(
            color: (_isDarkTheme ? Colors.cyanAccent : Colors.deepPurple).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _saveSettings,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.save,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Сохранить настройки',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
    _startAngleController.dispose();
    _rotationTimeController.dispose();
    super.dispose();
  }
}