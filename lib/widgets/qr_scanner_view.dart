import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  bool _isProcessing = false;
  bool _isTorchOn = false;
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && (code.contains('dhlottery.co.kr') || code.contains('qr.dhlottery'))) {
        _isProcessing = true;
        _handleQrUrl(code);
        break;
      }
    }
  }

  Future<void> _handleQrUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _isProcessing = false;
      }
    } catch (e) {
      _isProcessing = false;
    }
  }

  void _showManualInputDialog() {
    final TextEditingController urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QR URL 직접 입력',
                style: GoogleFonts.notoSansKr(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '로또 용지의 QR 코드 URL을 직접 입력하여 당첨을 확인할 수 있습니다.',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(
                  hintText: 'https://m.dhlottery.co.kr/qr.do?...',
                  hintStyle: GoogleFonts.notoSansKr(fontSize: 12, color: AppColors.textHint),
                ),
                style: GoogleFonts.notoSansKr(fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('취소', style: GoogleFonts.notoSansKr(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final input = urlCtrl.text.trim();
                      if (input.isNotEmpty) {
                        Navigator.pop(ctx);
                        _handleQrUrl(input);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.isLight ? AppColors.goldDark : AppColors.gold,
                      foregroundColor: AppColors.isLight ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('확인', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'QR 당첨 확인',
          style: GoogleFonts.notoSansKr(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // 플래시 토글
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? AppColors.gold : Colors.white70,
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          // 수동 입력
          IconButton(
            icon: const Icon(Icons.keyboard, color: Colors.white70),
            onPressed: _showManualInputDialog,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 카메라 스캐너 (화면 전체 꽉 차게 레아아웃 보정)
            Positioned.fill(
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                fit: BoxFit.cover,
              ),
            ),

            // 어두운 오버레이
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),

            // 스캔 가이드 영역 (중앙 260x260 박스)
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: AppColors.gold,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 모서리 원형 포인트
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 안내 메시지
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      '로또 용지의 QR 코드를 사각형 안에 맞추어 주세요',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _showManualInputDialog,
                    icon: const Icon(Icons.link, color: AppColors.goldLight, size: 16),
                    label: Text(
                      '카메라 사용이 불가한 경우 URL 직접 입력',
                      style: GoogleFonts.notoSansKr(
                        color: AppColors.goldLight,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
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
}
