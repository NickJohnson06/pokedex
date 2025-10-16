import 'package:flutter/material.dart';

final Map<String, Color> _map = {
  'normal': Colors.grey,
  'fire': Colors.redAccent,
  'water': Colors.blueAccent,
  'electric': Colors.amber,
  'grass': Colors.green,
  'ice': Colors.cyan,
  'fighting': Colors.deepOrange,
  'poison': Colors.purpleAccent,
  'ground': Colors.brown,
  'flying': Colors.teal,
  'psychic': Colors.pinkAccent,
  'bug': Colors.lightGreen,
  'rock': Colors.brown,
  'ghost': Colors.deepPurple,
  'dragon': Colors.indigo,
  'dark': Colors.black54,
  'steel': Colors.blueGrey,
  'fairy': Colors.pink,
};

Color typeColor(String type) {
  return _map[type.toLowerCase()] ?? Colors.grey;
}
