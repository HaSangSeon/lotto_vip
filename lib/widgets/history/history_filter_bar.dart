import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// 보관함 필터 타입
enum HistoryFilter {
  all, // 전체
  qrScanned, // 🎫 실물 복권 (QR 스캔)
  generated, // ✨ 생성 번호 (VIP + 맞춤)
  winnersOnly, // 🏆 당첨 번호
}

/// 보관함 상단 제어 바 (보관 번호 개수, 즐겨찾기 필터, 전체삭제) 및 4개 세그먼트 필터 위젯
class HistoryFilterBar extends StatelessWidget {
  final int currentCount;
  final bool onlyFavorites;
  final bool hasEntries;
  final HistoryFilter selectedFilter;
  final ValueChanged<HistoryFilter> onFilterChanged;
  final VoidCallback onToggleFavorites;
  final VoidCallback onClearAll;

  const HistoryFilterBar({
    super.key,
    required this.currentCount,
    required this.onlyFavorites,
    required this.hasEntries,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onToggleFavorites,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Column(
        children: [
          // 1. [상단 라인] 보관 개수 및 즐겨찾기 / 전체삭제 제어 라인
          Row(
            children: [
              Text(
                '보관된 번호 $currentCount개',
                style: GoogleFonts.notoSansKr(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),

              // 즐겨찾기 토글 버튼
              InkWell(
                onTap: onToggleFavorites,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: onlyFavorites
                        ? (isLight ? const Color(0xFFFFF0C2) : AppColors.gold.withValues(alpha: 0.2))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: onlyFavorites
                          ? (isLight ? const Color(0xFFD4AF37) : AppColors.gold)
                          : AppColors.borderSubtle.withValues(alpha: 0.5),
                      width: 0.9,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        onlyFavorites ? Icons.favorite : Icons.favorite_border,
                        size: 13,
                        color: onlyFavorites ? Colors.redAccent : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '즐겨찾기',
                        style: GoogleFonts.notoSansKr(
                          color: onlyFavorites
                              ? (isLight ? AppColors.goldDeep : AppColors.gold)
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: onlyFavorites ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 전체 삭제
              if (hasEntries)
                InkWell(
                  onTap: onClearAll,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_outlined, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '전체 삭제',
                          style: GoogleFonts.notoSansKr(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // 2. [하단 탭] 4개 세그먼트 (전체 | 실물복권 | 프리미엄 추출 | 당첨)
          Container(
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: isLight
                  ? const Color(0xFFF0EAE0)
                  : const Color(0xFF10131C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLight
                    ? const Color(0xFFE2D6C3)
                    : Colors.white.withValues(alpha: 0.08),
                width: 0.9,
              ),
            ),
            child: Row(
              children: [
                _buildSegmentItem(
                  filter: HistoryFilter.all,
                  label: '전체',
                  icon: Icons.grid_view_rounded,
                  isLight: isLight,
                ),
                _buildSegmentItem(
                  filter: HistoryFilter.qrScanned,
                  label: '실물복권',
                  icon: Icons.qr_code_scanner_rounded,
                  isLight: isLight,
                ),
                _buildSegmentItem(
                  filter: HistoryFilter.generated,
                  label: '프리미엄 추출',
                  icon: Icons.auto_awesome_rounded,
                  isLight: isLight,
                ),
                _buildSegmentItem(
                  filter: HistoryFilter.winnersOnly,
                  label: '당첨',
                  icon: Icons.emoji_events_rounded,
                  isLight: isLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem({
    required HistoryFilter filter,
    required String label,
    required IconData icon,
    required bool isLight,
  }) {
    final isSelected = selectedFilter == filter;
    final activeTextColor = isLight ? const Color(0xFF7A5200) : AppColors.gold;
    final inactiveTextColor = isLight ? const Color(0xFF7E756B) : const Color(0xFF8E94A8);
    final activeIconColor = isLight ? const Color(0xFF855A00) : AppColors.gold;
    final inactiveIconColor = isLight ? const Color(0xFF9E9284) : const Color(0xFF6B7288);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            onFilterChanged(filter);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            gradient: isSelected
                ? (isLight
                    ? const LinearGradient(
                        colors: [Colors.white, Color(0xFFFCF9F2)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.gold.withValues(alpha: 0.22),
                          AppColors.gold.withValues(alpha: 0.12),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ))
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isSelected
                  ? (isLight
                      ? const Color(0xFFD4AF37).withValues(alpha: 0.65)
                      : AppColors.gold.withValues(alpha: 0.75))
                  : Colors.transparent,
              width: 1.0,
            ),
            boxShadow: isSelected
                ? (isLight
                    ? [
                        BoxShadow(
                          color: const Color(0xFFB8860B).withValues(alpha: 0.10),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ])
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? activeIconColor : inactiveIconColor,
                ),
                const SizedBox(width: 3.5),
                Text(
                  label,
                  maxLines: 1,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: -0.2,
                    color: isSelected ? activeTextColor : inactiveTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
