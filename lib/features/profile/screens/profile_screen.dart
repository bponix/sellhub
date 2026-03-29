import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/share/sellhub_share_link_builder.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sellhub/features/profile/data/model/self_store_customer.dart';
import 'package:sellhub/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:sellhub/features/profile/presentation/cubit/profile_state.dart';
import 'package:sellhub/features/profile/screens/manage_addresses_screen.dart';
import 'package:sellhub/features/profile/screens/password_change_screen.dart';
import 'package:sellhub/features/profile/screens/widget/guest_profile.dart';
import 'package:sellhub/features/profile/screens/widget/profile_home_data.dart';
import 'package:sellhub/features/profile/screens/widget/profile_item_list.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _horizontalController = ScrollController();
  final _nameController = TextEditingController();
  final _paymentNoController = TextEditingController();

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
                          'Home',
                          'Order',
                          'Password',
                          'Notifications',
                          'Log Out',
                        ],
                        selectedIndex: profileState.indexProfileItem,
                        onTabSelected: (index) async {
                          final profileCubit = context.read<ProfileCubit>();
                          final authCubit = context.read<AuthCubit>();
                          if (index == 1) {
                            AppRouter.goToOrders(context);
                            return;
                          }
                          if (index == 3) {
                            AppRouter.goToNotifications(context);
                            return;
                          }
                          profileCubit.setIndexProfileItem(index);
                          if (index == 4) {
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
                          : profileState.indexProfileItem == 2
                          ? PasswordChangeScreen()
                          : profileState.indexProfileItem == 3
                          ? const SizedBox.shrink()
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColor.safe),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ProfileSectionLead(
                icon: HugeIcons.strokeRoundedUserAccount,
                eyebrow: 'Account overview',
                title: 'Customer profile',
              ),
              const SizedBox(height: 12),
              Text(
                profile?.title?.trim().isNotEmpty == true
                    ? profile!.title!.trim()
                    : 'Unknown customer',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  const AppHugeIcon(
                    HugeIcons.strokeRoundedCall02,
                    size: 16,
                    color: AppColor.neutral2,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      profile?.phone.toString() ?? 'No phone',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (profile?.address != null && profile?.address != "") ...[
                SizedBox(height: 6.h),
                Row(
                  children: [
                    const AppHugeIcon(
                      HugeIcons.strokeRoundedMapsLocation01,
                      size: 16,
                      color: AppColor.neutral2,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        profile?.address ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        ProfileHomeData(profile: profile),
        const SizedBox(height: 16),
        if (profileState.selfStoreCustomerRes != null)
          _ReferralRewardsCard(customer: profileState.selfStoreCustomerRes!),
        const SizedBox(height: 16),
        const _ProfileSectionLead(
          icon: HugeIcons.strokeRoundedDashboardSquare03,
          eyebrow: 'Quick access',
          title: 'Manage account',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () => AppRouter.goToOrders(context),
              icon: const AppHugeIcon(
                HugeIcons.strokeRoundedInvoice03,
                size: 18,
              ),
              label: const Text('Orders'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ManageAddressesScreen(),
                  ),
                );
              },
              icon: const AppHugeIcon(
                HugeIcons.strokeRoundedMapsLocation01,
                size: 18,
              ),
              label: const Text('Addresses'),
            ),
            OutlinedButton.icon(
              onPressed: () => AppRouter.goToSettings(context),
              icon: const AppHugeIcon(
                HugeIcons.strokeRoundedSettings02,
                size: 18,
              ),
              label: const Text('Settings'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReferralRewardsCard extends StatelessWidget {
  const _ReferralRewardsCard({required this.customer});

  final SelfStoreCustomerRes customer;

  @override
  Widget build(BuildContext context) {
    final activeStore = context.read<StoreContextCubit>().state.activeStore;
    final referralCode = customer.referCode?.trim() ?? '';
    final canShare = activeStore != null && referralCode.isNotEmpty;
    final rewardLabel = [
      if ((customer.totalRewardPoints ?? 0) > 0)
        '${customer.totalRewardPoints} reward points',
      if ((customer.totalCashbackBalance ?? 0) > 0)
        '৳${customer.totalCashbackBalance} cashback',
      if ((customer.totalGiftCardBalance ?? 0) > 0)
        '৳${customer.totalGiftCardBalance} gift balance',
    ].join(' • ');

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
          const _ProfileSectionLead(
            icon: HugeIcons.strokeRoundedShare08,
            eyebrow: 'Growth and rewards',
            title: 'Invite and earn',
          ),
          const SizedBox(height: 12),
          Text(
            referralCode.isEmpty
                ? 'Your referral code will appear here when the store enables it.'
                : 'Share your referral code to bring friends back into this store and collect rewards over time.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColor.safe),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Referral code',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColor.neutral2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        referralCode.isEmpty ? 'Unavailable' : referralCode,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColor.text,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColor.safe),
                  ),
                  child: Text(
                    (customer.isAffiliate ?? false) ? 'Active' : 'Ready',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColor.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _RewardChip(
                icon: HugeIcons.strokeRoundedGift,
                label: 'Points',
                value: '${customer.totalRewardPoints ?? 0}',
              ),
              _RewardChip(
                icon: HugeIcons.strokeRoundedWallet02,
                label: 'Cashback',
                value: '৳${customer.totalCashbackBalance ?? 0}',
              ),
              _RewardChip(
                icon: HugeIcons.strokeRoundedCardExchange01,
                label: 'Gift',
                value: '৳${customer.totalGiftCardBalance ?? 0}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canShare
                      ? () {
                          final text =
                              SellHubShareLinkBuilder.buildReferralShareText(
                                store: activeStore,
                                referCode: referralCode,
                                rewardLabel: rewardLabel,
                              );
                          Share.share(text, subject: 'SellHub referral');
                        }
                      : null,
                  icon: const AppHugeIcon(
                    HugeIcons.strokeRoundedShare08,
                    size: 18,
                  ),
                  label: const Text('Invite friend'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canShare
                      ? () {
                          final link =
                              SellHubShareLinkBuilder.buildReferralUri(
                                store: activeStore,
                                referCode: referralCode,
                              ).toString();
                          Share.share(
                            'Referral code: $referralCode\n$link',
                            subject: 'Referral code',
                          );
                        }
                      : null,
                  icon: const AppHugeIcon(
                    HugeIcons.strokeRoundedCopy01,
                    size: 18,
                  ),
                  label: const Text('Share code'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppHugeIcon(icon, size: 16, color: AppColor.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionLead extends StatelessWidget {
  const _ProfileSectionLead({
    required this.icon,
    required this.eyebrow,
    required this.title,
  });

  final List<List<dynamic>> icon;
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColor.safe),
          ),
          child: AppHugeIcon(icon, size: 18, color: AppColor.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColor.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
