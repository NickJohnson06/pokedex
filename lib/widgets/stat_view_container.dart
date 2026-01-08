import 'package:flutter/material.dart';
import 'stat_bar.dart';
import 'radar_stat_chart.dart';

class StatViewContainer extends StatefulWidget {
  final int hp, atk, def, spa, spd, spe;
  final Color themeColor;

  const StatViewContainer({
    super.key,
    required this.hp,
    required this.atk,
    required this.def,
    required this.spa,
    required this.spd,
    required this.spe,
    required this.themeColor,
  });

  @override
  State<StatViewContainer> createState() => _StatViewContainerState();
}

class _StatViewContainerState extends State<StatViewContainer> with SingleTickerProviderStateMixin {
  bool _showRadar = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Base Stats', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: Icon(_showRadar ? Icons.bar_chart : Icons.radar),
              tooltip: _showRadar ? 'Show Bars' : 'Show Radar',
              onPressed: () => setState(() => _showRadar = !_showRadar),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _showRadar
              ? RadarStatChart(
                  key: const ValueKey('radar'),
                  hp: widget.hp,
                  atk: widget.atk,
                  def: widget.def,
                  spa: widget.spa,
                  spd: widget.spd,
                  spe: widget.spe,
                  color: widget.themeColor,
                )
              : Column(
                  key: const ValueKey('bars'),
                  children: [
                    StatBar(label: 'HP',  value: widget.hp,  color: widget.themeColor),
                    StatBar(label: 'ATK', value: widget.atk, color: widget.themeColor),
                    StatBar(label: 'DEF', value: widget.def, color: widget.themeColor),
                    StatBar(label: 'SpA', value: widget.spa, color: widget.themeColor),
                    StatBar(label: 'SpD', value: widget.spd, color: widget.themeColor),
                    StatBar(label: 'SPE', value: widget.spe, color: widget.themeColor),
                  ],
                ),
        ),
      ],
    );
  }
}
