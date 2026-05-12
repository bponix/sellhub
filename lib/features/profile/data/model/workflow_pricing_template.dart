class WorkflowPricingTemplate {
  const WorkflowPricingTemplate({
    required this.id,
    required this.userId,
    required this.siteId,
    required this.name,
    required this.channel,
    required this.markupAmount,
    required this.markupPercent,
    required this.note,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final int siteId;
  final String name;
  final String channel;
  final double markupAmount;
  final double markupPercent;
  final String note;
  final DateTime? updatedAt;

  factory WorkflowPricingTemplate.fromJson(Map<String, dynamic> json) {
    return WorkflowPricingTemplate(
      id: '${json['id'] ?? ''}',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? 'Template',
      channel: (json['channel'] as String?) ?? 'General',
      markupAmount: (json['markupAmount'] as num?)?.toDouble() ?? 0,
      markupPercent: (json['markupPercent'] as num?)?.toDouble() ?? 0,
      note: (json['note'] as String?) ?? '',
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'userId': userId,
    'siteId': siteId,
    'name': name,
    'channel': channel,
    'markupAmount': markupAmount,
    'markupPercent': markupPercent,
    'note': note,
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
