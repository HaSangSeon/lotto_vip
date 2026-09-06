import 'dart:math';
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
      useSafeArea: true,
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
        label = '🥇 1등 당첨!';
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
        label = matchCount > 0 ? '$matchCount개 일치' : '낙첨';
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
    final isLight = AppColors.isLight;
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

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight
                ? const [Color(0xFFFFFDF8), Color(0xFFF9F5EC)]
                : const [Color(0xFF161922), Color(0xFF0F1118)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isLight
                ? AppColors.lightGoldBorder.withValues(alpha: 0.4)
                : AppColors.borderGold.withValues(alpha: 0.55),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (hasWin ? AppColors.gold : Colors.black).withValues(alpha: isLight ? 0.15 : 0.4),
              blurRadius: 32,
              spreadRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 드래그 핸들
            Container(
              width: 44,
              height: 4.5,
              margin: const EdgeInsets.only(top: 12, bottom: 10),
              decoration: BoxDecoration(
                color: isLight
                    ? const Color(0xFFD4C8B4)
                    : Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // 스크롤 가능한 본문 영역
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. 헤더: 타이틀 + 뱃지 + 닫기 버튼
                    _buildHeader(isLight, weekdayStr, hasWin),

                    const SizedBox(height: 14),

                    // 2. 통합 프리미엄 상태 히어로 카드 (낙첨/보관함 알림 분리 대신 하나의 일체형 VIP 카드로 통합)
                    _buildUnifiedHeroCard(
                      hasWin: hasWin,
                      isDrawn: isDrawn,
                      isPending: isPending,
                      isNetworkError: _networkError,
                      winCount: winningGames.length,
                      totalPrize: totalPrize,
                      fmt: currencyFmt,
                      dateStr: dateStr,
                      isLight: isLight,
                    ),

                    const SizedBox(height: 16),

                    // 3. 해당 회차 공식 당첨 번호 카드 (추첨 완료 시 표시)
                    if (_currentDrawResult != null) ...[
                      _buildOfficialDrawCard(_currentDrawResult!, isLight),
                      const SizedBox(height: 16),
                    ],

                    // 4. 스캔한 게임 목록 섹션 타이틀
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.format_list_bulleted_rounded,
                              size: 16,
                              color: AppColors.goldText,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '스캔한 복권 번호 상세',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (isPending)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isLight
                                  ? const Color(0xFFEBF5FB)
                                  : const Color(0xFF3498DB).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '추첨 후 자동 채점',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 11,
                                color: isLight ? const Color(0xFF2471A3) : const Color(0xFF85C1E9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Text(
                            '일치 번호 하이라이트',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 게임별 번호 카드 리스트 (A ~ E)
                    ...evaluations.map((eval) => _buildGameCard(eval, isDrawn, isPending, isLight)),

                    const SizedBox(height: 18),

                    // 5. 하단 액션 버튼 영역 (공식 웹 링크 & 확인 버튼)
                    _buildActionButtons(context, isLight),

                    // 안드로이드 3버튼 내비게이션 바 안전 여백 보장
                    SizedBox(height: max(16.0, MediaQuery.of(context).padding.bottom + 8.0)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. 헤더: 타이틀 & 회차 정보 & 닫기(X) 버튼
  Widget _buildHeader(bool isLight, String weekdayStr, bool hasWin) {
    return Row(
      children: [
        // 회차 & 스캔 아이콘 컨테이너
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasWin
                ? (isLight ? const Color(0xFFFFF0C2) : AppColors.gold.withValues(alpha: 0.18))
                : (isLight ? const Color(0xFFF2ECE1) : Colors.white.withValues(alpha: 0.08)),
            border: Border.all(
              color: hasWin
                  ? AppColors.gold
                  : (isLight ? AppColors.lightGoldBorder.withValues(alpha: 0.3) : AppColors.borderSubtle),
              width: 1.2,
            ),
          ),
          child: Icon(
            hasWin ? Icons.celebration_rounded : Icons.qr_code_scanner_rounded,
            color: hasWin ? AppColors.goldText : (isLight ? AppColors.goldDeep : AppColors.gold),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '제 ${widget.qrData.drwNo}회 당첨 결과',
                style: GoogleFonts.notoSansKr(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLight
                          ? const Color(0xFFEDE5D5)
                          : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '총 ${widget.qrData.games.length}게임',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.qrData.drwNo}회 로또 복권',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 닫기(X) 원형 버튼
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: isLight
                ? Colors.black.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.08),
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.all(8),
            minimumSize: const Size(36, 36),
          ),
        ),
      ],
    );
  }

  /// 2. 통합 프리미엄 VIP 히어로 카드 (상태 + 보관함 저장 완료 일체형 디자인)
  Widget _buildUnifiedHeroCard({
    required bool hasWin,
    required bool isDrawn,
    required bool isPending,
    required bool isNetworkError,
    required int winCount,
    required int totalPrize,
    required NumberFormat fmt,
    required String dateStr,
    required bool isLight,
  }) {
    // A. 당첨 상태
    if (hasWin) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLight
                ? const [Color(0xFFFFF8E5), Color(0xFFFFF0C2)]
                : const [Color(0xFF2C2208), Color(0xFF191404)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gold,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: isLight ? 0.2 : 0.35),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.military_tech_rounded, color: AppColors.gold, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '축하합니다! 총 $winCount게임 당첨',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isLight ? AppColors.goldDeep : AppColors.gold,
                        ),
                      ),
                      Text(
                        '가까운 판매점 및 농협에서 당첨금을 수령하세요!',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11.5,
                          color: isLight ? const Color(0xFF6E4D08) : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isLight
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '총 당첨금액',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${fmt.format(totalPrize)}원',
                    style: GoogleFonts.rajdhani(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isLight ? AppColors.goldDeep : AppColors.goldLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isSavedToHistory) ...[
              const SizedBox(height: 12),
              _buildInlineStorageChip(
                isLight: isLight,
                accentColor: isLight ? const Color(0xFF8C6514) : AppColors.gold,
                text: '스캔한 번호(${widget.qrData.games.length}게임)가 보관함에 안전하게 저장되었습니다.',
              ),
            ],
          ],
        ),
      ).animate().shimmer(duration: 1600.ms);
    }

    // B. 추첨 전 상태 (Pending)
    if (isPending) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLight
                ? const [Color(0xFFEBF5FB), Color(0xFFD6EAF8)]
                : const [Color(0xFF0F1E32), Color(0xFF0A1322)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF3498DB).withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498DB).withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.access_time_filled_rounded, color: Color(0xFF3498DB), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '아직 추첨 전인 복권입니다',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isLight ? const Color(0xFF1B4F72) : const Color(0xFFEBF5FB),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '추첨 예정일: $dateStr 오후 8시 35분경',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isLight ? const Color(0xFF2874A6) : const Color(0xFFAED6F1),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '추첨 완료 후 [보관함] 탭에서 자동으로 채점 결과를 확인하실 수 있습니다.',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11,
                          color: isLight ? const Color(0xFF5D6D7E) : Colors.white60,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.isSavedToHistory) ...[
              const SizedBox(height: 12),
              _buildInlineStorageChip(
                isLight: isLight,
                accentColor: const Color(0xFF3498DB),
                text: '번호가 보관함에 등록되었습니다. 추첨 당일 알림을 받으실 수 있습니다.',
              ),
            ],
          ],
        ),
      );
    }

    // C. 네트워크 오류 상태
    if (isNetworkError && !isDrawn) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLight
                ? const [Color(0xFFFEF9E7), Color(0xFFFCF3CF)]
                : const [Color(0xFF251C0E), Color(0xFF191307)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF39C12).withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: Color(0xFFD68910), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '당첨 결과 조회 연결 지연',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isLight ? const Color(0xFF7D6608) : const Color(0xFFFAD7A0),
                        ),
                      ),
                      Text(
                        '네트워크 상태를 확인 후 다시 시도해 주세요.',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 12),
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
                  label: Text(
                    _isRetrying ? '조회 중...' : '당첨 결과 다시 조회하기',
                    style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    foregroundColor: const Color(0xFFD68910),
                    side: const BorderSide(color: Color(0xFFD68910)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            if (widget.isSavedToHistory) ...[
              const SizedBox(height: 10),
              _buildInlineStorageChip(
                isLight: isLight,
                accentColor: const Color(0xFFD68910),
                text: '스캔한 번호는 보관함에 안전하게 임시 저장되었습니다.',
              ),
            ],
          ],
        ),
      );
    }

    // D. 낙첨 상태 (고급스러운 흑단/로즈골드 무드 카드 + 보관함 일체형)
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? const [Color(0xFFFFF7F6), Color(0xFFFAF0EF)]
              : const [Color(0xFF1E171B), Color(0xFF151117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE57373).withValues(alpha: 0.35)
              : const Color(0xFFE57373).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFE57373),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '아쉽게도 이번 회차는 낙첨되었습니다',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isLight ? const Color(0xFF8A2E24) : const Color(0xFFF7C5C0),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '다음 회차에는 더 큰 행운이 함께하길 기원합니다!',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.isSavedToHistory) ...[
            const SizedBox(height: 12),
            _buildInlineStorageChip(
              isLight: isLight,
              accentColor: const Color(0xFF2ECC71),
              text: '스캔한 번호(${widget.qrData.games.length}게임)가 보관함에 안전하게 저장되었습니다.',
            ),
          ],
        ],
      ),
    );
  }

  /// 히어로 카드 내부 일체형 보관함 안내 칩
  Widget _buildInlineStorageChip({
    required bool isLight,
    required Color accentColor,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: accentColor, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.notoSansKr(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isLight ? const Color(0xFF333333) : Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// 3. 공식 당첨 번호 카드 (제 N회 공식 당첨 번호)
  Widget _buildOfficialDrawCard(DHLotteryResult res, bool isLight) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLight
              ? AppColors.lightGoldBorder.withValues(alpha: 0.3)
              : AppColors.borderGold.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.15),
            blurRadius: 12,
          ),
        ],
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF4EFE6) : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  res.drwNoDate,
                  style: GoogleFonts.rajdhani(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...res.numbers.map(
                  (n) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: LottoBall(number: n, size: 30),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    '+',
                    style: GoogleFonts.rajdhani(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LottoBall(number: res.bonusNo, size: 30, isBonus: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4. 게임별 번호 카드 (A ~ E 게임 카드)
  Widget _buildGameCard(GameEvaluation eval, bool isDrawn, bool isPending, bool isLight) {
    final hasWon = eval.rank >= 1 && eval.rank <= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasWon
              ? (isLight ? const Color(0xFFD4AF37) : AppColors.gold)
              : (isLight
                  ? AppColors.lightGoldBorder.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.07)),
          width: hasWon ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (hasWon)
            BoxShadow(
              color: AppColors.gold.withValues(alpha: isLight ? 0.15 : 0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 게임 라벨 (A, B, C...)
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hasWon
                      ? (isLight ? const Color(0xFFFFF0C2) : AppColors.gold.withValues(alpha: 0.2))
                      : (isLight ? const Color(0xFFECE6D8) : Colors.white.withValues(alpha: 0.08)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasWon ? AppColors.gold : Colors.transparent,
                    width: 1,
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
              // 등수 및 일치 뱃지
              _buildRankBadge(eval, isPending, isLight),
            ],
          ),
          const SizedBox(height: 10),
          // 번호 볼 행
          LottoBallRow(
            numbers: eval.game.numbers,
            ballSize: 34,
            matchedNumbers: isDrawn ? eval.matchedNumbers : null,
            bonusNumber: isDrawn ? _currentDrawResult?.bonusNo : null,
          ),
        ],
      ),
    );
  }

  /// 등수 뱃지 (1~5등, 낙첨, 추첨대기)
  Widget _buildRankBadge(GameEvaluation eval, bool isPending, bool isLight) {
    if (isPending || eval.rank == -1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFEBF5FB) : const Color(0xFF3498DB).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLight ? const Color(0xFFAED6F1) : const Color(0xFF3498DB).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Text(
          '추첨 대기',
          style: GoogleFonts.notoSansKr(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isLight ? const Color(0xFF2471A3) : const Color(0xFF85C1E9),
          ),
        ),
      );
    }

    Color bg;
    Color border;
    Color text;

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
        bg = isLight ? const Color(0xFFF0EBE1) : Colors.white.withValues(alpha: 0.06);
        border = Colors.transparent;
        text = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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

  /// 5. 하단 액션 버튼 영역 (공식 웹 링크 & 프리미엄 확인 버튼)
  Widget _buildActionButtons(BuildContext context, bool isLight) {
    return Row(
      children: [
        // [동행복권 공식 웹] 버튼 - 고급 프로스티드 글래스 스타일
        Expanded(
          flex: 5,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openOfficialWeb,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF3EDE2) : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLight
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.14),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.public_rounded,
                      size: 18,
                      color: AppColors.goldText,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '동행복권 공식 웹',
                        style: GoogleFonts.notoSansKr(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // [확인] 버튼 - VIP 샴페인 골드 그라데이션 버튼
        Expanded(
          flex: 6,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLight
                        ? const [Color(0xFFE6B800), Color(0xFFC99700), Color(0xFFA67600)]
                        : const [Color(0xFFFFDF73), Color(0xFFFFC837), Color(0xFFD49A00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isLight ? const Color(0xFFC99700) : const Color(0xFFFFC837))
                          .withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '확인',
                  style: GoogleFonts.notoSansKr(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: const Color(0xFF140E00),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
