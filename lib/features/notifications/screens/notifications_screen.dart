import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/navigation/pending_product_deep_link.dart';
import 'package:sellhub/core/notifications/notification_center_cubit.dart';
import 'package:sellhub/core/notifications/app_notification.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SellHubTopAppBar(
        title: 'Notifications',
        icon: HugeIcons.strokeRoundedNotificationSquare,
        showBackButton: true,
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'read') {
                context.read<NotificationCenterCubit>().markAllRead();
                return;
              }
              if (value == 'clear') {
                context.read<NotificationCenterCubit>().clearAll();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'read',
                child: Text('Mark all read'),
              ),
              PopupMenuItem<String>(
                value: 'clear',
                child: Text('Clear all'),
              ),
            ],
            icon: const AppHugeIcon(HugeIcons.strokeRoundedMoreHorizontal, size: 20),
          ),
        ],
      ),
      body: BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          if (!state.isReady) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColor.safe),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppHugeIcon(
                        HugeIcons.strokeRoundedNotificationSquare,
                        size: 42,
                        color: AppColor.neutral2,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No notifications yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Order and store updates will appear here.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColor.neutral2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          final unread = state.notifications.where((item) => !item.isRead).toList();
          final read = state.notifications.where((item) => item.isRead).toList();
          final totalItems = unread.length + read.length + 2;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: totalItems,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _NotificationHero(
                  unreadCount: unread.length,
                  totalCount: state.notifications.length,
                );
              }
              if (index == 1) {
                return _BucketHeader(
                  title: 'Unread',
                  count: unread.length,
                  icon: HugeIcons.strokeRoundedNotificationSquare,
                );
              }
              if (index <= unread.length + 1) {
                return _NotificationCard(item: unread[index - 2]);
              }
              if (index == 0) {
                return const SizedBox.shrink();
              }
              if (index == unread.length + 2) {
                if (read.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _BucketHeader(
                  title: 'Earlier',
                  count: read.length,
                  icon: HugeIcons.strokeRoundedTimeQuarter02,
                );
              }
              return _NotificationCard(item: read[index - unread.length - 3]);
            },
          );
        },
      ),
    );
  }
}

class _NotificationHero extends StatelessWidget {
  const _NotificationHero({
    required this.unreadCount,
    required this.totalCount,
  });

  final int unreadCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
              HugeIcons.strokeRoundedNotificationSquare,
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
                  'Notification center',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColor.text,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Unread $unreadCount  •  Total $totalCount',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$unreadCount new',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BucketHeader extends StatelessWidget {
  const _BucketHeader({
    required this.title,
    required this.count,
    required this.icon,
  });

  final String title;
  final int count;
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColor.safe),
          ),
          child: AppHugeIcon(icon, size: 16, color: AppColor.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColor.text,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await context.read<NotificationCenterCubit>().markRead(item.id);
        if (!context.mounted) return;
        final routeName = item.routeName;
        if (routeName != null && routeName.isNotEmpty) {
          final handled = await PendingProductDeepLinkHandler.handleRoutePayload(
            context,
            routeName: routeName,
            routeParams: item.routeParams,
          );
          if (!context.mounted) return;
          if (handled) return;
          AppRouter.goNamed(routeName, queryParameters: item.routeParams);
        }
      },
        child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : AppColor.safe1.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead
                ? const Color(0xFFE5E7EB)
                : colorScheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: _accent(item.type, colorScheme),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(item.timestamp),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.safe1,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.type.name,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColor.neutral2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: item.isRead
                          ? FontWeight.w600
                          : FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => context.read<NotificationCenterCubit>().remove(item.id),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: AppHugeIcon(HugeIcons.strokeRoundedCancel01, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accent(AppNotificationType type, ColorScheme colorScheme) {
    switch (type) {
      case AppNotificationType.success:
        return Colors.green;
      case AppNotificationType.warning:
        return Colors.orange;
      case AppNotificationType.danger:
        return colorScheme.error;
      case AppNotificationType.info:
        return colorScheme.primary;
    }
  }
}
