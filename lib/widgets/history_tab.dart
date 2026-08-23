import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/dhlottery_api.dart';
import 'common_widgets.dart';
import 'lotto_ball.dart';
import 'qr_scanner_view.dart';

enum HistoryFilter {
  all, // 전체
  qrScanned, // 🎫 실물 복권 (QR 스캔)
  generated, // ✨ 생성 번호 (VIP + 맞춤)
  winnersOnly, // 🏆 당첨 번호
}

class LottoRankInfo {
  final int rank; // 1 ~ 5, 0 (낙첨)
  final String label;
  final String prizeText;
  final Color badgeColor;
  final Set<int> matchedNumbers;
  final bool isBonusMatched;

  const LottoRankInfo({
    required this.rank,
    required this.label,
    required this.prizeText,
    required this.badgeColor,
    required this.matchedNumbers,
    required this.isBonusMatched,
  });
}

class HistoryTab extends StatefulWidget {
  final List<LottoHistoryEntry> history;
  final VoidCallback onClear;
  final Function(LottoHistoryEntry)? onDeleteEntry;
  final VoidCallback? onRefresh;

  const HistoryTab({
    super.key,
    required this.history,
    required this.onClear,
    this.onDeleteEntry,
    this.onRefresh,
  });

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  HistoryFilter _selectedFilter = HistoryFilter.all;
  bool _onlyFavorites = false; // 즐겨찾기 필터

  DHLotteryResult? _currentCompareResult; // 현재 대조 중인 회차 결과
  int? _latestDrawNo;
  bool _isLoadingDraw = true;

  // 회차별 당첨 결과 캐시 (스캔 복권 각각의 회차 및 선택 대조용)
  final Map<int, DHLotteryResult> _drawResultsCache = {};

  @override
  void initState() {
    super.initState();
    _loadLatestDraw();
  }

  Future<void> _loadLatestDraw() async {
    try {
      final res = await DHLotteryApi.fetchLatest();
      if (mounted && res != null) {
        setState(() {
          _currentCompareResult = res;
          _latestDrawNo = res.drwNo;
          _drawResultsCache[res.drwNo] = res;
          _isLoadingDraw = false;
        });

        // 스캔된 복권 중 다른 회차가 있으면 백그라운드에서 로드
        _preloadScannedDraws();
      } else {
        if (mounted) setState(() => _isLoadingDraw = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDraw = false);
    }
  }

  Future<void> _preloadScannedDraws() async {
    for (final entry in widget.history) {
      if (entry.entryType == LottoEntryType.qrScan) {
        final drawNo = entry.drawNo;
        if (!_drawResultsCache.containsKey(drawNo)) {
          final res = await DHLotteryApi.fetchByDrawNo(drawNo);
          if (res != null && mounted) {
            setState(() {
              _drawResultsCache[drawNo] = res;
            });
          }
        }
      }
    }
  }

  /// 대조 기준 회차 변경
  Future<void> _changeCompareDrawNo(int drwNo) async {
    if (_drawResultsCache.containsKey(drwNo)) {
      setState(() {
        _currentCompareResult = _drawResultsCache[drwNo];
      });
      return;
    }

    setState(() => _isLoadingDraw = true);
    final res = await DHLotteryApi.fetchByDrawNo(drwNo);
    if (mounted) {
      setState(() {
        if (res != null) {
          _drawResultsCache[drwNo] = res;
          _currentCompareResult = res;
        }
        _isLoadingDraw = false;
      });
    }
  }

  /// 🌟 프리미엄 회차 선택 다이얼로그 (고급스러운 디자인 & 정렬)
  void _showDrawSelectDialog() {
    if (_latestDrawNo == null) return;
    final controller = TextEditingController(
      text: _currentCompareResult?.drwNo.toString() ?? _latestDrawNo.toString(),
    );
    final isLight = AppColors.isLight;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isLight ? AppColors.lightGoldBorder : AppColors.borderGold,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isLight ? AppColors.goldDark : Colors.black).withValues(alpha: 0.25),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 헤더: 아이콘 + 제목 + 닫기
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isLight
                              ? const Color(0xFFFFF0C2)
                              : AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.manage_search_rounded,
                          color: isLight ? AppColors.goldDeep : AppColors.gold,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '대조할 회차 선택',
                        style: GoogleFonts.notoSansKr(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.textHint, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 18,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 2. 설명 텍스트
              Text(
                '보관된 번호들을 비교할 회차를 입력하세요.\n(1회차 ~ 최신 제$_latestDrawNo회)',
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 18),

              // 3. 회차 입력 필드 (가운데 정렬 & 고급스러운 스타일)
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: isLight ? AppColors.goldDeep : AppColors.goldLight,
                ),
                decoration: InputDecoration(
                  hintText: '$_latestDrawNo',
                  hintStyle: GoogleFonts.rajdhani(color: AppColors.textHint),
                  suffixText: '회',
                  suffixStyle: GoogleFonts.notoSansKr(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: isLight ? const Color(0xFFF9F9F9) : Colors.white.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isLight ? AppColors.lightGoldBorder.withValues(alpha: 0.5) : AppColors.borderGold.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isLight ? AppColors.goldDark : AppColors.gold,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 4. 빠른 선택 칩 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => controller.text = _latestDrawNo.toString(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFFFF0C2) : AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isLight ? const Color(0xFFD4AF37) : AppColors.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '최신 제$_latestDrawNo회',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11.5,
                          color: AppColors.goldText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (_latestDrawNo! > 1) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => controller.text = (_latestDrawNo! - 1).toString(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isLight ? Colors.grey.shade200 : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          '이전 제${_latestDrawNo! - 1}회',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // 5. 하단 액션 버튼 (취소 | 대조하기 50:50 정렬)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        '취소',
                        style: GoogleFonts.notoSansKr(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final val = int.tryParse(controller.text.trim());
                        if (val != null && val >= 1 && val <= _latestDrawNo!) {
                          Navigator.pop(ctx);
                          _changeCompareDrawNo(val);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: isLight ? AppColors.goldDark : AppColors.gold,
                        foregroundColor: isLight ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: isLight ? 2 : 4,
                      ),
                      child: Text(
                        '대조하기',
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
    );
  }

  /// 당첨 등수 판정
  LottoRankInfo _judgeRank(List<int> myNumbers, DHLotteryResult? result) {
    if (result == null) {
      return const LottoRankInfo(
        rank: 0,
        label: '조회 대기',
        prizeText: '',
        badgeColor: Colors.grey,
        matchedNumbers: {},
        isBonusMatched: false,
      );
    }

    final matched = myNumbers.where((n) => result.numbers.contains(n)).toSet();
    final isBonusMatched = myNumbers.contains(result.bonusNo);
    final matchCount = matched.length;

    if (matchCount == 6) {
      return LottoRankInfo(
        rank: 1,
        label: '1등 당첨!',
        prizeText: '🎉 1등 당첨',
        badgeColor: const Color(0xFFFFD700),
        matchedNumbers: matched,
        isBonusMatched: false,
      );
    } else if (matchCount == 5 && isBonusMatched) {
      return LottoRankInfo(
        rank: 2,
        label: '2등 당첨!',
        prizeText: '🥈 2등 (5개+보너스)',
        badgeColor: const Color(0xFFE0E0E0),
        matchedNumbers: matched,
        isBonusMatched: true,
      );
    } else if (matchCount == 5) {
      return LottoRankInfo(
        rank: 3,
        label: '3등 당첨!',
        prizeText: '🥉 3등 (5개 일치)',
        badgeColor: const Color(0xFFCD7F32),
        matchedNumbers: matched,
        isBonusMatched: false,
      );
    } else if (matchCount == 4) {
      return LottoRankInfo(
        rank: 4,
        label: '4등 (5만원)',
        prizeText: '5만원',
        badgeColor: const Color(0xFF4CAF50),
        matchedNumbers: matched,
        isBonusMatched: false,
      );
    } else if (matchCount == 3) {
      return LottoRankInfo(
        rank: 5,
        label: '5등 (5천원)',
        prizeText: '5천원',
        badgeColor: const Color(0xFFFFB300),
        matchedNumbers: matched,
        isBonusMatched: false,
      );
    } else {
      return LottoRankInfo(
        rank: 0,
        label: matchCount > 0 ? '$matchCount개 일치' : '낙첨',
        prizeText: '',
        badgeColor: Colors.white24,
        matchedNumbers: matched,
        isBonusMatched: false,
      );
    }
  }

  /// 엔트리에 맞는 대조용 당첨 결과 가져오기
  DHLotteryResult? _getResultForEntry(LottoHistoryEntry entry) {
    if (entry.entryType == LottoEntryType.qrScan) {
      // 실물 복권은 용지 자체의 회차 기준
      return _drawResultsCache[entry.drawNo] ?? _currentCompareResult;
    } else {
      // 생성 번호(VIP/맞춤)는 사용자가 선택한 대조 회차 기준
      return _currentCompareResult;
    }
  }

  void _confirmDeleteEntry(LottoHistoryEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              '번호 기록 삭제',
              style: GoogleFonts.notoSansKr(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          '${entry.title} (${entry.numbers.join(', ')})\n이 기록을 삭제하시겠습니까?',
          style: GoogleFonts.notoSansKr(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: GoogleFonts.notoSansKr(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEntry(entry);
            },
            child: Text('삭제', style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(LottoHistoryEntry entry) async {
    await HistoryService.delete(entry);
    if (widget.onDeleteEntry != null) {
      widget.onDeleteEntry!(entry);
    } else {
      setState(() {
        widget.history.remove(entry);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 필터링된 항목 목록
    final displayedHistory = widget.history.where((entry) {
      // 1. 즐겨찾기 토글 체크
      if (_onlyFavorites && !entry.isFavorite) {
        return false;
      }

      // 2. 4가지 심플 탭 필터링
      switch (_selectedFilter) {
        case HistoryFilter.all:
          return true;
        case HistoryFilter.qrScanned:
          return entry.entryType == LottoEntryType.qrScan;
        case HistoryFilter.generated:
          return entry.entryType == LottoEntryType.vipLucky || entry.entryType == LottoEntryType.custom;
        case HistoryFilter.winnersOnly:
          final compareResult = _getResultForEntry(entry);
          final rankInfo = _judgeRank(entry.numbers, compareResult);
          return rankInfo.rank >= 1 && rankInfo.rank <= 5;
      }
    }).toList();

    return Column(
      children: [
        // 1. 상단 최신/대조 당첨 번호 카드 & 회차 선택 버튼
        _buildCompareDrawHeader(),

        // 2. 상단 제어 바 (보관된 번호 N개 / 즐겨찾기 / 전체삭제) + 4개 세그먼트 필터 바
        _buildSimpleSegmentBar(displayedHistory.length),

        // 3. 번호 카드 목록
        Expanded(
          child: displayedHistory.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
                  itemCount: displayedHistory.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = displayedHistory[index];
                    final isScanned = entry.entryType == LottoEntryType.qrScan;

                    // 대조용 결과 및 랭크 계산
                    final targetResult = _getResultForEntry(entry);
                    final rankInfo = _judgeRank(entry.numbers, targetResult);

                    final timeStr =
                        '${entry.createdAt.month}/${entry.createdAt.day} ${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';

                    // 실물 복권인 경우 게임 라벨(A~E) 추출
                    String gameLabel = '';
                    if (isScanned) {
                      final match = RegExp(r'([A-G])게임').firstMatch(entry.title);
                      if (match != null) {
                        gameLabel = '${match.group(1)}게임';
                      }
                    }

                    return Dismissible(
                      key: ValueKey('${entry.createdAt.toIso8601String()}_${entry.title}_$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                            SizedBox(width: 6),
                            Text('삭제', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        _confirmDeleteEntry(entry);
                        return false;
                      },
                      child: GlassCard(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        borderRadius: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🌟 1. 카드 상단 헤더: [유형 뱃지] + [회차 뱃지] ── [당첨 뱃지] + [❤️] + [🗑️]
                            Row(
                              children: [
                                // 유형 뱃지 ([🎫 실물복권] or [👑 VIP행운] or [⚙️ 맞춤조합])
                                _buildTypeBadge(entry.entryType),
                                const SizedBox(width: 6),

                                // 회차 정보
                                if (isScanned) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${entry.drawNo}회차${gameLabel.isNotEmpty ? " • $gameLabel" : ""}',
                                      style: GoogleFonts.notoSansKr(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  // 생성 번호는 회차 변경 뱃지 역할!
                                  InkWell(
                                    onTap: _showDrawSelectDialog,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.isLight
                                            ? const Color(0xFFFFF0C2)
                                            : AppColors.gold.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.isLight ? const Color(0xFFD4AF37) : AppColors.gold.withValues(alpha: 0.4),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${_currentCompareResult?.drwNo ?? _latestDrawNo ?? ""}회 대조',
                                            style: GoogleFonts.notoSansKr(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.isLight ? const Color(0xFF855A00) : AppColors.gold,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            size: 14,
                                            color: AppColors.isLight ? const Color(0xFF855A00) : AppColors.gold,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                // 불필요한 줄임표 텍스트 대신 Spacer로 여백 확보
                                const Spacer(),

                                // 당첨 판정 뱃지
                                _buildRankBadge(rankInfo),
                                const SizedBox(width: 6),

                                // 즐겨찾기 버튼
                                GestureDetector(
                                  onTap: () async {
                                    setState(() {
                                      entry.isFavorite = !entry.isFavorite;
                                    });
                                    await HistoryService.updateAll(widget.history);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: entry.isFavorite ? Colors.redAccent : AppColors.textHint,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),

                                // 개별 삭제 버튼
                                GestureDetector(
                                  onTap: () => _confirmDeleteEntry(entry),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.textHint,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // 2. 공 번호 행 (대조 결과 일치 번호 하이라이트 & 0개 일치 시 일관된 Dimmed 처리)
                            LottoBallRow(
                              numbers: entry.numbers,
                              ballSize: 38,
                              matchedNumbers: targetResult != null ? rankInfo.matchedNumbers : null,
                              bonusNumber: targetResult?.bonusNo,
                            ),

                            const SizedBox(height: 10),

                            // 3. 하단 메타 정보 (좌측: 번호 분석 스펙, 우측: 생성 일시)
                            Builder(
                              builder: (context) {
                                final sum = entry.numbers.reduce((a, b) => a + b);
                                final oddCount = entry.numbers.where((n) => n % 2 != 0).length;
                                final evenCount = 6 - oddCount;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.analytics_outlined,
                                          size: 13,
                                          color: AppColors.textHint.withValues(alpha: 0.7),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '총합 $sum • 홀$oddCount 짝$evenCount',
                                          style: GoogleFonts.notoSansKr(
                                            color: AppColors.textHint,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      timeStr,
                                      style: GoogleFonts.notoSansKr(
                                        color: AppColors.textHint,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate(delay: Duration(milliseconds: index * 35))
                        .fadeIn(duration: 220.ms)
                        .slideX(begin: 0.04, end: 0, duration: 220.ms);
                  },
                ),
        ),
      ],
    );
  }

  /// 번호 유형별 고유 컬러 뱃지 (중복 아이콘 없이 슬림하고 고급스럽게)
  Widget _buildTypeBadge(LottoEntryType type) {
    final isLight = AppColors.isLight;

    Color bg;
    Color border;
    Color textColor;
    String label;

    switch (type) {
      case LottoEntryType.qrScan:
        bg = isLight ? const Color(0xFFE8F8F5) : const Color(0xFF2ECC71).withValues(alpha: 0.18);
        border = isLight ? const Color(0xFF2ECC71) : const Color(0xFF2ECC71).withValues(alpha: 0.6);
        textColor = isLight ? const Color(0xFF145A32) : const Color(0xFFA9DFBF);
        label = '🎫 실물복권';
        break;

      case LottoEntryType.vipLucky:
        bg = isLight ? const Color(0xFFFFF9E6) : const Color(0xFFFFD700).withValues(alpha: 0.18);
        border = isLight ? const Color(0xFFD4AF37) : const Color(0xFFFFD700).withValues(alpha: 0.6);
        textColor = isLight ? const Color(0xFF855A00) : const Color(0xFFFFD700);
        label = '👑 VIP행운';
        break;

      case LottoEntryType.custom:
        bg = isLight ? const Color(0xFFF4ECF7) : const Color(0xFF9B59B6).withValues(alpha: 0.18);
        border = isLight ? const Color(0xFF9B59B6) : const Color(0xFF9B59B6).withValues(alpha: 0.6);
        textColor = isLight ? const Color(0xFF512E5F) : const Color(0xFFD7BDE2);
        label = '⚙️ 맞춤조합';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSansKr(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  /// 상단 대조 당첨 번호 헤더 카드 (회차 변경 탭 지원)
  Widget _buildCompareDrawHeader() {
    final drwNo = _currentCompareResult?.drwNo ?? _latestDrawNo ?? 0;
    final isLatest = _latestDrawNo != null && drwNo == _latestDrawNo;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.isLight
              ? AppColors.lightGoldBorder.withValues(alpha: 0.4)
              : AppColors.borderGold.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 회차 선택 팝업 트리거 버튼
              InkWell(
                onTap: _showDrawSelectDialog,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.isLight ? const Color(0xFFFFF0C2) : AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.isLight ? const Color(0xFFD4AF37) : AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tune, color: AppColors.goldText, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '제 $drwNo회 ${isLatest ? "(최신)" : "(선택)"}',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.goldText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down, color: AppColors.goldText, size: 16),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // 종이복권 QR 스캔 버튼
              InkWell(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QrScannerView(
                        onHistorySaved: widget.onRefresh,
                      ),
                    ),
                  );
                  widget.onRefresh?.call();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.isLight ? const Color(0xFFE8F8F5) : const Color(0xFF2ECC71).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_scanner, size: 13, color: Color(0xFF2ECC71)),
                      const SizedBox(width: 4),
                      Text(
                        '종이복권 QR',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.isLight ? const Color(0xFF145A32) : const Color(0xFFA9DFBF),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoadingDraw)
            const SizedBox(
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_currentCompareResult != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._currentCompareResult!.numbers.map(
                    (n) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: LottoBall(number: n, size: 28),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('+',
                        style: GoogleFonts.rajdhani(
                            color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  LottoBall(
                    number: _currentCompareResult!.bonusNo,
                    size: 28,
                    isBonus: true,
                  ),
                ],
              ),
            )
          else
            Text(
              '추첨 결과를 불러오는 중입니다...',
              style: GoogleFonts.notoSansKr(color: AppColors.textHint, fontSize: 12),
            ),
        ],
      ),
    );
  }

  /// 🌟 상단 제어 바 (보관된 번호 N개 / 즐겨찾기 / 전체삭제) + 4개 세그먼트 필터 바
  Widget _buildSimpleSegmentBar(int currentCount) {
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
                onTap: () => setState(() => _onlyFavorites = !_onlyFavorites),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: _onlyFavorites
                        ? (isLight ? const Color(0xFFFFF0C2) : AppColors.gold.withValues(alpha: 0.2))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _onlyFavorites
                          ? (isLight ? const Color(0xFFD4AF37) : AppColors.gold)
                          : AppColors.borderSubtle.withValues(alpha: 0.5),
                      width: 0.9,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _onlyFavorites ? Icons.favorite : Icons.favorite_border,
                        size: 13,
                        color: _onlyFavorites ? Colors.redAccent : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '즐겨찾기',
                        style: GoogleFonts.notoSansKr(
                          color: _onlyFavorites
                              ? (isLight ? AppColors.goldDeep : AppColors.gold)
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: _onlyFavorites ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 전체 삭제
              if (widget.history.isNotEmpty)
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.card,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Row(
                          children: [
                            const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22),
                            const SizedBox(width: 8),
                            Text('기록 전체 삭제',
                                style: GoogleFonts.notoSansKr(
                                    color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
                          ],
                        ),
                        content: Text('보관함의 모든 번호 기록을 삭제할까요?\n삭제된 기록은 복구할 수 없습니다.',
                            style: GoogleFonts.notoSansKr(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('취소', style: GoogleFonts.notoSansKr(color: AppColors.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onClear();
                            },
                            child: Text('전체 삭제',
                                style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
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

          // 2. [하단 탭] 4개 세그먼트 (전체 | 🎫 실물복권 | ✨ 생성번호 | 🏆 당첨)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isLight ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLight ? AppColors.lightGoldBorder.withValues(alpha: 0.3) : AppColors.borderSubtle.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                _buildSegmentButton('전체', HistoryFilter.all),
                _buildSegmentButton('🎫 실물복권', HistoryFilter.qrScanned),
                _buildSegmentButton('✨ 생성번호', HistoryFilter.generated),
                _buildSegmentButton('🏆 당첨', HistoryFilter.winnersOnly),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, HistoryFilter filter) {
    final isSelected = _selectedFilter == filter;
    final isLight = AppColors.isLight;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isLight ? Colors.white : AppColors.gold.withValues(alpha: 0.22))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (isLight ? const Color(0xFFD4AF37) : AppColors.gold)
                  : Colors.transparent,
              width: 1.0,
            ),
            boxShadow: isSelected && isLight
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected
                  ? (isLight ? AppColors.goldDeep : AppColors.gold)
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// 당첨 등수 뱃지 위젯
  Widget _buildRankBadge(LottoRankInfo info) {
    final isLight = AppColors.isLight;

    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (info.rank) {
      case 1:
        bgColor = isLight ? const Color(0xFFFFF3CD) : const Color(0xFFFFD700).withValues(alpha: 0.22);
        borderColor = isLight ? const Color(0xFFFFC107) : const Color(0xFFFFD700);
        textColor = isLight ? const Color(0xFF8C5D00) : const Color(0xFFFFD700);
        break;
      case 2:
        bgColor = isLight ? const Color(0xFFEBF5FB) : const Color(0xFF5DADE2).withValues(alpha: 0.22);
        borderColor = isLight ? const Color(0xFF3498DB) : const Color(0xFF5DADE2);
        textColor = isLight ? const Color(0xFF1B4F72) : const Color(0xFFD6EAF8);
        break;
      case 3:
        bgColor = isLight ? const Color(0xFFFBEEE6) : const Color(0xFFE59866).withValues(alpha: 0.22);
        borderColor = isLight ? const Color(0xFFE59866) : const Color(0xFFE59866);
        textColor = isLight ? const Color(0xFF78281F) : const Color(0xFFF5CBA7);
        break;
      case 4:
        bgColor = isLight ? const Color(0xFFE8F8F5) : const Color(0xFF2ECC71).withValues(alpha: 0.22);
        borderColor = isLight ? const Color(0xFF2ECC71) : const Color(0xFF2ECC71);
        textColor = isLight ? const Color(0xFF145A32) : const Color(0xFFA9DFBF);
        break;
      case 5:
        bgColor = isLight ? const Color(0xFFFEF9E7) : const Color(0xFFF39C12).withValues(alpha: 0.22);
        borderColor = isLight ? const Color(0xFFF39C12) : const Color(0xFFF39C12);
        textColor = isLight ? const Color(0xFF7D6608) : const Color(0xFFFAD7A0);
        break;
      default:
        final hasMatches = info.matchedNumbers.isNotEmpty;
        if (hasMatches) {
          bgColor = isLight ? const Color(0xFFF2F4F4) : Colors.white.withValues(alpha: 0.08);
          borderColor = isLight ? const Color(0xFFBDC3C7) : Colors.white24;
          textColor = isLight ? const Color(0xFF424949) : const Color(0xFFCCD1D1);
        } else {
          bgColor = isLight ? const Color(0xFFF8F9F9) : Colors.white.withValues(alpha: 0.05);
          borderColor = isLight ? const Color(0xFFE5E7E9) : Colors.white12;
          textColor = isLight ? const Color(0xFF707B7C) : const Color(0xFF85929E);
        }
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Text(
        info.label,
        style: GoogleFonts.notoSansKr(
          color: textColor,
          fontSize: 10.5,
          fontWeight: info.rank > 0 ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, color: AppColors.textHint, size: 54),
          const SizedBox(height: 14),
          Text(
            '해당하는 보관 번호가 없습니다.',
            style: GoogleFonts.notoSansKr(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '행운 번호 생성이나 종이복권 QR 스캔으로\n번호를 보관해 보세요.',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              color: AppColors.textHint,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
