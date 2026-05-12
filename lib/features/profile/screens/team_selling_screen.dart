import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/share/sellhub_share_link_builder.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/features/profile/data/model/team_member_entry.dart';
import 'package:sellhub/features/profile/data/model/team_shared_list_entry.dart';
import 'package:sellhub/features/profile/data/model/team_selling_overview.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';
import 'package:sellhub/injection_container.dart' as di;

class TeamSellingScreen extends StatefulWidget {
  const TeamSellingScreen({super.key});

  @override
  State<TeamSellingScreen> createState() => _TeamSellingScreenState();
}

class _TeamSellingScreenState extends State<TeamSellingScreen> {
  Future<TeamSellingOverview>? _overviewFuture;
  int? _userId;
  int? _siteId;

  @override
  void initState() {
    super.initState();
    _overviewFuture = _loadOverview();
  }

  Future<TeamSellingOverview> _loadOverview() async {
    final siteId = context.read<StoreContextCubit>().state.activeStore?.siteId;
    final userId = await LocalStorage.getUserID() ?? 0;
    if (siteId == null || userId <= 0) {
      throw StateError('Missing active seller session.');
    }
    _userId = userId;
    _siteId = siteId;
    return di.sl<ProfileRepository>().fetchTeamSellingOverview(
      userId: userId,
      siteId: siteId,
    );
  }

  Future<void> _refresh() async {
    final future = _loadOverview();
    setState(() {
      _overviewFuture = future;
    });
    await future;
  }

  Future<void> _manageTeam(TeamSellingOverview overview) async {
    final teamController = TextEditingController(text: overview.teamName);
    final ownerController = TextEditingController(text: overview.ownerName);
    final overrideController = TextEditingController(
      text: overview.overridePercent.toStringAsFixed(0),
    );
    final action = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Team settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: teamController,
                decoration: const InputDecoration(labelText: 'Team name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ownerController,
                decoration: const InputDecoration(labelText: 'Owner name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: overrideController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Direct override %',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('save'),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (action != 'save' || _userId == null || _siteId == null) return;
    await di.sl<ProfileRepository>().upsertTeamConfig(
      userId: _userId!,
      siteId: _siteId!,
      teamId: overview.teamId,
      teamName: teamController.text.trim().isEmpty
          ? overview.teamName
          : teamController.text.trim(),
      ownerName: ownerController.text.trim().isEmpty
          ? overview.ownerName
          : ownerController.text.trim(),
      overridePercent:
          double.tryParse(overrideController.text.trim()) ??
          overview.overridePercent,
    );
    await _refresh();
  }

  Future<void> _inviteSeller(TeamSellingOverview overview) async {
    final activeStore = context.read<StoreContextCubit>().state.activeStore;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final action = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Invite reseller'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Seller name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('invite'),
              child: const Text('Invite'),
            ),
          ],
        );
      },
    );
    if (action != 'invite' || _userId == null || _siteId == null) return;
    final now = DateTime.now();
    final member = TeamMemberEntry(
      id: 'member-${_siteId!}-${now.millisecondsSinceEpoch}',
      teamId: overview.teamId,
      ownerUserId: _userId!,
      siteId: _siteId!,
      name: nameController.text.trim().isEmpty
          ? 'New seller'
          : nameController.text.trim(),
      phone: phoneController.text.trim(),
      status: 'pending',
      role: 'team_seller',
      orderVolume: 0,
      overrideGenerated: 0,
      topProduct: '',
      joinedAt: now,
      lastActiveAt: now,
    );
    await di.sl<ProfileRepository>().upsertTeamMember(member);
    if (activeStore != null) {
      final text = SellHubShareLinkBuilder.buildTeamInviteShareText(
        store: activeStore,
        teamId: overview.teamId,
        memberId: member.id,
        ownerUserId: overview.ownerUserId,
        siteId: overview.siteId,
        teamName: overview.teamName,
        ownerName: overview.ownerName,
        overridePercent: overview.overridePercent,
      );
      await Share.share(text, subject: 'Join my SellHub team');
    }
    await _refresh();
  }

  Future<void> _manageSharedList(
    TeamSellingOverview overview, [
    TeamSharedListEntry? existing,
  ]) async {
    final activeStore = context.read<StoreContextCubit>().state.activeStore;
    final titleController = TextEditingController(text: existing?.title ?? '');
    final supplierController = TextEditingController(
      text: existing?.supplierName ?? activeStore?.title ?? '',
    );
    final productsController = TextEditingController(
      text: existing == null ? '' : existing.productTitles.join(', '),
    );
    final noteController = TextEditingController(text: existing?.note ?? '');
    final memberIds = <String>{
      ...?existing?.sharedWithMemberIds,
    };
    final action = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                existing == null ? 'Share supplier list' : 'Edit shared list',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'List title'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: supplierController,
                      decoration: const InputDecoration(
                        labelText: 'Supplier name',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: productsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Products',
                        hintText: 'Comma separated titles',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Note'),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Distribute to',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...overview.members.map((member) {
                      final selected = memberIds.contains(member.id);
                      return CheckboxListTile(
                        value: selected,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(member.name),
                        subtitle: Text(member.phone),
                        onChanged: (_) {
                          setModalState(() {
                            if (selected) {
                              memberIds.remove(member.id);
                            } else {
                              memberIds.add(member.id);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                if (existing != null)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop('delete'),
                    child: const Text('Delete'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop('save'),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    if (action == null || _userId == null || _siteId == null) return;
    if (action == 'delete' && existing != null) {
      await di.sl<ProfileRepository>().deleteTeamSharedList(existing.id);
      await _refresh();
      return;
    }
    if (action != 'save') return;
    final entry = TeamSharedListEntry(
      id: existing?.id ?? 'team-list-${_siteId!}-${DateTime.now().millisecondsSinceEpoch}',
      teamId: overview.teamId,
      ownerUserId: _userId!,
      siteId: _siteId!,
      title: titleController.text.trim().isEmpty
          ? 'Top products'
          : titleController.text.trim(),
      supplierName: supplierController.text.trim().isEmpty
          ? (activeStore?.title ?? 'Supplier')
          : supplierController.text.trim(),
      productTitles: productsController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      sharedWithMemberIds: memberIds.toList(growable: false),
      note: noteController.text.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await di.sl<ProfileRepository>().upsertTeamSharedList(entry);
    final recipients = overview.members
        .where((member) => memberIds.contains(member.id))
        .map((member) => member.name)
        .join(', ');
    final shareText = [
      'SellHub team list: ${entry.title}',
      'Supplier: ${entry.supplierName}',
      'Products: ${entry.productTitles.join(', ')}',
      if (recipients.isNotEmpty) 'Shared with: $recipients',
      if (entry.note.trim().isNotEmpty) 'Note: ${entry.note.trim()}',
    ].join('\n');
    await Share.share(shareText, subject: entry.title);
    await _refresh();
  }

  Future<void> _removeMember(TeamMemberEntry member) async {
    await di.sl<ProfileRepository>().deleteTeamMember(member.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Team selling'),
      ),
      body: FutureBuilder<TeamSellingOverview>(
        future: _overviewFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppHugeIcon(
                      HugeIcons.strokeRoundedAlertCircle,
                      size: 24,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Team selling is unavailable right now.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final overview = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TeamHero(
                  overview: overview,
                  onEditTeam: () => _manageTeam(overview),
                  onInvite: () => _inviteSeller(overview),
                ),
                const SizedBox(height: 16),
                _SectionLead(
                  icon: HugeIcons.strokeRoundedChartBarLine,
                  title: 'Team output',
                  subtitle:
                      'Track direct seller volume, override earnings, and shared execution.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(
                      label: 'Active sellers',
                      value: '${overview.activeMembers}',
                      helper: '${overview.pendingInvites} pending invite',
                    ),
                    _MetricCard(
                      label: 'Team volume',
                      value: '৳${overview.teamOrderVolume.toStringAsFixed(0)}',
                      helper: 'Direct team sales only',
                    ),
                    _MetricCard(
                      label: 'Override earned',
                      value: '৳${overview.overrideEarned.toStringAsFixed(0)}',
                      helper:
                          '${overview.overridePercent.toStringAsFixed(0)}% direct override',
                    ),
                    _MetricCard(
                      label: 'Shared lists',
                      value: '${overview.sharedListCount}',
                      helper:
                          '${overview.distributedProductCount} products distributed',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionLead(
                  icon: HugeIcons.strokeRoundedUserGroup,
                  title: 'Team members',
                  subtitle:
                      'Clear ownership only. Each seller is directly attached to your team.',
                ),
                const SizedBox(height: 12),
                ...overview.members.map(
                  (member) => _MemberCard(
                    member: member,
                    overridePercent: overview.overridePercent,
                    onRemove: () => _removeMember(member),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: _SectionLead(
                        icon: HugeIcons.strokeRoundedShare08,
                        title: 'Shared supplier lists',
                        subtitle:
                            'Distribute top products and supplier picks to your team.',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _manageSharedList(overview),
                      icon: const AppHugeIcon(
                        HugeIcons.strokeRoundedPlusSign,
                        size: 16,
                      ),
                      label: const Text('New list'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (overview.sharedLists.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColor.safe),
                    ),
                    child: Text(
                      'Share your first supplier list to help team sellers start faster.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ...overview.sharedLists.map(
                    (entry) => _SharedListCard(
                      entry: entry,
                      members: overview.members,
                      onEdit: () => _manageSharedList(overview, entry),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TeamHero extends StatelessWidget {
  const _TeamHero({
    required this.overview,
    required this.onEditTeam,
    required this.onInvite,
  });

  final TeamSellingOverview overview;
  final VoidCallback onEditTeam;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overview.teamName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColor.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Owner: ${overview.ownerName}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            overview.transparentPayoutRule,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColor.neutral2,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _GuardrailPill(label: 'No MLM chain'),
              _GuardrailPill(label: 'Direct override only'),
              _GuardrailPill(label: 'Clear ownership'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onInvite,
                  icon: const AppHugeIcon(
                    HugeIcons.strokeRoundedShare08,
                    size: 18,
                  ),
                  label: const Text('Invite reseller'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditTeam,
                  icon: const AppHugeIcon(
                    HugeIcons.strokeRoundedSettings02,
                    size: 18,
                  ),
                  label: const Text('Team settings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLead extends StatelessWidget {
  const _SectionLead({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(14),
          ),
          child: AppHugeIcon(icon, size: 18, color: AppColor.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColor.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
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
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColor.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
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

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.overridePercent,
    required this.onRemove,
  });

  final TeamMemberEntry member;
  final double overridePercent;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final statusColor = member.isActive ? AppColor.primarySoft : AppColor.safe1;
    final statusTextColor = member.isActive ? AppColor.primary : AppColor.neutral2;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.phone,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
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
                  color: statusColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColor.safe),
                ),
                child: Text(
                  member.isActive ? 'Active' : 'Pending',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusTextColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniStat(label: 'Order volume', value: '৳${member.orderVolume.toStringAsFixed(0)}'),
              _MiniStat(label: 'Override', value: '৳${member.overrideGenerated.toStringAsFixed(0)}'),
              _MiniStat(
                label: 'Rule',
                value: '${overridePercent.toStringAsFixed(0)}% direct',
              ),
            ],
          ),
          if (member.topProduct.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Top product: ${member.topProduct}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRemove,
              icon: const AppHugeIcon(
                HugeIcons.strokeRoundedDelete02,
                size: 16,
              ),
              label: const Text('Remove'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(14),
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColor.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedListCard extends StatelessWidget {
  const _SharedListCard({
    required this.entry,
    required this.members,
    required this.onEdit,
  });

  final TeamSharedListEntry entry;
  final List<TeamMemberEntry> members;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final sharedNames = members
        .where((member) => entry.sharedWithMemberIds.contains(member.id))
        .map((member) => member.name)
        .toList(growable: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.supplierName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const AppHugeIcon(
                  HugeIcons.strokeRoundedEdit02,
                  size: 16,
                ),
                label: const Text('Manage'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.productTitles.join(' • '),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColor.text,
            ),
          ),
          if (entry.note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.note,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            sharedNames.isEmpty
                ? 'Not distributed yet'
                : 'Shared with ${sharedNames.join(', ')}',
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

class _GuardrailPill extends StatelessWidget {
  const _GuardrailPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.safe),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColor.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
