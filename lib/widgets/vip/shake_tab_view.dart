import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../theme/app_theme.dart';
import '../../services/history_service.dart';
import '../../services/notification_service.dart';
import '../common_widgets.dart';
import '../lotto_ball.dart';
import '../dialogs/calculation_loading_dialog.dart';

class ShakeTabView extends StatefulWidget {
  final void Function(String title, List<int> numbers)? onShowResult;

  const ShakeTabView({
    super.key,
    this.onShowResult,
  });

  @override
  State<ShakeTabView> createState() => _ShakeTabViewState();
}

class _ShakeTabViewState extends State<ShakeTabView> with SingleTickerProviderStateMixin {
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  late AnimationController _animCtrl;
  Timer? _cooldownTimer;

  // 흔들림 게이지 (0.0 ~ 1.0, 4단계: 0.25, 0.50, 0.75, 1.0)
  double _shakeProgress = 0.0;
  DateTime _lastShakeTime = DateTime.now();
  bool _isExtracting = false;
  List<int> _recentNumbers = [];

  // 가속도 흔들림 임계값 (중력 가속도 9.80665 대비 변위량)
  static const double _shakeDeltaThreshold = 9.5;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _initSensor();
  }

  void _initSensor() {
    try {
      // 모든 안드로이드 기기 100% 탑재 물리 원시 가속도계 리슨
      _accelerometerSub = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          if (!mounted || _isExtracting) return;

          final double gX = event.x;
          final double gY = event.y;
          final double gZ = event.z;
          // 총 가속도 벡터 크기 계산
          final double netForce = sqrt(gX * gX + gY * gY + gZ * gZ);
          // 지구 중력 가속도(약 9.8m/s²)를 뺀 순수 흔들림 변위량
          final double delta = (netForce - 9.80665).abs();

          // 손목 스냅으로 가볍게 흔들었을 때 감지 (변위량 9.5 초과 또는 순간 가속도 19.5 초과)
          if (delta > _shakeDeltaThreshold || netForce > 19.5 || netForce < 2.5) {
            final now = DateTime.now();
            if (now.difference(_lastShakeTime).inMilliseconds > 130) {
              _lastShakeTime = now;
              _onDeviceShaken();
            }
          }
        },
        onError: (err) {
          debugPrint('Accelerometer stream error (fallback to touch): $err');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Sensor init exception: $e');
    }
  }

  void _onDeviceShaken() {
    if (_isExtracting) return;

    HapticFeedback.selectionClick();
    _animCtrl.forward(from: 0.0);

    // 쿨다운 타이머 리셋 (3.5초 동안 추가 흔들림 없으면 점진적 감소)
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && !_isExtracting && _shakeProgress > 0.0) {
        setState(() {
          _shakeProgress = (_shakeProgress - 0.25).clamp(0.0, 1.0);
        });
      }
    });

    setState(() {
      _shakeProgress = (_shakeProgress + 0.25).clamp(0.0, 1.0);
    });

    if (_shakeProgress >= 1.0) {
      _cooldownTimer?.cancel();
      _extractNumbers();
    }
  }

  Future<void> _extractNumbers() async {
    if (_isExtracting) return;
    _isExtracting = true;
    HapticFeedback.heavyImpact();

    // 로딩 팝업 표시
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const CalculationLoadingDialog(
        title: '🎲 쉐이크 황금 로또 추첨',
        step1: '기기 진동 에너지 파동 분석 중...',
        step2: '황금 캡슐 6개 번호 조합 완성 중...',
      ),
    );

    if (!mounted) return;

    // 1~45 무작위 6개 번호 생성
    final random = Random();
    final Set<int> picked = {};
    while (picked.length < 6) {
      picked.add(random.nextInt(45) + 1);
    }
    final finalNumbers = picked.toList()..sort();

    setState(() {
      _recentNumbers = finalNumbers;
      _shakeProgress = 0.0;
      _isExtracting = false;
    });

    // 보관함 자동 저장
    final upcomingDrawNo = HistoryService.calculateTargetDrawNo(DateTime.now());
    final entry = LottoHistoryEntry(
      title: '제$upcomingDrawNo회 흔들어 뽑기',
      numbers: finalNumbers,
      createdAt: DateTime.now(),
    );
    await HistoryService.save(entry);
    await NotificationService.scheduleWeeklyDrawNotification();

    // 결과 시트 호출 (바텀시트 닫힐 때 전면광고 연동)
    if (widget.onShowResult != null) {
      widget.onShowResult!('🎲 흔들어 뽑은 행운 번호', finalNumbers);
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _accelerometerSub?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  /// 게이지에 따른 다이나믹 상태 문구
  String get _statusText {
    if (_shakeProgress <= 0.0) return '스마트폰을 흔들어주세요';
    if (_shakeProgress <= 0.25) return '모션 감지! 더 흔들어보세요';
    if (_shakeProgress <= 0.50) return '에너지 충전 중! (절반 도달)';
    if (_shakeProgress <= 0.75) return '마지막 한 번 더 흔들어주세요!';
    return '황금 로또 번호 추출 중...';
  }

  int get _stepCount => (_shakeProgress * 4).round().clamp(0, 4);

  @override
  Widget build(BuildContext context) {
    final isLight = AppColors.isLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🌟 1. 메인 쉐이크 인터랙션 카드 (VIP 럭셔리 디자인)
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
            borderColor: isLight
                ? AppColors.lightGoldBorder.withValues(alpha: 0.6)
                : AppColors.borderGold,
            gradientColors: isLight
                ? const [Color(0xFFFFFFFF), Color(0xFFFFF9EC)]
                : const [Color(0xFF1A1504), Color(0xFF0F0E0A)],
            shadows: isLight
                ? [
                    BoxShadow(
                      color: AppColors.goldDark.withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.9),
                      blurRadius: 0,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                    const BoxShadow(
                      color: Colors.black54,
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
            child: Column(
              children: [
                // 1-1. 상단 VIP 칩 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: isLight
                        ? const Color(0xFFFAF0D7)
                        : AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLight
                          ? const Color(0xFFD4AF37).withValues(alpha: 0.5)
                          : AppColors.gold.withValues(alpha: 0.4),
                      width: 0.9,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: isLight ? AppColors.goldDeep : AppColors.gold,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'VIP 모션 센서 추첨',
                        style: GoogleFonts.notoSansKr(
                          color: isLight ? AppColors.goldDeep : AppColors.gold,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 1-2. 헤더 타이틀
                Text(
                  '스마트폰 흔들어 번호 뽑기',
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '스마트폰을 가볍게 흔들면 내부 모션 센서가\n황금 캡슐 속 행운의 6개 번호를 즉시 추출합니다.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 20),

                // 1-3. 럭셔리 골든 크리스탈 구체 (3D Golden Sphere Orb)
                GestureDetector(
                  onTap: _onDeviceShaken,
                  child: AnimatedBuilder(
                    animation: _animCtrl,
                    builder: (context, child) {
                      final shakeOffset = sin(_animCtrl.value * pi * 4) * 8.0;
                      final scale = 1.0 + (_animCtrl.value * 0.05);
                      return Transform.translate(
                        offset: Offset(shakeOffset, 0),
                        child: Transform.scale(
                          scale: scale,
                          child: child,
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 178,
                      height: 178,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 앰비언트 글로우 펄스 링 (진행률에 따라 환해짐)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 174,
                            height: 174,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isLight ? AppColors.goldDark : AppColors.gold)
                                      .withValues(alpha: 0.15 + (_shakeProgress * 0.35)),
                                  blurRadius: 24 + (_shakeProgress * 20),
                                  spreadRadius: 2 + (_shakeProgress * 5),
                                ),
                              ],
                            ),
                          ),

                          // 외곽 정밀 링 (골드 서클)
                          Container(
                            width: 168,
                            height: 168,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isLight
                                    ? const Color(0xFFD4AF37).withValues(alpha: 0.35 + (_shakeProgress * 0.4))
                                    : AppColors.gold.withValues(alpha: 0.25 + (_shakeProgress * 0.5)),
                                width: 1.2,
                              ),
                            ),
                          ),

                          // 내부 펄스 점선 링
                          Container(
                            width: 152,
                            height: 152,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (isLight ? AppColors.goldDeep : AppColors.gold)
                                    .withValues(alpha: 0.2),
                                width: 1.0,
                              ),
                            ),
                          ),

                          // 메인 골든 구체 본체
                          Container(
                            width: 136,
                            height: 136,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: const Alignment(-0.25, -0.35),
                                radius: 0.9,
                                colors: isLight
                                    ? [
                                        const Color(0xFFFFFBE8),
                                        const Color(0xFFFEE8A2),
                                        const Color(0xFFE5B73B),
                                        const Color(0xFFB38415),
                                      ]
                                    : [
                                        const Color(0xFFFFEFA7),
                                        AppColors.gold,
                                        const Color(0xFF9E7711),
                                        const Color(0xFF2B2005),
                                      ],
                                stops: const [0.0, 0.35, 0.75, 1.0],
                              ),
                              border: Border.all(
                                color: isLight
                                    ? const Color(0xFFFFF2C2)
                                    : AppColors.goldLight,
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isLight ? 0.12 : 0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 상단 글래스 하이라이트 글레어
                                Positioned(
                                  top: 8,
                                  child: Container(
                                    width: 70,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withValues(alpha: 0.65),
                                          Colors.white.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // 중앙 모션 아이콘 & 영문 타이포
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 4),
                                    Icon(
                                      Icons.casino_rounded,
                                      size: 38,
                                      color: isLight ? const Color(0xFF5C4000) : Colors.black87,
                                    )
                                        .animate(onPlay: (c) => c.repeat(reverse: true))
                                        .scale(
                                          begin: const Offset(0.96, 0.96),
                                          end: const Offset(1.06, 1.06),
                                          duration: 1100.ms,
                                        ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'SHAKE',
                                      style: GoogleFonts.rajdhani(
                                        color: isLight ? const Color(0xFF4A3400) : Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.2,
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
                  ),
                ),

                const SizedBox(height: 14),

                // 1-4. 실시간 상태 안내 문구
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _statusText,
                    key: ValueKey<String>(_statusText),
                    style: GoogleFonts.notoSansKr(
                      color: isLight ? AppColors.goldDeep : AppColors.gold,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 1-5. 럭셔리 4분할 세그먼트 파워 인디케이터
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 16,
                                color: isLight ? AppColors.goldDeep : AppColors.gold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '모션 충전 게이지',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$_stepCount / 4단계  (${(_shakeProgress * 100).toInt()}%)',
                            style: GoogleFonts.rajdhani(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isLight ? AppColors.goldDeep : AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 4분할 골드 바
                      Row(
                        children: List.generate(4, (index) {
                          final isFilled = _shakeProgress >= ((index + 1) * 0.25) - 0.01;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                              height: 9,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: isFilled
                                    ? LinearGradient(
                                        colors: isLight
                                            ? const [Color(0xFFE5B73B), Color(0xFFB8860B)]
                                            : [AppColors.goldLight, AppColors.goldDark],
                                      )
                                    : null,
                                color: isFilled
                                    ? null
                                    : (isLight
                                        ? const Color(0xFFECE4D4)
                                        : Colors.white.withValues(alpha: 0.08)),
                                border: Border.all(
                                  color: isFilled
                                      ? (isLight
                                          ? const Color(0xFFB8860B).withValues(alpha: 0.4)
                                          : AppColors.gold.withValues(alpha: 0.5))
                                      : Colors.transparent,
                                  width: 0.8,
                                ),
                                boxShadow: isFilled
                                    ? [
                                        BoxShadow(
                                          color: (isLight ? AppColors.goldDark : AppColors.gold)
                                              .withValues(alpha: 0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 1-6. 럭셔리 터치 흔들기 버튼 (에뮬레이터 및 간편 터치용)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: isLight
                        ? const LinearGradient(
                            colors: [Color(0xFFC59516), Color(0xFF9E7200)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [AppColors.gold, AppColors.goldDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: (isLight ? AppColors.goldDark : AppColors.gold)
                            .withValues(alpha: isLight ? 0.32 : 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _onDeviceShaken,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 49),
                      backgroundColor: Colors.transparent,
                      foregroundColor: isLight ? Colors.white : Colors.black,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 19,
                          color: isLight ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '직접 탭하여 흔들기 (터치 지원)',
                          style: GoogleFonts.notoSansKr(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: isLight ? Colors.white : Colors.black87,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 🌟 2. 방금 뽑은 번호 결과 카드 (추첨 시 노출)
          if (_recentNumbers.isNotEmpty)
            GlassCard(
              gradientColors: isLight
                  ? const [Color(0xFFFFFDF5), Color(0xFFFFF6DF)]
                  : const [Color(0xFF1D1702), Color(0xFF100C01)],
              borderColor: isLight
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.6)
                  : AppColors.borderGold,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              shadows: isLight
                  ? [
                      BoxShadow(
                        color: AppColors.goldDark.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: isLight ? AppColors.goldDeep : AppColors.gold,
                            size: 19,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '방금 흔들어 뽑은 행운 번호',
                            style: GoogleFonts.notoSansKr(
                              color: isLight ? AppColors.goldDeep : AppColors.goldText,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFE8F5E9) : const Color(0xFF2E7D32).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isLight ? const Color(0xFF4CAF50) : const Color(0xFF81C784),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '보관함 저장완료 💾',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isLight ? const Color(0xFF2E7D32) : const Color(0xFFA5D6A7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  LottoBallRow(numbers: _recentNumbers, ballSize: 46)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.25, end: 0, duration: 400.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 12),
                  Text(
                    '하단 보관함의 [추출번호] 탭에서 언제든지 다시 확인할 수 있습니다.',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11.5,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

          if (_recentNumbers.isNotEmpty) const SizedBox(height: 20),

          // 🌟 3. VIP 안내 팁 배너
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFFAF6EE) : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight
                    ? const Color(0xFFE5D7BF)
                    : Colors.white.withValues(alpha: 0.08),
                width: 0.9,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sensors_rounded,
                  color: isLight ? AppColors.goldDeep : AppColors.gold,
                  size: 20,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '안드로이드 모션 센서 100% 자동 지원',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '스마트폰을 손에 쥐고 가볍게 3~4회 흔들어주시면 자동으로 번호가 추첨됩니다. 기기를 흔들기 어려운 환경에서는 화면 중앙의 구체나 하단 버튼을 탭하여 동일하게 추첨하실 수 있습니다.',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
