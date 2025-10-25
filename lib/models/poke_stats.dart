// Stats Model
class PokeStats {
  final int hp, atk, def, spa, spd, spe;
  const PokeStats({required this.hp, required this.atk, required this.def, required this.spa, required this.spd, required this.spe});

  factory PokeStats.fromMap(Map<String, dynamic> m) => PokeStats(
    hp: m['hp'], atk: m['atk'], def: m['def'], spa: m['spa'], spd: m['spd'], spe: m['spe'],
  );
}