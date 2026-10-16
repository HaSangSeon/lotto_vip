import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import 'statistics/stat_section_card.dart';
import 'statistics/odd_even_ratio_card.dart';
import 'statistics/companion_number_card.dart';

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  // 최근 5주 트렌드 데이터 (가장 핫한 단기 번호 TOP 7)
  final List<Map<String, dynamic>> _recentHotNumbers = [
    {'number': 7, 'count': 3},
    {'number': 14, 'count': 2},
    {'number': 21, 'count': 2},
    {'number': 33, 'count': 2},
    {'number': 42, 'count': 2},
    {'number': 11, 'count': 2},
    {'number': 28, 'count': 2},
  ];

  // 실제 동행복권 역대 누적 통계 기반 더미 데이터
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

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;

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

          // 1. 최근 5주 단기 핫 트렌드
          StatSectionCard(
            title: '🔥 최근 5주 단기 핫 트렌드 TOP 7',
            subtitle: '최근 5주 동안 가장 많이 쏟아져 나온 번호들',
            data: _recentHotNumbers,
            icon: Icons.trending_up_rounded,
            iconColor: isLight ? const Color(0xFFE91E63) : const Color(0xFFFF4081),
            countKey: 'count',
            unit: '회',
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

          const SizedBox(height: 20),

          // 2. HOT 번호 TOP 7 (역대)
          StatSectionCard(
            title: 'HOT 번호 TOP 7 (역대)',
            subtitle: '1회차부터 역대 가장 많이 출현한 번호들',
            data: _hotNumbers,
            icon: Icons.local_fire_department,
            iconColor: Colors.redAccent,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

          const SizedBox(height: 20),

          // 3. COLD 번호 BOTTOM 7
          StatSectionCard(
            title: 'COLD 번호 BOTTOM 7',
            subtitle: '역대 가장 적게 출현한 희귀 번호들',
            data: _coldNumbers,
            icon: Icons.ac_unit,
            iconColor: Colors.blueAccent,
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

          const SizedBox(height: 20),

          // 4. 장기 미출현 번호
          StatSectionCard(
            title: '나올 때가 된 장기 미출현 번호',
            subtitle: '최근 가장 오랫동안 당첨되지 않은 번호들',
            data: _overdueNumbers,
            icon: Icons.hourglass_empty_rounded,
            iconColor: Colors.orangeAccent,
            countKey: 'weeks',
            unit: '주째',
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

          const SizedBox(height: 20),

          // 5. 짝꿍 번호 (궁합) 섹션
          const CompanionNumberCard()
              .animate()
              .fadeIn(duration: 400.ms, delay: 50.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms),

          const SizedBox(height: 20),

          // 6. 짝홀 비율 섹션
          const OddEvenRatioCard()
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms),
        ],
      ),
    );
  }
}
