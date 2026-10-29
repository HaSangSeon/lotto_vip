import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import 'common_widgets.dart';
import 'lotto_ball.dart';
import 'vip/dream_tab_view.dart';
import 'vip/shake_tab_view.dart';
import 'custom_tab.dart';

class VipTab extends StatefulWidget {
  final bool? isLight;
  final int initialIndex;
  final ValueChanged<int>? onSubTabChanged;
  final TextEditingController ctrl;
  final List<int> vipNumbers;
  final VoidCallback onGenerate;
  final ValueChanged<String>? onBirthDateChanged;
  final AnimationController shimmerCtrl;
  final List<int> customNumbers;
  final List<int> includeNumbers;
  final List<int> excludeNumbers;
  final VoidCallback onOpenCustomDialog;
  final VoidCallback onGenerateCustom;
  final void Function(String title, List<int> numbers)? onShowDreamResult;

  const VipTab({
    super.key,
    this.isLight,
    this.initialIndex = 0,
    this.onSubTabChanged,
    required this.ctrl,
    required this.vipNumbers,
    required this.onGenerate,
    this.onBirthDateChanged,
    required this.shimmerCtrl,
    required this.customNumbers,
    required this.includeNumbers,
    required this.excludeNumbers,
    required this.onOpenCustomDialog,
    required this.onGenerateCustom,
    this.onShowDreamResult,
  });

  @override
  State<VipTab> createState() => _VipTabState();
}

class _VipTabState extends State<VipTab> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = widget.isLight ?? (Theme.of(context).brightness == Brightness.light);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          // 모드 전환 스위치 (꿈 해몽 | 생년월일 | 맞춤 필터)
          Container(
            margin: const EdgeInsets.only(bottom: 16, top: 4),
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: isLight
                  ? const Color(0xFFF0EAE0)
                  : const Color(0xFF10131C),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isLight
                    ? const Color(0xFFE2D6C3)
                    : Colors.white.withValues(alpha: 0.08),
                width: 0.9,
              ),
            ),
            child: Row(
              children: [
                _buildTabSegmentItem(
                  index: 0,
                  label: '흔들기',
                  icon: Icons.vibration_rounded,
                  isLight: isLight,
                ),
                _buildTabSegmentItem(
                  index: 1,
                  label: '꿈 해몽',
                  icon: Icons.nights_stay_rounded,
                  isLight: isLight,
                ),
                _buildTabSegmentItem(
                  index: 2,
                  label: '생년월일',
                  icon: Icons.cake_rounded,
                  isLight: isLight,
                ),
                _buildTabSegmentItem(
                  index: 3,
                  label: '맞춤 필터',
                  icon: Icons.tune_rounded,
                  isLight: isLight,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _selectedIndex == 0
                ? ShakeTabView(
                    isLight: isLight,
                    onShowResult: widget.onShowDreamResult,
                  )
                : _selectedIndex == 1
                    ? DreamTabView(
                        isLight: isLight,
                        onShowResult: widget.onShowDreamResult,
                      )
                    : _selectedIndex == 3
                        ? CustomTab(
                            isLight: isLight,
                            customNumbers: widget.customNumbers,
                            includeNumbers: widget.includeNumbers,
                            excludeNumbers: widget.excludeNumbers,
                            onOpenDialog: widget.onOpenCustomDialog,
                            onGenerate: widget.onGenerateCustom,
                          )
                        : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            // VIP 카드
                            GlassCard(
            gradientColors: isLight
                ? const [Color(0xFFFFFEFA), Color(0xFFFFF8E0)]
                : const [Color(0xFF1E1800), Color(0xFF0F0D00)],
            borderColor: isLight
                ? AppColors.lightGoldBorder.withValues(alpha: 0.45)
                : AppColors.borderGold,
            shadows: isLight
                ? [
                    BoxShadow(
                      color: AppColors.goldDark.withValues(alpha: 0.12),
                      blurRadius: 28,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 0,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                        color: Colors.black54,
                        blurRadius: 12,
                        offset: const Offset(0, 6)),
                  ],
            child: Column(
              children: [
                // 엠블럼 (듀얼 링 골드 엠블럼)
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: isLight ? 0.22 : 0.25),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: isLight
                          ? AppColors.lightGoldBorder.withValues(alpha: 0.5)
                          : AppColors.gold.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLight
                            ? const Color(0xFFFFF7E6)
                            : AppColors.gold.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: isLight ? AppColors.goldDeep : AppColors.gold,
                        size: 32,
                      ),
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 2400.ms, color: AppColors.goldLight.withValues(alpha: 0.35)),

                const SizedBox(height: 14),
                Text(
                  '오늘 나의 행운 번호',
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '내 생년월일(6자리)을 입력하시면\n오늘 당신에게 딱 맞는 행운의 번호를 분석해 드립니다.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),

                const GoldDivider(),

                // 입력 필드
                Container(
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLight
                          ? const Color(0xFFD4A017).withValues(alpha: 0.35)
                          : AppColors.borderGold,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: widget.ctrl,
                    onChanged: widget.onBirthDateChanged,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      color: AppColors.goldText,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      border: InputBorder.none,
                      hintText: '700101',
                      hintStyle: GoogleFonts.rajdhani(
                        color: AppColors.textHint.withValues(alpha: 0.5),
                        fontSize: 26,
                        letterSpacing: 5,
                      ),
                      prefixIcon: Icon(Icons.cake_rounded, color: AppColors.goldText, size: 22),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Center(
                          widthFactor: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isLight
                                  ? const Color(0xFFF0EBE1)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '6자리',
                              style: GoogleFonts.notoSansKr(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 생성 버튼
                SizedBox(
                  width: double.infinity,
                  child: isLight
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFB8860B), Color(0xFF92690A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.goldDark.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              widget.onGenerate();
                            },
                            icon: const Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.white),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '오늘 나의 행운 번호 추출하기',
                                maxLines: 1,
                                style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            widget.onGenerate();
                          },
                          icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '오늘 나의 행운 번호 추출하기',
                              maxLines: 1,
                              style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 결과 카드
          if (widget.vipNumbers.isNotEmpty)
            GlassCard(
              gradientColors: isLight
                  ? const [Color(0xFFFFFDF5), Color(0xFFFFF8E5)]
                  : const [Color(0xFF1A1800), Color(0xFF0D0B00)],
              borderColor: AppColors.borderGold,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars, color: AppColors.goldText, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '오늘 뽑은 행운 번호',
                          style: GoogleFonts.notoSansKr(
                            color: AppColors.goldText,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LottoBallRow(numbers: widget.vipNumbers, ballSize: 48)
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOutBack),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          // 안내 카드 (럭셔리 팁 배너)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: isLight
                  ? const Color(0xFFFAF6EE)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLight
                    ? const Color(0xFFE8DCC8)
                    : Colors.white.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: isLight ? AppColors.goldDeep : AppColors.gold,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '생년월일 정보는 외부 서버 전송 없이 기기에 안전하게 보관되며, 매일 오늘의 새로운 행운 번호를 분석해 드립니다.',
                    style: GoogleFonts.notoSansKr(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSegmentItem({
    required int index,
    required String label,
    required IconData icon,
    required bool isLight,
  }) {
    final isSelected = _selectedIndex == index;
    final activeTextColor = isLight ? const Color(0xFF7A5200) : AppColors.gold;
    final inactiveTextColor = isLight ? const Color(0xFF7E756B) : const Color(0xFF8E94A8);
    final activeIconColor = isLight ? const Color(0xFF855A00) : AppColors.gold;
    final inactiveIconColor = isLight ? const Color(0xFF9E9284) : const Color(0xFF6B7288);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            setState(() => _selectedIndex = index);
            widget.onSubTabChanged?.call(index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            gradient: isSelected
                ? (isLight
                    ? const LinearGradient(
                        colors: [Colors.white, Color(0xFFFCF9F2)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.gold.withValues(alpha: 0.22),
                          AppColors.gold.withValues(alpha: 0.12),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ))
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (isLight
                      ? const Color(0xFFD4AF37).withValues(alpha: 0.65)
                      : AppColors.gold.withValues(alpha: 0.75))
                  : Colors.transparent,
              width: 1.0,
            ),
            boxShadow: isSelected
                ? (isLight
                    ? [
                        BoxShadow(
                          color: const Color(0xFFB8860B).withValues(alpha: 0.10),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ])
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? activeIconColor : inactiveIconColor,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  maxLines: 1,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: -0.2,
                    color: isSelected ? activeTextColor : inactiveTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

