import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/favourite/presentation/cubit/favourite_cubit.dart';
import 'package:sellhub/features/favourite/presentation/cubit/favourite_state.dart';
import 'package:sellhub/features/product/screens/widget/product_list_vertical.dart';

class FavouriteScreen extends StatelessWidget {
  const FavouriteScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: showAppBar
          ? const SellHubTopAppBar(
              title: 'Saved',
              subtitle: 'Keep fast-sell products close',
              icon: HugeIcons.strokeRoundedFavourite,
              showBackButton: true,
            )
          : null,
      body: BlocBuilder<FavouriteCubit, FavouriteState>(
        builder: (context, favourites) {
          if (favourites.items.isEmpty) {
            return _buildEmptyState(context);
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                  child: _SavedHeaderCard(itemCount: favourites.items.length),
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
              'No saved products yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: AppColor.text,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Keep products here for faster sharing, quoting, and repeat selling.',
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
                      'Tap the heart on any product card to keep it in your saved list.',
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
            SizedBox(height: 22.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDFF55A),
                  foregroundColor: AppColor.text,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                ),
                onPressed: () => AppRouter.goToHome(context),
                child: const Text('Browse products'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedHeaderCard extends StatelessWidget {
  const _SavedHeaderCard({required this.itemCount});

  final int itemCount;

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
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: AppHugeIcon(
              HugeIcons.strokeRoundedFavourite,
              size: 20.r,
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
                  '$itemCount items ready for repeat share, quote, or quick order.',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.neutral2,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
