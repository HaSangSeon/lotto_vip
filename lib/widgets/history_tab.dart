import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import '../services/history_service.dart';
import 'common_widgets.dart';
import 'lotto_ball.dart';

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
  bool _showOnlyFavorites = false;

  void _confirmDeleteEntry(LottoHistoryEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
            const SizedBox(width: 8),
            Text('번호 기록 삭제', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
    if (widget.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: AppColors.textHint, size: 64),
            const SizedBox(height: 16),
            Text(
              '생성 기록이 없습니다.',
              style: GoogleFonts.notoSansKr(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '번호를 생성하면 여기에 기록됩니다.',
              style: GoogleFonts.notoSansKr(
                color: AppColors.textHint,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final displayedHistory = _showOnlyFavorites
        ? widget.history.where((e) => e.isFavorite).toList()
        : widget.history;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Text(
                '총 ${displayedHistory.length}개',
                style: GoogleFonts.notoSansKr(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              FilterChip(
                label: Text(
                  '즐겨찾기',
                  style: GoogleFonts.notoSansKr(
                    color: _showOnlyFavorites ? AppColors.gold : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: _showOnlyFavorites,
                onSelected: (val) => setState(() => _showOnlyFavorites = val),
                backgroundColor: Colors.transparent,
                selectedColor: AppColors.gold.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _showOnlyFavorites ? AppColors.gold : AppColors.borderSubtle),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('기록 전체 삭제', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: Text('모든 기록을 삭제할까요?\n삭제된 기록은 복구할 수 없습니다.',
                          style: GoogleFonts.notoSansKr(color: AppColors.textSecondary, height: 1.4)),
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
                          child: Text('전체 삭제', style: GoogleFonts.notoSansKr(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.textSecondary),
                label: Text('전체 삭제',
                    style: GoogleFonts.notoSansKr(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            itemCount: displayedHistory.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = displayedHistory[index];
              final timeStr =
                  '${entry.createdAt.month}/${entry.createdAt.day} ${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';
              return Dismissible(
                key: ValueKey('${entry.createdAt.toIso8601String()}_${entry.title}_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
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
                  return false; // Let the confirmation dialog handle deletion
                },
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            entry.title.contains('VIP') ? Icons.auto_awesome : Icons.tune,
                            color: AppColors.gold,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            entry.title,
                            style: GoogleFonts.notoSansKr(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timeStr,
                            style: GoogleFonts.notoSansKr(
                              color: AppColors.textHint,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // 즐겨찾기 버튼
                          GestureDetector(
                            onTap: () async {
                              setState(() {
                                entry.isFavorite = !entry.isFavorite;
                              });
                              await HistoryService.updateAll(widget.history);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: entry.isFavorite ? Colors.redAccent : AppColors.textHint,
                                size: 19,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 개별 삭제 버튼
                          GestureDetector(
                            onTap: () => _confirmDeleteEntry(entry),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.textHint,
                                size: 19,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LottoBallRow(numbers: entry.numbers, ballSize: 38),
                    ],
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: index * 50))
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.05, end: 0, duration: 300.ms);
            },
          ),
        ),
      ],
    );
  }
}
