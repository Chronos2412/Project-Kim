class CategoryModel {
  final int? id;
  final String name;
  final DateTime createdAt;

  CategoryModel({
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

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map["id"],
      name: map["name"],
      createdAt: DateTime.parse(map["createdAt"]),
    );
  }
}