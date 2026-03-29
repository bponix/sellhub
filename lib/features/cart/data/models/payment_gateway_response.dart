class PaymentGatewayResponse {
  PaymentGatewayResponse({
    required this.amount,
    required this.callBack,
    required this.cancelUrl,
    required this.currency,
    required this.customerName,
    required this.displayValue,
    required this.failUrl,
    required this.id,
    required this.isCaptured,
    required this.isPaid,
    required this.merchantId,
    required this.productInfo,
    required this.referenceId,
    required this.showRefundButton,
    required this.status,
    required this.successUrl,
    required this.transactionType,
    required this.transactionId,
  });

  final double? amount;
  final String? callBack;
  final String? cancelUrl;
  final String? currency;
  final String? customerName;
  final String? displayValue;
  final int? failUrl;
  final int? id;
  final bool? isCaptured;
  final bool? isPaid;
  final int? merchantId;
  final String? productInfo;
  final String? referenceId;
  final bool? showRefundButton;
  final int? status;
  final String? successUrl;
  final int? transactionType;
  final String? transactionId;

  factory PaymentGatewayResponse.fromJson(Map<String, dynamic> json) {
    return PaymentGatewayResponse(
      amount: _toDouble(json['amount']),
      callBack: json['callBack']?.toString(),
      cancelUrl: json['cancelUrl']?.toString(),
      currency: json['currency']?.toString(),
      customerName: json['customerName']?.toString(),
      displayValue: json['displayValue']?.toString(),
      failUrl: _toInt(json['failUrl']),
      id: _toInt(json['id']),
      isCaptured: json['isCaptured'] as bool?,
      isPaid: json['isPaid'] as bool?,
      merchantId: _toInt(json['merchantId']),
      productInfo: json['productInfo']?.toString(),
      referenceId: json['referenceId']?.toString(),
      showRefundButton: json['showRefundButton'] as bool?,
      status: _toInt(json['status']),
      successUrl: json['successUrl']?.toString(),
      transactionType: _toInt(json['transactionType']),
      transactionId: json['transactionId']?.toString(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
