import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';
import 'lotto_ball.dart';

class ResultSheet extends StatefulWidget {
  final String title;
  final List<int> numbers;
  final bool isVip;

  const ResultSheet({
    super.key,
    required this.title,
    required this.numbers,
    required this.isVip,
  });

  @override
  State<ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<ResultSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _shareImage() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final image = await _screenshotController.capture(pixelRatio: 3.0);
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/lotto_vip_result.png').create();
        await imagePath.writeAsBytes(image);
        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: '내 로또 신통 번호: ${widget.numbers.join(', ')}',
        );
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.isLight
              ? const [Color(0xFFFFFDF5), Color(0xFFFFF8E5)]
              : const [Color(0xFF1E1800), Color(0xFF0F0D00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.borderGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Screenshot(
            controller: _screenshotController,
            child: Container(
              color: Colors.transparent,
              child: Column(
                children: [
                  widget.isVip
                      ? Icon(
                          Icons.auto_awesome,
                          color: AppColors.isLight ? AppColors.goldDark : AppColors.gold,
                          size: 48,
                        )
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(
                            duration: 1500.ms,
                            color: AppColors.isLight ? AppColors.goldDeep : AppColors.goldLight,
                          )
                      : Icon(
                          Icons.tune,
                          color: AppColors.isLight ? AppColors.goldDark : AppColors.gold,
                          size: 48,
                        ),

                  const SizedBox(height: 12),

                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: AppColors.isLight
                          ? [AppColors.goldDeep, AppColors.goldDark]
                          : [AppColors.goldLight, AppColors.gold],
                    ).createShader(b),
                    child: Text(
                      widget.title,
                      style: GoogleFonts.notoSansKr(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.isVip ? '오늘 나만을 위해 준비된 행운의 번호입니다!' : '나만의 맞춤 번호 조합이 완성되었습니다!',
                    style: GoogleFonts.notoSansKr(color: AppColors.textSecondary, fontSize: 13),
                  ),

                  const SizedBox(height: 28),

                  LottoBallRow(numbers: widget.numbers, ballSize: 52)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 500.ms, curve: Curves.elasticOut),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSharing ? null : _shareImage,
                  icon: _isSharing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.share,
                          size: 18,
                          color: AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
                        ),
                  label: Text(
                    '공유',
                    style: GoogleFonts.notoSansKr(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: AppColors.isLight ? Colors.white : Colors.transparent,
                    foregroundColor: AppColors.isLight ? AppColors.goldDeep : AppColors.gold,
                    side: BorderSide(
                      color: AppColors.isLight
                          ? AppColors.goldDark.withValues(alpha: 0.6)
                          : AppColors.gold.withValues(alpha: 0.5),
                      width: 1.3,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: AppColors.isLight ? AppColors.goldDark : AppColors.gold,
                    foregroundColor: AppColors.isLight ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: AppColors.isLight ? 2 : 6,
                    shadowColor: AppColors.isLight
                        ? AppColors.goldDark.withValues(alpha: 0.3)
                        : AppColors.gold.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    '확인',
                    style: GoogleFonts.notoSansKr(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.isLight ? Colors.white : Colors.black,
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
}
