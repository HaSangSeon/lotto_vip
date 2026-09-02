import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/safe_google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../services/dhlottery_api.dart';
import '../services/statistics_service.dart';
import 'common_widgets.dart';
import 'lotto_ball.dart';

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

  void _showDrawSelectDialog() {
    if (_latestDrwNo == null) return;
    final isLight = AppColors.isLight;
    final controller = TextEditingController(text: _result?.drwNo.toString() ?? '');
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          void submit() {
            final val = int.tryParse(controller.text.trim());
            if (val != null && val >= 1 && val <= _latestDrwNo!) {
              Navigator.pop(ctx);
              _fetchData(val);
            } else {
              setDialogState(() {
                errorText = '1 ~ $_latestDrwNo 사이의 숫자를 입력해 주세요.';
              });
            }
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isLight
                      ? AppColors.lightGoldBorder.withValues(alpha: 0.7)
                      : AppColors.borderGold,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 상단 헤더 (아이콘 + 타이틀 + 닫기 버튼)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isLight ? AppColors.goldDeep : AppColors.gold)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_calendar_rounded,
                          size: 18,
                          color: isLight ? AppColors.goldDeep : AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '회차 직접 선택',
                              style: GoogleFonts.notoSansKr(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 16.5,
                              ),
                            ),
                            Text(
                              '1회 ~ 최신 $_latestDrwNo회 조회',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 11.5,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: AppColors.textSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: isLight
                        ? Colors.black.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: 16),

                  // 빠른 선택 칩
                  Row(
                    children: [
                      _buildQuickChip('최신 회차', isLight, () {
                        controller.text = _latestDrwNo.toString();
                        setDialogState(() => errorText = null);
                      }),
                      const SizedBox(width: 6),
                      _buildQuickChip('1,000회', isLight, () {
                        controller.text = '1000';
                        setDialogState(() => errorText = null);
                      }),
                      const SizedBox(width: 6),
                      _buildQuickChip('1,200회', isLight, () {
                        controller.text = '1200';
                        setDialogState(() => errorText = null);
                      }),
                      const SizedBox(width: 6),
                      _buildQuickChip('1회', isLight, () {
                        controller.text = '1';
                        setDialogState(() => errorText = null);
                      }),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 회차 입력 필드
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    onSubmitted: (_) => submit(),
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                    style: GoogleFonts.rajdhani(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isLight ? AppColors.goldDeep : AppColors.gold,
                      letterSpacing: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: '회차 번호 입력',
                      hintStyle: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        color: AppColors.textHint,
                        letterSpacing: 0,
                      ),
                      suffixText: '회',
                      suffixStyle: GoogleFonts.notoSansKr(
                        color: isLight ? AppColors.goldDeep : AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: isLight
                          ? const Color(0xFFF9F7F2)
                          : Colors.white.withValues(alpha: 0.04),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isLight
                              ? AppColors.lightGoldBorder.withValues(alpha: 0.5)
                              : AppColors.borderGold.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isLight ? AppColors.goldDeep : AppColors.gold,
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),

                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11.5,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 하단 버튼 영역 (취소 / 조회)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: BorderSide(
                              color: isLight
                                  ? Colors.grey.shade300
                                  : Colors.white.withValues(alpha: 0.15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            '취소',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLight
                                ? AppColors.goldDark
                                : AppColors.gold,
                            foregroundColor:
                                isLight ? Colors.white : Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            '조회하기',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickChip(String label, bool isLight, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isLight
                ? Colors.black.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isLight
                  ? Colors.black.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
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

    final formatCurrency = NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0);
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
                      _buildPrizeSection(result, isRollover, formatCurrency),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 역대 누적 통계 분석 (HOT & COLD)
                _buildStatisticsSection(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 역대 누적 번호 통계 분석 카드
  Widget _buildStatisticsSection() {
    final hotNumbers = StatisticsService.getHotNumbers(5);
    final coldNumbers = StatisticsService.getColdNumbers(5);
    final isLight = AppColors.isLight;

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      borderColor: AppColors.borderGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: AppColors.goldText, size: 20),
              const SizedBox(width: 8),
              Text(
                '역대 번호 출현 통계',
                style: GoogleFonts.notoSansKr(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFFFF0C2)
                      : AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLight
                        ? const Color(0xFFD4AF37)
                        : AppColors.gold.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '1회 ~ 현재 누적',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // HOT 번호
          _buildStatGroup(
            'HOT 가장 많이 나온 번호',
            hotNumbers,
            const Color(0xFFE74C3C),
            Icons.local_fire_department_rounded,
          ),

          const SizedBox(height: 18),
          Divider(
            color: isLight
                ? AppColors.lightGoldBorder.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.08),
            height: 1,
          ),
          const SizedBox(height: 18),

          // COLD 번호
          _buildStatGroup(
            'COLD 가장 적게 나온 번호',
            coldNumbers,
            const Color(0xFF3498DB),
            Icons.ac_unit_rounded,
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.black.withValues(alpha: 0.03)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textHint, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '역대 동행복권 1등 당첨 데이터 기준 (보너스 번호 제외)',
                    style: GoogleFonts.notoSansKr(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGroup(
    String title,
    List<MapEntry<int, int>> data,
    Color accentColor,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accentColor, size: 17),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.notoSansKr(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: data.map((entry) {
            return Column(
              children: [
                LottoBall(number: entry.key, size: 38),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${entry.value}회',
                    style: GoogleFonts.rajdhani(
                      color: AppColors.isLight ? accentColor : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 이전 회차 버튼
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
              color: (_result!.drwNo > 1)
                  ? (AppColors.isLight ? AppColors.goldDeep : AppColors.gold)
                  : AppColors.textHint.withValues(alpha: 0.3),
              onPressed: (_result!.drwNo > 1) ? _goToPrevDraw : null,
              tooltip: '이전 회차',
            ),
            const SizedBox(width: 6),

            // 회차 뱃지 (클릭 시 회차 직접 입력 팝업)
            InkWell(
              onTap: _showDrawSelectDialog,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.isLight
                        ? [const Color(0xFFFFF7E6), const Color(0xFFFFE6B3)]
                        : [AppColors.gold.withValues(alpha: 0.2), AppColors.goldDark.withValues(alpha: 0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.isLight ? AppColors.lightGoldBorder : AppColors.gold.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '제 ${result.drwNo}회',
                      style: GoogleFonts.rajdhani(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.goldText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.edit_calendar_rounded,
                      size: 15,
                      color: AppColors.goldText.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // 다음 회차 버튼
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              color: (_latestDrwNo != null && _result!.drwNo < _latestDrwNo!)
                  ? (AppColors.isLight ? AppColors.goldDeep : AppColors.gold)
                  : AppColors.textHint.withValues(alpha: 0.3),
              onPressed: (_latestDrwNo != null && _result!.drwNo < _latestDrwNo!) ? _goToNextDraw : null,
              tooltip: '다음 회차',
            ),
          ],
        ),

        // 최신 회차가 아닐 때 "최신 회차로 바로가기" 버튼
        if (_latestDrwNo != null && result.drwNo < _latestDrwNo!) ...[
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _fetchData(_latestDrwNo!),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: 14, color: AppColors.isLight ? AppColors.goldDeep : AppColors.gold),
                  const SizedBox(width: 4),
                  Text(
                    '최신 제 $_latestDrwNo회로 이동',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.isLight ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${result.drwNoDate} 추첨',
            style: GoogleFonts.notoSansKr(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF9F7F1) : const Color(0xFF0F121C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight ? AppColors.lightGoldBorder.withValues(alpha: 0.4) : AppColors.borderGold.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 6개 당첨 번호 라벨
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '당첨 번호',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isLight ? AppColors.goldDeep : AppColors.gold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LottoBallRow(numbers: result.numbers, ballSize: 42),
          const SizedBox(height: 16),

          // 보너스 번호 칩
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: isLight ? const Color(0xFFE65100) : const Color(0xFFFF9800),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isLight ? const Color(0xFFE65100) : const Color(0xFFFF9800)).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '보너스',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isLight ? const Color(0xFFE65100) : const Color(0xFFFF9800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                LottoBall(number: result.bonusNo, size: 38, isBonus: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 당첨금 및 상세 내역 섹션
  Widget _buildPrizeSection(DHLotteryResult result, bool isRollover, NumberFormat fmt) {
    final isLight = AppColors.isLight;
    final hasTypeData = result.winTypeAuto > 0 || result.winTypeManual > 0 || result.winTypeSemi > 0;
    final firstWinAmount = isRollover ? result.firstSumWinamnt : result.firstWinamnt;
    final approxBillions = (firstWinAmount / 100000000).toStringAsFixed(1);
    final totalApproxBillions = (result.firstSumWinamnt / 100000000).toStringAsFixed(1);

    return Column(
      children: [
        // 1. 1등 당첨금 메인 하이라이트 카드 (Hero Prize Card)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isRollover
                  ? [
                      const Color(0xFFFF6B35).withValues(alpha: 0.15),
                      const Color(0xFFFF8C42).withValues(alpha: 0.08)
                    ]
                  : (isLight
                      ? [
                          const Color(0xFFFFFBF0),
                          const Color(0xFFFFF5D9),
                        ]
                      : [
                          AppColors.gold.withValues(alpha: 0.18),
                          AppColors.goldDark.withValues(alpha: 0.08),
                        ]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRollover
                  ? const Color(0xFFFF6B35).withValues(alpha: 0.45)
                  : (isLight ? const Color(0xFFE2B747).withValues(alpha: 0.6) : AppColors.gold.withValues(alpha: 0.45)),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: (isRollover ? const Color(0xFFFF6B35) : AppColors.gold).withValues(alpha: isLight ? 0.08 : 0.14),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 라벨 & 당첨자 수 뱃지
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isRollover
                              ? const Color(0xFFFF6B35).withValues(alpha: 0.2)
                              : (isLight ? const Color(0xFFFFE8A3) : AppColors.gold.withValues(alpha: 0.2)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRollover ? Icons.savings_rounded : Icons.emoji_events_rounded,
                          color: isRollover
                              ? const Color(0xFFE85D00)
                              : (isLight ? AppColors.goldDeep : AppColors.gold),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isRollover ? '이월 누적 적립금' : '1등 당첨금 (1인당)',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isRollover
                              ? const Color(0xFFE85D00)
                              : (isLight ? AppColors.goldDeep : AppColors.goldLight),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: isRollover
                          ? const Color(0xFFE85D00).withValues(alpha: 0.15)
                          : (isLight ? const Color(0xFFE8F8F5) : const Color(0xFF2ECC71).withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isRollover
                            ? const Color(0xFFE85D00).withValues(alpha: 0.3)
                            : (isLight ? const Color(0xFF2ECC71).withValues(alpha: 0.5) : const Color(0xFF2ECC71).withValues(alpha: 0.5)),
                        width: 0.9,
                      ),
                    ),
                    child: Text(
                      isRollover ? '당첨자 없음' : '🎯 ${result.firstWinCount}명 당첨',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isRollover
                            ? const Color(0xFFE85D00)
                            : (isLight ? const Color(0xFF145A32) : const Color(0xFFA9DFBF)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 중앙 메인 금액 (FittedBox로 자동 줄바꿈 원천 차단)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  fmt.format(firstWinAmount),
                  style: GoogleFonts.rajdhani(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    height: 1.05,
                    color: isRollover
                        ? const Color(0xFFE85D00)
                        : (isLight ? const Color(0xFF7A4F01) : const Color(0xFFFFD700)),
                  ),
                ),
              ),

              if (!isRollover && firstWinAmount >= 100000000) ...[
                const SizedBox(height: 9),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFFFEECC) : AppColors.gold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isLight ? const Color(0xFFE2B747).withValues(alpha: 0.6) : AppColors.gold.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '약 $approxBillions억 원',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isLight ? const Color(0xFF7A4F01) : AppColors.goldLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '총 ${result.firstWinCount}명에게 각 $approxBillions억 원씩 균등 지급',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. 통합 주요 내역 카드 (1등 총 당첨금 + 1등 배출 방식 단일 일체형 카드)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF131724),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isLight
                  ? AppColors.lightGoldBorder.withValues(alpha: 0.35)
                  : AppColors.borderGold.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1행: 1등 총 당첨금
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 14,
                      color: isLight ? AppColors.goldDeep : AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '1등 총 당첨금',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fmt.format(result.firstSumWinamnt),
                        style: GoogleFonts.rajdhani(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: isLight ? const Color(0xFF2C2520) : Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (result.firstSumWinamnt >= 100000000) ...[
                        const SizedBox(height: 1),
                        Text(
                          '총 약 $totalApproxBillions억 원',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  thickness: 0.8,
                  color: isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.08),
                ),
              ),

              // 2행: 1등 배출 방식
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFE8F0FE) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 14,
                      color: isLight ? const Color(0xFF1967D2) : const Color(0xFF8AB4F8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '1등 배출 방식',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (hasTypeData)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMiniTypeBadge('자동', result.winTypeAuto, const Color(0xFF1976D2)),
                        const SizedBox(width: 6),
                        _buildMiniTypeBadge('수동', result.winTypeManual, const Color(0xFF2E7D32)),
                        if (result.winTypeSemi > 0) ...[
                          const SizedBox(width: 6),
                          _buildMiniTypeBadge('반자동', result.winTypeSemi, const Color(0xFF7B1FA2)),
                        ],
                      ],
                    )
                  else
                    Text(
                      '구분 미제공',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 3. 1등 당첨 판매점(지역) 목록 확인 버튼
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFFFF8EE) : const Color(0xFF1E1A17),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight
                    ? const Color(0xFFFFB74D).withValues(alpha: 0.6)
                    : const Color(0xFFFF9800).withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.02 : 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showWinningStoresModal(context, result.drwNo),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFFE65100)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '제 ${result.drwNo}회 1등 당첨 판매점(지역) 확인',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isLight ? const Color(0xFFC04B00) : const Color(0xFFFFB74D),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: isLight ? const Color(0xFFC04B00) : const Color(0xFFFFB74D),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 4. 1등~5등 전체 등위별 상세 결과 확인 버튼
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              color: isLight ? Colors.white : AppColors.cardHover,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight
                    ? AppColors.lightGoldBorder.withValues(alpha: 0.45)
                    : AppColors.borderGold.withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.02 : 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showWinningDetailModal(context, result, fmt),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: (isLight ? AppColors.goldDeep : AppColors.gold).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.analytics_outlined,
                          size: 15,
                          color: isLight ? AppColors.goldDeep : AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '제 ${result.drwNo}회 등위별 상세 결과 및 상금 기준',
                        style: GoogleFonts.notoSansKr(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isLight ? AppColors.goldDeep : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: isLight ? AppColors.goldDeep : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isLight ? color : color.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isLight ? color : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showWinningDetailModal(BuildContext context, DHLotteryResult result, NumberFormat fmt) {
    final numFmt = NumberFormat.decimalPattern();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.isLight ? AppColors.lightGoldBorder : AppColors.borderGold,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.15),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 드래그 핸들
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 헤더 타이틀
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '제 ${result.drwNo}회 당첨 상세 분석',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '추첨일: ${result.drwNoDate}',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 18),

              // 1. 1등 당첨 유형 (자동 / 수동 / 반자동)
              Text(
                '1등 당첨 배출 유형 (총 ${result.firstWinCount}명)',
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
                ),
              ),
              const SizedBox(height: 10),
              if (result.firstWinCount > 0 && result.winTypeAuto == 0 && result.winTypeManual == 0 && result.winTypeSemi == 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.isLight ? const Color(0xFFF9F7F1) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textHint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '💡 261회 이전 과거 회차는 동행복권 공식 시스템에 자동/수동 구분 집계 데이터가 도입되기 전이므로 미제공(0명)으로 표기됩니다.',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeCard(
                        '자동',
                        '${result.winTypeAuto}명',
                        const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTypeCard(
                        '수동',
                        '${result.winTypeManual}명',
                        const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTypeCard(
                        '반자동',
                        '${result.winTypeSemi}명',
                        const Color(0xFF6C3FC5),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // 2. 등위별 상세 당첨 현황표
              Text(
                '등위별 당첨 기준 & 상금 결과',
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '추첨된 번호 6개와 보너스 번호의 일치 개수에 따라 등수가 결정됩니다.',
                style: GoogleFonts.notoSansKr(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.isLight ? const Color(0xFFF9F7F1) : AppColors.cardHover,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _buildRankRow('1등', '🎯 번호 6개 모두 일치', fmt.format(result.firstWinamnt), '${numFmt.format(result.firstWinCount)}명', isFirst: true),
                    Divider(height: 1, color: AppColors.borderSubtle),
                    _buildRankRow('2등', '🎯 번호 5개 + 보너스번호 일치', fmt.format(result.rank2Amount), '${numFmt.format(result.rank2Count)}명'),
                    Divider(height: 1, color: AppColors.borderSubtle),
                    _buildRankRow('3등', '🎯 번호 5개 일치', fmt.format(result.rank3Amount), '${numFmt.format(result.rank3Count)}명'),
                    Divider(height: 1, color: AppColors.borderSubtle),
                    _buildRankRow('4등', '🎯 번호 4개 일치 (고정 5만원)', fmt.format(result.rank4Amount > 0 ? result.rank4Amount : 50000), '${numFmt.format(result.rank4Count)}명'),
                    Divider(height: 1, color: AppColors.borderSubtle),
                    _buildRankRow('5등', '🎯 번호 3개 일치 (고정 5천원)', fmt.format(result.rank5Amount > 0 ? result.rank5Amount : 5000), '${numFmt.format(result.rank5Count)}명', isLast: true),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 등수 결정 기준 친절 안내 박스
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.isLight
                        ? AppColors.lightGoldBorder.withValues(alpha: 0.3)
                        : AppColors.borderGold.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: AppColors.isLight ? AppColors.goldDark : AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '로또 등수 결정 기준 (상식)',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• 1등~5등은 각각 다른 번호가 아니라, 메인 화면에 나온 [당첨 번호 6개 + 보너스 번호 1개]와 내가 가진 번호가 몇 개 일치하는지로 판정됩니다.\n• 2등은 5개 번호와 함께 [보너스 번호]까지 맞아야 당첨됩니다.',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 확인 닫기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.isLight ? AppColors.goldDark : AppColors.gold,
                    foregroundColor: AppColors.isLight ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('확인', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWinningStoresModal(BuildContext context, int drwNo) {
    final isLight = AppColors.isLight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String filter = '전체';

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
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
                  const SizedBox(height: 14),

                  // 모달 헤더 (아이콘 + 타이틀 + 닫기 버튼)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE65100).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFFE65100)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '제 $drwNo회 1등 당첨 판매점',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '동행복권 공식 1등 배출점 목록',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.textSecondary,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.08),
                  ),

                  // 판매점 비동기 데이터 목록
                  Expanded(
                    child: FutureBuilder<List<DHLotteryWinningStore>>(
                      future: DHLotteryApi.fetchWinningStores(drwNo),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(color: AppColors.gold),
                                const SizedBox(height: 16),
                                Text(
                                  '제 $drwNo회 1등 판매점을 불러오는 중...',
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
                                    '1등 판매점 정보를 불러올 수 없습니다.',
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

                        return Column(
                          children: [
                            // 상단 필터 칩 (전체, 자동, 수동, 반자동)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Row(
                                children: [
                                  _buildFilterChip('전체', allStores.length, filter == '전체', isLight, () {
                                    setModalState(() => filter = '전체');
                                  }),
                                  const SizedBox(width: 6),
                                  _buildFilterChip('자동', autoCount, filter == '자동', isLight, () {
                                    setModalState(() => filter = '자동');
                                  }, activeColor: const Color(0xFF1976D2)),
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

                            // 판매점 리스트
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                                itemCount: filteredStores.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, idx) {
                                  final store = filteredStores[idx];
                                  final Color typeColor = store.winType == '수동'
                                      ? const Color(0xFF2E7D32)
                                      : (store.winType == '반자동'
                                          ? const Color(0xFF7B1FA2)
                                          : const Color(0xFF1976D2));

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isLight ? const Color(0xFFFBF9F4) : AppColors.cardHover,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.06),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 1열: [좌측: 순번 + 상호명] - [중앙: 배출방식] - [우측: 주소 복사 버튼]
                                        Row(
                                          children: [
                                            // 좌측: 순번 + 상호명
                                            Expanded(
                                              flex: 5,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 22,
                                                    height: 22,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: (isLight ? AppColors.goldDeep : AppColors.gold).withValues(alpha: 0.12),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Text(
                                                      '${idx + 1}',
                                                      style: GoogleFonts.rajdhani(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w800,
                                                        color: isLight ? AppColors.goldDeep : AppColors.gold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      store.name,
                                                      style: GoogleFonts.notoSansKr(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.textPrimary,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // 중앙: 배출 유형 뱃지 (자동 / 수동 / 반자동)
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: typeColor.withValues(alpha: isLight ? 0.12 : 0.22),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: typeColor.withValues(alpha: 0.4),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Text(
                                                  store.winType,
                                                  style: GoogleFonts.notoSansKr(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: typeColor,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // 우측: 주소 복사 버튼 (아이콘 + 텍스트 명시)
                                            Expanded(
                                              flex: 3,
                                              child: Align(
                                                alignment: Alignment.centerRight,
                                                child: InkWell(
                                                  onTap: () {
                                                    Clipboard.setData(ClipboardData(text: store.address));
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('${store.name} 주소가 복사되었습니다.'),
                                                        duration: const Duration(seconds: 2),
                                                        behavior: SnackBarBehavior.floating,
                                                      ),
                                                    );
                                                  },
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                                                    decoration: BoxDecoration(
                                                      color: isLight ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.08),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: isLight ? Colors.black.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.15),
                                                        width: 0.8,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.copy_rounded, size: 11, color: AppColors.textSecondary),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '주소 복사',
                                                          style: GoogleFonts.notoSansKr(
                                                            fontSize: 10.5,
                                                            fontWeight: FontWeight.w600,
                                                            color: AppColors.textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 8),

                                        // 2열: 도로명 상세 주소
                                        Padding(
                                          padding: const EdgeInsets.only(left: 30),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.place_outlined, size: 13, color: AppColors.textHint),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  store.address,
                                                  style: GoogleFonts.notoSansKr(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withValues(alpha: isLight ? 0.12 : 0.22)
              : (isLight ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? effectiveColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? effectiveColor : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: GoogleFonts.rajdhani(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? effectiveColor : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(String title, String count, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankRow(String rank, String condition, String prize, String count, {bool isFirst = false, bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isFirst
                  ? (AppColors.isLight ? AppColors.gold.withValues(alpha: 0.25) : AppColors.gold.withValues(alpha: 0.2))
                  : (AppColors.isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rank,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isFirst
                    ? (AppColors.isLight ? AppColors.goldDeep : AppColors.gold)
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prize,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isFirst
                        ? (AppColors.isLight ? AppColors.goldDeep : AppColors.gold)
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  condition,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    color: isFirst
                        ? (AppColors.isLight ? AppColors.goldDark : AppColors.goldLight)
                        : AppColors.textSecondary,
                    fontWeight: isFirst ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                count,
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '당첨자',
                style: GoogleFonts.notoSansKr(
                  fontSize: 10,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
