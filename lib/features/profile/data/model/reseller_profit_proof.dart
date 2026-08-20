class ResellerProfitProof {
  const ResellerProfitProof({
    required this.proofStatus,
    required this.orderTotal,
    required this.orderResellAmount,
    required this.orderResellerCommission,
    required this.orderResellerIsPaid,
    required this.lineSummary,
    required this.buckets,
    required this.proofRows,
    this.quoteId,
    this.conversionStatus,
  });

  final String proofStatus;
  final double orderTotal;
  final double orderResellAmount;
  final double orderResellerCommission;
  final bool orderResellerIsPaid;
  final int? quoteId;
  final String? conversionStatus;
  final ResellerProfitLineSummary? lineSummary;
  final List<ResellerProfitBucket> buckets;
  final List<ResellerProfitProofRow> proofRows;

  factory ResellerProfitProof.fromJson(Map<String, dynamic> json) =>
      ResellerProfitProof(
        proofStatus: json['proofStatus'] as String? ?? 'proof_needed',
        orderTotal: _money(json['orderTotal']),
        orderResellAmount: _money(json['orderResellAmount']),
        orderResellerCommission: _money(json['orderResellerCommission']),
        orderResellerIsPaid: json['orderResellerIsPaid'] == true,
        quoteId: (json['quoteId'] as num?)?.toInt(),
        conversionStatus: json['conversionStatus'] as String?,
        lineSummary: json['lineSummary'] is Map
            ? ResellerProfitLineSummary.fromJson(
                Map<String, dynamic>.from(json['lineSummary'] as Map),
              )
            : null,
        buckets: (json['buckets'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (row) =>
                  ResellerProfitBucket.fromJson(Map<String, dynamic>.from(row)),
            )
            .toList(growable: false),
        proofRows: (json['proofRows'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (row) => ResellerProfitProofRow.fromJson(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList(growable: false),
      );

  static double _money(dynamic value) => (value as num?)?.toDouble() ?? 0;
}

class ResellerProfitLineSummary {
  const ResellerProfitLineSummary({
    required this.lineCount,
    required this.supplierCount,
    required this.quantityTotal,
    required this.baseTotal,
    required this.buyerTotal,
    required this.grossProfit,
    required this.orderCommission,
    required this.expectedProfit,
  });
  final int lineCount;
  final int supplierCount;
  final double quantityTotal;
  final double baseTotal;
  final double buyerTotal;
  final double grossProfit;
  final double orderCommission;
  final double expectedProfit;
  factory ResellerProfitLineSummary.fromJson(Map<String, dynamic> json) =>
      ResellerProfitLineSummary(
        lineCount: (json['lineCount'] as num?)?.toInt() ?? 0,
        supplierCount: (json['supplierCount'] as num?)?.toInt() ?? 0,
        quantityTotal: (json['quantityTotal'] as num?)?.toDouble() ?? 0,
        baseTotal: (json['baseTotal'] as num?)?.toDouble() ?? 0,
        buyerTotal: (json['buyerTotal'] as num?)?.toDouble() ?? 0,
        grossProfit: (json['grossProfit'] as num?)?.toDouble() ?? 0,
        orderCommission: (json['orderCommission'] as num?)?.toDouble() ?? 0,
        expectedProfit: (json['expectedProfit'] as num?)?.toDouble() ?? 0,
      );
}

class ResellerProfitBucket {
  const ResellerProfitBucket({required this.key, required this.amount});
  final String key;
  final double amount;
  factory ResellerProfitBucket.fromJson(Map<String, dynamic> json) =>
      ResellerProfitBucket(
        key: json['key'] as String? ?? 'unknown',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}

class ResellerProfitProofRow {
  const ResellerProfitProofRow({
    required this.source,
    required this.status,
    required this.amount,
    this.refType,
    this.refId,
    this.createdAt,
  });
  final String source;
  final String status;
  final double amount;
  final String? refType;
  final String? refId;
  final DateTime? createdAt;
  factory ResellerProfitProofRow.fromJson(Map<String, dynamic> json) =>
      ResellerProfitProofRow(
        source: json['source'] as String? ?? 'unknown',
        status: json['status'] as String? ?? 'unknown',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        refType: json['refType'] as String?,
        refId: json['refId']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}
