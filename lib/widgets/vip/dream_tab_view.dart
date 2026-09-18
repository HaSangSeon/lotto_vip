import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/dream_dictionary.dart';
import '../../services/history_service.dart';
import '../../services/notification_service.dart';
import '../common_widgets.dart';
import '../result_sheet.dart';

class DreamTabView extends StatefulWidget {
  const DreamTabView({super.key});

  @override
  State<DreamTabView> createState() => _DreamTabViewState();
}

class _DreamTabViewState extends State<DreamTabView> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _searchResults = DreamDictionary.popularKeywords;
  
  final List<String> _selectedDreams = [];
  bool _isGenerating = false;
  
  // 현재 선택된 꿈들로 만들 수 있는 고정수 계산
  Set<int> get _currentFixedNumbers {
    final Set<int> result = {};
    for (final dream in _selectedDreams) {
      result.addAll(DreamDictionary.getNumbers(dream));
    }
    // 6개를 초과하면 앞에서부터 6개만 자르기
    final list = result.toList();
    if (list.length > 6) {
      return list.sublist(0, 6).toSet();
    }
    return result;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchResults = DreamDictionary.search(query);
    });
  }

  void _onDreamSelected(String dream) {
    setState(() {
      if (_selectedDreams.contains(dream)) {
        _selectedDreams.remove(dream);
      } else {
        if (_selectedDreams.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('꿈 키워드는 최대 3개까지만 선택할 수 있습니다.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.isLight ? Colors.black87 : Colors.white70,
            ),
          );
          return;
        }
        _selectedDreams.add(dream);
      }
    });
    FocusScope.of(context).unfocus(); // 키보드 내림
  }

  void _generateDreamNumbers() async {
    if (_selectedDreams.isEmpty) return;
    
    setState(() {
      _isGenerating = true;
    });

    // 몽환적인 연출을 위해 약간의 딜레이
    await Future.delayed(const Duration(milliseconds: 1500));

    final random = Random();
    final Set<int> resultSet = Set<int>.from(_currentFixedNumbers);
    
    while (resultSet.length < 6) {
      resultSet.add(random.nextInt(45) + 1);
    }
    
    final finalNumbers = resultSet.toList()..sort();

    if (mounted) {
      setState(() {
        _isGenerating = false;
      });

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ResultSheet(
          title: '🌙 꿈해몽 행운 번호',
          numbers: finalNumbers,
          isVip: true,
        ),
      );
    }

    // 보관함(히스토리)에 자동 저장 로직 추가
    final upcomingDrawNo = HistoryService.calculateTargetDrawNo(DateTime.now());
    final dreamNames = _selectedDreams.join(', ');
    final entry = LottoHistoryEntry(
      title: '제$upcomingDrawNo회 꿈해몽 ($dreamNames)',
      numbers: finalNumbers,
      createdAt: DateTime.now(),
    );
    await HistoryService.save(entry);
    await NotificationService.scheduleWeeklyDrawNotification();
  }

  Widget _buildKeywordChip(String keyword, bool isSelected) {
    final isLight = AppColors.isLight;
    return InkWell(
      onTap: () => _onDreamSelected(keyword),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isLight ? AppColors.goldDark : AppColors.gold)
              : (isLight ? Colors.white : Colors.black.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Colors.transparent 
                : (isLight ? AppColors.lightGoldBorder : AppColors.borderGold),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: (isLight ? AppColors.goldDark : AppColors.gold).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Text(
          '#$keyword',
          style: GoogleFonts.notoSansKr(
            color: isSelected 
                ? (isLight ? Colors.white : Colors.black)
                : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 검색 영역
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.nights_stay, color: AppColors.goldText, size: 24)
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 2000.ms),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '꿈 해몽 번호 추출기',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '원하시는 꿈 키워드를 최대 3개까지 여러 개 선택해보세요.\n꿈에 얽힌 행운의 고정수를 추출합니다.',
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textHint,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                
                if (_selectedDreams.isNotEmpty) ...[
                  Text(
                    '✨ 선택된 꿈',
                    style: GoogleFonts.notoSansKr(
                      color: AppColors.goldText,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: _selectedDreams.map((kw) {
                      return _buildKeywordChip(kw, true);
                    }).toList(),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 20),
                ],

                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: '예: 돼지, 불, 똥, 조상님...',
                    hintStyle: GoogleFonts.notoSansKr(color: AppColors.textHint),
                    prefixIcon: Icon(Icons.search, color: AppColors.goldText),
                    filled: true,
                    fillColor: isLight ? Colors.white : Colors.black.withValues(alpha: 0.2),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isLight ? AppColors.lightGoldBorder : AppColors.borderGold.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isLight ? AppColors.lightGoldBorder : AppColors.borderGold.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.goldText,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _searchCtrl.text.isEmpty ? '🔥 인기 길몽 TOP' : '🔍 검색 결과',
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_searchResults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        '일치하는 꿈 키워드가 없습니다.\n다른 단어로 검색해보세요!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansKr(color: AppColors.textHint),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: _searchResults.map((kw) {
                      return _buildKeywordChip(kw, _selectedDreams.contains(kw));
                    }).toList(),
                  ).animate().fadeIn(duration: 400.ms),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // 2. 추출 버튼
          if (_selectedDreams.isNotEmpty) ...[
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateDreamNumbers,
                icon: _isGenerating 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _isGenerating 
                        ? '신비로운 번호 추출 중...' 
                        : _selectedDreams.length == 1
                            ? '[${_selectedDreams.first}] 행운 번호 조합하기'
                            : '${_selectedDreams.length}개의 꿈으로 행운 번호 조합하기',
                    style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldText,
                  foregroundColor: isLight ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: AppColors.goldText.withValues(alpha: 0.5),
                ),
              ),
            ).animate().slideY(begin: 0.5, end: 0, duration: 400.ms).fadeIn(),
            
            const SizedBox(height: 20),
          ],

        ],
      ),
    );
  }
}
