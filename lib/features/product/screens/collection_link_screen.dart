import 'package:flutter/material.dart';
import 'package:sellhub/core/navigation/unsupported_link_screen.dart';
import 'package:sellhub/features/product/screens/flash_saleProduct.dart';
import 'package:sellhub/features/product/screens/new_arrival_product.dart';

class CollectionLinkScreen extends StatelessWidget {
  const CollectionLinkScreen({
    super.key,
    required this.collectionType,
    this.title,
  });

  final String collectionType;
  final String? title;

  static const String newArrivals = 'new-arrivals';
  static const String flashSale = 'flash-sale';

  @override
  Widget build(BuildContext context) {
    switch (collectionType.trim().toLowerCase()) {
      case newArrivals:
        return const NewArrivalProductScreen();
      case flashSale:
        return const FlashSaleProduct();
      default:
        return const UnsupportedLinkScreen();
    }
  }
}
