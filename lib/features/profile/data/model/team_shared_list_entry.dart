class TeamSharedListEntry {
  const TeamSharedListEntry({
    required this.id,
    required this.teamId,
    required this.ownerUserId,
    required this.siteId,
    required this.title,
    required this.supplierName,
    required this.productTitles,
    required this.sharedWithMemberIds,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String teamId;
  final int ownerUserId;
  final int siteId;
  final String title;
  final String supplierName;
  final List<String> productTitles;
  final List<String> sharedWithMemberIds;
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TeamSharedListEntry.fromJson(Map<String, dynamic> json) {
    return TeamSharedListEntry(
      id: '${json['id'] ?? ''}',
      teamId: (json['teamId'] as String?) ?? '',
      ownerUserId: (json['ownerUserId'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? 'Shared list',
      supplierName: (json['supplierName'] as String?) ?? 'Supplier',
      productTitles:
          (json['productTitles'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => '$item')
              .where((item) => item.trim().isNotEmpty)
              .toList(growable: false),
      sharedWithMemberIds:
          (json['sharedWithMemberIds'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => '$item')
              .where((item) => item.trim().isNotEmpty)
              .toList(growable: false),
      note: (json['note'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'teamId': teamId,
    'ownerUserId': ownerUserId,
    'siteId': siteId,
    'title': title,
    'supplierName': supplierName,
    'productTitles': productTitles,
    'sharedWithMemberIds': sharedWithMemberIds,
    'note': note,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
