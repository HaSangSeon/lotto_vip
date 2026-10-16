import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// 맞춤 필터 고정수/제외수 상태 카운터 배지 위젯
class FilterCounterBadge extends StatelessWidget {
  final String label;
  final String? subLabel;
  final int count;
  final int maxCount;
  final Color primaryColor;
  final Color glowColor;
  final IconData icon;
  final bool isLight;

  const FilterCounterBadge({
    super.key,
    required this.label,
    this.subLabel,
    required this.count,
    required this.maxCount,
    required this.primaryColor,
    required this.glowColor,
    required this.icon,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = count >= maxCount;
    final displayColor = isFull ? glowColor : primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isLight
            ? displayColor.withValues(alpha: 0.07)
            : displayColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: displayColor.withValues(alpha: count > 0 ? 0.45 : 0.2),
          width: count > 0 ? 1.3 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: displayColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: count > 0 ? displayColor : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (subLabel != null)
                  Text(
                    subLabel!,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHint,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // 카운트 칩
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: count > 0
                  ? displayColor
                  : (isLight
                      ? Colors.black.withValues(alpha: 0.07)
                      : Colors.white.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '$count / $maxCount',
              style: GoogleFonts.rajdhani(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: count > 0 ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
