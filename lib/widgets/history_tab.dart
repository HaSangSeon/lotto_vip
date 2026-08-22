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
  thisWeek,
  all,
  past,
  favorites,
  winnersOnly,
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

  const HistoryTab({
    super.key,
    required this.history,
    required this.onClear,
    this.onDeleteEntry,
  });

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  HistoryFilter _selectedFilter = HistoryFilter.thisWeek;
  DHLotteryResult? _latestResult;
  bool _isLoadingDraw = true;

  @override
  void initState() {
    super.initState();
    _loadLatestDraw();
  }

  Future<void> _loadLatestDraw() async {
    try {
      final res = await DHLotteryApi.fetchLatest();
      if (mounted) {
        setState(() {
          _latestResult = res;
          _isLoadingDraw = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingDraw = false);
      }
    }
  }

  /// 번호가 생성된 날짜를 기준으로 해당 회차(drwNo) 계산
  int _calculateDrawNoForDate(DateTime date) {
    // 1회차: 2002년 12월 7일 (토) 20:00 마감
    final firstDrawDate = DateTime(2002, 12, 7, 20, 0, 0);
    final diff = date.difference(firstDrawDate);
    if (diff.isNegative) return 1;
    return (diff.inDays / 7).floor() + 1;
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

  void _confirmDeleteEntry(LottoHistoryEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent, size: 22),
            const SizedBox(width: 8),
            Text('번호 기록 삭제',
                style: GoogleFonts.notoSansKr(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
        content: Text(
          '${entry.title} (${entry.numbers.join(', ')})\n이 기록을 삭제하시겠습니까?',
          style: GoogleFonts.notoSansKr(
              color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소',
                style: GoogleFonts.notoSansKr(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEntry(entry);
            },
            child: Text('삭제',
                style: GoogleFonts.notoSansKr(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
    final currentDrawNo = _latestResult?.drwNo ??
        _calculateDrawNoForDate(DateTime.now());

    // 필터링된 항목 목록
    final displayedHistory = widget.history.where((entry) {
      final entryDrawNo = _calculateDrawNoForDate(entry.createdAt);

      switch (_selectedFilter) {
        case HistoryFilter.thisWeek:
          return entryDrawNo >= currentDrawNo;
        case HistoryFilter.past:
          return entryDrawNo < currentDrawNo;
        case HistoryFilter.favorites:
          return entry.isFavorite;
        case HistoryFilter.winnersOnly:
          final rankInfo = _judgeRank(entry.numbers, _latestResult);
          return rankInfo.rank >= 1 && rankInfo.rank <= 5;
        case HistoryFilter.all:
          return true;
      }
    }).toList();

    return Column(
      children: [
        // 상단 최신 당첨 번호 미니 카드 & QR 스캔 버튼
        _buildLatestDrawHeader(currentDrawNo),

        // 필터 탭 바
        _buildFilterBar(displayedHistory.length),

        // 번호 카드 목록
        Expanded(
          child: displayedHistory.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                  itemCount: displayedHistory.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = displayedHistory[index];
                    final entryDrawNo =
                        _calculateDrawNoForDate(entry.createdAt);
                    final isThisWeek = entryDrawNo >= currentDrawNo;
                    final rankInfo = _judgeRank(entry.numbers, _latestResult);

                    final timeStr =
                        '${entry.createdAt.month}/${entry.createdAt.day} ${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';

                    return Dismissible(
                      key: ValueKey(
                          '${entry.createdAt.toIso8601String()}_${entry.title}_$index'),
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
                            Icon(Icons.delete_outline_rounded,
                                color: Colors.white, size: 24),
                            SizedBox(width: 6),
                            Text('삭제',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        _confirmDeleteEntry(entry);
                        return false;
                      },
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        borderRadius: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 카드 상단 헤더 (제목, 회차 배지, 당첨 뱃지, 즐겨찾기)
                            Row(
                              children: [
                                Icon(
                                  entry.title.contains('VIP')
                                      ? Icons.auto_awesome
                                      : Icons.tune,
                                  color: AppColors.goldText,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  entry.title,
                                  style: GoogleFonts.notoSansKr(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isThisWeek
                                        ? (AppColors.isLight
                                            ? const Color(0xFFFFF0C2)
                                            : AppColors.gold.withValues(alpha: 0.18))
                                        : (AppColors.isLight
                                            ? Colors.black.withValues(alpha: 0.05)
                                            : Colors.white.withValues(alpha: 0.08)),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isThisWeek
                                          ? (AppColors.isLight
                                              ? const Color(0xFFD4AF37)
                                              : AppColors.gold.withValues(alpha: 0.4))
                                          : Colors.transparent,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '$entryDrawNo회차',
                                    style: GoogleFonts.notoSansKr(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isThisWeek
                                          ? (AppColors.isLight
                                              ? const Color(0xFF855A00)
                                              : AppColors.gold)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const Spacer(),

                                // 당첨 판정 뱃지 (색상 & 가독성 개선)
                                _buildRankBadge(rankInfo),
                                const SizedBox(width: 8),

                                // 즐겨찾기 버튼
                                GestureDetector(
                                  onTap: () async {
                                    setState(() {
                                      entry.isFavorite = !entry.isFavorite;
                                    });
                                    await HistoryService.updateAll(
                                        widget.history);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      entry.isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: entry.isFavorite
                                          ? Colors.redAccent
                                          : AppColors.textHint,
                                      size: 19,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // 개별 삭제 버튼
                                GestureDetector(
                                  onTap: () => _confirmDeleteEntry(entry),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.textHint,
                                      size: 19,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // 공 번호 행 (일치 번호 하이라이트 적용)
                            LottoBallRow(
                              numbers: entry.numbers,
                              ballSize: 38,
                              matchedNumbers: _latestResult != null && isThisWeek
                                  ? rankInfo.matchedNumbers
                                  : null,
                              bonusNumber: _latestResult != null && isThisWeek
                                  ? _latestResult!.bonusNo
                                  : null,
                            ),

                            const SizedBox(height: 10),

                            // 하단 시간 정보 (중복 텍스트 제거)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '생성일시 $timeStr',
                                  style: GoogleFonts.notoSansKr(
                                    color: AppColors.textHint,
                                    fontSize: 11,
                                  ),
                                ),
                                if (rankInfo.rank >= 1 && rankInfo.rank <= 3)
                                  Row(
                                    children: [
                                      const Icon(Icons.celebration,
                                          size: 13, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(
                                        '축하합니다!',
                                        style: GoogleFonts.notoSansKr(
                                          color: AppColors.gold,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate(delay: Duration(milliseconds: index * 40))
                        .fadeIn(duration: 250.ms)
                        .slideX(begin: 0.04, end: 0, duration: 250.ms);
                  },
                ),
        ),
      ],
    );
  }

  /// 상단 최신 당첨 번호 요약 카드 & QR 스캔 버튼
  Widget _buildLatestDrawHeader(int currentDrawNo) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 6),
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
              Icon(Icons.emoji_events_rounded,
                  color: AppColors.goldText, size: 18),
              const SizedBox(width: 6),
              Text(
                '제 $currentDrawNo회 공식 당첨번호',
                style: GoogleFonts.notoSansKr(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // QR 스캔 버튼 (라이트/다크 모드 가독성 강화)
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const QrScannerView(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.isLight
                        ? const Color(0xFFFFF0C2)
                        : AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.isLight
                          ? const Color(0xFFD4AF37)
                          : AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_scanner,
                          size: 13, color: AppColors.goldText),
                      const SizedBox(width: 4),
                      Text(
                        '종이복권 QR',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.goldText,
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
          else if (_latestResult != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._latestResult!.numbers.map(
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
                  LottoBall(
                    number: _latestResult!.bonusNo,
                    size: 28,
                    isBonus: true,
                  ),
                ],
              ),
            )
          else
            Text(
              '추첨 결과를 불러오는 중입니다...',
              style: GoogleFonts.notoSansKr(
                  color: AppColors.textHint, fontSize: 12),
            ),
        ],
      ),
    );
  }

  /// 필터 탭 바
  Widget _buildFilterBar(int currentCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('이번 주 번호', HistoryFilter.thisWeek),
                const SizedBox(width: 6),
                _buildFilterChip('전체', HistoryFilter.all),
                const SizedBox(width: 6),
                _buildFilterChip('지난 회차', HistoryFilter.past),
                const SizedBox(width: 6),
                _buildFilterChip('당첨 번호 🏆', HistoryFilter.winnersOnly),
                const SizedBox(width: 6),
                _buildFilterChip('즐겨찾기 ⭐', HistoryFilter.favorites),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
              if (widget.history.isNotEmpty)
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.card,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: Row(
                          children: [
                            const Icon(Icons.delete_sweep_rounded,
                                color: Colors.redAccent, size: 22),
                            const SizedBox(width: 8),
                            Text('기록 전체 삭제',
                                style: GoogleFonts.notoSansKr(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17)),
                          ],
                        ),
                        content: Text(
                            '보관함의 모든 번호 기록을 삭제할까요?\n삭제된 기록은 복구할 수 없습니다.',
                            style: GoogleFonts.notoSansKr(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.5)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('취소',
                                style: GoogleFonts.notoSansKr(
                                    color: AppColors.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onClear();
                            },
                            child: Text('전체 삭제',
                                style: GoogleFonts.notoSansKr(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '전체 삭제',
                          style: GoogleFonts.notoSansKr(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, HistoryFilter filter) {
    final isSelected = _selectedFilter == filter;
    final isLight = AppColors.isLight;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isLight
                  ? const Color(0xFFFFF0C2)
                  : AppColors.gold.withValues(alpha: 0.2))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isLight ? const Color(0xFFD4AF37) : AppColors.gold)
                : AppColors.borderSubtle.withValues(alpha: 0.6),
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansKr(
            color: isSelected
                ? (isLight ? AppColors.goldDeep : AppColors.gold)
                : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 당첨 등수 뱃지 위젯 (라이트/다크 모드 완벽 대응)
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Text(
        info.label,
        style: GoogleFonts.notoSansKr(
          color: textColor,
          fontSize: 11,
          fontWeight: info.rank > 0 ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, color: AppColors.textHint, size: 56),
          const SizedBox(height: 14),
          Text(
            _selectedFilter == HistoryFilter.thisWeek
                ? '이번 주에 뽑은 번호가 없습니다.'
                : '보관된 번호가 없습니다.',
            style: GoogleFonts.notoSansKr(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'VIP 또는 커스텀 탭에서 번호를 뽑아보세요!',
            style: GoogleFonts.notoSansKr(
              color: AppColors.textHint,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
