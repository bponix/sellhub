import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:sellhub/core/store/active_store.dart';
import 'package:sellhub/core/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sellhub/features/orders/data/models/order_issue_report.dart';
import 'package:sellhub/features/profile/data/model/buyer_book_profile.dart';
import 'package:sellhub/features/profile/data/model/repeat_sell_reminder.dart';

import 'recent_product.dart';

class LocalStorage {
  LocalStorage._();
  static final LocalStorage instance = LocalStorage._();
  static const String pendingDeepLinkKey = 'pending_deep_link';
  static const String pendingProductLinkKey = 'pending_product_link';
  static const String activeStoreKey = 'active_store';
  static const String recentStoresKey = 'recent_stores';
  static const String recentProductsKey = 'recent_products';
  static const String pendingBuyerKey = 'pending_buyer';
  static const String repeatSellRemindersKey = 'repeat_sell_reminders';
  static const String resellerOnboardingProfileKey =
      'reseller_onboarding_profile';
  static const String orderIssueReportsKey = 'order_issue_reports';
  static const String backendTruthModeKey = 'backend_truth_mode';
  factory LocalStorage() {
    return instance;
  }

  static Future<void> init() async {
    await Hive.initFlutter();
    // Boxes will be opened by their respective providers with correct types
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kAuthTokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.kAuthTokenKey);
  }

  static Future<void> saveUserID(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.kAuthUserID, id);
  }

  static Future<int?> getUserID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.kAuthUserID);
  }

  static Future<void> saveCustomerID(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.kAuthCustomerID, id);
  }

  static Future<int?> getCustomerID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.kAuthCustomerID);
  }

  static Future<void> setLogin(bool isLogin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.kLoginKey, isLogin);
  }

  static Future<bool> isLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.kLoginKey) ?? false;
  }

  static Future<void> setGuest(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.kGuestKey, isGuest);
  }

  static Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.kGuestKey) ?? false;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.kAuthTokenKey);
    await prefs.remove(AppConstants.kGuestKey);
    await prefs.remove(AppConstants.kLoginKey);
    await prefs.remove(AppConstants.kAuthUserID);
    await prefs.remove(AppConstants.kAuthCustomerID);
  }

  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> saveStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  static Future<List<String>> getStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? const <String>[];
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> saveActiveStore(ActiveStore store) async {
    await saveString(activeStoreKey, jsonEncode(store.toJson()));
  }

  static Future<ActiveStore?> getActiveStore() async {
    final raw = await getString(activeStoreKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['siteId'] == null || decoded['domain'] == null) return null;
      return ActiveStore.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearActiveStore() => remove(activeStoreKey);

  static Future<void> pushRecentStore(ActiveStore store) async {
    final stores = await getRecentStores();
    final deduped = <ActiveStore>[
      store,
      ...stores.where((item) => item.siteId != store.siteId),
    ].take(6).toList(growable: false);
    await saveString(
      recentStoresKey,
      jsonEncode(deduped.map((item) => item.toJson()).toList(growable: false)),
    );
  }

  static Future<List<ActiveStore>> getRecentStores() async {
    final raw = await getString(recentStoresKey);
    if (raw == null || raw.isEmpty) return const <ActiveStore>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <ActiveStore>[];
      return decoded
          .whereType<Map>()
          .map(
            (item) => ActiveStore.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .where((item) => item.domain.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <ActiveStore>[];
    }
  }

  static Future<void> pushRecentProduct(RecentProduct product) async {
    if (product.hid.isEmpty || product.siteId <= 0) return;
    final products = await getRecentProducts(siteId: product.siteId);
    final deduped = <RecentProduct>[
      product,
      ...products.where((item) => item.hid != product.hid),
    ].take(12).toList(growable: false);
    final allProducts = await _getAllRecentProducts();
    final merged = <RecentProduct>[
      ...deduped,
      ...allProducts.where(
        (item) => item.siteId != product.siteId && item.hid != product.hid,
      ),
    ].take(30).toList(growable: false);
    await saveString(
      recentProductsKey,
      jsonEncode(merged.map((item) => item.toJson()).toList(growable: false)),
    );
  }

  static Future<List<RecentProduct>> getRecentProducts({int? siteId}) async {
    final products = await _getAllRecentProducts();
    if (siteId == null || siteId <= 0) return products;
    return products
        .where((item) => item.siteId == siteId)
        .toList(growable: false);
  }

  static Future<List<RecentProduct>> _getAllRecentProducts() async {
    final raw = await getString(recentProductsKey);
    if (raw == null || raw.isEmpty) return const <RecentProduct>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <RecentProduct>[];
      return decoded
          .whereType<Map>()
          .map(
            (item) => RecentProduct.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .where((item) => item.hid.isNotEmpty && item.title.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <RecentProduct>[];
    }
  }

  static Future<void> savePendingBuyer(BuyerBookProfile buyer) async {
    await saveString(pendingBuyerKey, jsonEncode(buyer.toJson()));
  }

  static Future<BuyerBookProfile?> getPendingBuyer() async {
    final raw = await getString(pendingBuyerKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return BuyerBookProfile.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearPendingBuyer() => remove(pendingBuyerKey);

  static Future<List<RepeatSellReminder>> getRepeatSellReminders() async {
    final raw = await getString(repeatSellRemindersKey);
    if (raw == null || raw.isEmpty) return const <RepeatSellReminder>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <RepeatSellReminder>[];
      return decoded
          .whereType<Map>()
          .map(
            (item) => RepeatSellReminder.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const <RepeatSellReminder>[];
    }
  }

  static Future<void> saveRepeatSellReminders(
    List<RepeatSellReminder> reminders,
  ) async {
    await saveString(
      repeatSellRemindersKey,
      jsonEncode(
        reminders.map((item) => item.toJson()).toList(growable: false),
      ),
    );
  }

  static Future<void> saveResellerOnboardingProfile(
    Map<String, dynamic> profile,
  ) async {
    await saveString(resellerOnboardingProfileKey, jsonEncode(profile));
  }

  static Future<Map<String, dynamic>?> getResellerOnboardingProfile() async {
    final raw = await getString(resellerOnboardingProfileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearResellerOnboardingProfile() =>
      remove(resellerOnboardingProfileKey);

  static Future<void> saveBackendTruthMode(String mode) async {
    await saveString(
      backendTruthModeKey,
      mode.trim().isEmpty ? 'local' : mode.trim(),
    );
  }

  static Future<String> getBackendTruthMode() async {
    final mode = await getString(backendTruthModeKey);
    if (mode == null || mode.trim().isEmpty) return 'local';
    return mode.trim();
  }

  static Future<List<OrderIssueReport>> getOrderIssueReports() async {
    final raw = await getString(orderIssueReportsKey);
    if (raw == null || raw.isEmpty) return const <OrderIssueReport>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <OrderIssueReport>[];
      return decoded
          .whereType<Map>()
          .map(
            (item) => OrderIssueReport.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .where((item) => item.orderId.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <OrderIssueReport>[];
    }
  }

  static Future<void> saveOrderIssueReports(
    List<OrderIssueReport> reports,
  ) async {
    await saveString(
      orderIssueReportsKey,
      jsonEncode(
        reports.map((item) => item.toJson()).toList(growable: false),
      ),
    );
  }

  static Future<void> upsertOrderIssueReport(OrderIssueReport report) async {
    final existing = await getOrderIssueReports();
    final merged = <OrderIssueReport>[
      report,
      ...existing.where((item) => item.id != report.id),
    ];
    await saveOrderIssueReports(merged);
  }

  static Future<OrderIssueReport?> getLatestOrderIssueReport({
    required int siteId,
    required String orderId,
  }) async {
    final reports = await getOrderIssueReports();
    final matches = reports
        .where(
          (item) =>
              item.siteId == siteId &&
              item.orderId.trim().toLowerCase() == orderId.trim().toLowerCase(),
        )
        .toList(growable: false);
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return matches.first;
  }

  static Future<void> upsertRepeatSellReminder(RepeatSellReminder reminder) async {
    final reminders = await getRepeatSellReminders();
    final updated = <RepeatSellReminder>[
      reminder,
      ...reminders.where((item) => item.id != reminder.id),
    ];
    await saveRepeatSellReminders(updated);
  }

  static Future<void> deleteRepeatSellReminder(String id) async {
    final reminders = await getRepeatSellReminders();
    await saveRepeatSellReminders(
      reminders.where((item) => item.id != id).toList(growable: false),
    );
  }
}
