import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/dhlottery_api.dart';
import '../lotto_ball.dart';

/// 제 N회 당첨 번호 6개 & 보너스 번호 럭셔리 쇼케이스 박스
class WinningNumbersShowcase extends StatelessWidget {
  final DHLotteryResult result;

  const WinningNumbersShowcase({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF161825),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.03),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          // 은은한 골드 이너 글로우
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.03),
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // 6개 당첨 번호 라벨
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stars_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 6),
              Text(
                '당첨 번호',
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isLight ? AppColors.goldDeep : AppColors.goldText,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 6개의 당첨 번호 공
          LottoBallRow(numbers: result.numbers, ballSize: 42),

          const SizedBox(height: 24),

          // 보너스 번호 섹션 (시각적 구분감 강화)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 왼쪽 장식선
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, AppColors.borderGold.withValues(alpha: 0.5)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 보너스 아이콘과 + 기호 결합
              Column(
                children: [
                  Icon(
                    Icons.add_circle_rounded,
                    color: isLight ? const Color(0xFFE65100) : const Color(0xFFFF9800),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'BONUS',
                    style: GoogleFonts.rajdhani(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isLight ? const Color(0xFFE65100) : const Color(0xFFFF9800),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // 보너스 공
              LottoBall(number: result.bonusNo, size: 48, isBonus: true),
              const SizedBox(width: 16),

              // 오른쪽 장식선
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.borderGold.withValues(alpha: 0.5), Colors.transparent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
