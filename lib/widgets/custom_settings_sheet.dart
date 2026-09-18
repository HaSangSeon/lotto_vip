import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CustomSettingsSheet extends StatefulWidget {
  final List<int> includeNumbers;
  final List<int> excludeNumbers;
  final Function(List<int>, List<int>) onChanged;

  const CustomSettingsSheet({
    super.key,
    required this.includeNumbers,
    required this.excludeNumbers,
    required this.onChanged,
  });

  @override
  State<CustomSettingsSheet> createState() => _CustomSettingsSheetState();
}

class _CustomSettingsSheetState extends State<CustomSettingsSheet>
    with SingleTickerProviderStateMixin {
  late List<int> _inc;
  late List<int> _exc;
  String? _warningMessage;
  Timer? _warningTimer;
  late AnimationController _warningAnimCtrl;
  late Animation<double> _warningFadeAnim;

  @override
  void initState() {
    super.initState();
    _inc = List.from(widget.includeNumbers);
    _exc = List.from(widget.excludeNumbers);
    _warningAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _warningFadeAnim = CurvedAnimation(
      parent: _warningAnimCtrl,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _warningTimer?.cancel();
    _warningAnimCtrl.dispose();
    super.dispose();
  }

  void _showInSheetWarning(String message) {
    _warningTimer?.cancel();
    setState(() => _warningMessage = message);
    _warningAnimCtrl.forward(from: 0.0);
    _warningTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _warningAnimCtrl.reverse().then((_) {
          if (mounted) setState(() => _warningMessage = null);
        });
      }
    });
  }

  void _onTapNumber(int num) {
    setState(() {
      final isInc = _inc.contains(num);
      final isExc = _exc.contains(num);
      if (isInc) {
        // 꼭 넣기 → 빼기
        if (_exc.length < 39) {
          _inc.remove(num);
          _exc.add(num);
          _warningMessage = null;
        } else {
          _showInSheetWarning('제외수는 최대 39개까지만 선택 가능합니다.');
        }
      } else if (isExc) {
        // 빼기 → 일반
        _exc.remove(num);
        _warningMessage = null;
      } else {
        // 일반 → 꼭 넣기
        if (_inc.length < 5) {
          _inc.add(num);
          _warningMessage = null;
        } else {
          _showInSheetWarning('고정수는 최대 5개까지만 선택할 수 있습니다.');
        }
      }
      widget.onChanged(_inc, _exc);
    });
  }

  void _resetAll() {
    setState(() {
      _inc.clear();
      _exc.clear();
      _warningMessage = null;
    });
    widget.onChanged(_inc, _exc);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;
    final hasFilter = _inc.isNotEmpty || _exc.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight
                ? const [Color(0xFFFFFDF8), Color(0xFFF8F3EA)]
                : const [Color(0xFF181B28), Color(0xFF10121C)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isLight
                ? AppColors.lightGoldBorder.withValues(alpha: 0.45)
                : AppColors.borderGold.withValues(alpha: 0.5),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.10 : 0.35),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            // ── 드래그 핸들 ──────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isLight
                    ? const Color(0xFFD4C8B4)
                    : Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // ── 헤더: 타이틀 + 카운터 배지 + 초기화 ─────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLight
                          ? const Color(0xFFFFF0C2)
                          : AppColors.gold.withValues(alpha: 0.15),
                      border: Border.all(
                        color: isLight
                            ? AppColors.lightGoldBorder.withValues(alpha: 0.6)
                            : AppColors.gold.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 19,
                      color: AppColors.goldText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '고정수 / 제외수 필터 설정',
                          style: GoogleFonts.notoSansKr(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '번호를 터치해 고정수·제외수를 설정하세요',
                          style: GoogleFonts.notoSansKr(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 초기화 버튼
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: hasFilter ? _resetAll : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: hasFilter
                              ? (isLight
                                  ? const Color(0xFFFAF0E0)
                                  : Colors.white.withValues(alpha: 0.07))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: hasFilter
                                ? (isLight
                                    ? AppColors.lightGoldBorder
                                        .withValues(alpha: 0.5)
                                    : AppColors.borderSubtle)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          '초기화',
                          style: GoogleFonts.notoSansKr(
                            color: hasFilter
                                ? AppColors.goldText
                                : AppColors.textHint,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── 상태 카운터 배지 바 (가로 1단 배치로 대화면 공간 확보) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  // 고정수 카운터
                  Expanded(
                    child: _buildCounterBadge(
                      label: '고정수',
                      subLabel: '꼭 넣기',
                      count: _inc.count,
                      maxCount: 5,
                      primaryColor: const Color(0xFF1976D2),
                      glowColor: const Color(0xFF42A5F5),
                      icon: Icons.add_circle_rounded,
                      isLight: isLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 제외수 카운터
                  Expanded(
                    child: _buildCounterBadge(
                      label: '제외수',
                      subLabel: '빼기',
                      count: _exc.count,
                      maxCount: 39,
                      primaryColor: const Color(0xFFD32F2F),
                      glowColor: const Color(0xFFEF5350),
                      icon: Icons.remove_circle_rounded,
                      isLight: isLight,
                    ),
                  ),
                ],
              ),
            ),

            // ── 조작 안내 칩 ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isLight
                      ? Colors.blue.withValues(alpha: 0.05)
                      : Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 13,
                        color: isLight
                            ? Colors.blue.shade700
                            : Colors.blue.shade300),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '터치할 때마다: 기본 → 고정수(파랑) → 제외수(빨강) 순 변경',
                        style: GoogleFonts.notoSansKr(
                          color: isLight
                              ? Colors.blue.shade700
                              : Colors.blue.shade200,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 번호 그리드 (1 ~ 45) ────────────────────────
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: 45,
                itemBuilder: (context, idx) {
                  final num = idx + 1;
                  final isInc = _inc.contains(num);
                  final isExc = _exc.contains(num);
                  return _buildNumberCell(
                      num, isInc, isExc, isLight);
                },
              ),
            ),

            // ── 경고 토스트 ──────────────────────────────────
            if (_warningMessage != null)
              FadeTransition(
                opacity: _warningFadeAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: isLight
                          ? const Color(0xFFFBE9E7)
                          : const Color(0xFF3A1010),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFEF5350)
                            .withValues(alpha: 0.55),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD32F2F)
                              .withValues(alpha: 0.2),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_rounded,
                            color: Color(0xFFEF5350), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _warningMessage!,
                            style: GoogleFonts.notoSansKr(
                              color: isLight
                                  ? const Color(0xFFB71C1C)
                                  : const Color(0xFFFFCDD2),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── 하단 액션 버튼 (닫기 전용) ─────────────────────
            SafeArea(
              top: false,
              bottom: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFF8F3EA)
                      : const Color(0xFF10121C),
                  border: Border(
                    top: BorderSide(
                      color: isLight
                          ? AppColors.lightGoldBorder.withValues(alpha: 0.5)
                          : AppColors.borderGold.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                ),
                child: _buildConfirmButton(isLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 카운터 배지 위젯 ────────────────────────────────────────────
  Widget _buildCounterBadge({
    required String label,
    String? subLabel,
    required int count,
    required int maxCount,
    required Color primaryColor,
    required Color glowColor,
    required IconData icon,
    required bool isLight,
  }) {
    final isFull = count >= maxCount;
    final displayColor = isFull ? glowColor : primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isLight
            ? displayColor.withValues(alpha: 0.07)
            : displayColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: displayColor.withValues(alpha: count > 0 ? 0.45 : 0.2),
          width: count > 0 ? 1.3 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: displayColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: count > 0 ? displayColor : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (subLabel != null)
                  Text(
                    subLabel,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHint,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // 카운트 칩
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: count > 0
                  ? displayColor
                  : (isLight
                      ? Colors.black.withValues(alpha: 0.07)
                      : Colors.white.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '$count / $maxCount',
              style: GoogleFonts.rajdhani(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: count > 0
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 번호 셀 위젯 ────────────────────────────────────────────────
  Widget _buildNumberCell(int num, bool isInc, bool isExc, bool isLight) {
    Color? bgColor;
    List<Color>? gradColors;
    Color borderColor;
    Color textColor;

    if (isInc) {
      gradColors = const [Color(0xFF1E88E5), Color(0xFF0D47A1)];
      borderColor = const Color(0xFF64B5F6);
      textColor = Colors.white;
    } else if (isExc) {
      gradColors = const [Color(0xFFE53935), Color(0xFFB71C1C)];
      borderColor = const Color(0xFFEF9A9A);
      textColor = Colors.white;
    } else {
      bgColor = isLight
          ? Colors.white
          : AppColors.surface;
      borderColor = isLight
          ? AppColors.lightGoldBorder.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.1);
      textColor = AppColors.textSecondary;
    }

    return GestureDetector(
      onTap: () => _onTapNumber(num),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradColors != null
              ? LinearGradient(
                  colors: gradColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: gradColors == null ? bgColor : null,
          border: Border.all(color: borderColor, width: isInc || isExc ? 1.8 : 1.0),
          boxShadow: (isInc || isExc)
              ? [
                  BoxShadow(
                    color: (isInc ? const Color(0xFF1E88E5) : const Color(0xFFE53935))
                        .withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.05 : 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Text(
              num.toString(),
              style: GoogleFonts.rajdhani(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 닫기 전용 하단 버튼 ─────────────────────────────────────
  Widget _buildConfirmButton(bool isLight) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLight
                  ? const [Color(0xFFE6B800), Color(0xFFC99700), Color(0xFFA67600)]
                  : const [Color(0xFFFFDF73), Color(0xFFFFC837), Color(0xFFD49A00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isLight ? const Color(0xFFC99700) : const Color(0xFFFFC837))
                    .withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 22, color: Color(0xFF140E00)),
              const SizedBox(width: 8),
              Text(
                '선택 완료 및 닫기',
                style: GoogleFonts.notoSansKr(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.5,
                  color: const Color(0xFF140E00),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _ListCount on List {
  int get count => length;
}
