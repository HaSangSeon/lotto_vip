import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/history_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../common_widgets.dart';
import '../lotto_ball.dart';

/// 🎯 내 번호 6자리 황금 밸런스 실시간 진단기
class CombinationDiagnosisCard extends StatefulWidget {
  final bool? isLight;

  const CombinationDiagnosisCard({
    super.key,
    this.isLight,
  });

  @override
  State<CombinationDiagnosisCard> createState() => _CombinationDiagnosisCardState();
}

class _CombinationDiagnosisCardState extends State<CombinationDiagnosisCard> {
  // 실제 통계 황금 밸런스에 부합하는 대표 예시 번호 (총합 157 황금구간, 홀3:짝3, 고3:저3, 연번 2쌍, 1~10 단번대 멸)
  List<int> _currentNumbers = [12, 13, 24, 33, 34, 41];
  bool _isSaving = false;

  void _generateRandomNumbers() {
    HapticFeedback.lightImpact();
    final rand = Random();
    final Set<int> nums = {};
    while (nums.length < 6) {
      nums.add(rand.nextInt(45) + 1);
    }
    setState(() {
      _currentNumbers = nums.toList()..sort();
    });
  }

  Future<void> _saveCurrentNumbers() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final upcomingDrawNo = HistoryService.calculateTargetDrawNo(DateTime.now());
      final existingHistory = await HistoryService.load();
      final isAlreadySaved = existingHistory.any((entry) =>
          entry.drawNo == upcomingDrawNo &&
          !entry.isTicket &&
          entry.numbers.length == _currentNumbers.length &&
          entry.numbers.every((n) => _currentNumbers.contains(n)));

      if (isAlreadySaved) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '이미 이번 주 보관함에 저장되어 있는 번호입니다.',
                      style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF21252B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final entry = LottoHistoryEntry(
        title: '제$upcomingDrawNo회 황금밸런스 진단번호',
        numbers: _currentNumbers,
        createdAt: DateTime.now(),
      );
      await HistoryService.save(entry);
      await NotificationService.scheduleWeeklyDrawNotification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '내 번호가 보관함에 성공적으로 저장되었습니다!',
                    style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF21252B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showNumberSelector() {
    final Set<int> tempSelected = Set.from(_currentNumbers);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isLight = AppColors.isLight;
          final bottomPadding = MediaQuery.paddingOf(context).bottom;

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF1E222D),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '진단할 번호 6개 선택 (${tempSelected.length}/6)',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() => tempSelected.clear());
                      },
                      child: Text('초기화', style: GoogleFonts.notoSansKr(color: Colors.redAccent)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    itemCount: 45,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final num = index + 1;
                      final isSelected = tempSelected.contains(num);
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setModalState(() {
                            if (isSelected) {
                              tempSelected.remove(num);
                            } else {
                              if (tempSelected.length < 6) {
                                tempSelected.add(num);
                              }
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.gold
                                : (isLight ? Colors.grey.shade100 : Colors.white10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.goldDark : Colors.transparent,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$num',
                              style: GoogleFonts.rajdhani(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.black
                                    : (isLight ? Colors.black87 : Colors.white),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: tempSelected.length == 6
                        ? () {
                            setState(() {
                              _currentNumbers = tempSelected.toList()..sort();
                            });
                            Navigator.pop(ctx);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      '진단 시작 (${tempSelected.length}/6)',
                      style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = widget.isLight ?? (Theme.of(context).brightness == Brightness.light);

    // 1. 총합 계산 (100~175 황금구간 25점, 85~99/176~190 근접 15점, 그 외 5점)
    final sum = _currentNumbers.fold<int>(0, (s, n) => s + n);
    int sumScore = 5;
    String sumStatus = '주의';
    if (sum >= 100 && sum <= 175) {
      sumScore = 25;
      sumStatus = '황금구간';
    } else if ((sum >= 85 && sum < 100) || (sum > 175 && sum <= 190)) {
      sumScore = 15;
      sumStatus = '근접';
    }

    // 2. 홀짝 비율 계산 (3:3, 4:2, 2:4 균형 20점, 5:1, 1:5 10점, 6:0, 0:6 0점)
    final oddCount = _currentNumbers.where((n) => n % 2 != 0).length;
    final evenCount = 6 - oddCount;
    int oddEvenScore = 0;
    String oddEvenStatus = '치우침';
    if (oddCount == 3 || oddCount == 2 || oddCount == 4) {
      oddEvenScore = 20;
      oddEvenStatus = '균형';
    } else if (oddCount == 1 || oddCount == 5) {
      oddEvenScore = 10;
      oddEvenStatus = '양호';
    }

    // 3. 고저 비율 (1~22 저 vs 23~45 고: 3:3, 4:2, 2:4 균형 15점, 5:1, 1:5 8점, 6:0 0점)
    final lowCount = _currentNumbers.where((n) => n <= 22).length;
    final highCount = 6 - lowCount;
    int highLowScore = 0;
    String highLowStatus = '치우침';
    if (lowCount >= 2 && lowCount <= 4) {
      highLowScore = 15;
      highLowStatus = '안정';
    } else if (lowCount == 1 || lowCount == 5) {
      highLowScore = 8;
      highLowStatus = '양호';
    }

    // 4. 연속번호 체크 (1~2쌍 포함 15점, 3쌍 이상 또는 미포함 5점)
    int consecCount = 0;
    for (int i = 0; i < _currentNumbers.length - 1; i++) {
      if (_currentNumbers[i + 1] - _currentNumbers[i] == 1) {
        consecCount++;
      }
    }
    int consecScore = 5;
    String consecStatus = consecCount > 0 ? '미포함' : '미포함';
    if (consecCount >= 1 && consecCount <= 2) {
      consecScore = 15;
      consecStatus = '포함(63%)';
    } else if (consecCount > 2) {
      consecScore = 5;
      consecStatus = '과다';
    }

    // 5. 구간 멸(滅) 분석 (5개 번호대 중 1~2개 구간 전멸 15점, 전체 분산 5점, 3개 이상 과다 전멸 5점)
    final z1 = _currentNumbers.where((n) => n <= 10).length;
    final z2 = _currentNumbers.where((n) => n >= 11 && n <= 20).length;
    final z3 = _currentNumbers.where((n) => n >= 21 && n <= 30).length;
    final z4 = _currentNumbers.where((n) => n >= 31 && n <= 40).length;
    final z5 = _currentNumbers.where((n) => n >= 41).length;
    final zeroCount = [z1, z2, z3, z4, z5].where((c) => c == 0).length;

    int zeroScore = 5;
    String zeroStatus = '전체분산';
    if (zeroCount >= 1 && zeroCount <= 2) {
      zeroScore = 15;
      zeroStatus = '멸발생(78%)';
    } else if (zeroCount >= 3) {
      zeroScore = 5;
      zeroStatus = '과다전멸';
    }

    // 종합 밸런스 점수 계산 (기본 점수 10점 + 최대 90점 = 100점 만점)
    final score = min(100, 10 + sumScore + oddEvenScore + highLowScore + consecScore + zeroScore);

    return GlassCard(
      gradientColors: isLight
          ? const [Color(0xFFFFFEFA), Color(0xFFFFF8E0)]
          : const [Color(0xFF181B28), Color(0xFF141722)],
      borderColor: isLight ? AppColors.lightGoldBorder.withValues(alpha: 0.35) : AppColors.borderGold,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigoAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.analytics_rounded, color: Colors.indigoAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '내 번호 황금 밸런스 진단기',
                            style: GoogleFonts.notoSansKr(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '조합의 당첨 통계 점수 즉시 측정',
                            style: GoogleFonts.notoSansKr(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _generateRandomNumbers,
                tooltip: '새 번호 랜덤 진단',
                icon: const Icon(Icons.casino_outlined, color: Colors.indigoAccent),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 번호 터치 선택 버튼 영역
          InkWell(
            onTap: _showNumberSelector,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _currentNumbers
                          .map((n) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: LottoBall(number: n, size: 36),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '터치하여 직접 번호 변경하기',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit_outlined, size: 12, color: AppColors.textHint),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 진단 결과 점수 박스
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: score >= 80
                    ? [const Color(0xFF1B5E20).withValues(alpha: 0.15), Colors.transparent]
                    : [const Color(0xFFE65100).withValues(alpha: 0.15), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: score >= 80 ? Colors.green.shade400 : Colors.orange.shade400,
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: score >= 80 ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$score점',
                    style: GoogleFonts.rajdhani(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        score >= 80 ? '🌟 상위 황금 밸런스 조합!' : '⚠️ 밸런스 보정이 권장되는 조합',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        score >= 80
                            ? '역대 1등 당첨 패턴(총합·홀짝·연번·구간멸)과 높은 일치율을 보입니다.'
                            : '총합 황금구간(100~175)이나 홀짝/구간 배분을 조정해 보세요.',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 세부 진단 5대 지표 그리드 (반응형 5열)
          Row(
            children: [
              _buildIndicator('총합', '$sum', sumScore >= 15, sumStatus),
              const SizedBox(width: 4),
              _buildIndicator('홀짝', '홀$oddCount:짝$evenCount', oddEvenScore >= 15, oddEvenStatus),
              const SizedBox(width: 4),
              _buildIndicator('고저', '저$lowCount:고$highCount', highLowScore >= 12, highLowStatus),
              const SizedBox(width: 4),
              _buildIndicator('연번', consecCount > 0 ? '$consecCount쌍' : '없음', consecScore >= 12, consecStatus),
              const SizedBox(width: 4),
              _buildIndicator('구간멸', zeroCount > 0 ? '$zeroCount개멸' : '분산', zeroScore >= 12, zeroStatus),
            ],
          ),

          const SizedBox(height: 14),

          // 보관함 저장 액션 버튼
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _saveCurrentNumbers,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bookmark_add_outlined, size: 18),
              label: Text(
                '이 번호 보관함에 저장하기 💾',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.goldText,
                backgroundColor: AppColors.gold.withValues(alpha: 0.08),
                side: BorderSide(
                  color: isLight
                      ? const Color(0xFFD4AF37)
                      : AppColors.gold.withValues(alpha: 0.6),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(String title, String value, bool isGood, String status) {
    final isLight = AppColors.isLight;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isGood ? Colors.teal.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: GoogleFonts.notoSansKr(fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                status,
                style: GoogleFonts.notoSansKr(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isGood ? Colors.teal : Colors.orangeAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
