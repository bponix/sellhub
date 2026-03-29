// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_res_common.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductResCommonAdapter extends TypeAdapter<ProductResCommon> {
  @override
  final int typeId = 0;

  @override
  ProductResCommon read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductResCommon(
      affiliateCommission: fields[0] as double?,
      brands: (fields[1] as List).cast<String>(),
      cashback: fields[2] as double?,
      comparePrice: fields[3] as double?,
      currency: fields[4] as String?,
      deliveryCharge: fields[5] as double?,
      discount: fields[6] as double?,
      isExclusive: fields[7] as bool?,
      features: (fields[8] as List).cast<Feature>(),
      flashPrice: fields[9] as double?,
      hid: fields[10] as String?,
      id: fields[11] as int?,
      images: (fields[12] as List).cast<ProductImage>(),
      isActive: fields[13] as bool?,
      isContinueSelling: fields[14] as bool?,
      isFlash: fields[15] as bool?,
      isOneTime: fields[16] as bool?,
      isNegotiable: fields[17] as bool?,
      isVariant: fields[18] as bool?,
      maxOrder: fields[19] as int?,
      maxResellPrice: fields[20] as double?,
      minResellPrice: fields[21] as double?,
      minOrder: fields[22] as int?,
      price: fields[23] as double?,
      productType: fields[24] as int?,
      quantity: fields[25] as double?,
      rating: fields[26] as double?,
      ratingTotal: fields[27] as int?,
      rewardPoints: fields[28] as double?,
      siteId: fields[29] as int?,
      sku: fields[30] as String?,
      slug: fields[31] as String?,
      thumbnail: fields[32] as String?,
      title: fields[33] as String?,
      translation: fields[34] as String?,
      unit: fields[35] as double?,
      unitType: fields[36] as int?,
      variants: (fields[37] as List).cast<Variant>(),
      vat: fields[38] as double?,
      weight: fields[39] as double?,
      wholesale: (fields[40] as List).cast<dynamic>(),
      wholesalePrice: fields[41] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductResCommon obj) {
    writer
      ..writeByte(42)
      ..writeByte(0)
      ..write(obj.affiliateCommission)
      ..writeByte(1)
      ..write(obj.brands)
      ..writeByte(2)
      ..write(obj.cashback)
      ..writeByte(3)
      ..write(obj.comparePrice)
      ..writeByte(4)
      ..write(obj.currency)
      ..writeByte(5)
      ..write(obj.deliveryCharge)
      ..writeByte(6)
      ..write(obj.discount)
      ..writeByte(7)
      ..write(obj.isExclusive)
      ..writeByte(8)
      ..write(obj.features)
      ..writeByte(9)
      ..write(obj.flashPrice)
      ..writeByte(10)
      ..write(obj.hid)
      ..writeByte(11)
      ..write(obj.id)
      ..writeByte(12)
      ..write(obj.images)
      ..writeByte(13)
      ..write(obj.isActive)
      ..writeByte(14)
      ..write(obj.isContinueSelling)
      ..writeByte(15)
      ..write(obj.isFlash)
      ..writeByte(16)
      ..write(obj.isOneTime)
      ..writeByte(17)
      ..write(obj.isNegotiable)
      ..writeByte(18)
      ..write(obj.isVariant)
      ..writeByte(19)
      ..write(obj.maxOrder)
      ..writeByte(20)
      ..write(obj.maxResellPrice)
      ..writeByte(21)
      ..write(obj.minResellPrice)
      ..writeByte(22)
      ..write(obj.minOrder)
      ..writeByte(23)
      ..write(obj.price)
      ..writeByte(24)
      ..write(obj.productType)
      ..writeByte(25)
      ..write(obj.quantity)
      ..writeByte(26)
      ..write(obj.rating)
      ..writeByte(27)
      ..write(obj.ratingTotal)
      ..writeByte(28)
      ..write(obj.rewardPoints)
      ..writeByte(29)
      ..write(obj.siteId)
      ..writeByte(30)
      ..write(obj.sku)
      ..writeByte(31)
      ..write(obj.slug)
      ..writeByte(32)
      ..write(obj.thumbnail)
      ..writeByte(33)
      ..write(obj.title)
      ..writeByte(34)
      ..write(obj.translation)
      ..writeByte(35)
      ..write(obj.unit)
      ..writeByte(36)
      ..write(obj.unitType)
      ..writeByte(37)
      ..write(obj.variants)
      ..writeByte(38)
      ..write(obj.vat)
      ..writeByte(39)
      ..write(obj.weight)
      ..writeByte(40)
      ..write(obj.wholesale)
      ..writeByte(41)
      ..write(obj.wholesalePrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductResCommonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FeatureAdapter extends TypeAdapter<Feature> {
  @override
  final int typeId = 1;

  @override
  Feature read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Feature(key: fields[0] as String?, value: fields[1] as String?);
  }

  @override
  void write(BinaryWriter writer, Feature obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeatureAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductImageAdapter extends TypeAdapter<ProductImage> {
  @override
  final int typeId = 2;

  @override
  ProductImage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductImage(id: fields[0] as int?, image: fields[1] as String?);
  }

  @override
  void write(BinaryWriter writer, ProductImage obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.image);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VariantAdapter extends TypeAdapter<Variant> {
  @override
  final int typeId = 3;

  @override
  Variant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Variant(
      comparePrice: fields[0] as double?,
      cost: fields[1] as double?,
      currency: fields[2] as String?,
      id: fields[3] as int?,
      imageIndex: fields[4] as int?,
      price: fields[5] as double?,
      priority: fields[6] as int?,
      quantity: fields[7] as double?,
      title: fields[8] as String?,
      variant: (fields[9] as List).cast<Feature>(),
      weight: fields[10] as double?,
      wholesalePrice: fields[11] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Variant obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.comparePrice)
      ..writeByte(1)
      ..write(obj.cost)
      ..writeByte(2)
      ..write(obj.currency)
      ..writeByte(3)
      ..write(obj.id)
      ..writeByte(4)
      ..write(obj.imageIndex)
      ..writeByte(5)
      ..write(obj.price)
      ..writeByte(6)
      ..write(obj.priority)
      ..writeByte(7)
      ..write(obj.quantity)
      ..writeByte(8)
      ..write(obj.title)
      ..writeByte(9)
      ..write(obj.variant)
      ..writeByte(10)
      ..write(obj.weight)
      ..writeByte(11)
      ..write(obj.wholesalePrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
