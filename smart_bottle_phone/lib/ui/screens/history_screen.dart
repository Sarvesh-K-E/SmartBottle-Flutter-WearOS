import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/smart_bottle_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smartBottleControllerProvider);
    final bars = state.last7Days;
    final maxConsumed = bars.fold<double>(
      0,
      (max, day) => day.drankLiters > max ? day.drankLiters : max,
    );
    final maxY = maxConsumed <= 0 ? 1.0 : (maxConsumed * 1.25);
    final hasAnyData = bars.any((day) => day.drankLiters > 0);

    return Scaffold(
      appBar: AppBar(title: const Text('History & Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Number of days used: ${state.weekly.usedDays}',
                    style: const TextStyle(
                      color: Color(0xFF0F1728),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Average per used day: ${state.weekly.averagePerUsedDay.toStringAsFixed(2)} L',
                    style: const TextStyle(color: Color(0xFF0F1728)),
                  ),
                  Text(
                    'Goal achievement days: ${state.weekly.goalAchievedDays} / ${state.weekly.usedDays}',
                    style: const TextStyle(color: Color(0xFF0F1728)),
                  ),
                  Text(
                    'Total intake: ${state.weekly.totalDrank.toStringAsFixed(2)} L',
                    style: const TextStyle(color: Color(0xFF0F1728)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Number of days used: ${state.monthly.usedDays}',
                    style: const TextStyle(
                      color: Color(0xFF0F1728),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Average per used day: ${state.monthly.averagePerUsedDay.toStringAsFixed(2)} L',
                    style: const TextStyle(color: Color(0xFF0F1728)),
                  ),
                  Text(
                    'Goal achievement days: ${state.monthly.goalAchievedDays} / ${state.monthly.usedDays}',
                    style: const TextStyle(color: Color(0xFF0F1728)),
                  ),
                  Text(
                    'Total intake: ${state.monthly.totalDrank.toStringAsFixed(2)} L',
                    style: const TextStyle(color: Color(0xFF0F1728)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last 7 Days',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (!hasAnyData)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No drinking data yet. Bars are shown as 0.',
                        style: TextStyle(color: Color(0xFF475467)),
                      ),
                    ),
                  if (hasAnyData)
                    SizedBox(
                      height: 215,
                      child: BarChart(
                        BarChartData(
                          minY: 0,
                          maxY: maxY,
                          alignment: BarChartAlignment.spaceAround,
                          groupsSpace: 6,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          barGroups: List.generate(
                            bars.length,
                            (index) => BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: bars[index].drankLiters,
                                  width: 8,
                                  borderRadius: BorderRadius.circular(4),
                                  color: const Color(0xFF0A8BC7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 24),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(bars.length, (index) {
                      return Expanded(
                        child: Text(
                          '${DateFormat('dd').format(bars[index].date)}\n${DateFormat('MMM').format(bars[index].date)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8,
                            height: 1.0,
                            color: Color(0xFF475467),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
