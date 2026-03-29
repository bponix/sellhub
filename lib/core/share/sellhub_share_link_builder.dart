import 'package:sellhub/core/store/active_store.dart';
import 'package:sellhub/core/share/sellhub_share_payload_codec.dart';
import 'package:sellhub/core/utils/route_names.dart';
import 'package:sellhub/features/cart/data/models/cart_item_model.dart';
import 'package:sellhub/features/cart/data/models/order_create_res.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';

class SellHubShareLinkBuilder {
  const SellHubShareLinkBuilder._();

  static Uri buildStoreUri({required ActiveStore store, String? referCode}) {
    return Uri.https('sellhub.bponi.com', '/app', <String, String>{
      'domain': store.domain,
      'siteId': '${store.siteId}',
      if (_hasValue(store.title)) 'title': store.title!.trim(),
      if (_hasValue(store.logoUrl)) 'logo': store.logoUrl!.trim(),
      if (_hasValue(referCode)) 'refer': referCode!.trim(),
    });
  }

  static Uri buildProductUri({
    required ActiveStore store,
    required ProductResCommon product,
    String? referCode,
  }) {
    return buildStoreUri(store: store, referCode: referCode).replace(
      queryParameters: <String, String>{
        ...buildStoreUri(store: store, referCode: referCode).queryParameters,
        if (_hasValue(product.hid)) 'hid': product.hid!.trim(),
        if (_hasValue(_productTitle(product)))
          'productTitle': _productTitle(product)!,
        if (_hasValue(_productImage(product)))
          'productImage': _productImage(product)!,
        if ((product.price ?? 0) > 0) 'price': '${product.price!.round()}',
        if (_hasValue(_firstBrand(product))) 'brand': _firstBrand(product)!,
      },
    );
  }

  static Uri buildCartUri({
    required ActiveStore store,
    required List<CartItem> items,
  }) {
    final sharedItems = SharedCartProduct.fromCartItems(items);
    return buildStoreUri(store: store).replace(
      queryParameters: <String, String>{
        ...buildStoreUri(store: store).queryParameters,
        'routeName': RouteNames.cart,
        'cartItems': SellHubSharePayloadCodec.encodeCartItems(sharedItems),
      },
    );
  }

  static String buildCartShareText({
    required ActiveStore store,
    required List<CartItem> items,
  }) {
    final sharedItems = SharedCartProduct.fromCartItems(items);
    final titles = sharedItems
        .take(3)
        .map((item) => item.title?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final storeLabel = store.title?.trim().isNotEmpty == true
        ? store.title!.trim()
        : store.domain;
    final intro = titles.isEmpty
        ? 'Open this shared cart from $storeLabel.'
        : 'Shop this shared cart from $storeLabel: ${titles.join(', ')}';
    return '$intro\n${buildCartUri(store: store, items: items)}';
  }

  static Uri buildCollectionUri({
    required ActiveStore store,
    required String collectionType,
    String? title,
  }) {
    return buildStoreUri(store: store).replace(
      queryParameters: <String, String>{
        ...buildStoreUri(store: store).queryParameters,
        'routeName': RouteNames.collection,
        'collectionType': collectionType.trim(),
        if (_hasValue(title)) 'collectionTitle': title!.trim(),
      },
    );
  }

  static String buildCollectionShareText({
    required ActiveStore store,
    required String collectionType,
    required String title,
  }) {
    final storeLabel = store.title?.trim().isNotEmpty == true
        ? store.title!.trim()
        : store.domain;
    return '$title from $storeLabel\n${buildCollectionUri(store: store, collectionType: collectionType, title: title)}';
  }

  static String buildOrderShareText({
    required ActiveStore store,
    required OrderCreateRes order,
  }) {
    final uri = _orderPrimaryProductUri(store: store, order: order);
    final lines = order.lines
        .take(3)
        .map((line) => line.productName?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final intro = lines.isEmpty
        ? 'I just placed an order from ${store.title?.trim().isNotEmpty == true ? store.title!.trim() : store.domain}.'
        : 'I just ordered ${lines.join(', ')} from ${store.title?.trim().isNotEmpty == true ? store.title!.trim() : store.domain}.';
    return '$intro\nTrack store and shop again:\n$uri';
  }

  static Uri buildReferralUri({
    required ActiveStore store,
    required String referCode,
  }) {
    return buildStoreUri(store: store, referCode: referCode);
  }

  static String buildProductShareText({
    required ActiveStore store,
    required ProductResCommon product,
    String? referCode,
  }) {
    final title = _productTitle(product) ?? 'Product';
    final brand = _firstBrand(product);
    final price = (product.price ?? 0) > 0
        ? '৳${product.price!.round()}'
        : null;
    final parts = <String>[
      title,
      if (_hasValue(brand)) brand!,
      if (_hasValue(price)) price!,
      buildProductUri(
        store: store,
        product: product,
        referCode: referCode,
      ).toString(),
    ];
    return parts.join('\n');
  }

  static String buildReferralShareText({
    required ActiveStore store,
    required String referCode,
    String? rewardLabel,
  }) {
    final storeLabel = store.title?.trim().isNotEmpty == true
        ? store.title!.trim()
        : store.domain;
    final rewardCopy = rewardLabel?.trim().isNotEmpty == true
        ? '${rewardLabel!.trim()}\n'
        : '';
    return 'Shop on $storeLabel with my referral code.\n${rewardCopy}Referral code: $referCode\n${buildReferralUri(store: store, referCode: referCode)}';
  }

  static Uri _orderPrimaryProductUri({
    required ActiveStore store,
    required OrderCreateRes order,
  }) {
    Line? primaryLine;
    for (final line in order.lines) {
      if ((line.productHid ?? '').trim().isNotEmpty) {
        primaryLine = line;
        break;
      }
    }
    primaryLine ??= order.lines.isNotEmpty ? order.lines.first : null;
    if (primaryLine == null) {
      return buildStoreUri(store: store);
    }
    final hid = primaryLine.productHid?.trim();
    if (hid == null || hid.isEmpty) {
      return buildStoreUri(store: store);
    }
    return buildStoreUri(store: store).replace(
      queryParameters: <String, String>{
        ...buildStoreUri(store: store).queryParameters,
        'hid': hid,
        if (_hasValue(primaryLine.productName))
          'productTitle': primaryLine.productName!.trim(),
        if (_hasValue(primaryLine.image))
          'productImage': primaryLine.image!.trim(),
        if ((primaryLine.price ?? 0) > 0) 'price': '${primaryLine.price}',
      },
    );
  }

  static String? _productTitle(ProductResCommon product) {
    final translation = product.translation?.trim();
    if (_hasValue(translation)) return translation;
    final title = product.title?.trim();
    if (_hasValue(title)) return title;
    return null;
  }

  static String? _productImage(ProductResCommon product) {
    final thumbnail = product.thumbnail?.trim();
    if (_hasValue(thumbnail)) return thumbnail;
    final firstImage = product.images.isNotEmpty
        ? product.images.first.image?.trim()
        : null;
    if (_hasValue(firstImage)) return firstImage;
    return null;
  }

  static String? _firstBrand(ProductResCommon product) {
    if (product.brands.isEmpty) return null;
    final brand = product.brands.first.trim();
    return _hasValue(brand) ? brand : null;
  }

  static bool _hasValue(String? value) =>
      value != null && value.trim().isNotEmpty;
}
