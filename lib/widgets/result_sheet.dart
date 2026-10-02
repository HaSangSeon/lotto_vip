import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gal/gal.dart';

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

  Future<void> _saveImage() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final image = await _screenshotController.capture(pixelRatio: 3.0);
      if (image != null) {
        final hasAccess = await Gal.hasAccess(toAlbum: true);
        if (!hasAccess) {
          await Gal.requestAccess(toAlbum: true);
        }
        final directory = await getTemporaryDirectory();
        final imageFile = File('${directory.path}/lotto_vip_save_${DateTime.now().millisecondsSinceEpoch}.png');
        await imageFile.writeAsBytes(image);
        await Gal.putImage(imageFile.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미지가 갤러리에 저장되었습니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Save image error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미지 저장에 실패했습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _shareToKakaoTalk() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final numbersText = widget.numbers.join(', ');
      final appUrl = Uri.parse('https://play.google.com/store/apps/details?id=com.sintong.lotto');

      final image = await _screenshotController.capture(pixelRatio: 3.0);
      String? uploadedImageUrl;
      File? imageFile;

      if (image != null) {
        final directory = await getTemporaryDirectory();
        imageFile = File('${directory.path}/lotto_vip_share_${DateTime.now().millisecondsSinceEpoch}.png');
        await imageFile.writeAsBytes(image);

        try {
          final uploadResult = await ShareClient.instance.uploadImage(imagePath: imageFile.path);
          uploadedImageUrl = uploadResult.infos.original.url;
        } catch (e) {
          debugPrint('Kakao uploadImage notice: $e');
        }
      }

      final DefaultTemplate template;
      final installLink = Link(
        webUrl: appUrl,
        mobileWebUrl: appUrl,
        androidExecutionParams: {'source': 'kakaotalk_share'},
        iosExecutionParams: {'source': 'kakaotalk_share'},
      );

      if (uploadedImageUrl != null) {
        final imageLink = Link(
          webUrl: Uri.parse(uploadedImageUrl),
          mobileWebUrl: Uri.parse(uploadedImageUrl),
        );
        template = FeedTemplate(
          content: Content(
            imageUrl: Uri.parse(uploadedImageUrl),
            imageWidth: 800,
            imageHeight: 520,
            link: imageLink,
          ),
          buttons: [
            Button(
              title: '나도 행운번호 만들기',
              link: installLink,
            ),
          ],
        );
      } else {
        template = TextTemplate(
          text: '🍀 [로또신통] 1등 당첨 기원 행운 번호: $numbersText',
          link: installLink,
          buttons: [
            Button(
              title: '앱 설치하기',
              link: installLink,
            ),
          ],
        );
      }

      final isAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();
      if (isAvailable) {
        await ShareClient.instance.shareDefault(template: template);
      } else {
        try {
          final webUrl = await WebSharerClient.instance.makeDefaultUrl(template: template);
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        } catch (e) {
          if (imageFile != null) {
            await SharePlus.instance.share(
              ShareParams(
                files: [XFile(imageFile.path)],
                text: '[로또신통] 🍀 1등 당첨 기원 행운 번호: $numbersText',
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Kakao sharing error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('공유를 완료하지 못했습니다. 잠시 후 다시 시도해 주세요.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  /// 심플하고 고급스러운 결과 카드 (Modern Premium Design)
  Widget _buildShareCard(BuildContext context) {
    final isLight = AppColors.isLight;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF151515),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight 
                ? Colors.black.withValues(alpha: 0.03)
                : Colors.transparent,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 은은한 배경 효과 (Glow)
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLight 
                      ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                      : const Color(0xFFFFD700).withValues(alpha: 0.08),
                  boxShadow: [
                    BoxShadow(
                      color: isLight 
                          ? const Color(0xFFFFD700).withValues(alpha: 0.1)
                          : const Color(0xFFFFD700).withValues(alpha: 0.1),
                      blurRadius: 80,
                      spreadRadius: 80,
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 42, bottom: 46),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 상단 브랜드 마크 (세련된 알약 뱃지)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isLight 
                              ? Colors.black.withValues(alpha: 0.04) 
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isLight 
                                ? Colors.black.withValues(alpha: 0.06) 
                                : Colors.white.withValues(alpha: 0.08),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 13,
                              color: Color(0xFFFFB800),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '로또신통',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: isLight ? Colors.black54 : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // 메인 타이틀
                  Text(
                    '행운의 당첨 번호',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: isLight ? const Color(0xFF191919) : Colors.white,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '이번 주 1등 주인공은 바로 당신입니다',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isLight ? Colors.black45 : Colors.white38,
                      letterSpacing: -0.2,
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // 로또 번호 6개
                  Center(
                    child: LottoBallRow(
                      numbers: widget.numbers,
                      ballSize: 42,
                    ),
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
          color: isLight ? Colors.white : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 2,
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
              GestureDetector(
                onTap: _saveImage,
                child: Screenshot(
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
              ),

              const SizedBox(height: 20),

              // 하단 버튼 영역 (52px 고정 높이 완벽 대칭 & 반응형 안전 스타일)
              Row(
                children: [
                  // 카카오톡 공유 버튼
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSharing ? null : _shareToKakaoTalk,
                        icon: _isSharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF191919),
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.chat_bubble_rounded,
                                size: 18,
                                color: Color(0xFF191919),
                              ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '카카오톡 공유',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansKr(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: const Color(0xFF191919),
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          backgroundColor: const Color(0xFFFEE500),
                          foregroundColor: const Color(0xFF191919),
                          elevation: 0,
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
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '확인',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansKr(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isLight ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          backgroundColor: isLight ? const Color(0xFF222222) : const Color(0xFFEEEEEE),
                          foregroundColor: isLight ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
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


