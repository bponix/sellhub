import 'package:sellhub/features/profile/data/model/team_member_entry.dart';
import 'package:sellhub/features/profile/data/model/team_shared_list_entry.dart';

class TeamSellingOverview {
  const TeamSellingOverview({
    required this.teamId,
    required this.ownerUserId,
    required this.siteId,
    required this.teamName,
    required this.ownerName,
    required this.overridePercent,
    required this.transparentPayoutRule,
    required this.activeMembers,
    required this.pendingInvites,
    required this.teamOrderVolume,
    required this.overrideEarned,
    required this.sharedListCount,
    required this.distributedProductCount,
    required this.members,
    required this.sharedLists,
  });

  final String teamId;
  final int ownerUserId;
  final int siteId;
  final String teamName;
  final String ownerName;
  final double overridePercent;
  final String transparentPayoutRule;
  final int activeMembers;
  final int pendingInvites;
  final double teamOrderVolume;
  final double overrideEarned;
  final int sharedListCount;
  final int distributedProductCount;
  final List<TeamMemberEntry> members;
  final List<TeamSharedListEntry> sharedLists;
}
