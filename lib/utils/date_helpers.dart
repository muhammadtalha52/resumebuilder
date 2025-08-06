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

  /// Formats a DateTime to display format DD/MM/YYYY
  /// Returns empty string if date is null
  static String formatToDisplayDate(DateTime? date) {
    if (date == null) return '';

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
}
