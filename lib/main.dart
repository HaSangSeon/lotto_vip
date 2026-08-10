import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'utils/safe_google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'theme/app_theme.dart';
import 'widgets/common_widgets.dart';
import 'widgets/lotto_ball.dart';
import 'widgets/latest_draw_tab.dart';
import 'widgets/statistics_tab.dart';
import 'services/history_service.dart';

import 'dart:ui' as ui;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError caught safely: ${details.exception}');
  };

  ui.PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error caught safely: $error');
    return true; // Prevents app crash
  };

  try {
    await AppTheme.init();
    MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  runApp(const LottoVipApp());
}

class LottoVipApp extends StatelessWidget {
  const LottoVipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: '로또 신통',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.light,
          darkTheme: AppThemes.dark,
          themeMode: themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Home Screen
// ─────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  BannerAd? _bannerAd;
  Widget? _bannerAdWidget;
  bool _isBannerLoaded = false;
  bool _isBannerAdLoading = false;
  InterstitialAd? _interstitialAd;

  final TextEditingController _birthDateCtrl = TextEditingController();

  List<int> _vipNumbers = [];
  List<int> _customNumbers = [];
  List<int> _includeNumbers = [];
  List<int> _excludeNumbers = [];

  List<LottoHistoryEntry> _history = [];

  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedBirthDate();
    _loadInterstitialAd();
    _loadHistory();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isBannerLoaded && !_isBannerAdLoading) {
      _isBannerAdLoading = true;
      _loadBannerAd();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _bannerAd?.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedBirthDate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _birthDateCtrl.text = prefs.getString('birthDate') ?? '');
  }

  Future<void> _saveBirthDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('birthDate', _birthDateCtrl.text);
  }

  Future<void> _loadHistory() async {
    final h = await HistoryService.load();
    setState(() => _history = h);
  }

  Future<void> _loadBannerAd() async {
    try {
      if (!mounted) return;
      final screenWidth = MediaQuery.of(context).size.width.truncate();
      if (screenWidth <= 0) return;
      final AnchoredAdaptiveBannerAdSize? size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(screenWidth);

      _bannerAd = BannerAd(
        adUnitId: Platform.isAndroid
            ? 'ca-app-pub-3702899361747571/7789923273'
            : 'ca-app-pub-3940256099942544/2934735716',
        size: size ?? AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _bannerAdWidget = AdWidget(ad: ad as BannerAd);
                _isBannerLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _isBannerAdLoading = false;
          },
        ),
      )..load();
    } catch (_) {
      _isBannerAdLoading = false;
    }
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3702899361747571/3248043033'
          : 'ca-app-pub-3940256099942544/4411468910',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  void _showInterstitialAd(VoidCallback onComplete) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
          onComplete();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitialAd();
          onComplete();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      _loadInterstitialAd();
      onComplete();
    }
  }

  void _generateVipNumbers() {
    if (_birthDateCtrl.text.length < 6) {
      _showToast('생년월일 6자리를 입력해주세요.');
      return;
    }
    _saveBirthDate();
    FocusManager.instance.primaryFocus?.unfocus();

    _showInterstitialAd(() async {
      final today = DateTime.now();
      final hashString =
          '${_birthDateCtrl.text}_${today.year}${today.month}${today.day}';
      final rng = Random(hashString.hashCode);
      final Set<int> numbers = {};
      while (numbers.length < 6) {
        numbers.add(rng.nextInt(45) + 1);
      }
      final sorted = numbers.toList()..sort();
      final entry = LottoHistoryEntry(
        title: '오늘의 행운 번호',
        numbers: sorted,
        createdAt: DateTime.now(),
      );
      await HistoryService.save(entry);
      await _loadHistory();

      if (!mounted) return;
      setState(() => _vipNumbers = sorted);
      _showResultSheet('오늘 나의 행운 번호', sorted, isVip: true);
    });
  }

  void _generateCustomNumbers() {
    Set<int> available = List.generate(45, (i) => i + 1).toSet();
    available.removeAll(_excludeNumbers);

    Set<int> result = {};
    for (int n in _includeNumbers) {
      if (result.length < 6) result.add(n);
    }
    available.removeAll(result);

    final rng = Random();
    final List<int> avList = available.toList()..shuffle(rng);
    for (int n in avList) {
      if (result.length >= 6) break;
      result.add(n);
    }
    final sorted = result.toList()..sort();

    HistoryService.save(LottoHistoryEntry(
      title: '커스텀 번호',
      numbers: sorted,
      createdAt: DateTime.now(),
    )).then((_) => _loadHistory());

    setState(() => _customNumbers = sorted);
    _showResultSheet('커스텀 로또 번호', sorted, isVip: false);
  }



  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.notoSansKr()),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── 결과 바텀시트 ────────────────────────────────────────────────
  void _showResultSheet(String title, List<int> numbers, {required bool isVip}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ResultSheet(
        title: title,
        numbers: numbers,
        isVip: isVip,
      ),
    );
  }

  // ── 커스텀 설정 다이얼로그 ─────────────────────────────────────
  void _openCustomDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomSettingsSheet(
        includeNumbers: List.from(_includeNumbers),
        excludeNumbers: List.from(_excludeNumbers),
        onChanged: (inc, exc) {
          setState(() {
            _includeNumbers = inc;
            _excludeNumbers = exc;
          });
        },
        onGenerate: () {
          Navigator.pop(context);
          _generateCustomNumbers();
        },
      ),
    );
  }

  // ── 앱 정보 & 알고리즘 안내 다이얼로그 ───────────────────────
  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.borderGold, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.15),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.workspace_premium, color: AppColors.gold, size: 36),
              ),
              const SizedBox(height: 12),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: AppColors.isLight
                      ? [AppColors.goldDark, AppColors.gold]
                      : [AppColors.goldLight, AppColors.gold],
                ).createShader(bounds),
                child: Text(
                  '로또 신통 v1.2.0',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '프리미엄 로또 생성기 안내',
                style: GoogleFonts.notoSansKr(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.auto_awesome,
                '오늘의 행운 번호',
                '생년월일과 오늘 날짜를 조합하여 매일 나만을 위한 고유 행운 번호를 뽑아드립니다.',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.tune,
                '맞춤 번호 조합',
                '꼭 넣고 싶은 번호와 빼고 싶은 번호를 직접 골라 나만의 로또 번호를 조합합니다.',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.analytics,
                '빅데이터 통계 분석',
                '역대 동행복권 당첨 데이터를 바탕으로 HOT/COLD 번호를 한눈에 분석합니다.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardHover,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '※ 본 앱에서 제공하는 번호는 분석 및 알고리즘 기반 참고 자료이며, 실제 당첨을 보장하지 않습니다.',
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('확인', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.gold, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.notoSansKr(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.notoSansKr(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: AppColors.isLight ? Brightness.dark : Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: AppColors.black,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.isLight
                        ? AppColors.lightGoldBorder.withValues(alpha: 0.2)
                        : AppColors.gold.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.isLight
                        ? AppColors.goldDark.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBannerAd(),
                    BottomNavigationBar(
                      currentIndex: _selectedTab,
                      onTap: (index) => setState(() => _selectedTab = index),
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      selectedItemColor: AppColors.isLight ? AppColors.goldDark : AppColors.gold,
                      unselectedItemColor: AppColors.textHint,
                      selectedLabelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 12),
                      unselectedLabelStyle: GoogleFonts.notoSansKr(fontSize: 11),
                      items: const [
                        BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: '당첨 확인'),
                        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: '통계'),
                        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: '오늘의 행운'),
                        BottomNavigationBarItem(icon: Icon(Icons.tune_rounded), label: '맞춤 조합'),
                        BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: '보관함'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            body: Stack(
        children: [
          // Background decoration
          if (AppColors.isLight) ...[
            // Light mode: warm ivory decorative orbs
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.goldDark.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFD4A017).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 200,
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFC8860B).withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Positioned(
              top: -120,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -100,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildTabContent(),
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    ),
        );
      },
    );
  }

  // ── 헤더 ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppColors.isLight
          ? BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.lightGoldBorder.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldDark.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 0,
                  spreadRadius: 0,
                  offset: const Offset(0, 0),
                ),
              ],
            )
          : null,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: AppColors.isLight
                      ? [AppColors.goldDeep, AppColors.goldDark, AppColors.gold]
                      : [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
                ).createShader(bounds),
                child: Text(
                  '로또 신통',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Text(
                '프리미엄 번호 생성기',
                style: GoogleFonts.notoSansKr(
                  fontSize: 11,
                  color: AppColors.isLight ? AppColors.goldDeep.withValues(alpha: 0.7) : AppColors.textSecondary,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // 테마 변경 버튼
          Container(
            decoration: AppColors.isLight
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightAccentAmber.withValues(alpha: 0.6),
                  )
                : null,
            child: IconButton(
              icon: Icon(
                AppTheme.themeModeNotifier.value == ThemeMode.light
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: AppColors.isLight ? AppColors.goldDeep : AppColors.textSecondary,
              ),
              onPressed: AppTheme.toggleTheme,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _showAppInfoDialog,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) => Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.isLight
                      ? LinearGradient(
                          colors: [
                            AppColors.goldDark,
                            AppColors.goldDeep,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: AppColors.isLight ? null : AppColors.card,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.isLight
                          ? AppColors.goldDark.withValues(alpha: 0.25 + _pulseCtrl.value * 0.15)
                          : AppColors.gold.withValues(alpha: 0.1 + _pulseCtrl.value * 0.15),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.workspace_premium,
                  color: AppColors.isLight ? Colors.white : AppColors.gold,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildTabContent() {
    final mode = AppTheme.themeModeNotifier.value;
    switch (_selectedTab) {
      case 0:
        return LatestDrawTab(
          key: ValueKey('latest_$mode'),
        );
      case 1:
        return StatisticsTab(
          key: ValueKey('stats_$mode'),
        );
      case 2:
        return _VipTab(
          key: ValueKey('vip_$mode'),
          ctrl: _birthDateCtrl,
          vipNumbers: _vipNumbers,
          onGenerate: _generateVipNumbers,
          shimmerCtrl: _shimmerCtrl,
        );
      case 3:
        return _CustomTab(
          key: ValueKey('custom_$mode'),
          customNumbers: _customNumbers,
          includeNumbers: _includeNumbers,
          excludeNumbers: _excludeNumbers,
          onOpenDialog: _openCustomDialog,
          onGenerate: _generateCustomNumbers,
        );
      default:
        return _HistoryTab(
          key: ValueKey('history_$mode'),
          history: _history,
          onClear: () async {
            await HistoryService.clear();
            await _loadHistory();
          },
        );
    }
  }

  Widget _buildBannerAd() {
    if (!_isBannerLoaded || _bannerAd == null || _bannerAdWidget == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.isLight ? Colors.black.withValues(alpha: 0.05) : AppColors.borderSubtle,
            width: 0.5,
          ),
        ),
      ),
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble() + 8,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: _bannerAdWidget!,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// VIP Tab
// ─────────────────────────────────────────────────────────────────
class _VipTab extends StatelessWidget {
  final TextEditingController ctrl;
  final List<int> vipNumbers;
  final VoidCallback onGenerate;
  final AnimationController shimmerCtrl;

  const _VipTab({
    super.key,
    required this.ctrl,
    required this.vipNumbers,
    required this.onGenerate,
    required this.shimmerCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          // VIP 카드
          GlassCard(
            gradientColors: AppColors.isLight
                ? const [Color(0xFFFFFEFA), Color(0xFFFFF8E0)]
                : const [Color(0xFF1E1800), Color(0xFF0F0D00)],
            borderColor: AppColors.isLight
                ? AppColors.lightGoldBorder.withValues(alpha: 0.45)
                : AppColors.borderGold,
            shadows: AppColors.isLight
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
                // 아이콘 + 뱃지
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const Icon(Icons.auto_awesome, color: AppColors.gold, size: 40),
                  ],
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 2000.ms, color: AppColors.goldLight.withValues(alpha: 0.3)),

                const SizedBox(height: 14),
                Text(
                  '오늘 나의 행운 번호',
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '내 생년월일(6자리)을 입력하시면\n오늘 당신에게 딱 맞는 행운의 번호를 뽑아드립니다.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),

                const GoldDivider(),

                // 입력 필드
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.gold,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 6,
                  ),
                  decoration: InputDecoration(
                    hintText: '700101',
                    hintStyle: GoogleFonts.rajdhani(
                      color: AppColors.textHint,
                      fontSize: 24,
                      letterSpacing: 4,
                    ),
                    prefixIcon: Icon(Icons.cake_outlined, color: AppColors.textSecondary),
                    suffixText: '생년월일 6자리',
                    suffixStyle: GoogleFonts.notoSansKr(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 생성 버튼
                SizedBox(
                  width: double.infinity,
                  child: AppColors.isLight
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
                            onPressed: onGenerate,
                            icon: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
                            label: Text(
                              '🍀 오늘 나의 행운 번호 뽑기',
                              style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
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
                          onPressed: onGenerate,
                          icon: const Icon(Icons.auto_awesome, size: 20),
                          label: Text(
                            '🍀 오늘 나의 행운 번호 뽑기',
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
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 결과 카드
          if (vipNumbers.isNotEmpty)
            GlassCard(
              gradientColors: AppColors.isLight
                  ? const [Color(0xFFFFFDF5), Color(0xFFFFF8E5)]
                  : const [Color(0xFF1A1800), Color(0xFF0D0B00)],
              borderColor: AppColors.borderGold,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars, color: AppColors.gold, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '오늘의 당첨 예상 번호',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LottoBallRow(numbers: vipNumbers, ballSize: 48)
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOutBack),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          // 안내 카드
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '💡 생년월일이 같더라도 날짜가 바뀌면 매일 새로운 행운 번호가 부여됩니다.',
                    style: GoogleFonts.notoSansKr(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
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

// ─────────────────────────────────────────────────────────────────
// Custom Tab
// ─────────────────────────────────────────────────────────────────
class _CustomTab extends StatelessWidget {
  final List<int> customNumbers;
  final List<int> includeNumbers;
  final List<int> excludeNumbers;
  final VoidCallback onOpenDialog;
  final VoidCallback onGenerate;

  const _CustomTab({
    super.key,
    required this.customNumbers,
    required this.includeNumbers,
    required this.excludeNumbers,
    required this.onOpenDialog,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          // 메인 설정 및 생성 카드
          GlassCard(
            child: Column(
              children: [
                const SectionTitle(
                  icon: Icons.tune_rounded,
                  title: '내가 정하는 맞춤 번호',
                  subtitle: '꼭 넣고 싶은 번호는 고정하고, 빼고 싶은 번호는 제외하여\n나만의 맞춤 당첨 번호를 만들어보세요.',
                ),
                const GoldDivider(),

                // 현재 필터 상태 요약
                if (includeNumbers.isEmpty && excludeNumbers.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.gold, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '현재 전체 45개 번호에서 무작위 추출 중',
                          style: GoogleFonts.notoSansKr(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  if (includeNumbers.isNotEmpty) ...[
                    _buildNumberChips('꼭 넣을 번호 (${includeNumbers.length}개)', includeNumbers, const Color(0xFF1565C0)),
                    const SizedBox(height: 10),
                  ],
                  if (excludeNumbers.isNotEmpty) ...[
                    _buildNumberChips('뺄 번호 (${excludeNumbers.length}개)', excludeNumbers, const Color(0xFFC62828)),
                    const SizedBox(height: 16),
                  ],
                ],

                // 액션 버튼 그룹
                SizedBox(
                  width: double.infinity,
                  child: AppColors.isLight
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
                            onPressed: onGenerate,
                            icon: const Icon(Icons.bolt, color: Colors.white),
                            label: Text(
                              '⚡ 커스텀 번호 추출하기',
                              style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 54),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: onGenerate,
                          icon: const Icon(Icons.bolt, color: Colors.black),
                          label: Text(
                            '⚡ 커스텀 번호 추출하기',
                            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 6,
                            shadowColor: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onOpenDialog,
                    icon: Icon(Icons.settings, size: 18, color: AppColors.isLight ? AppColors.goldDeep : null),
                    label: Text(
                      '⚙️ 고정수 / 제외수 상세 필터',
                      style: GoogleFonts.notoSansKr(
                        fontWeight: FontWeight.w600,
                        color: AppColors.isLight ? AppColors.goldDeep : null,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: AppColors.isLight ? AppColors.goldDeep : AppColors.textPrimary,
                      side: BorderSide(
                        color: AppColors.isLight
                            ? AppColors.goldDark.withValues(alpha: 0.45)
                            : AppColors.borderGold,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),



          const SizedBox(height: 16),

          // 결과 카드 (생성 시)
          if (customNumbers.isNotEmpty)
            GlassCard(
              borderColor: AppColors.borderGold,
              gradientColors: AppColors.isLight
                  ? const [Color(0xFFFFFDF5), Color(0xFFFFF8E5)]
                  : const [Color(0xFF1A1800), Color(0xFF0D0B00)],
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.tune, color: AppColors.gold, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '최근 생성된 커스텀 번호',
                        style: GoogleFonts.notoSansKr(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LottoBallRow(numbers: customNumbers, ballSize: 48)
                      .animate()
                      .fadeIn()
                      .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutBack),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildNumberChips(String label, List<int> numbers, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansKr(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: numbers
              .map(
                (n) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    n.toString(),
                    style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// History Tab
// ─────────────────────────────────────────────────────────────────
class _HistoryTab extends StatefulWidget {
  final List<LottoHistoryEntry> history;
  final VoidCallback onClear;

  const _HistoryTab({super.key, required this.history, required this.onClear});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  bool _showOnlyFavorites = false;

  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: AppColors.textHint, size: 64),
            const SizedBox(height: 16),
            Text(
              '생성 기록이 없습니다.',
              style: GoogleFonts.notoSansKr(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '번호를 생성하면 여기에 기록됩니다.',
              style: GoogleFonts.notoSansKr(
                color: AppColors.textHint,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final displayedHistory = _showOnlyFavorites
        ? widget.history.where((e) => e.isFavorite).toList()
        : widget.history;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Text(
                '총 ${displayedHistory.length}개',
                style: GoogleFonts.notoSansKr(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              FilterChip(
                label: Text(
                  '즐겨찾기',
                  style: GoogleFonts.notoSansKr(
                    color: _showOnlyFavorites ? AppColors.gold : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: _showOnlyFavorites,
                onSelected: (val) => setState(() => _showOnlyFavorites = val),
                backgroundColor: Colors.transparent,
                selectedColor: AppColors.gold.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _showOnlyFavorites ? AppColors.gold : AppColors.borderSubtle),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('기록 삭제', style: GoogleFonts.notoSansKr(color: Colors.white)),
                      content: Text('모든 기록을 삭제할까요?',
                          style: GoogleFonts.notoSansKr(color: AppColors.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('취소', style: GoogleFonts.notoSansKr(color: AppColors.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onClear();
                          },
                          child: Text('삭제', style: GoogleFonts.notoSansKr(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.delete_outline, size: 16, color: AppColors.textSecondary),
                label: Text('전체 삭제',
                    style: GoogleFonts.notoSansKr(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            itemCount: displayedHistory.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = displayedHistory[index];
              final timeStr =
                  '${entry.createdAt.month}/${entry.createdAt.day} ${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';
              return GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          entry.title.contains('VIP') ? Icons.auto_awesome : Icons.tune,
                          color: AppColors.gold,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.title,
                          style: GoogleFonts.notoSansKr(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeStr,
                          style: GoogleFonts.notoSansKr(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            setState(() {
                              entry.isFavorite = !entry.isFavorite;
                            });
                            await HistoryService.updateAll(widget.history);
                          },
                          child: Icon(
                            entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: entry.isFavorite ? Colors.redAccent : AppColors.textHint,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LottoBallRow(numbers: entry.numbers, ballSize: 38),
                  ],
                ),
              )
                  .animate(delay: Duration(milliseconds: index * 50))
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.05, end: 0, duration: 300.ms);
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Result Bottom Sheet
// ─────────────────────────────────────────────────────────────────
class _ResultSheet extends StatefulWidget {
  final String title;
  final List<int> numbers;
  final bool isVip;

  const _ResultSheet({required this.title, required this.numbers, required this.isVip});

  @override
  State<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<_ResultSheet> {
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
        await Share.shareXFiles([XFile(imagePath.path)], text: '내 로또 신통 번호: ${widget.numbers.join(', ')}');
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
              color: Colors.transparent, // Background for screenshot
              child: Column(
                children: [
                  widget.isVip
                      ? const Icon(Icons.auto_awesome, color: AppColors.gold, size: 48)
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: 1500.ms, color: AppColors.goldLight)
                      : const Icon(Icons.tune, color: AppColors.gold, size: 48),

                  const SizedBox(height: 12),

                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: AppColors.isLight
                          ? [AppColors.goldDark, AppColors.gold]
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
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.share, size: 18),
                  label: Text('공유', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    foregroundColor: AppColors.gold,
                    side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
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
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('확인', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Custom Settings Bottom Sheet
// ─────────────────────────────────────────────────────────────────
class _CustomSettingsSheet extends StatefulWidget {
  final List<int> includeNumbers;
  final List<int> excludeNumbers;
  final void Function(List<int> inc, List<int> exc) onChanged;
  final VoidCallback onGenerate;

  const _CustomSettingsSheet({
    required this.includeNumbers,
    required this.excludeNumbers,
    required this.onChanged,
    required this.onGenerate,
  });

  @override
  State<_CustomSettingsSheet> createState() => _CustomSettingsSheetState();
}

class _CustomSettingsSheetState extends State<_CustomSettingsSheet> {
  late List<int> _inc;
  late List<int> _exc;

  @override
  void initState() {
    super.initState();
    _inc = List.from(widget.includeNumbers);
    _exc = List.from(widget.excludeNumbers);
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
        child: Column(
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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
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
                        _legend(Colors.blue, '1번 누르면: 꼭 넣기'),
                        const SizedBox(width: 16),
                        _legend(Colors.red, '2번 누르면: 빼기'),
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                          _inc.remove(num);
                          _exc.add(num);
                        } else if (isExc) {
                          _exc.remove(num);
                        } else {
                          if (_inc.length < 5) {
                            _inc.add(num);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('고정수는 최대 5개까지 가능합니다.',
                                    style: GoogleFonts.notoSansKr()),
                                backgroundColor: AppColors.card,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
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
