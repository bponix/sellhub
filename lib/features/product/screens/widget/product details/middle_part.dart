import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../../../core/utils/custom_toast.dart';
import '../../../../../core/widget/app_huge_icon.dart';
import '../../../../favourite/presentation/cubit/favourite_cubit.dart';
import '../../../../favourite/presentation/cubit/favourite_state.dart';
import '../../../data/models/product_details.dart';
import '../../../data/models/product_res_common.dart';

class ProductDetailsMiddlePart extends StatelessWidget {
  const ProductDetailsMiddlePart({
    super.key,
    required this.product,
    required this.productResCommon,
  });

  final ProductDetailsRes? product;
  final ProductResCommon productResCommon;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(color: AppColor.grey, fontSize: 12.sp);
    final valueStyle = TextStyle(color: AppColor.primary, fontSize: 12.sp);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
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
              const _DetailSectionLead(
                icon: HugeIcons.strokeRoundedInformationCircle,
                title: 'Product details',
              ),
              SizedBox(height: 12.h),
              if (product?.features.isNotEmpty ?? false)
                _MetaLine(
                  label: 'Category',
                  value: product?.features[0].value ?? '',
                  labelStyle: labelStyle,
                  valueStyle: valueStyle,
                ),
              _MetaLine(
                label: 'Stock',
                value: product?.quantity?.toStringAsFixed(0) ?? '',
                labelStyle: labelStyle,
                valueStyle: valueStyle,
              ),
              _MetaLine(
                label: 'SKU',
                value: product?.sku ?? '',
                labelStyle: labelStyle,
                valueStyle: valueStyle,
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        BlocBuilder<FavouriteCubit, FavouriteState>(
          builder: (context, favourites) {
            final isFav = favourites.favoriteIds.contains(product?.id ?? 0);
            return GestureDetector(
              onTap: () async {
                await context.read<FavouriteCubit>().toggleFavourite(
                  productResCommon,
                );
                if (!isFav) {
                  CustomToast.info('Added to the favourite');
                } else {
                  CustomToast.info('Removed from favourite');
                }
              },
              child: Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColor.safe1.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppHugeIcon(
                      HugeIcons.strokeRoundedFavourite,
                      color: isFav ? AppColor.primary : AppColor.grey,
                      size: 18,
                      secondaryColor: isFav
                          ? AppColor.primary.withValues(alpha: 0.18)
                          : null,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        isFav
                            ? 'Remove from your favorite list'
                            : 'Add to your favorite list',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isFav ? AppColor.primary : AppColor.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        Divider(height: 24.h, color: AppColor.safe.withValues(alpha: 0.45)),

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
              const _DetailSectionLead(
                icon: HugeIcons.strokeRoundedNote,
                title: 'Description',
              ),
              SizedBox(height: 10.h),
              HtmlWidget(
                product?.description ?? 'No description available.',
                textStyle: TextStyle(
                  fontSize: 12,
                  color: AppColor.secondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72.w,
            child: Text('$label:', style: labelStyle),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionLead extends StatelessWidget {
  const _DetailSectionLead({required this.icon, required this.title});

  final List<List<dynamic>> icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30.r,
          height: 30.r,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: AppHugeIcon(icon, size: 15.r, color: AppColor.primary),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            color: AppColor.text,
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
