import 'package:flutter/material.dart';

class DigitalWaterGauge extends StatelessWidget {
  const DigitalWaterGauge({
    super.key,
    required this.levelPercent,
    required this.liters,
    this.size = 132,
  });

  final int levelPercent;
  final double liters;
  final double size;

  @override
  Widget build(BuildContext context) {
    final progress = (levelPercent / 100).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: animatedProgress,
                  strokeWidth: 10,
                  backgroundColor: const Color(0xFFE6F2FA),
                  color: const Color(0xFF0A8BC7),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(animatedProgress * 100).round()}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0A8BC7),
                    ),
                  ),
                  Text(
                    '${liters.toStringAsFixed(2)} L',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
