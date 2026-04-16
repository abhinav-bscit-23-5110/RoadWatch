import 'package:flutter/material.dart';

class AppTheme {
  // ═══════════════════════════════════════════════════════════════════
  // BRAND COLORS (UNCHANGED - Used in both themes)
  // ═══════════════════════════════════════════════════════════════════
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color primaryBlueDark = Color(0xFF1565C0);
  static const Color secondaryGreen = Color(0xFF34A853);
  static const Color accentYellow = Color(0xFFFBBC05);
  static const Color dangerRed = Color(0xFFEA4335);
  static const Color warningOrange = Color(0xFFFF9800);

  // ═══════════════════════════════════════════════════════════════════
  // LIGHT THEME - ORIGINAL DESIGN (DO NOT MODIFY)
  // ═══════════════════════════════════════════════════════════════════

  // Light Theme Base
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBg = Color(0xFFFAFAFA);
  static const Color lightDivider = Color(0xFFE8EAED);
  static const Color lightTextPrimary = Color(0xFF202124);
  static const Color lightTextSecondary = Color(0xFF5F6368);
  static const Color lightTextTertiary = Color(0xFF9AA0A6);

  // Light Theme - Semantic Status Colors
  static const Color lightStatusPending = Color(0xFFFBBC05); // Amber
  static const Color lightStatusInProgress = Color(0xFF1A73E8); // Blue
  static const Color lightStatusResolved = Color(0xFF34A853); // Green

  // Light Theme - Semantic Status Colors (New for matching first UI)
  static const Color lightStatusPendingBgNew = Color(0xFFCFE8FF); // Light blue
  static const Color lightStatusPendingTextNew = Color(0xFF111827); // Dark text


  // Light Theme - Semantic Severity Colors
  static const Color lightSeverityLow = Color(0xFF5F6368); // Grey-Blue
  static const Color lightSeverityMedium = Color(0xFFFF9800); // Orange
  static const Color lightSeverityHigh = Color(0xFFD32F2F); // Red

  // ═══════════════════════════════════════════════════════════════════
  // DARK THEME - PROFESSIONAL SEMANTIC SYSTEM
  // Light Theme - Semantic Severity Colors (New for matching first UI)
  static const Color lightSeverityHighBgNew = Color(0xFFFADDDD); // Light red/pink
  static const Color lightSeverityHighTextNew = Color(0xFFEF4444); // Red

  // ═══════════════════════════════════════════════════════════════════

  // Dark Theme Base - Professional Navy Palette
  static const Color darkBackground = Color(0xFF0F172A); // Deep navy background
  static const Color darkSurface = Color(0xFF111827); // Primary surface
  static const Color darkElevatedSurface = Color(0xFF1E293B); // Elevated cards
  static const Color darkElevatedSurface2 = Color(
    0xFF334155,
  ); // Secondary elevated

  // Dark Theme Text - Professional
  static const Color darkTextPrimary = Color(0xFFE5E7EB); // Primary text
  static const Color darkTextSecondary = Color(0xFF9CA3AF); // Secondary text
  static const Color darkTextMuted = Color(0xFF6B7280); // Disabled/muted text

  // Dark Theme - Borders & Dividers
  static const Color darkDivider = Color(0xFF334155); // Subtle border
  static const Color darkBorderSubtle = Color(0xFF475569); // Brighter border

  // Dark Theme - Accent Colors
  static const Color darkPrimaryBlue = Color(0xFF60A5FA); // Bright blue
  static const Color darkSecondaryBlue = Color(0xFF3B82F6); // Solid blue

  // Dark Theme - Status Colors (Glassmorphism Style)
  // Pending: Amber
  static const Color darkStatusPendingBg = Color(0xFF2A1F12);
  static const Color darkStatusPendingText = Color(0xFFFBBF24);

  // In Progress: Blue
  static const Color darkStatusInProgressBg = Color(0xFF13233B);
  static const Color darkStatusInProgressText = Color(0xFF60A5FA);

  // Resolved: Green
  static const Color darkStatusResolvedBg = Color(0xFF132A1F);
  static const Color darkStatusResolvedText = Color(0xFF34D399);

  // Dark Theme - Severity Colors
  // Low: Teal
  static const Color darkSeverityLowBg = Color(0xFF0F2E2E);
  static const Color darkSeverityLowText = Color(0xFF5EEAD4);

  // Medium: Amber
  static const Color darkSeverityMediumBg = Color(0xFF2A1F12);
  static const Color darkSeverityMediumText = Color(0xFFFBBF24);

  // High: Red
  static const Color darkSeverityHighBg = Color(0xFF2B1215);
  static const Color darkSeverityHighText = Color(0xFFF87171);

  // Dark Theme - Input Fields & Forms
  static const Color darkInputBg = Color(0xFF1E293B); // Input background
  static const Color darkInputBorder = Color(0xFF334155); // Border color
  static const Color darkInputBorderFocus = Color(0xFF60A5FA); // Focus blue
  static const Color darkInputText = Color(0xFFE5E7EB); // Input text
  static const Color darkInputPlaceholder = Color(0xFF94A3B8); // Placeholder
  static const Color darkInputLabel = Color(0xFFCBD5E1); // Labels

  // Glass Effect Parameters (Dark Mode Only)
  static const double glassOpacity = 0.08; // 8% opacity
  static const double glassBlur = 14.0; // Medium blur
  static const double glassBorderOpacity = 0.12; // 12% border

  static const double borderRadius12 = 12.0;
  static const double borderRadius16 = 16.0;
  static const double borderRadius20 = 20.0;

  // ═══════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS (KEPT FOR REFERENCE)
  // ═══════════════════════════════════════════════════════════════════
  static const Color successGreen = Color(0xFF34A853);
  static const Color warningRed = Color(0xFFEA4335);
  static const Color infoBlue = Color(0xFF1A73E8);

  // ═══════════════════════════════════════════════════════════════════
  // LIGHT THEME (UNCHANGED - ORIGINAL DESIGN)
  // ═══════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: lightBackground,
      canvasColor: lightBackground,
      dividerColor: lightDivider,
      shadowColor: Colors.black.withOpacity(0.08),

      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        elevation: 1,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: lightTextPrimary),
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        color: lightCardBg,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius16),
          side: const BorderSide(color: lightDivider, width: 0.5),
        ),
        margin: const EdgeInsets.all(0),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          surfaceTintColor: primaryBlue,
          shadowColor: primaryBlue.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius12),
          borderSide: const BorderSide(color: lightDivider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius12),
          borderSide: const BorderSide(color: lightDivider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: lightTextSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: lightTextTertiary, fontSize: 14),
        counterStyle: const TextStyle(color: lightTextTertiary, fontSize: 12),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: lightTextSecondary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: lightTextSecondary,
          letterSpacing: 0.2,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightTextSecondary,
          letterSpacing: 0.2,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: lightTextTertiary,
          letterSpacing: 0.3,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: lightTextSecondary,
          letterSpacing: 0.4,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: lightTextTertiary,
          letterSpacing: 0.3,
        ),
      ),

      iconTheme: const IconThemeData(color: lightTextSecondary, size: 24),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius16),
        ),
        elevation: 8,
        hoverElevation: 12,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryBlue,
        unselectedItemColor: lightTextTertiary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: lightCardBg,
        selectedColor: primaryBlue,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius12),
          side: BorderSide(color: lightDivider.withOpacity(0.5)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius16),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightTextSecondary,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(borderRadius20),
            topRight: Radius.circular(borderRadius20),
          ),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: primaryBlue,
        unselectedLabelColor: lightTextTertiary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryBlue, width: 3),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // DARK THEME (FIXED - PROFESSIONAL & SEMANTIC)
  // ═══════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkPrimaryBlue,
      scaffoldBackgroundColor: darkBackground,
      canvasColor: darkBackground,
      dividerColor: darkDivider,
      shadowColor: Colors.black.withOpacity(0.3),

      appBarTheme: AppBarTheme(
        backgroundColor: darkElevatedSurface,
        foregroundColor: darkTextPrimary,
        elevation: 2,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        color: darkElevatedSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius16),
          side: BorderSide(color: darkBorderSubtle.withOpacity(0.3), width: 1),
        ),
        margin: const EdgeInsets.all(0),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: darkPrimaryBlue,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkSecondaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkSecondaryBlue,
          side: BorderSide(color: darkSecondaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius12),
          borderSide: const BorderSide(color: darkInputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius12),
          borderSide: const BorderSide(color: darkInputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius12),
          borderSide: const BorderSide(color: darkInputBorderFocus, width: 2),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: darkInputPlaceholder, fontSize: 14),
        counterStyle: const TextStyle(color: darkTextMuted, fontSize: 12),
        helperStyle: const TextStyle(color: darkTextSecondary, fontSize: 12),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: darkTextSecondary,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkTextMuted,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
          letterSpacing: 0.2,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
          letterSpacing: 0.2,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: darkTextMuted,
          letterSpacing: 0.3,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkTextSecondary,
          letterSpacing: 0.4,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: darkTextMuted,
          letterSpacing: 0.3,
        ),
      ),

      iconTheme: const IconThemeData(color: darkTextSecondary, size: 24),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkPrimaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius16),
        ),
        elevation: 4,
        hoverElevation: 8,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkElevatedSurface,
        selectedItemColor: darkSecondaryBlue,
        unselectedItemColor: darkTextMuted,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: darkElevatedSurface2,
        selectedColor: darkPrimaryBlue,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius12),
          side: BorderSide(color: darkBorderSubtle.withOpacity(0.3)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: darkElevatedSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius16),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkElevatedSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(borderRadius20),
            topRight: Radius.circular(borderRadius20),
          ),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: darkSecondaryBlue,
        unselectedLabelColor: darkTextMuted,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: darkSecondaryBlue, width: 3),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPER: Get status color based on theme
  // ═══════════════════════════════════════════════════════════════════
  static Color getStatusColor(String status, {required bool isDark}) {
    return getStatusBgColor(status, isDark: isDark);
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPER: Get status background color based on theme
  // ═══════════════════════════════════════════════════════════════════
  static Color getStatusBgColor(String status, {required bool isDark}) {
    if (!isDark) return Colors.transparent;

    switch (status.toLowerCase()) {
      case 'pending':
        return darkStatusPendingBg;
      case 'in progress':
        return darkStatusInProgressBg;
      case 'resolved':
      case 'verified':
        return darkStatusResolvedBg;
      default:
        return darkElevatedSurface;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPER: Get status text color based on theme
  // ═══════════════════════════════════════════════════════════════════
  static Color getStatusTextColor(String status, {required bool isDark}) {
    if (!isDark) {
      // Light mode - use colored text
      switch (status.toLowerCase()) {
        case 'pending': // New color for pending in light mode
          return lightStatusPendingTextNew;
        case 'in progress':
          return lightStatusInProgress;
        case 'resolved':
        case 'verified':
          return lightStatusPending;
        case 'in progress':
          return lightStatusInProgress;
        case 'resolved':
        case 'verified':
          return lightStatusResolved;
        default:
          return lightTextPrimary;
      }
    }

    // Dark mode - use semantic colors
    switch (status.toLowerCase()) {
      case 'pending':
        return darkStatusPendingText;
      case 'in progress':
        return darkStatusInProgressText;
      case 'resolved':
      case 'verified':
        return darkStatusResolvedText;
      default:
        return darkTextPrimary;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPER: Get severity color based on theme
  // ═══════════════════════════════════════════════════════════════════
  static Color getSeverityColor(String severity, {required bool isDark}) {
    if (!isDark) return lightSeverityHigh;
    if (!isDark) {
      switch (severity.toLowerCase()) {
        case 'high':
          return lightSeverityHighTextNew;
        default: return lightSeverityHigh;
      }
    }
    switch (severity.toLowerCase()) {
      case 'low':
        return darkSeverityLowText;
      case 'medium':
        return darkSeverityMediumText;
      case 'high':
        return darkSeverityHighText;
      default:
        return darkTextMuted;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPER: Get severity background color based on theme
  // ═══════════════════════════════════════════════════════════════════
  static Color getSeverityBgColor(String severity, {required bool isDark}) {
    if (!isDark) return Colors.transparent;
    if (!isDark) {
      switch (severity.toLowerCase()) {
        case 'high':
          return lightSeverityHighBgNew;
        default: return Colors.transparent;
      }
    }
    switch (severity.toLowerCase()) {
      case 'low':
        return darkSeverityLowBg;
      case 'medium':
        return darkSeverityMediumBg;
      case 'high':
        return darkSeverityHighBg;
      default:
        return darkElevatedSurface;
    }
  }
}
