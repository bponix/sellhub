class OrderEventModel {
  const OrderEventModel({
    required this.id,
    required this.createdAt,
    required this.eventType,
    required this.note,
    required this.isPublic,
    required this.address,
    required this.location,
  });

  final int id;
  final DateTime? createdAt;
  final int eventType;
  final String note;
  final bool isPublic;
  final String address;
  final String location;

  factory OrderEventModel.fromJson(Map<String, dynamic> json) {
    return OrderEventModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
      eventType: (json['eventType'] as num?)?.toInt() ?? 0,
      note: (json['note'] as String?) ?? '',
      isPublic: json['isPublic'] as bool? ?? false,
      address: (json['address'] as String?) ?? '',
      location: (json['location'] as String?) ?? '',
    );
  }
}
