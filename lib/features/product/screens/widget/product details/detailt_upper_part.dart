import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sellhub/core/product_viability/product_viability.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import '../../../../../core/widget/app_huge_icon.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../data/models/product_details.dart';
import '../../../presentation/cubit/product_details_cubit.dart';
import 'package:hugeicons/hugeicons.dart';

class titlePriceColor extends StatelessWidget {
  const titlePriceColor({
    super.key,
    required this.product,
    required this.textTheme,
  });

  final ProductDetailsRes? product;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProductDetailsCubit>().state;
    final viability = state.baseProduct == null
        ? null
        : ProductViabilityEngine.build(state.baseProduct!);
    final basePrice = product?.price?.toInt() ?? 0;
    final minSellPrice =
        state.baseProduct?.minResellPrice?.round() ??
        product?.minResellPrice?.round() ??
        basePrice;
    final maxSellPrice =
        state.baseProduct?.maxResellPrice?.round() ??
        product?.maxResellPrice?.round() ??
        minSellPrice;
    //print(jsonEncode(product?.variants));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: AppColor.text.withValues(alpha: 0.025),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34.r,
                    height: 34.r,
                    decoration: BoxDecoration(
                      color: AppColor.safe1,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: AppHugeIcon(
                      HugeIcons.strokeRoundedShoppingBag01,
                      size: 16.r,
                      color: AppColor.primary,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      product?.translation ?? product?.title ?? 'Unknown Title',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColor.text,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (product?.isFlash ?? false)
                          ? '৳${convertToBengaliNumber(product?.flashPrice?.toInt() ?? 0)}'
                          : '৳${convertToBengaliNumber(product?.price?.toInt() ?? 0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColor.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  if ((product?.comparePrice ?? 0) > 0)
                    Flexible(
                      child: Text(
                        '৳${convertToBengaliNumber(product?.comparePrice?.toInt() ?? 0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColor.secondary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColor.primary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.safe1,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      (product?.quantity ?? 0) > 0 ? 'In stock' : 'Low stock',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColor.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColor.safe.withValues(alpha: 0.9),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seller snapshot',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DecisionPill(
                          icon: HugeIcons.strokeRoundedMoneyBag02,
                          label:
                              'Margin ৳${convertToBengaliNumber((minSellPrice - basePrice).clamp(0, 1 << 30))}-${convertToBengaliNumber((maxSellPrice - basePrice).clamp(0, 1 << 30))}',
                        ),
                        if (viability != null)
                          _DecisionPill(
                            icon: HugeIcons.strokeRoundedShield01,
                            label: 'Trust ${viability.trustScore.round()}',
                          ),
                        if (viability != null)
                          _DecisionPill(
                            icon: HugeIcons.strokeRoundedShare08,
                            label:
                                'Share ${viability.shareabilityScore.round()}',
                          ),
                        if (viability != null)
                          _DecisionPill(
                            icon: HugeIcons.strokeRoundedAlert02,
                            label:
                                'Risk ${viabilityRiskLabel(viability.deliveryRisk)}',
                          ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Quick-order friendly when your buyer price stays inside the allowed sell window.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColor.secondary,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        if (product?.variants.isNotEmpty ?? false)
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColor.text.withValues(alpha: 0.02),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.variants[0].variant[0].key?.toUpperCase() ?? 'COLOR',
                  style: const TextStyle(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: product?.variants.length ?? 0,
                    itemBuilder: (context, index) {
                      final variant = product?.variants[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            context.read<ProductDetailsCubit>().setVariantIndex(
                              index,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: state.variantIndex == index
                                  ? AppColor.primary
                                  : AppColor.safe1.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Center(
                              child: Text(
                                variant?.title ?? '',
                                style: TextStyle(
                                  color: state.variantIndex == index
                                      ? Colors.white
                                      : AppColor.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DecisionPill extends StatelessWidget {
  const _DecisionPill({required this.icon, required this.label});

  final List<List<dynamic>> icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.safe),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppHugeIcon(icon, size: 14, color: AppColor.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
