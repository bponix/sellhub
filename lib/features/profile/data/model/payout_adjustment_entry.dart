class PayoutAdjustmentEntry {
  const PayoutAdjustmentEntry({
    required this.id,
    required this.userId,
    required this.siteId,
    required this.orderId,
    required this.type,
    required this.label,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final int userId;
  final int siteId;
  final String orderId;
  final String type;
  final String label;
  final double amount;
  final String note;
  final DateTime? createdAt;

  factory PayoutAdjustmentEntry.fromJson(Map<String, dynamic> json) {
    return PayoutAdjustmentEntry(
      id: '${json['id'] ?? ''}',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      orderId: '${json['orderId'] ?? ''}',
      type: (json['type'] as String?) ?? 'adjustment',
      label: (json['label'] as String?) ?? 'Adjustment',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      note: (json['note'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'siteId': siteId,
      'orderId': orderId,
      'type': type,
      'label': label,
      'amount': amount,
      'note': note,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
