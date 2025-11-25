/// Utility class for date formatting and conversion
class DateHelpers {
  /// Formats a DateTime to yyyy-MM-dd format
  /// Returns null if date is null
  /// Example: 2024-01-15
  static String? formatToApiDate(DateTime? date) {
    if (date == null) return null;

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Parses a date string in various formats to DateTime
  /// Handles ISO8601, yyyy-MM-dd, and other common formats
  /// Returns null if parsing fails
  static DateTime? parseApiDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      // Try to parse as standard DateTime (handles ISO8601 and other formats)
      return DateTime.parse(dateString);
    } catch (e) {
      // If standard parsing fails, try manual parsing for yyyy-MM-dd
      try {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      } catch (_) {
        // Ignore and return null
      }
    }

    return null;
  }

  /// Formats a DateTime to display format MM/DD/YYYY
  /// Returns empty string if date is null
  static String formatToDisplayDate(DateTime? date) {
    if (date == null) return '';

    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Converts a string date (that might be in ISO8601 format) to yyyy-MM-dd format
  /// Useful for converting stored dates to API format
  static String? convertToApiDateFormat(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    // If already in correct format, return as is
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateString)) {
      return dateString;
    }

    // Parse and reformat
    final date = parseApiDate(dateString);
    return formatToApiDate(date);
  }

  /// Validates if a date string is in yyyy-MM-dd format
  static bool isValidApiDateFormat(String? dateString) {
    if (dateString == null || dateString.isEmpty) return false;

    // Check format
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateString)) {
      return false;
    }

    // Check if it's a valid date
    try {
      final parts = dateString.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      // Basic validation
      if (month < 1 || month > 12) return false;
      if (day < 1 || day > 31) return false;
      if (year < 1900 || year > 2100) return false;

      // Create DateTime to validate the date is real
      final date = DateTime(year, month, day);
      return date.year == year && date.month == month && date.day == day;
    } catch (_) {
      return false;
    }
  }

  /// Formats a DateTime to a readable format with time
  /// Returns 'N/A' if date is null
  /// Example: "11/25/2025, 2:30pm"
  static String formatToReadableDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';

    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'pm' : 'am';
    final displayHour = hour == 0 ? 12 : hour; // Handle midnight and noon

    return '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}/${dateTime.year}, $displayHour:${dateTime.minute.toString().padLeft(2, '0')}$period';
  }

  /// Formats duration in minutes to a readable format
  /// Returns 'N/A' if minutes is null
  /// Example: "90 minutes", "2 hours, 30 minutes", "1 hour"
  static String formatDuration(int? minutes) {
    if (minutes == null) return 'N/A';
    if (minutes < 60) return '$minutes minutes';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    return remainingMinutes > 0
        ? '$hours hour${hours > 1 ? 's' : ''}, $remainingMinutes minutes'
        : '$hours hour${hours > 1 ? 's' : ''}';
  }

  /// Formats a date string to relative time
  /// Returns relative time like "just now", "1 hour ago", "2 days ago"
  /// Returns empty string if date string is invalid
  static String getTimeAgo(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return '$years year${years > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 7) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks week${weeks > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'just now';
      }
    } catch (e) {
      return '';
    }
  }

  /// Parses a UTC datetime string and converts it to local DateTime
  /// Returns null if parsing fails
  /// Example: "2025-10-20T12:18:58.175018Z" -> Local DateTime
  static DateTime? parseUtcToLocal(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      final utcDate = DateTime.parse(dateString);
      return utcDate.toLocal();
    } catch (e) {
      return null;
    }
  }

  /// Parses a UTC datetime string, converts to local, and formats it
  /// Returns defaultValue if parsing fails
  /// Example: "2025-10-20T12:18:58.175018Z" -> "10/20/2025 • 05:18 PM"
  static String formatUtcToLocal(
    String? dateString, {
    String format = 'MM/dd/yyyy • hh:mm a',
    String defaultValue = 'N/A',
  }) {
    final localDate = parseUtcToLocal(dateString);
    if (localDate == null) return defaultValue;

    try {
      // Format based on the provided pattern
      final year = localDate.year;
      final month = localDate.month;
      final day = localDate.day;
      final hour = localDate.hour;
      final minute = localDate.minute;

      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final period = hour >= 12 ? 'PM' : 'AM';

      // Default format: "10/20/2025 • 05:18 PM"
      return '${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}/$year • ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return defaultValue;
    }
  }

  /// Formats a DateTime object to local time string
  /// Assumes the DateTime is in UTC and converts to local
  /// Returns defaultValue if date is null
  /// Example: DateTime(UTC) -> "10/20/2025 • 05:18 PM"
  static String formatDateTimeToLocal(
    DateTime? dateTime, {
    String defaultValue = 'N/A',
  }) {
    if (dateTime == null) return defaultValue;

    try {
      // Convert UTC to local time
      final localDate = dateTime.toLocal();

      final year = localDate.year;
      final month = localDate.month;
      final day = localDate.day;
      final hour = localDate.hour;
      final minute = localDate.minute;

      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final period = hour >= 12 ? 'PM' : 'AM';

      // Default format: "10/20/2025 • 05:18 PM"
      return '${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}/$year • ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return defaultValue;
    }
  }
}
