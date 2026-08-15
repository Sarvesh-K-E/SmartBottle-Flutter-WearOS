import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/wear_sync_controller.dart';

class WearHomeScreen extends ConsumerWidget {
  const WearHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wearSyncControllerProvider);
    final phoneConnected = state.reachable;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF2CB9E8), Color(0xFF006A94), Color(0xFF05324A)],
            radius: 1.0,
            center: Alignment(0, -0.2),
          ),
        ),
        child: SafeArea(
          child: phoneConnected
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        'Smart Bottle',
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _glassCard(
                        child: Column(
                          children: [
                            Text(
                              'Water level',
                              style: GoogleFonts.manrope(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _digitalGauge(state.levelPercent ?? 0),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    '${state.levelLiters.toStringAsFixed(2)} L / 2.00 L',
                                    style: GoogleFonts.sora(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _glassCard(
                              child: Column(
                                children: [
                                  Text(
                                    'Temp',
                                    style: GoogleFonts.manrope(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    '${state.temperatureC?.toStringAsFixed(1) ?? '--.-'} C',
                                    style: GoogleFonts.sora(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _glassCard(
                              child: Column(
                                children: [
                                  Text(
                                    'TDS',
                                    style: GoogleFonts.manrope(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    '${state.tdsPpm ?? '--'} ppm',
                                    style: GoogleFonts.sora(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _glassCard(
                        child: Column(
                          children: [
                            Text(
                              'Current intake',
                              style: GoogleFonts.manrope(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${state.todayDrankLiters.toStringAsFixed(2)} / ${state.goalLiters.toStringAsFixed(2)} L',
                              style: GoogleFonts.sora(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: state.goalProgress,
                                color: const Color(0xFF6AF9C4),
                                backgroundColor: Colors.white24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.watch_later_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Waiting for phone sync...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _digitalGauge(int levelPercent) {
    final progress = (levelPercent / 100).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        return SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: animatedProgress,
                strokeWidth: 4,
                backgroundColor: Colors.white24,
                color: const Color(0xFF6AF9C4),
              ),
              Text(
                '${(animatedProgress * 100).round()}%',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
