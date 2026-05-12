import 'package:sellhub/core/supplier_trust/supplier_trust_model.dart';

class ActiveStore {
  const ActiveStore({
    required this.siteId,
    required this.domain,
    this.title,
    this.logoUrl,
    this.address,
    this.latitude,
    this.longitude,
    this.trustProfile,
  });

  final int siteId;
  final String domain;
  final String? title;
  final String? logoUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  final SupplierTrustProfile? trustProfile;

  factory ActiveStore.fromJson(Map<String, dynamic> json) {
    return ActiveStore(
      siteId: json['siteId'] as int,
      domain: json['domain'] as String,
      title: json['title'] as String?,
      logoUrl: json['logoUrl'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      trustProfile: json['trustProfile'] is Map<String, dynamic>
          ? SupplierTrustProfile.fromJson(json['trustProfile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'siteId': siteId,
    'domain': domain,
    'title': title,
    'logoUrl': logoUrl,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'trustProfile': trustProfile?.toJson(),
  };

  ActiveStore copyWith({
    int? siteId,
    String? domain,
    String? title,
    String? logoUrl,
    String? address,
    double? latitude,
    double? longitude,
    SupplierTrustProfile? trustProfile,
  }) {
    return ActiveStore(
      siteId: siteId ?? this.siteId,
      domain: domain ?? this.domain,
      title: title ?? this.title,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      trustProfile: trustProfile ?? this.trustProfile,
    );
  }
}
