import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../services/qr_lottery_parser.dart';
import '../services/dhlottery_api.dart';
import 'lotto_ball.dart';

class GameEvaluation {
  final QRLotteryGame game;
  final int rank; // 1~5, 0 (낙첨), -1 (추첨 전)
  final String rankLabel;
  final int prizeAmount;
  final Set<int> matchedNumbers;
  final bool isBonusMatched;

  const GameEvaluation({
    required this.game,
    required this.rank,
    required this.rankLabel,
    required this.prizeAmount,
    required this.matchedNumbers,
    required this.isBonusMatched,
  });
}

class QrResultSheet extends StatefulWidget {
  final QRLotteryData qrData;
  final DHLotteryResult? drawResult;
  final bool isSavedToHistory;
  final bool isNetworkError;
  final Future<DHLotteryResult?> Function()? onRetry;

  const QrResultSheet({
    super.key,
    required this.qrData,
    required this.drawResult,
    this.isSavedToHistory = true,
    this.isNetworkError = false,
    this.onRetry,
  });

  static Future<void> show(
    BuildContext context, {
    required QRLotteryData qrData,
    required DHLotteryResult? drawResult,
    bool isSavedToHistory = true,
    bool isNetworkError = false,
    Future<DHLotteryResult?> Function()? onRetry,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QrResultSheet(
        qrData: qrData,
        drawResult: drawResult,
        isSavedToHistory: isSavedToHistory,
        isNetworkError: isNetworkError,
        onRetry: onRetry,
      ),
    );
  }

  @override
  State<QrResultSheet> createState() => _QrResultSheetState();
}

class _QrResultSheetState extends State<QrResultSheet> {
  DHLotteryResult? _currentDrawResult;
  bool _isRetrying = false;
  late bool _networkError;

  @override
  void initState() {
    super.initState();
    _currentDrawResult = widget.drawResult;
    _networkError = widget.isNetworkError;
  }

  List<GameEvaluation> _evaluateGames() {
    return widget.qrData.games.map((game) {
      if (_currentDrawResult == null) {
        return GameEvaluation(
          game: game,
          rank: -1,
          rankLabel: '추첨 대기',
          prizeAmount: 0,
          matchedNumbers: {},
          isBonusMatched: false,
        );
      }

      final matched = game.numbers.where((n) => _currentDrawResult!.numbers.contains(n)).toSet();
      final isBonus = game.numbers.contains(_currentDrawResult!.bonusNo);
      final matchCount = matched.length;

      int rank = 0;
      String label = '낙첨';
      int prize = 0;

      if (matchCount == 6) {
        rank = 1;
        label = '🎉 1등 당첨!';
        prize = _currentDrawResult!.firstWinamnt;
      } else if (matchCount == 5 && isBonus) {
        rank = 2;
        label = '🥈 2등 당첨!';
        prize = _currentDrawResult!.rank2Amount > 0 ? _currentDrawResult!.rank2Amount : 50000000;
      } else if (matchCount == 5) {
        rank = 3;
        label = '🥉 3등 당첨!';
        prize = _currentDrawResult!.rank3Amount > 0 ? _currentDrawResult!.rank3Amount : 1500000;
      } else if (matchCount == 4) {
        rank = 4;
        label = '4등 (5만원)';
        prize = _currentDrawResult!.rank4Amount > 0 ? _currentDrawResult!.rank4Amount : 50000;
      } else if (matchCount == 3) {
        rank = 5;
        label = '5등 (5천원)';
        prize = _currentDrawResult!.rank5Amount > 0 ? _currentDrawResult!.rank5Amount : 5000;
      } else {
        rank = 0;
        label = matchCount > 0 ? '$matchCount개 일치 (낙첨)' : '낙첨';
        prize = 0;
      }

      return GameEvaluation(
        game: game,
        rank: rank,
        rankLabel: label,
        prizeAmount: prize,
        matchedNumbers: matched,
        isBonusMatched: isBonus,
      );
    }).toList();
  }

  Future<void> _handleRetry() async {
    if (widget.onRetry == null || _isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      final res = await widget.onRetry!();
      if (mounted) {
        setState(() {
          _currentDrawResult = res;
          _networkError = res == null;
          _isRetrying = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  Future<void> _openOfficialWeb() async {
    try {
      final uri = Uri.parse(widget.qrData.rawUrl.isNotEmpty
          ? widget.qrData.rawUrl
          : 'https://m.dhlottery.co.kr/qr.do?method=winQr&v=${widget.qrData.drwNo}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###');
    final evaluations = _evaluateGames();
    final isDrawn = _currentDrawResult != null;
    final winningGames = evaluations.where((e) => e.rank >= 1 && e.rank <= 5).toList();
    final totalPrize = winningGames.fold<int>(0, (sum, e) => sum + e.prizeAmount);
    final hasWin = winningGames.isNotEmpty;

    final drawDate = widget.qrData.drawDate;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayStr = (drawDate.weekday >= 1 && drawDate.weekday <= 7)
        ? weekdays[drawDate.weekday - 1]
        : '';
    final dateStr = '${drawDate.year}년 ${drawDate.month}월 ${drawDate.day}일 ($weekdayStr)';
    final isPending = !widget.qrData.isDrawnTimePassed && !isDrawn;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppColors.isLight ? AppColors.lightGoldBorder : AppColors.borderGold,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasWin ? AppColors.gold : Colors.black).withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 드래그 핸들
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 14, bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 스크롤 가능한 본문
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 상단 타이틀 & 회차 정보
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPending
                                ? Icons.hourglass_top_rounded
                                : (hasWin ? Icons.celebration_rounded : Icons.qr_code_scanner_rounded),
                            color: hasWin ? AppColors.gold : AppColors.goldText,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '제 ${widget.qrData.drwNo}회 당첨 확인',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.isLight
                              ? const Color(0xFFFFF0C2)
                              : AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.isLight
                                ? const Color(0xFFD4AF37)
                                : AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '총 ${widget.qrData.games.length}게임',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldText,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 당첨 요약 배너 (추첨 전 / 네트워크 오류 / 당첨 / 낙첨 완벽 분기)
                  _buildSummaryBanner(
                    hasWin: hasWin,
                    isDrawn: isDrawn,
                    isPending: isPending,
                    isNetworkError: _networkError,
                    winCount: winningGames.length,
                    totalPrize: totalPrize,
                    fmt: currencyFmt,
                    dateStr: dateStr,
                  ),

                  const SizedBox(height: 14),

                  // 보관함 자동 저장 안내 알림 배너
                  if (widget.isSavedToHistory)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.isLight
                            ? const Color(0xFFE8F8F5)
                            : const Color(0xFF2ECC71).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2ECC71).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF2ECC71), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '스캔한 번호(${widget.qrData.games.length}게임)가 보관함에 안전하게 저장되었습니다.',
                              style: GoogleFonts.notoSansKr(
                                color: AppColors.isLight ? const Color(0xFF145A32) : const Color(0xFFA9DFBF),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // 해당 회차 공식 당첨 번호 카드 (추첨 완료 시)
                  if (_currentDrawResult != null) ...[
                    _buildOfficialDrawCard(_currentDrawResult!),
                    const SizedBox(height: 16),
                  ],

                  // 게임별 번호 및 당첨 상세 리스트
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '스캔한 복권 번호 상세',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isPending)
                        Text(
                          '추첨 후 자동 채점',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...evaluations.map((eval) => _buildGameCard(eval, isDrawn, isPending)),

                  const SizedBox(height: 16),

                  // 하단 액션 버튼 영역
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openOfficialWeb,
                          icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                          label: Text(
                            '동행복권 공식 웹',
                            style: GoogleFonts.notoSansKr(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            foregroundColor: AppColors.textSecondary,
                            side: BorderSide(color: AppColors.borderSubtle),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            backgroundColor: AppColors.isLight ? AppColors.goldDark : AppColors.gold,
                            foregroundColor: AppColors.isLight ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            '확인',
                            style: GoogleFonts.notoSansKr(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 당첨 요약 배너 (모든 상태 대응)
  Widget _buildSummaryBanner({
    required bool hasWin,
    required bool isDrawn,
    required bool isPending,
    required bool isNetworkError,
    required int winCount,
    required int totalPrize,
    required NumberFormat fmt,
    required String dateStr,
  }) {
    // 1. 추첨 전 상태
    if (isPending) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.isLight
                ? const [Color(0xFFEBF5FB), Color(0xFFD6EAF8)]
                : const [Color(0xFF0F2027), Color(0xFF203A43)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF3498DB).withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3498DB).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.access_time_filled_rounded, color: Color(0xFF2980B9), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⏳ 아직 추첨 전인 복권입니다',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.isLight ? const Color(0xFF1B4F72) : const Color(0xFFEBF5FB),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '추첨 예정일: $dateStr 오후 8시 35분경',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.isLight ? const Color(0xFF2E86C1) : const Color(0xFFAED6F1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '번호가 보관함에 저장되었으니, 추첨 후 [보관함] 탭에서 결과를 바로 확인하실 수 있습니다!',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: AppColors.isLight ? const Color(0xFF5D6D7E) : Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 2. 네트워크 오류 상태 (추첨은 지났으나 API 조회 실패)
    if (isNetworkError && !isDrawn) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.isLight ? const Color(0xFFFEF9E7) : const Color(0xFFF39C12).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFF39C12).withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: Color(0xFFD68910), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '당첨 결과를 불러오는 중 연결 지연',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.isLight ? const Color(0xFF7D6608) : const Color(0xFFFAD7A0),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '네트워크 상태를 확인 후 다시 시도해 주세요. 번호는 보관함에 저장되었습니다.',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isRetrying ? null : _handleRetry,
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(_isRetrying ? '조회 중...' : '결과 다시 조회하기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD68910),
                    side: const BorderSide(color: Color(0xFFD68910)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // 3. 당첨인 경우
    if (hasWin) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.isLight
                ? const [Color(0xFFFFF9E6), Color(0xFFFFF0C2)]
                : const [Color(0xFF2A2100), Color(0xFF191400)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.celebration, color: AppColors.gold, size: 22),
                const SizedBox(width: 8),
                Text(
                  '축하합니다! 총 $winCount게임 당첨',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '총 당첨금: ${fmt.format(totalPrize)}원',
              style: GoogleFonts.rajdhani(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.isLight ? AppColors.goldDeep : AppColors.goldLight,
              ),
            ),
          ],
        ),
      ).animate().shimmer(duration: 1500.ms);
    }

    // 4. 낙첨인 경우
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.isLight ? const Color(0xFFF9EBEA) : const Color(0xFFE74C3C).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE74C3C).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.sentiment_dissatisfied_rounded, color: Color(0xFFE74C3C), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '아쉽게도 이번 회차는 낙첨되었습니다',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.isLight ? const Color(0xFF78281F) : const Color(0xFFF5B7B1),
                  ),
                ),
                Text(
                  '다음 회차의 행운을 기원합니다!',
                  style: GoogleFonts.notoSansKr(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 공식 당첨 번호 카드
  Widget _buildOfficialDrawCard(DHLotteryResult res) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGold.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stars_rounded, color: AppColors.goldText, size: 16),
              const SizedBox(width: 6),
              Text(
                '제 ${res.drwNo}회 공식 당첨 번호',
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${res.drwNoDate})',
                style: GoogleFonts.notoSansKr(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...res.numbers.map(
                  (n) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: LottoBall(number: n, size: 28),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('+',
                      style: GoogleFonts.rajdhani(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
                LottoBall(number: res.bonusNo, size: 28, isBonus: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 게임별 번호 카드 (일치 번호 하이라이트 & 등수)
  Widget _buildGameCard(GameEvaluation eval, bool isDrawn, bool isPending) {
    final hasWon = eval.rank >= 1 && eval.rank <= 5;
    final isLight = AppColors.isLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasWon
              ? (isLight ? const Color(0xFFD4AF37) : AppColors.gold)
              : AppColors.borderSubtle.withValues(alpha: 0.5),
          width: hasWon ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hasWon
                      ? (isLight ? const Color(0xFFFFF0C2) : AppColors.gold.withValues(alpha: 0.2))
                      : (isLight ? Colors.grey.shade200 : Colors.white.withValues(alpha: 0.08)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasWon ? AppColors.gold : Colors.transparent,
                  ),
                ),
                child: Text(
                  eval.game.label,
                  style: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: hasWon ? AppColors.goldText : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${eval.game.label} 게임',
                style: GoogleFonts.notoSansKr(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // 등수 뱃지
              _buildRankBadge(eval, isPending),
            ],
          ),
          const SizedBox(height: 12),
          // 공 번호 행 (당첨 번호 일치 시 하이라이트)
          LottoBallRow(
            numbers: eval.game.numbers,
            ballSize: 36,
            matchedNumbers: isDrawn ? eval.matchedNumbers : null,
            bonusNumber: isDrawn ? _currentDrawResult?.bonusNo : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(GameEvaluation eval, bool isPending) {
    final isLight = AppColors.isLight;
    Color bg;
    Color border;
    Color text;

    if (isPending || eval.rank == -1) {
      bg = isLight ? const Color(0xFFEBF5FB) : const Color(0xFF3498DB).withValues(alpha: 0.15);
      border = isLight ? const Color(0xFFAED6F1) : const Color(0xFF3498DB);
      text = isLight ? const Color(0xFF2471A3) : const Color(0xFF85C1E9);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: 1),
        ),
        child: Text(
          '추첨 대기',
          style: GoogleFonts.notoSansKr(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: text,
          ),
        ),
      );
    }

    switch (eval.rank) {
      case 1:
        bg = isLight ? const Color(0xFFFFF3CD) : const Color(0xFFFFD700).withValues(alpha: 0.25);
        border = isLight ? const Color(0xFFFFC107) : const Color(0xFFFFD700);
        text = isLight ? const Color(0xFF8C5D00) : const Color(0xFFFFD700);
        break;
      case 2:
        bg = isLight ? const Color(0xFFEBF5FB) : const Color(0xFF5DADE2).withValues(alpha: 0.25);
        border = isLight ? const Color(0xFF3498DB) : const Color(0xFF5DADE2);
        text = isLight ? const Color(0xFF1B4F72) : const Color(0xFFD6EAF8);
        break;
      case 3:
        bg = isLight ? const Color(0xFFFBEEE6) : const Color(0xFFE59866).withValues(alpha: 0.25);
        border = isLight ? const Color(0xFFE59866) : const Color(0xFFE59866);
        text = isLight ? const Color(0xFF78281F) : const Color(0xFFF5CBA7);
        break;
      case 4:
        bg = isLight ? const Color(0xFFE8F8F5) : const Color(0xFF2ECC71).withValues(alpha: 0.25);
        border = isLight ? const Color(0xFF2ECC71) : const Color(0xFF2ECC71);
        text = isLight ? const Color(0xFF145A32) : const Color(0xFFA9DFBF);
        break;
      case 5:
        bg = isLight ? const Color(0xFFFEF9E7) : const Color(0xFFF39C12).withValues(alpha: 0.25);
        border = isLight ? const Color(0xFFF39C12) : const Color(0xFFF39C12);
        text = isLight ? const Color(0xFF7D6608) : const Color(0xFFFAD7A0);
        break;
      default:
        bg = isLight ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.05);
        border = Colors.transparent;
        text = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        eval.rankLabel,
        style: GoogleFonts.notoSansKr(
          fontSize: 11,
          fontWeight: eval.rank > 0 ? FontWeight.w800 : FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
