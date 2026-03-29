class TopBrandRes {
  TopBrandRes({
    required this.description,
    required this.hid,
    required this.id,
    required this.image,
    required this.isActive,
    required this.isPrivate,
    required this.priority,
    required this.siteId,
    required this.slug,
    required this.title,
    required this.translation,
    required this.updatedAt,
  });

  final String? description;
  final String? hid;
  final int? id;
  final String? image;
  final bool? isActive;
  final bool? isPrivate;
  final int? priority;
  final int? siteId;
  final String? slug;
  final String? title;
  final String? translation;
  final DateTime? updatedAt;

  factory TopBrandRes.fromJson(Map<String, dynamic> json) {
    return TopBrandRes(
      description: json["description"],
      hid: json["hid"],
      id: json["id"],
      image: json["image"],
      isActive: json["isActive"],
      isPrivate: json["isPrivate"],
      priority: json["priority"],
      siteId: json["siteId"],
      slug: json["slug"],
      title: json["title"],
      translation: json["translation"],
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
    );
  }

  Map<String, dynamic> toJson() => {
    "description": description,
    "hid": hid,
    "id": id,
    "image": image,
    "isActive": isActive,
    "isPrivate": isPrivate,
    "priority": priority,
    "siteId": siteId,
    "slug": slug,
    "title": title,
    "translation": translation,
    "updatedAt": updatedAt?.toIso8601String(),
  };
}
