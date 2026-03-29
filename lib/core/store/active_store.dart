class ActiveStore {
  const ActiveStore({
    required this.siteId,
    required this.domain,
    this.title,
    this.logoUrl,
    this.address,
    this.latitude,
    this.longitude,
  });

  final int siteId;
  final String domain;
  final String? title;
  final String? logoUrl;
  final String? address;
  final double? latitude;
  final double? longitude;

  factory ActiveStore.fromJson(Map<String, dynamic> json) {
    return ActiveStore(
      siteId: json['siteId'] as int,
      domain: json['domain'] as String,
      title: json['title'] as String?,
      logoUrl: json['logoUrl'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
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
  };

  ActiveStore copyWith({
    int? siteId,
    String? domain,
    String? title,
    String? logoUrl,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return ActiveStore(
      siteId: siteId ?? this.siteId,
      domain: domain ?? this.domain,
      title: title ?? this.title,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
