class ProductLogModel {
  final int? id;
  final int productId;
  final String changedBy;
  final String actionType; // CREATE / UPDATE / DELETE / ADJUST_STOCK
  final String fieldChanged;
  final String? oldValue;
  final String? newValue;
  final DateTime createdAt;

  ProductLogModel({
    this.id,
    required this.productId,
    required this.changedBy,
    required this.actionType,
    required this.fieldChanged,
    this.oldValue,
    this.newValue,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "productId": productId,
      "changedBy": changedBy,
      "actionType": actionType,
      "fieldChanged": fieldChanged,
      "oldValue": oldValue,
      "newValue": newValue,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  factory ProductLogModel.fromMap(Map<String, dynamic> map) {
    return ProductLogModel(
      id: map["id"],
      productId: map["productId"],
      changedBy: map["changedBy"],
      actionType: map["actionType"],
      fieldChanged: map["fieldChanged"],
      oldValue: map["oldValue"],
      newValue: map["newValue"],
      createdAt: DateTime.parse(map["createdAt"]),
    );
  }
}