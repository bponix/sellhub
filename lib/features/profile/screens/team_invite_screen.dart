import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/formatDateTime.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/profile/data/model/self_store_customer.dart';
import 'package:sellhub/features/profile/data/model/team_member_entry.dart';
import 'package:sellhub/features/profile/data/model/team_selling_overview.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';
import 'package:sellhub/injection_container.dart' as di;

class TeamInviteScreen extends StatefulWidget {
  const TeamInviteScreen({
    super.key,
    required this.teamId,
    required this.memberId,
    required this.ownerUserId,
    required this.siteId,
    this.inviteCode,
    this.teamName,
    this.ownerName,
    this.overridePercent = 0,
  });

  final String teamId;
  final String memberId;
  final String? inviteCode;
  final int ownerUserId;
  final int siteId;
  final String? teamName;
  final String? ownerName;
  final double overridePercent;

  @override
  State<TeamInviteScreen> createState() => _TeamInviteScreenState();
}

class _TeamInviteScreenState extends State<TeamInviteScreen> {
  Future<
    ({
      TeamSellingOverview? overview,
      TeamMemberEntry? member,
      SelfStoreCustomerRes? customer,
    })
  >?
  _future;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  bool get _isValidInvite =>
      (widget.memberId.trim().isNotEmpty ||
          (widget.inviteCode?.trim().isNotEmpty ?? false)) &&
      widget.teamId.trim().isNotEmpty &&
      widget.ownerUserId > 0 &&
      widget.siteId > 0;

  Future<
    ({
      TeamSellingOverview? overview,
      TeamMemberEntry? member,
      SelfStoreCustomerRes? customer,
    })
  >
  _load() async {
    if (!_isValidInvite) {
      return (overview: null, member: null, customer: null);
    }
    final repo = di.sl<ProfileRepository>();
    final currentUserId = await LocalStorage.getUserID() ?? 0;
    final overview = await repo.fetchTeamSellingOverview(
      userId: widget.ownerUserId,
      siteId: widget.siteId,
    );
    final localMember = widget.memberId.trim().isEmpty
        ? null
        : await repo.fetchTeamMember(widget.memberId);
    final inviteCode = widget.inviteCode?.trim();
    final member =
        localMember ??
        overview.members.cast<TeamMemberEntry?>().firstWhere(
          (member) =>
              member?.id == widget.memberId ||
              (inviteCode?.isNotEmpty == true &&
                  member?.inviteCode.toLowerCase() ==
                      inviteCode!.toLowerCase()),
          orElse: () => null,
        );
    final customer = currentUserId > 0
        ? await repo.fetchSelfStoreCustomer(currentUserId, widget.siteId)
        : null;
    return (overview: overview, member: member, customer: customer);
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _acceptInvite(
    TeamSellingOverview? overview,
    TeamMemberEntry? member,
    SelfStoreCustomerRes? customer,
  ) async {
    if (_accepting || !_isValidInvite) return;
    setState(() {
      _accepting = true;
    });
    try {
      final currentUserId = await LocalStorage.getUserID() ?? 0;
      final customerTitle = customer?.title?.trim();
      final customerPhone = customer?.phone?.toString().trim();
      await di.sl<ProfileRepository>().acceptTeamInvite(
        memberId: widget.memberId,
        inviteCode: widget.inviteCode,
        teamId: widget.teamId,
        ownerUserId: widget.ownerUserId,
        currentUserId: currentUserId,
        siteId: widget.siteId,
        memberCustomerId: customer?.id,
        sellerName: customerTitle?.isNotEmpty == true
            ? customerTitle
            : member?.name,
        sellerPhone: customerPhone?.isNotEmpty == true
            ? customerPhone
            : member?.phone,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team invite accepted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _refresh();
    } finally {
      if (mounted) {
        setState(() {
          _accepting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Team invite',
        subtitle: 'Review and accept the direct seller invite',
        icon: HugeIcons.strokeRoundedUserMultiple02,
        showBackButton: true,
      ),
      body:
          FutureBuilder<
            ({
              TeamSellingOverview? overview,
              TeamMemberEntry? member,
              SelfStoreCustomerRes? customer,
            })
          >(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final payload = snapshot.data;
              final overview = payload?.overview;
              final member = payload?.member;
              final customer = payload?.customer;
              final customerTitle = customer?.title?.trim();
              final customerPhone = customer?.phone?.toString().trim();
              final isAccepted = member?.isActive == true;
              if (!_isValidInvite) {
                return const _InviteEmptyState(
                  title: 'Invite link is incomplete',
                  subtitle: 'Ask the team owner to send the invite again.',
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _InviteHero(
                    teamName:
                        overview?.teamName ?? widget.teamName ?? 'SellHub Team',
                    ownerName:
                        overview?.ownerName ?? widget.ownerName ?? 'Team owner',
                    overridePercent:
                        overview?.overridePercent ?? widget.overridePercent,
                  ),
                  const SizedBox(height: 16),
                  _InviteFactCard(
                    label: 'Invite status',
                    value: isAccepted
                        ? 'Accepted'
                        : member?.isPending == true
                        ? 'Pending'
                        : 'Ready to accept',
                  ),
                  const SizedBox(height: 12),
                  _InviteFactCard(
                    label: 'Direct payout rule',
                    value:
                        overview?.transparentPayoutRule ??
                        'Override applies only to direct team sales.',
                  ),
                  const SizedBox(height: 12),
                  _InviteFactCard(
                    label: 'Your seller record',
                    value: customerTitle?.isNotEmpty == true
                        ? '$customerTitle • ${customerPhone ?? ''}'
                        : member?.name ?? 'Seller record will attach on accept',
                  ),
                  if (overview != null) ...[
                    const SizedBox(height: 12),
                    _InviteFactCard(
                      label: 'Current team output',
                      value:
                          '${overview.activeMembers} active sellers • ৳${overview.teamOrderVolume.toStringAsFixed(0)} team volume',
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isAccepted
                          ? null
                          : () => _acceptInvite(overview, member, customer),
                      child: Text(
                        _accepting
                            ? 'Accepting...'
                            : isAccepted
                            ? 'Invite accepted'
                            : 'Accept invite',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => AppRouter.goToHome(context),
                    child: const Text('Back to home'),
                  ),
                  if (member?.lastActiveAt != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Latest team activity ${formatDateTime(member!.lastActiveAt)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
    );
  }
}

class _InviteHero extends StatelessWidget {
  const _InviteHero({
    required this.teamName,
    required this.ownerName,
    required this.overridePercent,
  });

  final String teamName;
  final String ownerName;
  final double overridePercent;

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
            teamName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColor.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Owner: $ownerName',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _GuardrailPill(
                label: '${overridePercent.toStringAsFixed(0)}% direct override',
              ),
              const _GuardrailPill(label: 'No MLM chain'),
              const _GuardrailPill(label: 'Direct seller only'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InviteFactCard extends StatelessWidget {
  const _InviteFactCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(999),
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

class _InviteEmptyState extends StatelessWidget {
  const _InviteEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
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
                HugeIcons.strokeRoundedAlert02,
                size: 40,
                color: AppColor.neutral2,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColor.neutral2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
