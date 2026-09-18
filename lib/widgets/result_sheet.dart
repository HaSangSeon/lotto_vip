import 'dart:io';
import 'dart:math';
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
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(imagePath.path)],
            text: '[LOTTO VIP] 🍀 1등 당첨 기원 행운 번호: ${widget.numbers.join(', ')}',
          ),
        );
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  /// 카카오톡 및 메신저 공유 시 단독 이미지로 빛나는 프리미엄 VIP 행운 카드 (라이트/다크 테마 완벽 대응)
  Widget _buildShareCard(BuildContext context) {
    final isLight = AppColors.isLight;
    final now = DateTime.now();
    final dateStr =
        '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    // 테마별 색상 팔레트
    final cardBgGradient = isLight
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFDF8),
              Color(0xFFFAF3E3),
              Color(0xFFF3E7C6),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF241F18),
              Color(0xFF171410),
              Color(0xFF0F0E0C),
            ],
          );

    final cardBorderColor = isLight
        ? const Color(0xFFD4A017).withValues(alpha: 0.6)
        : const Color(0xFFD4AF37).withValues(alpha: 0.75);

    final cardShadowColor = isLight
        ? const Color(0xFFD4A017).withValues(alpha: 0.15)
        : const Color(0xFFD4AF37).withValues(alpha: 0.22);

    final innerBorderColor = isLight
        ? const Color(0xFFD4A017).withValues(alpha: 0.25)
        : const Color(0xFFD4AF37).withValues(alpha: 0.25);

    final glowColor = isLight
        ? const Color(0xFFFFD700).withValues(alpha: 0.12)
        : const Color(0xFFFFD700).withValues(alpha: 0.2);

    final badgeBgColor = isLight
        ? const Color(0xFFD4A017).withValues(alpha: 0.1)
        : const Color(0xFFD4AF37).withValues(alpha: 0.12);

    final badgeBorderColor = isLight
        ? const Color(0xFFD4A017).withValues(alpha: 0.4)
        : const Color(0xFFD4AF37).withValues(alpha: 0.4);

    final badgeTextColor = isLight
        ? const Color(0xFF855A00)
        : const Color(0xFFFFE082);

    final badgeIconColor = isLight
        ? const Color(0xFF855A00)
        : const Color(0xFFFFD700);

    final dateTextColor = isLight
        ? const Color(0xFF855A00).withValues(alpha: 0.75)
        : const Color(0xFFB89E72);

    final emblemGradient = isLight
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF9EA), Color(0xFFFFE9A8)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF382F1D), Color(0xFF1E1A12)],
          );

    final emblemBorderColor = isLight
        ? const Color(0xFFD4A017).withValues(alpha: 0.55)
        : const Color(0xFFFFD700).withValues(alpha: 0.5);

    final emblemIconColor = isLight
        ? const Color(0xFF855A00)
        : const Color(0xFFFFD700);

    final titleColors = isLight
        ? const [Color(0xFF593800), Color(0xFF7D5000), Color(0xFFA16800)]
        : const [Color(0xFFFFF6D6), Color(0xFFFFD700), Color(0xFFE5A93C)];

    final subtitleColor = isLight
        ? const Color(0xFF6E5F52)
        : const Color(0xFFC7BBAA);

    final trayBgColor = isLight
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.55);

    final trayBorderColor = isLight
        ? const Color(0xFFD4A017).withValues(alpha: 0.35)
        : const Color(0xFFD4AF37).withValues(alpha: 0.35);

    final trayShadowColor = isLight
        ? const Color(0xFFD4A017).withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.4);

    final dividerColor = isLight
        ? const Color(0xFFD4A017).withValues(alpha: 0.35)
        : const Color(0xFFD4AF37).withValues(alpha: 0.45);

    final footerTextColor = isLight
        ? const Color(0xFF855A00)
        : const Color(0xFFD4AF37);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: cardBgGradient,
        border: Border.all(
          color: cardBorderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            blurRadius: 24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: isLight
                ? Colors.black.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.65),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.5),
        child: Stack(
          children: [
            // 상단 은은한 골드 앰비언트 글로우
            Positioned(
              top: -60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 240,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        glowColor,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 내부 이중 프레임 (VIP 골드 듀얼 라인)
            Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: innerBorderColor,
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. 헤더: 발급 날짜 + '로또신통' 앱 검색 뱃지
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$dateStr 발급',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: dateTextColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: badgeBorderColor,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 11,
                              color: badgeIconColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "스토어 '로또신통' 검색",
                              style: GoogleFonts.notoSansKr(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: badgeTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 2. 중앙 엠블럼 아이콘
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: emblemGradient,
                      border: Border.all(
                        color: emblemBorderColor,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isLight
                              ? const Color(0xFFD4A017).withValues(alpha: 0.2)
                              : const Color(0xFFFFD700).withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.auto_awesome,
                        color: emblemIconColor,
                        size: 26,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. 타이틀 (골드 그라데이션 - 공통 행운 로또 번호)
                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: titleColors,
                    ).createShader(b),
                    child: Text(
                      '✨ 행운의 로또 번호',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansKr(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  // 4. 서브타이틀 (공통 축원 문구)
                  Text(
                    '1등 당첨의 기운을 담은 특별한 추천 번호입니다',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansKr(
                      color: subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. 로또 볼 전용 트레이 (골드 테두리 인셋 플레이트)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: trayBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: trayBorderColor,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: trayShadowColor,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: LottoBallRow(
                      numbers: widget.numbers,
                      ballSize: 46,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 6. 골드 그라데이션 구분선
                  Container(
                    height: 1,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          dividerColor,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 7. 하단 축원 문구 (충분한 하단 여백 확보)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🍀', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '1등 당첨의 기운을 담았습니다 • 행운을 빕니다',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSansKr(
                            color: footerTextColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          max(16.0, MediaQuery.of(context).padding.bottom + 8.0),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFFFFDF8) : const Color(0xFF141311),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isLight
                ? AppColors.goldDark.withValues(alpha: 0.3)
                : AppColors.gold.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isLight
                  ? Colors.black.withValues(alpha: 0.08)
                  : AppColors.gold.withValues(alpha: 0.12),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 드래그 핸들
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isLight
                      ? Colors.black.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 캡처 대상: 프리미엄 VIP 공유 카드 전체
              Screenshot(
                controller: _screenshotController,
                child: _buildShareCard(context)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ),

              const SizedBox(height: 20),

              // 하단 버튼 영역 (52px 고정 높이 완벽 대칭 & 통일된 스타일)
              Row(
                children: [
                  // 공유 버튼
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isSharing ? null : _shareImage,
                        icon: _isSharing
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isLight ? AppColors.goldDeep : AppColors.gold,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.share_rounded,
                                size: 18,
                                color: isLight ? AppColors.goldDeep : AppColors.gold,
                              ),
                        label: Text(
                          '공유',
                          style: GoogleFonts.notoSansKr(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isLight ? AppColors.goldDeep : AppColors.gold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: isLight ? Colors.white : const Color(0xFF1E1A14),
                          foregroundColor: isLight ? AppColors.goldDeep : AppColors.gold,
                          side: BorderSide(
                            color: isLight
                                ? AppColors.goldDark.withValues(alpha: 0.65)
                                : AppColors.gold.withValues(alpha: 0.55),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 확인 버튼
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: isLight ? Colors.white : Colors.black,
                        ),
                        label: Text(
                          '확인',
                          style: GoogleFonts.notoSansKr(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isLight ? Colors.white : Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: isLight ? AppColors.goldDark : AppColors.gold,
                          foregroundColor: isLight ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: isLight ? 2 : 4,
                          shadowColor: isLight
                              ? AppColors.goldDark.withValues(alpha: 0.3)
                              : AppColors.gold.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


