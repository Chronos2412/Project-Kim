class BookingPaymentModel {
  final int? id;
  final int bookingId;
  final double amount;
  final DateTime paymentDate;
  final DateTime createdAt;
  final String createdBy;
  final String? note;

  BookingPaymentModel({
    this.id,
    required this.bookingId,
    required this.amount,
    required this.paymentDate,
    required this.createdAt,
    required this.createdBy,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "bookingId": bookingId,
      "amount": amount,
      "paymentDate": paymentDate.toIso8601String(),
      "createdAt": createdAt.toIso8601String(),
      "createdBy": createdBy,
      "note": note,
    };
  }

  factory BookingPaymentModel.fromMap(Map<String, dynamic> map) {
    return BookingPaymentModel(
      id: map["id"],
      bookingId: map["bookingId"],
      amount: (map["amount"] as num).toDouble(),
      paymentDate: DateTime.parse(map["paymentDate"]),
      createdAt: DateTime.parse(map["createdAt"]),
      createdBy: map["createdBy"] ?? "system",
      note: map["note"],
    );
  }
}