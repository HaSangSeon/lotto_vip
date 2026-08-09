import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import '../services/dhlottery_api.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final res = await DHLotteryApi.fetchLatest();
    if (mounted) {
      setState(() {
        _result = res;
        _isLoading = false;
      });
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
              onPressed: _fetchData,
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
            title: '최신 당첨 결과',
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
                // 회차 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '제 ${result.drwNo}회',
                    style: GoogleFonts.rajdhani(
                      color: AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
        ],
      ),
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
        ],
      ],
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
