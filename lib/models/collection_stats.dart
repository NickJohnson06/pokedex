class CollectionStats {
  final int totalCaught;
  final int totalAvailable;
  final Map<int, GenerationStats> byGeneration;
  final Map<String, int> byType;
  final double completionPercentage;

  const CollectionStats({
    required this.totalCaught,
    required this.totalAvailable,
    required this.byGeneration,
    required this.byType,
    required this.completionPercentage,
  });
}

class GenerationStats {
  final int generation;
  final int caught;
  final int total;
  final double percentage;

  const GenerationStats({
    required this.generation,
    required this.caught,
    required this.total,
    required this.percentage,
  });
}
