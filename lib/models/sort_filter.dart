import 'package:flutter/foundation.dart';

enum SortMode { dex, name, type, favorite }
enum SortDirection { asc, desc }

@immutable
class FilterState {
  final Set<String> types; // e.g., {'Fire','Flying'}
  final bool favoritesOnly;
  final Set<int> generations; // optional future-proof

  const FilterState({
    this.types = const {},
    this.favoritesOnly = false,
    this.generations = const {},
  });

  FilterState copyWith({
    Set<String>? types,
    bool? favoritesOnly,
    Set<int>? generations,
  }) => FilterState(
        types: types ?? this.types,
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
        generations: generations ?? this.generations,
      );

  Map<String, dynamic> toJson() => {
    'types': types.toList(),
    'favoritesOnly': favoritesOnly,
    'generations': generations.toList(),
  };

  static FilterState fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FilterState();
    return FilterState(
      types: Set<String>.from(json['types'] ?? const []),
      favoritesOnly: json['favoritesOnly'] ?? false,
      generations: Set<int>.from((json['generations'] ?? const []).cast<int>()),
    );
  }
}

@immutable
class SortState {
  final SortMode mode;
  final SortDirection dir;

  const SortState({this.mode = SortMode.dex, this.dir = SortDirection.asc});

  SortState toggleDir() => SortState(mode: mode, dir: dir == SortDirection.asc ? SortDirection.desc : SortDirection.asc);

  Map<String, dynamic> toJson() => {'mode': mode.name, 'dir': dir.name};

  static SortState fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SortState();
    return SortState(
      mode: SortMode.values.firstWhere(
        (e) => e.name == (json['mode'] ?? 'dex'),
        orElse: () => SortMode.dex,
      ),
      dir: SortDirection.values.firstWhere(
        (e) => e.name == (json['dir'] ?? 'asc'),
        orElse: () => SortDirection.asc,
      ),
    );
  }
}
