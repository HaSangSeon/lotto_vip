import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/safe_google_fonts.dart';

class DrawSelectDialog extends StatefulWidget {
  final int latestDrwNo;
  final int? currentDrwNo;

  const DrawSelectDialog({
    super.key,
    required this.latestDrwNo,
    this.currentDrwNo,
  });

  @override
  State<DrawSelectDialog> createState() => _DrawSelectDialogState();
}

class _DrawSelectDialogState extends State<DrawSelectDialog> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentDrwNo?.toString() ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final val = int.tryParse(_controller.text.trim());
    if (val != null && val >= 1 && val <= widget.latestDrwNo) {
      Navigator.pop(context, val);
    } else {
      setState(() {
        _errorText = '1 ~ ${widget.latestDrwNo} 사이의 숫자를 입력해 주세요.';
      });
    }
  }

  Widget _buildQuickChip(String label, bool isLight, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isLight
                ? Colors.black.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isLight
                  ? Colors.black.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;

    return SafeArea(
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLight
                ? AppColors.lightGoldBorder.withValues(alpha: 0.7)
                : AppColors.borderGold,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isLight ? AppColors.goldDeep : AppColors.gold)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_calendar_rounded,
                    size: 18,
                    color: isLight ? AppColors.goldDeep : AppColors.gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '회차 직접 선택',
                        style: GoogleFonts.notoSansKr(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 16.5,
                        ),
                      ),
                      Text(
                        '1회 ~ 최신 ${widget.latestDrwNo}회 조회',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11.5,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: isLight
                  ? Colors.black.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildQuickChip('최신 회차', isLight, () {
                  _controller.text = widget.latestDrwNo.toString();
                  setState(() => _errorText = null);
                }),
                const SizedBox(width: 6),
                _buildQuickChip('1,000회', isLight, () {
                  _controller.text = '1000';
                  setState(() => _errorText = null);
                }),
                const SizedBox(width: 6),
                _buildQuickChip('1,200회', isLight, () {
                  _controller.text = '1200';
                  setState(() => _errorText = null);
                }),
                const SizedBox(width: 6),
                _buildQuickChip('1회', isLight, () {
                  _controller.text = '1';
                  setState(() => _errorText = null);
                }),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              onSubmitted: (_) => _submit(),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
              style: GoogleFonts.rajdhani(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isLight ? AppColors.goldDeep : AppColors.gold,
                letterSpacing: 1.5,
              ),
              decoration: InputDecoration(
                hintText: '회차 번호 입력',
                hintStyle: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: AppColors.textHint,
                  letterSpacing: 0,
                ),
                suffixText: '회',
                suffixStyle: GoogleFonts.notoSansKr(
                  color: isLight ? AppColors.goldDeep : AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                filled: true,
                fillColor: isLight
                    ? const Color(0xFFF9F7F2)
                    : Colors.white.withValues(alpha: 0.04),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isLight
                        ? AppColors.lightGoldBorder.withValues(alpha: 0.5)
                        : AppColors.borderGold.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isLight ? AppColors.goldDeep : AppColors.gold,
                    width: 1.8,
                  ),
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: GoogleFonts.notoSansKr(
                  fontSize: 11.5,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(
                        color: isLight
                            ? Colors.grey.shade300
                            : Colors.white.withValues(alpha: 0.15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      '취소',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLight
                          ? AppColors.goldDark
                          : AppColors.gold,
                      foregroundColor:
                          isLight ? Colors.white : Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      '조회하기',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}
