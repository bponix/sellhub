class CategoriesRes {
  CategoriesRes({
    required this.description,
    required this.createdAt,
    required this.categoriesResExternal,
    required this.id,
    required this.hid,
    required this.image,
    required this.cover,
    required this.isActive,
    required this.isExternal,
    required this.isParent,
    required this.isPrivate,
    required this.priority,
    required this.siteId,
    required this.slug,
    required this.title,
    required this.total,
    required this.translation,
    required this.updatedAt,
  });

  final String? description;
  final DateTime? createdAt;
  final String? categoriesResExternal;
  final int? id;
  final String? hid;
  final String? image;
  final String? cover;
  final bool? isActive;
  final bool? isExternal;
  final bool? isParent;
  final bool? isPrivate;
  final int? priority;
  final int? siteId;
  final String? slug;
  final String? title;
  final int? total;
  final String? translation;
  final DateTime? updatedAt;

  factory CategoriesRes.fromJson(Map<String, dynamic> json) {
    return CategoriesRes(
      description: json["description"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      categoriesResExternal: json["external"],
      id: json["id"],
      hid: json["hid"],
      image: json["image"],
      cover: json["cover"],
      isActive: json["isActive"],
      isExternal: json["isExternal"],
      isParent: json["isParent"],
      isPrivate: json["isPrivate"],
      priority: json["priority"],
      siteId: json["siteId"],
      slug: json["slug"],
      title: json["title"],
      total: json["total"],
      translation: json["translation"],
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
    );
  }

  Map<String, dynamic> toJson() => {
    "description": description,
    "createdAt": createdAt?.toIso8601String(),
    "external": categoriesResExternal,
    "id": id,
    "hid": hid,
    "image": image,
    "cover": cover,
    "isActive": isActive,
    "isExternal": isExternal,
    "isParent": isParent,
    "isPrivate": isPrivate,
    "priority": priority,
    "siteId": siteId,
    "slug": slug,
    "title": title,
    "total": total,
    "translation": translation,
    "updatedAt": updatedAt?.toIso8601String(),
  };
}
