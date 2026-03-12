import 'package:flutter/material.dart';
import '../models/valley_device.dart';
import '../screens/valley_detail_screen.dart';

class ValleyCard extends StatelessWidget {
  final ValleyDevice device;
  final bool isDarkTheme;

  const ValleyCard({
    Key? key,
    required this.device,
    this.isDarkTheme = true,
  }) : super(key: key);

  Color get _statusColor {
    if (!device.isOnline) return Colors.grey;
    if (device.motorRunning) return Colors.green;
    return Colors.orange;
  }

  Color get _glowColor {
    if (!device.isOnline) return Colors.grey;
    if (device.motorRunning) return Colors.greenAccent;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'valley_${device.id}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkTheme
                ? [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ]
                : [
              Colors.white,
              Colors.white.withOpacity(0.9),
            ],
          ),
          border: Border.all(
            color: _statusColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _glowColor.withOpacity(device.isOnline ? 0.2 : 0),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      ValleyDetailScreen(deviceId: device.id),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Animated status indicator
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _statusColor.withOpacity(0.3 * value),
                                  _statusColor.withOpacity(0.1 * value),
                                ],
                              ),
                              border: Border.all(
                                color: _statusColor.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.grass,
                              color: _statusColor,
                              size: 28,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkTheme ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _statusColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _statusColor.withOpacity(0.5),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  device.statusText,
                                  style: TextStyle(
                                    color: _statusColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: isDarkTheme ? Colors.white54 : Colors.black45,
                      ),
                    ],
                  ),
                  if (device.isOnline) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem(
                            icon: Icons.speed,
                            value: '${device.pressure.toStringAsFixed(1)}',
                            unit: 'PSI',
                          ),
                          _buildInfoItem(
                            icon: Icons.timer,
                            value: '${device.runtimeSeconds}',
                            unit: 'сек',
                          ),
                          _buildInfoItem(
                            icon: Icons.rotate_right,
                            value: '${device.currentAngle.toStringAsFixed(0)}°',
                            unit: 'позиция',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required String unit,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDarkTheme ? Colors.white60 : Colors.black54,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 10,
            color: isDarkTheme ? Colors.white.withOpacity(0.4) : Colors.black38,
          ),
        ),
      ],
    );
  }
}