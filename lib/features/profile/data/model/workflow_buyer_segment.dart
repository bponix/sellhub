class WorkflowBuyerSegment {
  const WorkflowBuyerSegment({
    required this.id,
    required this.userId,
    required this.siteId,
    required this.name,
    required this.description,
    required this.buyerCount,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final int siteId;
  final String name;
  final String description;
  final int buyerCount;
  final DateTime? updatedAt;

  factory WorkflowBuyerSegment.fromJson(Map<String, dynamic> json) {
    return WorkflowBuyerSegment(
      id: '${json['id'] ?? ''}',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? 'Segment',
      description: (json['description'] as String?) ?? '',
      buyerCount: (json['buyerCount'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'userId': userId,
    'siteId': siteId,
    'name': name,
    'description': description,
    'buyerCount': buyerCount,
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
