class OrderIssueReport {
  const OrderIssueReport({
    required this.id,
    required this.siteId,
    required this.orderId,
    required this.issueType,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int siteId;
  final String orderId;
  final String issueType;
  final String note;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory OrderIssueReport.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return OrderIssueReport(
      id: (json['id'] as String? ?? '').trim(),
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      orderId: (json['orderId'] as String? ?? '').trim(),
      issueType: (json['issueType'] as String? ?? '').trim(),
      note: (json['note'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? 'open').trim(),
      createdAt:
          DateTime.tryParse((json['createdAt'] as String? ?? '').trim()) ?? now,
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String? ?? '').trim()) ?? now,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'siteId': siteId,
      'orderId': orderId,
      'issueType': issueType,
      'note': note,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
