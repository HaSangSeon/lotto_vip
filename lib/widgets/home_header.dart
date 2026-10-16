import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onQrScanTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onAppInfoTap;
  final Animation<double> pulseAnimation;
  final bool? isLight;

  const HomeHeader({
    super.key,
    required this.onQrScanTap,
    required this.onNotificationTap,
    required this.onAppInfoTap,
    required this.pulseAnimation,
    this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsLight = isLight ?? AppColors.isLight;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: effectiveIsLight
          ? BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.lightGoldBorder.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldDark.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 0,
                  spreadRadius: 0,
                  offset: const Offset(0, 0),
                ),
              ],
            )
          : null,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: effectiveIsLight
                      ? [AppColors.goldDeep, AppColors.goldDark, AppColors.gold]
                      : [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
                ).createShader(bounds),
                child: Text(
                  '로또 신통',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Text(
                '프리미엄 번호 생성기',
                style: GoogleFonts.notoSansKr(
                  fontSize: 10.5,
                  color: effectiveIsLight ? AppColors.goldDeep.withValues(alpha: 0.7) : AppColors.textSecondary,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // 📷 QR 스캔 전용 버튼
          InkWell(
            onTap: onQrScanTap,
            borderRadius: BorderRadius.circular(17),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: effectiveIsLight
                    ? const Color(0xFFFFF6DF)
                    : AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: effectiveIsLight
                      ? AppColors.lightGoldBorder.withValues(alpha: 0.7)
                      : AppColors.borderGold.withValues(alpha: 0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (effectiveIsLight ? AppColors.goldDark : AppColors.gold)
                        .withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 16,
                    color: effectiveIsLight ? AppColors.goldDeep : AppColors.gold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'QR스캔',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: effectiveIsLight ? AppColors.goldDeep : AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 34,
            height: 34,
            decoration: effectiveIsLight
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightAccentAmber.withValues(alpha: 0.6),
                  )
                : null,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 19,
              icon: Icon(
                Icons.notifications_outlined,
                color: effectiveIsLight ? AppColors.goldDeep : AppColors.textSecondary,
              ),
              tooltip: '추첨 알림 설정',
              onPressed: onNotificationTap,
            ),
          ),
          const SizedBox(width: 3),
          Container(
            width: 34,
            height: 34,
            decoration: effectiveIsLight
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightAccentAmber.withValues(alpha: 0.6),
                  )
                : null,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 19,
              icon: Icon(
                effectiveIsLight
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: effectiveIsLight ? AppColors.goldDeep : AppColors.textSecondary,
              ),
              tooltip: '테마 변경',
              onPressed: AppTheme.toggleTheme,
            ),
          ),
          const SizedBox(width: 3),
          GestureDetector(
            onTap: onAppInfoTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (_, _) => Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: effectiveIsLight
                      ? LinearGradient(
                          colors: [
                            AppColors.goldDark,
                            AppColors.goldDeep,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: effectiveIsLight ? null : AppColors.card,
                  boxShadow: [
                    BoxShadow(
                      color: effectiveIsLight
                          ? AppColors.goldDark.withValues(alpha: 0.25 + pulseAnimation.value * 0.15)
                          : AppColors.gold.withValues(alpha: 0.1 + pulseAnimation.value * 0.15),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.workspace_premium,
                  color: effectiveIsLight ? Colors.white : AppColors.gold,
                  size: 19,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
