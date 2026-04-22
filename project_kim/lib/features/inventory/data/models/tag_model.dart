class TagModel {
  final int? id;
  final String name;
  final DateTime createdAt;

  TagModel({
    this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  factory TagModel.fromMap(Map<String, dynamic> map) {
    return TagModel(
      id: map["id"],
      name: map["name"],
      createdAt: DateTime.parse(map["createdAt"]),
    );
  }
}