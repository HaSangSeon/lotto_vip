import 'package:flutter/material.dart';
import '../utils/safe_google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../services/qr_lottery_parser.dart';
import '../services/dhlottery_api.dart';
import '../services/history_service.dart';
import '../services/notification_service.dart';
import 'qr_result_sheet.dart';

class QrScannerView extends StatefulWidget {
  final VoidCallback? onHistorySaved;

  const QrScannerView({super.key, this.onHistorySaved});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  bool _isHandling = false;
  bool _isLoading = false;
  bool _isTorchOn = false;
  String? _lastScannedCode;
  DateTime? _lastClosedTime;
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

  void _onDetect(BarcodeCapture capture) {
    if (_isHandling) return;

    final now = DateTime.now();
    // 팝업/시트를 방금 닫은 직후(0.4초 이내)에는 화면 전환 안정화를 위해 스캔 대기
    if (_lastClosedTime != null &&
        now.difference(_lastClosedTime!) < const Duration(milliseconds: 400)) {
      return;
    }

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue?.trim();
      if (code != null && code.isNotEmpty) {
        // 방금 확인하고 닫은 동일한 복권이 아직 카메라 앞에 머물러 있을 때 2.5초간 연속 재스캔 방지
        // (단, 다른 복권 QR 코드를 비추면 즉시 인식)
        if (_lastScannedCode == code &&
            _lastClosedTime != null &&
            now.difference(_lastClosedTime!) < const Duration(milliseconds: 2500)) {
          continue;
        }

        _isHandling = true;
        _handleQrCode(code, isManual: false);
        break;
      }
    }
  }

  Future<void> _handleQrCode(String rawCode, {bool isManual = false}) async {
    _isHandling = true;
    _lastScannedCode = rawCode.trim();

    try {
      // 1. QR 코드 정밀 파싱 및 유효성 검사 (즉시 동기 처리)
      final parseResult = QRLotteryParser.parseDetailed(rawCode);

      if (!parseResult.isSuccess || parseResult.data == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          await _showErrorDialog(
            errorType: parseResult.errorType ?? QRErrorType.invalidFormat,
            errorMessage: parseResult.errorMessage ?? '올바른 로또 QR 코드가 아닙니다.',
            rawCode: rawCode,
          );
        }
        return;
      }

      final qrData = parseResult.data!;
      if (mounted) {
        setState(() => _isLoading = true);
      }

      // 2. 해당 회차 공식 당첨 결과 조회
      DHLotteryResult? drawResult;
      bool isNetworkError = false;

      try {
        drawResult = await DHLotteryApi.fetchByDrawNo(qrData.drwNo);
        // 추첨 시간이 지났는데 API 결과가 안 오는 경우 네트워크/서버 지연으로 처리
        if (drawResult == null && qrData.isDrawnTimePassed) {
          isNetworkError = true;
        }
      } catch (_) {
        if (qrData.isDrawnTimePassed) {
          isNetworkError = true;
        }
      }

      // 3. 보관함(히스토리) 자동 저장 및 알림 갱신 (오류가 나도 결과 시트 표시는 절대 중단되지 않도록 격리)
      bool isSavedToHistory = false;
      try {
        final existingHistory = await HistoryService.load();
        final firstGame = qrData.games.first;
        final alreadySaved = existingHistory.any((e) {
          if (e.drawNo != qrData.drwNo) return false;
          // 기존에 보관된 실물 복권(티켓)과의 일치 여부만 확인 (단일 추출번호로 인한 누락 방지)
          if (!e.isTicket || e.games == null) return false;
          if (e.games!.length != qrData.games.length) return false;
          for (int i = 0; i < e.games!.length; i++) {
            final savedNums = e.games![i].numbers;
            final scannedNums = qrData.games[i].numbers;
            if (savedNums.length != scannedNums.length ||
                !savedNums.every((n) => scannedNums.contains(n))) {
              return false;
            }
          }
          return true;
        });

        if (!alreadySaved) {
          final ticketEntry = LottoHistoryEntry(
            title: '[QR스캔] 제${qrData.drwNo}회 실물 복권 (${qrData.games.length}게임)',
            numbers: firstGame.numbers,
            games: qrData.games
                .map((g) => SavedLotteryGame(label: g.label, numbers: g.numbers))
                .toList(),
            createdAt: DateTime.now(),
          );
          await HistoryService.save(ticketEntry);
        }
        isSavedToHistory = true;
        widget.onHistorySaved?.call();
      } catch (_) {}

      // 알림 스케줄 갱신 (비동기 격리)
      try {
        if (NotificationService.isEnabled) {
          await NotificationService.scheduleWeeklyDrawNotification();
        }
      } catch (_) {}

      if (!mounted) return;

      // 결과 시트를 띄우기 전 로딩 오버레이 즉시 해제
      setState(() => _isLoading = false);

      // 4. 앱 자체 프리미엄 결과 시트 표시
      await QrResultSheet.show(
        context,
        qrData: qrData,
        drawResult: drawResult,
        isSavedToHistory: isSavedToHistory,
        isNetworkError: isNetworkError,
        onRetry: () async {
          return await DHLotteryApi.fetchByDrawNo(qrData.drwNo);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await _showErrorDialog(
          errorType: QRErrorType.invalidFormat,
          errorMessage: 'QR 코드를 처리하는 도중 예상치 못한 오류가 발생했습니다.\n다시 시도해 주세요.',
          rawCode: rawCode,
        );
      }
    } finally {
      // 안드로이드 시스템 뒤로가기(Back) 제스처로 시트/팝업을 닫더라도 100% 스캔 상태 복구 보장
      _lastClosedTime = DateTime.now();
      if (isManual) {
        _lastScannedCode = null;
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isHandling = false;
        });
      } else {
        _isLoading = false;
        _isHandling = false;
      }
    }
  }

  /// 예외 상황 전용 친절한 다이얼로그
  Future<void> _showErrorDialog({
    required QRErrorType errorType,
    required String errorMessage,
    required String rawCode,
  }) async {
    final isPension = errorType == QRErrorType.pensionLottery;
    final isHttpUrl = rawCode.startsWith('http://') || rawCode.startsWith('https://');

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(
              isPension ? Icons.info_outline_rounded : Icons.warning_amber_rounded,
              color: isPension ? AppColors.gold : Colors.amber.shade700,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isPension ? '연금복권 QR 감지' : 'QR 코드 확인 필요',
                style: GoogleFonts.notoSansKr(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMessage,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.isLight ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '로또 6/45 복권 용지 우측 상단의 QR 코드를 사각형 안에 맞춰주세요.',
                      style: GoogleFonts.notoSansKr(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (isHttpUrl)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final uri = Uri.parse(rawCode);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
              child: Text(
                '웹브라우저로 열기',
                style: GoogleFonts.notoSansKr(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.isLight ? AppColors.goldDark : AppColors.gold,
              foregroundColor: AppColors.isLight ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              '다시 스캔하기',
              style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    final TextEditingController urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
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
                '로또 용지의 QR 코드 URL 또는 파라미터(v=...)를 직접 입력하여 당첨을 확인할 수 있습니다.',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'https://m.dhlottery.co.kr/qr.do?method=winQr&v=...',
                  hintStyle: GoogleFonts.notoSansKr(fontSize: 12, color: AppColors.textHint),
                ),
                style: GoogleFonts.notoSansKr(fontSize: 13, color: AppColors.textPrimary),
                onSubmitted: (val) {
                  final input = val.trim();
                  if (input.isNotEmpty) {
                    Navigator.pop(ctx);
                    _handleQrCode(input, isManual: true);
                  }
                },
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
                        _handleQrCode(input, isManual: true);
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

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) {
        setState(() => _isTorchOn = !_isTorchOn);
      }
    } catch (_) {}
  }

  Future<void> _retryCamera() async {
    try {
      await _controller.stop();
    } catch (_) {}
    try {
      await _controller.start();
    } catch (_) {}
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
            onPressed: _toggleTorch,
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
            // 카메라 스캐너
            Positioned.fill(
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                fit: BoxFit.cover,
                errorBuilder: (context, error) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.videocam_off_rounded, color: Colors.white70, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            '카메라를 실행할 수 없습니다.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSansKr(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '카메라 권한이 허용되지 않았거나 일시적으로 사용할 수 없습니다.\n권한 확인 후 다시 시도하거나 URL을 직접 입력해 주세요.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSansKr(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _retryCamera,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: Text(
                                  '카메라 다시 연결',
                                  style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.gold,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _showManualInputDialog,
                                icon: const Icon(Icons.keyboard, size: 18),
                                label: Text(
                                  'QR URL 직접 입력',
                                  style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 어두운 오버레이 (무시 가능한 포인터 처리로 카메라 에러 버튼 터치 보장)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),

            // 스캔 가이드 영역 (중앙 260x260 박스, 터치 투과)
            Center(
              child: IgnorePointer(
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
            ),

            // 하단 안내 메시지
            Positioned(
              bottom: 48,
              left: 20,
              right: 20,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _showManualInputDialog,
                      icon: const Icon(Icons.link, color: AppColors.goldLight, size: 16),
                      label: Flexible(
                        child: Text(
                          '카메라 사용이 불가한 경우 URL 직접 입력',
                          style: GoogleFonts.notoSansKr(
                            color: AppColors.goldLight,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 처리 중 로딩 인디케이터 오버레이 (네트워크/저장 중일 때만 표시)
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.75),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.gold),
                        const SizedBox(height: 16),
                        Text(
                          '당첨 결과 확인 및 번호 저장 중...',
                          style: GoogleFonts.notoSansKr(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
