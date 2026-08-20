import 'package:equatable/equatable.dart';
import 'package:sellhub/features/cart/data/models/cart_item_model.dart';

class CartState extends Equatable {
  const CartState({this.items = const <CartItem>[]});

  final List<CartItem> items;

  double get totalAmount {
    return items.fold(
      0,
      (sum, item) => sum + (item.product.price! * item.quantity),
    );
  }

  double get totalSellAmount {
    return items.fold(0, (sum, item) => sum + (item.sellPrice * item.quantity));
  }

  double get totalProfitAmount {
    return items.fold(
      0,
      (sum, item) =>
          sum +
          ((item.sellPrice - (item.product.price?.round() ?? 0)) *
              item.quantity),
    );
  }

  double get totalCompareAmount {
    return items.fold(
      0,
      (sum, item) => sum + (item.product.comparePrice! * item.quantity),
    );
  }

  int get totalItems {
    return items.fold(0, (previous, element) => previous + element.quantity);
  }

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }

  @override
  List<Object?> get props => [items];
}
