import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sort_filter.dart';
import '../models/pokemon.dart';

class SortFilterController extends ChangeNotifier {
  static const _kKey = 'pokedex_sort_filter_v1';
  SortState _sort = const SortState();
  FilterState _filter = const FilterState();

  SortState get sort => _sort;
  FilterState get filter => _filter;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _sort = SortState.fromJson(map['sort'] as Map<String, dynamic>?);
      _filter = FilterState.fromJson(map['filter'] as Map<String, dynamic>?);
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({'sort': _sort.toJson(), 'filter': _filter.toJson()});
    await prefs.setString(_kKey, payload);
  }

  Future<void> setSort(SortState next) async {
    _sort = next;
    await _save();
    notifyListeners();
  }

  Future<void> setFilter(FilterState next) async {
    _filter = next;
    await _save();
    notifyListeners();
  }

  List<Pokemon> apply(List<Pokemon> items) {
    // 1. Filter
    var out = items.where((p) {
      // Filter by Type
      if (_filter.types.isNotEmpty) {
        final hasType = _filter.types.contains(p.type) || (p.type2 != null && _filter.types.contains(p.type2));
        if (!hasType) return false;
      }

      // Filter by Generation
      if (_filter.generations.isNotEmpty) {
        final dex = p.dex ?? 99999;
        bool matchGen = false;
        for (final g in _filter.generations) {
          if (_isInGen(dex, g)) {
            matchGen = true;
            break;
          }
        }
        if (!matchGen) return false;
      }

      // Filter by Favorites
      if (_filter.favoritesOnly && !p.favorite) return false;

      return true;
    }).toList();

    // 2. Sort
    out.sort((a, b) {
      int cmp = 0;
      switch (_sort.mode) {
        case SortMode.name:
          cmp = a.name.compareTo(b.name);
          break;
        case SortMode.type:
          cmp = a.type.compareTo(b.type);
          if (cmp == 0) cmp = (a.type2 ?? '').compareTo(b.type2 ?? '');
          break;
        case SortMode.favorite:
          cmp = (b.favorite ? 1 : 0).compareTo(a.favorite ? 1 : 0);
          break;
        case SortMode.dex:
        default:
          final da = a.dex ?? 9999;
          final db = b.dex ?? 9999;
          cmp = da.compareTo(db);
          break;
      }
      return _sort.dir == SortDirection.asc ? cmp : -cmp;
    });

    return out;
  }

  bool _isInGen(int dex, int gen) {
    switch (gen) {
      case 1: return dex >= 1 && dex <= 151;
      case 2: return dex >= 152 && dex <= 251;
      case 3: return dex >= 252 && dex <= 386;
      case 4: return dex >= 387 && dex <= 493;
      case 5: return dex >= 494 && dex <= 649;
      case 6: return dex >= 650 && dex <= 721;
      case 7: return dex >= 722 && dex <= 809;
      case 8: return dex >= 810 && dex <= 905;
      case 9: return dex >= 906 && dex <= 1025;
      default: return false;
    }
  }
}
