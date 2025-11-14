import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sort_filter.dart';

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
}
