import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/features/favourite/presentation/cubit/favourite_cubit.dart';
import 'package:sellhub/features/favourite/presentation/cubit/favourite_state.dart';
import 'package:sellhub/features/product/screens/widget/product_list_vertical.dart';

class FavouriteScreen extends StatelessWidget {
  const FavouriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<FavouriteCubit, FavouriteState>(
        builder: (context, favourites) {
          if (favourites.items.isEmpty) {
            return _buildEmptyState(context);
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
                  child: _FavouriteIntroCard(count: favourites.items.length),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  0,
                  16.w,
                  kBottomNavigationBarHeight + 20.h,
                ),
                sliver: SliverToBoxAdapter(
                  child: ProductListViewVerical(
                    products: favourites.items,
                    emphasizeImage: true,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Pro Level Empty State ---
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 34.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColor.safe1,
                shape: BoxShape.circle,
              ),
              child: AppHugeIcon(
                HugeIcons.strokeRoundedFavourite,
                size: 72,
                color: AppColor.primary,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No favourites yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: AppColor.text,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Save products here for quick access later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColor.neutral2,
                height: 1.4,
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: AppColor.safe),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppHugeIcon(
                    HugeIcons.strokeRoundedShoppingBag02,
                    size: 18.r,
                    color: AppColor.primary,
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: Text(
                      'Tap the heart on any product card to save it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavouriteIntroCard extends StatelessWidget {
  const _FavouriteIntroCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: [
          Container(
            width: 46.r,
            height: 46.r,
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: AppHugeIcon(
              HugeIcons.strokeRoundedFavourite,
              size: 22.r,
              color: AppColor.primary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved products',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Keep your shortlist ready for faster repeat orders.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Text(
              '$count items',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColor.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
