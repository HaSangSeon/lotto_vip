import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/history_service.dart';
import '../../services/dhlottery_api.dart';
import '../common_widgets.dart';
import '../lotto_ball.dart';
import 'history_badges.dart';
import 'ticket_summary_badge.dart';

/// 묶음 실물 복권 영수증 카드 위젯
class TicketHistoryCard extends StatefulWidget {
  final LottoHistoryEntry entry;
  final DHLotteryResult? targetResult;
  final bool isInitiallyCollapsed;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  const TicketHistoryCard({
    super.key,
    required this.entry,
    this.targetResult,
    this.isInitiallyCollapsed = false,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  @override
  State<TicketHistoryCard> createState() => _TicketHistoryCardState();
}

class _TicketHistoryCardState extends State<TicketHistoryCard> {
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isInitiallyCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;
    final entry = widget.entry;
    final games = entry.games ?? [];
    final targetResult = widget.targetResult;
    final summary = TicketSummaryData.evaluate(entry, targetResult);

    final timeStr =
        '${entry.createdAt.month}/${entry.createdAt.day} ${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      borderRadius: 22,
      borderColor: entry.isFavorite
          ? (isLight
              ? AppColors.goldDark.withValues(alpha: 0.45)
              : AppColors.gold.withValues(alpha: 0.35))
          : (summary.bestRank >= 1 && summary.bestRank <= 3
              ? AppColors.gold.withValues(alpha: 0.5)
              : null),
      shadows: [
        if (entry.isFavorite)
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
          // 🌟 1. 헤더 행: [🎫 실물 복권] [제1158회 • 5게임] ──── [당첨 요약 뱃지] [❤️] [🗑️]
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LottoTypeBadge(type: LottoEntryType.qrScan),
                  const SizedBox(width: 6),
                  LottoDrawBadge(drawNo: entry.drawNo, gameCount: entry.gameCount),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LottoTicketSummaryBadge(
                    bestRank: summary.bestRank,
                    summaryLabel: summary.summaryLabel,
                    badgeColor: summary.badgeColor,
                  ),
                  const SizedBox(width: 8),

                  // 즐겨찾기 버튼
                  HistoryActionButton(
                    icon: entry.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    iconColor: entry.isFavorite
                        ? (isLight ? const Color(0xFFE53935) : const Color(0xFFFF5252))
                        : AppColors.textHint,
                    bgColor: entry.isFavorite
                        ? (isLight
                            ? const Color(0xFFFFECEB)
                            : const Color(0xFFE53935).withValues(alpha: 0.18))
                        : null,
                    borderColor: entry.isFavorite
                        ? (isLight
                            ? const Color(0xFFFF8A80).withValues(alpha: 0.6)
                            : const Color(0xFFFF5252).withValues(alpha: 0.4))
                        : null,
                    onTap: widget.onToggleFavorite,
                  ),
                  const SizedBox(width: 6),

                  // 개별 삭제 버튼
                  HistoryActionButton(
                    icon: Icons.delete_outline_rounded,
                    iconColor: AppColors.textHint,
                    onTap: widget.onDelete,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 🌟 2. 영수증 본문 트레이
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            child: Column(
              children: [
                if (_isCollapsed) ...[
                  // 접힌 상태: 첫 번째 게임 한 줄
                  InkWell(
                    onTap: () => setState(() => _isCollapsed = false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLight ? Colors.grey.shade300 : Colors.white12,
                            ),
                            child: Text(
                              games.isNotEmpty ? games.first.label : 'A',
                              style: GoogleFonts.rajdhani(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LottoBallRow(
                              numbers: games.isNotEmpty ? games.first.numbers : entry.numbers,
                              ballSize: 30,
                              matchedNumbers: targetResult != null
                                  ? games.first.numbers.where((n) => targetResult.numbers.contains(n)).toSet()
                                  : null,
                              bonusNumber: targetResult?.bonusNo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // 펼쳐진 상태: 전체 게임 출력
                  ...games.map((game) {
                    final matched = targetResult != null
                        ? game.numbers.where((n) => targetResult.numbers.contains(n)).toSet()
                        : <int>{};
                    final isBonus = targetResult != null && game.numbers.contains(targetResult.bonusNo);
                    final matchCount = matched.length;

                    int rank = 0;
                    if (targetResult != null) {
                      if (matchCount == 6) {
                        rank = 1;
                      } else if (matchCount == 5 && isBonus) {
                        rank = 2;
                      } else if (matchCount == 5) {
                        rank = 3;
                      } else if (matchCount == 4) {
                        rank = 4;
                      } else if (matchCount == 3) {
                        rank = 5;
                      }
                    }

                    Color badgeColor;
                    switch (rank) {
                      case 1:
                        badgeColor = const Color(0xFFFFD700);
                        break;
                      case 2:
                        badgeColor = const Color(0xFF5DADE2);
                        break;
                      case 3:
                        badgeColor = const Color(0xFFE59866);
                        break;
                      case 4:
                        badgeColor = const Color(0xFF2ECC71);
                        break;
                      case 5:
                        badgeColor = const Color(0xFFF39C12);
                        break;
                      default:
                        badgeColor = Colors.white24;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLight ? const Color(0xFFFFF0C2) : AppColors.gold.withValues(alpha: 0.18),
                              border: Border.all(
                                color: isLight ? const Color(0xFFD4AF37) : AppColors.gold.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              game.label,
                              style: GoogleFonts.rajdhani(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.goldText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LottoBallRow(
                              numbers: game.numbers,
                              ballSize: 30,
                              matchedNumbers: targetResult != null ? matched : null,
                              bonusNumber: targetResult?.bonusNo,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (targetResult != null)
                            LottoMiniRankBadge(
                              rank: rank,
                              matchedCount: matchCount,
                              badgeColor: badgeColor,
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 🌟 3. 하단 접기/펼치기 토글 & 등록 일시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.black.withValues(alpha: 0.04)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isCollapsed
                            ? '전체 ${entry.gameCount}게임 보기'
                            : '영수증 접기',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldText,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _isCollapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                        size: 15,
                        color: AppColors.goldText,
                      ),
                    ],
                  ),
                ),
              ),
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
          ),
        ],
      ),
    );
  }
}
