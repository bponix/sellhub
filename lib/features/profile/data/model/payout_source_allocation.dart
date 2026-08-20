class PayoutSourceAllocation {
  const PayoutSourceAllocation({
    required this.id,
    required this.payoutRequestId,
    required this.walletLedgerId,
    required this.orderId,
    required this.sourceType,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String payoutRequestId;
  final String walletLedgerId;
  final int? orderId;
  final String sourceType;
  final double amount;
  final String status;
  final DateTime? createdAt;

  factory PayoutSourceAllocation.fromJson(Map<String, dynamic> json) {
    return PayoutSourceAllocation(
      id: '${json['id'] ?? ''}',
      payoutRequestId: '${json['payoutRequestId'] ?? ''}',
      walletLedgerId: '${json['walletLedgerId'] ?? ''}',
      orderId: (json['orderId'] as num?)?.toInt(),
      sourceType: '${json['sourceType'] ?? 'unknown'}',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: '${json['status'] ?? 'reserved'}',
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
    );
  }
}
