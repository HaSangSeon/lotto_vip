import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// 맞춤 필터 번호 선택 그리드 셀 위젯 (기본 / 고정수 / 제외수)
class FilterNumberCell extends StatelessWidget {
  final int number;
  final bool isIncluded;
  final bool isExcluded;
  final bool isLight;
  final VoidCallback onTap;

  const FilterNumberCell({
    super.key,
    required this.number,
    required this.isIncluded,
    required this.isExcluded,
    required this.isLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    List<Color>? gradColors;
    Color borderColor;
    Color textColor;

    if (isIncluded) {
      gradColors = const [Color(0xFF1E88E5), Color(0xFF0D47A1)];
      borderColor = const Color(0xFF64B5F6);
      textColor = Colors.white;
    } else if (isExcluded) {
      gradColors = const [Color(0xFFE53935), Color(0xFFB71C1C)];
      borderColor = const Color(0xFFEF9A9A);
      textColor = Colors.white;
    } else {
      bgColor = isLight ? Colors.white : AppColors.surface;
      borderColor = isLight
          ? AppColors.lightGoldBorder.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.1);
      textColor = AppColors.textSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradColors != null
              ? LinearGradient(
                  colors: gradColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: gradColors == null ? bgColor : null,
          border: Border.all(
            color: borderColor,
            width: isIncluded || isExcluded ? 1.8 : 1.0,
          ),
          boxShadow: (isIncluded || isExcluded)
              ? [
                  BoxShadow(
                    color: (isIncluded
                            ? const Color(0xFF1E88E5)
                            : const Color(0xFFE53935))
                        .withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.05 : 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Text(
              number.toString(),
              style: GoogleFonts.rajdhani(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
