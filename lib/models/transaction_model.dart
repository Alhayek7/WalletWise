class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String note;
  final String method;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.note,
    required this.method,
    required this.date,
  });

  // تحويل من Firestore document إلى Model
  factory TransactionModel.fromFirestore(String id, Map<String, dynamic> data) {
    return TransactionModel(
      id: id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? 'أخرى',
      note: data['note'] ?? '',
      method: data['method'] ?? 'يدوي',
      date: (data['date'] as dynamic).toDate(),
    );
  }

  // تحويل إلى Map للحفظ في Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'category': category,
      'note': note,
      'method': method,
      'date': date,
    };
  }
}