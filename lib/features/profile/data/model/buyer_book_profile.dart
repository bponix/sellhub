class BuyerBookProfile {
  const BuyerBookProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.addresses,
    required this.primaryAddress,
    required this.note,
    required this.sourceTag,
    required this.isRisky,
    required this.isBlocked,
    required this.totalOrders,
    required this.totalDelivered,
    required this.returnCount,
    required this.pendingOrders,
    required this.unpaidOrders,
    required this.totalSales,
    required this.averageBasketSize,
    required this.lastOrderedAt,
    required this.profileMetaUpdatedAt,
    required this.preferredProducts,
    required this.district,
    required this.deliveryZone,
    required this.lastOrderId,
  });

  final String id;
  final String name;
  final String phone;
  final List<String> addresses;
  final String primaryAddress;
  final String note;
  final String sourceTag;
  final bool isRisky;
  final bool isBlocked;
  final int totalOrders;
  final int totalDelivered;
  final int returnCount;
  final int pendingOrders;
  final int unpaidOrders;
  final double totalSales;
  final double averageBasketSize;
  final DateTime? lastOrderedAt;
  final DateTime? profileMetaUpdatedAt;
  final List<String> preferredProducts;
  final String district;
  final String deliveryZone;
  final String? lastOrderId;

  double get returnRate =>
      totalOrders <= 0 ? 0 : (returnCount / totalOrders) * 100;
  bool get isRepeatBuyer => totalOrders >= 2;
  bool get hasPendingBuyerRisk => pendingOrders > 0 || unpaidOrders > 0;
  bool get hasProfileMeta => profileMetaUpdatedAt != null;

  factory BuyerBookProfile.fromJson(Map<String, dynamic> json) {
    return BuyerBookProfile(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Unnamed buyer',
      phone: (json['phone'] as String?) ?? '',
      addresses: (json['addresses'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false),
      primaryAddress: (json['primaryAddress'] as String?) ?? '',
      note: (json['note'] as String?) ?? '',
      sourceTag: (json['sourceTag'] as String?) ?? 'Repeat',
      isRisky: json['isRisky'] == true,
      isBlocked: json['isBlocked'] == true,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      totalDelivered: (json['totalDelivered'] as num?)?.toInt() ?? 0,
      returnCount: (json['returnCount'] as num?)?.toInt() ?? 0,
      pendingOrders: (json['pendingOrders'] as num?)?.toInt() ?? 0,
      unpaidOrders: (json['unpaidOrders'] as num?)?.toInt() ?? 0,
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
      averageBasketSize: (json['averageBasketSize'] as num?)?.toDouble() ?? 0,
      lastOrderedAt: DateTime.tryParse(
        (json['lastOrderedAt'] as String?) ?? '',
      ),
      profileMetaUpdatedAt: DateTime.tryParse(
        (json['profileMetaUpdatedAt'] as String?) ?? '',
      ),
      preferredProducts:
          (json['preferredProducts'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList(growable: false),
      district: (json['district'] as String?) ?? '',
      deliveryZone: (json['deliveryZone'] as String?) ?? '',
      lastOrderId: json['lastOrderId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'phone': phone,
      'addresses': addresses,
      'primaryAddress': primaryAddress,
      'note': note,
      'sourceTag': sourceTag,
      'isRisky': isRisky,
      'isBlocked': isBlocked,
      'totalOrders': totalOrders,
      'totalDelivered': totalDelivered,
      'returnCount': returnCount,
      'pendingOrders': pendingOrders,
      'unpaidOrders': unpaidOrders,
      'totalSales': totalSales,
      'averageBasketSize': averageBasketSize,
      'lastOrderedAt': lastOrderedAt?.toIso8601String(),
      'profileMetaUpdatedAt': profileMetaUpdatedAt?.toIso8601String(),
      'preferredProducts': preferredProducts,
      'district': district,
      'deliveryZone': deliveryZone,
      'lastOrderId': lastOrderId,
    };
  }
}
