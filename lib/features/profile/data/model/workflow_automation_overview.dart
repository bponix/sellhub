import 'package:sellhub/features/profile/data/model/workflow_buyer_segment.dart';
import 'package:sellhub/features/profile/data/model/workflow_pricing_template.dart';
import 'package:sellhub/features/profile/data/model/workflow_recent_pairing.dart';
import 'package:sellhub/features/profile/data/model/workflow_sell_again_suggestion.dart';
import 'package:sellhub/features/profile/data/model/workflow_supplier_bundle.dart';

class WorkflowAutomationOverview {
  const WorkflowAutomationOverview({
    required this.pricingTemplates,
    required this.supplierBundles,
    required this.buyerSegments,
    required this.recentPairings,
    required this.sellAgainSuggestions,
  });

  final List<WorkflowPricingTemplate> pricingTemplates;
  final List<WorkflowSupplierBundle> supplierBundles;
  final List<WorkflowBuyerSegment> buyerSegments;
  final List<WorkflowRecentPairing> recentPairings;
  final List<WorkflowSellAgainSuggestion> sellAgainSuggestions;
}
