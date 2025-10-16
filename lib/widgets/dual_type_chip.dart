import 'package:flutter/material.dart';
import '../utils/type_colors.dart';

class DualTypeChip extends StatelessWidget {
  final String type1;
  final String? type2;

  const DualTypeChip({super.key, required this.type1, this.type2});

  @override
  Widget build(BuildContext context) {
    final t1 = type1.trim();
    final t2 = type2?.trim().isEmpty ?? true ? null : type2!.trim();

    if (t2 == null) {
      // Single type chip with shadow + outline
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: typeColor(t1).withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black26, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          t1,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Dual type chip with gradient, border, shadow
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            typeColor(t1).withOpacity(0.9),
            typeColor(t2).withOpacity(0.9),
          ],
          stops: const [0.5, 0.5],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black26, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Text(
        '$t1 / $t2',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
