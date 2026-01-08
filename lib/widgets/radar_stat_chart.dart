import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RadarStatChart extends StatelessWidget {
  final int hp, atk, def, spa, spd, spe;
  final Color color;

  const RadarStatChart({
    super.key,
    required this.hp,
    required this.atk,
    required this.def,
    required this.spa,
    required this.spd,
    required this.spe,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const double maxVal = 160; 

    return SizedBox(
      height: 200,
      child: RadarChart(
        RadarChartData(
          radarTouchData: RadarTouchData(enabled: false),
          tickCount: 3,
          ticksTextStyle: const TextStyle(color: Colors.transparent),
          gridBorderData: BorderSide(color: Colors.black.withOpacity(0.1), width: 1),
          titlePositionPercentageOffset: 0.1,
          getTitle: (index, angle) {
            const titles = ['HP', 'ATK', 'DEF', 'SPE', 'SPD', 'SPA'];
            return RadarChartTitle(
              text: titles[index],
              angle: 0, // keep text straight
            );
          },
          dataSets: [
            RadarDataSet(
              fillColor: color.withOpacity(0.4),
              borderColor: color,
              entryRadius: 2,
              dataEntries: [
                RadarEntry(value: _norm(hp, maxVal)),
                RadarEntry(value: _norm(atk, maxVal)),
                RadarEntry(value: _norm(def, maxVal)),
                RadarEntry(value: _norm(spe, maxVal)),
                RadarEntry(value: _norm(spd, maxVal)),
                RadarEntry(value: _norm(spa, maxVal)),
              ],
              borderWidth: 2,
            ),
          ],
        ),
        swapAnimationDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  double _norm(int val, double max) {
    return (val > max ? max : val.toDouble());
  }
}
