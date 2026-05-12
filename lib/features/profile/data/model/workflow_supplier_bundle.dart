class WorkflowSupplierBundle {
  const WorkflowSupplierBundle({
    required this.id,
    required this.userId,
    required this.siteId,
    required this.supplierName,
    required this.name,
    required this.productTitles,
    required this.note,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final int siteId;
  final String supplierName;
  final String name;
  final List<String> productTitles;
  final String note;
  final DateTime? updatedAt;

  factory WorkflowSupplierBundle.fromJson(Map<String, dynamic> json) {
    return WorkflowSupplierBundle(
      id: '${json['id'] ?? ''}',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      supplierName: (json['supplierName'] as String?) ?? 'Supplier',
      name: (json['name'] as String?) ?? 'Bundle',
      productTitles:
          (json['productTitles'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => '$item')
              .where((item) => item.trim().isNotEmpty)
              .toList(growable: false),
      note: (json['note'] as String?) ?? '',
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'userId': userId,
    'siteId': siteId,
    'supplierName': supplierName,
    'name': name,
    'productTitles': productTitles,
    'note': note,
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
