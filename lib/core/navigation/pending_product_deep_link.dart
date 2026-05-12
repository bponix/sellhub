import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/store/active_store.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/route_names.dart';
import 'package:sellhub/features/discovery/presentation/store_activator.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/screens/product_details_screen.dart';
import 'package:sellhub/features/shell/presentation/cubit/store_shell_cubit.dart';

class PendingProductDeepLink {
  const PendingProductDeepLink({
    required this.hid,
    required this.siteId,
    this.title,
    this.imageUrl,
    this.brand,
    this.price,
  });

  final String hid;
  final int siteId;
  final String? title;
  final String? imageUrl;
  final String? brand;
  final double? price;

  factory PendingProductDeepLink.fromJson(Map<String, dynamic> json) {
    return PendingProductDeepLink(
      hid: (json['hid'] as String? ?? '').trim(),
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?)?.trim(),
      imageUrl: (json['imageUrl'] as String?)?.trim(),
      brand: (json['brand'] as String?)?.trim(),
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  factory PendingProductDeepLink.fromUri(Uri uri) {
    return PendingProductDeepLink(
      hid: (uri.queryParameters['hid'] ?? '').trim(),
      siteId: int.tryParse(uri.queryParameters['siteId']?.trim() ?? '') ?? 0,
      title: uri.queryParameters['productTitle']?.trim(),
      imageUrl: uri.queryParameters['productImage']?.trim(),
      brand: uri.queryParameters['brand']?.trim(),
      price: double.tryParse(uri.queryParameters['price']?.trim() ?? ''),
    );
  }

  factory PendingProductDeepLink.fromRouteParams(Map<String, String> params) {
    return PendingProductDeepLink(
      hid: (params['hid'] ?? '').trim(),
      siteId: int.tryParse(params['siteId']?.trim() ?? '') ?? 0,
      title: params['productTitle']?.trim(),
      imageUrl: params['productImage']?.trim(),
      brand: params['brand']?.trim(),
      price: double.tryParse(params['price']?.trim() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'hid': hid,
    'siteId': siteId,
    'title': title,
    'imageUrl': imageUrl,
    'brand': brand,
    'price': price,
  };

  bool get isValid => hid.isNotEmpty && siteId > 0;

  ProductResCommon toPlaceholderProduct() {
    return ProductResCommon(
      brands: brand?.isNotEmpty == true ? <String>[brand!] : const <String>[],
      features: const <Feature>[],
      hid: hid,
      id: null,
      images: imageUrl?.isNotEmpty == true
          ? <ProductImage>[ProductImage(id: null, image: imageUrl)]
          : const <ProductImage>[],
      price: price,
      siteId: siteId,
      thumbnail: imageUrl,
      title: title,
      translation: title,
      variants: const <Variant>[],
      wholesale: const <dynamic>[],
    );
  }
}

class PendingProductDeepLinkHandler {
  const PendingProductDeepLinkHandler._();

  static Future<void> persistFromUri(Uri uri) async {
    final payload = PendingProductDeepLink.fromUri(uri);
    await persist(payload);
  }

  static Future<void> persistFromRouteParams(Map<String, String>? params) async {
    if (params == null || params.isEmpty) {
      await LocalStorage.remove(LocalStorage.pendingProductLinkKey);
      return;
    }
    final payload = PendingProductDeepLink.fromRouteParams(params);
    await persist(payload);
  }

  static Future<void> persist(PendingProductDeepLink payload) async {
    if (!payload.isValid) {
      await LocalStorage.remove(LocalStorage.pendingProductLinkKey);
      return;
    }
    await LocalStorage.saveString(
      LocalStorage.pendingProductLinkKey,
      jsonEncode(payload.toJson()),
    );
  }

  static Future<bool> handleRoutePayload(
    BuildContext context, {
    String? routeName,
    Map<String, String>? routeParams,
  }) async {
    if (!_isProductIntent(routeName: routeName, routeParams: routeParams)) {
      return false;
    }
    final payload = PendingProductDeepLink.fromRouteParams(routeParams!);
    if (!payload.isValid) return false;

    final storeContextCubit = context.read<StoreContextCubit>();
    final shellCubit = context.read<StoreShellCubit>();
    final activeStore = storeContextCubit.state.activeStore;

    if (activeStore != null && activeStore.siteId == payload.siteId) {
      await LocalStorage.remove(LocalStorage.pendingProductLinkKey);
      shellCubit.setIndex(0);
      if (!context.mounted) return true;
      Navigator.of(context).push(
        ProductDetailsScreen.route(
          hid: payload.hid,
          product: payload.toPlaceholderProduct(),
        ),
      );
      return true;
    }

    await persist(payload);
    final targetStore = await _resolveStoreForPayload(
      payload: payload,
      routeParams: routeParams,
      activeStore: activeStore,
    );

    if (!context.mounted) return true;

    if (targetStore != null) {
      await StoreActivator.activate(
        context,
        targetStore,
        returnTo: '/${RouteNames.home}',
        shellIndex: 0,
      );
      return true;
    }

    AppRouter.goToHome(context);
    return true;
  }

  static Future<bool> consumeAndOpen(BuildContext context) async {
    final storeContextCubit = context.read<StoreContextCubit>();
    final shellCubit = context.read<StoreShellCubit>();
    final navigator = Navigator.of(context);
    final raw = await LocalStorage.getString(
      LocalStorage.pendingProductLinkKey,
    );
    if (raw == null || raw.isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await LocalStorage.remove(LocalStorage.pendingProductLinkKey);
        return false;
      }
      final payload = PendingProductDeepLink.fromJson(decoded);
      final activeStore = storeContextCubit.state.activeStore;
      if (!payload.isValid ||
          activeStore == null ||
          activeStore.siteId != payload.siteId) {
        return false;
      }
      await LocalStorage.remove(LocalStorage.pendingProductLinkKey);
      shellCubit.setIndex(0);
      navigator.push(
        ProductDetailsScreen.route(
          hid: payload.hid,
          product: payload.toPlaceholderProduct(),
        ),
      );
      return true;
    } catch (_) {
      await LocalStorage.remove(LocalStorage.pendingProductLinkKey);
      return false;
    }
  }

  static bool _isProductIntent({
    String? routeName,
    Map<String, String>? routeParams,
  }) {
    if (routeParams == null || routeParams.isEmpty) return false;
    final hid = routeParams['hid']?.trim();
    final siteId = int.tryParse(routeParams['siteId']?.trim() ?? '');
    if (hid == null || hid.isEmpty || siteId == null || siteId <= 0) {
      return false;
    }
    return routeName == null ||
        routeName.isEmpty ||
        routeName == RouteNames.home;
  }

  static Future<ActiveStore?> _resolveStoreForPayload({
    required PendingProductDeepLink payload,
    required Map<String, String>? routeParams,
    required ActiveStore? activeStore,
  }) async {
    if (activeStore != null && activeStore.siteId == payload.siteId) {
      return activeStore;
    }

    final domain = routeParams?['domain']?.trim();
    if (domain != null && domain.isNotEmpty) {
      return ActiveStore(
        siteId: payload.siteId,
        domain: domain,
        title: routeParams?['title']?.trim(),
        logoUrl: routeParams?['logo']?.trim(),
      );
    }

    final recentStores = await LocalStorage.getRecentStores();
    for (final store in recentStores) {
      if (store.siteId == payload.siteId) {
        return store;
      }
    }
    return null;
  }
}
