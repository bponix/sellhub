class PaymentResponse {
  final bool success;
  final String message;
  final String? transactionId;
  final String? paymentMethod;
  final double amount;

  PaymentResponse({
    required this.success,
    required this.message,
    this.transactionId,
    this.paymentMethod,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'amount': amount,
    };
  }
}
