import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/history_service.dart';
import '../common_widgets.dart';
import '../lotto_ball.dart';
import 'history_badges.dart';

/// 보관함 단일 복권 번호 카드 위젯 (프리미엄 VIP 디자인)
class HistoryCard extends StatelessWidget {
  final LottoHistoryEntry entry;
  final int rank;
  final String rankLabel;
  final Set<int> matchedNumbers;
  final int? bonusNumber;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  const HistoryCard({
    super.key,
    required this.entry,
    required this.rank,
    required this.rankLabel,
    required this.matchedNumbers,
    this.bonusNumber,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;
    final isFavorite = entry.isFavorite;

    // 게임 라벨 추출 (A~G)
    String gameLabel = '';
    if (entry.entryType == LottoEntryType.qrScan) {
      final match = RegExp(r'([A-G])게임').firstMatch(entry.title);
      if (match != null) {
        gameLabel = '${match.group(1)}게임';
      }
    }

    final timeStr =
        '${entry.createdAt.month}/${entry.createdAt.day} ${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      borderRadius: 22,
      borderColor: isFavorite
          ? (isLight
              ? AppColors.goldDark.withValues(alpha: 0.45)
              : AppColors.gold.withValues(alpha: 0.35))
          : (rank >= 1 && rank <= 3
              ? AppColors.gold.withValues(alpha: 0.5)
              : null),
      shadows: [
        if (isFavorite)
          BoxShadow(
            color: isLight
                ? AppColors.goldDark.withValues(alpha: 0.08)
                : AppColors.gold.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        BoxShadow(
          color: isLight
              ? Colors.black.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌟 1. 카드 상단 헤더: [유형 뱃지] [회차] ──── [추첨 대기 뱃지] [❤️] [🗑️]
          Row(
            children: [
              // 좌측: 유형 + 회차
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LottoTypeBadge(type: entry.entryType),
                  const SizedBox(width: 6),
                  LottoDrawBadge(drawNo: entry.drawNo, gameLabel: gameLabel),
                ],
              ),

              const Spacer(),

              // 우측: 당첨/추첨대기 뱃지 + 원형 액션 버튼 (말줄임 없이 온전한 크기 유지)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LottoRankBadgeWidget(
                    rank: rank,
                    label: rankLabel,
                    matchedNumbers: matchedNumbers,
                  ),
                  const SizedBox(width: 8),

                  // 즐겨찾기 원형 소프트 버튼
                  HistoryActionButton(
                    icon: isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    iconColor: isFavorite
                        ? (isLight ? const Color(0xFFE53935) : const Color(0xFFFF5252))
                        : AppColors.textHint,
                    bgColor: isFavorite
                        ? (isLight
                            ? const Color(0xFFFFECEB)
                            : const Color(0xFFE53935).withValues(alpha: 0.18))
                        : null,
                    borderColor: isFavorite
                        ? (isLight
                            ? const Color(0xFFFF8A80).withValues(alpha: 0.6)
                            : const Color(0xFFFF5252).withValues(alpha: 0.4))
                        : null,
                    onTap: onToggleFavorite,
                  ),
                  const SizedBox(width: 6),

                  // 개별 삭제 원형 소프트 버튼
                  HistoryActionButton(
                    icon: Icons.delete_outline_rounded,
                    iconColor: AppColors.textHint,
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 🌟 2. 프리미엄 넘버 트레이 (보석함처럼 6개 볼을 정돈하는 전용 라운드 컨테이너)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: isLight
                  ? const Color(0xFFF5EFE6).withValues(alpha: 0.85)
                  : const Color(0xFF0C0E17).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight
                    ? const Color(0xFFE5D9C8).withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.08),
                width: 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: isLight
                      ? Colors.black.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LottoBallRow(
              numbers: entry.numbers,
              ballSize: 38,
              matchedNumbers: matchedNumbers.isNotEmpty ? matchedNumbers : null,
              bonusNumber: bonusNumber,
            ),
          ),

          const SizedBox(height: 11),

          // 🌟 3. 하단 메타 정보 (좌측: 마이크로 분석 칩, 우측: 생성 일시)
          Builder(
            builder: (context) {
              final sum = entry.numbers.reduce((a, b) => a + b);
              final oddCount = entry.numbers.where((n) => n % 2 != 0).length;
              final evenCount = 6 - oddCount;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 번호 분석 마이크로 칩 그룹
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 총합 칩
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: isLight
                              ? Colors.black.withValues(alpha: 0.035)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: isLight
                                ? const Color(0xFFE8DFD0)
                                : Colors.white.withValues(alpha: 0.07),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '∑',
                              style: GoogleFonts.rajdhani(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldText,
                              ),
                            ),
                            const SizedBox(width: 3.5),
                            Text(
                              '총합 $sum',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5.5),

                      // 홀짝 칩
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: isLight
                              ? Colors.black.withValues(alpha: 0.035)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: isLight
                                ? const Color(0xFFE8DFD0)
                                : Colors.white.withValues(alpha: 0.07),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '홀$oddCount · 짝$evenCount',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 등록 일시
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 11.5,
                        color: AppColors.textHint.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        timeStr,
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.textHint,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
