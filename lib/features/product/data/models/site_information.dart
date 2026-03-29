class SiteInformationRes {
  SiteInformationRes({
    required this.address,
    required this.coverImage,
    required this.createdAt,
    required this.createdById,
    required this.currency,
    required this.desktopLogo,
    required this.desktopTheme,
    required this.domain,
    required this.email,
    required this.favicon,
    required this.foot,
    required this.hostname,
    required this.id,
    required this.industry,

    required this.latitude,
    required this.locale,
    required this.longitude,

    required this.notice,

    required this.phone,
    required this.phoneLogo,

    required this.social,
    required this.street,
    required this.title,
    required this.subscription,
    required this.subscriptionFee,
    required this.theme,

    required this.version,
    required this.whiteLabel,
    required this.whiteLabelUrl,
    required this.withdraw,
    required this.createdBy,
  });

  final String? address;
  final String? coverImage;
  final DateTime? createdAt;
  final int? createdById;
  final String? currency;
  final String? desktopLogo;
  final String? desktopTheme;
  final String? domain;
  final String? email;
  final String? favicon;
  final String? foot;
  final String? hostname;
  final int? id;
  final Object? industry;
  final double? latitude;
  final String? locale;
  final double? longitude;

  final String? notice;

  final int? phone;
  final String? phoneLogo;

  final Social? social;
  final String? street;
  final String? title;
  final String? subscription;
  final double? subscriptionFee;
  final String? theme;

  final double? version;
  final String? whiteLabel;
  final String? whiteLabelUrl;
  final double? withdraw;
  final CreatedBy? createdBy;

  factory SiteInformationRes.fromJson(Map<String, dynamic> json) {
    return SiteInformationRes(
      address: json["address"],
      coverImage: json["coverImage"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      createdById: json["createdById"],
      currency: json["currency"],
      desktopLogo: json["desktopLogo"],
      desktopTheme: json["desktopTheme"],
      domain: json["domain"],
      email: json["email"],
      favicon: json["favicon"],
      foot: json["foot"],

      hostname: json["hostname"],
      id: json["id"],
      industry: json["industry"],

      latitude: json["latitude"],
      locale: json["locale"],
      longitude: json["longitude"],

      notice: json["notice"],

      phone: json["phone"],
      phoneLogo: json["phoneLogo"],

      social: json["social"] == null
          ? null
          : Social.fromJson(Map<String, dynamic>.from(json["social"])),
      street: json["street"],
      title: json['title'],
      subscription: json["subscription"],
      subscriptionFee: json["subscriptionFee"],
      theme: json["theme"],

      version: json["version"],
      whiteLabel: json["whiteLabel"],
      whiteLabelUrl: json["whiteLabelUrl"],
      withdraw: json["withdraw"],
      createdBy: json["createdBy"] == null
          ? null
          : CreatedBy.fromJson(Map<String, dynamic>.from(json["createdBy"])),
    );
  }

  Map<String, dynamic> toJson() => {
    "address": address,

    "coverImage": coverImage,
    "createdAt": createdAt?.toIso8601String(),
    "createdById": createdById,
    "currency": currency,
    "desktopLogo": desktopLogo,
    "desktopTheme": desktopTheme,
    "domain": domain,
    "email": email,
    "favicon": favicon,
    "foot": foot,
    "hostname": hostname,
    "id": id,
    "industry": industry,
    "latitude": latitude,
    "locale": locale,
    "longitude": longitude,
    "notice": notice,
    "phone": phone,
    "phoneLogo": phoneLogo,
    "social": social?.toJson(),
    "street": street,
    "title": title,
    "subscription": subscription,
    "subscriptionFee": subscriptionFee,
    "theme": theme,
    "version": version,
    "whiteLabel": whiteLabel,
    "whiteLabelUrl": whiteLabelUrl,
    "withdraw": withdraw,
    "createdBy": createdBy?.toJson(),
  };
}

class CreatedBy {
  CreatedBy({
    required this.address,
    required this.avatar,
    required this.country,
    required this.currency,
    required this.email,
    required this.firstName,
    required this.id,
    required this.isStaff,
    required this.name,
    required this.phone,
    required this.username,
  });

  final String? address;
  final String? avatar;
  final int? country;
  final String? currency;
  final String? email;
  final String? firstName;
  final int? id;
  final bool? isStaff;
  final String? name;
  final int? phone;
  final String? username;

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      address: json["address"],
      avatar: json["avatar"],
      country: json["country"],
      currency: json["currency"],
      email: json["email"],
      firstName: json["firstName"],
      id: json["id"],
      isStaff: json["isStaff"],
      name: json["name"],
      phone: json["phone"],
      username: json["username"],
    );
  }

  Map<String, dynamic> toJson() => {
    "address": address,
    "avatar": avatar,
    "country": country,
    "currency": currency,
    "email": email,
    "firstName": firstName,
    "id": id,
    "isStaff": isStaff,
    "name": name,
    "phone": phone,
    "username": username,
  };
}

class Social {
  Social({
    required this.facebook,
    required this.instagram,
    required this.twitter,
    required this.youtube,
  });

  final String? facebook;
  final String? instagram;
  final String? twitter;
  final String? youtube;

  factory Social.fromJson(Map<String, dynamic> json) {
    return Social(
      facebook: json["facebook"],
      instagram: json["instagram"],
      twitter: json["twitter"],
      youtube: json["youtube"],
    );
  }

  Map<String, dynamic> toJson() => {
    "facebook": facebook,
    "instagram": instagram,
    "twitter": twitter,
    "youtube": youtube,
  };
}
