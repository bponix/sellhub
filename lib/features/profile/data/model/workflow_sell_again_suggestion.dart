class WorkflowSellAgainSuggestion {
  const WorkflowSellAgainSuggestion({
    required this.productTitle,
    required this.lastBuyerName,
    required this.lastBuyerPhone,
    required this.lastBuyerAddress,
    required this.lastSellPrice,
    required this.repeatCount,
    required this.lastOrderedAt,
    required this.reason,
  });

  final String productTitle;
  final String lastBuyerName;
  final String lastBuyerPhone;
  final String lastBuyerAddress;
  final double lastSellPrice;
  final int repeatCount;
  final DateTime? lastOrderedAt;
  final String reason;
}
