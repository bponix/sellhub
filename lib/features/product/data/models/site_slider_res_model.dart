class SiteSliderRes {
  SiteSliderRes({
    required this.body,
    required this.cover,
    required this.id,
    required this.isActive,
    required this.isPrivate,
    required this.isPhone,
    required this.priority,
    required this.siteId,
    required this.title,
    required this.updatedAt,
    required this.url,
  });

  final String? body;
  final String? cover;
  final int? id;
  final bool? isActive;
  final bool? isPrivate;
  final bool? isPhone;
  final int? priority;
  final int? siteId;
  final String? title;
  final DateTime? updatedAt;
  final String? url;

  factory SiteSliderRes.fromJson(Map<String, dynamic> json) {
    return SiteSliderRes(
      body: json["body"],
      cover: json["cover"],
      id: json["id"],
      isActive: json["isActive"],
      isPrivate: json["isPrivate"],
      isPhone: json["isPhone"],
      priority: json["priority"],
      siteId: json["siteId"],
      title: json["title"],
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
      url: json["url"],
    );
  }

  Map<String, dynamic> toJson() => {
    "body": body,
    "cover": cover,
    "id": id,
    "isActive": isActive,
    "isPrivate": isPrivate,
    "isPhone": isPhone,
    "priority": priority,
    "siteId": siteId,
    "title": title,
    "updatedAt": updatedAt?.toIso8601String(),
    "url": url,
  };
}
