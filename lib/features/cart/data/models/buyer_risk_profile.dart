class BuyerRiskProfile {
  const BuyerRiskProfile({
    required this.id,
    required this.userId,
    required this.siteId,
    required this.buyerName,
    required this.buyerPhone,
    required this.riskLevel,
    required this.riskScore,
    required this.blocked,
    required this.note,
    required this.reasonCodes,
    required this.recommendedAction,
    required this.totalOrders,
    required this.deliveredOrders,
    required this.returnCount,
    required this.pendingOrders,
    required this.unpaidOrders,
    required this.lastOrderId,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final int siteId;
  final String buyerName;
  final String buyerPhone;
  final String riskLevel;
  final int riskScore;
  final bool blocked;
  final String note;
  final List<String> reasonCodes;
  final String recommendedAction;
  final int totalOrders;
  final int deliveredOrders;
  final int returnCount;
  final int pendingOrders;
  final int unpaidOrders;
  final String? lastOrderId;
  final DateTime? updatedAt;

  factory BuyerRiskProfile.fromJson(Map<String, dynamic> json) {
    return BuyerRiskProfile(
      id: '${json['id'] ?? ''}',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      buyerName: (json['buyerName'] as String?) ?? 'Buyer',
      buyerPhone: (json['buyerPhone'] as String?) ?? '',
      riskLevel: (json['riskLevel'] as String?) ?? 'low',
      riskScore: (json['riskScore'] as num?)?.toInt() ?? 0,
      blocked: json['blocked'] == true,
      note: (json['note'] as String?) ?? '',
      reasonCodes: (json['reasonCodes'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => '$item')
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false),
      recommendedAction: (json['recommendedAction'] as String?) ?? '',
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      deliveredOrders: (json['deliveredOrders'] as num?)?.toInt() ?? 0,
      returnCount: (json['returnCount'] as num?)?.toInt() ?? 0,
      pendingOrders: (json['pendingOrders'] as num?)?.toInt() ?? 0,
      unpaidOrders: (json['unpaidOrders'] as num?)?.toInt() ?? 0,
      lastOrderId: json['lastOrderId'] as String?,
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'siteId': siteId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'riskLevel': riskLevel,
      'riskScore': riskScore,
      'blocked': blocked,
      'note': note,
      'reasonCodes': reasonCodes,
      'recommendedAction': recommendedAction,
      'totalOrders': totalOrders,
      'deliveredOrders': deliveredOrders,
      'returnCount': returnCount,
      'pendingOrders': pendingOrders,
      'unpaidOrders': unpaidOrders,
      'lastOrderId': lastOrderId,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
