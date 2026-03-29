import 'package:hive/hive.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';

part 'cart_item_model.g.dart';

@HiveType(typeId: 10)
class CartItem extends HiveObject {
  @HiveField(0)
  final ProductResCommon product;

  @HiveField(1)
  int quantity;

  CartItem({required this.product, required this.quantity});
}
