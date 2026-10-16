import 'package:flutter/material.dart';
import '../utils/safe_google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../services/dhlottery_api.dart';
import 'common_widgets.dart';
import 'latest_draw/draw_select_dialog.dart';
import 'latest_draw/prize_section_view.dart';
import 'latest_draw/winning_numbers_showcase.dart';
import 'latest_draw/draw_nav_header.dart';

class LatestDrawTab extends StatefulWidget {
  const LatestDrawTab({super.key});

  @override
  State<LatestDrawTab> createState() => _LatestDrawTabState();
}

class _LatestDrawTabState extends State<LatestDrawTab> {
  DHLotteryResult? _result;
  int? _latestDrwNo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData([int? targetDrwNo]) async {
    setState(() => _isLoading = true);
    final res = targetDrwNo == null
        ? await DHLotteryApi.fetchLatest()
        : await DHLotteryApi.fetchByDrawNo(targetDrwNo);

    if (mounted) {
      setState(() {
        _result = res;
        if (targetDrwNo == null && res != null) {
          _latestDrwNo = res.drwNo;
        }
        _isLoading = false;
      });
    }
  }

  void _goToPrevDraw() {
    if (_result != null && _result!.drwNo > 1) {
      _fetchData(_result!.drwNo - 1);
    }
  }

  void _goToNextDraw() {
    if (_result != null && _latestDrwNo != null && _result!.drwNo < _latestDrwNo!) {
      _fetchData(_result!.drwNo + 1);
    }
  }

  void _showDrawSelectDialog() async {
    if (_latestDrwNo == null) return;
    
    final int? selectedNo = await showDialog<int>(
      context: context,
      builder: (ctx) => DrawSelectDialog(
        latestDrwNo: _latestDrwNo!,
        currentDrwNo: _result?.drwNo,
      ),
    );

    if (selectedNo != null) {
      _fetchData(selectedNo);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: AppColors.textHint, size: 64),
            const SizedBox(height: 16),
            Text(
              '당첨 정보를 불러올 수 없습니다.',
              style: GoogleFonts.notoSansKr(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '네트워크 상태를 확인해 주세요.',
              style: GoogleFonts.notoSansKr(
                color: AppColors.textHint,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _fetchData(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                '다시 시도',
                style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.isLight ? AppColors.goldDark : AppColors.gold,
                foregroundColor: AppColors.isLight ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      );
    }

    final formatCurrency = NumberFormat.currency(locale: 'ko_KR', symbol: '₩ ', decimalDigits: 0);
    final result = _result!;
    final isRollover = result.isRollover;
    final isLight = AppColors.isLight;

    return SizedBox.expand(
      child: Stack(
        children: [
          // 상단 은은한 앰비언트 골드 오로라 글로우 효과
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            height: 280,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.15,
                    colors: isLight
                        ? [
                            AppColors.gold.withValues(alpha: 0.22),
                            AppColors.gold.withValues(alpha: 0.06),
                            Colors.transparent,
                          ]
                        : [
                            AppColors.gold.withValues(alpha: 0.14),
                            const Color(0xFF6C3FC5).withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                // 이월 배너 (1등 당첨자 없을 때)
                if (isRollover) ...[
                  _buildRolloverBanner(),
                  const SizedBox(height: 16),
                ],

                // 메인 당첨 카드
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
                  borderColor: AppColors.borderGold,
                  child: Column(
                    children: [
                      // 회차 네비게이션 헤더 & 추첨일
                      DrawNavHeader(
                        result: result,
                        latestDrwNo: _latestDrwNo,
                        onPrevDraw: _goToPrevDraw,
                        onNextDraw: _goToNextDraw,
                        onSelectDraw: _showDrawSelectDialog,
                        onGoLatest: () => _fetchData(_latestDrwNo!),
                      ),
                      const SizedBox(height: 18),

                      // 당첨 번호 & 보너스 번호 프리미엄 쇼케이스
                      WinningNumbersShowcase(result: result),
                      const SizedBox(height: 18),

                      // 당첨금 및 주요 내역 섹션
                      PrizeSectionView(result: result, isRollover: isRollover, fmt: formatCurrency),
                    ],
                  ),
                ),



                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 이월 배너 — 1등 당첨자 없을 때 표시
  Widget _buildRolloverBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withValues(alpha: 0.12),
            const Color(0xFFFF8C42).withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings_rounded, color: Color(0xFFE85D00), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔥 이번 회차 1등 당첨자 없음 — 이월!',
                  style: GoogleFonts.notoSansKr(
                    color: const Color(0xFFE85D00),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '1등 당첨금이 다음 회차로 이월됩니다.\n다음 주 당첨금이 더욱 커집니다!',
                  style: GoogleFonts.notoSansKr(
                    color: const Color(0xFFE85D00).withValues(alpha: 0.75),
                    fontSize: 11,
                    height: 1.5,
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

