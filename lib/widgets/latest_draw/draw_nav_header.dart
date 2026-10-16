import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/dhlottery_api.dart';

/// 회차 네비게이션 헤더 (이전/다음 회차 이동, 회차 선택 팝업 트리거, 최신 회차 복귀 버튼)
class DrawNavHeader extends StatelessWidget {
  final DHLotteryResult result;
  final int? latestDrwNo;
  final VoidCallback onPrevDraw;
  final VoidCallback onNextDraw;
  final VoidCallback onSelectDraw;
  final VoidCallback onGoLatest;

  const DrawNavHeader({
    super.key,
    required this.result,
    required this.latestDrwNo,
    required this.onPrevDraw,
    required this.onNextDraw,
    required this.onSelectDraw,
    required this.onGoLatest,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;
    final canGoPrev = result.drwNo > 1;
    final canGoNext = latestDrwNo != null && result.drwNo < latestDrwNo!;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 이전 회차 버튼
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: canGoPrev
                  ? (isLight ? AppColors.goldDeep : AppColors.gold)
                  : AppColors.textHint.withValues(alpha: 0.2),
              onPressed: canGoPrev ? onPrevDraw : null,
              tooltip: '이전 회차',
            ),
            const SizedBox(width: 8),

            // 회차 뱃지 (클릭 시 회차 직접 입력 팝업)
            InkWell(
              onTap: onSelectDraw,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLight
                        ? [const Color(0xFFFFFDF5), const Color(0xFFFFF3D4)]
                        : [const Color(0xFF2C2616), const Color(0xFF1E190D)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: isLight ? 0.6 : 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: isLight ? 0.2 : 0.1),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '제 ${result.drwNo}회',
                      style: GoogleFonts.rajdhani(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.goldText,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: AppColors.gold.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_drop_down_circle_outlined,
                      size: 18,
                      color: AppColors.goldText.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 다음 회차 버튼
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
              color: canGoNext
                  ? (isLight ? AppColors.goldDeep : AppColors.gold)
                  : AppColors.textHint.withValues(alpha: 0.2),
              onPressed: canGoNext ? onNextDraw : null,
              tooltip: '다음 회차',
            ),
          ],
        ),

        // 최신 회차가 아닐 때 "최신 회차로 바로가기" 버튼
        if (canGoNext) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: onGoLatest,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.update_rounded, size: 16, color: AppColors.goldText),
                  const SizedBox(width: 6),
                  Text(
                    '최신 제 $latestDrwNo회로 이동',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),
        Text(
          '${result.drwNoDate} 추첨',
          style: GoogleFonts.notoSansKr(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
