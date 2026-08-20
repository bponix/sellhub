import 'package:sellhub/core/local_seed/sellhub_commerce_local_store.dart';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/features/profile/data/model/buyer_book_profile.dart';
import 'package:sellhub/features/profile/data/model/payout_source_allocation.dart';
import 'package:sellhub/features/profile/data/model/order_res_model.dart';
import 'package:sellhub/features/profile/data/model/payout_adjustment_entry.dart';
import 'package:sellhub/features/profile/data/model/payout_batch_entry.dart';
import 'package:sellhub/features/profile/data/model/payout_dispute_entry.dart';
import 'package:sellhub/features/profile/data/model/reseller_payout_readiness.dart';
import 'package:sellhub/features/profile/data/model/reseller_profit_proof.dart';
import 'package:sellhub/features/profile/data/model/reseller_payout_evidence.dart';
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
import 'package:sellhub/features/profile/query/order_query.dart';
import 'package:sellhub/features/profile/mutation/user_password_update.dart';
import 'package:sellhub/features/profile/mutation/customer_address_mutations.dart';
import 'package:sellhub/features/profile/mutation/customer_favorite_mutations.dart';
import 'package:sellhub/features/profile/mutation/request_reseller.dart';
import 'package:sellhub/features/profile/query/profile_query.dart';
import 'package:sellhub/features/profile/query/reseller_query.dart';
import 'package:sellhub/features/profile/query/self_store_customer.dart';

class ProfileRepository {
  ProfileRepository(GraphQLClient client, this._commerceStore)
    : _client = client;

  final GraphQLClient _client;
  final SellHubCommerceLocalStore _commerceStore;

  static final _teamSummaryDocument = gql(r'''
    query SellHubTeamSummary($siteId: Int!, $userId: Int!, $limit: Int) {
      storeSellhubTeamSummary(siteId: $siteId, userId: $userId, limit: $limit) {
        siteId
        ownerResellerId
        ownerResellerCode
        memberCount
        invitedCount
        acceptedCount
        orderCount
        deliveredOrderCount
        totalCommission
        teamAllocatedCommission
        teamReversedCommission
        teamPayoutImpact
        totalRevenue
        buyerReachCount
        anonymousSupplierCount
        status
        nextAction
        members {
          id
          siteId
          ownerResellerId
          memberUserId
          memberCustomerId
          inviteCode
          displayName
          role
          status
          overrideSharePct
          orderCount
          deliveredOrderCount
          pendingOrderCount
          totalCommission
          allocatedCommission
          reversedCommission
          payoutImpact
          totalRevenue
          buyerReachCount
          anonymousSupplierCount
          acceptedAt
          updatedAt
        }
      }
    }
  ''');

  static final _payoutReadinessDocument = gql(r'''
    query SellHubMobilePayoutReadiness($data: ResellerPayoutReadinessInput!) {
      resellerPayoutReadiness(data: $data) {
        siteId resellerId pendingAmount withdrawableAmount pendingPayoutAmount
        paidAmount requestedPayoutAmount processingPayoutAmount
        settledPayoutAmount blockedPayoutAmount disputedAmount reversedAmount
        proofNeededAmount openPayoutCount blockedPayoutCount
        lastPayoutRequestedAt lastPayoutSettledAt canWithdraw
        primaryStatus primaryAction routeTarget
        buckets { key amount }
      }
    }
  ''');

  static final _profitProofDocument = gql(r'''
    query SellHubMobileProfitProof($data: ResellerProfitProofInput!) {
      resellerProfitProof(data: $data) {
        proofStatus orderTotal orderResellAmount orderResellerCommission
        orderResellerIsPaid quoteId conversionStatus
        lineSummary {
          lineCount supplierCount quantityTotal baseTotal buyerTotal
          grossProfit orderCommission expectedProfit
        }
        buckets { key amount }
        proofRows { source status amount refType refId createdAt }
      }
    }
  ''');

  static final _payoutEvidenceDocument = gql(r'''
    query SellHubMobilePayoutEvidence($userId: Int!, $siteId: Int!, $orderId: Int) {
      storeSellhubPayoutEvidence(userId: $userId, siteId: $siteId, orderId: $orderId) {
        expectedProfit walletCreditedAmount allocatedAmount paidAmount releasedAmount
        disputedAmount reversedAmount orderProofGap payoutAllocationGap
        status blockers nextAction
        allocations { id amount status }
        disputes { id reason status eventCount }
      }
    }
  ''');

  static final _buyerBookDocument = gql(r'''
    query SellHubMobileBuyerBook($data: ResellerBuyerBookListInput!) {
      resellerBuyerBook(data: $data) {
        id siteId resellerId buyerKey buyerLabel areaName preferredProducts
        notes reliability followUpAt followUpStatus followUpCompletedAt
        followUpLastRemindedAt followUpReminderCount blocked disputed lastOrderId lastOrderAt
        orderCount totalAmount meta createdAt updatedAt
      }
    }
  ''');

  static final _buyerBookUpsertDocument = gql(r'''
    mutation SellHubMobileBuyerBookUpsert($data: ResellerBuyerBookUpsertInput!) {
      resellerBuyerBookUpsert(data: $data) {
        id siteId resellerId buyerKey buyerLabel areaName preferredProducts
        notes reliability followUpAt followUpStatus followUpCompletedAt
        followUpLastRemindedAt followUpReminderCount blocked disputed lastOrderId lastOrderAt
        orderCount totalAmount meta createdAt updatedAt
      }
    }
  ''');

  static final _buyerFollowUpActionDocument = gql(r'''
    mutation SellHubMobileBuyerFollowUpAction($data: ResellerBuyerFollowUpActionInput!) {
      resellerBuyerFollowUpAction(data: $data) {
        id followUpAt followUpStatus followUpCompletedAt followUpReminderCount updatedAt
      }
    }
  ''');

  static final _resellerByUserDocument = gql(r'''
    query SellHubMobileResellerByUser($data: ResellerByUserInput!) {
      resellerByUser(data: $data) { id siteId userId }
    }
  ''');

  static final _storeQuotesDocument = gql(r'''
    query SellHubMobileQuotes($siteId: Int!, $customerId: Int!, $first: Int, $offset: Int) {
      storeQuotes(siteId: $siteId, customerId: $customerId, first: $first, offset: $offset) {
        edges {
          node {
            id siteId userId customerName customerPhone customerAddress
            deliveryTime logisticsText logisticsCharge grossAmount total cost
            profit status createdAt currency
            lines { productId productName image quantity price resellPrice }
          }
        }
      }
    }
  ''');

  static final _payoutRequestsDocument = gql(r'''
    query SellHubMobilePayoutRequests($data: WalletPayoutRequestListInput!) {
      walletPayoutRequests(data: $data) {
        id siteId resellerId status amount note idempotencyKey transactionRef
        requestedAt approvedAt settledAt rejectedAt createdAt updatedAt
      }
    }
  ''');

  static final _createPayoutRequestDocument = gql(r'''
    mutation SellHubMobileCreatePayoutRequest($data: WalletPayoutRequestCreateInput!) {
      walletPayoutRequestCreate(data: $data) {
        id siteId resellerId status amount note idempotencyKey transactionRef
        requestedAt approvedAt settledAt rejectedAt createdAt updatedAt
      }
    }
  ''');

  static final _payoutAllocationsDocument = gql(r'''
    query SellHubMobilePayoutAllocations($data: ResellerPayoutAllocationListInput!) {
      resellerPayoutAllocations(data: $data) {
        id payoutRequestId walletLedgerId orderId sourceType amount status createdAt
      }
    }
  ''');

  static final _payoutDisputesDocument = gql(r'''
    query SellHubMobilePayoutDisputes($data: ResellerPayoutDisputeListInput!) {
      resellerPayoutDisputes(data: $data) {
        id siteId resellerId orderId payoutRequestId reason note status
        resolutionNote createdByUserId resolvedByUserId resolvedAt createdAt updatedAt
      }
    }
  ''');

  static final _payoutAdjustmentsDocument = gql(r'''
    query SellHubMobilePayoutAdjustments($data: CommissionEventListInput!) {
      commissionEvents(data: $data) {
        id siteId resellerId orderId refType status basis amount meta createdAt
      }
    }
  ''');

  static final _createPayoutDisputeDocument = gql(r'''
    mutation SellHubMobileCreatePayoutDispute($data: ResellerPayoutDisputeCreateInput!) {
      resellerPayoutDisputeCreate(data: $data) {
        id siteId resellerId orderId payoutRequestId reason note status
        resolutionNote createdByUserId resolvedByUserId resolvedAt createdAt updatedAt
      }
    }
  ''');

  Future<ResellerProfitProof> fetchProfitProof({
    required int siteId,
    required int orderId,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: _profitProofDocument,
        variables: <String, dynamic>{
          'data': <String, dynamic>{'siteId': siteId, 'orderId': orderId},
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      final errors = result.exception?.graphqlErrors ?? const [];
      throw Exception(
        errors.isEmpty ? 'Profit proof is unavailable.' : errors.first.message,
      );
    }
    final row = result.data?['resellerProfitProof'];
    if (row is! Map) throw Exception('Profit proof is unavailable.');
    return ResellerProfitProof.fromJson(Map<String, dynamic>.from(row));
  }

  Future<ResellerPayoutEvidence> fetchPayoutEvidence({
    required int userId,
    required int siteId,
    required int orderId,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: _payoutEvidenceDocument,
        variables: <String, dynamic>{
          'userId': userId,
          'siteId': siteId,
          'orderId': orderId,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      final errors = result.exception?.graphqlErrors ?? const [];
      throw Exception(
        errors.isEmpty
            ? 'Payout evidence is unavailable.'
            : errors.first.message,
      );
    }
    final row = result.data?['storeSellhubPayoutEvidence'];
    if (row is! Map) throw Exception('Payout evidence is unavailable.');
    return ResellerPayoutEvidence.fromJson(Map<String, dynamic>.from(row));
  }

  Future<ResellerPayoutReadiness> fetchPayoutReadiness({
    required int siteId,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: _payoutReadinessDocument,
        variables: <String, dynamic>{
          'data': <String, dynamic>{'siteId': siteId},
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      final errors = result.exception?.graphqlErrors ?? const [];
      throw Exception(
        errors.isEmpty
            ? 'Payout readiness is unavailable.'
            : errors.first.message,
      );
    }
    final row = result.data?['resellerPayoutReadiness'];
    if (row is! Map) throw Exception('Payout readiness is unavailable.');
    return ResellerPayoutReadiness.fromJson(Map<String, dynamic>.from(row));
  }

  static final _upsertTeamMemberDocument = gql(r'''
    mutation UpsertSellHubTeamMember($userId: Int!, $siteId: Int!, $input: StoreSellhubTeamMemberInput!) {
      upsertStoreSellhubTeamMember(userId: $userId, siteId: $siteId, input: $input) {
        id
        siteId
        ownerResellerId
        inviteCode
        status
      }
    }
  ''');

  static final _acceptTeamInviteDocument = gql(r'''
    mutation AcceptSellHubTeamInvite($userId: Int!, $siteId: Int!, $inviteCode: String!, $memberCustomerId: Int) {
      acceptStoreSellhubTeamInvite(userId: $userId, siteId: $siteId, inviteCode: $inviteCode, memberCustomerId: $memberCustomerId) {
        id
        siteId
        ownerResellerId
        inviteCode
        status
      }
    }
  ''');

  Future<ProfileResModel?>? fetchProfileDetails(int id) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHPROFILE),
        variables: <String, dynamic>{'id': id},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final row = result.data?['storeCustomer'];
    return row is Map
        ? ProfileResModel.fromJson(Map<String, dynamic>.from(row))
        : null;
  }

  Future<List<OrderHistoryResModelProfile>> fetchOrderHistory(
    int siteId,
    int customerId,
  ) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHORDERHISTORY),
        variables: <String, dynamic>{
          'siteId': siteId,
          'customerId': customerId,
          'first': 200,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final edges = result.data?['storeOrders']?['edges'];
    if (edges is! List) return const <OrderHistoryResModelProfile>[];
    return edges
        .whereType<Map>()
        .map((edge) => edge['node'])
        .whereType<Map>()
        .map(
          (row) => OrderHistoryResModelProfile.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList(growable: false);
  }

  Future<List<BuyerBookProfile>> fetchBuyerBook({
    required int userId,
    required int siteId,
  }) async {
    final local = await _commerceStore.fetchBuyerBook(
      userId: userId,
      siteId: siteId,
    );
    final result = await _client.query(
      QueryOptions(
        document: _buyerBookDocument,
        variables: <String, dynamic>{
          'data': <String, dynamic>{
            'siteId': siteId,
            'includeBlocked': true,
            'limit': 200,
            'offset': 0,
          },
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final rows = result.data?['resellerBuyerBook'];
    if (rows is! List) throw StateError('Store returned no buyer book.');
    return _mergeStoreBuyerBook(rows, local);
  }

  Future<List<PayoutBatchEntry>> fetchPayoutBatches({
    required int userId,
    required int siteId,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: _payoutRequestsDocument,
        variables: <String, dynamic>{
          'data': <String, dynamic>{
            'siteId': siteId,
            'limit': 100,
            'offset': 0,
          },
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      final errors = result.exception?.graphqlErrors ?? const [];
      throw StateError(
        errors.isEmpty
            ? 'Payout requests are unavailable.'
            : errors.first.message,
      );
    }
    final rows = result.data?['walletPayoutRequests'];
    if (rows is! List) return const <PayoutBatchEntry>[];
    return rows
        .whereType<Map>()
        .map(
          (row) => _payoutBatchFromStore(
            Map<String, dynamic>.from(row),
            userId: userId,
          ),
        )
        .toList(growable: false);
  }

  Future<List<PayoutSourceAllocation>> fetchPayoutAllocations({
    required int siteId,
    required String payoutRequestId,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: _payoutAllocationsDocument,
        fetchPolicy: FetchPolicy.networkOnly,
        variables: <String, dynamic>{
          'data': <String, dynamic>{
            'siteId': siteId,
            'payoutRequestId': payoutRequestId,
          },
        },
      ),
    );
    if (result.hasException) throw result.exception!;
    return ((result.data?['resellerPayoutAllocations'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (row) =>
              PayoutSourceAllocation.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  Future<PayoutBatchEntry> createPayoutRequest({
    required int userId,
    required int siteId,
    required double amount,
    required String note,
    required String operationKey,
  }) async {
    final readiness = await fetchPayoutReadiness(siteId: siteId);
    if (!readiness.canWithdraw || amount <= 0) {
      throw StateError('Store has no withdrawable balance for this request.');
    }
    if (amount > readiness.withdrawableAmount) {
      throw StateError('Requested amount exceeds Store withdrawable balance.');
    }
    final resellerId = readiness.resellerId.trim().isNotEmpty
        ? readiness.resellerId.trim()
        : await _resolveResellerId(userId: userId, siteId: siteId);
    final result = await _client.mutate(
      MutationOptions(
        document: _createPayoutRequestDocument,
        variables: <String, dynamic>{
          'data': <String, dynamic>{
            'siteId': siteId,
            'resellerId': resellerId,
            'amount': amount,
            'note': note.trim(),
            'idempotencyKey': operationKey,
          },
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      final errors = result.exception?.graphqlErrors ?? const [];
      throw StateError(
        errors.isEmpty
            ? 'Payout request could not be created.'
            : errors.first.message,
      );
    }
    final row = result.data?['walletPayoutRequestCreate'];
    if (row is! Map) throw StateError('Store returned no payout request.');
    return _payoutBatchFromStore(
      Map<String, dynamic>.from(row),
      userId: userId,
    );
  }

  static PayoutBatchEntry _payoutBatchFromStore(
    Map<String, dynamic> row, {
    required int userId,
  }) {
    final status = '${row['status'] ?? 'requested'}';
    final amount = (row['amount'] as num?)?.toDouble() ?? 0;
    return PayoutBatchEntry(
      id: '${row['id'] ?? ''}',
      userId: userId,
      siteId: (row['siteId'] as num?)?.toInt() ?? 0,
      customerId: 0,
      status: status,
      channel: 'Store wallet',
      referenceId: '${row['transactionRef'] ?? ''}',
      orderIds: const <String>[],
      totalAmount: amount,
      deductionTotal: 0,
      netAmount: amount,
      note: '${row['note'] ?? ''}',
      createdAt: DateTime.tryParse(
        '${row['requestedAt'] ?? row['createdAt'] ?? ''}',
      ),
      estimatedSettlementDate: null,
      releasedAt: DateTime.tryParse('${row['approvedAt'] ?? ''}'),
      paidAt: DateTime.tryParse('${row['settledAt'] ?? ''}'),
    );
  }

  Future<List<PayoutAdjustmentEntry>> fetchPayoutAdjustments({
    required int userId,
    required int siteId,
  }) async {
    final resellerId = await _resolveResellerId(userId: userId, siteId: siteId);
    final result = await _client.query(
      QueryOptions(
        document: _payoutAdjustmentsDocument,
        variables: <String, dynamic>{
          'data': <String, dynamic>{
            'siteId': siteId,
            'resellerId': resellerId,
            'limit': 200,
            'offset': 0,
          },
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final rows = (result.data?['commissionEvents'] as List?) ?? const [];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .where((row) {
          final status = '${row['status'] ?? ''}'.toLowerCase();
          return status == 'reversed' ||
              status == 'disputed' ||
              status == 'held' ||
              status == 'failed';
        })
        .map((row) {
          final status = '${row['status'] ?? 'adjusted'}'.toLowerCase();
          final refType = '${row['refType'] ?? 'commission'}'.toLowerCase();
          final metadata = row['meta'] is Map
              ? Map<String, dynamic>.from(row['meta'] as Map)
              : const <String, dynamic>{};
          final isReturn =
              refType.contains('return') || refType.contains('refund');
          return PayoutAdjustmentEntry(
            id: '${row['id'] ?? ''}',
            userId: userId,
            siteId: (row['siteId'] as num?)?.toInt() ?? siteId,
            orderId: '${row['orderId'] ?? ''}',
            type: isReturn ? 'return_adjustment' : 'commission_$status',
            label: isReturn
                ? 'Return adjustment'
                : 'Commission ${status.replaceAll('_', ' ')}',
            amount: ((row['amount'] as num?)?.toDouble() ?? 0).abs(),
            note:
                '${metadata['reason'] ?? metadata['note'] ?? row['basis'] ?? 'Store commission proof'}',
            createdAt: DateTime.tryParse('${row['createdAt'] ?? ''}'),
          );
        })
        .toList(growable: false);
  }

  Future<List<PayoutDisputeEntry>> fetchPayoutDisputes({
    required int userId,
    required int siteId,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: _payoutDisputesDocument,
        variables: <String, dynamic>{
          'data': <String, dynamic>{
            'siteId': siteId,
            'limit': 100,
            'offset': 0,
          },
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      final errors = result.exception?.graphqlErrors ?? const [];
      throw StateError(
        errors.isEmpty
            ? 'Payout disputes are unavailable.'
            : errors.first.message,
      );
    }
    final rows = result.data?['resellerPayoutDisputes'];
    if (rows is! List) return const <PayoutDisputeEntry>[];
    return rows
        .whereType<Map>()
        .map(
          (row) => _payoutDisputeFromStore(
            Map<String, dynamic>.from(row),
            userId: userId,
          ),
        )
        .toList(growable: false);
  }

  Future<List<ResellerQuote>> fetchQuotes({
    required int userId,
    required int siteId,
  }) async {
    final local = await _commerceStore.fetchQuotes(
      userId: userId,
      siteId: siteId,
    );
    final customer = await fetchSelfStoreCustomer(userId, siteId);
    final customerId = customer?.id ?? 0;
    if (customerId <= 0) return local;
    final result = await _client.query(
      QueryOptions(
        document: _storeQuotesDocument,
        variables: <String, dynamic>{
          'siteId': siteId,
          'customerId': customerId,
          'first': 100,
          'offset': 0,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final edges = result.data?['storeQuotes']?['edges'];
    if (edges is! List) throw StateError('Store returned no quote list.');
    final remote = edges
        .whereType<Map>()
        .map((edge) => edge['node'])
        .whereType<Map>()
        .map((row) => _quoteFromStore(Map<String, dynamic>.from(row), userId))
        .toList(growable: false);
    final remoteIds = remote.map((quote) => quote.id).toSet();
    return <ResellerQuote>[
      ...remote,
      ...local.where(
        (quote) => quote.status == 'offline' && !remoteIds.contains(quote.id),
      ),
    ];
  }

  Future<bool> deleteQuote(String quoteId) {
    if (int.tryParse(quoteId) != null) {
      throw StateError('Store quotes cannot be deleted from local drafts.');
    }
    return _commerceStore.deleteQuote(quoteId);
  }

  static ResellerQuote _quoteFromStore(
    Map<String, dynamic> row,
    int fallbackUserId,
  ) {
    final lines = ((row['lines'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (line) => ResellerQuoteLine(
            productId: (line['productId'] as num?)?.toInt(),
            title: '${line['productName'] ?? ''}',
            thumbnail: '${line['image'] ?? ''}',
            quantity: (line['quantity'] as num?)?.toInt() ?? 1,
            basePrice: (line['price'] as num?)?.toInt() ?? 0,
            sellPrice: (line['resellPrice'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList(growable: false);
    final status = (row['status'] as num?)?.toInt() ?? 0;
    return ResellerQuote(
      id: '${row['id'] ?? ''}',
      siteId: (row['siteId'] as num?)?.toInt() ?? 0,
      userId: (row['userId'] as num?)?.toInt() ?? fallbackUserId,
      buyerName: '${row['customerName'] ?? ''}',
      buyerPhone: (row['customerPhone'] as num?)?.toInt() ?? 0,
      buyerAddress: '${row['customerAddress'] ?? ''}',
      deliveryLabel: '${row['logisticsText'] ?? ''}',
      deliveryEstimate: '${row['deliveryTime'] ?? ''}',
      deliveryCharge: (row['logisticsCharge'] as num?)?.toInt() ?? 0,
      subtotal: (row['grossAmount'] as num?)?.toInt() ?? 0,
      total: (row['total'] as num?)?.toInt() ?? 0,
      baseTotal: (row['cost'] as num?)?.toInt() ?? 0,
      profit: (row['profit'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse('${row['createdAt'] ?? ''}') ?? DateTime.now(),
      status: status == 2
          ? 'converted'
          : (status == 7 || status == 9 ? 'closed' : 'draft'),
      lines: lines,
    );
  }

  Future<PayoutDisputeEntry> reportPayoutDispute({
    required int userId,
    required int siteId,
    required int orderId,
    String? batchId,
    required String reason,
    required String note,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: _createPayoutDisputeDocument,
        variables: <String, dynamic>{
          'data': <String, dynamic>{
            'siteId': siteId,
            'orderId': orderId,
            'payoutRequestId': batchId,
            'reason': reason,
            'note': note,
          },
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      final errors = result.exception?.graphqlErrors ?? const [];
      throw StateError(
        errors.isEmpty
            ? 'Payout dispute could not be created.'
            : errors.first.message,
      );
    }
    final row = result.data?['resellerPayoutDisputeCreate'];
    if (row is! Map) throw StateError('Store returned no payout dispute.');
    return _payoutDisputeFromStore(
      Map<String, dynamic>.from(row),
      userId: userId,
    );
  }

  static PayoutDisputeEntry _payoutDisputeFromStore(
    Map<String, dynamic> row, {
    required int userId,
  }) => PayoutDisputeEntry(
    id: '${row['id'] ?? ''}',
    userId: userId,
    siteId: (row['siteId'] as num?)?.toInt() ?? 0,
    orderId: '${row['orderId'] ?? ''}',
    batchId: row['payoutRequestId']?.toString(),
    status: '${row['status'] ?? 'open'}',
    reason: '${row['reason'] ?? 'Payout mismatch'}',
    note: '${row['note'] ?? ''}',
    createdAt: DateTime.tryParse('${row['createdAt'] ?? ''}'),
    updatedAt: DateTime.tryParse('${row['updatedAt'] ?? ''}'),
  );

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
  }) async {
    final resellerId = await _resolveResellerId(userId: userId, siteId: siteId);
    final result = await _client.mutate(
      MutationOptions(
        document: _buyerBookUpsertDocument,
        variables: <String, dynamic>{
          'data': <String, dynamic>{
            'siteId': siteId,
            'resellerId': resellerId,
            'buyerKey': _privacySafeBuyerKey(siteId, buyerId),
            'buyerLabel': buyerName.trim(),
            'buyerPhoneHash': buyerPhone.trim().isEmpty
                ? null
                : _privacySafeBuyerKey(siteId, buyerPhone),
            'notes': note.trim(),
            'reliability': isBlocked
                ? 'blocked'
                : (isRisky ? 'caution' : 'good'),
            'blocked': isBlocked,
            'disputed': false,
            'meta': <String, dynamic>{
              'localBuyerId': buyerId,
              'sourceTag': sourceTag,
            },
          },
        },
      ),
    );
    if (result.hasException) throw result.exception!;
    if (result.data?['resellerBuyerBookUpsert'] == null) {
      throw StateError('Store returned no buyer-book update.');
    }
    await _commerceStore.saveBuyerProfileMeta(
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
    return true;
  }

  Future<bool> resetBuyerProfileMeta({
    required BuyerBookProfile buyer,
    required int userId,
    required int siteId,
  }) {
    return saveBuyerProfileMeta(
      buyerId: buyer.id,
      buyerName: buyer.name,
      buyerPhone: buyer.phone,
      userId: userId,
      siteId: siteId,
      note: '',
      sourceTag: 'Repeat',
      isRisky: false,
      isBlocked: false,
    );
  }

  Future<String> _resolveResellerId({
    required int userId,
    required int siteId,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: _resellerByUserDocument,
        variables: <String, dynamic>{
          'data': <String, dynamic>{'siteId': siteId, 'userId': userId},
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final row = result.data?['resellerByUser'];
    final id = row is Map ? '${row['id'] ?? ''}'.trim() : '';
    if (id.isEmpty) throw StateError('Reseller profile is unavailable.');
    return id;
  }

  static String _privacySafeBuyerKey(int siteId, String value) => sha256
      .convert(utf8.encode('$siteId:${value.trim().toLowerCase()}'))
      .toString();

  static List<BuyerBookProfile> _mergeStoreBuyerBook(
    List<dynamic> rows,
    List<BuyerBookProfile> local,
  ) {
    final localById = <String, BuyerBookProfile>{
      for (final row in local) row.id: row,
    };
    final merged = <BuyerBookProfile>[];
    for (final value in rows) {
      if (value is! Map) continue;
      final row = Map<String, dynamic>.from(value);
      final meta = row['meta'] is Map
          ? Map<String, dynamic>.from(row['meta'] as Map)
          : const <String, dynamic>{};
      final localId = '${meta['localBuyerId'] ?? ''}'.trim();
      final cached = localById[localId];
      final products = row['preferredProducts'] is List
          ? (row['preferredProducts'] as List)
                .map((item) => '$item')
                .toList(growable: false)
          : cached?.preferredProducts ?? const <String>[];
      final reliability = '${row['reliability'] ?? 'unknown'}';
      merged.add(
        BuyerBookProfile(
          id: localId.isNotEmpty ? localId : '${row['buyerKey'] ?? row['id']}',
          name: '${row['buyerLabel'] ?? cached?.name ?? 'Saved buyer'}',
          phone: cached?.phone ?? '',
          addresses: cached?.addresses ?? const <String>[],
          primaryAddress: cached?.primaryAddress ?? '${row['areaName'] ?? ''}',
          note: '${row['notes'] ?? cached?.note ?? ''}',
          sourceTag: '${meta['sourceTag'] ?? cached?.sourceTag ?? 'Repeat'}',
          isRisky: reliability == 'caution' || reliability == 'disputed',
          isBlocked: row['blocked'] == true || reliability == 'blocked',
          totalOrders:
              (row['orderCount'] as num?)?.toInt() ?? cached?.totalOrders ?? 0,
          totalDelivered: cached?.totalDelivered ?? 0,
          returnCount: cached?.returnCount ?? 0,
          pendingOrders: cached?.pendingOrders ?? 0,
          unpaidOrders: cached?.unpaidOrders ?? 0,
          totalSales:
              (row['totalAmount'] as num?)?.toDouble() ??
              cached?.totalSales ??
              0,
          averageBasketSize: ((row['orderCount'] as num?)?.toInt() ?? 0) > 0
              ? ((row['totalAmount'] as num?)?.toDouble() ?? 0) /
                    (row['orderCount'] as num).toInt()
              : cached?.averageBasketSize ?? 0,
          lastOrderedAt:
              DateTime.tryParse('${row['lastOrderAt'] ?? ''}') ??
              cached?.lastOrderedAt,
          profileMetaUpdatedAt: DateTime.tryParse('${row['updatedAt'] ?? ''}'),
          preferredProducts: products,
          district: '${row['areaName'] ?? cached?.district ?? ''}',
          deliveryZone: cached?.deliveryZone ?? '',
          lastOrderId: row['lastOrderId'] == null
              ? cached?.lastOrderId
              : '${row['lastOrderId']}',
          followUpAt: DateTime.tryParse('${row['followUpAt'] ?? ''}'),
          followUpStatus: '${row['followUpStatus'] ?? 'none'}',
          followUpCompletedAt: DateTime.tryParse(
            '${row['followUpCompletedAt'] ?? ''}',
          ),
          followUpReminderCount:
              (row['followUpReminderCount'] as num?)?.toInt() ?? 0,
          storeBuyerBookId: '${row['id'] ?? ''}',
        ),
      );
    }
    return merged;
  }

  Future<bool> updateBuyerFollowUp({
    required int userId,
    required int siteId,
    required String buyerBookId,
    required String action,
    DateTime? scheduledAt,
    String? note,
  }) async {
    final resellerId = await _resolveResellerId(userId: userId, siteId: siteId);
    final result = await _client.mutate(
      MutationOptions(
        document: _buyerFollowUpActionDocument,
        fetchPolicy: FetchPolicy.networkOnly,
        variables: <String, dynamic>{
          'data': <String, dynamic>{
            'siteId': siteId,
            'resellerId': resellerId,
            'buyerBookId': buyerBookId,
            'action': action,
            'scheduledAt': scheduledAt?.toUtc().toIso8601String(),
            'note': note,
            'operationKey':
                'sellhub-mobile:$buyerBookId:$action:${DateTime.now().microsecondsSinceEpoch}',
          },
        },
      ),
    );
    return !result.hasException &&
        result.data?['resellerBuyerFollowUpAction'] != null;
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
  }) async {
    final local = await _commerceStore.fetchTeamSellingOverview(
      userId: userId,
      siteId: siteId,
    );
    final result = await _client.query(
      QueryOptions(
        document: _teamSummaryDocument,
        fetchPolicy: FetchPolicy.networkOnly,
        variables: <String, dynamic>{
          'userId': userId,
          'siteId': siteId,
          'limit': 50,
        },
      ),
    );
    if (result.hasException) throw result.exception!;
    final summary = result.data?['storeSellhubTeamSummary'];
    if (summary is! Map<String, dynamic>) {
      throw StateError('Store returned no team workspace.');
    }
    return _teamOverviewFromStoreSummary(
      summary,
      local: local,
      userId: userId,
      siteId: siteId,
    );
  }

  Future<void> upsertTeamConfig({
    required int userId,
    required int siteId,
    required String teamId,
    required String teamName,
    required String ownerName,
    required double overridePercent,
  }) async {
    if (overridePercent < 0 || overridePercent > 100) {
      throw StateError('Direct override must be between 0 and 100 percent.');
    }
    final summaryResult = await _client.query(
      QueryOptions(
        document: _teamSummaryDocument,
        variables: <String, dynamic>{
          'userId': userId,
          'siteId': siteId,
          'limit': 100,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (summaryResult.hasException) {
      final errors = summaryResult.exception?.graphqlErrors ?? const [];
      throw StateError(
        errors.isEmpty
            ? 'Store team policy is unavailable.'
            : errors.first.message,
      );
    }
    final summary = summaryResult.data?['storeSellhubTeamSummary'];
    final members = summary is Map
        ? ((summary['members'] as List?) ?? const <dynamic>[])
        : const <dynamic>[];
    for (final value in members.whereType<Map>()) {
      final id = '${value['id'] ?? ''}'.trim();
      if (id.isEmpty) continue;
      final result = await _client.mutate(
        MutationOptions(
          document: _upsertTeamMemberDocument,
          variables: <String, dynamic>{
            'userId': userId,
            'siteId': siteId,
            'input': <String, dynamic>{
              'id': id,
              'ownerResellerId': '${value['ownerResellerId'] ?? teamId}',
              'displayName': '${value['displayName'] ?? 'Team seller'}',
              'role': '${value['role'] ?? 'seller'}',
              'status': '${value['status'] ?? 'invited'}',
              'overrideSharePct': overridePercent,
              'overrideNote': 'Direct team policy updated from SellHub mobile.',
            },
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException ||
          result.data?['upsertStoreSellhubTeamMember'] == null) {
        final errors = result.exception?.graphqlErrors ?? const [];
        throw StateError(
          errors.isEmpty
              ? 'Store team override update failed.'
              : errors.first.message,
        );
      }
    }
    await _commerceStore.upsertTeamConfig(
      userId: userId,
      siteId: siteId,
      teamId: teamId,
      teamName: teamName,
      ownerName: ownerName,
      overridePercent: overridePercent,
    );
  }

  Future<TeamMemberEntry> upsertTeamMember(TeamMemberEntry member) async {
    final remoteId =
        RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ).hasMatch(member.id)
        ? member.id
        : null;
    final result = await _client.mutate(
      MutationOptions(
        document: _upsertTeamMemberDocument,
        fetchPolicy: FetchPolicy.networkOnly,
        variables: <String, dynamic>{
          'userId': member.ownerUserId,
          'siteId': member.siteId,
          'input': <String, dynamic>{
            if (remoteId != null) 'id': remoteId,
            if (member.teamId.trim().isNotEmpty)
              'ownerResellerId': member.teamId.trim(),
            'displayName': member.name,
            if (member.phone.trim().isNotEmpty)
              'contactHash': _privacySafeBuyerKey(member.siteId, member.phone),
            'role': member.role.toLowerCase().contains('manager')
                ? 'manager'
                : 'seller',
            'status': member.isActive ? 'accepted' : 'invited',
          },
        },
      ),
    );
    if (result.hasException) throw result.exception!;
    final payload = result.data?['upsertStoreSellhubTeamMember'];
    if (payload is! Map<String, dynamic>) {
      throw StateError('Store returned no team member.');
    }
    final remoteMember = TeamMemberEntry(
      id: '${payload['id'] ?? member.id}',
      teamId: '${payload['ownerResellerId'] ?? member.teamId}',
      ownerUserId: member.ownerUserId,
      siteId: (payload['siteId'] as num?)?.toInt() ?? member.siteId,
      name: member.name,
      phone: member.phone,
      status: '${payload['status'] ?? member.status}',
      role: member.role,
      orderVolume: member.orderVolume,
      overrideGenerated: member.overrideGenerated,
      topProduct: member.topProduct,
      joinedAt: member.joinedAt,
      lastActiveAt: DateTime.now(),
      inviteCode: '${payload['inviteCode'] ?? ''}',
    );
    await _commerceStore.upsertTeamMember(remoteMember);
    return remoteMember;
  }

  Future<TeamMemberEntry?> fetchTeamMember(String id) {
    return _commerceStore.fetchTeamMember(id);
  }

  Future<TeamMemberEntry> acceptTeamInvite({
    required String memberId,
    String? inviteCode,
    required String teamId,
    required int ownerUserId,
    int? currentUserId,
    required int siteId,
    int? memberCustomerId,
    String? sellerName,
    String? sellerPhone,
  }) async {
    final normalizedInviteCode = (inviteCode?.trim().isNotEmpty ?? false)
        ? inviteCode!.trim()
        : memberId;
    final actorUserId = currentUserId != null && currentUserId > 0
        ? currentUserId
        : ownerUserId;
    final result = await _client.mutate(
      MutationOptions(
        document: _acceptTeamInviteDocument,
        fetchPolicy: FetchPolicy.networkOnly,
        variables: <String, dynamic>{
          'userId': actorUserId,
          'siteId': siteId,
          'inviteCode': normalizedInviteCode,
          'memberCustomerId': memberCustomerId,
        },
      ),
    );
    if (result.hasException) throw result.exception!;
    final payload = result.data?['acceptStoreSellhubTeamInvite'];
    if (payload is! Map<String, dynamic>) {
      throw StateError('Store returned no accepted team member.');
    }
    final accepted = TeamMemberEntry(
      id: '${payload['id'] ?? memberId}',
      teamId: '${payload['ownerResellerId'] ?? teamId}',
      ownerUserId: ownerUserId,
      siteId: (payload['siteId'] as num?)?.toInt() ?? siteId,
      name: sellerName?.trim().isNotEmpty == true
          ? sellerName!.trim()
          : 'Accepted seller',
      phone: sellerPhone?.trim().isNotEmpty == true ? sellerPhone!.trim() : '',
      status: '${payload['status'] ?? 'accepted'}',
      role: 'seller',
      orderVolume: 0,
      overrideGenerated: 0,
      topProduct: '',
      joinedAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      inviteCode: '${payload['inviteCode'] ?? normalizedInviteCode}',
    );
    await _commerceStore.upsertTeamMember(accepted);
    return accepted;
  }

  TeamSellingOverview _teamOverviewFromStoreSummary(
    Map<String, dynamic> summary, {
    required TeamSellingOverview local,
    required int userId,
    required int siteId,
  }) {
    final members = ((summary['members'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((member) => _teamMemberFromStoreSummary(member, userId: userId))
        .toList(growable: false);
    final ownerResellerId = '${summary['ownerResellerId'] ?? ''}';
    final ownerCode = '${summary['ownerResellerCode'] ?? ''}';
    return TeamSellingOverview(
      teamId: ownerResellerId.trim().isEmpty ? local.teamId : ownerResellerId,
      ownerUserId: userId,
      siteId: (summary['siteId'] as num?)?.toInt() ?? siteId,
      teamName: ownerCode.trim().isEmpty ? local.teamName : 'Team $ownerCode',
      ownerName: local.ownerName,
      overridePercent: local.overridePercent,
      transparentPayoutRule:
          '${summary['nextAction'] ?? local.transparentPayoutRule}',
      activeMembers:
          (summary['acceptedCount'] as num?)?.toInt() ?? local.activeMembers,
      pendingInvites:
          (summary['invitedCount'] as num?)?.toInt() ?? local.pendingInvites,
      teamOrderVolume:
          (summary['totalRevenue'] as num?)?.toDouble() ??
          local.teamOrderVolume,
      overrideEarned:
          (summary['teamAllocatedCommission'] as num?)?.toDouble() ??
          local.overrideEarned,
      sharedListCount: local.sharedListCount,
      distributedProductCount: local.distributedProductCount,
      buyerReachCount:
          (summary['buyerReachCount'] as num?)?.toInt() ??
          local.buyerReachCount,
      anonymousSupplierCount:
          (summary['anonymousSupplierCount'] as num?)?.toInt() ??
          local.anonymousSupplierCount,
      payoutImpact:
          (summary['teamPayoutImpact'] as num?)?.toDouble() ??
          local.payoutImpact,
      members: members.isEmpty ? local.members : members,
      sharedLists: local.sharedLists,
    );
  }

  TeamMemberEntry _teamMemberFromStoreSummary(
    Map<String, dynamic> member, {
    required int userId,
  }) {
    final updatedAt = DateTime.tryParse('${member['updatedAt'] ?? ''}');
    final acceptedAt = DateTime.tryParse('${member['acceptedAt'] ?? ''}');
    return TeamMemberEntry(
      id: '${member['id'] ?? ''}',
      teamId: '${member['ownerResellerId'] ?? ''}',
      ownerUserId: userId,
      siteId: (member['siteId'] as num?)?.toInt() ?? 0,
      name: '${member['displayName'] ?? 'Team seller'}',
      phone: '',
      status: '${member['status'] ?? 'invited'}',
      role: '${member['role'] ?? 'seller'}',
      orderVolume: (member['totalRevenue'] as num?)?.toDouble() ?? 0,
      overrideGenerated:
          (member['allocatedCommission'] as num?)?.toDouble() ?? 0,
      topProduct: '',
      joinedAt: acceptedAt,
      lastActiveAt: updatedAt,
      inviteCode: '${member['inviteCode'] ?? ''}',
      buyerReachCount: (member['buyerReachCount'] as num?)?.toInt() ?? 0,
      anonymousSupplierCount:
          (member['anonymousSupplierCount'] as num?)?.toInt() ?? 0,
      payoutImpact: (member['payoutImpact'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<bool> deleteTeamMember(TeamMemberEntry member) async {
    final remoteId =
        RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ).hasMatch(member.id)
        ? member.id
        : null;
    if (remoteId == null) {
      throw StateError('Store team member identity is invalid.');
    }
    final result = await _client.mutate(
      MutationOptions(
        document: _upsertTeamMemberDocument,
        fetchPolicy: FetchPolicy.networkOnly,
        variables: <String, dynamic>{
          'userId': member.ownerUserId,
          'siteId': member.siteId,
          'input': <String, dynamic>{
            'id': remoteId,
            'ownerResellerId': member.teamId,
            'displayName': member.name,
            'role': member.role.toLowerCase().contains('manager')
                ? 'manager'
                : 'seller',
            'status': 'disabled',
          },
        },
      ),
    );
    if (result.hasException ||
        result.data?['upsertStoreSellhubTeamMember'] == null) {
      return false;
    }
    await _commerceStore.deleteTeamMember(member.id);
    return true;
  }

  Future<TeamSharedListEntry> upsertTeamSharedList(TeamSharedListEntry entry) {
    return _commerceStore.upsertTeamSharedList(entry);
  }

  Future<bool> deleteTeamSharedList(String id) {
    return _commerceStore.deleteTeamSharedList(id);
  }

  Future<ResellerResModelProfile?> fetchResellerInformation(int id) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHRESELLERINFORMATION),
        variables: <String, dynamic>{'id': id},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final row = result.data?['storeCustomer'];
    return row is Map
        ? ResellerResModelProfile.fromJson(Map<String, dynamic>.from(row))
        : null;
  }

  Future<bool> makeResellerRequest(
    int userId,
    int customerId,
    String title,
    String paymentTitle,
    String paymentNo,
  ) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(RESELLERREQUEST),
        variables: <String, dynamic>{
          'userId': userId,
          'customerId': customerId,
          'title': title,
          'customerType': const <int>[2],
          'paymentTitle': paymentTitle,
          'paymentNo': paymentNo,
          'note': const <dynamic>[],
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    return result.data?['selfStoreCustomerUpdate'] != null;
  }

  Future<SelfStoreCustomerRes?> fetchSelfStoreCustomer(
    int userId,
    int siteID,
  ) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHSELFSTORECUSTOMER),
        variables: <String, dynamic>{
          'userId': userId,
          'siteId': siteID,
          'isActive': true,
          'isReseller': null,
          'isWholesale': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final row = result.data?['selfStoreCustomer'];
    return row is Map
        ? SelfStoreCustomerRes.fromJson(Map<String, dynamic>.from(row))
        : null;
  }

  Future<bool> addFavorite({
    required int userId,
    required int customerId,
    required int productId,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(ADD_STORE_CUSTOMER_FAVORITE),
        variables: <String, dynamic>{
          'userId': userId,
          'customerId': customerId,
          'productId': productId,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    return result.data?['selfStoreCustomerAddFavorite'] == true;
  }

  Future<bool> removeFavorite({
    required int userId,
    required int customerId,
    required int productId,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(REMOVE_STORE_CUSTOMER_FAVORITE),
        variables: <String, dynamic>{
          'userId': userId,
          'customerId': customerId,
          'productId': productId,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    return result.data?['selfStoreCustomerRemoveFavorite'] == true;
  }

  Future<bool> addShippingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) => _addressMutation(
    document: ADD_STORE_CUSTOMER_SHIPPING_ADDRESS,
    customerId: customerId,
    address: address,
    resultKey: 'storeCustomerAddShippingAddress',
  );
  Future<bool> removeShippingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) => _addressMutation(
    document: REMOVE_STORE_CUSTOMER_SHIPPING_ADDRESS,
    customerId: customerId,
    address: address,
    resultKey: 'storeCustomerRemoveShippingAddress',
  );

  Future<bool> addBillingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) => _addressMutation(
    document: ADD_STORE_CUSTOMER_BILLING_ADDRESS,
    customerId: customerId,
    address: address,
    resultKey: 'storeCustomerAddBillingAddress',
  );

  Future<bool> removeBillingAddress({
    required int customerId,
    required StoreCustomerAddressModel address,
  }) => _addressMutation(
    document: REMOVE_STORE_CUSTOMER_BILLING_ADDRESS,
    customerId: customerId,
    address: address,
    resultKey: 'storeCustomerRemoveBillingAddress',
  );

  Future<bool> _addressMutation({
    required String document,
    required int customerId,
    required StoreCustomerAddressModel address,
    required String resultKey,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(document),
        variables: <String, dynamic>{
          'customerId': customerId,
          'id': address.id,
          'address': address.address,
          'formattedAddress': address.formattedAddress,
          'latitude': address.latitude,
          'longitude': address.longitude,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    return result.data?[resultKey] == true;
  }

  Future<bool> passwordChange(
    int id,
    String oldPassword,
    String newPassword,
  ) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(USER_PASSWORD_UPDATE),
        variables: <String, dynamic>{
          'id': id,
          'email': '',
          'new': newPassword,
          'old': oldPassword,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    return result.data?['userPasswordUpdate'] != null;
  }
}
