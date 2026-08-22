import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/safe_google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import '../services/dhlottery_api.dart';
import '../services/statistics_service.dart';
import 'common_widgets.dart';
import 'lotto_ball.dart';
import 'qr_scanner_view.dart';

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
    final controller = TextEditingController(text: _result?.drwNo.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '회차 직접 선택',
          style: GoogleFonts.notoSansKr(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '조회할 회차를 입력하세요 (1 ~ $_latestDrwNo회)',
              style: GoogleFonts.notoSansKr(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.rajdhani(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '예: 1158',
                hintStyle: GoogleFonts.rajdhani(color: AppColors.textHint),
                suffixText: '회',
                suffixStyle: GoogleFonts.notoSansKr(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: AppColors.isLight ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.borderGold),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.gold, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소', style: GoogleFonts.notoSansKr(color: AppColors.textHint)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= 1 && val <= _latestDrwNo!) {
                Navigator.pop(ctx);
                _fetchData(val);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('조회', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold)),
          ),
        ],
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SectionTitle(
            title: '당첨 결과 조회',
            subtitle: '동행복권 공식 데이터를 기반으로 합니다.',
            icon: Icons.emoji_events_rounded,
          ),
          const SizedBox(height: 16),

          // QR 스캔 버튼
          _buildQrButton(context),
          const SizedBox(height: 20),

          // 이월 배너 (1등 당첨자 없을 때)
          if (isRollover) ...[
            _buildRolloverBanner(),
            const SizedBox(height: 16),
          ],

          // 메인 당첨 카드
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            borderColor: AppColors.borderGold,
            child: Column(
              children: [
                // 회차 네비게이션 헤더 (이전 회차 < 제 N회 > 다음 회차)
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
                    const SizedBox(width: 4),

                    // 회차 뱃지 (클릭 시 회차 선택 팝업)
                    InkWell(
                      onTap: _showDrawSelectDialog,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '제 ${result.drwNo}회',
                              style: GoogleFonts.rajdhani(
                                color: AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 20,
                              color: AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

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

                // 과거 회차일 때 최신 회차 복귀 버튼
                if (_latestDrwNo != null && result.drwNo != _latestDrwNo!) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _fetchData(_latestDrwNo),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                Text(
                  result.drwNoDate,
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),

                // 당첨 번호
                LottoBallRow(numbers: result.numbers, ballSize: 44),
                const SizedBox(height: 16),

                // 보너스 구분선
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 1, width: 40, color: AppColors.borderSubtle),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.add_circle_outline, color: AppColors.textHint, size: 18),
                    ),
                    Container(height: 1, width: 40, color: AppColors.borderSubtle),
                  ],
                ),
                const SizedBox(height: 16),

                // 보너스 번호
                Column(
                  children: [
                    Text(
                      '보너스',
                      style: GoogleFonts.notoSansKr(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LottoBall(number: result.bonusNo, size: 44),
                  ],
                ),

                const GoldDivider(),

                // 당첨금 정보
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

  Widget _buildQrButton(BuildContext context) {
    return AppColors.isLight
        ? Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB8860B), Color(0xFF92690A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldDark.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const QrScannerView()),
              ),
              icon: const Icon(CupertinoIcons.qrcode_viewfinder, color: Colors.white),
              label: Text(
                'QR 스캔으로 내 당첨 확인하기',
                style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          )
        : ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const QrScannerView()),
            ),
            icon: const Icon(CupertinoIcons.qrcode_viewfinder),
            label: Text(
              'QR 스캔으로 내 당첨 확인하기',
              style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
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

  /// 당첨금 섹션 — 이월 여부에 따라 다르게 표시
  Widget _buildPrizeSection(DHLotteryResult result, bool isRollover, NumberFormat fmt) {
    return Column(
      children: [
        // 1등 당첨자 수
        _buildInfoRow(
          icon: Icons.people_rounded,
          label: '1등 당첨자',
          value: isRollover ? '없음 (이월)' : '${result.firstWinCount}명',
          valueColor: isRollover
              ? const Color(0xFFE85D00)
              : (AppColors.isLight ? AppColors.goldDeep : AppColors.gold),
        ),
        const SizedBox(height: 12),

        if (isRollover) ...[
          // 이월: 적립된 총 금액 강조
          _buildInfoRow(
            icon: Icons.account_balance_rounded,
            label: '이월 적립금 (총)',
            value: fmt.format(result.firstSumWinamnt),
            valueColor: const Color(0xFFE85D00),
            isLarge: true,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 13, color: Color(0xFFE85D00)),
                const SizedBox(width: 6),
                Text(
                  '1등 당첨자가 없어 다음 회차로 이월됩니다.',
                  style: GoogleFonts.notoSansKr(
                    color: const Color(0xFFE85D00),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // 정상: 1인당 당첨금
          _buildInfoRow(
            icon: Icons.emoji_events_rounded,
            label: '1등 1인당 당첨금',
            value: fmt.format(result.firstWinamnt),
            valueColor: AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
            isLarge: true,
          ),
          const SizedBox(height: 12),
          // 1등 총 당첨금
          _buildInfoRow(
            icon: Icons.account_balance_rounded,
            label: '1등 총 당첨금',
            value: fmt.format(result.firstSumWinamnt),
            valueColor: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          // 1등 당첨 유형 및 등위별 상세 분석 확인 버튼 (앱 내 네이티브 팝업)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showWinningDetailModal(context, result, fmt),
              icon: Icon(
                Icons.analytics_outlined,
                size: 18,
                color: AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
              ),
              label: Text(
                '📊 제 ${result.drwNo}회 1등 당첨유형 및 등위별 상세',
                style: GoogleFonts.notoSansKr(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.isLight ? AppColors.goldDeep : AppColors.textPrimary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppColors.isLight ? Colors.white : AppColors.cardHover,
                foregroundColor: AppColors.isLight ? AppColors.goldDeep : AppColors.textPrimary,
                side: BorderSide(
                  color: AppColors.isLight
                      ? AppColors.goldDark.withValues(alpha: 0.5)
                      : AppColors.borderGold,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ],
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

              const SizedBox(height: 16),

              // 1등 배출 판매점(지역) 목록 확인 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openWinningStores(result.drwNo),
                  icon: const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFFE65100)),
                  label: Text(
                    '📍 제 ${result.drwNo}회 1등 당첨 판매점(지역) 목록 확인',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.isLight ? const Color(0xFFE65100) : const Color(0xFFFF9800),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(
                      color: (AppColors.isLight ? const Color(0xFFE65100) : const Color(0xFFFF9800))
                          .withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                    backgroundColor: (AppColors.isLight ? const Color(0xFFFFE0B2) : const Color(0xFFE65100))
                        .withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 확인 버튼
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

  Future<void> _openWinningStores(int drwNo) async {
    final uri = Uri.parse('https://m.dhlottery.co.kr/gameResult.do?method=byWin&drwNo=$drwNo');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching winning stores: $e');
    }
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    bool isLarge = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.textHint, size: 16),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.notoSansKr(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: isLarge
              ? GoogleFonts.rajdhani(color: valueColor, fontSize: 22, fontWeight: FontWeight.w800)
              : GoogleFonts.notoSansKr(color: valueColor, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
