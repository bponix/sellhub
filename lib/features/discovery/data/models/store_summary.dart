import 'package:sellhub/core/store/active_store.dart';

class StoreSummary {
  const StoreSummary({
    required this.siteId,
    required this.domain,
    required this.title,
    this.logoUrl,
    this.coverImage,
    this.address,
    this.latitude,
    this.longitude,
    this.whiteLabelUrl,
  });

  final int siteId;
  final String domain;
  final String title;
  final String? logoUrl;
  final String? coverImage;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? whiteLabelUrl;

  factory StoreSummary.fromJson(Map<String, dynamic> json) {
    return StoreSummary(
      siteId: json['id'] as int,
      domain: (json['domain'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'Store',
      logoUrl: json['phoneLogo'] as String?,
      coverImage: json['coverImage'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      whiteLabelUrl: json['whiteLabelUrl'] as String?,
    );
  }

  ActiveStore toActiveStore() => ActiveStore(
    siteId: siteId,
    domain: domain,
    title: title,
    logoUrl: logoUrl,
    address: address,
    latitude: latitude,
    longitude: longitude,
  );
}
