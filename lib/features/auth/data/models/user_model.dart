import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 15)
class User extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String username;

  @HiveField(3)
  final String phone;

  @HiveField(4)
  final String email;

  @HiveField(5)
  final String address;

  @HiveField(6)
  final String? avatar;

  @HiveField(7)
  final int country;

  @HiveField(8)
  final String currency;

  @HiveField(9)
  final String firstName;

  @HiveField(10)
  final String formattedAddress;

  @HiveField(11)
  final bool isStaff;

  @HiveField(12)
  final bool isActive;

  @HiveField(13)
  final double latitude;

  @HiveField(14)
  final double longitude;

  @HiveField(15)
  final String? referCode;

  @HiveField(16)
  final String? referedCode;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.phone,
    required this.email,
    required this.address,
    required this.avatar,
    required this.country,
    required this.currency,
    required this.firstName,
    required this.formattedAddress,
    required this.isStaff,
    required this.isActive,
    required this.latitude,
    required this.longitude,
    required this.referCode,
    required this.referedCode,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      avatar: json['avatar'],
      country: json['country'] ?? 0,
      currency: json['currency'] ?? '',
      firstName: json['firstName'] ?? '',
      formattedAddress: json['formattedAddress'] ?? '',
      isStaff: json['isStaff'] ?? false,
      isActive: json['isActive'] ?? false,
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      referCode: json['referCode'],
      referedCode: json['referedCode'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'phone': phone,
    'email': email,
    'address': address,
    'avatar': avatar,
    'country': country,
    'currency': currency,
    'firstName': firstName,
    'formattedAddress': formattedAddress,
    'isStaff': isStaff,
    'isActive': isActive,
    'latitude': latitude,
    'longitude': longitude,
    'referCode': referCode,
    'referedCode': referedCode,
  };
}
