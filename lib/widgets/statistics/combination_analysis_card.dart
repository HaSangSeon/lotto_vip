import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../common_widgets.dart';

/// 🔢 총합 황금구간(100~175) & 고저/연속번호 분석 카드
class CombinationAnalysisCard extends StatelessWidget {
  final bool? isLight;

  const CombinationAnalysisCard({
    super.key,
    this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = this.isLight ?? (Theme.of(context).brightness == Brightness.light);

    return GlassCard(
      gradientColors: isLight
          ? const [Color(0xFFFFFEFA), Color(0xFFFFF8E0)]
          : const [Color(0xFF181B28), Color(0xFF141722)],
      borderColor: isLight ? AppColors.lightGoldBorder.withValues(alpha: 0.35) : AppColors.borderGold,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calculate_rounded, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '총합 황금구간 & 연속번호 분석',
                      style: GoogleFonts.notoSansKr(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '역대 당첨 번호 6개의 합계 및 연번 통계',
                      style: GoogleFonts.notoSansKr(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. 번호 총합(Sum) 황금구간
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '🎯 총합 황금구간 (100 ~ 175)',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '역대 74.2% 출현',
                          style: GoogleFonts.rajdhani(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 시각적 게이지 바
                LayoutBuilder(
                  builder: (context, constraints) {
                    final totalW = constraints.maxWidth;
                    // 총합 범위: 21 (1+2+3+4+5+6) ~ 255 (40+41+42+43+44+45)
                    // 황금구간 100 ~ 175의 위치
                    final leftP = (100 - 21) / (255 - 21);
                    final rightP = (175 - 21) / (255 - 21);

                    return Stack(
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: isLight ? Colors.grey.shade200 : Colors.white10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Positioned(
                          left: totalW * leftP,
                          width: totalW * (rightP - leftP),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.teal, Colors.greenAccent],
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('최소 21', style: GoogleFonts.rajdhani(fontSize: 11, color: AppColors.textHint)),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '황금구간 (평균 138)',
                          style: GoogleFonts.notoSansKr(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('최대 255', style: GoogleFonts.rajdhani(fontSize: 11, color: AppColors.textHint)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. 고저 비율 & 연속번호 2열 카드
          Row(
            children: [
              // 고저 비율
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.swap_vert_rounded, size: 16, color: Colors.blueAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '고저 비율 (1~22 vs 23~45)',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildMiniStatRow('저3 : 고3', '33.1%', isTop: true),
                      const SizedBox(height: 4),
                      _buildMiniStatRow('저2 : 고4', '24.3%'),
                      const SizedBox(height: 4),
                      _buildMiniStatRow('저4 : 고2', '23.8%'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 연속 번호 출현율
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.link_rounded, size: 16, color: Colors.orangeAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '연속번호(연번) 출현',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildMiniStatRow('1쌍 이상 출현', '62.8%', isTop: true),
                      const SizedBox(height: 4),
                      _buildMiniStatRow('연번 없음', '37.2%'),
                      const SizedBox(height: 4),
                      _buildMiniStatRow('2쌍 연속 출현', '9.4%'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3. 전문가 팁
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.blueGrey.shade50.withValues(alpha: 0.5)
                  : Colors.blueGrey.shade900.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_rounded, color: AppColors.goldText, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '극단적으로 낮거나 높은 합계(100 미만 또는 180 초과)는 피하고, 6개 번호 중 1쌍(예: 23·24) 정도 연속된 번호를 포함하는 조합이 통계적으로 가장 많이 당첨됩니다.',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.45,
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

  Widget _buildMiniStatRow(String label, String value, {bool isTop = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
              color: isTop ? AppColors.goldText : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.rajdhani(
            fontSize: 12,
            fontWeight: isTop ? FontWeight.w800 : FontWeight.w600,
            color: isTop ? AppColors.goldText : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

