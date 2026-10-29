import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../common_widgets.dart';

/// 가장 유리한 홀짝 비율 통계 카드 위젯
class OddEvenRatioCard extends StatelessWidget {
  final bool? isLight;

  const OddEvenRatioCard({
    super.key,
    this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsLight = isLight ?? AppColors.isLight;

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
                  color: AppColors.goldText.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.pie_chart_rounded, color: AppColors.goldText, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                '가장 유리한 홀짝 비율',
                style: GoogleFonts.notoSansKr(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildRatioItem('홀 3 : 짝 3', '26.8%', isHighest: true),
              const SizedBox(width: 8),
              _buildRatioItem('홀 4 : 짝 2', '24.1%'),
              const SizedBox(width: 8),
              _buildRatioItem('홀 2 : 짝 4', '23.4%'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.isLight
                  ? Colors.blueGrey.shade50.withValues(alpha: 0.5)
                  : Colors.blueGrey.shade900.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.isLight
                    ? Colors.blueGrey.shade100
                    : Colors.blueGrey.shade800,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.goldText, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '번호를 선택하실 때 홀수와 짝수를 3:3이나 4:2 비율로 섞는 것이 통계적으로 가장 당첨 확률이 높습니다.',
                    style: GoogleFonts.notoSansKr(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
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

  Widget _buildRatioItem(String ratio, String percent, {bool isHighest = false}) {
    final RegExp regex = RegExp(r'홀 (\d+) : 짝 (\d+)');
    final match = regex.firstMatch(ratio);
    int oddCount = 0;
    int evenCount = 0;
    if (match != null) {
      oddCount = int.tryParse(match.group(1)!) ?? 0;
      evenCount = int.tryParse(match.group(2)!) ?? 0;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isHighest
              ? AppColors.goldText.withValues(alpha: 0.1)
              : (AppColors.isLight ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighest
                ? AppColors.goldText.withValues(alpha: 0.5)
                : (AppColors.isLight ? const Color(0xFFD0C5B4) : Colors.white.withValues(alpha: 0.12)),
            width: 1.5,
          ),
          boxShadow: isHighest
              ? [
                  BoxShadow(
                    color: AppColors.goldText.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isHighest)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.goldText,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'BEST',
                    style: GoogleFonts.rajdhani(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (!isHighest) const SizedBox(height: 22),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                percent,
                style: GoogleFonts.rajdhani(
                  color: isHighest ? AppColors.goldText : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge('홀', oddCount.toString(), Colors.redAccent),
                  const SizedBox(width: 4),
                  Text(':', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  _buildBadge('짝', evenCount.toString(), Colors.blueAccent),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildVisualBar(oddCount, evenCount),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      alignment: Alignment.center,
      child: Text(
        '$label $value',
        style: GoogleFonts.notoSansKr(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildVisualBar(int odd, int even) {
    final int total = odd + even;
    if (total == 0) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        height: 4,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            if (odd > 0)
              Expanded(
                flex: odd,
                child: Container(color: Colors.redAccent.withValues(alpha: 0.8)),
              ),
            if (even > 0)
              Expanded(
                flex: even,
                child: Container(color: Colors.blueAccent.withValues(alpha: 0.8)),
              ),
          ],
        ),
      ),
    );
  }
}
