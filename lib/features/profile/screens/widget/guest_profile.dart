import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';

import '../../../auth/screens/login_screen.dart';

class GuestProfileView extends StatelessWidget {
  const GuestProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColor.safe),
              ),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColor.safe1,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const AppHugeIcon(
                      HugeIcons.strokeRoundedUserAccount,
                      size: 38,
                      color: AppColor.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign in for a better shopping flow',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Keep track of orders, save favourites, and recover your shopping history.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _GuestBenefitRow(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColor.text,
                  side: const BorderSide(color: AppColor.safe),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppHugeIcon(
                      HugeIcons.strokeRoundedArrowRight02,
                      size: 16,
                      color: AppColor.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Continue to account',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestBenefitRow extends StatelessWidget {
  const _GuestBenefitRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _GuestBenefitTile(
            icon: HugeIcons.strokeRoundedInvoice03,
            title: 'Orders',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _GuestBenefitTile(
            icon: HugeIcons.strokeRoundedFavourite,
            title: 'Favourites',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _GuestBenefitTile(
            icon: HugeIcons.strokeRoundedNotificationSquare,
            title: 'Updates',
          ),
        ),
      ],
    );
  }
}

class _GuestBenefitTile extends StatelessWidget {
  const _GuestBenefitTile({required this.icon, required this.title});

  final List<List<dynamic>> icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        children: [
          AppHugeIcon(icon, size: 18, color: AppColor.primary),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColor.text,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
