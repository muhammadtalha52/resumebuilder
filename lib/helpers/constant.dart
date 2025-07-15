import 'package:flutter/material.dart';

const Color kNeutralColor = Color(0xFF6B7280);

// DASI Purple colors
const Color kDasiPurpleDark = Color(0xFF6D5BFF); // Dark mode purple
const Color kDasiPurpleDarkPressed = Color(
  0xFF5A4CE1,
); // Dark mode pressed state
const Color kDasiPurpleLight = Color(0xFF8B5CF6); // Light mode purple
const Color kDasiPurpleLightPressed = Color(
  0xFF8B5CF6,
); // Light mode pressed (90% opacity applied programmatically)

// Background colors
const Color kBackgroundLight = Color(
  0xFFF8FBFF,
); // Light mode background (white)
const Color kBackgroundDark = Color(0xFF000000); // Dark mode background (black)

const kTextStyle = TextStyle(
  color: kNeutralColor,
  fontFamily: FontFamilies.inter,
);

// Helper function to get the appropriate purple color based on theme
Color getDasiPurple(BuildContext context, {bool isPressed = false}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  if (isDarkMode) {
    return isPressed ? kDasiPurpleDarkPressed : kDasiPurpleDark;
  } else {
    return isPressed
        ? kDasiPurpleLightPressed.withValues(alpha: 0.9)
        : kDasiPurpleLight;
  }
}

// Helper function to get the appropriate background color based on theme
Color getBackgroundColor(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  return isDarkMode ? kBackgroundDark : kBackgroundLight;
}

const String findMemberInfoUrl =
    'https://cloudjoin.ecohytech.net/cloudRegister/findInfo.jsp';
const String customerSupportUrl = 'https://www.ecohytech.co.kr/';

List<String> status = ['', 'publish', 'draft', 'in-progress', 'completed'];
List<String> accountTypes = ['Checking', 'Savings'];
List<String> accountHolderTypes = ['Individual', 'Company'];
final List<Map<String, String>> roomTypes = [
  {'id': 'living_room', 'name': 'Living Room'},
  {'id': 'bedroom', 'name': 'Bedroom'},
  {'id': 'kitchen', 'name': 'Kitchen'},
  {'id': 'bathroom', 'name': 'Bathroom'},
  {'id': 'office', 'name': 'Home Office'},
  {'id': 'dining_room', 'name': 'Dining Room'},
  {'id': 'outdoor', 'name': 'Outdoor Space'},
];

// List of available style options
final List<Map<String, String>> roomStyles = [
  {'id': 'modern', 'name': 'Modern'},
  {'id': 'traditional', 'name': 'Traditional'},
  {'id': 'farmhouse', 'name': 'Farmhouse'},
  {'id': 'industrial', 'name': 'Industrial'},
  {'id': 'scandinavian', 'name': 'Scandinavian'},
  {'id': 'bohemian', 'name': 'Bohemian'},
  {'id': 'mid_century', 'name': 'Mid-Century'},
];

class FontFamilies {
  static const String inter = 'Inter';
}
