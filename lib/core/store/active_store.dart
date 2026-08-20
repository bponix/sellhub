import 'package:sellhub/core/supplier_trust/supplier_trust_model.dart';
import 'package:sellhub/core/market/store_market_settings.dart';

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
    this.market = const StoreMarketSettings(),
  });

  final int siteId;
  final String domain;
  final String? title;
  final String? logoUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  final SupplierTrustProfile? trustProfile;
  final StoreMarketSettings market;

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
          ? SupplierTrustProfile.fromJson(
              json['trustProfile'] as Map<String, dynamic>,
            )
          : null,
      market: json['market'] is Map<String, dynamic>
          ? StoreMarketSettings.fromJson(json['market'] as Map<String, dynamic>)
          : const StoreMarketSettings(),
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
    'market': market.toJson(),
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
    StoreMarketSettings? market,
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
      market: market ?? this.market,
    );
  }
}
