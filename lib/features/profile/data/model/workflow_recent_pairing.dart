class WorkflowRecentPairing {
  const WorkflowRecentPairing({
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerAddress,
    required this.productTitle,
    required this.sellPrice,
    required this.orderId,
    required this.updatedAt,
  });

  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String buyerAddress;
  final String productTitle;
  final double sellPrice;
  final String orderId;
  final DateTime? updatedAt;
}
