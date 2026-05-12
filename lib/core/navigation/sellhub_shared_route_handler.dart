import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sellhub/core/share/sellhub_share_payload_codec.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/custom_toast.dart';
import 'package:sellhub/core/utils/route_names.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/data/product_repository.dart';
import 'package:sellhub/features/search/data/models/product_details_to_common_mapper.dart';
import 'package:sellhub/injection_container.dart' as di;

class SellHubSharedRouteHandler {
  const SellHubSharedRouteHandler._();

  static Future<bool> handleRoutePayload(
    BuildContext context, {
    required String routeName,
    Map<String, String>? routeParams,
  }) async {
    if (routeName != RouteNames.sellingList && routeName != RouteNames.cart) {
      return false;
    }
    final sharedItems = SellHubSharePayloadCodec.decodeCartItems(
      routeParams?['cartItems'],
    );
    if (sharedItems.isEmpty) return false;

    final imported = await _importSharedCart(context, sharedItems);
    AppRouter.goNamed(RouteNames.sellingList);
    if (!context.mounted) return true;
    if (imported > 0) {
      CustomToast.success('Shared selling list loaded');
    } else {
      CustomToast.info('Could not load shared selling list');
    }
    return true;
  }

  static Future<int> _importSharedCart(
    BuildContext context,
    List<SharedCartProduct> items,
  ) async {
    final repository = di.sl<ProductRepository>();
    final cartCubit = context.read<CartCubit>();
    final importedProducts = <({ProductResCommon product, int quantity})>[];

    for (final item in items) {
      try {
        final details = await repository.fetchProductDetails(item.hid);
        if (details == null) continue;
        final base = ProductResCommon(
          brands: item.brand?.isNotEmpty == true
              ? <String>[item.brand!]
              : <String>[
                  ...details.brands.map((value) => value.toString()),
                ],
          features: const <Feature>[],
          hid: details.hid ?? item.hid,
          id: details.id,
          images: item.imageUrl?.isNotEmpty == true
              ? <ProductImage>[ProductImage(id: null, image: item.imageUrl)]
              : const <ProductImage>[],
          price: item.price ?? details.price,
          siteId: details.siteId,
          thumbnail: item.imageUrl ?? details.thumbnail,
          title: item.title ?? details.title,
          translation: item.title ?? details.translation,
          variants: const <Variant>[],
          wholesale: const <dynamic>[],
        );
        final product = ProductDetailsToCommonMapper.map(details, base);
        importedProducts.add((product: product, quantity: item.quantity));
      } catch (_) {
        continue;
      }
    }

    if (importedProducts.isEmpty) return 0;
    await cartCubit.replaceWithProducts(importedProducts);
    return importedProducts.length;
  }
}
