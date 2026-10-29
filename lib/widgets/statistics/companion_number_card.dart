import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/statistics_service.dart';
import '../../theme/app_theme.dart';
import '../common_widgets.dart';
import '../lotto_ball.dart';

/// 내 번호 짝꿍 찾기 (궁합 번호) 섹션 위젯
class CompanionNumberCard extends StatefulWidget {
  final bool? isLight;
  final int initialNumber;
  final ValueChanged<int>? onNumberChanged;

  const CompanionNumberCard({
    super.key,
    this.isLight,
    this.initialNumber = 7,
    this.onNumberChanged,
  });

  @override
  State<CompanionNumberCard> createState() => _CompanionNumberCardState();
}

class _CompanionNumberCardState extends State<CompanionNumberCard> {
  late int _selectedCompanionNumber;

  @override
  void initState() {
    super.initState();
    _selectedCompanionNumber = widget.initialNumber;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIsLight = widget.isLight ?? AppColors.isLight;
    final List<Map<String, dynamic>> companionData =
        StatisticsService.getCompanionNumbers(_selectedCompanionNumber);

    return GlassCard(
      gradientColors: effectiveIsLight
          ? const [Color(0xFFFFFEFA), Color(0xFFFFF8E0)]
          : const [Color(0xFF181B28), Color(0xFF141722)],
      borderColor: effectiveIsLight ? AppColors.lightGoldBorder.withValues(alpha: 0.35) : AppColors.borderGold,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.purpleAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '내 번호 짝꿍 찾기 (궁합)',
                      style: GoogleFonts.notoSansKr(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '고정수와 가장 같이 많이 나온 번호들',
                      style: GoogleFonts.notoSansKr(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // 번호 선택기
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () => _showNumberSelectModal(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.isLight ? Colors.white : Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LottoBall(number: _selectedCompanionNumber, size: 28),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 짝꿍 번호 결과 뱃지
              Expanded(
                flex: 5,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white,
                        Colors.white,
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.85, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 2, right: 24, top: 12, bottom: 12),
                    child: Row(
                      children: companionData.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            children: [
                              LottoBall(number: item['number'] as int, size: 36),
                              const SizedBox(height: 4),
                              Text(
                                '${item['count']}회',
                                style: GoogleFonts.rajdhani(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNumberSelectModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.isLight ? AppColors.lightGoldBorder : AppColors.borderGold,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.15),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                '고정수 선택',
                style: GoogleFonts.notoSansKr(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '궁합을 알고 싶은 번호를 선택해주세요.',
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 6,
                ),
                itemCount: 45,
                itemBuilder: (context, index) {
                  final number = index + 1;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCompanionNumber = number;
                      });
                      widget.onNumberChanged?.call(number);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: _selectedCompanionNumber == number
                            ? Border.all(color: AppColors.gold, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: LottoBall(number: number, size: 34),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
