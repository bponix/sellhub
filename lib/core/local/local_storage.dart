import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:sellhub/core/store/active_store.dart';
import 'package:sellhub/core/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'recent_product.dart';

class LocalStorage {
  LocalStorage._();
  static final LocalStorage instance = LocalStorage._();
  static const String pendingDeepLinkKey = 'pending_deep_link';
  static const String pendingProductLinkKey = 'pending_product_link';
  static const String activeStoreKey = 'active_store';
  static const String recentStoresKey = 'recent_stores';
  static const String recentProductsKey = 'recent_products';
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
    if (siteId == null) return products;
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
}
