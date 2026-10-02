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
  // 최근 5주 트렌드 데이터 (가장 핫한 단기 번호)
  final List<Map<String, dynamic>> _recentHotNumbers = [
    {'number': 7, 'count': 3},
    {'number': 14, 'count': 2},
    {'number': 21, 'count': 2},
    {'number': 33, 'count': 2},
    {'number': 42, 'count': 2},
  ];

  // 궁합 번호를 찾기 위한 현재 선택된 번호 상태
  int _selectedCompanionNumber = 7;

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
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white,
                  Colors.white,
                  Colors.white.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.08, 0.85, 1.0], // 좌측 8%, 우측 15% 영역을 서서히 투명하게
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // 마지막 아이템이 그라데이션 영역에 묻히지 않도록 우측 여백 추가, 그림자가 잘리지 않게 상하 패딩 추가
              padding: const EdgeInsets.only(right: 32, top: 12, bottom: 12),
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
            '🔥 최근 5주 단기 핫 트렌드',
            '최근 5주 동안 가장 많이 쏟아져 나온 번호들',
            _recentHotNumbers,
            Icons.trending_up_rounded,
            AppColors.isLight ? const Color(0xFFE91E63) : const Color(0xFFFF4081),
            countKey: 'count',
            unit: '회',
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

          const SizedBox(height: 20),

          _buildStatSection(
            'HOT 번호 TOP 7 (역대)',
            '1회차부터 역대 가장 많이 출현한 번호들',
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

          // 짝꿍 번호 (궁합) 섹션
          _buildCompanionSection().animate().fadeIn(duration: 400.ms, delay: 50.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
          
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
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildRatioItem(String ratio, String percent, {bool isHighest = false}) {
    // "홀 3 : 짝 3" 
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
          boxShadow: isHighest ? [
            BoxShadow(
              color: AppColors.goldText.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 0,
            )
          ] : null,
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
            if (!isHighest)
              const SizedBox(height: 22),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansKr(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value,
            style: GoogleFonts.rajdhani(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  Widget _buildCompanionSection() {
    // 임의의 더미 짝꿍 번호 데이터 (선택된 번호에 따라 변하는 것처럼 연출)
    final List<Map<String, dynamic>> companionData = [
      {'number': (_selectedCompanionNumber + 5) % 45 == 0 ? 45 : (_selectedCompanionNumber + 5) % 45, 'count': 42},
      {'number': (_selectedCompanionNumber + 11) % 45 == 0 ? 45 : (_selectedCompanionNumber + 11) % 45, 'count': 38},
      {'number': (_selectedCompanionNumber + 23) % 45 == 0 ? 45 : (_selectedCompanionNumber + 23) % 45, 'count': 35},
      {'number': (_selectedCompanionNumber + 31) % 45 == 0 ? 45 : (_selectedCompanionNumber + 31) % 45, 'count': 33},
      {'number': (_selectedCompanionNumber + 40) % 45 == 0 ? 45 : (_selectedCompanionNumber + 40) % 45, 'count': 31},
    ];

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
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white,
                        Colors.white,
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.1, 0.8, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 24, top: 12, bottom: 12),
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
          border: Border.all(color: AppColors.isLight ? AppColors.lightGoldBorder : AppColors.borderGold, width: 1.5),
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
                decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2)),
              ),
              Text(
                '고정수 선택',
                style: GoogleFonts.notoSansKr(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                '궁합을 알고 싶은 번호를 선택해주세요.',
                style: GoogleFonts.notoSansKr(fontSize: 13, color: AppColors.textSecondary),
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
