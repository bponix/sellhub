class OrderGroupDraft {
  const OrderGroupDraft({
    required this.id,
    required this.userId,
    required this.siteId,
    required this.title,
    required this.status,
    required this.channel,
    required this.buyerIds,
    required this.quickOrderDraftIds,
    required this.tags,
    required this.note,
    required this.targetOrderCount,
    required this.projectedRevenue,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final int siteId;
  final String title;
  final String status;
  final String channel;
  final List<String> buyerIds;
  final List<String> quickOrderDraftIds;
  final List<String> tags;
  final String note;
  final int targetOrderCount;
  final int projectedRevenue;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory OrderGroupDraft.fromJson(Map<String, dynamic> json) {
    return OrderGroupDraft(
      id: '${json['id'] ?? ''}',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? 'Order group',
      status: (json['status'] as String?) ?? 'draft',
      channel: (json['channel'] as String?) ?? '',
      buyerIds: (json['buyerIds'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => '$item')
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false),
      quickOrderDraftIds:
          (json['quickOrderDraftIds'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => '$item')
              .where((item) => item.trim().isNotEmpty)
              .toList(growable: false),
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => '$item')
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false),
      note: (json['note'] as String?) ?? '',
      targetOrderCount: (json['targetOrderCount'] as num?)?.toInt() ?? 0,
      projectedRevenue: (json['projectedRevenue'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'siteId': siteId,
      'title': title,
      'status': status,
      'channel': channel,
      'buyerIds': buyerIds,
      'quickOrderDraftIds': quickOrderDraftIds,
      'tags': tags,
      'note': note,
      'targetOrderCount': targetOrderCount,
      'projectedRevenue': projectedRevenue,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
