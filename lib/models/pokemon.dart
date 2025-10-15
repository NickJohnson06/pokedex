class Pokemon {
  int? id;
  String name;
  String type;
  String? imageUrl; // optional enhancement for Step 4

  Pokemon({this.id, required this.name, required this.type, this.imageUrl});

  factory Pokemon.fromMap(Map<String, dynamic> m) => Pokemon(
    id: m['id'] as int?,
    name: m['name'] as String,
    type: m['type'] as String,
    imageUrl: m['imageUrl'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'imageUrl': imageUrl,
  };
}
