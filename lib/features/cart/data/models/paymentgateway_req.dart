class PaymentGatewayReq {
  PaymentGatewayReq({
    required this.siteId,
    required this.gatewayId,
    required this.amount,
    required this.cancelUrl,
    required this.currency,
    required this.customerName,
    required this.emiDuration,
    required this.emiInterest,
    required this.failUrl,
    required this.isCardTransaction,
    required this.isCodPayment,
    required this.isEmi,
    required this.merchantId,
    required this.payeeSource,
    required this.productInfo,
    required this.referenceId,
    required this.showRefundButton,
    required this.successUrl,
    required this.transactionType,
  });

  final int? siteId;
  final int? gatewayId;
  final int? amount;
  final String? cancelUrl;
  final String? currency;
  final String? customerName;
  final int? emiDuration;
  final int? emiInterest;
  final String? failUrl;
  final bool? isCardTransaction;
  final bool? isCodPayment;
  final bool? isEmi;
  final int? merchantId;
  final String? payeeSource;
  final String? productInfo;
  final String? referenceId;
  final bool? showRefundButton;
  final String? successUrl;
  final int? transactionType;

  factory PaymentGatewayReq.fromJson(Map<String, dynamic> json) {
    return PaymentGatewayReq(
      siteId: json["siteId"],
      gatewayId: json["gatewayId"],
      amount: json["amount"],
      cancelUrl: json["cancelUrl"],
      currency: json["currency"],
      customerName: json["customerName"],
      emiDuration: json["emiDuration"],
      emiInterest: json["emiInterest"],
      failUrl: json["failUrl"],
      isCardTransaction: json["isCardTransaction"],
      isCodPayment: json["isCodPayment"],
      isEmi: json["isEmi"],
      merchantId: json["merchantId"],
      payeeSource: json["payeeSource"],
      productInfo: json["productInfo"],
      referenceId: json["referenceId"],
      showRefundButton: json["showRefundButton"],
      successUrl: json["successUrl"],
      transactionType: json["transactionType"],
    );
  }

  Map<String, dynamic> toJson() => {
    "siteId": siteId,
    "gatewayId": gatewayId,
    "amount": amount,
    "cancelUrl": cancelUrl,
    "currency": currency,
    "customerName": customerName,
    "emiDuration": emiDuration,
    "emiInterest": emiInterest,
    "failUrl": failUrl,
    "isCardTransaction": isCardTransaction,
    "isCodPayment": isCodPayment,
    "isEmi": isEmi,
    "merchantId": merchantId,
    "payeeSource": payeeSource,
    "productInfo": productInfo,
    "referenceId": referenceId,
    "showRefundButton": showRefundButton,
    "successUrl": successUrl,
    "transactionType": transactionType,
  };
}
