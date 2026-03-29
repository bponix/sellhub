class SubmitReviewReq {
  SubmitReviewReq({
    required this.userId,
    required this.siteId,
    required this.productId,
    required this.description,
    required this.rating,
    required this.feedbackType,
    required this.status,
    required this.image,
    required this.feedbacker,
  });

  final int? userId;
  final int? siteId;
  final int? productId;
  final String? description;
  final int? rating;
  final String? feedbackType;
  final String? status;
  final dynamic image;
  final String? feedbacker;

  factory SubmitReviewReq.fromJson(Map<String, dynamic> json) {
    return SubmitReviewReq(
      userId: json["userId"],
      siteId: json["siteId"],
      productId: json["productId"],
      description: json["description"],
      rating: json["rating"],
      feedbackType: json["feedbackType"],
      status: json["status"],
      image: json["image"],
      feedbacker: json["feedbacker"],
    );
  }

  Map<String, dynamic> toJson() => {
    "userId": userId,
    "siteId": siteId,
    "productId": productId,
    "description": description,
    "rating": rating,
    "feedbackType": feedbackType,
    "status": status,
    "image": image,
    "feedbacker": feedbacker,
  };
}
