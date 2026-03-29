import 'package:intl/intl.dart';

String formatDateTime(DateTime? updatedAt) {
  if (updatedAt == null) return "";

  // format: 03:13 PM Jan 25
  return DateFormat('hh:mm a MMM d').format(updatedAt);
}

// How many days ago logic
String timeAgo(DateTime? updatedAt) {
  if (updatedAt == null) return "";

  final duration = DateTime.now().difference(updatedAt);

  if (duration.inDays >= 30) {
    int month = ((duration.inDays) / 30).floor();
    return "$month month${month > 1 ? 's' : ''} ago ";
  } else if (duration.inDays >= 7) {
    int weeks = (duration.inDays / 7).floor();
    return "$weeks week${weeks > 1 ? 's' : ''} ago";
  } else if (duration.inDays >= 1) {
    return "${duration.inDays} day${duration.inDays > 1 ? 's' : ''}ago";
  } else if (duration.inHours >= 1) {
    return "${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}ago";
  } else {
    return "Just now";
  }
}
