import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'constant.dart';

double calculateDeduction(double x) {
  // Calculate 15% of x
  final deduction = 0.15 * x;

  // Deduct the calculated amount from x
  final result = x - deduction;

  return result;
}

bool isTablet(BuildContext context) =>
    MediaQuery.of(context).size.shortestSide > 600;

bool isLandscape(BuildContext context) =>
    MediaQuery.of(context).orientation == Orientation.landscape;

String formatDate(DateTime? dateTime) =>
    DateFormat('yyyy-MM-dd').format(dateTime ?? DateTime.now());

String formatDateWithoutDashes(DateTime? dateTime) =>
    DateFormat('yyyyMMdd').format(dateTime ?? DateTime.now());

String formatDateWitTime(DateTime? dateTime) =>
    DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime ?? DateTime.now());

Future<DateTime?> getDateFromPicker(
  BuildContext context,
  DateTime? selectedDate,
) async {
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: selectedDate ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2300),
  );

  return pickedDate;
}

String formatNumber(String value) {
  try {
    final numberFormatDe = NumberFormat('#,##0.00', 'en_US');
    final formattedNumberDe = numberFormatDe.format(double.parse(value));
    return formattedNumberDe;
  } catch (e) {
    return '';
  }
}

String getMainString(String input) {
  final regex = RegExp(r'\(@F\)\s*([^,]+)');
  final Match? match = regex.firstMatch(input);

  if (match != null && match.groupCount > 0) {
    return match.group(1)!;
  }

  return '';
}

double convertToDouble(dynamic value) {
  if (value is int) {
    return value.toDouble();
  } else if (value is double) {
    return value;
  } else if (value is String) {
    return double.tryParse(value) ?? 0.0;
  } else {
    return 0; // Return a default value if the conversion fails
  }
}

double parseToDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) {
    return value.toDouble();
  } else if (value is String) {
    return double.tryParse(value) ?? 0.0;
  } else {
    return 0;
  }
}

String? passwordValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter password.';
  } else if (value.length < 8) {
    return 'Use at least 8 characters.';
  } else if (!RegExp('[A-Z]').hasMatch(value)) {
    return 'Add at least one uppercase letter.';
  } else if (!RegExp('[a-z]').hasMatch(value)) {
    return 'Add at least one lowercase letter.';
  } else if (!RegExp(r'\d').hasMatch(value)) {
    return 'Include at least one number.';
  } else if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
    return 'Use at least one special character.';
  }
  return null; // Valid password
}

String removeDialCode(String completePhoneNumber, String dialCode) {
  if (completePhoneNumber.startsWith(dialCode)) {
    return completePhoneNumber.substring(dialCode.length);
  }
  return completePhoneNumber; // Return as-is if the dial code isn't present
}

// Success SnackBar
void showSuccessSnackBar({
  required BuildContext context,
  required String snackBarTxt,
  String? title,
  Color? txtColor,
}) {
  showTopSnackBar(
    Overlay.of(context),
    animationDuration: const Duration(seconds: 2),
    CustomSnackBar.success(
      message: snackBarTxt,
      maxLines: 3,
      textStyle: kTextStyle.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      messagePadding: const EdgeInsets.symmetric(horizontal: 10),
    ),
  );
}

// Error SnackBar
void showErrorSnackBar({
  required BuildContext context,
  required String snackBarTxt,
  String? title,
  Color? txtColor,
}) {
  showTopSnackBar(
    Overlay.of(context),
    padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
    animationDuration: const Duration(seconds: 2),
    CustomSnackBar.error(
      message: snackBarTxt,
      maxLines: 3,
      textStyle: kTextStyle.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      messagePadding: const EdgeInsets.symmetric(horizontal: 10),
    ),
  );
}

String capFirstLetter(String? text) {
  if (text == null || text.isEmpty) return ''; // Handle null or empty string
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

double calculateServiceFee(
  dynamic ratePerHour,
  dynamic hoursRequired,
  dynamic numberOfPersons,
) {
  final rate = double.tryParse(ratePerHour.toString()) ?? 0.0;
  final hours = double.tryParse(hoursRequired.toString()) ?? 0.0;
  final persons = int.tryParse(numberOfPersons.toString()) ?? 0;

  final value = (rate * hours * persons) * 0.15;
  return double.parse(value.toStringAsFixed(2));
}

double calculateTotalCost(
  dynamic ratePerHour,
  dynamic hoursRequired,
  dynamic numberOfPersons,
) {
  final rate = double.tryParse(ratePerHour.toString()) ?? 0.0;
  final hours = double.tryParse(hoursRequired.toString()) ?? 0.0;
  final persons = int.tryParse(numberOfPersons.toString()) ?? 0;

  final baseCost = rate * hours * persons;
  final serviceFee = baseCost * 0.15;
  final totalCost = baseCost + serviceFee;

  return double.parse(totalCost.toStringAsFixed(2));
}

Future<void> openGoogleMapsDirections({
  required double startLat,
  required double startLng,
  required double destLat,
  required double destLng,
}) async {
  final url =
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$startLat,$startLng'
      '&destination=$destLat,$destLng'
      '&travelmode=driving';

  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    throw 'Could not launch $url';
  }
}

Future<DateTime?> pickDateTime(BuildContext context) async {
  // Pick the date
  final selectedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  // Return null if no date is selected.
  if (selectedDate == null) return null;

  // Pick the time
  final selectedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );

  // Return null if no time is selected.
  if (selectedTime == null) return null;

  // Combine the selected date and time into a DateTime object.
  return DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    selectedTime.hour,
    selectedTime.minute,
  );
}

String formatDateTime(DateTime dateTime) {
  // Pattern explanation:
  // EEE - abbreviated day of the week (e.g., Tue)
  // d - day of the month (e.g., 14)
  // MMM - abbreviated month (e.g., Feb)
  // 'at' - literal string
  // ha - hour in am/pm format (e.g., 12PM)
  var formatted = DateFormat("EEE, d MMM 'at' ha").format(dateTime);

  // Optional: if you specifically need the month in lowercase (e.g., "feb" instead of "Feb")
  // you can replace the month portion.
  // For a simple approach, you can convert the entire formatted string to lowercase and then fix the day of week:
  // However, a more targeted approach is better:

  // Extract month part, make it lowercase, and reconstruct the string:
  // This assumes the month is the third word in the string.
  final parts = formatted.split(' ');
  if (parts.length >= 3) {
    parts[2] = parts[2].toLowerCase();
    formatted = parts.join(' ');
  }

  return formatted;
}

String getDayAndMonth(String? dateStr) {
  DateTime date;
  if (dateStr == null || dateStr.trim().isEmpty) {
    date = DateTime.now();
  } else {
    try {
      date = DateTime.parse(dateStr);
    } catch (e) {
      date = DateTime.now();
    }
  }
  return DateFormat('EEE, d MMM').format(date);
}

String getTimeFromDate(String? dateStr) {
  DateTime date;
  if (dateStr == null || dateStr.trim().isEmpty) {
    date = DateTime.now();
  } else {
    try {
      date = DateTime.parse(dateStr);
    } catch (e) {
      date = DateTime.now();
    }
  }
  return DateFormat('h:mm a').format(date);
}
