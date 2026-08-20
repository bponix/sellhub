class TeamMemberEntry {
  const TeamMemberEntry({
    required this.id,
    required this.teamId,
    required this.ownerUserId,
    required this.siteId,
    required this.name,
    required this.phone,
    required this.status,
    required this.role,
    required this.orderVolume,
    required this.overrideGenerated,
    required this.topProduct,
    required this.joinedAt,
    required this.lastActiveAt,
    this.inviteCode = '',
    this.buyerReachCount = 0,
    this.anonymousSupplierCount = 0,
    this.payoutImpact = 0,
  });

  final String id;
  final String teamId;
  final int ownerUserId;
  final int siteId;
  final String name;
  final String phone;
  final String status;
  final String role;
  final double orderVolume;
  final double overrideGenerated;
  final String topProduct;
  final DateTime? joinedAt;
  final DateTime? lastActiveAt;
  final String inviteCode;
  final int buyerReachCount;
  final int anonymousSupplierCount;
  final double payoutImpact;

  bool get isActive {
    final value = status.toLowerCase();
    return value == 'active' || value == 'accepted';
  }

  bool get isPending {
    final value = status.toLowerCase();
    return value == 'pending' || value == 'invited';
  }

  factory TeamMemberEntry.fromJson(Map<String, dynamic> json) {
    return TeamMemberEntry(
      id: '${json['id'] ?? ''}',
      teamId: (json['teamId'] as String?) ?? '',
      ownerUserId: (json['ownerUserId'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? 'Seller',
      phone: (json['phone'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      role: (json['role'] as String?) ?? 'team_seller',
      orderVolume: (json['orderVolume'] as num?)?.toDouble() ?? 0,
      overrideGenerated: (json['overrideGenerated'] as num?)?.toDouble() ?? 0,
      topProduct: (json['topProduct'] as String?) ?? '',
      joinedAt: DateTime.tryParse((json['joinedAt'] as String?) ?? ''),
      lastActiveAt: DateTime.tryParse((json['lastActiveAt'] as String?) ?? ''),
      inviteCode: (json['inviteCode'] as String?) ?? '',
      buyerReachCount: (json['buyerReachCount'] as num?)?.toInt() ?? 0,
      anonymousSupplierCount:
          (json['anonymousSupplierCount'] as num?)?.toInt() ?? 0,
      payoutImpact: (json['payoutImpact'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'teamId': teamId,
    'ownerUserId': ownerUserId,
    'siteId': siteId,
    'name': name,
    'phone': phone,
    'status': status,
    'role': role,
    'orderVolume': orderVolume,
    'overrideGenerated': overrideGenerated,
    'topProduct': topProduct,
    'joinedAt': joinedAt?.toIso8601String(),
    'lastActiveAt': lastActiveAt?.toIso8601String(),
    'inviteCode': inviteCode,
    'buyerReachCount': buyerReachCount,
    'anonymousSupplierCount': anonymousSupplierCount,
    'payoutImpact': payoutImpact,
  };
}
