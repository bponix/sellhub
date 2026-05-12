import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';

class AppDrawerFull extends StatelessWidget {
  const AppDrawerFull({
    super.key,
    required this.onOpenCategories,
  });

  final VoidCallback onOpenCategories;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Reseller menu',
                style: TextStyle(
                  color: AppColor.neutral2,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _DrawerItem(
              icon: HugeIcons.strokeRoundedInvoice03,
              title: 'Orders',
              onTap: () {
                Navigator.of(context).pop();
                AppRouter.goToOrders(context);
              },
            ),
            _DrawerItem(
              icon: HugeIcons.strokeRoundedUserGroup,
              title: 'Buyers',
              onTap: () {
                Navigator.of(context).pop();
                AppRouter.goToBuyerBook(context);
              },
            ),
            _DrawerItem(
              icon: HugeIcons.strokeRoundedWallet02,
              title: 'Payouts',
              onTap: () {
                Navigator.of(context).pop();
                AppRouter.goToPayouts(context);
              },
            ),
            _DrawerItem(
              icon: HugeIcons.strokeRoundedFavourite,
              title: 'Saved',
              onTap: () {
                Navigator.of(context).pop();
                AppRouter.goToSaved(context);
              },
            ),
            _DrawerItem(
              icon: HugeIcons.strokeRoundedGridView,
              title: 'Categories',
              onTap: () {
                Navigator.of(context).pop();
                onOpenCategories();
              },
            ),
            _DrawerItem(
              icon: HugeIcons.strokeRoundedUserAccount,
              title: 'Profile',
              onTap: () {
                Navigator.of(context).pop();
                AppRouter.goToProfile(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColor.safe),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AppHugeIcon(icon, size: 18, color: AppColor.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColor.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const AppHugeIcon(
                HugeIcons.strokeRoundedArrowRight01,
                size: 16,
                color: AppColor.neutral2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
