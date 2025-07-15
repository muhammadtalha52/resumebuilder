import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constant.dart';

// Font Family
class FontFamilies {
  static const String inter = 'Inter';
}

// Theme Configuration
class Themes {
  static ThemeData lightTheme() => ThemeData(
    brightness: Brightness.light,
    primaryColor: kDasiPurpleLight,
    scaffoldBackgroundColor: Colors.white,
    // Pure white background
    useMaterial3: true,
    disabledColor: const Color.fromRGBO(185, 185, 185, 1),
    fontFamily: FontFamilies.inter,
    colorScheme: ColorScheme.fromSeed(seedColor: kDasiPurpleLight),
    cardTheme: _cardThemeLight(),
    appBarTheme: _appBarThemeLight(),
    datePickerTheme: _datePickerTheme(),
    timePickerTheme: _timePickerTheme(),
    textTheme: _textThemeLight(),
    tabBarTheme: _tabBarTheme(),
    inputDecorationTheme: _inputDecorationThemeLight(),
    popupMenuTheme: _popUpMenuThemeDataLight(),
    textSelectionTheme: _textSelectionTheme(),
    textButtonTheme: _textButtonTheme(),
    scrollbarTheme: _scrollbarTheme(),
    checkboxTheme: _checkBoxThemeData(),
    elevatedButtonTheme: _elevatedButtonThemeDataLight(),
    outlinedButtonTheme: _outlinedButtonThemeData(),
    expansionTileTheme: _expansionTileThemeData(),
    bottomNavigationBarTheme: _bottomNavigationBarThemeLight(),
  );

  static ThemeData darkTheme() => ThemeData(
    brightness: Brightness.dark,
    primaryColor: kDasiPurpleDark,
    scaffoldBackgroundColor: Colors.black,
    // Pure black background
    useMaterial3: true,
    disabledColor: const Color.fromRGBO(100, 100, 100, 1),
    fontFamily: FontFamilies.inter,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kDasiPurpleDark,
      brightness: Brightness.dark,
    ),
    cardTheme: _cardThemeDark(),
    appBarTheme: _appBarThemeDark(),
    datePickerTheme: _datePickerThemeDark(),
    timePickerTheme: _timePickerThemeDark(),
    textTheme: _textThemeDark(),
    tabBarTheme: _tabBarThemeDark(),
    inputDecorationTheme: _inputDecorationThemeDark(),
    popupMenuTheme: _popUpMenuThemeDataDark(),
    textSelectionTheme: _textSelectionThemeDark(),
    textButtonTheme: _textButtonThemeDark(),
    scrollbarTheme: _scrollbarThemeDark(),
    checkboxTheme: _checkBoxThemeDataDark(),
    elevatedButtonTheme: _elevatedButtonThemeDataDark(),
    outlinedButtonTheme: _outlinedButtonThemeDataDark(),
    expansionTileTheme: _expansionTileThemeData(),
    bottomNavigationBarTheme: _bottomNavigationBarThemeDark(),
  );

  // Card Themes
  static CardThemeData _cardThemeLight() => CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  static CardThemeData _cardThemeDark() => CardThemeData(
    color: const Color(0xFF1F2937),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  // AppBar Themes
  static AppBarTheme _appBarThemeLight() => const AppBarTheme(
    elevation: 0,
    color: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: true,
    ),
    actionsIconTheme: IconThemeData(color: kNeutralColor),
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 16,
      letterSpacing: 0.5,
      color: Colors.black,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Colors.black),
  );

  static AppBarTheme _appBarThemeDark() => const AppBarTheme(
    elevation: 0,
    color: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemStatusBarContrastEnforced: true,
    ),
    actionsIconTheme: IconThemeData(color: Colors.white70),
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 16,
      letterSpacing: 0.5,
      color: Colors.white,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  );

  // Date Picker Themes
  static DatePickerThemeData _datePickerTheme() {
    return DatePickerThemeData(
      backgroundColor: Colors.white,
      headerBackgroundColor: kDasiPurpleLight,
      headerForegroundColor: Colors.white,
      todayBorder: const BorderSide(color: kDasiPurpleLight),
      dayBackgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? kDasiPurpleLight
            : Colors.transparent,
      ),
      todayBackgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? kDasiPurpleLight
            : Colors.transparent,
      ),
      cancelButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(kDasiPurpleLight),
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      confirmButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(kDasiPurpleLight),
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static DatePickerThemeData _datePickerThemeDark() {
    return DatePickerThemeData(
      backgroundColor: const Color(0xFF1F2937),
      headerBackgroundColor: kDasiPurpleDark,
      headerForegroundColor: Colors.white,
      todayBorder: const BorderSide(color: kDasiPurpleDark),
      dayBackgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? kDasiPurpleDark
            : Colors.transparent,
      ),
      todayBackgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? kDasiPurpleDark
            : Colors.transparent,
      ),
      cancelButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(kDasiPurpleDark),
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      confirmButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(kDasiPurpleDark),
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Time Picker Themes
  static TimePickerThemeData _timePickerTheme() {
    return TimePickerThemeData(
      backgroundColor: Colors.white,
      hourMinuteColor: Colors.grey.shade200,
      hourMinuteTextColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? kDasiPurpleLight
            : Colors.black,
      ),
      dialHandColor: kDasiPurpleLight,
      dialBackgroundColor: Colors.grey.shade200,
      dayPeriodColor: kDasiPurpleLight,
      dayPeriodBorderSide: const BorderSide(color: kDasiPurpleLight),
      dayPeriodTextColor: WidgetStateColor.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? Colors.white : Colors.black,
      ),
      entryModeIconColor: Colors.black,
      cancelButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(kDasiPurpleLight),
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      confirmButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(kDasiPurpleLight),
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static TimePickerThemeData _timePickerThemeDark() {
    return TimePickerThemeData(
      backgroundColor: const Color(0xFF1F2937),
      hourMinuteColor: const Color(0xFF374151),
      hourMinuteTextColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? kDasiPurpleDark
            : Colors.white,
      ),
      dialHandColor: kDasiPurpleDark,
      dialBackgroundColor: const Color(0xFF374151),
      dayPeriodColor: kDasiPurpleDark,
      dayPeriodBorderSide: const BorderSide(color: kDasiPurpleDark),
      dayPeriodTextColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : Colors.white70,
      ),
      entryModeIconColor: Colors.white,
      cancelButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(kDasiPurpleDark),
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      confirmButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(kDasiPurpleDark),
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Text Themes
  static TextTheme _textThemeLight() => const TextTheme(
    displayLarge: TextStyle(
      height: 1,
      fontSize: 96,
      color: Colors.black,
      letterSpacing: -1.5,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.normal,
    ),
    displayMedium: TextStyle(
      height: 1.2,
      fontSize: 60,
      color: Colors.black,
      letterSpacing: -0.5,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.normal,
    ),
    displaySmall: TextStyle(
      height: 1.2,
      fontSize: 48,
      letterSpacing: 0,
      color: Colors.black,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.normal,
    ),
    headlineMedium: TextStyle(
      height: 1.2,
      fontSize: 34,
      letterSpacing: 0.25,
      color: Colors.black,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.normal,
    ),
    headlineSmall: TextStyle(
      height: 1.2,
      fontSize: 24,
      letterSpacing: 0,
      color: Colors.black,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      height: 1.2,
      fontSize: 20,
      letterSpacing: 0.15,
      color: Colors.black,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      letterSpacing: 0.15,
      color: Color(0xFF323643),
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      letterSpacing: 0.1,
      color: Color(0xFF323643),
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      letterSpacing: 0.5,
      color: Color(0xFF323643),
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
      letterSpacing: 0.25,
      color: Color(0xFF6B7280),
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      letterSpacing: 1.25,
      color: Colors.white,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.bold,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      letterSpacing: 0.4,
      color: Color(0xFF9CA3AF),
      fontFamily: FontFamilies.inter,
      height: 1.2,
      fontWeight: FontWeight.w500,
    ),
  );

  static TextTheme _textThemeDark() => const TextTheme(
    displayLarge: TextStyle(
      height: 1,
      fontSize: 96,
      color: Colors.white,
      letterSpacing: -1.5,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.normal,
    ),
    displayMedium: TextStyle(
      height: 1.2,
      fontSize: 60,
      color: Colors.white,
      letterSpacing: -0.5,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.normal,
    ),
    displaySmall: TextStyle(
      height: 1.2,
      fontSize: 48,
      letterSpacing: 0,
      color: Colors.white,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.normal,
    ),
    headlineMedium: TextStyle(
      height: 1.2,
      fontSize: 34,
      letterSpacing: 0.25,
      color: Colors.white,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.normal,
    ),
    headlineSmall: TextStyle(
      height: 1.2,
      fontSize: 24,
      letterSpacing: 0,
      color: Colors.white,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      height: 1.2,
      fontSize: 20,
      letterSpacing: 0.15,
      color: Colors.white,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      letterSpacing: 0.15,
      color: Color(0xFFE5E7EB),
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      letterSpacing: 0.1,
      color: Color(0xFFE5E7EB),
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      letterSpacing: 0.5,
      color: Color(0xFFE5E7EB),
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
      letterSpacing: 0.25,
      color: Color(0xFF9CA3AF),
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      letterSpacing: 1.25,
      color: Colors.white,
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.bold,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      letterSpacing: 0.4,
      color: Color(0xFF6B7280),
      fontFamily: FontFamilies.inter,
      height: 1.2,
      fontWeight: FontWeight.w500,
    ),
  );

  // TabBar Theme
  static TabBarThemeData _tabBarTheme() => TabBarThemeData(
    labelColor: Colors.black,
    unselectedLabelColor: Colors.grey,
    labelStyle: const TextStyle(
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.bold,
    ),
    unselectedLabelStyle: TextStyle(
      fontFamily: FontFamilies.inter,
      color: Colors.grey[500],
      fontWeight: FontWeight.w600,
    ),
    indicator: const BoxDecoration(
      border: Border(bottom: BorderSide(color: kDasiPurpleLight, width: 4)),
    ),
  );

  static TabBarThemeData _tabBarThemeDark() => TabBarThemeData(
    labelColor: Colors.white,
    unselectedLabelColor: Colors.grey,
    labelStyle: const TextStyle(
      fontFamily: FontFamilies.inter,
      fontWeight: FontWeight.bold,
    ),
    unselectedLabelStyle: TextStyle(
      fontFamily: FontFamilies.inter,
      color: Colors.grey[500],
      fontWeight: FontWeight.w600,
    ),
    indicator: const BoxDecoration(
      border: Border(bottom: BorderSide(color: kDasiPurpleDark, width: 4)),
    ),
  );

  // Input Decoration Themes
  static InputDecorationTheme _inputDecorationThemeLight() =>
      InputDecorationTheme(
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 13,
          fontFamily: FontFamilies.inter,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kDasiPurpleLight),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
          fontFamily: FontFamilies.inter,
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.normal,
        ),
      );

  static InputDecorationTheme _inputDecorationThemeDark() =>
      InputDecorationTheme(
        fillColor: const Color(0xFF1F2937),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 13,
          fontFamily: FontFamilies.inter,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kDasiPurpleDark),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF374151)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontFamily: FontFamilies.inter,
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.normal,
        ),
      );

  // ScrollBar Theme
  static ScrollbarThemeData _scrollbarTheme() =>
      ScrollbarThemeData(thumbColor: WidgetStateProperty.all(Colors.grey));

  static ScrollbarThemeData _scrollbarThemeDark() =>
      ScrollbarThemeData(thumbColor: WidgetStateProperty.all(Colors.grey[700]));

  // PopUp Menu Themes
  static PopupMenuThemeData _popUpMenuThemeDataLight() => PopupMenuThemeData(
    elevation: 15,
    color: Colors.white,
    textStyle: TextStyle(
      color: Colors.grey[800],
      fontWeight: FontWeight.w500,
      fontSize: 12,
      fontFamily: FontFamilies.inter,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  static PopupMenuThemeData _popUpMenuThemeDataDark() => PopupMenuThemeData(
    elevation: 15,
    color: const Color(0xFF1F2937),
    textStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w500,
      fontSize: 12,
      fontFamily: FontFamilies.inter,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  // Text Selection Theme
  static TextSelectionThemeData _textSelectionTheme() => TextSelectionThemeData(
    selectionColor: kDasiPurpleLight.withValues(alpha: 0.3),
    cursorColor: kDasiPurpleLight,
    selectionHandleColor: kDasiPurpleLight,
  );

  static TextSelectionThemeData _textSelectionThemeDark() =>
      TextSelectionThemeData(
        selectionColor: kDasiPurpleDark.withValues(alpha: 0.3),
        cursorColor: kDasiPurpleDark,
        selectionHandleColor: kDasiPurpleDark,
      );

  // Text Button Theme
  static TextButtonThemeData _textButtonTheme() => TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: kDasiPurpleLight),
  );

  static TextButtonThemeData _textButtonThemeDark() => TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: kDasiPurpleDark),
  );

  // Elevated Button Theme
  static ElevatedButtonThemeData _elevatedButtonThemeDataLight() =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: kDasiPurpleLight,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: FontFamilies.inter,
          ),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          animationDuration: const Duration(milliseconds: 250),
          elevation: 0,
        ),
      );

  static ElevatedButtonThemeData _elevatedButtonThemeDataDark() =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF6366F1),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: FontFamilies.inter,
          ),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          animationDuration: const Duration(milliseconds: 250),
          elevation: 0,
        ),
      );

  // CheckBox Theme
  static CheckboxThemeData _checkBoxThemeData() => CheckboxThemeData(
    side: const BorderSide(width: 0.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
  );

  static CheckboxThemeData _checkBoxThemeDataDark() => CheckboxThemeData(
    side: const BorderSide(width: 0.5, color: Color(0xFF6B7280)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
  );

  // Outlined Button Theme
  static OutlinedButtonThemeData _outlinedButtonThemeData() =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kDasiPurpleLight,
          backgroundColor: Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: FontFamilies.inter,
          ),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          animationDuration: const Duration(milliseconds: 250),
          side: const BorderSide(width: 1.5, color: kDasiPurpleLight),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonThemeDataDark() =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kDasiPurpleDark,
          backgroundColor: Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: FontFamilies.inter,
          ),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          animationDuration: const Duration(milliseconds: 250),
          side: const BorderSide(width: 1.5, color: kDasiPurpleDark),
        ),
      );

  // Expansion Tile Theme
  static ExpansionTileThemeData _expansionTileThemeData() =>
      const ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
      );

  // Bottom Navigation Bar Themes
  static BottomNavigationBarThemeData _bottomNavigationBarThemeLight() =>
      const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: kDasiPurpleLight,
        unselectedItemColor: Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: FontFamilies.inter,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: FontFamilies.inter,
        ),
      );

  static BottomNavigationBarThemeData _bottomNavigationBarThemeDark() =>
      const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1F2937),
        selectedItemColor: kDasiPurpleDark,
        unselectedItemColor: Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: FontFamilies.inter,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: FontFamilies.inter,
        ),
      );
}
