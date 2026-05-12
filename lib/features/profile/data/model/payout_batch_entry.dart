class PayoutBatchEntry {
  const PayoutBatchEntry({
    required this.id,
    required this.userId,
    required this.siteId,
    required this.customerId,
    required this.status,
    required this.channel,
    required this.referenceId,
    required this.orderIds,
    required this.totalAmount,
    required this.deductionTotal,
    required this.netAmount,
    required this.note,
    required this.createdAt,
    required this.estimatedSettlementDate,
    required this.releasedAt,
    required this.paidAt,
  });

  final String id;
  final int userId;
  final int siteId;
  final int customerId;
  final String status;
  final String channel;
  final String referenceId;
  final List<String> orderIds;
  final double totalAmount;
  final double deductionTotal;
  final double netAmount;
  final String note;
  final DateTime? createdAt;
  final DateTime? estimatedSettlementDate;
  final DateTime? releasedAt;
  final DateTime? paidAt;

  factory PayoutBatchEntry.fromJson(Map<String, dynamic> json) {
    return PayoutBatchEntry(
      id: '${json['id'] ?? ''}',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'processing',
      channel: (json['channel'] as String?) ?? '',
      referenceId: (json['referenceId'] as String?) ?? '',
      orderIds: (json['orderIds'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => '$item')
          .toList(growable: false),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      deductionTotal: (json['deductionTotal'] as num?)?.toDouble() ?? 0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0,
      note: (json['note'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
      estimatedSettlementDate: DateTime.tryParse(
        (json['estimatedSettlementDate'] as String?) ?? '',
      ),
      releasedAt: DateTime.tryParse((json['releasedAt'] as String?) ?? ''),
      paidAt: DateTime.tryParse((json['paidAt'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'siteId': siteId,
      'customerId': customerId,
      'status': status,
      'channel': channel,
      'referenceId': referenceId,
      'orderIds': orderIds,
      'totalAmount': totalAmount,
      'deductionTotal': deductionTotal,
      'netAmount': netAmount,
      'note': note,
      'createdAt': createdAt?.toIso8601String(),
      'estimatedSettlementDate': estimatedSettlementDate?.toIso8601String(),
      'releasedAt': releasedAt?.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
    };
  }
}
