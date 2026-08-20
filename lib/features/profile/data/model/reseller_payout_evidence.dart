class ResellerPayoutEvidence {
  const ResellerPayoutEvidence({
    required this.status,
    required this.nextAction,
    required this.expectedProfit,
    required this.walletCreditedAmount,
    required this.allocatedAmount,
    required this.paidAmount,
    required this.releasedAmount,
    required this.disputedAmount,
    required this.reversedAmount,
    required this.orderProofGap,
    required this.payoutAllocationGap,
    required this.blockers,
    required this.allocationCount,
    required this.disputeCount,
  });

  final String status;
  final String nextAction;
  final double expectedProfit;
  final double walletCreditedAmount;
  final double allocatedAmount;
  final double paidAmount;
  final double releasedAmount;
  final double disputedAmount;
  final double reversedAmount;
  final double orderProofGap;
  final double payoutAllocationGap;
  final List<String> blockers;
  final int allocationCount;
  final int disputeCount;

  factory ResellerPayoutEvidence.fromJson(Map<String, dynamic> json) {
    double money(String key) => (json[key] as num?)?.toDouble() ?? 0;
    final allocations = json['allocations'];
    final disputes = json['disputes'];
    return ResellerPayoutEvidence(
      status: json['status'] as String? ?? 'proof_needed',
      nextAction: json['nextAction'] as String? ?? 'Review money proof',
      expectedProfit: money('expectedProfit'),
      walletCreditedAmount: money('walletCreditedAmount'),
      allocatedAmount: money('allocatedAmount'),
      paidAmount: money('paidAmount'),
      releasedAmount: money('releasedAmount'),
      disputedAmount: money('disputedAmount'),
      reversedAmount: money('reversedAmount'),
      orderProofGap: money('orderProofGap'),
      payoutAllocationGap: money('payoutAllocationGap'),
      blockers:
          (json['blockers'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const <String>[],
      allocationCount: allocations is List ? allocations.length : 0,
      disputeCount: disputes is List ? disputes.length : 0,
    );
  }
}
