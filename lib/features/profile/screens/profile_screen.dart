import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sellhub/features/profile/data/model/profile_res-Model.dart';
import 'package:sellhub/features/profile/data/model/self_store_customer.dart';
import 'package:sellhub/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:sellhub/features/profile/presentation/cubit/profile_state.dart';
import 'package:sellhub/features/profile/screens/password_change_screen.dart';
import 'package:sellhub/features/profile/screens/reseller_screen.dart';
import 'package:sellhub/features/profile/screens/widget/guest_profile.dart';
import 'package:sellhub/features/profile/screens/widget/profile_home_data.dart';
import 'package:sellhub/features/profile/screens/widget/profile_item_list.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _horizontalController = ScrollController();
  final _nameController = TextEditingController();
  final _paymentNoController = TextEditingController();
  final _resellerFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final siteId = context.read<StorefrontCubit>().state.siteDetails?.id ?? 0;
      context.read<ProfileCubit>().hydrateSession(siteId: siteId);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    _paymentNoController.dispose();
    _horizontalController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: widget.showAppBar
              ? SellHubTopAppBar(
                  title: 'Profile',
                  subtitle: 'Buyer book, payouts, and team',
                  icon: HugeIcons.strokeRoundedUser,
                  showBackButton: true,
                )
              : null,
          body: !profileState.isHydrated || profileState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : !profileState.isAuthenticated
              ? const GuestProfileView()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: ListView(
                    children: [
                      ItemListWidget(
                        items: const [
                          'Overview',
                          'Buyers',
                          'Payouts',
                          'Team',
                          'Password',
                          'Log Out',
                        ],
                        selectedIndex: profileState.indexProfileItem,
                        onTabSelected: (index) async {
                          final profileCubit = context.read<ProfileCubit>();
                          final authCubit = context.read<AuthCubit>();
                          if (index == 1) {
                            AppRouter.goToBuyerBook(context);
                            return;
                          }
                          if (index == 2) {
                            AppRouter.goToPayouts(context);
                            return;
                          }
                          if (index == 3) {
                            AppRouter.goToTeamSelling(context);
                            return;
                          }
                          profileCubit.setIndexProfileItem(index);
                          if (index == 5) {
                            profileCubit.setIndexProfileItem(0);
                            await authCubit.logout();
                            if (!context.mounted) return;
                            await profileCubit.hydrateSession(
                              siteId:
                                  context
                                      .read<StorefrontCubit>()
                                      .state
                                      .siteDetails
                                      ?.id ??
                                  0,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      profileState.indexProfileItem == 0
                          ? _profileHomeDetails(profileState)
                          : profileState.indexProfileItem == 4
                          ? PasswordChangeScreen()
                          : Container(),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _profileHomeDetails(ProfileState profileState) {
    final profile = profileState.profile;
    final customer = profileState.selfStoreCustomerRes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SellerProfileHero(profile: profile, customer: customer),
        const SizedBox(height: 16),
        const _ProfileOperatorCard(),
        const SizedBox(height: 16),
        const _ProfileQuickTools(),
        const SizedBox(height: 16),
        const _DailyResellerLoopCard(),
        const SizedBox(height: 16),
        ProfileHomeData(profile: profile),
        if (customer != null && customer.isReseller != true) ...[
          const SizedBox(height: 16),
          ResellerScreen(
            nameController: _nameController,
            paymentNoController: _paymentNoController,
            formkey: _resellerFormKey,
          ),
        ],
      ],
    );
  }
}

class _DailyResellerLoopCard extends StatelessWidget {
  const _DailyResellerLoopCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: const [
          Expanded(
            child: _LoopStep(title: 'Find', subtitle: 'Pick easy products'),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _LoopStep(title: 'Share', subtitle: 'Post in chat/social'),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _LoopStep(title: 'Repeat', subtitle: 'Reuse buyers'),
          ),
        ],
      ),
    );
  }
}

class _ProfileOperatorCard extends StatelessWidget {
  const _ProfileOperatorCard();

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
          Text(
            'Reseller control center',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Use this page to watch payout readiness, reopen buyers, and jump into chat intake, quick orders, disputes, team, and referrals.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoopStep extends StatelessWidget {
  const _LoopStep({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColor.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileQuickTools extends StatelessWidget {
  const _ProfileQuickTools();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operate',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColor.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _ProfileToolTile(
              icon: HugeIcons.strokeRoundedInvoice03,
              title: 'Orders',
              onTap: () => AppRouter.goToOrders(context),
            ),
            _ProfileToolTile(
              icon: HugeIcons.strokeRoundedDashboardSquare03,
              title: 'Ops hub',
              onTap: () => AppRouter.goToResellerOps(context),
            ),
            _ProfileToolTile(
              icon: HugeIcons.strokeRoundedUserGroup,
              title: 'Buyers',
              onTap: () => AppRouter.goToBuyerBook(context),
            ),
            _ProfileToolTile(
              icon: HugeIcons.strokeRoundedWallet02,
              title: 'Payouts',
              onTap: () => AppRouter.goToPayouts(context),
            ),
            _ProfileToolTile(
              icon: HugeIcons.strokeRoundedFile02,
              title: 'Quotes',
              onTap: () => AppRouter.goToQuotes(context),
            ),
            _ProfileToolTile(
              icon: HugeIcons.strokeRoundedUserMultiple02,
              title: 'Team selling',
              onTap: () => AppRouter.goToTeamSelling(context),
            ),
            _ProfileToolTile(
              icon: HugeIcons.strokeRoundedReload,
              title: 'Workflows',
              onTap: () => AppRouter.goToWorkflows(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileToolTile extends StatelessWidget {
  const _ProfileToolTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColor.safe),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColor.safe1,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppHugeIcon(icon, size: 18, color: AppColor.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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

class _SellerProfileHero extends StatelessWidget {
  const _SellerProfileHero({required this.profile, required this.customer});

  final ProfileResModel? profile;
  final SelfStoreCustomerRes? customer;

  @override
  Widget build(BuildContext context) {
    final payoutLabel = (customer?.paymentTitle?.trim().isNotEmpty ?? false)
        ? customer!.paymentTitle!
        : 'Setup';
    final payable =
        customer?.resellPayable?.toDouble() ?? profile?.resellPayable ?? 0;
    final processing =
        customer?.resellProcessing?.toDouble() ??
        profile?.resellProcessing ??
        0;
    final paid = customer?.resellPaid?.toDouble() ?? profile?.resellPaid ?? 0;
    final hasPayoutChannel =
        (customer?.paymentTitle?.trim().isNotEmpty ?? false) ||
        (profile?.paymentTitle?.trim().isNotEmpty ?? false);
    final confidenceLabel = hasPayoutChannel
        ? payable > 0
              ? 'Payout ready'
              : processing > 0
              ? 'Delivery lock active'
              : 'Payout route set'
        : 'Set payout route';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.title?.trim().isNotEmpty == true
                          ? profile?.title?.trim() ?? 'Unknown reseller'
                          : 'Unknown reseller',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    _InlineMeta(
                      icon: HugeIcons.strokeRoundedCall02,
                      text: profile?.phone?.toString() ?? 'No phone',
                    ),
                    SizedBox(height: 8.h),
                    _InlineMeta(
                      icon: HugeIcons.strokeRoundedShield01,
                      text: confidenceLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetricChip(
                label: 'Orders',
                value: '${profile?.ordersTotal ?? 0}',
                icon: HugeIcons.strokeRoundedInvoice03,
              ),
              _HeroMetricChip(
                label: 'Payout',
                value: payoutLabel,
                icon: HugeIcons.strokeRoundedWallet02,
              ),
              _HeroMetricChip(
                label: 'Payable',
                value: '৳ ${payable.toStringAsFixed(0)}',
                icon: HugeIcons.strokeRoundedMoneyBag01,
              ),
              _HeroMetricChip(
                label: 'Processing',
                value: '৳ ${processing.toStringAsFixed(0)}',
                icon: HugeIcons.strokeRoundedPackageProcess,
              ),
              _HeroMetricChip(
                label: 'Paid',
                value: '৳ ${paid.toStringAsFixed(0)}',
                icon: HugeIcons.strokeRoundedWalletDone02,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.icon, required this.text});

  final List<List<dynamic>> icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppHugeIcon(icon, size: 16, color: AppColor.neutral2),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _HeroMetricChip extends StatelessWidget {
  const _HeroMetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppHugeIcon(icon, size: 16, color: AppColor.primary),
          const SizedBox(width: 8),
          Flexible(
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
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
