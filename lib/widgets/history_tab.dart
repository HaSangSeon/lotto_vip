import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../services/dhlottery_api.dart';
import '../services/notification_service.dart';
import 'history/history_card.dart';
import 'history/ticket_history_card.dart';
import 'history/history_delete_dialog.dart';
import 'history/upcoming_draw_header.dart';
import 'history/history_filter_bar.dart';

class LottoRankInfo {
  final int rank; // 1 ~ 5, 0 (낙첨), -1 (추첨 대기)
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
  final bool? isLight;
  final List<LottoHistoryEntry> history;
  final VoidCallback onClear;
  final Function(LottoHistoryEntry)? onDeleteEntry;
  final VoidCallback? onRefresh;

  const HistoryTab({
    super.key,
    this.isLight,
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
  bool _onlyFavorites = false;

  int? _latestDrawNo;
  final Map<int, DHLotteryResult> _drawResultsCache = {};
  final Set<String> _collapsedTicketKeys = {};

  int get _upcomingDrawNo => HistoryService.calculateUpcomingDrawNo(DateTime.now());

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
        _preloadDrawResults();
      } else {
        _preloadDrawResults();
      }
    } catch (_) {
      _preloadDrawResults();
    }
  }

  @override
  void didUpdateWidget(covariant HistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.history.length != oldWidget.history.length) {
      _preloadDrawResults();
    }
  }

  Future<void> _preloadDrawResults() async {
    final Map<int, DHLotteryResult> newlyLoaded = {};
    final maxCheckDraw = _latestDrawNo ?? (_upcomingDrawNo - 1);
    for (final entry in widget.history) {
      final drawNo = entry.drawNo;
      if (drawNo <= maxCheckDraw &&
          !_drawResultsCache.containsKey(drawNo) &&
          !newlyLoaded.containsKey(drawNo)) {
        final res = await DHLotteryApi.fetchByDrawNo(drawNo);
        if (res != null) {
          newlyLoaded[drawNo] = res;
        }
      }
    }
    if (newlyLoaded.isNotEmpty && mounted) {
      setState(() {
        _drawResultsCache.addAll(newlyLoaded);
      });
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
    if (_latestDrawNo != null && entryDrawNo > _latestDrawNo!) {
      return null;
    }
    return _drawResultsCache[entryDrawNo];
  }

  void _confirmDeleteEntry(LottoHistoryEntry entry) {
    HistoryDeleteDialog.showConfirmDeleteEntry(
      context: context,
      entry: entry,
      onConfirm: () => _deleteEntry(entry),
    );
  }

  void _confirmClearAll() {
    HistoryDeleteDialog.showConfirmClearAll(
      context: context,
      historyCount: widget.history.length,
      onConfirm: () async {
        widget.onClear();
        try {
          await NotificationService.scheduleWeeklyDrawNotification();
        } catch (_) {}
      },
    );
  }

  /// 스와이프 삭제 시 노출되는 프리미엄 배경
  Widget _buildDismissBackground() {
    final isLight = AppColors.isLight;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? [const Color(0xFFFF5252), const Color(0xFFD32F2F)]
              : [const Color(0xFF9E1B24), const Color(0xFF5A0D10)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 6),
          Text(
            '삭제',
            style: GoogleFonts.notoSansKr(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(LottoHistoryEntry entry) async {
    await HistoryService.delete(entry);
    try {
      await NotificationService.scheduleWeeklyDrawNotification();
    } catch (_) {}
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
    // 테마 변경(ThemeData) 의존성 등록
    final _ = widget.isLight ?? (Theme.of(context).brightness == Brightness.light);
    // 필터링된 항목 목록
    final displayedHistory = widget.history.where((entry) {
      if (_onlyFavorites && !entry.isFavorite) {
        return false;
      }
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
        // 1. 상단 이번 주 추첨 예정 안내 & D-Day
        UpcomingDrawHeader(
          upcomingDrawNo: _upcomingDrawNo,
          drawDate: _upcomingDrawDate,
          waitingGameCount: _waitingGameCount,
        ),

        // 2. 상단 제어 바 (보관 번호 개수, 즐겨찾기, 전체삭제) + 4개 세그먼트 필터
        HistoryFilterBar(
          currentCount: displayedHistory.length,
          onlyFavorites: _onlyFavorites,
          hasEntries: widget.history.isNotEmpty,
          selectedFilter: _selectedFilter,
          onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
          onToggleFavorites: () => setState(() => _onlyFavorites = !_onlyFavorites),
          onClearAll: _confirmClearAll,
        ),

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
                    final dismissKey =
                        '${entry.createdAt.millisecondsSinceEpoch}_${entry.title}';

                    // 1. 묶음 실물 복권(영수증)인 경우 전용 카드 렌더링
                    if (entry.isTicket) {
                      return Dismissible(
                        key: ValueKey(dismissKey),
                        direction: DismissDirection.endToStart,
                        background: _buildDismissBackground(),
                        confirmDismiss: (direction) async {
                          _confirmDeleteEntry(entry);
                          return false;
                        },
                        child: TicketHistoryCard(
                          entry: entry,
                          targetResult: targetResult,
                          isInitiallyCollapsed:
                              _collapsedTicketKeys.contains(dismissKey),
                          onToggleCollapse: () {
                            if (_collapsedTicketKeys.contains(dismissKey)) {
                              _collapsedTicketKeys.remove(dismissKey);
                            } else {
                              _collapsedTicketKeys.add(dismissKey);
                            }
                          },
                          onToggleFavorite: () async {
                            setState(() => entry.isFavorite = !entry.isFavorite);
                            await HistoryService.updateAll(widget.history);
                          },
                          onDelete: () => _confirmDeleteEntry(entry),
                        ),
                      )
                          .animate(delay: Duration(milliseconds: index * 35))
                          .fadeIn(duration: 220.ms)
                          .slideX(begin: 0.04, end: 0, duration: 220.ms);
                    }

                    // 2. 단일 복권 번호 카드 렌더링
                    final rankInfo = _judgeRank(entry.numbers, targetResult);
                    return Dismissible(
                      key: ValueKey(dismissKey),
                      direction: DismissDirection.endToStart,
                      background: _buildDismissBackground(),
                      confirmDismiss: (direction) async {
                        _confirmDeleteEntry(entry);
                        return false;
                      },
                      child: HistoryCard(
                        entry: entry,
                        rank: rankInfo.rank,
                        rankLabel: rankInfo.label,
                        matchedNumbers: targetResult != null
                            ? rankInfo.matchedNumbers
                            : const {},
                        bonusNumber: (rankInfo.rank == 2) ? targetResult?.bonusNo : null,
                        onToggleFavorite: () async {
                          setState(() => entry.isFavorite = !entry.isFavorite);
                          await HistoryService.updateAll(widget.history);
                        },
                        onDelete: () => _confirmDeleteEntry(entry),
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
