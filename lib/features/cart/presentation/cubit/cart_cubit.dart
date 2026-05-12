import 'package:hive_flutter/hive_flutter.dart';
import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/core/utils/constants.dart';
import 'package:sellhub/features/cart/data/models/cart_item_model.dart';
import 'package:sellhub/features/cart/presentation/cubit/cart_state.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';

class CartCubit extends SafeCubit<CartState> {
  CartCubit() : super(const CartState());

  Box<CartItem>? _box;

  Future<void> init() async {
    if (Hive.isBoxOpen(AppConstants.kCartBox)) {
      _box = Hive.box<CartItem>(AppConstants.kCartBox);
    } else {
      _box = await Hive.openBox<CartItem>(AppConstants.kCartBox);
    }
    emit(state.copyWith(items: _box!.values.toList()));
  }

  int _normalizedMinSellPrice(ProductResCommon product) {
    final base = product.price?.round() ?? 0;
    final min = product.minResellPrice?.round();
    final max = product.maxResellPrice?.round();
    final floor = min ?? max ?? base;
    if (floor <= 0) return base;
    return floor < base ? base : floor;
  }

  int _normalizedMaxSellPrice(ProductResCommon product) {
    final floor = _normalizedMinSellPrice(product);
    final max = product.maxResellPrice?.round() ?? floor;
    if (max < floor) return floor;
    return max <= 0 ? floor : max;
  }

  int defaultSellPrice(ProductResCommon product) {
    final min = _normalizedMinSellPrice(product);
    final max = _normalizedMaxSellPrice(product);
    if (max >= min && max > 0) return max;
    if (min > 0) return min;
    return product.price?.round() ?? 0;
  }

  Future<void> addToCart(ProductResCommon product, {int? sellPrice}) async {
    await addProduct(product, quantity: 1, sellPrice: sellPrice);
  }

  Future<void> addProduct(
    ProductResCommon product, {
    required int quantity,
    int? sellPrice,
  }) async {
    if (_box == null) await init();
    if (quantity <= 0) return;
    final items = [...state.items];
    final index = items.indexWhere((item) => item.product.id == product.id);
    final minSellPrice = _normalizedMinSellPrice(product);
    final maxSellPrice = _normalizedMaxSellPrice(product);
    final resolvedSellPrice = (sellPrice ?? defaultSellPrice(product)).clamp(
      minSellPrice,
      maxSellPrice,
    );
    if (index >= 0) {
      items[index].quantity += quantity;
      items[index].minSellPrice = minSellPrice;
      items[index].maxSellPrice = maxSellPrice;
      if (sellPrice != null) {
        items[index].sellPrice = resolvedSellPrice;
      }
      await items[index].save();
    } else {
      final newItem = CartItem(
        product: product,
        quantity: quantity,
        sellPrice: resolvedSellPrice,
        minSellPrice: minSellPrice,
        maxSellPrice: maxSellPrice,
      );
      await _box!.add(newItem);
      items.add(newItem);
    }
    emit(state.copyWith(items: items));
  }

  Future<void> replaceWithProducts(
    List<({ProductResCommon product, int quantity})> items,
  ) async {
    if (_box == null) await init();
    await _box!.clear();
    final newItems = <CartItem>[];
    for (final item in items) {
      if (item.quantity <= 0) continue;
      final minSellPrice = _normalizedMinSellPrice(item.product);
      final maxSellPrice = _normalizedMaxSellPrice(item.product);
      final cartItem = CartItem(
        product: item.product,
        quantity: item.quantity,
        sellPrice: defaultSellPrice(item.product),
        minSellPrice: minSellPrice,
        maxSellPrice: maxSellPrice,
      );
      await _box!.add(cartItem);
      newItems.add(cartItem);
    }
    emit(state.copyWith(items: newItems));
  }

  Future<void> removeFromCart(CartItem item) async {
    final items = [...state.items]..remove(item);
    await item.delete();
    emit(state.copyWith(items: items));
  }

  Future<void> clearCart() async {
    await _box!.clear();
    emit(const CartState(items: <CartItem>[]));
  }

  Future<void> updateQuantity(CartItem item, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(item);
      return;
    }
    item.quantity = quantity;
    await item.save();
    emit(state.copyWith(items: [...state.items]));
  }

  Future<void> updateSellPrice(CartItem item, int sellPrice) async {
    final clamped = sellPrice.clamp(item.minSellPrice, item.maxSellPrice);
    item.sellPrice = clamped;
    await item.save();
    emit(state.copyWith(items: [...state.items]));
  }

  bool isCart(int productId) {
    return state.items.any((item) => item.product.id == productId);
  }
}
