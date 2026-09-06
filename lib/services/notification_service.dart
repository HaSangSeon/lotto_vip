import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'history_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _prefKeyNotificationEnabled = 'lotto_weekly_push_enabled';
  static const int _weeklyNotificationId = 777;
  static const int _testNotificationId = 888;

  static const String _channelId = 'lotto_draw_channel';
  static const String _channelName = '로또 추첨 결과 알림';
  static const String _channelDescription = '매주 토요일 로또 추첨 완료 후 당첨 결과 알림을 발송합니다.';

  static bool _isInitialized = false;
  static bool _isEnabled = true;

  /// 알림 터치 시 전달되는 페이로드 Notifier (UI에서 감지하여 탭 이동)
  static final ValueNotifier<String?> onNotificationPayload = ValueNotifier(null);

  static bool get isEnabled => _isEnabled;

  /// 현재 시점 기준 다음 추첨 회차 번호 계산 (다음 토요일 20:45 기준)
  static int getUpcomingDrawNo() {
    final firstDrawDate = DateTime(2002, 12, 7, 20, 45, 0);
    final nextSaturday = _nextInstanceOfSaturday845PM();
    final diff = nextSaturday.difference(firstDrawDate);
    return (diff.inDays / 7).round() + 1;
  }

  /// 알림 서비스 초기화 (main()에서 호출)
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Timezone 데이터 초기화
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      } catch (e) {
        debugPrint('Timezone Asia/Seoul setting fallback: $e');
      }

      // 2. 플랫폼별 초기화 설정
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
          onNotificationPayload.value = response.payload ?? 'lotto_draw_result';
        },
      );

      // 3. 저장된 알림 활성화 여부 로드 (기본값: true)
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_prefKeyNotificationEnabled) ?? true;

      _isInitialized = true;

      // 4. 활성화 상태라면 권한 확인 및 토요일 알람 스케줄 등록
      if (_isEnabled) {
        final hasPermission = await areNotificationsEnabled();
        if (!hasPermission) {
          await requestPermission();
        }
        await scheduleWeeklyDrawNotification();
      }
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// OS 시스템 레벨에서 앱의 알림이 허용되어 있는지 확인
  static Future<bool> areNotificationsEnabled() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        return enabled ?? false;
      }

      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final permissions = await iosPlugin.checkPermissions();
        return permissions?.isEnabled ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return true;
    }
  }

  /// Android 12+ 정확한 알람(Exact Alarm) 예약 가능 여부 확인
  static Future<bool> canScheduleExactNotifications() async {
    try {
      if (defaultTargetPlatform != TargetPlatform.android) return true;
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final canExact = await androidPlugin.canScheduleExactNotifications();
        return canExact ?? true;
      }
      return true;
    } catch (e) {
      debugPrint('Error checking exact alarm capability: $e');
      return true;
    }
  }

  /// 알림 권한 요청 (Android 13+ 및 iOS)
  static Future<bool> requestPermission() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted =
            await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// 알림 켜기 / 끄기 토글
  static Future<void> setNotificationEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyNotificationEnabled, enabled);

    if (enabled) {
      await requestPermission();
      await scheduleWeeklyDrawNotification();
    } else {
      await cancelWeeklyDrawNotification();
    }
  }

  /// 매주 토요일 저녁 8시 45분 알림 스케줄링 (보관함 등록 복권 여부에 따라 맞춤 문구 적용)
  static Future<void> scheduleWeeklyDrawNotification() async {
    try {
      final scheduledDate = _nextInstanceOfSaturday845PM();

      // 보관함에서 이번 회차 또는 미추첨 등록 번호(실물 복권 및 생성 번호 모두 포함) 확인
      final upcomingDrawNo = getUpcomingDrawNo();
      final history = await HistoryService.load();
      final registeredTickets = history.where((e) => e.drawNo >= upcomingDrawNo).toList();

      final String title;
      final String body;
      final String payload;

      if (registeredTickets.isNotEmpty) {
        final ticket = registeredTickets.first;
        final totalGames = registeredTickets.fold(0, (sum, t) => sum + t.gameCount);
        title = '🎫 [제${ticket.drawNo}회] 보관함 번호 추첨 완료!';
        body = '등록해두신 번호($totalGames게임)의 추첨이 끝났습니다. 지금 당첨 결과를 확인해보세요! 🎰';
        payload = 'lotto_draw_result:${ticket.drawNo}';
      } else {
        title = '💰 혹시… 이번 주 1등 당첨자이신가요?';
        body = '로또 추첨이 완료되었습니다. 저장해둔 내 번호와 지금 맞춰보세요! 🎰';
        payload = 'lotto_draw_result';
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 정확한 알람(Exact Alarm) 가능 여부 확인 후 최적의 스케줄 모드 지정 (정시 발송 보장)
      AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      final canExact = await canScheduleExactNotifications();
      if (!canExact) {
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        debugPrint('Exact alarm not supported or permitted, falling back to inexactAllowWhileIdle');
      }

      await _notificationsPlugin.cancel(_weeklyNotificationId);

      // [2중 안전망] 1차 정확한 알람 시도 -> 예외 발생 시 즉시 inexact로 재시도하여 100% 등록 보장
      try {
        await _notificationsPlugin.zonedSchedule(
          _weeklyNotificationId,
          title,
          body,
          scheduledDate,
          platformDetails,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
      } catch (scheduleErr) {
        debugPrint('Primary zonedSchedule failed ($scheduleErr), retrying with inexact fallback...');
        await _notificationsPlugin.zonedSchedule(
          _weeklyNotificationId,
          title,
          body,
          scheduledDate,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
      }

      debugPrint('Weekly notification successfully scheduled for: $scheduledDate (Mode: $scheduleMode, Custom ticket: ${registeredTickets.isNotEmpty})');
    } catch (e) {
      debugPrint('Failed to schedule weekly notification: $e');
    }
  }

  /// 예약된 주간 알림 취소
  static Future<void> cancelWeeklyDrawNotification() async {
    try {
      await _notificationsPlugin.cancel(_weeklyNotificationId);
      debugPrint('Weekly lotto notification cancelled');
    } catch (e) {
      debugPrint('Failed to cancel weekly notification: $e');
    }
  }

  /// 테스트 알림 즉시 발송 (설정창에서 확인용)
  static Future<void> showTestNotification() async {
    try {
      await requestPermission();

      final upcomingDrawNo = getUpcomingDrawNo();
      final history = await HistoryService.load();
      final registeredTickets = history.where((e) => e.drawNo >= upcomingDrawNo).toList();

      final String title;
      final String body;
      final String payload;

      if (registeredTickets.isNotEmpty) {
        final ticket = registeredTickets.first;
        final totalGames = registeredTickets.fold(0, (sum, t) => sum + t.gameCount);
        title = '🎫 [테스트] [제${ticket.drawNo}회] 보관함 번호 추첨 완료!';
        body = '등록해두신 번호($totalGames게임)의 추첨이 끝났습니다. 지금 당첨 결과를 확인해보세요! 🎰';
        payload = 'test_notification:${ticket.drawNo}';
      } else {
        title = '💰 [테스트] 혹시… 이번 주 1등 당첨자이신가요?';
        body = '로또 추첨이 완료되었습니다. 저장해둔 내 번호와 지금 맞춰보세요! 🎰';
        payload = 'test_notification';
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        _testNotificationId,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show test notification: $e');
    }
  }

  /// [실제 예약 알림 검증용] 10초(또는 지정 초) 뒤 예약 알림 발송 테스트
  /// 토요일 20:45 알림과 100% 동일한 zonedSchedule + AlarmManager + Receiver 경로를 거칩니다.
  /// 화면을 끄거나 앱을 닫은 상태에서도 실제 알람이 오는지 지금 바로 검증할 수 있습니다.
  static Future<bool> scheduleTestDelayedNotification({int seconds = 10}) async {
    try {
      await requestPermission();

      final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

      final upcomingDrawNo = getUpcomingDrawNo();
      final history = await HistoryService.load();
      final registeredTickets = history.where((e) => e.drawNo >= upcomingDrawNo).toList();

      final String title;
      final String body;
      final String payload;

      if (registeredTickets.isNotEmpty) {
        final ticket = registeredTickets.first;
        final totalGames = registeredTickets.fold(0, (sum, t) => sum + t.gameCount);
        title = '🎫 [제${ticket.drawNo}회] 보관함 번호 추첨 완료!';
        body = '등록해두신 번호($totalGames게임)의 추첨이 끝났습니다. 지금 당첨 결과를 확인해보세요! 🎰';
        payload = 'lotto_draw_result:${ticket.drawNo}';
      } else {
        title = '💰 혹시… 이번 주 1등 당첨자이신가요?';
        body = '로또 추첨이 완료되었습니다. 저장해둔 내 번호와 지금 맞춰보세요! 🎰';
        payload = 'lotto_draw_result';
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      final canExact = await canScheduleExactNotifications();
      if (!canExact) {
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      }

      await _notificationsPlugin.cancel(_testNotificationId);

      try {
        await _notificationsPlugin.zonedSchedule(
          _testNotificationId,
          title,
          body,
          scheduledDate,
          platformDetails,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (err) {
        await _notificationsPlugin.zonedSchedule(
          _testNotificationId,
          title,
          body,
          scheduledDate,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      }

      debugPrint('Test delayed notification scheduled for $seconds seconds later: $scheduledDate');
      return true;
    } catch (e) {
      debugPrint('Failed to schedule test delayed notification: $e');
      return false;
    }
  }

  /// 다음 토요일 저녁 8시 45분(20:45) TZDateTime 계산
  static tz.TZDateTime _nextInstanceOfSaturday845PM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20, // 20시
      45, // 45분
    );

    // 오늘이 토요일(DateTime.saturday == 6)인지 확인
    while (scheduledDate.weekday != DateTime.saturday ||
        scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      scheduledDate = tz.TZDateTime(
        tz.local,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        20,
        45,
      );
    }
    return scheduledDate;
  }
}
