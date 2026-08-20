import 'dart:convert';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/core/api/graphql_client_factory.dart';
import 'package:sellhub/core/api/local_graphql_api.dart';
import 'package:sellhub/core/api/local_seed_guard.dart';
import 'package:sellhub/features/cart/data/models/buyer_risk_profile.dart';
import 'package:sellhub/features/cart/data/models/order_group_draft.dart';
import 'package:sellhub/features/cart/data/models/quick_order_draft.dart';
import 'package:sellhub/features/cart/data/models/reseller_quote.dart';
import 'package:sellhub/features/cart/data/models/share_asset_draft.dart';
import 'package:sellhub/features/profile/data/model/buyer_book_profile.dart';
import 'package:sellhub/features/profile/data/model/team_member_entry.dart';
import 'package:sellhub/features/profile/data/model/team_shared_list_entry.dart';
import 'package:sellhub/features/profile/data/model/team_selling_overview.dart';
import 'package:sellhub/features/profile/data/model/workflow_automation_overview.dart';
import 'package:sellhub/features/profile/data/model/workflow_buyer_segment.dart';
import 'package:sellhub/features/profile/data/model/workflow_pricing_template.dart';
import 'package:sellhub/features/profile/data/model/workflow_recent_pairing.dart';
import 'package:sellhub/features/profile/data/model/workflow_sell_again_suggestion.dart';
import 'package:sellhub/features/profile/data/model/workflow_supplier_bundle.dart';

class SellHubCommerceLocalStore {
  SellHubCommerceLocalStore({required LocalGraphQLApi api})
    : _client = createGraphQLClient(
        endpoint: 'https://example.invalid/graphql',
        link: LocalGraphQLLink(api: api),
      );

  final GraphQLClient _client;
  Future<void>? _seedFuture;

  static const String _seedKey = 'sellhub_commerce_seed';
  static const String _quotesCollection = 'commerce_quotes';
  static const String _buyerMetaCollection = 'commerce_buyer_meta';
  static const String _quickOrderDraftsCollection =
      LocalGraphqlCollections.resellerQuickOrderDrafts;
  static const String _buyerRiskProfilesCollection =
      LocalGraphqlCollections.resellerBuyerRiskProfiles;
  static const String _orderGroupDraftsCollection =
      LocalGraphqlCollections.resellerOrderGroupDrafts;
  static const String _shareAssetDraftsCollection =
      LocalGraphqlCollections.resellerShareAssetDrafts;
  static const String _workflowPricingTemplatesCollection =
      'commerce_workflow_pricing_templates';
  static const String _workflowBundlesCollection =
      'commerce_workflow_supplier_bundles';
  static const String _workflowBuyerSegmentsCollection =
      'commerce_workflow_buyer_segments';
  static const String _teamConfigCollection = 'commerce_team_config';
  static const String _teamMembersCollection = 'commerce_team_members';
  static const String _teamSharedListsCollection = 'commerce_team_shared_lists';
  static const String _seedVersion = 'commerce_v8';

  static final _listCollectionDocument = gql(r'''
    query ListCollection($collection: String!) {
      listCollection(collection: $collection) {
        id
        payload
      }
    }
  ''');

  static final _getEntityDocument = gql(r'''
    query GetEntity($collection: String!, $id: String!) {
      getEntity(collection: $collection, id: $id) {
        id
        payload
      }
    }
  ''');

  static final _upsertEntityDocument = gql(r'''
    mutation UpsertEntity(
      $collection: String!
      $id: String!
      $payload: String!
      $updatedAt: String!
    ) {
      upsertEntity(
        collection: $collection
        id: $id
        payload: $payload
        updatedAt: $updatedAt
      ) {
        id
      }
    }
  ''');

  static final _deleteEntityDocument = gql(r'''
    mutation DeleteEntity($collection: String!, $id: String!) {
      deleteEntity(collection: $collection, id: $id) {
        id
        deleted
      }
    }
  ''');

  Future<void> ensureSeeded() {
    final existing = _seedFuture;
    if (existing != null) return existing;
    final future = _ensureSeededInternal().whenComplete(() {
      _seedFuture = null;
    });
    _seedFuture = future;
    return future;
  }

  Future<List<BuyerBookProfile>> fetchBuyerBook({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final rows = await _loadCollection(_buyerMetaCollection);
    return rows
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(
          (item) => BuyerBookProfile(
            id: '${item['id'] ?? ''}',
            name: '${item['buyerName'] ?? 'Saved buyer'}',
            phone: '${item['buyerPhone'] ?? ''}',
            addresses: const <String>[],
            primaryAddress: '',
            note: '${item['note'] ?? ''}',
            sourceTag: '${item['sourceTag'] ?? 'Device cache'}',
            isRisky: item['isRisky'] == true,
            isBlocked: item['isBlocked'] == true,
            totalOrders: 0,
            totalDelivered: 0,
            returnCount: 0,
            pendingOrders: 0,
            unpaidOrders: 0,
            totalSales: 0,
            averageBasketSize: 0,
            lastOrderedAt: null,
            profileMetaUpdatedAt: DateTime.tryParse(
              '${item['updatedAt'] ?? ''}',
            ),
            preferredProducts: const <String>[],
            district: '',
            deliveryZone: '',
            lastOrderId: null,
          ),
        )
        .toList(growable: false);
  }

  Future<List<WorkflowPricingTemplate>> fetchWorkflowPricingTemplates({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final rows = await _loadCollection(_workflowPricingTemplatesCollection);
    return rows
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(WorkflowPricingTemplate.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );
  }

  Future<WorkflowPricingTemplate> upsertWorkflowPricingTemplate(
    WorkflowPricingTemplate template,
  ) async {
    await ensureSeeded();
    await _upsertEntity(
      _workflowPricingTemplatesCollection,
      template.id,
      template.toJson(),
    );
    return template;
  }

  Future<bool> deleteWorkflowPricingTemplate(String id) async {
    await ensureSeeded();
    return _deleteEntity(_workflowPricingTemplatesCollection, id);
  }

  Future<List<WorkflowSupplierBundle>> fetchWorkflowSupplierBundles({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final rows = await _loadCollection(_workflowBundlesCollection);
    return rows
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(WorkflowSupplierBundle.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );
  }

  Future<WorkflowSupplierBundle> upsertWorkflowSupplierBundle(
    WorkflowSupplierBundle bundle,
  ) async {
    await ensureSeeded();
    await _upsertEntity(_workflowBundlesCollection, bundle.id, bundle.toJson());
    return bundle;
  }

  Future<bool> deleteWorkflowSupplierBundle(String id) async {
    await ensureSeeded();
    return _deleteEntity(_workflowBundlesCollection, id);
  }

  Future<List<WorkflowBuyerSegment>> fetchWorkflowBuyerSegments({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final rows = await _loadCollection(_workflowBuyerSegmentsCollection);
    return rows
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(WorkflowBuyerSegment.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );
  }

  Future<WorkflowBuyerSegment> upsertWorkflowBuyerSegment(
    WorkflowBuyerSegment segment,
  ) async {
    await ensureSeeded();
    await _upsertEntity(
      _workflowBuyerSegmentsCollection,
      segment.id,
      segment.toJson(),
    );
    return segment;
  }

  Future<bool> deleteWorkflowBuyerSegment(String id) async {
    await ensureSeeded();
    return _deleteEntity(_workflowBuyerSegmentsCollection, id);
  }

  Future<WorkflowAutomationOverview> fetchWorkflowAutomationOverview({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final templates = await fetchWorkflowPricingTemplates(
      userId: userId,
      siteId: siteId,
    );
    final bundles = await fetchWorkflowSupplierBundles(
      userId: userId,
      siteId: siteId,
    );
    final savedSegments = await fetchWorkflowBuyerSegments(
      userId: userId,
      siteId: siteId,
    );
    return WorkflowAutomationOverview(
      pricingTemplates: templates,
      supplierBundles: bundles,
      buyerSegments: savedSegments,
      recentPairings: const <WorkflowRecentPairing>[],
      sellAgainSuggestions: const <WorkflowSellAgainSuggestion>[],
    );
  }

  Future<TeamSellingOverview> fetchTeamSellingOverview({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final config =
        await _loadEntity(
          _teamConfigCollection,
          _teamConfigKey(userId, siteId),
        ) ??
        <String, dynamic>{
          'id': _teamConfigKey(userId, siteId),
          'teamId': 'team-$siteId-$userId',
          'ownerUserId': userId,
          'siteId': siteId,
          'teamName': 'SellHub Team',
          'ownerName': 'Team owner',
          'overridePercent': 4,
          'transparentPayoutRule':
              'Override applies only to direct team sales. No multi-level payouts.',
        };
    final members =
        (await _loadCollection(_teamMembersCollection))
            .where(
              (item) =>
                  (item['ownerUserId'] as num?)?.toInt() == userId &&
                  (item['siteId'] as num?)?.toInt() == siteId &&
                  (item['teamId'] as String?) == config['teamId'],
            )
            .map(TeamMemberEntry.fromJson)
            .toList(growable: false)
          ..sort(
            (a, b) => (b.lastActiveAt ?? DateTime(2000)).compareTo(
              a.lastActiveAt ?? DateTime(2000),
            ),
          );
    final sharedLists =
        (await _loadCollection(_teamSharedListsCollection))
            .where(
              (item) =>
                  (item['ownerUserId'] as num?)?.toInt() == userId &&
                  (item['siteId'] as num?)?.toInt() == siteId &&
                  (item['teamId'] as String?) == config['teamId'],
            )
            .map(TeamSharedListEntry.fromJson)
            .toList(growable: false)
          ..sort(
            (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
              a.updatedAt ?? DateTime(2000),
            ),
          );

    final activeMembers = members.where((item) => item.isActive).length;
    final pendingInvites = members.where((item) => item.isPending).length;
    final teamOrderVolume = members.fold<double>(
      0,
      (sum, item) => sum + item.orderVolume,
    );
    final overrideEarned = members.fold<double>(
      0,
      (sum, item) => sum + item.overrideGenerated,
    );
    final distributedProductCount = sharedLists
        .expand((item) => item.productTitles)
        .toSet()
        .length;

    return TeamSellingOverview(
      teamId: (config['teamId'] as String?) ?? 'team-$siteId-$userId',
      ownerUserId: userId,
      siteId: siteId,
      teamName: (config['teamName'] as String?) ?? 'SellHub Team',
      ownerName: (config['ownerName'] as String?) ?? 'Team owner',
      overridePercent: (config['overridePercent'] as num?)?.toDouble() ?? 0,
      transparentPayoutRule:
          (config['transparentPayoutRule'] as String?) ??
          'Override applies only to direct team sales. No hidden chain payouts.',
      activeMembers: activeMembers,
      pendingInvites: pendingInvites,
      teamOrderVolume: teamOrderVolume,
      overrideEarned: overrideEarned,
      sharedListCount: sharedLists.length,
      distributedProductCount: distributedProductCount,
      members: members,
      sharedLists: sharedLists,
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
    await ensureSeeded();
    await _upsertEntity(_teamConfigCollection, _teamConfigKey(userId, siteId), <
      String,
      dynamic
    >{
      'id': _teamConfigKey(userId, siteId),
      'teamId': teamId,
      'ownerUserId': userId,
      'siteId': siteId,
      'teamName': teamName,
      'ownerName': ownerName,
      'overridePercent': overridePercent,
      'transparentPayoutRule':
          'Override applies only to direct team sales. No multi-level payouts.',
    });
  }

  Future<TeamMemberEntry> upsertTeamMember(TeamMemberEntry member) async {
    await ensureSeeded();
    await _upsertEntity(_teamMembersCollection, member.id, member.toJson());
    return member;
  }

  Future<TeamMemberEntry?> fetchTeamMember(String id) async {
    await ensureSeeded();
    final entity = await _loadEntity(_teamMembersCollection, id);
    return entity == null ? null : TeamMemberEntry.fromJson(entity);
  }

  Future<TeamMemberEntry> acceptTeamInvite({
    required String memberId,
    required String teamId,
    required int ownerUserId,
    required int siteId,
    String? sellerName,
    String? sellerPhone,
  }) async {
    await ensureSeeded();
    final entity = await _loadEntity(_teamMembersCollection, memberId);
    final now = DateTime.now();
    final member = TeamMemberEntry(
      id: memberId,
      teamId: teamId,
      ownerUserId: ownerUserId,
      siteId: siteId,
      name: sellerName?.trim().isNotEmpty == true
          ? sellerName!.trim()
          : (entity?['name'] as String?) ?? 'Seller',
      phone: sellerPhone?.trim().isNotEmpty == true
          ? sellerPhone!.trim()
          : (entity?['phone'] as String?) ?? '',
      status: 'active',
      role: (entity?['role'] as String?) ?? 'team_seller',
      orderVolume: (entity?['orderVolume'] as num?)?.toDouble() ?? 0,
      overrideGenerated:
          (entity?['overrideGenerated'] as num?)?.toDouble() ?? 0,
      topProduct: (entity?['topProduct'] as String?) ?? '',
      joinedAt:
          DateTime.tryParse((entity?['joinedAt'] as String?) ?? '') ?? now,
      lastActiveAt: now,
    );
    await _upsertEntity(_teamMembersCollection, member.id, member.toJson());
    return member;
  }

  Future<bool> deleteTeamMember(String id) async {
    await ensureSeeded();
    return _deleteEntity(_teamMembersCollection, id);
  }

  Future<TeamSharedListEntry> upsertTeamSharedList(
    TeamSharedListEntry entry,
  ) async {
    await ensureSeeded();
    await _upsertEntity(_teamSharedListsCollection, entry.id, entry.toJson());
    return entry;
  }

  Future<bool> deleteTeamSharedList(String id) async {
    await ensureSeeded();
    return _deleteEntity(_teamSharedListsCollection, id);
  }

  Future<Map<String, dynamic>?> fetchQuickOrderDraft({
    required int userId,
    required int siteId,
    String? draftId,
  }) async {
    if ((draftId?.trim().isNotEmpty ?? false)) {
      final draft = await fetchResellerQuickOrderDraft(draftId!.trim());
      if (draft != null && draft.userId == userId && draft.siteId == siteId) {
        return draft.toJson();
      }
    }
    final drafts = await fetchResellerQuickOrderDrafts(
      userId: userId,
      siteId: siteId,
    );
    return drafts.isEmpty ? null : drafts.first.toJson();
  }

  Future<Map<String, dynamic>> saveQuickOrderDraft(
    Map<String, dynamic> payload,
  ) async {
    final draft = QuickOrderDraft.fromJson(payload);
    final saved = await upsertResellerQuickOrderDraft(draft);
    return saved.toJson();
  }

  Future<bool> deleteQuickOrderDraft({
    required int userId,
    required int siteId,
    String? draftId,
  }) async {
    if ((draftId?.trim().isNotEmpty ?? false)) {
      return deleteResellerQuickOrderDraft(draftId!.trim());
    }
    final drafts = await fetchResellerQuickOrderDrafts(
      userId: userId,
      siteId: siteId,
    );
    if (drafts.isEmpty) return true;
    return deleteResellerQuickOrderDraft(drafts.first.id);
  }

  Future<Map<String, dynamic>> fetchBuyerRiskDecision({
    required int userId,
    required int siteId,
    required String buyerPhone,
    String? buyerName,
    String? buyerAddress,
    double? orderTotal,
    int? itemCount,
    Map<String, dynamic>? context,
  }) async {
    await ensureSeeded();
    final buyers = await fetchBuyerBook(userId: userId, siteId: siteId);
    BuyerBookProfile? matchedBuyer;
    for (final buyer in buyers) {
      if (buyerPhone.trim().isNotEmpty &&
          _normalizeIdentity(buyer.phone) == _normalizeIdentity(buyerPhone)) {
        matchedBuyer = buyer;
        break;
      }
    }
    if (matchedBuyer == null && (buyerName?.trim().isNotEmpty ?? false)) {
      for (final buyer in buyers) {
        if (_normalizeIdentity(buyer.name) ==
            _normalizeIdentity(buyerName!.trim())) {
          matchedBuyer = buyer;
          break;
        }
      }
    }

    final storedProfile = await fetchResellerBuyerRiskProfile(
      buyerId:
          matchedBuyer?.id ??
          _buyerIdentityKey(phone: buyerPhone, name: buyerName ?? ''),
      userId: userId,
      siteId: siteId,
    );
    final profile =
        storedProfile ??
        (matchedBuyer == null
            ? BuyerRiskProfile(
                id: _buyerIdentityKey(phone: buyerPhone, name: buyerName ?? ''),
                userId: userId,
                siteId: siteId,
                buyerName: (buyerName?.trim().isNotEmpty ?? false)
                    ? buyerName!.trim()
                    : 'Buyer',
                buyerPhone: buyerPhone.trim(),
                riskLevel: (orderTotal ?? 0) >= 5000 ? 'medium' : 'low',
                riskScore: (orderTotal ?? 0) >= 5000 ? 20 : 0,
                blocked: false,
                note: '',
                reasonCodes: <String>[
                  if ((buyerAddress ?? '').trim().isEmpty) 'missing_address',
                  if ((orderTotal ?? 0) >= 5000) 'high_value_order',
                  if ((itemCount ?? 0) >= 6) 'large_basket',
                ],
                recommendedAction: (orderTotal ?? 0) >= 5000
                    ? 'Reconfirm buyer phone and address before placing supplier order.'
                    : 'Buyer can proceed through the normal reseller order flow.',
                totalOrders: 0,
                deliveredOrders: 0,
                returnCount: 0,
                pendingOrders: 0,
                unpaidOrders: 0,
                lastOrderId: null,
                updatedAt: DateTime.now(),
              )
            : _deriveBuyerRiskProfile(matchedBuyer, userId, siteId));

    final escalatedScore =
        profile.riskScore +
        ((orderTotal ?? 0) >= 5000 ? 10 : 0) +
        ((itemCount ?? 0) >= 6 ? 5 : 0);
    final decision = profile.blocked || escalatedScore >= 90
        ? 'blocked'
        : escalatedScore >= 45
        ? 'review'
        : 'approved';
    final reasons = {
      ...profile.reasonCodes,
      if ((orderTotal ?? 0) >= 5000) 'high_value_order',
      if ((itemCount ?? 0) >= 6) 'large_basket',
    }.toList(growable: false);

    final updatedProfile = BuyerRiskProfile(
      id: profile.id,
      userId: profile.userId,
      siteId: profile.siteId,
      buyerName: profile.buyerName,
      buyerPhone: profile.buyerPhone,
      riskLevel: decision == 'approved'
          ? 'low'
          : decision == 'review'
          ? 'medium'
          : 'high',
      riskScore: escalatedScore,
      blocked: decision == 'blocked',
      note: profile.note,
      reasonCodes: reasons,
      recommendedAction: decision == 'blocked'
          ? 'Hold the order, collect advance, and verify buyer intent before dispatch.'
          : decision == 'review'
          ? 'Call the buyer, confirm landmark, and check COD intent before supplier confirmation.'
          : profile.recommendedAction,
      totalOrders: profile.totalOrders,
      deliveredOrders: profile.deliveredOrders,
      returnCount: profile.returnCount,
      pendingOrders: profile.pendingOrders,
      unpaidOrders: profile.unpaidOrders,
      lastOrderId: profile.lastOrderId,
      updatedAt: DateTime.now(),
    );
    await upsertResellerBuyerRiskProfile(updatedProfile);
    return <String, dynamic>{
      'decision': decision,
      'riskScore': escalatedScore,
      'summary': updatedProfile.recommendedAction,
      'reasons': reasons,
      'requiresManualReview': decision != 'approved',
      'buyer': matchedBuyer?.toJson(),
      'buyerPhone': buyerPhone.trim(),
      'buyerName': (buyerName ?? '').trim(),
      'buyerAddress': buyerAddress ?? matchedBuyer?.primaryAddress ?? '',
      'orderTotal': orderTotal ?? 0,
      'itemCount': itemCount ?? 0,
      'context': context ?? const <String, dynamic>{},
      'evaluatedAt': DateTime.now().toIso8601String(),
      'source': 'local-store',
      'profile': updatedProfile.toJson(),
    };
  }

  Future<Map<String, dynamic>> previewSupplierSplit({
    required int userId,
    required int siteId,
    required List<Map<String, dynamic>> lines,
    Map<String, dynamic>? draft,
    List<Map<String, dynamic>> supplierHints = const <Map<String, dynamic>>[],
  }) async {
    final bySupplier = <String, List<Map<String, dynamic>>>{};
    final supplierNames = <String, String>{};
    for (final hint in supplierHints) {
      final key = _supplierKeyFromLine(hint, fallbackSiteId: siteId);
      supplierNames[key] =
          (hint['supplierName'] ?? hint['name'] ?? hint['title'] ?? 'Supplier')
              .toString();
    }
    for (final line in lines) {
      final key = _supplierKeyFromLine(line, fallbackSiteId: siteId);
      bySupplier.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(line);
      supplierNames[key] =
          (line['supplierName'] ??
                  line['siteName'] ??
                  supplierNames[key] ??
                  'Supplier')
              .toString();
    }
    final suppliers = bySupplier.entries
        .map((entry) {
          final supplierLines = entry.value;
          final quantity = supplierLines.fold<int>(
            0,
            (sum, item) => sum + _toInt(item['quantity'], fallback: 1),
          );
          final baseAmount = supplierLines.fold<double>(
            0,
            (sum, item) =>
                sum +
                (_toDouble(item['basePrice'] ?? item['resellPrice']) *
                    _toInt(item['quantity'], fallback: 1)),
          );
          final sellAmount = supplierLines.fold<double>(
            0,
            (sum, item) =>
                sum +
                (_toDouble(item['sellPrice'] ?? item['price']) *
                    _toInt(item['quantity'], fallback: 1)),
          );
          return <String, dynamic>{
            'supplierKey': entry.key,
            'supplierName': supplierNames[entry.key] ?? 'Supplier',
            'siteId': _extractSiteId(entry.key, fallback: siteId),
            'lineCount': supplierLines.length,
            'quantity': quantity,
            'baseAmount': baseAmount,
            'sellAmount': sellAmount,
            'profit': sellAmount - baseAmount,
            'lines': supplierLines,
          };
        })
        .toList(growable: false);

    final totalSellAmount = suppliers.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['sellAmount']),
    );
    final totalBaseAmount = suppliers.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['baseAmount']),
    );
    final groupDraft = await upsertResellerSupplierOrderGroupDraft(
      OrderGroupDraft(
        id:
            ((draft?['groupId'] ?? draft?['id']) as Object?)
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                true
            ? ((draft?['groupId'] ?? draft?['id']) as Object).toString()
            : 'group-$siteId-$userId',
        userId: userId,
        siteId: siteId,
        title: (draft?['title'] as String?) ?? 'Supplier split draft',
        status: (draft?['status'] as String?) ?? 'draft',
        channel: (draft?['channel'] as String?) ?? 'quick-order',
        buyerIds: <String>[
          if ((draft?['buyerPhone'] as String?)?.trim().isNotEmpty ?? false)
            _buyerIdentityKey(
              phone: draft!['buyerPhone'] as String,
              name: (draft['buyerName'] as String?) ?? '',
            ),
        ],
        quickOrderDraftIds: <String>[
          if ((draft?['id'] as String?)?.trim().isNotEmpty ?? false)
            draft!['id'] as String,
        ],
        tags: suppliers
            .map((item) => '${item['supplierName']}')
            .toList(growable: false),
        note:
            'Local supplier grouping preview for ${suppliers.length} supplier lanes.',
        targetOrderCount: suppliers.length,
        projectedRevenue: totalSellAmount.round(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return <String, dynamic>{
      'userId': userId,
      'siteId': siteId,
      'draftId': draft?['id'] ?? draft?['draftId'],
      'groupId': groupDraft.id,
      'supplierCount': suppliers.length,
      'lineCount': lines.length,
      'totalQuantity': suppliers.fold<int>(
        0,
        (sum, item) => sum + _toInt(item['quantity']),
      ),
      'totalBaseAmount': totalBaseAmount,
      'totalSellAmount': totalSellAmount,
      'totalProfit': totalSellAmount - totalBaseAmount,
      'suppliers': suppliers,
      'generatedAt': DateTime.now().toIso8601String(),
      'source': 'local-store',
    };
  }

  Future<List<QuickOrderDraft>> fetchResellerQuickOrderDrafts({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final rows = await _loadCollection(_quickOrderDraftsCollection);
    return rows
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(QuickOrderDraft.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );
  }

  Future<QuickOrderDraft?> fetchResellerQuickOrderDraft(String id) async {
    await ensureSeeded();
    final entity = await _loadEntity(_quickOrderDraftsCollection, id);
    return entity == null ? null : QuickOrderDraft.fromJson(entity);
  }

  Future<QuickOrderDraft> upsertResellerQuickOrderDraft(
    QuickOrderDraft draft,
  ) async {
    await ensureSeeded();
    final now = DateTime.now();
    final payload = draft.toJson();
    if ((payload['createdAt'] as String?)?.isEmpty ?? true) {
      payload['createdAt'] = now.toIso8601String();
    }
    payload['updatedAt'] = now.toIso8601String();
    await _upsertEntity(_quickOrderDraftsCollection, draft.id, payload);
    return QuickOrderDraft.fromJson(payload);
  }

  Future<bool> deleteResellerQuickOrderDraft(String id) async {
    await ensureSeeded();
    return _deleteEntity(_quickOrderDraftsCollection, id);
  }

  Future<List<BuyerRiskProfile>> fetchResellerBuyerRiskProfiles({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final storedRows = await _loadCollection(_buyerRiskProfilesCollection);
    final profiles = <String, BuyerRiskProfile>{};
    for (final row in storedRows) {
      if ((row['userId'] as num?)?.toInt() != userId) continue;
      if ((row['siteId'] as num?)?.toInt() != siteId) continue;
      final profile = BuyerRiskProfile.fromJson(row);
      profiles[profile.id] = profile;
    }
    final buyers = await fetchBuyerBook(userId: userId, siteId: siteId);
    for (final buyer in buyers) {
      profiles.putIfAbsent(
        buyer.id,
        () => _deriveBuyerRiskProfile(buyer, userId, siteId),
      );
    }
    final items = profiles.values.toList(growable: false)
      ..sort((a, b) {
        final scoreCompare = b.riskScore.compareTo(a.riskScore);
        if (scoreCompare != 0) return scoreCompare;
        return (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        );
      });
    return items;
  }

  Future<BuyerRiskProfile?> fetchResellerBuyerRiskProfile({
    required String buyerId,
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final entity = await _loadEntity(_buyerRiskProfilesCollection, buyerId);
    if (entity != null) return BuyerRiskProfile.fromJson(entity);
    final buyers = await fetchBuyerBook(userId: userId, siteId: siteId);
    for (final buyer in buyers) {
      if (buyer.id == buyerId) {
        return _deriveBuyerRiskProfile(buyer, userId, siteId);
      }
    }
    return null;
  }

  Future<BuyerRiskProfile> upsertResellerBuyerRiskProfile(
    BuyerRiskProfile profile,
  ) async {
    await ensureSeeded();
    final payload = profile.toJson()
      ..['updatedAt'] = DateTime.now().toIso8601String();
    await _upsertEntity(_buyerRiskProfilesCollection, profile.id, payload);
    return BuyerRiskProfile.fromJson(payload);
  }

  Future<bool> deleteResellerBuyerRiskProfile(String buyerId) async {
    await ensureSeeded();
    return _deleteEntity(_buyerRiskProfilesCollection, buyerId);
  }

  Future<List<OrderGroupDraft>> fetchResellerSupplierOrderGroupDrafts({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final rows = await _loadCollection(_orderGroupDraftsCollection);
    return rows
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(OrderGroupDraft.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );
  }

  Future<OrderGroupDraft?> fetchResellerSupplierOrderGroupDraft(
    String id,
  ) async {
    await ensureSeeded();
    final entity = await _loadEntity(_orderGroupDraftsCollection, id);
    return entity == null ? null : OrderGroupDraft.fromJson(entity);
  }

  Future<OrderGroupDraft> upsertResellerSupplierOrderGroupDraft(
    OrderGroupDraft draft,
  ) async {
    await ensureSeeded();
    final now = DateTime.now();
    final payload = draft.toJson();
    if ((payload['createdAt'] as String?)?.isEmpty ?? true) {
      payload['createdAt'] = now.toIso8601String();
    }
    payload['updatedAt'] = now.toIso8601String();
    await _upsertEntity(_orderGroupDraftsCollection, draft.id, payload);
    return OrderGroupDraft.fromJson(payload);
  }

  Future<bool> deleteResellerSupplierOrderGroupDraft(String id) async {
    await ensureSeeded();
    return _deleteEntity(_orderGroupDraftsCollection, id);
  }

  Future<List<ShareAssetDraft>> fetchResellerShareAssetDrafts({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final rows = await _loadCollection(_shareAssetDraftsCollection);
    return rows
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(ShareAssetDraft.fromJson)
        .toList(growable: false)
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );
  }

  Future<ShareAssetDraft?> fetchResellerShareAssetDraft(String id) async {
    await ensureSeeded();
    final entity = await _loadEntity(_shareAssetDraftsCollection, id);
    return entity == null ? null : ShareAssetDraft.fromJson(entity);
  }

  Future<ShareAssetDraft> upsertResellerShareAssetDraft(
    ShareAssetDraft draft,
  ) async {
    await ensureSeeded();
    final payload = draft.toJson()
      ..['updatedAt'] = DateTime.now().toIso8601String();
    await _upsertEntity(_shareAssetDraftsCollection, draft.id, payload);
    return ShareAssetDraft.fromJson(payload);
  }

  Future<bool> deleteResellerShareAssetDraft(String id) async {
    await ensureSeeded();
    return _deleteEntity(_shareAssetDraftsCollection, id);
  }

  Future<ResellerQuote> createQuote(ResellerQuote quote) async {
    await ensureSeeded();
    await _upsertEntity(_quotesCollection, quote.id, quote.toJson());
    return quote;
  }

  Future<ResellerQuote> upsertQuote(ResellerQuote quote) {
    return createQuote(quote);
  }

  Future<List<ResellerQuote>> fetchQuotes({
    required int userId,
    required int siteId,
  }) async {
    await ensureSeeded();
    final rows = await _loadCollection(_quotesCollection);
    return rows
        .where(
          (item) =>
              (item['userId'] as num?)?.toInt() == userId &&
              (item['siteId'] as num?)?.toInt() == siteId,
        )
        .map(ResellerQuote.fromJson)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> markQuoteConverted({
    required String quoteId,
    required String orderId,
  }) async {
    await ensureSeeded();
    final existing = await _loadEntity(_quotesCollection, quoteId);
    if (existing == null) return;
    final updated = ResellerQuote.fromJson(
      existing,
    ).copyWith(status: 'converted', orderId: orderId);
    await _upsertEntity(_quotesCollection, quoteId, updated.toJson());
  }

  Future<bool> deleteQuote(String quoteId) async {
    await ensureSeeded();
    return _deleteEntity(_quotesCollection, quoteId);
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
  }) async {
    await ensureSeeded();
    await _upsertEntity(_buyerMetaCollection, buyerId, <String, dynamic>{
      'id': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'userId': userId,
      'siteId': siteId,
      'note': note.trim(),
      'sourceTag': sourceTag.trim().isEmpty ? 'Repeat' : sourceTag.trim(),
      'isRisky': isRisky,
      'isBlocked': isBlocked,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    return true;
  }

  Future<bool> deleteBuyerProfileMeta(String buyerId) async {
    await ensureSeeded();
    return _deleteEntity(_buyerMetaCollection, buyerId);
  }

  Future<void> _ensureSeededInternal() async {
    final version = await loadLocalSeedVersion(_client, seedKey: _seedKey);
    if (version == _seedVersion) return;
    await saveLocalSeedVersion(
      _client,
      seedKey: _seedKey,
      version: _seedVersion,
    );
  }

  String _buyerIdentityKey({required String phone, required String name}) {
    final normalizedPhone = phone.replaceAll(RegExp(r'\s+'), '').trim();
    if (normalizedPhone.isNotEmpty && normalizedPhone != '0') {
      return 'phone:$normalizedPhone';
    }
    return 'name:${name.trim().toLowerCase()}';
  }

  String _normalizeIdentity(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  String _supplierKeyFromLine(
    Map<String, dynamic> line, {
    required int fallbackSiteId,
  }) {
    final supplierId =
        line['supplierId'] ??
        line['siteId'] ??
        line['storeId'] ??
        fallbackSiteId;
    return '${line['supplierKey'] ?? line['supplierCode'] ?? supplierId}';
  }

  int _extractSiteId(String key, {required int fallback}) {
    final parsed = int.tryParse(key);
    return parsed ?? fallback;
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? fallback;
  }

  BuyerRiskProfile _deriveBuyerRiskProfile(
    BuyerBookProfile buyer,
    int userId,
    int siteId,
  ) {
    final score =
        (buyer.returnCount * 45) +
        (buyer.unpaidOrders * 15) +
        (buyer.pendingOrders * 10) +
        (buyer.isBlocked ? 30 : 0) +
        (buyer.isRisky ? 15 : 0);
    final boundedScore = score.clamp(0, 100).toInt();
    final riskLevel = boundedScore >= 75
        ? 'high'
        : boundedScore >= 40
        ? 'medium'
        : 'low';
    final reasonCodes = <String>[
      if (buyer.returnCount > 0) 'returned_order',
      if (buyer.unpaidOrders > 0) 'unpaid_order',
      if (buyer.pendingOrders > 0) 'pending_fulfillment',
      if (buyer.isBlocked) 'blocked_buyer',
      if (buyer.totalOrders >= 2 && buyer.returnCount == 0) 'repeat_buyer',
    ];
    final recommendedAction = boundedScore >= 75
        ? 'Require call confirmation and partial advance before dispatch.'
        : boundedScore >= 40
        ? 'Confirm address and delivery slot before placing supplier order.'
        : 'Safe to handle as standard COD with regular follow-up.';
    return BuyerRiskProfile(
      id: buyer.id,
      userId: userId,
      siteId: siteId,
      buyerName: buyer.name,
      buyerPhone: buyer.phone,
      riskLevel: riskLevel,
      riskScore: boundedScore,
      blocked: buyer.isBlocked,
      note: buyer.note,
      reasonCodes: reasonCodes,
      recommendedAction: recommendedAction,
      totalOrders: buyer.totalOrders,
      deliveredOrders: buyer.totalDelivered,
      returnCount: buyer.returnCount,
      pendingOrders: buyer.pendingOrders,
      unpaidOrders: buyer.unpaidOrders,
      lastOrderId: buyer.lastOrderId,
      updatedAt: buyer.lastOrderedAt ?? DateTime.now(),
    );
  }

  Future<List<Map<String, dynamic>>> _loadCollection(String collection) async {
    final result = await _client.query(
      QueryOptions(
        document: _listCollectionDocument,
        variables: <String, dynamic>{'collection': collection},
        fetchPolicy: FetchPolicy.noCache,
      ),
    );
    if (result.hasException) throw result.exception!;
    return (result.data?['listCollection'] as List<dynamic>? ??
            const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => Map<String, dynamic>.from(
            jsonDecode(item['payload'] as String? ?? '{}') as Map,
          ),
        )
        .toList(growable: false);
  }

  Future<Map<String, dynamic>?> _loadEntity(
    String collection,
    String id,
  ) async {
    final result = await _client.query(
      QueryOptions(
        document: _getEntityDocument,
        variables: <String, dynamic>{'collection': collection, 'id': id},
        fetchPolicy: FetchPolicy.noCache,
      ),
    );
    if (result.hasException) throw result.exception!;
    final entity = result.data?['getEntity'];
    if (entity is! Map<String, dynamic>) return null;
    return Map<String, dynamic>.from(
      jsonDecode(entity['payload'] as String? ?? '{}') as Map,
    );
  }

  Future<void> _upsertEntity(
    String collection,
    String id,
    Map<String, dynamic> payload,
  ) async {
    final result = await _client.mutate(
      MutationOptions(
        document: _upsertEntityDocument,
        variables: <String, dynamic>{
          'collection': collection,
          'id': id,
          'payload': jsonEncode(payload),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        fetchPolicy: FetchPolicy.noCache,
      ),
    );
    if (result.hasException) throw result.exception!;
  }

  Future<bool> _deleteEntity(String collection, String id) async {
    final result = await _client.mutate(
      MutationOptions(
        document: _deleteEntityDocument,
        variables: <String, dynamic>{'collection': collection, 'id': id},
        fetchPolicy: FetchPolicy.noCache,
      ),
    );
    if (result.hasException) throw result.exception!;
    return result.data?['deleteEntity']?['deleted'] == true;
  }

  String _teamConfigKey(int userId, int siteId) =>
      'team-config-$siteId-$userId';
}
