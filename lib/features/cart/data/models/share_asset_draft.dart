class ShareAssetDraft {
  const ShareAssetDraft({
    required this.id,
    required this.userId,
    required this.siteId,
    required this.title,
    required this.channel,
    required this.assetType,
    required this.assetUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.callToAction,
    required this.targetBuyerIds,
    required this.productTitles,
    required this.tags,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final int siteId;
  final String title;
  final String channel;
  final String assetType;
  final String assetUrl;
  final String thumbnailUrl;
  final String caption;
  final String callToAction;
  final List<String> targetBuyerIds;
  final List<String> productTitles;
  final List<String> tags;
  final String status;
  final DateTime? updatedAt;

  factory ShareAssetDraft.fromJson(Map<String, dynamic> json) {
    return ShareAssetDraft(
      id: '${json['id'] ?? ''}',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? 'Share asset',
      channel: (json['channel'] as String?) ?? '',
      assetType: (json['assetType'] as String?) ?? 'image',
      assetUrl: (json['assetUrl'] as String?) ?? '',
      thumbnailUrl: (json['thumbnailUrl'] as String?) ?? '',
      caption: (json['caption'] as String?) ?? '',
      callToAction: (json['callToAction'] as String?) ?? '',
      targetBuyerIds:
          (json['targetBuyerIds'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => '$item')
              .where((item) => item.trim().isNotEmpty)
              .toList(growable: false),
      productTitles:
          (json['productTitles'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => '$item')
              .where((item) => item.trim().isNotEmpty)
              .toList(growable: false),
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => '$item')
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false),
      status: (json['status'] as String?) ?? 'draft',
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'siteId': siteId,
      'title': title,
      'channel': channel,
      'assetType': assetType,
      'assetUrl': assetUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'callToAction': callToAction,
      'targetBuyerIds': targetBuyerIds,
      'productTitles': productTitles,
      'tags': tags,
      'status': status,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
