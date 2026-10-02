import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.sage,
        primary: AppColors.sageDark,
        surface: AppColors.cream,
        secondary: AppColors.terracotta,
        onSurface: AppColors.ink,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.ink),
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.sand,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          side: BorderSide(
            color: AppColors.sageDark.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sageDark,
          foregroundColor: AppColors.cream,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sageDark,
          side: BorderSide(
            color: AppColors.sageDark.withValues(alpha: 0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.terracotta,
        foregroundColor: AppColors.cream,
        elevation: 2,
        shape: CircleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.sand,
        indicatorColor: AppColors.sageDark.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.sageDark,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: AppColors.ink.withValues(alpha: 0.6),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.sageDark);
          }
          return IconThemeData(color: AppColors.ink.withValues(alpha: 0.6));
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.sand,
        labelStyle: TextStyle(color: AppColors.ink.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: AppColors.ink.withValues(alpha: 0.5)),
        prefixStyle: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
        suffixIconColor: AppColors.sageDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.sageDark.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.sageDark.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.sageDark,
            width: 1.5,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.sageDark;
            }
            return AppColors.sand;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.cream;
            }
            return AppColors.ink;
          }),
          textStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.cream);
            }
            return const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink);
          }),
          side: WidgetStateProperty.all(
            BorderSide(
              color: AppColors.sageDark.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.cream,
        headerBackgroundColor: AppColors.sageDark,
        headerForegroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        weekdayStyle: const TextStyle(color: AppColors.sageDark, fontWeight: FontWeight.bold),
        yearStyle: const TextStyle(color: AppColors.ink),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.cream;
          }
          return AppColors.ink;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.sageDark;
          }
          return null;
        }),
        todayBorder: const BorderSide(color: AppColors.sageDark),
        todayForegroundColor: WidgetStateProperty.all(AppColors.sageDark),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.sageDark,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        confirmButtonStyle: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sageDark,
          foregroundColor: AppColors.cream,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.sageDark,
        contentTextStyle: const TextStyle(color: AppColors.cream),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkPrimary,
        brightness: Brightness.dark,
        surface: AppColors.darkBackground,
        primary: AppColors.darkPrimary,
        secondary: AppColors.terracotta,
        onSurface: AppColors.darkText,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
