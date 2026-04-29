class BookingModel {
  final int? id;
  final String customerName;
  final String customerPhone;
  final DateTime eventDate;
  final String eventLocation;
  final String packageName;
  final double totalAmount;
  final double depositAmount;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final String createdBy;

  BookingModel({
    this.id,
    required this.customerName,
    required this.customerPhone,
    required this.eventDate,
    required this.eventLocation,
    required this.packageName,
    required this.totalAmount,
    required this.depositAmount,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "customerName": customerName,
      "customerPhone": customerPhone,
      "eventDate": eventDate.toIso8601String(),
      "eventLocation": eventLocation,
      "packageName": packageName,
      "totalAmount": totalAmount,
      "depositAmount": depositAmount,
      "status": status,
      "notes": notes,
      "createdAt": createdAt.toIso8601String(),
      "createdBy": createdBy,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map["id"],
      customerName: map["customerName"] ?? "",
      customerPhone: map["customerPhone"] ?? "",
      eventDate: DateTime.parse(map["eventDate"]),
      eventLocation: map["eventLocation"] ?? "",
      packageName: map["packageName"] ?? "",
      totalAmount: (map["totalAmount"] as num).toDouble(),
      depositAmount: (map["depositAmount"] as num).toDouble(),
      status: map["status"] ?? "Pendiente",
      notes: map["notes"],
      createdAt: DateTime.parse(map["createdAt"]),
      createdBy: map["createdBy"] ?? "system",
    );
  }

  BookingModel copyWith({
    int? id,
    String? customerName,
    String? customerPhone,
    DateTime? eventDate,
    String? eventLocation,
    String? packageName,
    double? totalAmount,
    double? depositAmount,
    String? status,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return BookingModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      eventDate: eventDate ?? this.eventDate,
      eventLocation: eventLocation ?? this.eventLocation,
      packageName: packageName ?? this.packageName,
      totalAmount: totalAmount ?? this.totalAmount,
      depositAmount: depositAmount ?? this.depositAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}