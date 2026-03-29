import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/widget/app_huge_icon.dart';
import '../../data/model/profile_res-Model.dart';

class ProfileHomeData extends StatelessWidget {
  const ProfileHomeData({super.key, required this.profile});

  final ProfileResModel? profile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ProfileSectionLead(
            icon: HugeIcons.strokeRoundedWalletAdd01,
            title: 'Account snapshot',
          ),
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceStatus(
                context: context,
                text: 'Purchase',
                color: Colors.blue,
                amount: profile?.totalPurchase?.toStringAsFixed(0) ?? '0',
                icon: Icons.add_shopping_cart_outlined,
              ),
              _buildBalanceStatus(
                context: context,
                text: 'Balance',
                color: Colors.blue,
                amount: profile?.totalBalance?.toStringAsFixed(0) ?? '0',
                icon: Icons.balance,
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceStatus(
                context: context,
                text: 'Cashback',
                color: Colors.deepPurple,
                amount: profile?.totalCashbackBalance?.toStringAsFixed(0) ?? '0',
                icon: Icons.attach_money_sharp,
              ),
              _buildBalanceStatus(
                context: context,
                text: 'Gift Card',
                color: Colors.deepOrangeAccent,
                amount: profile?.totalGiftCardBalance?.toStringAsFixed(0) ?? '0',
                icon: Icons.card_giftcard_sharp,
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildBalanceStatus(
            context: context,
            text: 'Reward Point',
            color: Colors.green,
            amount: profile?.totalRewardPoints?.toStringAsFixed(0) ?? '0',
            icon: Icons.wallet_giftcard_sharp,
          ),

          SizedBox(height: 20),
          const _ProfileSectionLead(
            icon: HugeIcons.strokeRoundedPackageProcess,
            title: 'Order status',
          ),
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOrderStatusCard(
                context: context,
                text: 'Pending',
                color: Colors.blue,
                quantity: profile?.ordersPending?.toStringAsFixed(0) ?? '0',
              ),
              _buildOrderStatusCard(
                context: context,
                text: 'Processing',
                color: Colors.deepPurple,
                quantity: profile?.ordersPackaging?.toStringAsFixed(0) ?? '0',
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOrderStatusCard(
                context: context,
                text: 'Delivered',
                color: Colors.green,
                quantity: profile?.ordersDelivered?.toStringAsFixed(0) ?? '0',
              ),
              _buildOrderStatusCard(
                context: context,
                text: 'Return',
                color: Colors.orangeAccent,
                quantity: profile?.ordersReturned?.toStringAsFixed(0) ?? '0',
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildOrderStatusCard(
            context: context,
            text: 'Cancel',
            color: Colors.pinkAccent,
            quantity: profile?.ordersCancelled?.toStringAsFixed(0) ?? '0',
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard({
    required BuildContext context,
    required String text,
    required Color color,
    required String quantity,
  }) {
    return Container(
      padding: EdgeInsets.all(10),
      height: 70,
      width: MediaQuery.of(context).size.width / 2 - 30,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(color: AppColor.neutral2, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            quantity,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStatus({
    required BuildContext context,
    required Color color,
    required String text,
    required IconData icon,
    required String amount,
  }) {
    return Container(
      padding: EdgeInsets.all(10),
      height: 90,
      width: MediaQuery.of(context).size.width / 2 - 30,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColor.grey.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(text, style: TextStyle(color: AppColor.grey)),
              CircleAvatar(
                radius: 15,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          Text(
            '৳ $amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionLead extends StatelessWidget {
  const _ProfileSectionLead({required this.icon, required this.title});

  final List<List<dynamic>> icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AppHugeIcon(icon, size: 16, color: AppColor.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColor.text,
          ),
        ),
      ],
    );
  }
}
