import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 홈 화면 배경 럭셔리 실크 그라데이션 및 골드/퍼플 글로우 원형 오라 데코레이션 위젯
class HomeBackgroundOrbs extends StatelessWidget {
  final bool? isLight;

  const HomeBackgroundOrbs({
    super.key,
    this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsLight = isLight ?? AppColors.isLight;

    return SizedBox.expand(
      child: Stack(
        children: [
          // 1. 베이스 럭셔리 실크 그라데이션 (GPU 셰이더 연산, 메모리 0MB 소모)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: effectiveIsLight
                    ? const [
                        Color(0xFFFCF9F2), // 최상단: 따뜻하고 부드러운 샴페인 밀크
                        Color(0xFFF9F5EC), // 중간: 안정적인 프리미엄 아이보리 실크
                        Color(0xFFF2ECE1), // 최하단: 깊이감 있는 앤틱 골드 베이지
                      ]
                    : const [
                        Color(0xFF14131A), // 최상단: 깊은 밤하늘의 럭셔리 블랙
                        Color(0xFF0F0E14), // 중간: 세련된 옵시디언 다크
                        Color(0xFF0A090D), // 최하단: 극도의 몰입감을 주는 딥 블랙
                      ],
              ),
            ),
          ),
        ),

        // 2. 미세 글로우 오라 데코레이션
        if (effectiveIsLight) ...[
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFE8A3).withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE8D5B5).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFDF73).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          Positioned(
            top: -80,
            right: -50,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7B2CBF).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.purple.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
  }
}
