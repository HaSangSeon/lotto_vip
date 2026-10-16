import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/history_service.dart';

/// 상단 우측 원형 마이크로 액션 버튼 (즐겨찾기, 삭제 등)
class HistoryActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final Color? bgColor;
  final Color? borderColor;
  final double size;
  final double iconSize;

  const HistoryActionButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.bgColor,
    this.borderColor,
    this.size = 32,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor ??
                (isLight
                    ? Colors.black.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.07)),
            border: Border.all(
              color: borderColor ??
                  (isLight
                      ? const Color(0xFFE5DCD0)
                      : Colors.white.withValues(alpha: 0.1)),
              width: 0.9,
            ),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

/// 회차 및 게임 라벨 뱃지 (모던 캡슐)
class LottoDrawBadge extends StatelessWidget {
  final int drawNo;
  final String? gameLabel;
  final int? gameCount;

  const LottoDrawBadge({
    super.key,
    required this.drawNo,
    this.gameLabel,
    this.gameCount,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;
    final label = gameLabel;
    final text = gameCount != null
        ? '$drawNo회차 • $gameCount게임'
        : (label != null && label.isNotEmpty
            ? '$drawNo회차 • $label'
            : '$drawNo회차');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.black.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE2D8C8)
              : Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.notoSansKr(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// 번호 유형별 고유 컬러 뱃지 (실물복권, 꿈해몽, 생년월일, 맞춤필터)
class LottoTypeBadge extends StatelessWidget {
  final LottoEntryType type;

  const LottoTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;

    Color bg;
    Color border;
    Color textColor;
    String label;

    switch (type) {
      case LottoEntryType.qrScan:
        bg = isLight ? const Color(0xFFE8F8F5) : const Color(0xFF2ECC71).withValues(alpha: 0.18);
        border = isLight ? const Color(0xFF2ECC71) : const Color(0xFF2ECC71).withValues(alpha: 0.6);
        textColor = isLight ? const Color(0xFF145A32) : const Color(0xFFA9DFBF);
        label = '🎫 실물복권';
        break;

      case LottoEntryType.dream:
        bg = isLight ? const Color(0xFFF3E5F5) : const Color(0xFFAB47BC).withValues(alpha: 0.18);
        border = isLight ? const Color(0xFFAB47BC) : const Color(0xFFAB47BC).withValues(alpha: 0.6);
        textColor = isLight ? const Color(0xFF6A1B9A) : const Color(0xFFCE93D8);
        label = '🌙 꿈해몽';
        break;

      case LottoEntryType.birthDate:
        bg = isLight ? const Color(0xFFFFF8E1) : const Color(0xFFFFB300).withValues(alpha: 0.18);
        border = isLight ? const Color(0xFFFFB300) : const Color(0xFFFFB300).withValues(alpha: 0.6);
        textColor = isLight ? const Color(0xFFB76E00) : const Color(0xFFFFE082);
        label = '🎂 생년월일';
        break;

      case LottoEntryType.customFilter:
        bg = isLight ? const Color(0xFFE0F7FA) : const Color(0xFF00ACC1).withValues(alpha: 0.18);
        border = isLight ? const Color(0xFF00ACC1) : const Color(0xFF00ACC1).withValues(alpha: 0.6);
        textColor = isLight ? const Color(0xFF006064) : const Color(0xFF80DEEA);
        label = '⚙️ 맞춤필터';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: border, width: 0.9),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSansKr(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

/// 당첨 등수 / 추첨 대기 뱃지 (텍스트 잘림 절대 방지)
class LottoRankBadgeWidget extends StatelessWidget {
  final int rank;
  final String label;
  final Set<int> matchedNumbers;

  const LottoRankBadgeWidget({
    super.key,
    required this.rank,
    required this.label,
    this.matchedNumbers = const {},
  });

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? icon;

    switch (rank) {
      case -1: // 추첨 대기
        bgColor = isLight
            ? const Color(0xFFEEF2FF)
            : const Color(0xFF312E81).withValues(alpha: 0.35);
        borderColor = isLight
            ? const Color(0xFFC7D2FE)
            : const Color(0xFF6366F1).withValues(alpha: 0.45);
        textColor = isLight
            ? const Color(0xFF4338CA)
            : const Color(0xFFA5B4FC);
        icon = Icons.schedule_rounded;
        break;
      case 1:
        bgColor = isLight ? const Color(0xFFFFF3CD) : const Color(0xFFFFD700).withValues(alpha: 0.22);
        borderColor = isLight ? const Color(0xFFFFC107) : const Color(0xFFFFD700);
        textColor = isLight ? const Color(0xFF8C5D00) : const Color(0xFFFFD700);
        icon = Icons.emoji_events_rounded;
        break;
      case 2:
        bgColor = isLight ? const Color(0xFFEBF5FB) : const Color(0xFF5DADE2).withValues(alpha: 0.22);
        borderColor = isLight ? const Color(0xFF3498DB) : const Color(0xFF5DADE2);
        textColor = isLight ? const Color(0xFF1B4F72) : const Color(0xFFD6EAF8);
        icon = Icons.military_tech_rounded;
        break;
      case 3:
        bgColor = isLight ? const Color(0xFFFBEEE6) : const Color(0xFFE59866).withValues(alpha: 0.22);
        borderColor = isLight ? const Color(0xFFE59866) : const Color(0xFFE59866);
        textColor = isLight ? const Color(0xFF78281F) : const Color(0xFFF5CBA7);
        icon = Icons.military_tech_outlined;
        break;
      case 4:
        bgColor = isLight ? const Color(0xFFE8F8F5) : const Color(0xFF2ECC71).withValues(alpha: 0.22);
        borderColor = isLight ? const Color(0xFF2ECC71) : const Color(0xFF2ECC71);
        textColor = isLight ? const Color(0xFF145A32) : const Color(0xFFA9DFBF);
        break;
      case 5:
        bgColor = isLight ? const Color(0xFFFEF9E7) : const Color(0xFFF39C12).withValues(alpha: 0.22);
        borderColor = isLight ? const Color(0xFFF39C12) : const Color(0xFFF39C12);
        textColor = isLight ? const Color(0xFF7D6608) : const Color(0xFFFAD7A0);
        break;
      default:
        final hasMatches = matchedNumbers.isNotEmpty;
        if (hasMatches) {
          bgColor = isLight ? const Color(0xFFF2F4F4) : Colors.white.withValues(alpha: 0.08);
          borderColor = isLight ? const Color(0xFFBDC3C7) : Colors.white24;
          textColor = isLight ? const Color(0xFF424949) : const Color(0xFFCCD1D1);
        } else {
          bgColor = isLight ? const Color(0xFFF8F9F9) : Colors.white.withValues(alpha: 0.05);
          borderColor = isLight ? const Color(0xFFE5E7E9) : Colors.white12;
          textColor = isLight ? const Color(0xFF707B7C) : const Color(0xFF85929E);
        }
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: borderColor, width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11.5, color: textColor),
            const SizedBox(width: 3.5),
          ],
          Text(
            label,
            style: GoogleFonts.notoSansKr(
              color: textColor,
              fontSize: 10.5,
              fontWeight: rank > 0 ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
