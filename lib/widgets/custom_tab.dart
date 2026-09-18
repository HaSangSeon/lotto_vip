import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import 'common_widgets.dart';
import 'lotto_ball.dart';

class CustomTab extends StatelessWidget {
  final List<int> customNumbers;
  final List<int> includeNumbers;
  final List<int> excludeNumbers;
  final VoidCallback onOpenDialog;
  final VoidCallback onGenerate;

  const CustomTab({
    super.key,
    required this.customNumbers,
    required this.includeNumbers,
    required this.excludeNumbers,
    required this.onOpenDialog,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;
    final bool hasFilter = includeNumbers.isNotEmpty || excludeNumbers.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          // 메인 설정 및 생성 카드
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            borderColor: AppColors.borderGold,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 세련된 상단 헤더
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isLight
                                ? [const Color(0xFFFFF7E6), const Color(0xFFFFE6B3)]
                                : [AppColors.gold.withValues(alpha: 0.2), AppColors.goldDark.withValues(alpha: 0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: isLight ? AppColors.lightGoldBorder : AppColors.gold.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: isLight ? AppColors.goldDeep : AppColors.gold,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '내가 정하는 맞춤 번호',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '고정수(포함)와 제외수(제외)를 설정하여 나만의 최적 조합을 추출합니다.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. 1단계: 고정수/제외수 상세 필터 버튼 (최상단으로 이동)
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isLight ? Colors.white : AppColors.cardHover,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLight ? AppColors.lightGoldBorder.withValues(alpha: 0.45) : AppColors.borderGold.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onOpenDialog,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 17,
                                color: isLight ? AppColors.goldDeep : AppColors.gold,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                hasFilter ? '⚙️ 고정수 / 제외수 변경하기' : '⚙️ 고정수 / 제외수 상세 필터 설정',
                                style: GoogleFonts.notoSansKr(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: isLight ? AppColors.goldDeep : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 3. 설정된 번호 칩 표시 (필터가 있을 때만 노출)
                if (hasFilter) ...[
                  if (includeNumbers.isNotEmpty) ...[
                    _buildSelectedNumberList('포함할 고정수', includeNumbers, const Color(0xFF1976D2), isLight),
                    const SizedBox(height: 12),
                  ],
                  if (excludeNumbers.isNotEmpty) ...[
                    _buildSelectedNumberList('제외할 번호', excludeNumbers, const Color(0xFFD32F2F), isLight),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                ],

                // 4. 2단계: 메인 액션 버튼 (맞춤 번호 조합 추출하기)
                SizedBox(
                  width: double.infinity,
                  child: isLight
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFB8860B), Color(0xFF92690A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.goldDark.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: onGenerate,
                            icon: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                            label: Text(
                              '⚡ 맞춤 번호 조합 추출하기',
                              style: GoogleFonts.notoSansKr(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            if (includeNumbers.isEmpty && excludeNumbers.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '고정수나 제외수를 최소 1개 이상 선택해 주세요!',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.notoSansKr(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFFD32F2F),
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                              return;
                            }
                            onGenerate();
                          },
                          icon: const Icon(Icons.bolt_rounded, color: Colors.black, size: 22),
                          label: Text(
                            '⚡ 맞춤 번호 조합 추출하기',
                            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 7. 결과 카드 (생성 시)
          if (customNumbers.isNotEmpty)
            GlassCard(
              borderColor: AppColors.borderGold,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
              gradientColors: isLight
                  ? const [Color(0xFFFFFDF5), Color(0xFFFFF8E5)]
                  : const [Color(0xFF1A1800), Color(0xFF0D0B00)],
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars_rounded, color: AppColors.goldText, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '생성된 맞춤 행운 번호',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.goldText,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  LottoBallRow(numbers: customNumbers, ballSize: 44)
                      .animate()
                      .fadeIn()
                      .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutBack),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
        ],
      ),
    );
  }



  /// 설정된 고정수/제외수 번호 칩 리스트
  Widget _buildSelectedNumberList(String label, List<int> numbers, Color color, bool isLight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF9F7F1) : const Color(0xFF0F121C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$label (${numbers.length}개)',
                style: GoogleFonts.notoSansKr(
                  color: AppColors.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: numbers
                .map(
                  (n) => Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: isLight ? 0.15 : 0.3),
                          color.withValues(alpha: isLight ? 0.3 : 0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: color.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      n.toString(),
                      style: GoogleFonts.rajdhani(
                        color: isLight ? color : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
