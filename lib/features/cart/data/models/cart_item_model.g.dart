// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CartItemAdapter extends TypeAdapter<CartItem> {
  @override
  final int typeId = 10;

  @override
  CartItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CartItem(
      product: fields[0] as ProductResCommon,
      quantity: fields[1] as int,
      sellPrice:
          (fields[2] as int?) ??
          ((fields[4] as int?) ??
              (fields[3] as int?) ??
              (((fields[0] as ProductResCommon).maxResellPrice ??
                          (fields[0] as ProductResCommon).minResellPrice ??
                          (fields[0] as ProductResCommon).price ??
                          0)
                      .round())),
      minSellPrice:
          (fields[3] as int?) ??
          (((fields[0] as ProductResCommon).minResellPrice ??
                      (fields[0] as ProductResCommon).price ??
                      0)
                  .round()),
      maxSellPrice:
          (fields[4] as int?) ??
          (((fields[0] as ProductResCommon).maxResellPrice ??
                      (fields[0] as ProductResCommon).minResellPrice ??
                      (fields[0] as ProductResCommon).price ??
                      0)
                  .round()),
    );
  }

  @override
  void write(BinaryWriter writer, CartItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.product)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.sellPrice)
      ..writeByte(3)
      ..write(obj.minSellPrice)
      ..writeByte(4)
      ..write(obj.maxSellPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
