import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';

class AppDrawerFull extends StatelessWidget {
  const AppDrawerFull({
    super.key,
    required this.logoUrl,
    required this.onOpenCategories,
  });

  final String? logoUrl;
  final VoidCallback onOpenCategories;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: AppColor.safe1,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColor.safe),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Store menu',
                          style: TextStyle(
                            color: AppColor.neutral2,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColor.safe),
                        ),
                        child: const Text(
                          'Browse',
                          style: TextStyle(
                            color: AppColor.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColor.safe),
                    ),
                    child: AppNetworkImage(
                      imageUrl: logoUrl,
                      fit: BoxFit.contain,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Quick links for store discovery and shopping',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColor.neutral2,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DrawerItem(
              icon: HugeIcons.strokeRoundedDashboardSquare01,
              title: 'Campaigns',
              tag: 'Offers',
              onTap: () {},
            ),
            _DrawerItem(
              icon: HugeIcons.strokeRoundedCollectionsBookmark,
              title: 'Collections',
              tag: 'Curated',
              onTap: () {},
            ),
            _DrawerItem(
              icon: HugeIcons.strokeRoundedFavourite,
              title: 'Wishlist',
              tag: 'Saved',
              onTap: () {},
            ),
            _DrawerItem(
              icon: HugeIcons.strokeRoundedShoppingCart01,
              title: 'Cart',
              tag: 'Bag',
              onTap: () {},
            ),
            _DrawerItem(
              icon: HugeIcons.strokeRoundedGridView,
              title: 'Categories',
              tag: 'Browse',
              onTap: () {
                Navigator.of(context).pop();
                onOpenCategories();
              },
            ),
            _DrawerItem(
              icon: HugeIcons.strokeRoundedPackageDelivered,
              title: 'New Arrival',
              tag: 'Latest',
              onTap: () {},
            ),
            _DrawerItem(
              icon: HugeIcons.strokeRoundedFlash,
              title: 'Flash Sale',
              tag: 'Hot',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDFF55A),
                foregroundColor: AppColor.text,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () {},
              label: const Text(
                'Sign in',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              icon: const AppHugeIcon(
                HugeIcons.strokeRoundedLogin02,
                color: AppColor.text,
              ),
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
    required this.tag,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String tag;
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: AppColor.neutral2,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
