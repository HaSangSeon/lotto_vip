import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/dhlottery_api.dart';
import '../../utils/lottery_tax_calculator.dart';
import 'winning_detail_modal.dart';
import 'winning_stores_modal.dart';

class PrizeSectionView extends StatelessWidget {
  final DHLotteryResult result;
  final bool isRollover;
  final NumberFormat fmt;

  const PrizeSectionView({
    super.key,
    required this.result,
    required this.isRollover,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return _buildPrizeSection(result, isRollover, fmt, context);
  }

  /// 당첨금 및 상세 내역 섹션
  Widget _buildPrizeSection(DHLotteryResult result, bool isRollover, NumberFormat fmt, BuildContext context) {
    final isLight = AppColors.isLight;
    final hasTypeData = result.winTypeAuto > 0 || result.winTypeManual > 0 || result.winTypeSemi > 0;
    final firstWinAmount = isRollover ? result.firstSumWinamnt : result.firstWinamnt;
    final approxBillions = (firstWinAmount / 100000000).toStringAsFixed(1);
    final totalApproxBillions = (result.firstSumWinamnt / 100000000).toStringAsFixed(1);
    final firstTax = LotteryTaxCalculator.calculate(firstWinAmount);
    final firstNetBillion = (firstTax.netAmount / 100000000).toStringAsFixed(1);
    final firstTaxBillion = (firstTax.taxAmount / 100000000).toStringAsFixed(1);

    return Column(
      children: [
        // 1. 1등 당첨금 메인 하이라이트 카드 (Hero Prize Card)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isRollover
                  ? [
                      const Color(0xFFFF6B35).withValues(alpha: 0.15),
                      const Color(0xFFFF8C42).withValues(alpha: 0.08)
                    ]
                  : (isLight
                      ? [
                          const Color(0xFFFFFBF0),
                          const Color(0xFFFFF5D9),
                        ]
                      : [
                          AppColors.gold.withValues(alpha: 0.18),
                          AppColors.goldDark.withValues(alpha: 0.08),
                        ]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRollover
                  ? const Color(0xFFFF6B35).withValues(alpha: 0.45)
                  : (isLight ? const Color(0xFFE2B747).withValues(alpha: 0.6) : AppColors.gold.withValues(alpha: 0.45)),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: (isRollover ? const Color(0xFFFF6B35) : AppColors.gold).withValues(alpha: isLight ? 0.08 : 0.14),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 라벨 & 당첨자 수 뱃지
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isRollover
                              ? const Color(0xFFFF6B35).withValues(alpha: 0.2)
                              : (isLight ? const Color(0xFFFFE8A3) : AppColors.gold.withValues(alpha: 0.2)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRollover ? Icons.savings_rounded : Icons.emoji_events_rounded,
                          color: isRollover
                              ? const Color(0xFFE85D00)
                              : (isLight ? AppColors.goldDeep : AppColors.gold),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isRollover ? '이월 누적 적립금' : '1등 당첨금 (1인당)',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isRollover
                              ? const Color(0xFFE85D00)
                              : (isLight ? AppColors.goldDeep : AppColors.goldLight),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: isRollover
                          ? const Color(0xFFE85D00).withValues(alpha: 0.15)
                          : (isLight ? const Color(0xFFE8F8F5) : const Color(0xFF2ECC71).withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isRollover
                            ? const Color(0xFFE85D00).withValues(alpha: 0.3)
                            : (isLight ? const Color(0xFF2ECC71).withValues(alpha: 0.5) : const Color(0xFF2ECC71).withValues(alpha: 0.5)),
                        width: 0.9,
                      ),
                    ),
                    child: Text(
                      isRollover ? '당첨자 없음' : '🎯 ${result.firstWinCount}명 당첨',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isRollover
                            ? const Color(0xFFE85D00)
                            : (isLight ? const Color(0xFF145A32) : const Color(0xFFA9DFBF)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 중앙 메인 금액 (FittedBox로 자동 줄바꿈 원천 차단)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  fmt.format(firstWinAmount),
                  style: GoogleFonts.rajdhani(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    height: 1.05,
                    color: isRollover
                        ? const Color(0xFFE85D00)
                        : (isLight ? const Color(0xFF7A4F01) : const Color(0xFFFFD700)),
                  ),
                ),
              ),

              if (!isRollover && firstWinAmount >= 100000000) ...[
                const SizedBox(height: 9),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFFFEECC) : AppColors.gold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isLight ? const Color(0xFFE2B747).withValues(alpha: 0.6) : AppColors.gold.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '약 $approxBillions억 원',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isLight ? const Color(0xFF7A4F01) : AppColors.goldLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '총 ${result.firstWinCount}명에게 각 $approxBillions억 원씩 균등 지급',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // 1등 세후 예상 실수령액 안내 박스
              if (!isRollover && firstWinAmount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF7F3EA) : const Color(0xFF10131E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLight
                          ? const Color(0xFFE2B747).withValues(alpha: 0.45)
                          : AppColors.borderGold.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isLight
                              ? AppColors.gold.withValues(alpha: 0.3)
                              : AppColors.gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 15,
                          color: isLight ? AppColors.goldDeep : AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '예상 실수령액',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              firstTax.originalAmount > 300000000
                                  ? '세금 약 $firstTaxBillion억 공제 (33% 누진)'
                                  : (firstTax.taxAmount >= 100000000
                                      ? '세금 약 $firstTaxBillion억 공제 (22%)'
                                      : '세금 ${fmt.format(firstTax.taxAmount)} 공제 (22%)'),
                              style: GoogleFonts.notoSansKr(
                                fontSize: 10.5,
                                color: AppColors.textHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fmt.format(firstTax.netAmount),
                            style: GoogleFonts.rajdhani(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              color: isLight ? AppColors.goldDeep : AppColors.gold,
                            ),
                          ),
                          if (firstTax.netAmount >= 100000000)
                            Container(
                              margin: const EdgeInsets.only(top: 1.5),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isLight
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFF1B5E20).withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '약 $firstNetBillion억 원',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isLight
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFF81C784),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. 통합 주요 내역 카드 (1등 총 당첨금 + 1등 배출 방식 단일 일체형 카드)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF131724),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isLight
                  ? AppColors.lightGoldBorder.withValues(alpha: 0.35)
                  : AppColors.borderGold.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1행: 1등 총 당첨금
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 14,
                      color: isLight ? AppColors.goldDeep : AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '1등 총 당첨금',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fmt.format(result.firstSumWinamnt),
                        style: GoogleFonts.rajdhani(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: isLight ? const Color(0xFF2C2520) : Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (result.firstSumWinamnt >= 100000000) ...[
                        const SizedBox(height: 1),
                        Text(
                          '총 약 $totalApproxBillions억 원',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  thickness: 0.8,
                  color: isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.08),
                ),
              ),

              // 2행: 1등 배출 방식
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFE8F0FE) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 14,
                      color: isLight ? const Color(0xFF1967D2) : const Color(0xFF8AB4F8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '1등 배출 방식',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Spacer(),
                  if (hasTypeData)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMiniTypeBadge('자동', result.winTypeAuto, const Color(0xFF1976D2)),
                            const SizedBox(width: 6),
                            _buildMiniTypeBadge('수동', result.winTypeManual, const Color(0xFF2E7D32)),
                            if (result.winTypeSemi > 0) ...[
                              const SizedBox(width: 6),
                              _buildMiniTypeBadge('반자동', result.winTypeSemi, const Color(0xFF7B1FA2)),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    Text(
                      '구분 미제공',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 3. 1등 당첨 판매점(지역) 목록 확인 버튼
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFFFF8EE) : const Color(0xFF1E1A17),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight
                    ? const Color(0xFFFFB74D).withValues(alpha: 0.6)
                    : const Color(0xFFFF9800).withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.02 : 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => showWinningStoresModal(context, result.drwNo),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFFE65100)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '제 ${result.drwNo}회 1등 당첨 판매점(지역) 확인',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isLight ? const Color(0xFFC04B00) : const Color(0xFFFFB74D),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: isLight ? const Color(0xFFC04B00) : const Color(0xFFFFB74D),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 4. 1등~5등 전체 등위별 상세 결과 확인 버튼
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              color: isLight ? Colors.white : AppColors.cardHover,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight
                    ? AppColors.lightGoldBorder.withValues(alpha: 0.45)
                    : AppColors.borderGold.withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.02 : 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => showWinningDetailModal(context, result, fmt),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: (isLight ? AppColors.goldDeep : AppColors.gold).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.analytics_outlined,
                          size: 15,
                          color: isLight ? AppColors.goldDeep : AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '제 ${result.drwNo}회 등위별 상세 결과 및 상금 기준',
                          style: GoogleFonts.notoSansKr(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isLight ? AppColors.goldDeep : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: isLight ? AppColors.goldDeep : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniTypeBadge(String label, int count, Color color) {
    final isLight = AppColors.isLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isLight ? 0.1 : 0.18),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: color.withValues(alpha: isLight ? 0.3 : 0.4),
          width: 0.9,
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: label,
              style: GoogleFonts.notoSansKr(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isLight ? color : color.withValues(alpha: 0.95),
              ),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: '$count',
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isLight ? color : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
