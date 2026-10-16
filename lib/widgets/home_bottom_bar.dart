import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// 홈 화면 하단 네비게이션 바 및 상단 배너 광고 래퍼 위젯
class HomeBottomBar extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  final Widget? bannerAdWidget;
  final bool? isLight;

  const HomeBottomBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    this.bannerAdWidget,
    this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsLight = isLight ?? AppColors.isLight;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: effectiveIsLight
                ? AppColors.lightGoldBorder.withValues(alpha: 0.2)
                : AppColors.gold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveIsLight
                ? AppColors.goldDark.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?bannerAdWidget,
            BottomNavigationBar(
              currentIndex: selectedTab,
              onTap: onTabSelected,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: effectiveIsLight ? AppColors.goldDark : AppColors.gold,
              unselectedItemColor: AppColors.textHint,
              selectedLabelStyle: GoogleFonts.notoSansKr(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: GoogleFonts.notoSansKr(
                fontSize: 11,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events_rounded),
                  label: '당첨 확인',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_awesome),
                  label: '추출번호',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_rounded),
                  label: '통계 분석',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded),
                  label: '보관함',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
