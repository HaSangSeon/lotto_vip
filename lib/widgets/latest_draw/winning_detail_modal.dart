import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/dhlottery_api.dart';
import '../../utils/lottery_tax_calculator.dart';

/// 제 N회 등위별 상세 결과 및 상금 기준 모달
void showWinningDetailModal(
  BuildContext context,
  DHLotteryResult result,
  NumberFormat fmt,
) {
  final numFmt = NumberFormat.decimalPattern();
  final isLight = AppColors.isLight;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.isLight ? AppColors.lightGoldBorder : AppColors.borderGold,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.15),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 헤더 타이틀
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '제 ${result.drwNo}회 당첨 상세 분석',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '추첨일: ${result.drwNoDate}',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 24),
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 18),

            // 1. 1등 당첨 유형 (자동 / 수동 / 반자동)
            Text(
              '1등 당첨 배출 유형 (총 ${result.firstWinCount}명)',
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
              ),
            ),
            const SizedBox(height: 10),
            if (result.firstWinCount > 0 && result.winTypeAuto == 0 && result.winTypeManual == 0 && result.winTypeSemi == 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.isLight ? const Color(0xFFF9F7F1) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textHint),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '💡 261회 이전 과거 회차는 동행복권 공식 시스템에 자동/수동 구분 집계 데이터가 도입되기 전이므로 미제공(0명)으로 표기됩니다.',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildTypeCard(
                      '자동',
                      '${result.winTypeAuto}명',
                      const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeCard(
                      '수동',
                      '${result.winTypeManual}명',
                      const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeCard(
                      '반자동',
                      '${result.winTypeSemi}명',
                      const Color(0xFF6C3FC5),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // 2. 등위별 상세 당첨 현황표
            Text(
              '등위별 당첨 기준 & 상금 결과',
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '추첨된 번호 6개와 보너스 번호의 일치 개수에 따라 등수가 결정됩니다.',
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.isLight ? const Color(0xFFF9F7F1) : AppColors.cardHover,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  _buildRankRow('1등', '🎯 번호 6개 모두 일치', result.firstWinamnt, '${numFmt.format(result.firstWinCount)}명', fmt, isFirst: true),
                  Divider(height: 1, color: AppColors.borderSubtle),
                  _buildRankRow('2등', '🎯 번호 5개 + 보너스번호 일치', result.rank2Amount, '${numFmt.format(result.rank2Count)}명', fmt),
                  Divider(height: 1, color: AppColors.borderSubtle),
                  _buildRankRow('3등', '🎯 번호 5개 일치', result.rank3Amount, '${numFmt.format(result.rank3Count)}명', fmt),
                  Divider(height: 1, color: AppColors.borderSubtle),
                  _buildRankRow('4등', '🎯 번호 4개 일치 (고정 5만원)', result.rank4Amount > 0 ? result.rank4Amount : 50000, '${numFmt.format(result.rank4Count)}명', fmt),
                  Divider(height: 1, color: AppColors.borderSubtle),
                  _buildRankRow('5등', '🎯 번호 3개 일치 (고정 5천원)', result.rank5Amount > 0 ? result.rank5Amount : 5000, '${numFmt.format(result.rank5Count)}명', fmt, isLast: true),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 복권 과세 및 실수령 안내 박스
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF0F5FA) : const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isLight
                      ? const Color(0xFFCFDEEC)
                      : const Color(0xFF2B384E),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 16,
                        color: isLight ? const Color(0xFF1976D2) : const Color(0xFF64B5F6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '복권 당첨금 세금 및 실수령 기준 (소득세법)',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '• 200만 원 이하 (3~5등): 전액 비과세로 세금 0원 (수령액 100%)\n• 200만~3억 원 이하 (2등): 소득세 20% + 지방세 2% = 총 22% 원천징수\n• 3억 원 초과 (1등): 3억 원까지 22% + 3억 초과분 33% 원천징수\n* 1게임 복권 구입비용(1,000원)은 필요경비로 전액 공제됩니다.',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 등수 결정 기준 친절 안내 박스
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.isLight
                      ? AppColors.lightGoldBorder.withValues(alpha: 0.3)
                      : AppColors.borderGold.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: AppColors.isLight ? AppColors.goldDark : AppColors.gold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '로또 등수 결정 기준 (상식)',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• 1등~5등은 각각 다른 번호가 아니라, 메인 화면에 나온 [당첨 번호 6개 + 보너스 번호 1개]와 내가 가진 번호가 몇 개 일치하는지로 판정됩니다.\n• 2등은 5개 번호와 함께 [보너스 번호]까지 맞아야 당첨됩니다.',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildTypeCard(String title, String count, Color accentColor) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: accentColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Text(
          title,
          style: GoogleFonts.notoSansKr(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: GoogleFonts.rajdhani(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

Widget _buildRankRow(
  String rank,
  String condition,
  int rawAmount,
  String count,
  NumberFormat fmt, {
  bool isFirst = false,
  bool isLast = false,
}) {
  final taxResult = LotteryTaxCalculator.calculate(rawAmount);
  final isLight = AppColors.isLight;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isFirst
                ? (AppColors.isLight ? AppColors.gold.withValues(alpha: 0.25) : AppColors.gold.withValues(alpha: 0.2))
                : (AppColors.isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            rank,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isFirst
                  ? (AppColors.isLight ? AppColors.goldDeep : AppColors.gold)
                  : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 당첨 조건
              Text(
                condition,
                style: GoogleFonts.notoSansKr(
                  fontSize: 11,
                  color: isFirst
                      ? (AppColors.isLight ? AppColors.goldDark : AppColors.goldLight)
                      : AppColors.textSecondary,
                  fontWeight: isFirst ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              // 세전 당첨금
              Row(
                children: [
                  Text(
                    '세전 ',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                  Text(
                    fmt.format(rawAmount),
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isFirst
                          ? (AppColors.isLight ? AppColors.goldDeep : AppColors.gold)
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // 세후 실수령액 (하이라이트 박스)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: taxResult.isTaxFree
                        ? (isLight ? const Color(0xFFE8F5E9) : const Color(0xFF1B5E20).withValues(alpha: 0.35))
                        : (isLight ? const Color(0xFFFFF3E0) : const Color(0xFFE65100).withValues(alpha: 0.25)),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: taxResult.isTaxFree
                          ? (isLight ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32).withValues(alpha: 0.5))
                          : (isLight ? const Color(0xFFFFCC80) : const Color(0xFFFF9800).withValues(alpha: 0.4)),
                      width: 0.6,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '실수령 ',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: taxResult.isTaxFree
                              ? (isLight ? const Color(0xFF2E7D32) : const Color(0xFF81C784))
                              : (isLight ? const Color(0xFFE65100) : const Color(0xFFFFB74D)),
                        ),
                      ),
                      Text(
                        fmt.format(taxResult.netAmount),
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: taxResult.isTaxFree
                              ? (isLight ? const Color(0xFF1B5E20) : const Color(0xFFA5D6A7))
                              : (isLight ? const Color(0xFFBF360C) : const Color(0xFFFFCC80)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${taxResult.taxDescription})',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              count,
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '당첨자',
              style: GoogleFonts.notoSansKr(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
