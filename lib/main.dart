import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';

import 'theme/app_theme.dart';
import 'services/history_service.dart';
import 'services/notification_service.dart';
import 'widgets/splash_screen.dart';
import 'widgets/latest_draw_tab.dart';
import 'widgets/vip_tab.dart';
import 'widgets/statistics_tab.dart';
import 'widgets/history_tab.dart';
import 'widgets/custom_settings_sheet.dart';
import 'widgets/result_sheet.dart';
import 'widgets/notification_settings_dialog.dart';
import 'widgets/qr_scanner_view.dart';
import 'widgets/dialogs/calculation_loading_dialog.dart';
import 'widgets/dialogs/app_info_dialog.dart';
import 'widgets/home_header.dart';
import 'widgets/home_bottom_bar.dart';
import 'widgets/home_background_orbs.dart';

import 'dart:ui' as ui;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError caught safely: ${details.exception}');
  };

  ui.PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error caught safely: $error');
    return true; // Prevents app crash
  };

  try {
    KakaoSdk.init(nativeAppKey: '4fbc1168c5aab0bfff20dfefc86a1bb2');
    await initializeDateFormatting('ko_KR', null);
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
          builder: (context, child) {
            return MediaQuery.withClampedTextScaling(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.15, // 최대 1.15배까지만 폰트 크기 증가 허용
              child: child!,
            );
          },
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

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 앱이 화면으로 돌아왔을 때 알림 스케줄 자가 치유(Auto-Healing)
      if (NotificationService.isEnabled) {
        NotificationService.scheduleWeeklyDrawNotification();
      }
    }
  }

  void _onNotificationTapped() {
    final payload = NotificationService.onNotificationPayload.value;
    if (payload != null && mounted) {
      setState(() {
        _selectedTab = 3; // 보관함(히스토리) 탭으로 이동
      });
      _loadHistory();

      if (payload.contains(':')) {
        final drwStr = payload.split(':').last;
        final drwNo = int.tryParse(drwStr);
        if (drwNo != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showToast('📢 제$drwNo회 등록 복권의 당첨 결과를 확인하세요!');
          });
        }
      }

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
    WidgetsBinding.instance.removeObserver(this);
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
      if (!mounted) {
        _isBannerAdLoading = false;
        return;
      }
      final screenWidth = MediaQuery.of(context).size.width.truncate();
      if (screenWidth <= 0) {
        _isBannerAdLoading = false;
        return;
      }
      // ignore: deprecated_member_use
      final AnchoredAdaptiveBannerAdSize? size =
          // ignore: deprecated_member_use
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
                _isBannerAdLoading = false;
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
      builder: (ctx) => CalculationLoadingDialog(
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
      final upcomingDrawNo = HistoryService.calculateTargetDrawNo(DateTime.now());
      final entry = LottoHistoryEntry(
        title: '제$upcomingDrawNo회 생년월일 행운 번호',
        numbers: result,
        createdAt: DateTime.now(),
      );
      await HistoryService.save(entry);
      await NotificationService.scheduleWeeklyDrawNotification();
      await _loadHistory();
    }

    _showResultSheet('🎂 생년월일 행운 번호', result, true);
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
    final upcomingDrawNo = HistoryService.calculateTargetDrawNo(DateTime.now());
    final entry = LottoHistoryEntry(
      title: '제$upcomingDrawNo회 맞춤필터 번호',
      numbers: result,
      createdAt: DateTime.now(),
    );
    await HistoryService.save(entry);
    await NotificationService.scheduleWeeklyDrawNotification();
    await _loadHistory();
    _showResultSheet('⚙️ 맞춤필터 추천 번호', result, false);
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
      useSafeArea: true,
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
      useSafeArea: true,
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
    AppInfoDialog.show(context);
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
            bottomNavigationBar: HomeBottomBar(
              selectedTab: _selectedTab,
              bannerAdWidget: _buildBannerAd(),
              onTabSelected: (index) {
                setState(() => _selectedTab = index);
                if (index == 3) {
                  _loadHistory();
                }
              },
            ),
            body: Stack(
              children: [
                const HomeBackgroundOrbs(),
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
    return HomeHeader(
      onQrScanTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QrScannerView(
              onHistorySaved: _loadHistory,
            ),
          ),
        );
        _loadHistory();
      },
      onNotificationTap: _showNotificationSettingsDialog,
      onAppInfoTap: _showAppInfoDialog,
      pulseAnimation: _pulseCtrl,
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
        return VipTab(
          key: ValueKey('vip_$mode'),
          ctrl: _birthDateCtrl,
          vipNumbers: _vipNumbers,
          onGenerate: _generateVipNumbers,
          onBirthDateChanged: _onBirthDateChanged,
          shimmerCtrl: _shimmerCtrl,
          customNumbers: _customNumbers,
          includeNumbers: _includeNumbers,
          excludeNumbers: _excludeNumbers,
          onOpenCustomDialog: _openCustomDialog,
          onGenerateCustom: _generateCustomNumbers,
        );
      case 2:
        return StatisticsTab(
          key: ValueKey('stat_$mode'),
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
          onRefresh: _loadHistory,
        );
    }
  }

  Widget _buildBannerAd() {
    if (!_isBannerLoaded || _bannerAd == null || _bannerAdWidget == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      color: AppColors.surface,
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: _bannerAdWidget!,
      ),
    );
  }
}

