import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/store/store_context_state.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sellhub/features/settings/presentation/cubit/settings_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().hydrate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SellHubTopAppBar(
        title: 'Settings',
        icon: HugeIcons.strokeRoundedSettings02,
        showBackButton: true,
      ),
      body: BlocBuilder<StoreContextCubit, StoreContextState>(
        builder: (context, storeState) {
          return BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              final activeStore = storeState.activeStore;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SettingsOverviewCard(
                    storeName: activeStore?.title?.trim().isNotEmpty == true
                        ? activeStore!.title!.trim()
                        : 'Default supplier context',
                    domain: activeStore?.domain ?? 'sellhub.bponi.com',
                  ),
                  const SizedBox(height: 12),
                  const _SettingsOperatorCard(),
                  const SizedBox(height: 12),
                  _SettingsSection(
                    title: 'Preferences',
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Notification inbox'),
                          value: state.notificationOptIn,
                          onChanged: context
                              .read<SettingsCubit>()
                              .setNotificationOptIn,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Notification permission'),
                          subtitle: Text(
                            state.notificationGranted ? 'Granted' : 'Not granted',
                          ),
                          trailing: const AppHugeIcon(
                            HugeIcons.strokeRoundedNotificationSquare,
                            size: 20,
                            color: AppColor.neutral2,
                          ),
                          onTap: state.notificationAvailable
                              ? () => context
                                    .read<SettingsCubit>()
                                    .requestNotificationPermission()
                              : null,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Location permission'),
                          subtitle: Text(
                            state.locationGranted ? 'Granted' : 'Not granted',
                          ),
                          trailing: const AppHugeIcon(
                            HugeIcons.strokeRoundedLocation01,
                            size: 20,
                            color: AppColor.neutral2,
                          ),
                          onTap: () => context
                              .read<SettingsCubit>()
                              .requestLocationPermission(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsSection(
                    title: 'Supplier context',
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Active supplier'),
                          subtitle: Text(
                            activeStore?.title?.trim().isNotEmpty == true
                                ? activeStore!.title!.trim()
                                : 'Default supplier context',
                          ),
                          trailing: const AppHugeIcon(
                            HugeIcons.strokeRoundedStore01,
                            size: 20,
                            color: AppColor.neutral2,
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Domain'),
                          subtitle: Text(activeStore?.domain ?? 'sellhub.bponi.com'),
                          trailing: const AppHugeIcon(
                            HugeIcons.strokeRoundedGlobe02,
                            size: 20,
                            color: AppColor.neutral2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SettingsOverviewCard extends StatelessWidget {
  const _SettingsOverviewCard({
    required this.storeName,
    required this.domain,
  });

  final String storeName;
  final String domain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.safe),
            ),
            child: const AppHugeIcon(
              HugeIcons.strokeRoundedSettings02,
              size: 22,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device and supplier settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$storeName • $domain',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w600,
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

class _SettingsOperatorCard extends StatelessWidget {
  const _SettingsOperatorCard();

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
            'Keep this page practical',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Only device permissions and active supplier context should live here. Operational selling actions belong in the main app routes.',
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColor.safe),
                ),
                child: AppHugeIcon(
                  _iconForTitle(title),
                  size: 18,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  List<List<dynamic>> _iconForTitle(String title) {
    switch (title) {
      case 'Supplier context':
      case 'Marketplace context':
        return HugeIcons.strokeRoundedStore01;
      case 'Preferences':
        return HugeIcons.strokeRoundedSettings02;
      case 'Store':
        return HugeIcons.strokeRoundedRefresh;
      default:
        return HugeIcons.strokeRoundedDashboardSquare03;
    }
  }
}
