import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/store/store_context_state.dart';
import 'package:sellhub/core/utils/app_router.dart';
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
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SettingsHero(
                    storeTitle: storeState.activeStore?.title?.trim().isNotEmpty == true
                        ? storeState.activeStore!.title!.trim()
                        : storeState.activeStore?.domain,
                  ),
                  const SizedBox(height: 14),
                  if (storeState.activeStore != null) ...[
                    _SettingsSection(
                      title: 'Current store',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          storeState.activeStore!.title?.trim().isNotEmpty == true
                              ? storeState.activeStore!.title!.trim()
                              : storeState.activeStore!.domain,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          storeState.activeStore!.domain,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const AppHugeIcon(
                          HugeIcons.strokeRoundedStore01,
                          size: 20,
                          color: AppColor.neutral2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _SettingsSection(
                    title: 'Preferences',
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Notification inbox'),
                          subtitle: const Text(
                            'Keep SellHub campaign and order alerts enabled',
                          ),
                          value: state.notificationOptIn,
                          onChanged: context.read<SettingsCubit>().setNotificationOptIn,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Notification permission'),
                          subtitle: Text(
                            !state.notificationAvailable
                                ? 'Unavailable until SellHub Firebase is configured'
                                : state.notificationGranted
                                ? 'Granted'
                                : 'Not granted',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 14),
                  _SettingsSection(
                    title: 'Store',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reset selected store'),
                          subtitle: const Text(
                            'Return to shop discovery and clear the current store context',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      trailing: const AppHugeIcon(
                        HugeIcons.strokeRoundedArrowRight01,
                        size: 20,
                        color: AppColor.neutral2,
                      ),
                      onTap: () async {
                        await context.read<StoreContextCubit>().clear();
                        if (!context.mounted) return;
                        AppRouter.goToStoreSelector(context);
                      },
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings section',
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
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  List<List<dynamic>> _iconForTitle(String title) {
    switch (title) {
      case 'Current store':
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

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({this.storeTitle});

  final String? storeTitle;

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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const AppHugeIcon(
              HugeIcons.strokeRoundedSettings02,
              size: 18,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Store preferences',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  storeTitle == null
                      ? 'Permissions, alerts, and store behavior live here.'
                      : 'Managing preferences for $storeTitle',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
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
