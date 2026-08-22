import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import 'common_widgets.dart';
import 'lotto_ball.dart';

class VipTab extends StatelessWidget {
  final TextEditingController ctrl;
  final List<int> vipNumbers;
  final VoidCallback onGenerate;
  final ValueChanged<String>? onBirthDateChanged;
  final AnimationController shimmerCtrl;

  const VipTab({
    super.key,
    required this.ctrl,
    required this.vipNumbers,
    required this.onGenerate,
    this.onBirthDateChanged,
    required this.shimmerCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          // VIP 카드
          GlassCard(
            gradientColors: AppColors.isLight
                ? const [Color(0xFFFFFEFA), Color(0xFFFFF8E0)]
                : const [Color(0xFF1E1800), Color(0xFF0F0D00)],
            borderColor: AppColors.isLight
                ? AppColors.lightGoldBorder.withValues(alpha: 0.45)
                : AppColors.borderGold,
            shadows: AppColors.isLight
                ? [
                    BoxShadow(
                      color: AppColors.goldDark.withValues(alpha: 0.12),
                      blurRadius: 28,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 0,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                        color: Colors.black54,
                        blurRadius: 12,
                        offset: const Offset(0, 6)),
                  ],
            child: Column(
              children: [
                // 아이콘 + 뱃지
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const Icon(Icons.auto_awesome, color: AppColors.goldDark, size: 40),
                  ],
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 2000.ms, color: AppColors.goldLight.withValues(alpha: 0.3)),

                const SizedBox(height: 14),
                Text(
                  '오늘 나의 행운 번호',
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '내 생년월일(6자리)을 입력하시면\n오늘 당신에게 딱 맞는 행운의 번호를 뽑아드립니다.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),

                const GoldDivider(),

                // 입력 필드
                TextField(
                  controller: ctrl,
                  onChanged: onBirthDateChanged,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.goldText,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6,
                  ),
                  decoration: InputDecoration(
                    hintText: '700101',
                    hintStyle: GoogleFonts.rajdhani(
                      color: AppColors.textHint,
                      fontSize: 24,
                      letterSpacing: 4,
                    ),
                    prefixIcon: Icon(Icons.cake_outlined, color: AppColors.textSecondary),
                    suffixText: '생년월일 6자리',
                    suffixStyle: GoogleFonts.notoSansKr(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 생성 버튼
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
                            icon: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
                            label: Text(
                              '🍀 오늘 나의 행운 번호 뽑기',
                              style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
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
                          icon: const Icon(Icons.auto_awesome, size: 20),
                          label: Text(
                            '🍀 오늘 나의 행운 번호 뽑기',
                            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 결과 카드
          if (vipNumbers.isNotEmpty)
            GlassCard(
              gradientColors: AppColors.isLight
                  ? const [Color(0xFFFFFDF5), Color(0xFFFFF8E5)]
                  : const [Color(0xFF1A1800), Color(0xFF0D0B00)],
              borderColor: AppColors.borderGold,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars, color: AppColors.goldText, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '오늘 뽑은 행운 번호',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.goldText,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LottoBallRow(numbers: vipNumbers, ballSize: 48)
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOutBack),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          // 안내 카드
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '💡 생년월일은 기기에 안전하게 자동 저장되어, 매일 접속 시 오늘의 새로운 행운 번호가 자동으로 완성됩니다.',
                    style: GoogleFonts.notoSansKr(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
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
}
