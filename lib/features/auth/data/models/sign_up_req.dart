class SignUpReq {
  SignUpReq({
    required this.country,
    required this.currency,
    required this.firstName,
    required this.language,
    required this.lastName,
    required this.name,
    required this.password,
    required this.phone,
    required this.referedCode,
    required this.source,
    required this.username,
    required this.sourceId,
    required this.parentId,
  });

  final int? country;
  final String? currency;
  final String? firstName;
  final String? language;
  final String? lastName;
  final String? name;
  final String? password;
  final int? phone;
  final String? referedCode;
  final String? source;
  final String? username;
  final int? sourceId;
  final dynamic parentId;

  factory SignUpReq.fromJson(Map<String, dynamic> json) {
    return SignUpReq(
      country: json["country"],
      currency: json["currency"],
      firstName: json["firstName"],
      language: json["language"],
      lastName: json["lastName"],
      name: json["name"],
      password: json["password"],
      phone: json["phone"],
      referedCode: json["referedCode"],
      source: json["source"],
      username: json["username"],
      sourceId: json["sourceId"],
      parentId: json["parentId"],
    );
  }

  Map<String, dynamic> toJson() => {
    "country": country,
    "currency": currency,
    "firstName": firstName,
    "language": language,
    "lastName": lastName,
    "name": name,
    "password": password,
    "phone": phone,
    "referedCode": referedCode,
    "source": source,
    "username": username,
    "sourceId": sourceId,
    "parentId": parentId,
  };
}
