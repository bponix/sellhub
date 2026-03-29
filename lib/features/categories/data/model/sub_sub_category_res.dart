class SubSubCategoryRes {
  SubSubCategoryRes({
    required this.categoryId,
    required this.id,
    required this.hid,
    required this.image,
    required this.isActive,
    required this.isPrivate,
    required this.priority,
    required this.slug,
    required this.subCategoryId,
    required this.title,
    required this.translation,
    required this.siteId,
    required this.updatedAt,
  });

  final int? categoryId;
  final int? id;
  final String? hid;
  final String? image;
  final bool? isActive;
  final bool? isPrivate;
  final int? priority;
  final String? slug;
  final int? subCategoryId;
  final String? title;
  final String? translation;
  final int? siteId;
  final DateTime? updatedAt;

  factory SubSubCategoryRes.fromJson(Map<String, dynamic> json) {
    return SubSubCategoryRes(
      categoryId: json["categoryId"],
      id: json["id"],
      hid: json["hid"],
      image: json["image"],
      isActive: json["isActive"],
      isPrivate: json["isPrivate"],
      priority: json["priority"],
      slug: json["slug"],
      subCategoryId: json["subCategoryId"],
      title: json["title"],
      translation: json["translation"],
      siteId: json["siteId"],
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
    );
  }

  Map<String, dynamic> toJson() => {
    "categoryId": categoryId,
    "id": id,
    "hid": hid,
    "image": image,
    "isActive": isActive,
    "isPrivate": isPrivate,
    "priority": priority,
    "slug": slug,
    "subCategoryId": subCategoryId,
    "title": title,
    "translation": translation,
    "siteId": siteId,
    "updatedAt": updatedAt?.toIso8601String(),
  };
}
