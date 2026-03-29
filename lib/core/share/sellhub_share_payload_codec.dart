import 'dart:convert';

import 'package:sellhub/features/cart/data/models/cart_item_model.dart';

class SharedCartProduct {
  const SharedCartProduct({
    required this.hid,
    required this.quantity,
    this.title,
    this.imageUrl,
    this.brand,
    this.price,
  });

  final String hid;
  final int quantity;
  final String? title;
  final String? imageUrl;
  final String? brand;
  final double? price;

  factory SharedCartProduct.fromJson(Map<String, dynamic> json) {
    return SharedCartProduct(
      hid: (json['h'] as String? ?? '').trim(),
      quantity: (json['q'] as num?)?.toInt() ?? 1,
      title: (json['t'] as String?)?.trim(),
      imageUrl: (json['i'] as String?)?.trim(),
      brand: (json['b'] as String?)?.trim(),
      price: (json['p'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'h': hid,
    'q': quantity,
    if (title != null && title!.trim().isNotEmpty) 't': title!.trim(),
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) 'i': imageUrl!.trim(),
    if (brand != null && brand!.trim().isNotEmpty) 'b': brand!.trim(),
    if (price != null && price! > 0) 'p': price,
  };

  bool get isValid => hid.isNotEmpty && quantity > 0;

  static List<SharedCartProduct> fromCartItems(List<CartItem> items) {
    return items
        .map(
          (item) => SharedCartProduct(
            hid: item.product.hid?.trim() ?? '',
            quantity: item.quantity,
            title: item.product.translation?.trim().isNotEmpty == true
                ? item.product.translation!.trim()
                : item.product.title?.trim(),
            imageUrl: item.product.thumbnail?.trim().isNotEmpty == true
                ? item.product.thumbnail!.trim()
                : item.product.images.isNotEmpty
                ? item.product.images.first.image?.trim()
                : null,
            brand: item.product.brands.isNotEmpty
                ? item.product.brands.first.trim()
                : null,
            price: item.product.price,
          ),
        )
        .where((item) => item.isValid)
        .toList(growable: false);
  }
}

class SellHubSharePayloadCodec {
  const SellHubSharePayloadCodec._();

  static String encodeCartItems(List<SharedCartProduct> items) {
    final safeItems = items.where((item) => item.isValid).take(8).toList();
    return base64Url.encode(utf8.encode(jsonEncode(safeItems)));
  }

  static List<SharedCartProduct> decodeCartItems(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <SharedCartProduct>[];
    try {
      final normalized = base64Url.normalize(raw.trim());
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      if (json is! List) return const <SharedCartProduct>[];
      return json
          .whereType<Map>()
          .map(
            (item) => SharedCartProduct.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .where((item) => item.isValid)
          .toList(growable: false);
    } catch (_) {
      return const <SharedCartProduct>[];
    }
  }
}
