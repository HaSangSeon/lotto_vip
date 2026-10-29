import 'package:flutter/material.dart';
import '../../utils/safe_google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/dhlottery_api.dart';
import '../../services/qr_lottery_parser.dart';
import '../lotto_ball.dart';

class GameEvaluation {
  final QRLotteryGame game;
  final int rank; // 1~5, 0 (낙첨), -1 (추첨 전)
  final String rankLabel;
  final int prizeAmount;
  final Set<int> matchedNumbers;
  final bool isBonusMatched;

  const GameEvaluation({
    required this.game,
    required this.rank,
    required this.rankLabel,
    required this.prizeAmount,
    required this.matchedNumbers,
    required this.isBonusMatched,
  });
}

/// 제 N회 공식 당첨 번호 카드
class QrOfficialDrawCard extends StatelessWidget {
  final DHLotteryResult res;
  final bool isLight;

  const QrOfficialDrawCard({
    super.key,
    required this.res,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLight
              ? AppColors.lightGoldBorder.withValues(alpha: 0.3)
              : AppColors.borderGold.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stars_rounded, color: AppColors.goldText, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '제 ${res.drwNo}회 공식 당첨 번호',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF4EFE6) : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  res.drwNoDate,
                  style: GoogleFonts.rajdhani(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...res.numbers.map(
                  (n) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: LottoBall(number: n, size: 30),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    '+',
                    style: GoogleFonts.rajdhani(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LottoBall(number: res.bonusNo, size: 30, isBonus: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A ~ E 개별 게임 결과 카드
class QrGameCard extends StatelessWidget {
  final GameEvaluation eval;
  final bool isDrawn;
  final bool isPending;
  final bool isLight;
  final int? bonusNumber;

  const QrGameCard({
    super.key,
    required this.eval,
    required this.isDrawn,
    required this.isPending,
    required this.isLight,
    this.bonusNumber,
  });

  @override
  Widget build(BuildContext context) {
    final hasWon = eval.rank >= 1 && eval.rank <= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasWon
              ? (isLight ? const Color(0xFFD4AF37) : AppColors.gold)
              : (isLight
                  ? AppColors.lightGoldBorder.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.07)),
          width: hasWon ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (hasWon)
            BoxShadow(
              color: AppColors.gold.withValues(alpha: isLight ? 0.15 : 0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 게임 라벨 (A, B, C...)
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hasWon
                      ? (isLight ? const Color(0xFFFFF0C2) : AppColors.gold.withValues(alpha: 0.2))
                      : (isLight ? const Color(0xFFECE6D8) : Colors.white.withValues(alpha: 0.08)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasWon ? AppColors.gold : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Text(
                  eval.game.label,
                  style: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: hasWon ? AppColors.goldText : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${eval.game.label} 게임',
                style: GoogleFonts.notoSansKr(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // 등수 및 일치 뱃지 (당첨금 포함)
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: QrRankBadge(eval: eval, isPending: isPending, isLight: isLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 번호 볼 행
          LottoBallRow(
            numbers: eval.game.numbers,
            ballSize: 34,
            matchedNumbers: isDrawn ? eval.matchedNumbers : null,
            bonusNumber: isDrawn ? bonusNumber : null,
          ),
        ],
      ),
    );
  }
}

/// 등수 뱃지 (1~5등, 낙첨, 추첨대기)
class QrRankBadge extends StatelessWidget {
  final GameEvaluation eval;
  final bool isPending;
  final bool isLight;

  const QrRankBadge({
    super.key,
    required this.eval,
    required this.isPending,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    if (isPending || eval.rank == -1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFEBF5FB) : const Color(0xFF3498DB).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLight ? const Color(0xFFAED6F1) : const Color(0xFF3498DB).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Text(
          '추첨 대기',
          style: GoogleFonts.notoSansKr(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isLight ? const Color(0xFF2471A3) : const Color(0xFF85C1E9),
          ),
        ),
      );
    }

    Color bg;
    Color border;
    Color text;

    switch (eval.rank) {
      case 1:
        bg = isLight ? const Color(0xFFFFF3CD) : const Color(0xFFFFD700).withValues(alpha: 0.25);
        border = isLight ? const Color(0xFFFFC107) : const Color(0xFFFFD700);
        text = isLight ? const Color(0xFF8C5D00) : const Color(0xFFFFD700);
        break;
      case 2:
        bg = isLight ? const Color(0xFFEBF5FB) : const Color(0xFF5DADE2).withValues(alpha: 0.25);
        border = isLight ? const Color(0xFF3498DB) : const Color(0xFF5DADE2);
        text = isLight ? const Color(0xFF1B4F72) : const Color(0xFFD6EAF8);
        break;
      case 3:
        bg = isLight ? const Color(0xFFFBEEE6) : const Color(0xFFE59866).withValues(alpha: 0.25);
        border = isLight ? const Color(0xFFE59866) : const Color(0xFFE59866);
        text = isLight ? const Color(0xFF78281F) : const Color(0xFFF5CBA7);
        break;
      case 4:
        bg = isLight ? const Color(0xFFE8F8F5) : const Color(0xFF2ECC71).withValues(alpha: 0.25);
        border = isLight ? const Color(0xFF2ECC71) : const Color(0xFF2ECC71);
        text = isLight ? const Color(0xFF145A32) : const Color(0xFFA9DFBF);
        break;
      case 5:
        bg = isLight ? const Color(0xFFFEF9E7) : const Color(0xFFF39C12).withValues(alpha: 0.25);
        border = isLight ? const Color(0xFFF39C12) : const Color(0xFFF39C12);
        text = isLight ? const Color(0xFF7D6608) : const Color(0xFFFAD7A0);
        break;
      default:
        bg = isLight ? const Color(0xFFF0EBE1) : Colors.white.withValues(alpha: 0.06);
        border = Colors.transparent;
        text = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        eval.rankLabel,
        style: GoogleFonts.notoSansKr(
          fontSize: 11,
          fontWeight: eval.rank > 0 ? FontWeight.w800 : FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
