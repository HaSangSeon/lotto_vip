import 'package:flutter/material.dart';
import '../utils/safe_google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isLight = prefs.getBool('isLightMode') ?? false;
    themeModeNotifier.value = isLight ? ThemeMode.light : ThemeMode.dark;
  }

  static Future<void> toggleTheme() async {
    final newMode = themeModeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    themeModeNotifier.value = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLightMode', newMode == ThemeMode.light);
  }
}

class AppColors {
  static bool get isLight => AppTheme.themeModeNotifier.value == ThemeMode.light;

  // Light mode surfaces (크림/아이보리 고급 팔레트)
  static Color get black => isLight ? const Color(0xFFF6F1E9) : const Color(0xFF0B0D14);
  static Color get surface => isLight ? const Color(0xFFFFFEFA) : const Color(0xFF141722);
  static Color get card => isLight ? const Color(0xFFFFFEFA) : const Color(0xFF181B28);
  static Color get cardHover => isLight ? const Color(0xFFFAF6EE) : const Color(0xFF202436);

  // Gold
  static const gold = Color(0xFFFFD700);
  static const goldLight = Color(0xFFFFF0A0);
  static const goldDark = Color(0xFFB8860B);
  static const goldDeep = Color(0xFF855A00); // 라이트모드 고대비 딥골드
  static const goldGlow = Color(0x33FFD700);

  /// 라이트 모드에서는 짙은 딥골드, 다크 모드에서는 밝은 골드를 반환하는 텍스트/아이콘 전용 컬러
  static Color get goldText => isLight ? goldDeep : gold;
  static Color get goldAccent => isLight ? goldDark : gold;

  // Accent
  static const purple = Color(0xFF6C3FC5);
  static const purpleLight = Color(0xFF9B6EFA);
  static const blue = Color(0xFF1E90FF);

  // Text
  static Color get textPrimary => isLight ? const Color(0xFF1C1410) : const Color(0xFFF2F4FF);
  static Color get textSecondary => isLight ? const Color(0xFF6B5D50) : const Color(0xFF9498B5);
  static Color get textHint => isLight ? const Color(0xFFAA9E92) : const Color(0xFF4C506B);

  // Borders
  static Color get borderGold =>
      isLight ? const Color(0xFFD4A017).withValues(alpha: 0.5) : const Color(0x66FFD700);
  static Color get borderSubtle =>
      isLight ? const Color(0xFFD4B896).withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.1);

  // Light-mode exclusive decorative colors
  static const lightBg1 = Color(0xFFF6F1E9);
  static const lightBg2 = Color(0xFFF0E8D8);
  static const lightAccentAmber = Color(0xFFFFF3D0);
  static const lightAccentRose = Color(0xFFFFF0EC);
  static const lightGoldBorder = Color(0xFFD4A017);

  // Ball colors by range
  static const ballYellow = Color(0xFFFBC02D);
  static const ballBlue = Color(0xFF1565C0);
  static const ballRed = Color(0xFFC62828);
  static const ballGray = Color(0xFF546E7A);
  static const ballGreen = Color(0xFF2E7D32);
}

class AppThemes {
  static ThemeData get dark {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData get light {
    return _buildTheme(Brightness.light);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final baseTextTheme = isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: isLight ? AppColors.lightBg1 : const Color(0xFF0A0A0F),
      primaryColor: AppColors.gold,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        brightness: brightness,
        primary: AppColors.gold,
        secondary: isLight ? AppColors.goldDark : AppColors.goldDark,
        surface: isLight ? AppColors.surface : const Color(0xFF12121A),
      ),
      textTheme: GoogleFonts.notoSansKrTextTheme(baseTextTheme).apply(
        fontFamilyFallback: const ['Apple SD Gothic Neo', 'Malgun Gothic', 'sans-serif'],
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isLight ? AppColors.goldDeep : const Color(0xFFF0F0FF),
        ),
        titleTextStyle: GoogleFonts.rajdhani(
          color: isLight ? AppColors.goldDeep : AppColors.gold,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLight ? AppColors.goldDark : AppColors.gold,
          foregroundColor: isLight ? Colors.white : Colors.black,
          textStyle: GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: isLight ? 3 : 0,
          shadowColor: isLight ? AppColors.goldDark.withValues(alpha: 0.4) : Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isLight ? AppColors.goldDeep : AppColors.textPrimary,
          side: BorderSide(
            color: isLight ? AppColors.goldDark.withValues(alpha: 0.5) : AppColors.borderGold,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? const Color(0xFFFFF9EE) : const Color(0xFF12121A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isLight ? AppColors.lightGoldBorder.withValues(alpha: 0.25) : const Color(0x1AFFFFFF),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isLight ? AppColors.lightGoldBorder.withValues(alpha: 0.25) : const Color(0x1AFFFFFF),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isLight ? AppColors.goldDark : AppColors.gold,
            width: 1.5,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? AppColors.lightAccentAmber.withValues(alpha: 0.5) : Colors.transparent,
        selectedColor: isLight ? AppColors.goldDark.withValues(alpha: 0.2) : AppColors.gold.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.notoSansKr(fontSize: 12),
        side: BorderSide(color: isLight ? AppColors.lightGoldBorder.withValues(alpha: 0.3) : AppColors.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isLight ? AppColors.surface : const Color(0xFF141722),
        selectedItemColor: isLight ? AppColors.goldDark : AppColors.gold,
        unselectedItemColor: isLight ? AppColors.textHint : const Color(0xFF4C506B),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: isLight ? AppColors.lightGoldBorder.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.08),
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? AppColors.surface : const Color(0xFF1A1D2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: isLight ? 12 : 24,
        shadowColor: isLight ? AppColors.goldDark.withValues(alpha: 0.15) : Colors.black,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? const Color(0xFF3D2B1F) : AppColors.card,
        contentTextStyle: GoogleFonts.notoSansKr(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
