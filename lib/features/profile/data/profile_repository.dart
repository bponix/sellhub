import 'package:sellhub/core/local_seed/sellhub_commerce_local_store.dart';
import 'package:sellhub/features/profile/data/model/buyer_book_profile.dart';
import 'package:sellhub/features/profile/data/model/order_res_model.dart';
import 'package:sellhub/features/profile/data/model/payout_adjustment_entry.dart';
import 'package:sellhub/features/profile/data/model/payout_batch_entry.dart';
import 'package:sellhub/features/profile/data/model/payout_dispute_entry.dart';
import 'package:sellhub/features/profile/data/model/profile_res-Model.dart';
import 'package:sellhub/features/profile/data/model/reseller_response_model.dart';
import 'package:sellhub/features/profile/data/model/self_store_customer.dart';
import 'package:sellhub/features/profile/data/model/store_customer_address.dart';
import 'package:sellhub/features/profile/data/model/team_member_entry.dart';
import 'package:sellhub/features/profile/data/model/team_shared_list_entry.dart';
import 'package:sellhub/features/profile/data/model/team_selling_overview.dart';
import 'package:sellhub/features/profile/data/model/workflow_automation_overview.dart';
import 'package:sellhub/features/profile/data/model/workflow_buyer_segment.dart';
import 'package:sellhub/features/profile/data/model/workflow_pricing_template.dart';
import 'package:sellhub/features/profile/data/model/workflow_supplier_bundle.dart';
import 'package:sellhub/features/cart/data/models/reseller_quote.dart';

class ProfileRepository {
  ProfileRepository(Object? client, this._commerceStore);

  final SellHubCommerceLocalStore _commerceStore;

  Future<ProfileResModel?>? fetchProfileDetails(int id) {
    return _commerceStore.fetchProfileDetails(id);
  }

  Future<List<OrderHistoryResModelProfile>> fetchOrderHistory(
    int siteId,
    int customerId,
  ) {
    return _commerceStore.fetchOrderHistory(siteId, customerId);
  }

  Future<List<BuyerBookProfile>> fetchBuyerBook({
    required int userId,
    required int siteId,
  }) {
    return _commerceStore.fetchBuyerBook(userId: userId, siteId: siteId);
  }

  Future<List<PayoutBatchEntry>> fetchPayoutBatches({
    required int userId,
    required int siteId,
  }) {
    return _commerceStore.fetchPayoutBatches(userId: userId, siteId: siteId);
  }

  Future<PayoutBatchEntry> upsertPayoutBatch(PayoutBatchEntry entry) {
    return _commerceStore.upsertPayoutBatch(entry);
  }

  Future<bool> deletePayoutBatch(String id) {
    return _commerceStore.deletePayoutBatch(id);
  }

  Future<List<PayoutAdjustmentEntry>> fetchPayoutAdjustments({
    required int userId,
    required int siteId,
  }) {
    return _commerceStore.fetchPayoutAdjustments(
      userId: userId,
      siteId: siteId,
    );
  }

  Future<PayoutAdjustmentEntry> upsertPayoutAdjustment(
    PayoutAdjustmentEntry entry,
  ) {
    return _commerceStore.upsertPayoutAdjustment(entry);
  }

  Future<bool> deletePayoutAdjustment(String id) {
    return _commerceStore.deletePayoutAdjustment(id);
  }

  Future<List<PayoutDisputeEntry>> fetchPayoutDisputes({
    required int userId,
    required int siteId,
  }) {
    return _commerceStore.fetchPayoutDisputes(userId: userId, siteId: siteId);
  }

  Future<List<ResellerQuote>> fetchQuotes({
    required int userId,
    required int siteId,
  }) {
    return _commerceStore.fetchQuotes(userId: userId, siteId: siteId);
  }

  Future<bool> deleteQuote(String quoteId) {
    return _commerceStore.deleteQuote(quoteId);
  }

  Future<PayoutDisputeEntry> upsertPayoutDispute(PayoutDisputeEntry entry) {
    return _commerceStore.upsertPayoutDispute(entry);
  }

  Future<bool> deletePayoutDispute(String id) {
    return _commerceStore.deletePayoutDispute(id);
  }

  Future<PayoutDisputeEntry> reportPayoutDispute({
    required int userId,
    required int siteId,
    required String orderId,
    String? batchId,
    required String reason,
    required String note,
  }) {
    return _commerceStore.reportPayoutDispute(
      userId: userId,
      siteId: siteId,
      orderId: orderId,
      batchId: batchId,
      reason: reason,
      note: note,
    );
  }

  Future<bool> saveBuyerProfileMeta({
    required String buyerId,
    required String buyerName,
    required String buyerPhone,
    required int userId,
    required int siteId,
    required String note,
    required String sourceTag,
    required bool isRisky,
    required bool isBlocked,
  }) {
    return _commerceStore.saveBuyerProfileMeta(
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      userId: userId,
      siteId: siteId,
      note: note,
      sourceTag: sourceTag,
      isRisky: isRisky,
      isBlocked: isBlocked,
    );
  }

  Future<bool> deleteBuyerProfileMeta(String buyerId) {
    return _commerceStore.deleteBuyerProfileMeta(buyerId);
  }

  Future<WorkflowAutomationOverview> fetchWorkflowAutomationOverview({
    required int userId,
    required int siteId,
  }) {
    return _commerceStore.fetchWorkflowAutomationOverview(
      userId: userId,
      siteId: siteId,
    );
  }

  Future<WorkflowPricingTemplate> upsertWorkflowPricingTemplate(
    WorkflowPricingTemplate template,
  ) {
    return _commerceStore.upsertWorkflowPricingTemplate(template);
  }

  Future<bool> deleteWorkflowPricingTemplate(String id) {
    return _commerceStore.deleteWorkflowPricingTemplate(id);
  }

  Future<WorkflowSupplierBundle> upsertWorkflowSupplierBundle(
    WorkflowSupplierBundle bundle,
  ) {
    return _commerceStore.upsertWorkflowSupplierBundle(bundle);
  }

  Future<bool> deleteWorkflowSupplierBundle(String id) {
    return _commerceStore.deleteWorkflowSupplierBundle(id);
  }

  Future<WorkflowBuyerSegment> upsertWorkflowBuyerSegment(
    WorkflowBuyerSegment segment,
  ) {
    return _commerceStore.upsertWorkflowBuyerSegment(segment);
  }

  Future<bool> deleteWorkflowBuyerSegment(String id) {
    return _commerceStore.deleteWorkflowBuyerSegment(id);
  }

  Future<TeamSellingOverview> fetchTeamSellingOverview({
    required int userId,
    required int siteId,
  }) {
    return _commerceStore.fetchTeamSellingOverview(userId: userId, siteId: siteId);
  }

  Future<void> upsertTeamConfig({
    required int userId,
    required int siteId,
    required String teamId,
    required String teamName,
    required String ownerName,
    required double overridePercent,
  }) {
    return _commerceStore.upsertTeamConfig(
      userId: userId,
      siteId: siteId,
      teamId: teamId,
      teamName: teamName,
      ownerName: ownerName,
      overridePercent: overridePercent,
    );
  }

  Future<TeamMemberEntry> upsertTeamMember(TeamMemberEntry member) {
    return _commerceStore.upsertTeamMember(member);
  }

  Future<TeamMemberEntry?> fetchTeamMember(String id) {
    return _commerceStore.fetchTeamMember(id);
  }

  Future<TeamMemberEntry> acceptTeamInvite({
    required String memberId,
    required String teamId,
    required int ownerUserId,
    required int siteId,
    String? sellerName,
    String? sellerPhone,
  }) {
    return _commerceStore.acceptTeamInvite(
      memberId: memberId,
      teamId: teamId,
      ownerUserId: ownerUserId,
      siteId: siteId,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
    );
  }

  Future<bool> deleteTeamMember(String id) {
    return _commerceStore.deleteTeamMember(id);
  }

  Future<TeamSharedListEntry> upsertTeamSharedList(TeamSharedListEntry entry) {
    return _commerceStore.upsertTeamSharedList(entry);
  }

  Future<bool> deleteTeamSharedList(String id) {
    return _commerceStore.deleteTeamSharedList(id);
  }

  Future<ResellerResModelProfile?> fetchResellerInformation(int id) {
    return _commerceStore.fetchResellerInformation(id);
  }

  Future<bool> makeResellerRequest(
    int userId,
    int customerId,
    String title,
    String paymentTitle,
    String paymentNo,
  ) {
    return _commerceStore.makeResellerRequest(
      userId: userId,
      customerId: customerId,
      title: title,
      paymentTitle: paymentTitle,
      paymentNo: paymentNo,
    );
  }

  Future<SelfStoreCustomerRes?> fetchSelfStoreCustomer(int userId, int siteID) {
    return _commerceStore.fetchSelfStoreCustomer(userId, siteID);
  }

  Future<bool> addFavorite({
    required int userId,
    required int customerId,
    required int productId,
  }) {
    return _commerceStore.addFavorite(
      userId: userId,
      customerId: customerId,
      productId: productId,
    );
  }

  Future<bool> removeFavorite({
    required int userId,
    required int customerId,
    required int productId,
  }) {
    return _commerceStore.removeFavorite(
      userId: userId,
      customerId: customerId,
      productId: productId,
    );
  }

  Future<bool> addShippingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) {
    return _commerceStore.addShippingAddress(
      customerId: customerId,
      address: address,
    );
  }

  Future<bool> removeShippingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) {
    return _commerceStore.removeShippingAddress(
      customerId: customerId,
      address: address,
    );
  }

  Future<bool> addBillingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) {
    return _commerceStore.addBillingAddress(
      customerId: customerId,
      address: address,
    );
  }

  Future<bool> removeBillingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) {
    return _commerceStore.removeBillingAddress(
      customerId: customerId,
      address: address,
    );
  }

  Future<bool> passwordChange(int id, String oldPassword, String newPassword) {
    return _commerceStore.passwordChange(id, oldPassword, newPassword);
  }
}
