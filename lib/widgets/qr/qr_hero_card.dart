import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class QrHeroCard extends StatelessWidget {
  final bool hasWin;
  final bool isDrawn;
  final bool isPending;
  final bool isNetworkError;
  final int winCount;
  final int totalPrize;
  final NumberFormat fmt;
  final String dateStr;
  final bool isLight;
  final bool isSavedToHistory;
  final int gameCount;
  final bool isRetrying;
  final VoidCallback? onRetry;

  const QrHeroCard({
    super.key,
    required this.hasWin,
    required this.isDrawn,
    required this.isPending,
    required this.isNetworkError,
    required this.winCount,
    required this.totalPrize,
    required this.fmt,
    required this.dateStr,
    required this.isLight,
    required this.isSavedToHistory,
    required this.gameCount,
    this.isRetrying = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // A. 당첨 상태
    if (hasWin) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLight
                ? const [Color(0xFFFFF8E5), Color(0xFFFFF0C2)]
                : const [Color(0xFF2C2208), Color(0xFF191404)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gold,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: isLight ? 0.2 : 0.35),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.military_tech_rounded, color: AppColors.gold, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '축하합니다! 총 $winCount게임 당첨',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isLight ? AppColors.goldDeep : AppColors.gold,
                        ),
                      ),
                      Text(
                        '가까운 판매점 및 농협에서 당첨금을 수령하세요!',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11.5,
                          color: isLight ? const Color(0xFF6E4D08) : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isLight
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '총 당첨금액',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${fmt.format(totalPrize)}원',
                    style: GoogleFonts.rajdhani(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isLight ? AppColors.goldDeep : AppColors.goldLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isSavedToHistory) ...[
              const SizedBox(height: 12),
              _buildInlineStorageChip(
                isLight: isLight,
                accentColor: isLight ? const Color(0xFF8C6514) : AppColors.gold,
                text: '스캔한 번호($gameCount게임)가 보관함에 안전하게 저장되었습니다.',
              ),
            ],
          ],
        ),
      ).animate().shimmer(duration: 1600.ms);
    }

    // B. 추첨 전 상태 (Pending)
    if (isPending) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLight
                ? const [Color(0xFFEBF5FB), Color(0xFFD6EAF8)]
                : const [Color(0xFF0F1E32), Color(0xFF0A1322)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF3498DB).withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498DB).withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.access_time_filled_rounded, color: Color(0xFF3498DB), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '아직 추첨 전인 복권입니다',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isLight ? const Color(0xFF1B4F72) : const Color(0xFFEBF5FB),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '추첨 예정일: $dateStr 오후 8시 35분경',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isLight ? const Color(0xFF2874A6) : const Color(0xFFAED6F1),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '추첨 완료 후 [보관함] 탭에서 자동으로 채점 결과를 확인하실 수 있습니다.',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11,
                          color: isLight ? const Color(0xFF5D6D7E) : Colors.white60,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSavedToHistory) ...[
              const SizedBox(height: 12),
              _buildInlineStorageChip(
                isLight: isLight,
                accentColor: const Color(0xFF3498DB),
                text: '번호가 보관함에 등록되었습니다. 추첨 당일 알림을 받으실 수 있습니다.',
              ),
            ],
          ],
        ),
      );
    }

    // C. 네트워크 오류 상태
    if (isNetworkError && !isDrawn) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLight
                ? const [Color(0xFFFEF9E7), Color(0xFFFCF3CF)]
                : const [Color(0xFF251C0E), Color(0xFF191307)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF39C12).withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: Color(0xFFD68910), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '당첨 결과 조회 연결 지연',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isLight ? const Color(0xFF7D6608) : const Color(0xFFFAD7A0),
                        ),
                      ),
                      Text(
                        '네트워크 상태를 확인 후 다시 시도해 주세요.',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isRetrying ? null : onRetry,
                  icon: isRetrying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    isRetrying ? '조회 중...' : '당첨 결과 다시 조회하기',
                    style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    foregroundColor: const Color(0xFFD68910),
                    side: const BorderSide(color: Color(0xFFD68910)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            if (isSavedToHistory) ...[
              const SizedBox(height: 10),
              _buildInlineStorageChip(
                isLight: isLight,
                accentColor: const Color(0xFFD68910),
                text: '스캔한 번호는 보관함에 안전하게 임시 저장되었습니다.',
              ),
            ],
          ],
        ),
      );
    }

    // D. 낙첨 상태
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? const [Color(0xFFFFF7F6), Color(0xFFFAF0EF)]
              : const [Color(0xFF1E171B), Color(0xFF151117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE57373).withValues(alpha: 0.35)
              : const Color(0xFFE57373).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFE57373),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '아쉽게도 이번 회차는 낙첨되었습니다',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isLight ? const Color(0xFF8A2E24) : const Color(0xFFF7C5C0),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '다음 회차에는 더 큰 행운이 함께하길 기원합니다!',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isSavedToHistory) ...[
            const SizedBox(height: 12),
            _buildInlineStorageChip(
              isLight: isLight,
              accentColor: const Color(0xFF2ECC71),
              text: '스캔한 번호($gameCount게임)가 보관함에 안전하게 저장되었습니다.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineStorageChip({
    required bool isLight,
    required Color accentColor,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: accentColor, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.notoSansKr(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isLight ? const Color(0xFF333333) : Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
