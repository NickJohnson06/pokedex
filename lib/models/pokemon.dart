class Pokemon {
  int? id;
  String name;
  String type;
  String? type2;
  int? dex;
  bool favorite;

  Pokemon({
    this.id,
    required this.name,
    required this.type,
    this.type2,
    this.dex,
    this.favorite = false, // default = not favorite
  });

  factory Pokemon.fromMap(Map<String, dynamic> m) => Pokemon(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: m['type'] as String,
        type2: m['type2'] as String?,
        dex: m['dex'] as int?,
        // SQLite stores booleans as ints (0 or 1)
        favorite: (m['favorite'] is int)
            ? (m['favorite'] as int) == 1
            : (m['favorite'] as bool?) ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'type2': type2,
        'dex': dex,
        'favorite': favorite ? 1 : 0, // store as 1/0 for SQLite
      };

  // handy copyWith() for updates
  Pokemon copyWith({
    int? id,
    String? name,
    String? type,
    String? type2,
    int? dex,
    bool? favorite,
  }) {
    return Pokemon(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      type2: type2 ?? this.type2,
      dex: dex ?? this.dex,
      favorite: favorite ?? this.favorite,
    );
  }
}
