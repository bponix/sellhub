class RepeatSellReminder {
  const RepeatSellReminder({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.productTitle,
    required this.district,
    required this.note,
    required this.scheduledFor,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String productTitle;
  final String district;
  final String note;
  final DateTime? scheduledFor;
  final DateTime? createdAt;
  final String status;

  bool get isDue =>
      status == 'open' &&
      scheduledFor != null &&
      !scheduledFor!.isAfter(DateTime.now());

  factory RepeatSellReminder.fromJson(Map<String, dynamic> json) {
    return RepeatSellReminder(
      id: '${json['id'] ?? ''}',
      buyerId: (json['buyerId'] as String?) ?? '',
      buyerName: (json['buyerName'] as String?) ?? 'Buyer',
      buyerPhone: (json['buyerPhone'] as String?) ?? '',
      productTitle: (json['productTitle'] as String?) ?? '',
      district: (json['district'] as String?) ?? '',
      note: (json['note'] as String?) ?? '',
      scheduledFor: DateTime.tryParse((json['scheduledFor'] as String?) ?? ''),
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
      status: (json['status'] as String?) ?? 'open',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'productTitle': productTitle,
      'district': district,
      'note': note,
      'scheduledFor': scheduledFor?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'status': status,
    };
  }
}
