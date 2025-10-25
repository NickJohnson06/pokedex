import 'package:flutter/material.dart';

class StatBar extends StatelessWidget {
  final String label;
  final int value; // 0..255 typical
  final int maxValue;

  const StatBar({super.key, required this.label, required this.value, this.maxValue = 180});

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, maxValue).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 64, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: v / maxValue,
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 36, child: Text(value.toString(), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
