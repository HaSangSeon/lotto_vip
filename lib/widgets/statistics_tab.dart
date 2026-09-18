import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import 'common_widgets.dart';
import 'lotto_ball.dart';

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  // 실제 동행복권 역대 누적 통계 기반 더미 데이터 (예시)
  final List<Map<String, dynamic>> _hotNumbers = [
    {'number': 43, 'count': 192},
    {'number': 34, 'count': 188},
    {'number': 12, 'count': 186},
    {'number': 27, 'count': 184},
    {'number': 13, 'count': 183},
    {'number': 18, 'count': 182},
    {'number': 39, 'count': 180},
  ];

  final List<Map<String, dynamic>> _coldNumbers = [
    {'number': 9, 'count': 138},
    {'number': 29, 'count': 141},
    {'number': 41, 'count': 143},
    {'number': 22, 'count': 145},
    {'number': 23, 'count': 145},
    {'number': 8, 'count': 148},
    {'number': 32, 'count': 149},
  ];

  final List<Map<String, dynamic>> _overdueNumbers = [
    {'number': 2, 'weeks': 15},
    {'number': 16, 'weeks': 12},
    {'number': 25, 'weeks': 11},
    {'number': 31, 'weeks': 11},
    {'number': 4, 'weeks': 9},
    {'number': 11, 'weeks': 8},
    {'number': 38, 'weeks': 8},
  ];

  Widget _buildStatSection(
    String title,
    String subtitle,
    List<Map<String, dynamic>> data,
    IconData icon,
    Color iconColor, {
    String countKey = 'count',
    String unit = '회',
    Color? countColor,
  }) {
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '역대 로또 빅데이터',
            style: GoogleFonts.notoSansKr(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1회차부터 현재까지의 전체 당첨 데이터를 분석합니다.',
            style: GoogleFonts.notoSansKr(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildStatSection(
            'HOT 번호 TOP 7',
            '역대 가장 많이 출현한 행운의 번호들',
            _hotNumbers,
            Icons.local_fire_department,
            Colors.redAccent,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
          
          const SizedBox(height: 20),
          
          _buildStatSection(
            'COLD 번호 BOTTOM 7',
            '역대 가장 적게 출현한 희귀 번호들',
            _coldNumbers,
            Icons.ac_unit,
            Colors.blueAccent,
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

          const SizedBox(height: 20),
          
          _buildStatSection(
            '나올 때가 된 장기 미출현 번호',
            '최근 가장 오랫동안 당첨되지 않은 번호들',
            _overdueNumbers,
            Icons.hourglass_empty_rounded,
            Colors.orangeAccent,
            countKey: 'weeks',
            unit: '주째',
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

          const SizedBox(height: 20),

          // 짝홀 비율
          GlassCard(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRatioItem('홀 3 : 짝 3', '26.8%'),
                    _buildRatioItem('홀 4 : 짝 2', '24.1%'),
                    _buildRatioItem('홀 2 : 짝 4', '23.4%'),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.isLight ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '💡 팁: 번호를 선택하실 때 홀수와 짝수를 3:3이나 4:2 비율로 섞는 것이 통계적으로 가장 당첨 확률이 높습니다.',
                    style: GoogleFonts.notoSansKr(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildRatioItem(String ratio, String percent) {
    return Column(
      children: [
        Text(
          ratio,
          style: GoogleFonts.notoSansKr(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          percent,
          style: GoogleFonts.rajdhani(
            color: AppColors.goldText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
