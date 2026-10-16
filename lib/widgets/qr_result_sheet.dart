import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../services/qr_lottery_parser.dart';
import '../services/dhlottery_api.dart';
import 'qr/qr_hero_card.dart';
import 'qr/qr_game_cards.dart';

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

                    // 2. 통합 프리미엄 상태 히어로 카드
                    QrHeroCard(
                      hasWin: hasWin,
                      isDrawn: isDrawn,
                      isPending: isPending,
                      isNetworkError: _networkError,
                      winCount: winningGames.length,
                      totalPrize: totalPrize,
                      fmt: currencyFmt,
                      dateStr: dateStr,
                      isLight: isLight,
                      isSavedToHistory: widget.isSavedToHistory,
                      gameCount: widget.qrData.games.length,
                      isRetrying: _isRetrying,
                      onRetry: widget.onRetry != null ? _handleRetry : null,
                    ),

                    const SizedBox(height: 16),

                    // 3. 해당 회차 공식 당첨 번호 카드 (추첨 완료 시 표시)
                    if (_currentDrawResult != null) ...[
                      QrOfficialDrawCard(res: _currentDrawResult!, isLight: isLight),
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
                    ...evaluations.map((eval) => QrGameCard(
                          eval: eval,
                          isDrawn: isDrawn,
                          isPending: isPending,
                          isLight: isLight,
                          bonusNumber: _currentDrawResult?.bonusNo,
                        )),

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
