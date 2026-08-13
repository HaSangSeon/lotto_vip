import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CustomSettingsSheet extends StatefulWidget {
  final List<int> includeNumbers;
  final List<int> excludeNumbers;
  final Function(List<int> inc, List<int> exc) onChanged;
  final VoidCallback onGenerate;

  const CustomSettingsSheet({
    super.key,
    required this.includeNumbers,
    required this.excludeNumbers,
    required this.onChanged,
    required this.onGenerate,
  });

  @override
  State<CustomSettingsSheet> createState() => _CustomSettingsSheetState();
}

class _CustomSettingsSheetState extends State<CustomSettingsSheet> {
  late List<int> _inc;
  late List<int> _exc;
  String? _warningMessage;
  Timer? _warningTimer;

  @override
  void initState() {
    super.initState();
    _inc = List.from(widget.includeNumbers);
    _exc = List.from(widget.excludeNumbers);
  }

  @override
  void dispose() {
    _warningTimer?.cancel();
    super.dispose();
  }

  void _showInSheetWarning(String message) {
    _warningTimer?.cancel();
    setState(() {
      _warningMessage = message;
    });
    _warningTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _warningMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.borderGold)),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // 핸들
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      Text(
                        '번호 설정',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() {
                          _inc.clear();
                          _exc.clear();
                          _warningMessage = null;
                          widget.onChanged(_inc, _exc);
                        }),
                        child: Text('초기화',
                            style: GoogleFonts.notoSansKr(color: AppColors.textSecondary, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

                // 범례 및 설명
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.isLight ? Colors.blue.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _legend(Colors.blue, '1번 누르면: 꼭 넣기 (${_inc.length}/5개)'),
                            const SizedBox(width: 14),
                            _legend(Colors.red, '2번 누르면: 빼기 (${_exc.length}/39개)'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '💡 번호를 누를 때마다 [일반 -> 꼭 넣기 -> 빼기] 순서로 바뀝니다.',
                          style: GoogleFonts.notoSansKr(
                            color: AppColors.isLight ? Colors.blue.shade700 : Colors.blue.shade200,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: GridView.builder(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: 45,
                    itemBuilder: (context, idx) {
                      final num = idx + 1;
                      final isInc = _inc.contains(num);
                      final isExc = _exc.contains(num);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isInc) {
                              // 꼭 넣기 -> 빼기
                              if (_exc.length < 39) {
                                _inc.remove(num);
                                _exc.add(num);
                                _warningMessage = null;
                              } else {
                                _showInSheetWarning('⚠️ 제외수는 최대 39개까지만 선택 가능합니다.');
                              }
                            } else if (isExc) {
                              // 빼기 -> 일반
                              _exc.remove(num);
                              _warningMessage = null;
                            } else {
                              // 일반 -> 꼭 넣기
                              if (_inc.length < 5) {
                                _inc.add(num);
                                _warningMessage = null;
                              } else {
                                _showInSheetWarning('⚠️ 고정수는 최대 5개까지만 선택할 수 있습니다.');
                              }
                            }
                            widget.onChanged(_inc, _exc);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isInc
                                ? const LinearGradient(
                                    colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : isExc
                                    ? const LinearGradient(
                                        colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                            color: (!isInc && !isExc) ? AppColors.surface : null,
                            border: Border.all(
                              color: isInc
                                  ? Colors.blue.shade300
                                  : isExc
                                      ? Colors.red.shade300
                                      : AppColors.borderSubtle,
                              width: isInc || isExc ? 2 : 1,
                            ),
                            boxShadow: isInc || isExc
                                ? [
                                    BoxShadow(
                                      color:
                                          (isInc ? Colors.blue : Colors.red).withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            num.toString(),
                            style: GoogleFonts.rajdhani(
                              color: (isInc || isExc) ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 하단 버튼
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).padding.bottom + 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onGenerate,
                      icon: const Icon(Icons.shuffle_rounded, size: 20),
                      label: Text(
                        '번호 생성하기',
                        style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, fontSize: 16),
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
                ),
              ],
            ),

            // 실시간 플로팅 경고 토스트 배너
            Positioned(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).padding.bottom + 84,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _warningMessage != null
                    ? Container(
                        key: ValueKey(_warningMessage),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _warningMessage!,
                                style: GoogleFonts.notoSansKr(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.notoSansKr(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
