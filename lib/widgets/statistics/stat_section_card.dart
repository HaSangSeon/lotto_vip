import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../common_widgets.dart';
import '../lotto_ball.dart';

/// 통계 공통 순위 가로 스크롤 카드 위젯 (HOT/COLD/미출현/트렌드)
class StatSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> data;
  final IconData icon;
  final Color iconColor;
  final String countKey;
  final String unit;
  final Color? countColor;

  const StatSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.data,
    required this.icon,
    required this.iconColor,
    this.countKey = 'count',
    this.unit = '회',
    this.countColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSansKr(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
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
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white,
                  Colors.white,
                  Colors.white.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.88, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 4, right: 32, top: 12, bottom: 12),
              child: Row(
                children: data.map((item) {
                  final value = item[countKey];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        LottoBall(number: item['number'] as int, size: 44),
                        const SizedBox(height: 8),
                        Text(
                          '$value$unit',
                          style: GoogleFonts.rajdhani(
                            color: countColor ?? AppColors.textSecondary,
                            fontSize: 14,
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
        ],
      ),
    );
  }
}
