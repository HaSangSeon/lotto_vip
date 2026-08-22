import 'package:flutter/material.dart';
import '../utils/safe_google_fonts.dart';
import '../theme/app_theme.dart';

/// 로또 볼 위젯 - 3D 입체 그라데이션 및 디테일한 광택 표현
class LottoBall extends StatelessWidget {
  final int number;
  final double size;
  final bool animate;
  final bool isMatched;
  final bool isDimmed;
  final bool isBonus;

  const LottoBall({
    super.key,
    required this.number,
    this.size = 44,
    this.animate = false,
    this.isMatched = false,
    this.isDimmed = false,
    this.isBonus = false,
  });

  static Color ballColor(int number) {
    if (number <= 10) return AppColors.ballYellow;
    if (number <= 20) return AppColors.ballBlue;
    if (number <= 30) return AppColors.ballRed;
    if (number <= 40) return AppColors.ballGray;
    return AppColors.ballGreen;
  }

  @override
  Widget build(BuildContext context) {
    final color = ballColor(number);
    final fontSize = size * 0.38;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isDimmed ? 0.35 : 1.0,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isMatched
              ? Border.all(
                  color: isBonus ? Colors.deepOrangeAccent : AppColors.gold,
                  width: 2.2,
                )
              : null,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.4),
            radius: 0.85,
            colors: [
              Color.lerp(color, Colors.white, 0.6)!,
              color,
              Color.lerp(color, Colors.black, 0.45)!,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            if (isMatched)
              BoxShadow(
                color: isBonus
                    ? Colors.deepOrangeAccent.withValues(alpha: 0.7)
                    : AppColors.gold.withValues(alpha: 0.8),
                blurRadius: size * 0.4,
                spreadRadius: 2,
              ),
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: size * 0.25,
              spreadRadius: 1,
              offset: Offset(0, size * 0.08),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: size * 0.2,
              offset: Offset(size * 0.05, size * 0.1),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 상단 곡면 반사광 (하이라이트)
            Positioned(
              top: size * 0.1,
              left: size * 0.2,
              child: Container(
                width: size * 0.32,
                height: size * 0.18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.5),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              number.toString(),
              style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: fontSize,
                height: 1.0,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 번호 행 위젯 - 6개 볼 반응형 자동 맞춤 배열 (일치 번호 하이라이트 지원)
class LottoBallRow extends StatelessWidget {
  final List<int> numbers;
  final double ballSize;
  final Set<int>? matchedNumbers;
  final int? bonusNumber;

  const LottoBallRow({
    super.key,
    required this.numbers,
    this.ballSize = 44,
    this.matchedNumbers,
    this.bonusNumber,
  });

  @override
  Widget build(BuildContext context) {
    final hasComparison = matchedNumbers != null && matchedNumbers!.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: numbers.map((n) {
              final isMainMatched = matchedNumbers?.contains(n) ?? false;
              final isBonusMatched = bonusNumber != null && bonusNumber == n;
              final isMatched = isMainMatched || isBonusMatched;
              final isDimmed = hasComparison && !isMatched;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: ballSize * 0.08),
                child: LottoBall(
                  number: n,
                  size: ballSize,
                  isMatched: isMatched,
                  isBonus: isBonusMatched,
                  isDimmed: isDimmed,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

