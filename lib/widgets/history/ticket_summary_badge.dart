import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/history_service.dart';
import '../../services/dhlottery_api.dart';

/// 묶음 실물 복권 영수증 판정 결과 데이터
class TicketSummaryData {
  final int bestRank;
  final String summaryLabel;
  final Color badgeColor;

  const TicketSummaryData({
    required this.bestRank,
    required this.summaryLabel,
    required this.badgeColor,
  });

  factory TicketSummaryData.evaluate(LottoHistoryEntry entry, DHLotteryResult? result) {
    if (result == null) {
      return const TicketSummaryData(
        bestRank: -1,
        summaryLabel: '추첨 대기',
        badgeColor: Colors.grey,
      );
    }

    final games = entry.games ?? [];
    final Map<int, int> winCounts = {};
    int bestRank = 999;

    for (final g in games) {
      final matched = g.numbers.where((n) => result.numbers.contains(n)).toSet();
      final isBonus = g.numbers.contains(result.bonusNo);
      final count = matched.length;

      int rank = 0;
      if (count == 6) {
        rank = 1;
      } else if (count == 5 && isBonus) {
        rank = 2;
      } else if (count == 5) {
        rank = 3;
      } else if (count == 4) {
        rank = 4;
      } else if (count == 3) {
        rank = 5;
      }

      if (rank >= 1 && rank <= 5) {
        winCounts[rank] = (winCounts[rank] ?? 0) + 1;
        if (rank < bestRank) {
          bestRank = rank;
        }
      }
    }

    if (winCounts.isEmpty) {
      return const TicketSummaryData(
        bestRank: 0,
        summaryLabel: '낙첨',
        badgeColor: Colors.white24,
      );
    }

    String label = '';
    if (winCounts.containsKey(1)) {
      final others = winCounts.entries.where((e) => e.key != 1).fold<int>(0, (s, e) => s + e.value);
      label = others > 0
          ? '🎉 1등 당첨! 외 $others개'
          : (winCounts[1]! > 1 ? '🎉 1등 ${winCounts[1]}개 당첨!' : '🎉 1등 당첨!');
    } else if (winCounts.containsKey(2)) {
      final others = winCounts.entries.where((e) => e.key != 2).fold<int>(0, (s, e) => s + e.value);
      label = others > 0
          ? '🎉 2등 당첨! 외 $others개'
          : (winCounts[2]! > 1 ? '🎉 2등 ${winCounts[2]}개 당첨!' : '🎉 2등 당첨!');
    } else if (winCounts.containsKey(3)) {
      final others = winCounts.entries.where((e) => e.key != 3).fold<int>(0, (s, e) => s + e.value);
      label = others > 0
          ? '🎉 3등 당첨! 외 $others개'
          : (winCounts[3]! > 1 ? '🎉 3등 ${winCounts[3]}개 당첨!' : '🎉 3등 당첨!');
    } else if (winCounts.containsKey(4) && winCounts.containsKey(5)) {
      label = '🎉 4등 ${winCounts[4]}개 · 5등 ${winCounts[5]}개';
    } else if (winCounts.containsKey(4)) {
      label = '🎉 4등 ${winCounts[4]}개 당첨';
    } else if (winCounts.containsKey(5)) {
      final count = winCounts[5]!;
      label = count > 1 ? '🎉 5등 $count개 (${NumberFormat('#,###').format(count * 5000)}원)' : '🎉 5등 (5,000원)';
    }

    Color badgeColor;
    switch (bestRank) {
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

    return TicketSummaryData(
      bestRank: bestRank,
      summaryLabel: label,
      badgeColor: badgeColor,
    );
  }
}

/// 티켓 단위 종합 당첨 요약 뱃지
class LottoTicketSummaryBadge extends StatelessWidget {
  final int bestRank;
  final String summaryLabel;
  final Color badgeColor;

  const LottoTicketSummaryBadge({
    super.key,
    required this.bestRank,
    required this.summaryLabel,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;
    final isWin = bestRank >= 1 && bestRank <= 5;

    Color bg;
    Color border;
    Color text;
    IconData? icon;

    if (bestRank == -1) {
      bg = isLight
          ? const Color(0xFFEEF2FF)
          : const Color(0xFF312E81).withValues(alpha: 0.35);
      border = isLight
          ? const Color(0xFFC7D2FE)
          : const Color(0xFF6366F1).withValues(alpha: 0.45);
      text = isLight
          ? const Color(0xFF4338CA)
          : const Color(0xFFA5B4FC);
      icon = Icons.schedule_rounded;
    } else if (isWin) {
      if (isLight) {
        switch (bestRank) {
          case 1:
            bg = const Color(0xFFFFF3CD);
            border = const Color(0xFFFFC107);
            text = const Color(0xFF8C5D00);
            break;
          case 2:
            bg = const Color(0xFFEBF5FB);
            border = const Color(0xFF3498DB);
            text = const Color(0xFF1B4F72);
            break;
          case 3:
            bg = const Color(0xFFFBEEE6);
            border = const Color(0xFFE59866);
            text = const Color(0xFF78281F);
            break;
          case 4:
            bg = const Color(0xFFE8F8F5);
            border = const Color(0xFF2ECC71);
            text = const Color(0xFF145A32);
            break;
          case 5:
          default:
            bg = const Color(0xFFFEF9E7);
            border = const Color(0xFFF39C12);
            text = const Color(0xFF7D6608);
            break;
        }
      } else {
        bg = badgeColor.withValues(alpha: 0.22);
        border = badgeColor;
        text = badgeColor;
      }
      icon = Icons.emoji_events_rounded;
    } else {
      bg = isLight ? const Color(0xFFF8F9F9) : Colors.white.withValues(alpha: 0.05);
      border = isLight ? const Color(0xFFE5E7E9) : Colors.white12;
      text = isLight ? const Color(0xFF707B7C) : const Color(0xFF85929E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: border, width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11.5, color: text),
            const SizedBox(width: 3.5),
          ],
          Text(
            summaryLabel,
            style: GoogleFonts.notoSansKr(
              fontSize: 10.5,
              fontWeight: isWin ? FontWeight.bold : FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

/// 미니 게임별 당첨 뱃지
class LottoMiniRankBadge extends StatelessWidget {
  final int rank;
  final int matchedCount;
  final Color badgeColor;

  const LottoMiniRankBadge({
    super.key,
    required this.rank,
    required this.matchedCount,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;
    final isWin = rank >= 1 && rank <= 5;

    Color bg;
    Color border;
    Color text;

    if (isWin) {
      if (isLight) {
        switch (rank) {
          case 1:
            bg = const Color(0xFFFFF3CD);
            border = const Color(0xFFFFC107);
            text = const Color(0xFF8C5D00);
            break;
          case 2:
            bg = const Color(0xFFEBF5FB);
            border = const Color(0xFF3498DB);
            text = const Color(0xFF1B4F72);
            break;
          case 3:
            bg = const Color(0xFFFBEEE6);
            border = const Color(0xFFE59866);
            text = const Color(0xFF78281F);
            break;
          case 4:
            bg = const Color(0xFFE8F8F5);
            border = const Color(0xFF2ECC71);
            text = const Color(0xFF145A32);
            break;
          case 5:
          default:
            bg = const Color(0xFFFEF9E7);
            border = const Color(0xFFF39C12);
            text = const Color(0xFF7D6608);
            break;
        }
      } else {
        bg = badgeColor.withValues(alpha: 0.2);
        border = badgeColor;
        text = badgeColor;
      }
    } else {
      bg = isLight ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.05);
      border = isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white12;
      text = AppColors.textHint;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: border,
          width: 0.8,
        ),
      ),
      child: Text(
        isWin
            ? '$rank등'
            : (matchedCount > 0 ? '$matchedCount개' : '낙첨'),
        style: GoogleFonts.notoSansKr(
          fontSize: 10,
          fontWeight: isWin ? FontWeight.bold : FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
