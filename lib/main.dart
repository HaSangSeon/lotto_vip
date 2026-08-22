import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'services/history_service.dart';
import 'services/notification_service.dart';
import 'widgets/splash_screen.dart';
import 'widgets/latest_draw_tab.dart';
import 'widgets/statistics_tab.dart';
import 'widgets/vip_tab.dart';
import 'widgets/custom_tab.dart';
import 'widgets/history_tab.dart';
import 'widgets/custom_settings_sheet.dart';
import 'widgets/result_sheet.dart';
import 'widgets/notification_settings_dialog.dart';

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
    await NotificationService.init();
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
          home: const SplashScreen(nextScreen: HomeScreen()),
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

  int _generationCount = 0;
  DateTime? _lastInterstitialAdShownTime;

  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedBirthDate();
    _loadSavedCustomFilters();
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

    NotificationService.onNotificationPayload.addListener(_onNotificationTapped);
  }

  void _onNotificationTapped() {
    final payload = NotificationService.onNotificationPayload.value;
    if (payload != null && mounted) {
      setState(() {
        _selectedTab = 4; // 보관함(히스토리) 탭으로 이동
      });
      NotificationService.onNotificationPayload.value = null; // 초기화
    }
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
    NotificationService.onNotificationPayload.removeListener(_onNotificationTapped);
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _bannerAd?.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  List<int> _calculateVipNumbers(String birthDate) {
    if (birthDate.length < 6) return [];
    final now = DateTime.now();
    final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final seedString = "${birthDate}_$dateStr";

    int hash = 0;
    for (int i = 0; i < seedString.length; i++) {
      hash = (hash * 31 + seedString.codeUnitAt(i)) & 0x7FFFFFFF;
    }

    final rand = Random(hash);
    final Set<int> picked = {};
    while (picked.length < 6) {
      picked.add(rand.nextInt(45) + 1);
    }
    return picked.toList()..sort();
  }

  String _todayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadSavedBirthDate() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('birthDate') ?? '';
    final lastDate = prefs.getString('last_vip_generated_date') ?? '';
    final today = _todayString();

    List<int> restoredNums = [];
    if (saved.isNotEmpty && lastDate == today) {
      final rawList = prefs.getStringList('last_vip_numbers') ?? [];
      restoredNums = rawList
          .map((e) => int.tryParse(e) ?? 0)
          .where((n) => n > 0 && n <= 45)
          .toList();
    }

    if (mounted) {
      setState(() {
        _birthDateCtrl.text = saved;
        _vipNumbers = restoredNums;
      });
    }
  }

  Future<void> _saveBirthDate(String birthDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('birthDate', birthDate);
  }

  void _onBirthDateChanged(String val) {
    _saveBirthDate(val);
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('last_vip_generated_date');
      prefs.remove('last_vip_numbers');
    });
    if (_vipNumbers.isNotEmpty) {
      setState(() => _vipNumbers = []);
    }
  }

  Future<void> _loadSavedCustomFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final incStr = prefs.getStringList('custom_include_numbers') ?? [];
    final excStr = prefs.getStringList('custom_exclude_numbers') ?? [];
    setState(() {
      _includeNumbers = incStr.map((e) => int.tryParse(e) ?? 0).where((n) => n > 0 && n <= 45).toList();
      _excludeNumbers = excStr.map((e) => int.tryParse(e) ?? 0).where((n) => n > 0 && n <= 45).toList();
    });
  }

  Future<void> _saveCustomFilters(List<int> inc, List<int> exc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_include_numbers', inc.map((e) => e.toString()).toList());
    await prefs.setStringList('custom_exclude_numbers', exc.map((e) => e.toString()).toList());
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

      final adUnitId = kReleaseMode
          ? (Platform.isAndroid
              ? 'ca-app-pub-3702899361747571/7789923273'
              : 'ca-app-pub-3940256099942544/2934735716')
          : (Platform.isAndroid
              ? 'ca-app-pub-3940256099942544/6300978111'
              : 'ca-app-pub-3940256099942544/2934735716');

      _bannerAd = BannerAd(
        adUnitId: adUnitId,
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
            debugPrint('BannerAd failed to load: $error');
            ad.dispose();
            _isBannerAdLoading = false;
          },
        ),
      )..load();
    } catch (e) {
      debugPrint('BannerAd error: $e');
      _isBannerAdLoading = false;
    }
  }

  void _loadInterstitialAd() {
    final adUnitId = kReleaseMode
        ? (Platform.isAndroid
            ? 'ca-app-pub-3702899361747571/3248043033'
            : 'ca-app-pub-3940256099942544/4411468910')
        : (Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/1033173712'
            : 'ca-app-pub-3940256099942544/4411468910');

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  void _showInterstitialAd(VoidCallback onComplete) {
    // 1) 번호 생성 3회마다 1회 노출 검사 (1회, 2회차는 광고 없이 쾌적하게 통과)
    if (_generationCount == 0 || _generationCount % 3 != 0) {
      onComplete();
      return;
    }

    // 2) 최소 90초(1분 30초) 쿨타임 검사 (최근 광고 시청 후 일정 시간 방어)
    if (_lastInterstitialAdShownTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialAdShownTime!);
      if (elapsed < const Duration(seconds: 90)) {
        onComplete();
        return;
      }
    }

    // 3) 광고 노출 및 재로드
    if (_interstitialAd != null) {
      _lastInterstitialAdShownTime = DateTime.now();
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

  Future<void> _showCalculationLoading({
    required String title,
    required String step1,
    required String step2,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CalculationLoadingDialog(
        title: title,
        step1: step1,
        step2: step2,
      ),
    );
  }

  Future<void> _generateVipNumbers() async {
    if (_birthDateCtrl.text.length < 6) {
      _showToast('생년월일 6자리를 입력해주세요.');
      return;
    }
    _saveBirthDate(_birthDateCtrl.text);

    await _showCalculationLoading(
      title: '👑 행운 번호 정밀 분석',
      step1: '생년월일과 오늘의 기운 데이터 분석 중...',
      step2: '최적의 6개 행운 번호 조합 도출 중...',
    );

    if (!mounted) return;

    _generationCount++;
    final result = _calculateVipNumbers(_birthDateCtrl.text);
    setState(() => _vipNumbers = result);

    // 당일 생성 번호 및 날짜 저장
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('last_vip_generated_date', _todayString());
      prefs.setStringList('last_vip_numbers', result.map((e) => e.toString()).toList());
    });

    // 이미 보관함에 동일한 번호 조합이 있는지 확인하여 중복 저장 방지
    final isAlreadySaved = _history.any((entry) =>
        entry.numbers.length == result.length &&
        entry.numbers.every((n) => result.contains(n)));

    if (!isAlreadySaved) {
      final entry = LottoHistoryEntry(
        title: 'VIP 행운 번호',
        numbers: result,
        createdAt: DateTime.now(),
      );
      await HistoryService.save(entry);
      await _loadHistory();
    }

    _showResultSheet('👑 VIP 행운 번호', result, true);
  }

  Future<void> _generateCustomNumbers() async {
    final Set<int> picked = Set.from(_includeNumbers);
    final Set<int> excSet = Set.from(_excludeNumbers);

    final available = List<int>.generate(45, (i) => i + 1)
        .where((n) => !picked.contains(n) && !excSet.contains(n))
        .toList();

    if (picked.length + available.length < 6) {
      _showToast('제외수가 너무 많아 6개 번호를 만들 수 없습니다.');
      return;
    }

    await _showCalculationLoading(
      title: '⚡ 맞춤 번호 알고리즘 연산',
      step1: '지정된 고정수/제외수 필터링 중...',
      step2: '빅데이터 확률 기반 최적 번호 조합 중...',
    );

    if (!mounted) return;

    _generationCount++;
    available.shuffle();
    while (picked.length < 6 && available.isNotEmpty) {
      picked.add(available.removeLast());
    }

    final result = picked.toList()..sort();

    setState(() => _customNumbers = result);
    final entry = LottoHistoryEntry(
      title: '맞춤 번호 조합',
      numbers: result,
      createdAt: DateTime.now(),
    );
    HistoryService.save(entry).then((_) => _loadHistory());
    _showResultSheet('⚙️ 커스텀 맞춤 번호', result, false);
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.notoSansKr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showResultSheet(String title, List<int> numbers, bool isVip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ResultSheet(
        title: title,
        numbers: numbers,
        isVip: isVip,
      ),
    ).then((_) {
      // 번호 결과를 먼저 확인한 후, 결과 창을 닫았을 때 전면 광고 노출
      _showInterstitialAd(() {});
    });
  }

  void _openCustomDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomSettingsSheet(
        includeNumbers: List.from(_includeNumbers),
        excludeNumbers: List.from(_excludeNumbers),
        onChanged: (inc, exc) {
          setState(() {
            _includeNumbers = inc;
            _excludeNumbers = exc;
          });
          _saveCustomFilters(inc, exc);
        },
        onGenerate: () {
          Navigator.pop(context);
          _generateCustomNumbers();
        },
      ),
    );
  }

  void _showNotificationSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const NotificationSettingsDialog(),
    );
  }

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
                if (AppColors.isLight) ...[
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
          Container(
            decoration: AppColors.isLight
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightAccentAmber.withValues(alpha: 0.6),
                  )
                : null,
            child: IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: AppColors.isLight ? AppColors.goldDeep : AppColors.textSecondary,
              ),
              tooltip: '추첨 알림 설정',
              onPressed: _showNotificationSettingsDialog,
            ),
          ),
          const SizedBox(width: 4),
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
              tooltip: '테마 변경',
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
        return VipTab(
          key: ValueKey('vip_$mode'),
          ctrl: _birthDateCtrl,
          vipNumbers: _vipNumbers,
          onGenerate: _generateVipNumbers,
          onBirthDateChanged: _onBirthDateChanged,
          shimmerCtrl: _shimmerCtrl,
        );
      case 3:
        return CustomTab(
          key: ValueKey('custom_$mode'),
          customNumbers: _customNumbers,
          includeNumbers: _includeNumbers,
          excludeNumbers: _excludeNumbers,
          onOpenDialog: _openCustomDialog,
          onGenerate: _generateCustomNumbers,
        );
      default:
        return HistoryTab(
          key: ValueKey('history_$mode'),
          history: _history,
          onClear: () async {
            await HistoryService.clear();
            await _loadHistory();
          },
          onDeleteEntry: (entry) async {
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

class _CalculationLoadingDialog extends StatefulWidget {
  final String title;
  final String step1;
  final String step2;

  const _CalculationLoadingDialog({
    required this.title,
    required this.step1,
    required this.step2,
  });

  @override
  State<_CalculationLoadingDialog> createState() => _CalculationLoadingDialogState();
}

class _CalculationLoadingDialogState extends State<_CalculationLoadingDialog> {
  late String _currentStep;
  Timer? _stepTimer;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.step1;
    _stepTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _currentStep = widget.step2);
      }
    });
    _closeTimer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.isLight ? AppColors.lightGoldBorder : AppColors.borderGold,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.12),
              ),
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.isLight ? AppColors.goldDark : AppColors.gold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: GoogleFonts.notoSansKr(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _currentStep,
                key: ValueKey(_currentStep),
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  color: AppColors.isLight ? AppColors.goldDark : AppColors.goldLight,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '알고리즘 연산 진행 중...',
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

