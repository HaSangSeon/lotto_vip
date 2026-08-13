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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          // 메인 설정 및 생성 카드
          GlassCard(
            child: Column(
              children: [
                const SectionTitle(
                  icon: Icons.tune_rounded,
                  title: '내가 정하는 맞춤 번호',
                  subtitle: '꼭 넣고 싶은 번호는 고정하고, 빼고 싶은 번호는 제외하여\n나만의 맞춤 당첨 번호를 만들어보세요.',
                ),
                const GoldDivider(),

                // 현재 필터 상태 요약
                if (includeNumbers.isEmpty && excludeNumbers.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.gold, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '현재 전체 45개 번호에서 무작위 추출 중',
                          style: GoogleFonts.notoSansKr(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  if (includeNumbers.isNotEmpty) ...[
                    _buildNumberChips('꼭 넣을 번호 (${includeNumbers.length}개)', includeNumbers, const Color(0xFF1565C0)),
                    const SizedBox(height: 10),
                  ],
                  if (excludeNumbers.isNotEmpty) ...[
                    _buildNumberChips('뺄 번호 (${excludeNumbers.length}개)', excludeNumbers, const Color(0xFFC62828)),
                    const SizedBox(height: 16),
                  ],
                ],

                // 액션 버튼 그룹
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
                            icon: const Icon(Icons.bolt, color: Colors.white),
                            label: Text(
                              '⚡ 커스텀 번호 추출하기',
                              style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 54),
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
                          icon: const Icon(Icons.bolt, color: Colors.black),
                          label: Text(
                            '⚡ 커스텀 번호 추출하기',
                            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 6,
                            shadowColor: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onOpenDialog,
                    icon: Icon(Icons.settings, size: 18, color: AppColors.isLight ? AppColors.goldDeep : null),
                    label: Text(
                      '⚙️ 고정수 / 제외수 상세 필터',
                      style: GoogleFonts.notoSansKr(
                        fontWeight: FontWeight.w600,
                        color: AppColors.isLight ? AppColors.goldDeep : null,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: AppColors.isLight ? AppColors.goldDeep : AppColors.textPrimary,
                      side: BorderSide(
                        color: AppColors.isLight
                            ? AppColors.goldDark.withValues(alpha: 0.45)
                            : AppColors.borderGold,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      const Icon(Icons.tune, color: AppColors.gold, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '최근 생성된 커스텀 번호',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
                      color: Colors.white,
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
