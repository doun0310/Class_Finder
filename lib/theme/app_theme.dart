import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color ink = Color(0xFF111827);
  static const Color blue = Color(0xFF1D4ED8);
  static const Color cyan = Color(0xFF0891B2);
  static const Color coral = Color(0xFFF97316);
  static const Color leaf = Color(0xFF16A34A);
  static const Color cloud = Color(0xFFF4F7FB);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color slate = Color(0xFF64748B);
  static const Color border = Color(0xFFD9E2EC);

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: blue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDCE6FF),
      onPrimaryContainer: Color(0xFF0E255E),
      secondary: cyan,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD8F4F8),
      onSecondaryContainer: Color(0xFF0C3440),
      tertiary: coral,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFFE2D1),
      onTertiaryContainer: Color(0xFF5A2100),
      error: Color(0xFFDC2626),
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF6F1D1B),
      surface: paper,
      onSurface: ink,
      onSurfaceVariant: slate,
      outline: Color(0xFF98A2B3),
      outlineVariant: border,
      shadow: Color(0x140F172A),
      scrim: Color(0x520F172A),
      inverseSurface: Color(0xFF1F2937),
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFF93C5FD),
      surfaceContainerHighest: Color(0xFFE7EEF5),
      surfaceContainerHigh: Color(0xFFEEF3F8),
      surfaceContainer: Color(0xFFF4F7FB),
      surfaceContainerLow: Color(0xFFF8FAFC),
      surfaceContainerLowest: Colors.white,
    );

    return _buildTheme(scheme);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF8FB3FF),
      onPrimary: Color(0xFF07235B),
      primaryContainer: Color(0xFF12368E),
      onPrimaryContainer: Color(0xFFDCE6FF),
      secondary: Color(0xFF7EE1F1),
      onSecondary: Color(0xFF003742),
      secondaryContainer: Color(0xFF0B596A),
      onSecondaryContainer: Color(0xFFD8F4F8),
      tertiary: Color(0xFFFFB486),
      onTertiary: Color(0xFF582200),
      tertiaryContainer: Color(0xFF8C3A00),
      onTertiaryContainer: Color(0xFFFFE2D1),
      error: Color(0xFFFCA5A5),
      onError: Color(0xFF601410),
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFEE2E2),
      surface: Color(0xFF0B1220),
      onSurface: Color(0xFFF8FAFC),
      onSurfaceVariant: Color(0xFF94A3B8),
      outline: Color(0xFF64748B),
      outlineVariant: Color(0xFF1E293B),
      shadow: Color(0x52000000),
      scrim: Color(0x99000000),
      inverseSurface: Color(0xFFF8FAFC),
      onInverseSurface: Color(0xFF0F172A),
      inversePrimary: blue,
      surfaceContainerHighest: Color(0xFF172234),
      surfaceContainerHigh: Color(0xFF121B2B),
      surfaceContainer: Color(0xFF0F1727),
      surfaceContainerLow: Color(0xFF0D1523),
      surfaceContainerLowest: Color(0xFF0A111D),
    );

    return _buildTheme(scheme);
  }

  static ThemeData _buildTheme(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.brightness == Brightness.light
          ? cloud
          : scheme.surface,
    );
    final textTheme = _textTheme(base.textTheme, scheme);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.brightness == Brightness.light
          ? cloud
          : scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: scheme.outlineVariant),
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        backgroundColor: scheme.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: textTheme.labelLarge ?? const TextStyle(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface.withValues(alpha: 0.96),
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium!.copyWith(
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: scheme.onPrimaryContainer,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        indicator: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(scheme.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        hintStyle: WidgetStatePropertyAll(
          textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primary.withValues(alpha: 0.15),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    final body = GoogleFonts.plusJakartaSansTextTheme(base);
    final headline = GoogleFonts.spaceGroteskTextTheme(body);

    return body.copyWith(
      displayLarge: headline.displayLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: headline.displayMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: headline.displaySmall?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: headline.headlineLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: headline.headlineMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: headline.headlineSmall?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: headline.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: headline.titleMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: headline.titleSmall?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        color: scheme.onSurface,
        height: 1.35,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        color: scheme.onSurface,
        height: 1.35,
      ),
      bodySmall: body.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
        height: 1.35,
      ),
      labelLarge: body.labelLarge?.copyWith(color: scheme.onSurface),
      labelMedium: body.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      labelSmall: body.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}
