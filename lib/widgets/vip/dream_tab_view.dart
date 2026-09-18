import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/dream_dictionary.dart';
import '../common_widgets.dart';
import '../lotto_ball.dart';

class DreamTabView extends StatefulWidget {
  const DreamTabView({super.key});

  @override
  State<DreamTabView> createState() => _DreamTabViewState();
}

class _DreamTabViewState extends State<DreamTabView> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _searchResults = DreamDictionary.popularKeywords;
  
  final List<String> _selectedDreams = [];
  List<int> _generatedNumbers = [];
  bool _isGenerating = false;
  String _luckyMessage = '';
  
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
      _generatedNumbers = []; // 리셋
    });
    FocusScope.of(context).unfocus(); // 키보드 내림
  }

  void _generateDreamNumbers() async {
    if (_selectedDreams.isEmpty) return;
    
    setState(() {
      _isGenerating = true;
      _generatedNumbers = [];
    });

    // 몽환적인 연출을 위해 약간의 딜레이
    await Future.delayed(const Duration(milliseconds: 1500));

    final random = Random();
    final Set<int> resultSet = Set<int>.from(_currentFixedNumbers);
    
    while (resultSet.length < 6) {
      resultSet.add(random.nextInt(45) + 1);
    }
    
    final finalNumbers = resultSet.toList()..sort();
    
    // 행운의 메시지 풀이 랜덤 선택
    final List<String> messages = [
      "이야, 이건 뭐 두말할 필요 없는 대박 꿈이네요! 엄청난 기운이 팍팍 느껴집니다. 오늘 무조건 이 좋은 기운 꽉 쥐고 가세요!",
      "간밤에 꾸신 꿈자리가 예사롭지 않습니다. 막혔던 금전운이 뻥 뚫리면서 크게 횡재수가 들어오는 형국이네요. 느낌이 아주 찌릿합니다!",
      "캬~ 꿈자리 기가 막히네요! 이런 기운이면 굳이 아등바등 안 해도 행운이 알아서 굴러들어올 관상입니다. 오늘 하루 기분 좋게 시작하세요!",
      "쉿! 이 기운은 원래 남한테 절대 말하면 안 되는 거 아시죠? 나만의 행운으로 조용히 챙겨가셔야 할 엄청 귀한 번호들입니다.",
      "아주 맑고 강한 재물운이 제대로 꼈습니다. 이 정도면 오늘 퇴근길에 복권방 앞을 그냥 지나치시면 며칠 밤낮으로 후회하실지도 모릅니다 하하!",
      "이 번호들끼리 궁합이 아주 찰떡이네요. 평소에 신경 쓰이던 골칫거리도 해결되고 뜻밖의 용돈도 생길 수 있는 기분 좋은 하루가 예상됩니다."
    ];
    final String selectedMessage = messages[random.nextInt(messages.length)];

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _generatedNumbers = finalNumbers;
        _luckyMessage = selectedMessage;
      });
    }
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
                    Text(
                      '꿈 해몽 번호 추출기',
                      style: GoogleFonts.notoSansKr(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                label: Text(
                  _isGenerating 
                      ? '신비로운 번호 추출 중...' 
                      : _selectedDreams.length == 1
                          ? '[${_selectedDreams.first}] 행운 번호 조합하기'
                          : '${_selectedDreams.length}개의 꿈으로 행운 번호 조합하기',
                  style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 16),
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

          // 3. 결과 뷰
          if (_generatedNumbers.isNotEmpty)
            GlassCard(
              gradientColors: isLight 
                  ? [const Color(0xFFFDFBF7), const Color(0xFFF9F5EC)]
                  : [const Color(0xFF161410), const Color(0xFF0A0907)],
              borderColor: AppColors.goldText.withValues(alpha: 0.6),
              shadows: [
                BoxShadow(
                  color: AppColors.goldText.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.goldText, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedDreams.join(', ')} 꿈이 점지해준 번호',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.goldText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LottoBallRow(numbers: _generatedNumbers, ballSize: 42)
                      .animate()
                      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 600.ms, curve: Curves.easeOutBack)
                      .fadeIn(duration: 600.ms),
                  const SizedBox(height: 24),
                  
                  // 프리미엄 해몽 풀이 박스
                  if (_luckyMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLight 
                              ? [Colors.white, const Color(0xFFF9F6F0)]
                              : [const Color(0xFF1A1814), const Color(0xFF100F0D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLight ? AppColors.lightGoldBorder : AppColors.borderGold.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.menu_book_rounded, size: 18, color: AppColors.goldText),
                              const SizedBox(width: 8),
                              Text(
                                '선택한 꿈 번호 풀이', 
                                style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._selectedDreams.map((dream) {
                            final nums = DreamDictionary.getNumbers(dream);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isLight ? const Color(0xFFFFF9ED) : const Color(0xFF2A2210),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.goldText.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      dream, 
                                      style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.goldText),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '➔ ${nums.join(", ")}의 기운', 
                                      style: GoogleFonts.notoSansKr(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, color: Colors.black12),
                          ),
                          
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.goldText.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Text('🔮', style: TextStyle(fontSize: 16)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _luckyMessage,
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 13.5, 
                                    height: 1.6, 
                                    color: AppColors.textPrimary, 
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }
}
