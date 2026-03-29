class CustomerReviewResModel {
  CustomerReviewResModel({
    required this.createdAt,
    required this.description,
    required this.id,
    required this.rating,
    required this.userId,
    required this.user,
  });

  final DateTime? createdAt;
  final String? description;
  final int? id;
  final int? rating;
  final int? userId;
  final User? user;

  factory CustomerReviewResModel.fromJson(Map<String, dynamic> json) {
    return CustomerReviewResModel(
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      description: json["description"],
      id: json["id"],
      rating: json["rating"],
      userId: json["userId"],
      user: json["user"] == null ? null : User.fromJson(json["user"]),
    );
  }
}

class User {
  User({required this.id, required this.name, required this.avatar});

  final int? id;
  final String? name;
  final String? avatar;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json["id"], name: json["name"], avatar: json["avatar"]);
  }
}
