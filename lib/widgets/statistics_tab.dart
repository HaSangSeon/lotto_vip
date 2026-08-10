import 'package:flutter/material.dart';
import '../utils/safe_google_fonts.dart';

import '../theme/app_theme.dart';
import '../services/statistics_service.dart';
import 'common_widgets.dart';
import 'lotto_ball.dart';

class StatisticsTab extends StatelessWidget {
  const StatisticsTab({super.key});

  Widget _buildStatRow(String title, List<MapEntry<int, int>> data, Color accentColor, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.notoSansKr(
                  color: AppColors.isLight ? Colors.black87 : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: data.map((entry) {
              return Column(
                children: [
                  LottoBall(number: entry.key, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    '${entry.value}회',
                    style: GoogleFonts.rajdhani(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotNumbers = StatisticsService.getHotNumbers(5);
    final coldNumbers = StatisticsService.getColdNumbers(5);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SectionTitle(
            title: '번호 통계 분석',
            subtitle: '역대 누적 데이터 기반 핫 & 콜드 넘버',
            icon: Icons.analytics,
          ),
          const SizedBox(height: 24),
          _buildStatRow(
            'HOT 가장 많이 나온 번호',
            hotNumbers,
            Colors.redAccent,
            Icons.local_fire_department,
          ),
          const SizedBox(height: 20),
          _buildStatRow(
            'COLD 가장 적게 나온 번호',
            coldNumbers,
            Colors.blueAccent,
            Icons.ac_unit,
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textHint),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '위 통계는 역대 당첨 번호를 누적 분석한 자료입니다. 번호 선택 시 참고용으로만 활용해 주세요.',
                    style: GoogleFonts.notoSansKr(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
