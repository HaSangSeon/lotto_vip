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
    final bool hasFilter = includeNumbers.isNotEmpty || excludeNumbers.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          // 메인 설정 및 생성 카드
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  icon: Icons.tune_rounded,
                  title: '내가 정하는 맞춤 번호',
                  subtitle: '꼭 넣고 싶은 번호와 빼고 싶은 번호를 직접 선택하여\n나만의 최적화된 로또 번호를 조합합니다.',
                ),
                const GoldDivider(),

                // 상단 필터 개념 & 상태 친절 안내 박스
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.isLight
                        ? const Color(0xFFF9F7F1)
                        : Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.isLight
                          ? AppColors.lightGoldBorder.withValues(alpha: 0.35)
                          : AppColors.borderSubtle,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            color: AppColors.isLight ? AppColors.goldDark : AppColors.gold,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '고정수 / 제외수란?',
                            style: GoogleFonts.notoSansKr(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildGuideRow(
                        '🔵 고정수(포함)',
                        '결과에 꼭 넣고 싶은 내 행운의 번호 (최대 5개)',
                      ),
                      const SizedBox(height: 4),
                      _buildGuideRow(
                        '🔴 제외수(제외)',
                        '나올 것 같지 않아 조합에서 뺄 번호 (최대 39개)',
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        color: AppColors.isLight
                            ? Colors.black.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            hasFilter ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                            size: 15,
                            color: hasFilter
                                ? (AppColors.isLight ? AppColors.goldDark : AppColors.gold)
                                : AppColors.textHint,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hasFilter
                                  ? '현재 고정수(${includeNumbers.length}개) 및 제외수(${excludeNumbers.length}개) 필터가 적용되어 있습니다.'
                                  : '현재 설정된 필터가 없어 전체(1~45번)에서 무작위로 추출됩니다.',
                              style: GoogleFonts.notoSansKr(
                                color: hasFilter
                                    ? (AppColors.isLight ? AppColors.goldDark : AppColors.goldLight)
                                    : AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: hasFilter ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 설정된 번호 칩 표시 (필터가 있을 때)
                if (hasFilter) ...[
                  if (includeNumbers.isNotEmpty) ...[
                    _buildNumberChips('꼭 넣을 고정수 (${includeNumbers.length}개)', includeNumbers, const Color(0xFF1565C0)),
                    const SizedBox(height: 10),
                  ],
                  if (excludeNumbers.isNotEmpty) ...[
                    _buildNumberChips('뺄 제외수 (${excludeNumbers.length}개)', excludeNumbers, const Color(0xFFC62828)),
                    const SizedBox(height: 12),
                  ],
                ],

                // 1단계: 고정수/제외수 상세 필터 버튼
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onOpenDialog,
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
                    ),
                    label: Text(
                      hasFilter ? '⚙️ 고정수 / 제외수 변경하기' : '⚙️ 고정수 / 제외수 상세 필터 설정',
                      style: GoogleFonts.notoSansKr(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.isLight ? AppColors.goldDeep : AppColors.textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      foregroundColor: AppColors.isLight ? AppColors.goldDeep : AppColors.textPrimary,
                      side: BorderSide(
                        color: AppColors.isLight
                            ? AppColors.goldDark.withValues(alpha: 0.45)
                            : AppColors.borderGold,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 2단계 (맨 아래 메인 버튼): 커스텀 번호 추출하기
                SizedBox(
                  width: double.infinity,
                  child: AppColors.isLight
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
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: onGenerate,
                            icon: const Icon(Icons.bolt, color: Colors.white, size: 22),
                            label: Text(
                              '⚡ 맞춤 번호 조합 추출하기',
                              style: GoogleFonts.notoSansKr(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: onGenerate,
                          icon: const Icon(Icons.bolt, color: Colors.black, size: 22),
                          label: Text(
                            '⚡ 맞춤 번호 조합 추출하기',
                            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 6,
                            shadowColor: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 결과 카드 (생성 시)
          if (customNumbers.isNotEmpty)
            GlassCard(
              borderColor: AppColors.borderGold,
              gradientColors: AppColors.isLight
                  ? const [Color(0xFFFFFDF5), Color(0xFFFFF8E5)]
                  : const [Color(0xFF1A1800), Color(0xFF0D0B00)],
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars, color: AppColors.goldText, size: 18),
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
                  const SizedBox(height: 20),
                  LottoBallRow(numbers: customNumbers, ballSize: 48)
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

  Widget _buildGuideRow(String label, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.notoSansKr(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            desc,
            style: GoogleFonts.notoSansKr(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberChips(String label, List<int> numbers, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansKr(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: numbers
              .map(
                (n) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    n.toString(),
                    style: GoogleFonts.rajdhani(
                      color: AppColors.isLight ? color : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
