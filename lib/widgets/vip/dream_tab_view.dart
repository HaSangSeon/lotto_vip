import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/dream_dictionary.dart';
import '../../services/history_service.dart';
import '../../services/notification_service.dart';
import '../common_widgets.dart';
import '../result_sheet.dart';
import '../dialogs/calculation_loading_dialog.dart';

class DreamTabView extends StatefulWidget {
  final void Function(String title, List<int> numbers)? onShowResult;

  const DreamTabView({
    super.key,
    this.onShowResult,
  });

  @override
  State<DreamTabView> createState() => _DreamTabViewState();
}

class _DreamTabViewState extends State<DreamTabView> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _searchResults = DreamDictionary.popularKeywords;
  
  final List<String> _selectedDreams = [];
  
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
    FocusScope.of(context).unfocus();

    // 맞춤필터와 동일한 로딩 팝업 다이얼로그 표시
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const CalculationLoadingDialog(
        title: '🌙 꿈해몽 알고리즘 연산',
        step1: '선택된 꿈 키워드 고정수 분석 중...',
        step2: '신비로운 역대 로또 최적 조합 도출 중...',
      ),
    );

    if (!mounted) return;

    final random = Random();
    final Set<int> resultSet = Set<int>.from(_currentFixedNumbers);
    
    while (resultSet.length < 6) {
      resultSet.add(random.nextInt(45) + 1);
    }
    
    final finalNumbers = resultSet.toList()..sort();

    if (widget.onShowResult != null) {
      widget.onShowResult!('🌙 꿈해몽 행운 번호', finalNumbers);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ResultSheet(
          title: '🌙 꿈해몽 행운 번호',
          numbers: finalNumbers,
          isVip: true,
        ),
      );
    }

    // 보관함(히스토리)에 자동 저장 로직
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
      onTap: () {
        HapticFeedback.selectionClick();
        _onDreamSelected(keyword);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? (isLight
                  ? const LinearGradient(
                      colors: [Color(0xFFB8860B), Color(0xFF92690A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [AppColors.gold, AppColors.goldDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ))
              : null,
          color: isSelected
              ? null
              : (isLight ? Colors.white : Colors.white.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isLight
                    ? const Color(0xFFE2D6C3)
                    : Colors.white.withValues(alpha: 0.1)),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isLight ? AppColors.goldDark : AppColors.gold).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          '#$keyword',
          style: GoogleFonts.notoSansKr(
            color: isSelected
                ? Colors.white
                : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
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
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.goldText, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        '선택된 꿈 키워드 (${_selectedDreams.length}/3)',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.goldText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

                Container(
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isLight
                          ? const Color(0xFFD4A017).withValues(alpha: 0.35)
                          : AppColors.borderGold,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.notoSansKr(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: '예: 돼지, 불, 황금, 용, 조상님...',
                      hintStyle: GoogleFonts.notoSansKr(
                        color: AppColors.textHint.withValues(alpha: 0.6),
                        fontSize: 13.5,
                      ),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.goldText, size: 21),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      _searchCtrl.text.isEmpty ? Icons.whatshot_rounded : Icons.manage_search_rounded,
                      color: _searchCtrl.text.isEmpty ? const Color(0xFFE65100) : AppColors.goldText,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _searchCtrl.text.isEmpty ? '인기 길몽 키워드' : '검색 결과',
                      style: GoogleFonts.notoSansKr(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
              child: Container(
                decoration: BoxDecoration(
                  gradient: isLight
                      ? const LinearGradient(
                          colors: [Color(0xFFB8860B), Color(0xFF92690A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isLight ? AppColors.goldDark : AppColors.gold).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _generateDreamNumbers();
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _selectedDreams.length == 1
                          ? '[${_selectedDreams.first}] 행운 번호 조합하기'
                          : '${_selectedDreams.length}개 꿈으로 행운 번호 조합하기',
                      style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLight ? Colors.transparent : AppColors.gold,
                    foregroundColor: isLight ? Colors.white : Colors.black,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ).animate().slideY(begin: 0.3, end: 0, duration: 300.ms).fadeIn(),
            
            const SizedBox(height: 20),
          ],

        ],
      ),
    );
  }
}
