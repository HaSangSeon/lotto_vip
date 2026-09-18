import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/dhlottery_api.dart';
import 'common_widgets.dart';
import 'lotto_ball.dart';

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

class TicketEvaluationSummary {
  final int bestRank; // 1~5, 0 (낙첨), -1 (추첨 대기)
  final String summaryLabel;
  final Color badgeColor;
  final int totalPrize;
  final Map<int, int> winCounts;

  const TicketEvaluationSummary({
    required this.bestRank,
    required this.summaryLabel,
    required this.badgeColor,
    required this.totalPrize,
    required this.winCounts,
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

  int? _latestDrawNo;

  // 회차별 당첨 결과 캐시 (스캔 복권 및 과거 회차 당첨 결과)
  final Map<int, DHLotteryResult> _drawResultsCache = {};

  // 접힌 티켓 키 집합
  final Set<String> _collapsedTicketKeys = {};

  int get _upcomingDrawNo => HistoryService.calculateTargetDrawNo(DateTime.now());

  DateTime get _upcomingDrawDate {
    final firstDraw = DateTime(2002, 12, 7, 20, 45, 0);
    return firstDraw.add(Duration(days: (_upcomingDrawNo - 1) * 7));
  }

  int get _waitingGameCount {
    return widget.history
        .where((e) => e.drawNo == _upcomingDrawNo)
        .fold(0, (sum, e) => sum + e.gameCount);
  }

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
          _latestDrawNo = res.drwNo;
          _drawResultsCache[res.drwNo] = res;
        });

        // 과거 회차 결과들을 백그라운드에서 로드
        _preloadDrawResults();
      }
    } catch (_) {}
  }

  Future<void> _preloadDrawResults() async {
    for (final entry in widget.history) {
      final drawNo = entry.drawNo;
      if (_latestDrawNo != null && drawNo <= _latestDrawNo! && !_drawResultsCache.containsKey(drawNo)) {
        final res = await DHLotteryApi.fetchByDrawNo(drawNo);
        if (res != null && mounted) {
          setState(() {
            _drawResultsCache[drawNo] = res;
          });
        }
      }
    }
  }



  /// 당첨 등수 판정
  LottoRankInfo _judgeRank(List<int> myNumbers, DHLotteryResult? result) {
    if (result == null) {
      return const LottoRankInfo(
        rank: -1,
        label: '추첨 대기',
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

  /// 엔트리에 맞는 고유 대상 회차의 당첨 결과 가져오기
  DHLotteryResult? _getResultForEntry(LottoHistoryEntry entry) {
    final entryDrawNo = entry.drawNo;
    // 최신 발표 회차보다 미래의 회차(예: 이번 주 토요일 추첨 예정)는 아직 추첨 전이므로 null -> [추첨 대기]
    if (_latestDrawNo != null && entryDrawNo > _latestDrawNo!) {
      return null;
    }
    return _drawResultsCache[entryDrawNo];
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
          return entry.entryType != LottoEntryType.qrScan;
        case HistoryFilter.winnersOnly:
          final compareResult = _getResultForEntry(entry);
          if (entry.isTicket && entry.games != null) {
            return entry.games!.any((g) {
              final r = _judgeRank(g.numbers, compareResult);
              return r.rank >= 1 && r.rank <= 5;
            });
          }
          final rankInfo = _judgeRank(entry.numbers, compareResult);
          return rankInfo.rank >= 1 && rankInfo.rank <= 5;
      }
    }).toList();

    return Column(
      children: [
        // 1. 상단 이번 주 추첨 예정 안내 & 종이복권 QR 스캔 버튼
        _buildUpcomingDrawHeader(),

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
                    final targetResult = _getResultForEntry(entry);

                    // 묶음 실물 복권(영수증)인 경우 전용 카드 렌더링
                    if (entry.isTicket) {
                      return _buildTicketCard(entry, targetResult, index);
                    }

                    final isScanned = entry.entryType == LottoEntryType.qrScan;
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

                                // 회차 정보 (해당 번호의 고유 추첨 회차)
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

      case LottoEntryType.dream:
        bg = isLight ? const Color(0xFFF3E5F5) : const Color(0xFFAB47BC).withValues(alpha: 0.18);
        border = isLight ? const Color(0xFFAB47BC) : const Color(0xFFAB47BC).withValues(alpha: 0.6);
        textColor = isLight ? const Color(0xFF6A1B9A) : const Color(0xFFCE93D8);
        label = '🌙 꿈해몽';
        break;

      case LottoEntryType.birthDate:
        bg = isLight ? const Color(0xFFFFF8E1) : const Color(0xFFFFB300).withValues(alpha: 0.18);
        border = isLight ? const Color(0xFFFFB300) : const Color(0xFFFFB300).withValues(alpha: 0.6);
        textColor = isLight ? const Color(0xFFB76E00) : const Color(0xFFFFE082);
        label = '🎂 생년월일';
        break;

      case LottoEntryType.customFilter:
        bg = isLight ? const Color(0xFFE0F7FA) : const Color(0xFF00ACC1).withValues(alpha: 0.18);
        border = isLight ? const Color(0xFF00ACC1) : const Color(0xFF00ACC1).withValues(alpha: 0.6);
        textColor = isLight ? const Color(0xFF006064) : const Color(0xFF80DEEA);
        label = '⚙️ 맞춤필터';
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

  /// 묶음 실물 복권 종합 판정
  TicketEvaluationSummary _judgeTicket(LottoHistoryEntry entry, DHLotteryResult? result) {
    if (result == null) {
      return const TicketEvaluationSummary(
        bestRank: -1,
        summaryLabel: '추첨 대기',
        badgeColor: Colors.grey,
        totalPrize: 0,
        winCounts: {},
      );
    }

    final games = entry.games ?? [];
    final Map<int, int> winCounts = {};
    int bestRank = 999;
    int totalPrize = 0;

    for (final g in games) {
      final rankInfo = _judgeRank(g.numbers, result);
      if (rankInfo.rank >= 1 && rankInfo.rank <= 5) {
        winCounts[rankInfo.rank] = (winCounts[rankInfo.rank] ?? 0) + 1;
        if (rankInfo.rank < bestRank) {
          bestRank = rankInfo.rank;
        }
        if (rankInfo.rank == 5) {
          totalPrize += 5000;
        } else if (rankInfo.rank == 4) {
          totalPrize += 50000;
        } else if (rankInfo.rank == 3) {
          totalPrize += result.rank3Amount > 0 ? result.rank3Amount : 1500000;
        } else if (rankInfo.rank == 2) {
          totalPrize += result.rank2Amount > 0 ? result.rank2Amount : 50000000;
        } else if (rankInfo.rank == 1) {
          totalPrize += result.firstWinamnt > 0 ? result.firstWinamnt : 2000000000;
        }
      }
    }

    if (winCounts.isEmpty) {
      return const TicketEvaluationSummary(
        bestRank: 0,
        summaryLabel: '낙첨',
        badgeColor: Colors.white24,
        totalPrize: 0,
        winCounts: {},
      );
    }

    String label = '';
    if (winCounts.containsKey(1)) {
      label = '🎉 1등 당첨!';
    } else if (winCounts.containsKey(2)) {
      label = '🎉 2등 당첨!';
    } else if (winCounts.containsKey(3)) {
      label = '🎉 3등 당첨!';
    } else if (winCounts.containsKey(4) && winCounts.containsKey(5)) {
      label = '🎉 4등 ${winCounts[4]}개 · 5등 ${winCounts[5]}개';
    } else if (winCounts.containsKey(4)) {
      label = '🎉 4등 ${winCounts[4]}개 당첨';
    } else if (winCounts.containsKey(5)) {
      final count = winCounts[5]!;
      label = count > 1 ? '🎉 5등 $count개 (${NumberFormat('#,###').format(count * 5000)}원)' : '🎉 5등 (5,000원)';
    }

    Color badgeColor;
    switch (bestRank) {
      case 1: badgeColor = const Color(0xFFFFD700); break;
      case 2: badgeColor = const Color(0xFF5DADE2); break;
      case 3: badgeColor = const Color(0xFFE59866); break;
      case 4: badgeColor = const Color(0xFF2ECC71); break;
      case 5: badgeColor = const Color(0xFFF39C12); break;
      default: badgeColor = Colors.white24;
    }

    return TicketEvaluationSummary(
      bestRank: bestRank,
      summaryLabel: label,
      badgeColor: badgeColor,
      totalPrize: totalPrize,
      winCounts: winCounts,
    );
  }

  /// 묶음 실물 복권 영수증 카드 렌더링
  Widget _buildTicketCard(LottoHistoryEntry entry, DHLotteryResult? targetResult, int index) {
    final ticketKey = '${entry.createdAt.toIso8601String()}_${entry.title}_$index';
    final isCollapsed = _collapsedTicketKeys.contains(ticketKey);
    final summary = _judgeTicket(entry, targetResult);
    final isLight = AppColors.isLight;
    final games = entry.games ?? [];

    final timeStr =
        '${entry.createdAt.month}/${entry.createdAt.day} ${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: ValueKey(ticketKey),
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
            // 1. 헤더 행: [🎫 실물 복권] [제1158회 • 5게임] ... [🎉 당첨 요약 뱃지] [❤️] [🗑️]
            Row(
              children: [
                _buildTypeBadge(LottoEntryType.qrScan),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${entry.drawNo}회차 • ${entry.gameCount}게임',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                _buildTicketSummaryBadge(summary),
                const SizedBox(width: 6),
                // 즐겨찾기
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
                // 삭제
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

            const SizedBox(height: 12),

            // 2. 영수증 본문 (게임 목록)
            if (isCollapsed) ...[
              // 접힌 상태: 첫 번째 대표 게임 1줄
              InkWell(
                onTap: () {
                  setState(() {
                    _collapsedTicketKeys.remove(ticketKey);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLight ? Colors.grey.shade300 : Colors.white12,
                        ),
                        child: Text(
                          games.isNotEmpty ? games.first.label : 'A',
                          style: GoogleFonts.rajdhani(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LottoBallRow(
                          numbers: games.isNotEmpty ? games.first.numbers : entry.numbers,
                          ballSize: 30,
                          matchedNumbers: targetResult != null
                              ? _judgeRank(games.isNotEmpty ? games.first.numbers : entry.numbers, targetResult).matchedNumbers
                              : null,
                          bonusNumber: targetResult?.bonusNo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // 펼쳐진 상태: A, B, C, D, E 게임 라인별 출력
              ...games.map((game) {
                final gameRank = targetResult != null ? _judgeRank(game.numbers, targetResult) : null;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // 라벨 배지 (A, B, C, D, E)
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLight ? const Color(0xFFFFF0C2) : AppColors.gold.withValues(alpha: 0.18),
                          border: Border.all(
                            color: isLight ? const Color(0xFFD4AF37) : AppColors.gold.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          game.label,
                          style: GoogleFonts.rajdhani(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.goldText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 6개 로또 볼
                      Expanded(
                        child: LottoBallRow(
                          numbers: game.numbers,
                          ballSize: 30,
                          matchedNumbers: gameRank?.matchedNumbers,
                          bonusNumber: targetResult?.bonusNo,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 개별 게임 결과 뱃지 (예: 5등 / 낙첨 / 3개)
                      if (gameRank != null)
                        _buildMiniRankBadge(gameRank),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 10),

            // 3. 하단 접기/펼치기 토글 바 & 생성 일시
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isCollapsed) {
                        _collapsedTicketKeys.remove(ticketKey);
                      } else {
                        _collapsedTicketKeys.add(ticketKey);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isCollapsed
                              ? '전체 ${entry.gameCount}게임 보기 (${entry.gameCount - 1}개 더보기)'
                              : '영수증 접기',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldText,
                          ),
                        ),
                        Icon(
                          isCollapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                          size: 16,
                          color: AppColors.goldText,
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  timeStr,
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 35))
        .fadeIn(duration: 220.ms)
        .slideX(begin: 0.04, end: 0, duration: 220.ms);
  }

  /// 미니 게임별 당첨 뱃지
  Widget _buildMiniRankBadge(LottoRankInfo info) {
    final isLight = AppColors.isLight;
    final isWin = info.rank >= 1 && info.rank <= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isWin
            ? (isLight ? const Color(0xFFFFF3CD) : info.badgeColor.withValues(alpha: 0.2))
            : (isLight ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isWin ? info.badgeColor : Colors.transparent,
          width: 0.8,
        ),
      ),
      child: Text(
        info.rank >= 1 && info.rank <= 5
            ? '${info.rank}등'
            : (info.matchedNumbers.isNotEmpty ? '${info.matchedNumbers.length}개' : '낙첨'),
        style: GoogleFonts.notoSansKr(
          fontSize: 10,
          fontWeight: isWin ? FontWeight.bold : FontWeight.w500,
          color: isWin ? (isLight ? const Color(0xFF8C5D00) : info.badgeColor) : AppColors.textHint,
        ),
      ),
    );
  }

  /// 티켓 단위 종합 당첨 요약 뱃지
  Widget _buildTicketSummaryBadge(TicketEvaluationSummary summary) {
    final isLight = AppColors.isLight;
    final isWin = summary.bestRank >= 1 && summary.bestRank <= 5;

    Color bg;
    Color border;
    Color text;

    if (summary.bestRank == -1) {
      bg = isLight ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.05);
      border = isLight ? Colors.grey.shade300 : Colors.white12;
      text = AppColors.textHint;
    } else if (isWin) {
      bg = isLight ? const Color(0xFFFFF3CD) : summary.badgeColor.withValues(alpha: 0.22);
      border = isLight ? const Color(0xFFFFC107) : summary.badgeColor;
      text = isLight ? const Color(0xFF8C5D00) : summary.badgeColor;
    } else {
      bg = isLight ? const Color(0xFFF8F9F9) : Colors.white.withValues(alpha: 0.05);
      border = isLight ? const Color(0xFFE5E7E9) : Colors.white12;
      text = isLight ? const Color(0xFF707B7C) : const Color(0xFF85929E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        summary.summaryLabel,
        style: GoogleFonts.notoSansKr(
          fontSize: 11,
          fontWeight: isWin ? FontWeight.bold : FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  /// 상단 이번 주 추첨 예정 및 현황 안내 카드
  Widget _buildUpcomingDrawHeader() {
    final upcomingDrawNo = _upcomingDrawNo;
    final drawDate = _upcomingDrawDate;
    final waitingCount = _waitingGameCount;
    final isLight = AppColors.isLight;

    // D-Day 계산
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(drawDate.year, drawDate.month, drawDate.day);
    final daysLeft = targetDay.difference(today).inDays;
    final String dDayText = daysLeft <= 0 ? 'D-Day' : 'D-$daysLeft';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight
              ? AppColors.lightGoldBorder.withValues(alpha: 0.6)
              : AppColors.borderGold.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: isLight ? AppColors.goldDark.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 왼쪽: 이번 주 추첨 회차 안내 & 상세 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFFFF0C2) : AppColors.gold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLight ? const Color(0xFFD4AF37) : AppColors.gold.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, color: AppColors.goldText, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '이번 주 제 $upcomingDrawNo회',
                            style: GoogleFonts.notoSansKr(
                              color: AppColors.goldText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '${drawDate.month}월 ${drawDate.day}일 (토) 20:45 발표 예정',
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '추첨 완료 시 보관된 번호와 자동 대조됩니다',
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 오른쪽: D-Day & 보관 게임 수 위젯
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLight
                    ? [const Color(0xFFFFF7DB), const Color(0xFFFEEBB4)]
                    : [AppColors.gold.withValues(alpha: 0.18), AppColors.goldDark.withValues(alpha: 0.12)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLight ? const Color(0xFFE2B747) : AppColors.gold.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  dDayText,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.goldText,
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: waitingCount > 0
                        ? (isLight ? const Color(0xFFE8F8F5) : const Color(0xFF2ECC71).withValues(alpha: 0.2))
                        : (isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    waitingCount > 0 ? '$waitingCount게임 대기' : '미보관',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: waitingCount > 0
                          ? (isLight ? const Color(0xFF145A32) : const Color(0xFFA9DFBF))
                          : AppColors.textHint,
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

          // 2. [하단 탭] 4개 세그먼트 (전체 | 🎫 실물복권 | ✨ 프리미엄 추출 | 🏆 당첨)
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
                _buildSegmentButton('✨ 프리미엄 추출', HistoryFilter.generated),
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: GoogleFonts.notoSansKr(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? (isLight ? AppColors.goldDeep : AppColors.gold)
                    : AppColors.textSecondary,
              ),
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
      case -1:
        bgColor = isLight ? const Color(0xFFF4F6F6) : Colors.white.withValues(alpha: 0.06);
        borderColor = isLight ? const Color(0xFFBDC3C7) : Colors.white24;
        textColor = isLight ? const Color(0xFF7F8C8D) : Colors.white60;
        break;
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
            '프리미엄 번호 추출이나 종이복권 QR 스캔으로\n번호를 보관해 보세요.',
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
