import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/features/profile/data/model/profile_res-Model.dart';

class ProfileHomeData extends StatelessWidget {
  const ProfileHomeData({super.key, required this.profile});

  final ProfileResModel? profile;

  @override
  Widget build(BuildContext context) {
    final totalOrders = profile?.ordersTotal ?? 0;
    final resellTotal = _currency(profile?.resellTotal);
    final resellPayable = _currency(profile?.resellPayable);
    final resellPaid = _currency(profile?.resellPaid);
    final resellProcessing = _currency(profile?.resellProcessing);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ProfileSectionLead(
          icon: HugeIcons.strokeRoundedAnalytics01,
          title: 'Business',
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.62,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MetricTile(
              label: 'Ready for payout',
              value: resellPayable,
              icon: HugeIcons.strokeRoundedMoneyReceiveSquare,
              tone: const Color(0xFF0E9F6E),
            ),
            _MetricTile(
              label: 'Paid out',
              value: resellPaid,
              icon: HugeIcons.strokeRoundedWalletDone02,
              tone: const Color(0xFF2563EB),
            ),
            _MetricTile(
              label: 'Processing',
              value: resellProcessing,
              icon: HugeIcons.strokeRoundedLoading03,
              tone: const Color(0xFFEA580C),
            ),
            _MetricTile(
              label: 'Resell total',
              value: resellTotal,
              icon: HugeIcons.strokeRoundedWallet02,
              tone: AppColor.primary,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _ProfileSectionLead(
          icon: HugeIcons.strokeRoundedPackageProcess,
          title: 'Pipeline',
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatusChip(label: 'Total orders', value: '$totalOrders'),
            _StatusChip(
              label: 'Delivered',
              value: '${profile?.ordersDelivered ?? 0}',
            ),
            _StatusChip(
              label: 'Pending',
              value: '${profile?.ordersPending ?? 0}',
            ),
            _StatusChip(
              label: 'Packaging',
              value: '${profile?.ordersPackaging ?? 0}',
            ),
            _StatusChip(
              label: 'Returned',
              value: '${profile?.ordersReturned ?? 0}',
            ),
            _StatusChip(
              label: 'Canceled',
              value: '${profile?.ordersCancelled ?? 0}',
            ),
          ],
        ),
      ],
    );
  }

  static String _currency(num? value) {
    return '৳${(value ?? 0).toStringAsFixed(0)}';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final List<List<dynamic>> icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppHugeIcon(icon, size: 16, color: tone),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
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
