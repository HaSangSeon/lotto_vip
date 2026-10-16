import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// 보관함 상단 이번 주 추첨 예정 및 대기 현황 안내 카드 위젯
class UpcomingDrawHeader extends StatelessWidget {
  final int upcomingDrawNo;
  final DateTime drawDate;
  final int waitingGameCount;

  const UpcomingDrawHeader({
    super.key,
    required this.upcomingDrawNo,
    required this.drawDate,
    required this.waitingGameCount,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;

    // D-Day 계산
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(drawDate.year, drawDate.month, drawDate.day);
    final daysLeft = targetDay.difference(today).inDays;
    final String dDayText = daysLeft <= 0 ? 'D-Day' : 'D-$daysLeft';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight
              ? AppColors.lightGoldBorder.withValues(alpha: 0.6)
              : AppColors.borderGold.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? AppColors.goldDark.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 왼쪽: 이번 주 추첨 회차 안내 & 상세 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFFFFF0C2)
                            : AppColors.gold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLight
                              ? const Color(0xFFD4AF37)
                              : AppColors.gold.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, color: AppColors.goldText, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '이번 주 제 $upcomingDrawNo회',
                            style: GoogleFonts.notoSansKr(
                              color: AppColors.goldText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '${drawDate.month}월 ${drawDate.day}일 (토) 20:45 발표 예정',
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '추첨 완료 시 보관된 번호와 자동 대조됩니다',
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 오른쪽: D-Day & 보관 게임 수 위젯
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLight
                    ? [const Color(0xFFFFF7DB), const Color(0xFFFEEBB4)]
                    : [
                        AppColors.gold.withValues(alpha: 0.18),
                        AppColors.goldDark.withValues(alpha: 0.12)
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLight
                    ? const Color(0xFFE2B747)
                    : AppColors.gold.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  dDayText,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.goldText,
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: waitingGameCount > 0
                        ? (isLight
                            ? const Color(0xFFE8F8F5)
                            : const Color(0xFF2ECC71).withValues(alpha: 0.2))
                        : (isLight
                            ? Colors.black.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    waitingGameCount > 0 ? '$waitingGameCount게임 대기' : '미보관',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: waitingGameCount > 0
                          ? (isLight ? const Color(0xFF145A32) : const Color(0xFFA9DFBF))
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
