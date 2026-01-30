import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tema aplikace SpiderBagzz
/// Design podle loga - nocni atmosfera, cervena, cyan neon
class AppTheme {
  AppTheme._();

  /// Tmave tema (vychozi) - SpiderBagzz Night Theme
  static ThemeData get darkTheme {
    // Bangers font pro titulky - komiksovy styl jako v logu
    final headlineTextTheme = GoogleFonts.bangersTextTheme(
      ThemeData.dark().textTheme,
    );

    // Rajdhani pro body text - moderni a citelny
    final bodyTextTheme = GoogleFonts.rajdhaniTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.functionalBg,
      fontFamily: GoogleFonts.rajdhani().fontFamily,
      fontFamilyFallback: const [
        'Roboto', // Fallback s plnou Czech support
        'Arial',
        'sans-serif',
      ],
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textPrimary,
        tertiary: AppColors.accent,           // Neonove cyan
        onTertiary: AppColors.background,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.bangers(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.accent.withAlpha(20),  // Cyan border
            width: 1,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.functionalBg,
        indicatorColor: AppColors.accent.withAlpha(30),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.rajdhani(
              color: AppColors.accent,  // Cyan kdyz vybrano
              fontSize: 12,
              fontWeight: FontWeight.w700,
            );
          }
          return GoogleFonts.rajdhani(
            color: AppColors.functionalMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accent, size: 26);
          }
          return const IconThemeData(color: AppColors.functionalMuted, size: 24);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.functionalSurface,
        hintStyle: GoogleFonts.rajdhani(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.rajdhani(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.secondary.withAlpha(40),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.rajdhani(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.rajdhani(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,  // Cyan
          textStyle: GoogleFonts.rajdhani(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.accent.withAlpha(60)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.rajdhani(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.accent.withAlpha(20),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: GoogleFonts.rajdhani(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.accent.withAlpha(30)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.accent.withAlpha(30)),
        ),
        titleTextStyle: GoogleFonts.bangers(
          color: AppColors.textPrimary,
          fontSize: 24,
          letterSpacing: 1.5,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: AppColors.accent.withAlpha(20)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.accent.withAlpha(20)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary.withAlpha(40),
        labelStyle: GoogleFonts.rajdhani(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: AppColors.accent.withAlpha(30)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.accent,  // Cyan
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.accent,
        labelStyle: GoogleFonts.rajdhani(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.rajdhani(
          fontWeight: FontWeight.w500,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.surfaceLight,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.surfaceLight,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accent.withAlpha(30),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent.withAlpha(60);
          }
          return AppColors.surfaceLight;
        }),
      ),
      textTheme: TextTheme(
        // Headlines - Bangers (komiksovy styl z loga)
        displayLarge: headlineTextTheme.displayLarge?.copyWith(
          color: AppColors.textPrimary,
          letterSpacing: 3,
        ),
        displayMedium: headlineTextTheme.displayMedium?.copyWith(
          color: AppColors.textPrimary,
          letterSpacing: 2.5,
        ),
        displaySmall: headlineTextTheme.displaySmall?.copyWith(
          color: AppColors.textPrimary,
          letterSpacing: 2,
        ),
        headlineLarge: headlineTextTheme.headlineLarge?.copyWith(
          color: AppColors.textPrimary,
          letterSpacing: 2,
        ),
        headlineMedium: headlineTextTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
          letterSpacing: 1.5,
        ),
        headlineSmall: headlineTextTheme.headlineSmall?.copyWith(
          color: AppColors.textPrimary,
          letterSpacing: 1,
        ),
        // Titles - Rajdhani bold
        titleLarge: bodyTextTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: bodyTextTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: bodyTextTheme.titleSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        // Body - Rajdhani regular
        bodyLarge: bodyTextTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: bodyTextTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: bodyTextTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
        // Labels
        labelLarge: bodyTextTheme.labelLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: bodyTextTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: bodyTextTheme.labelSmall?.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Svetle tema - plna implementace
  static ThemeData get lightTheme {
    // Light theme colors
    const backgroundLight = Color(0xFFF8F9FA);
    const surfaceLight = Color(0xFFFFFFFF);
    const surfaceLightElevated = Color(0xFFF0F2F5);
    const textPrimaryLight = Color(0xFF1A1A2E);
    const textSecondaryLight = Color(0xFF4A4A5A);
    const textMutedLight = Color(0xFF8A8A9A);

    final headlineTextTheme = GoogleFonts.bangersTextTheme(
      ThemeData.light().textTheme,
    );

    final bodyTextTheme = GoogleFonts.rajdhaniTextTheme(
      ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: GoogleFonts.rajdhani().fontFamily,
      fontFamilyFallback: const [
        'Roboto', // Fallback s plnou Czech support
        'Arial',
        'sans-serif',
      ],
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        tertiary: AppColors.secondaryDark,
        onTertiary: Colors.white,
        surface: surfaceLight,
        onSurface: textPrimaryLight,
        error: AppColors.error,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: surfaceLight,
        foregroundColor: textPrimaryLight,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.bangers(
          color: textPrimaryLight,
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: 2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: surfaceLight,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceLight,
        indicatorColor: AppColors.primary.withAlpha(30),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.rajdhani(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            );
          }
          return GoogleFonts.rajdhani(
            color: textMutedLight,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 26);
          }
          return IconThemeData(color: textMutedLight, size: 24);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLightElevated,
        hintStyle: GoogleFonts.rajdhani(
          color: textMutedLight,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.rajdhani(
          color: textSecondaryLight,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.rajdhani(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.rajdhani(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSecondaryLight,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimaryLight,
        contentTextStyle: GoogleFonts.rajdhani(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.bangers(
          color: textPrimaryLight,
          fontSize: 24,
          letterSpacing: 1.5,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLightElevated,
        selectedColor: AppColors.primary.withAlpha(30),
        labelStyle: GoogleFonts.rajdhani(
          color: textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: textMutedLight,
        indicatorColor: AppColors.primary,
        labelStyle: GoogleFonts.rajdhani(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.rajdhani(
          fontWeight: FontWeight.w500,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Color(0xFFE0E0E0),
      ),
      textTheme: TextTheme(
        displayLarge: headlineTextTheme.displayLarge?.copyWith(
          color: textPrimaryLight,
          letterSpacing: 3,
        ),
        displayMedium: headlineTextTheme.displayMedium?.copyWith(
          color: textPrimaryLight,
          letterSpacing: 2.5,
        ),
        displaySmall: headlineTextTheme.displaySmall?.copyWith(
          color: textPrimaryLight,
          letterSpacing: 2,
        ),
        headlineLarge: headlineTextTheme.headlineLarge?.copyWith(
          color: textPrimaryLight,
          letterSpacing: 2,
        ),
        headlineMedium: headlineTextTheme.headlineMedium?.copyWith(
          color: textPrimaryLight,
          letterSpacing: 1.5,
        ),
        headlineSmall: headlineTextTheme.headlineSmall?.copyWith(
          color: textPrimaryLight,
          letterSpacing: 1,
        ),
        titleLarge: bodyTextTheme.titleLarge?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: bodyTextTheme.titleMedium?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: bodyTextTheme.titleSmall?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: bodyTextTheme.bodyLarge?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: bodyTextTheme.bodyMedium?.copyWith(
          color: textSecondaryLight,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: bodyTextTheme.bodySmall?.copyWith(
          color: textMutedLight,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: bodyTextTheme.labelLarge?.copyWith(
          color: textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: bodyTextTheme.labelMedium?.copyWith(
          color: textSecondaryLight,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: bodyTextTheme.labelSmall?.copyWith(
          color: textMutedLight,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
