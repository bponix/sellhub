class ResellerPayoutReadiness {
  const ResellerPayoutReadiness({
    required this.siteId,
    required this.resellerId,
    required this.pendingAmount,
    required this.withdrawableAmount,
    required this.pendingPayoutAmount,
    required this.paidAmount,
    required this.requestedPayoutAmount,
    required this.processingPayoutAmount,
    required this.settledPayoutAmount,
    required this.blockedPayoutAmount,
    required this.disputedAmount,
    required this.reversedAmount,
    required this.proofNeededAmount,
    required this.openPayoutCount,
    required this.blockedPayoutCount,
    required this.canWithdraw,
    required this.primaryStatus,
    required this.primaryAction,
    required this.buckets,
    this.lastPayoutRequestedAt,
    this.lastPayoutSettledAt,
    this.routeTarget,
  });

  final int siteId;
  final String resellerId;
  final double pendingAmount;
  final double withdrawableAmount;
  final double pendingPayoutAmount;
  final double paidAmount;
  final double requestedPayoutAmount;
  final double processingPayoutAmount;
  final double settledPayoutAmount;
  final double blockedPayoutAmount;
  final double disputedAmount;
  final double reversedAmount;
  final double proofNeededAmount;
  final int openPayoutCount;
  final int blockedPayoutCount;
  final DateTime? lastPayoutRequestedAt;
  final DateTime? lastPayoutSettledAt;
  final bool canWithdraw;
  final String primaryStatus;
  final String primaryAction;
  final String? routeTarget;
  final List<ResellerPayoutBucket> buckets;

  factory ResellerPayoutReadiness.fromJson(Map<String, dynamic> json) =>
      ResellerPayoutReadiness(
        siteId: (json['siteId'] as num?)?.toInt() ?? 0,
        resellerId: '${json['resellerId'] ?? ''}',
        pendingAmount: _money(json['pendingAmount']),
        withdrawableAmount: _money(json['withdrawableAmount']),
        pendingPayoutAmount: _money(json['pendingPayoutAmount']),
        paidAmount: _money(json['paidAmount']),
        requestedPayoutAmount: _money(json['requestedPayoutAmount']),
        processingPayoutAmount: _money(json['processingPayoutAmount']),
        settledPayoutAmount: _money(json['settledPayoutAmount']),
        blockedPayoutAmount: _money(json['blockedPayoutAmount']),
        disputedAmount: _money(json['disputedAmount']),
        reversedAmount: _money(json['reversedAmount']),
        proofNeededAmount: _money(json['proofNeededAmount']),
        openPayoutCount: (json['openPayoutCount'] as num?)?.toInt() ?? 0,
        blockedPayoutCount: (json['blockedPayoutCount'] as num?)?.toInt() ?? 0,
        lastPayoutRequestedAt: _date(json['lastPayoutRequestedAt']),
        lastPayoutSettledAt: _date(json['lastPayoutSettledAt']),
        canWithdraw: json['canWithdraw'] == true,
        primaryStatus: json['primaryStatus'] as String? ?? 'pending',
        primaryAction:
            json['primaryAction'] as String? ?? 'Review payout state',
        routeTarget: json['routeTarget'] as String?,
        buckets: (json['buckets'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (row) =>
                  ResellerPayoutBucket.fromJson(Map<String, dynamic>.from(row)),
            )
            .toList(growable: false),
      );

  static double _money(dynamic value) => (value as num?)?.toDouble() ?? 0;
  static DateTime? _date(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '');
}

class ResellerPayoutBucket {
  const ResellerPayoutBucket({required this.key, required this.amount});
  final String key;
  final double amount;

  factory ResellerPayoutBucket.fromJson(Map<String, dynamic> json) =>
      ResellerPayoutBucket(
        key: json['key'] as String? ?? 'unknown',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}
