class TimeUtils {
  /// Format duration since a given timestamp (e.g., "3 days ago", "2 hours ago")
  static String formatTimeSince(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      final days = difference.inDays;
      return days == 1 ? '1 day ago' : '$days days ago';
    } else if (difference.inHours > 0) {
      final hours = difference.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    } else if (difference.inMinutes > 0) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Format duration in a more compact way (e.g., "3d", "2h", "45m")
  static String formatCompactTimeSince(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  /// Format a timestamp to a readable date and time
  static String formatDateTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final timestampDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    String dateStr;
    if (timestampDate == today) {
      dateStr = 'Today';
    } else if (timestampDate == yesterday) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }

    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }

  /// Format duration between two timestamps
  static String formatDuration(DateTime start, DateTime end) {
    final difference = end.difference(start);

    if (difference.inDays > 0) {
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      if (hours > 0) {
        return '${days}d ${hours}h';
      }
      return days == 1 ? '1 day' : '$days days';
    } else if (difference.inHours > 0) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return hours == 1 ? '1 hour' : '$hours hours';
    } else if (difference.inMinutes > 0) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? '1 minute' : '$minutes minutes';
    } else {
      final seconds = difference.inSeconds;
      return seconds == 1 ? '1 second' : '$seconds seconds';
    }
  }
}
