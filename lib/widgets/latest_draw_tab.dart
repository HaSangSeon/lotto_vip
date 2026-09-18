import 'package:flutter/material.dart';
import '../utils/safe_google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../services/dhlottery_api.dart';
import 'common_widgets.dart';
import 'lotto_ball.dart';
import 'latest_draw/draw_select_dialog.dart';
import 'latest_draw/prize_section_view.dart';

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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isLight
              ? [
                  const Color(0xFFFBF8F2),
                  const Color(0xFFF4ECE1),
                  const Color(0xFFEFE6D6),
                ]
              : [
                  const Color(0xFF10131E),
                  const Color(0xFF0C0E16),
                  const Color(0xFF08090E),
                ],
        ),
      ),
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
                      _buildDrawHeader(result),
                      const SizedBox(height: 18),

                      // 당첨 번호 & 보너스 번호 프리미엄 쇼케이스
                      _buildWinningNumbersShowcase(result),
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

  /// 회차 네비게이션 헤더 및 추첨일 칩
  Widget _buildDrawHeader(DHLotteryResult result) {
    final isLight = AppColors.isLight;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 이전 회차 버튼
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: (_result!.drwNo > 1)
                  ? (isLight ? AppColors.goldDeep : AppColors.gold)
                  : AppColors.textHint.withValues(alpha: 0.2),
              onPressed: (_result!.drwNo > 1) ? _goToPrevDraw : null,
              tooltip: '이전 회차',
            ),
            const SizedBox(width: 8),

            // 회차 뱃지 (클릭 시 회차 직접 입력 팝업)
            InkWell(
              onTap: _showDrawSelectDialog,
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
              color: (_latestDrwNo != null && _result!.drwNo < _latestDrwNo!)
                  ? (isLight ? AppColors.goldDeep : AppColors.gold)
                  : AppColors.textHint.withValues(alpha: 0.2),
              onPressed: (_latestDrwNo != null && _result!.drwNo < _latestDrwNo!) ? _goToNextDraw : null,
              tooltip: '다음 회차',
            ),
          ],
        ),

        // 최신 회차가 아닐 때 "최신 회차로 바로가기" 버튼
        if (_latestDrwNo != null && result.drwNo < _latestDrwNo!) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _fetchData(_latestDrwNo!),
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
                    '최신 제 $_latestDrwNo회로 이동',
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

  /// 당첨 번호 & 보너스 번호 통합 쇼케이스 박스
  Widget _buildWinningNumbersShowcase(DHLotteryResult result) {
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
