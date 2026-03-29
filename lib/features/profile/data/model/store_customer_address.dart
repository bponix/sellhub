class StoreCustomerAddressModel {
  const StoreCustomerAddressModel({
    required this.id,
    required this.address,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String address;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  factory StoreCustomerAddressModel.fromJson(Map<String, dynamic> json) {
    return StoreCustomerAddressModel(
      id: _toInt(json['id']) ?? 0,
      address: (json['address'] as String?) ?? '',
      formattedAddress: (json['formattedAddress'] as String?) ?? '',
      latitude: _toDouble(json['latitude']) ?? 0,
      longitude: _toDouble(json['longitude']) ?? 0,
    );
  }

  Map<String, dynamic> toInputJson() {
    return <String, dynamic>{
      'id': id,
      'address': address,
      'formattedAddress': formattedAddress,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
