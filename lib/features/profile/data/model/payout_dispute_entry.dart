class PayoutDisputeEntry {
  const PayoutDisputeEntry({
    required this.id,
    required this.userId,
    required this.siteId,
    required this.orderId,
    required this.batchId,
    required this.status,
    required this.reason,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final int siteId;
  final String orderId;
  final String? batchId;
  final String status;
  final String reason;
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PayoutDisputeEntry.fromJson(Map<String, dynamic> json) {
    return PayoutDisputeEntry(
      id: '${json['id'] ?? ''}',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      orderId: '${json['orderId'] ?? ''}',
      batchId: json['batchId']?.toString(),
      status: (json['status'] as String?) ?? 'open',
      reason: (json['reason'] as String?) ?? 'Mismatch',
      note: (json['note'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'siteId': siteId,
      'orderId': orderId,
      'batchId': batchId,
      'status': status,
      'reason': reason,
      'note': note,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
