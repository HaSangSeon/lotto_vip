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

  const HistoryTab({
    super.key,
    required this.history,
    required this.onClear,
  });

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  bool _showOnlyFavorites = false;

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
                      title: Text('기록 삭제', style: GoogleFonts.notoSansKr(color: Colors.white)),
                      content: Text('모든 기록을 삭제할까요?',
                          style: GoogleFonts.notoSansKr(color: AppColors.textSecondary)),
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
                          child: Text('삭제', style: GoogleFonts.notoSansKr(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.delete_outline, size: 16, color: AppColors.textSecondary),
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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = displayedHistory[index];
              final timeStr =
                  '${entry.createdAt.month}/${entry.createdAt.day} ${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';
              return GlassCard(
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
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            setState(() {
                              entry.isFavorite = !entry.isFavorite;
                            });
                            await HistoryService.updateAll(widget.history);
                          },
                          child: Icon(
                            entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: entry.isFavorite ? Colors.redAccent : AppColors.textHint,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LottoBallRow(numbers: entry.numbers, ballSize: 38),
                  ],
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
