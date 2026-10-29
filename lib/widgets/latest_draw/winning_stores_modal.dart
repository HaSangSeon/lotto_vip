import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/dhlottery_api.dart';
import 'winning_store_card.dart';

/// 제 N회 당첨 판매점(명당) 조회 모달 (1등 및 2등 배출점 지원)
void showWinningStoresModal(BuildContext context, int drwNo) {
  final isLight = AppColors.isLight;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      String filter = '전체';
      int currentRank = 1; // 1: 1등, 2: 2등

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isLight ? AppColors.lightGoldBorder.withValues(alpha: 0.5) : AppColors.borderGold,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // 상단 드래그 핸들
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isLight ? Colors.grey.shade300 : Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),

                // 모달 헤더 (아이콘 + 타이틀 + 닫기 버튼)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFE65100).withValues(alpha: 0.16),
                              (isLight ? AppColors.goldDeep : AppColors.gold).withValues(alpha: 0.18),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (isLight ? AppColors.goldDeep : AppColors.gold).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(Icons.storefront_rounded, size: 20, color: Color(0xFFE65100)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '제 $drwNo회 당첨 판매점(지역)',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '동행복권 공식 1등·2등 배출 명당 목록',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textSecondary,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 1등 배출점 vs 2등 배출점 메인 세그먼트 탭
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF0EAE0) : const Color(0xFF10131C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLight ? const Color(0xFFE2D6C3) : Colors.white.withValues(alpha: 0.08),
                        width: 0.9,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildRankTabButton(
                          label: '🥇 1등 배출 명당',
                          isSelected: currentRank == 1,
                          isLight: isLight,
                          onTap: () {
                            if (currentRank != 1) {
                              setModalState(() {
                                currentRank = 1;
                                filter = '전체';
                              });
                            }
                          },
                        ),
                        _buildRankTabButton(
                          label: '🥈 2등 배출 명당',
                          isSelected: currentRank == 2,
                          isLight: isLight,
                          onTap: () {
                            if (currentRank != 2) {
                              setModalState(() {
                                currentRank = 2;
                                filter = '전체';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.08),
                ),

                // 판매점 비동기 데이터 목록
                Expanded(
                  child: FutureBuilder<List<DHLotteryWinningStore>>(
                    key: ValueKey('store_${drwNo}_$currentRank'),
                    future: DHLotteryApi.fetchWinningStores(drwNo, rank: currentRank),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: AppColors.gold),
                              const SizedBox(height: 16),
                              Text(
                                '제 $drwNo회 $currentRank등 판매점을 불러오는 중...',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.storefront_outlined, size: 48, color: AppColors.textHint),
                                const SizedBox(height: 12),
                                Text(
                                  '$currentRank등 판매점 정보를 불러올 수 없습니다.',
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '아직 집계 중이거나 네트워크 연결 상태를 확인해 주세요.',
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 12,
                                    color: AppColors.textHint,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse(
                                      'https://www.dhlottery.co.kr/gameResult.do?method=byWin',
                                    );
                                    try {
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    } catch (_) {}
                                  },
                                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                                  label: Text(
                                    '동행복권 공식 웹에서 확인하기',
                                    style: GoogleFonts.notoSansKr(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isLight ? AppColors.goldDark : AppColors.gold,
                                    foregroundColor: isLight ? Colors.white : Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final allStores = snapshot.data!;
                      final filteredStores = filter == '전체'
                          ? allStores
                          : allStores.where((s) => s.winType == filter).toList();

                      final autoCount = allStores.where((s) => s.winType == '자동').length;
                      final manualCount = allStores.where((s) => s.winType == '수동').length;
                      final semiCount = allStores.where((s) => s.winType == '반자동').length;
                      final hasTypeInfo = autoCount > 0 || manualCount > 0 || semiCount > 0;

                      return Column(
                        children: [
                          // 1. VIP 명당 요약 배너 (오버플로우 방지)
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isLight
                                    ? [const Color(0xFFFFFDF7), const Color(0xFFFFF6E4)]
                                    : [const Color(0xFF24201A), const Color(0xFF1B1814)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: isLight ? 0.45 : 0.35),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: isLight ? 0.08 : 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: (isLight ? AppColors.goldDeep : AppColors.gold).withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    currentRank == 1 ? Icons.emoji_events_rounded : Icons.military_tech_rounded,
                                    size: 18,
                                    color: isLight ? AppColors.goldDeep : AppColors.gold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$currentRank등 배출 명당 총 ${allStores.length}곳',
                                        style: GoogleFonts.notoSansKr(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: isLight ? const Color(0xFF5D4037) : AppColors.goldLight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        '전국 행운의 당첨 지역 집계',
                                        style: GoogleFonts.notoSansKr(
                                          fontSize: 11,
                                          color: AppColors.textHint,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasTypeInfo) ...[
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildMiniTypeBadge('자동', autoCount, const Color(0xFF1E88E5)),
                                          const SizedBox(width: 4),
                                          _buildMiniTypeBadge('수동', manualCount, const Color(0xFF2E7D32)),
                                          if (semiCount > 0) ...[
                                            const SizedBox(width: 4),
                                            _buildMiniTypeBadge('반자동', semiCount, const Color(0xFF7B1FA2)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // 2. 상단 필터 탭 바 (자동/수동 정보가 있는 경우만 노출)
                          if (hasTypeInfo)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip('전체', allStores.length, filter == '전체', isLight, () {
                                      setModalState(() => filter = '전체');
                                    }),
                                    const SizedBox(width: 6),
                                    _buildFilterChip('자동', autoCount, filter == '자동', isLight, () {
                                      setModalState(() => filter = '자동');
                                    }, activeColor: const Color(0xFF1E88E5)),
                                    const SizedBox(width: 6),
                                    _buildFilterChip('수동', manualCount, filter == '수동', isLight, () {
                                      setModalState(() => filter = '수동');
                                    }, activeColor: const Color(0xFF2E7D32)),
                                    if (semiCount > 0) ...[
                                      const SizedBox(width: 6),
                                      _buildFilterChip('반자동', semiCount, filter == '반자동', isLight, () {
                                        setModalState(() => filter = '반자동');
                                      }, activeColor: const Color(0xFF7B1FA2)),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                          // 3. 판매점 리스트
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + MediaQuery.of(context).padding.bottom),
                              itemCount: filteredStores.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, idx) {
                                return WinningStoreCard(
                                  store: filteredStores[idx],
                                  index: idx,
                                  isLight: isLight,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildRankTabButton({
  required String label,
  required bool isSelected,
  required bool isLight,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isLight ? Colors.white : AppColors.gold.withValues(alpha: 0.2))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isLight ? const Color(0xFFD4AF37) : AppColors.gold)
                : Colors.transparent,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (isLight ? AppColors.goldDeep : Colors.white)
                : AppColors.textSecondary,
          ),
        ),
      ),
    ),
  );
}


Widget _buildMiniTypeBadge(String label, int count, Color color) {
  final isLight = AppColors.isLight;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: isLight ? 0.1 : 0.18),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(
        color: color.withValues(alpha: isLight ? 0.3 : 0.4),
        width: 0.9,
      ),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: GoogleFonts.notoSansKr(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isLight ? color : color.withValues(alpha: 0.95),
            ),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: '$count',
            style: GoogleFonts.notoSansKr(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isLight ? color : Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildFilterChip(
  String label,
  int count,
  bool isSelected,
  bool isLight,
  VoidCallback onTap, {
  Color? activeColor,
}) {
  final effectiveColor = activeColor ?? (isLight ? AppColors.goldDeep : AppColors.gold);

  return InkWell(
    onTap: () {
      HapticFeedback.selectionClick();
      onTap();
    },
    borderRadius: BorderRadius.circular(20),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? (isLight ? effectiveColor.withValues(alpha: 0.14) : effectiveColor.withValues(alpha: 0.24))
            : (isLight ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? effectiveColor
              : (isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.1)),
          width: isSelected ? 1.3 : 0.8,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: effectiveColor.withValues(alpha: 0.16),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: label,
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? (isLight ? effectiveColor : Colors.white) : AppColors.textSecondary,
              ),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: '$count',
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? (isLight ? effectiveColor : AppColors.goldLight)
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
