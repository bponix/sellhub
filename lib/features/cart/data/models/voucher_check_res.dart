class VoucherCheckRes {
  const VoucherCheckRes({required this.discount, required this.message});

  final double discount;
  final String message;

  factory VoucherCheckRes.fromJson(Map<String, dynamic> json) {
    return VoucherCheckRes(
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      message: (json['message'] as String?) ?? '',
    );
  }
}
