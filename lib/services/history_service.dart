import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum LottoEntryType {
  shake, // 흔들어 뽑기
  dream, // 꿈해몽
  birthDate, // 생년월일
  customFilter, // 맞춤필터
  diagnosis, // 황금밸런스 진단
  qrScan, // 실제 구매 복권 (QR 스캔)
}

class SavedLotteryGame {
  final String label; // A, B, C, D, E
  final List<int> numbers; // 6 numbers

  const SavedLotteryGame({
    required this.label,
    required this.numbers,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'numbers': numbers,
      };

  factory SavedLotteryGame.fromJson(Map<String, dynamic> json) =>
      SavedLotteryGame(
        label: json['label'] ?? '',
        numbers: List<int>.from(json['numbers'] ?? []),
      );
}

class LottoHistoryEntry {
  final String title;
  final List<int> numbers;
  final List<SavedLotteryGame>? games; // 실물 복권인 경우 복수 게임(A~E)
  final DateTime createdAt;
  bool isFavorite;

  LottoHistoryEntry({
    required this.title,
    required this.numbers,
    this.games,
    required this.createdAt,
    this.isFavorite = false,
  });

  /// 묶음 실물 복권 여부 (여러 게임을 포함하는 티켓)
  bool get isTicket => games != null && games!.isNotEmpty;

  /// 게임 개수 (단일 번호면 1, 묶음 티켓이면 게임 개수)
  int get gameCount => isTicket ? games!.length : 1;

  LottoEntryType get entryType {
    if (title.contains('QR') || title.contains('스캔') || isTicket) {
      return LottoEntryType.qrScan;
    } else if (title.contains('흔들')) {
      return LottoEntryType.shake;
    } else if (title.contains('꿈') || title.contains('해몽')) {
      return LottoEntryType.dream;
    } else if (title.contains('생년월일') || title.contains('VIP') || title.contains('행운')) {
      return LottoEntryType.birthDate;
    } else if (title.contains('진단') || title.contains('밸런스')) {
      return LottoEntryType.diagnosis;
    } else {
      return LottoEntryType.customFilter;
    }
  }

  String get typeBadgeLabel {
    switch (entryType) {
      case LottoEntryType.qrScan:
        return isTicket ? '🎫 실물복권 ($gameCount게임)' : '🎫 실물복권';
      case LottoEntryType.shake:
        return '🎲 흔들어 뽑기';
      case LottoEntryType.dream:
        return '🌙 꿈해몽';
      case LottoEntryType.birthDate:
        return '🎂 생년월일';
      case LottoEntryType.diagnosis:
        return '🎯 밸런스진단';
      case LottoEntryType.customFilter:
        return '⚙️ 맞춤필터';
    }
  }

  /// 번호가 속한 회차 계산 (제목에 명시된 회차 우선, 없으면 생성일 기준 공식 회차)
  int get drawNo {
    final match = RegExp(r'제?(\d{3,5})회').firstMatch(title);
    if (match != null) {
      final parsed = int.tryParse(match.group(1)!);
      if (parsed != null && parsed > 0) return parsed;
    }

    return HistoryService.calculateTargetDrawNo(createdAt);
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'numbers': numbers,
        if (games != null) 'games': games!.map((g) => g.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'isFavorite': isFavorite,
      };

  factory LottoHistoryEntry.fromJson(Map<String, dynamic> json) =>
      LottoHistoryEntry(
        title: json['title'] ?? '보관된 번호',
        numbers: List<int>.from(json['numbers'] ?? []),
        games: json['games'] != null
            ? (json['games'] as List)
                .map((e) =>
                    SavedLotteryGame.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        isFavorite: json['isFavorite'] ?? false,
      );
}

class HistoryService {
  static const _key = 'lotto_history';
  static const _maxEntries = 500; // 30개 제한에서 500개로 대폭 확장

  /// 최근 생성순(최신순)으로 정렬하여 로드
  static Future<List<LottoHistoryEntry>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getStringList(_key) ?? [];
      final entries = raw
          .map((e) => LottoHistoryEntry.fromJson(jsonDecode(e)))
          .toList();

      // 최신 생성 순으로 내림차순 정렬 (새로 추가된 항목이 맨 위)
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    } catch (e) {
      return [];
    }
  }

  /// 단일 기록 추가 (생성시간 기준 순서 보장)
  static Future<void> save(LottoHistoryEntry entry) async {
    final currentList = await load();
    currentList.insert(0, entry); // 최신 항목 맨 앞 추가

    if (currentList.length > _maxEntries) {
      currentList.removeRange(_maxEntries, currentList.length);
    }
    await updateAll(currentList);
  }

  /// 전체 기록 업데이트 (항상 생성시간 순서로 저장하여 뒤얽힘 방지)
  static Future<void> updateAll(List<LottoHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    // 저장할 때는 항상 최신순 저장 유지
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final toSave = entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, toSave);
  }

  /// 특정 기록 개별 삭제
  static Future<void> delete(LottoHistoryEntry entry) async {
    final currentList = await load();
    currentList.removeWhere((e) =>
        e.createdAt.millisecondsSinceEpoch == entry.createdAt.millisecondsSinceEpoch &&
        e.title == entry.title);
    await updateAll(currentList);
  }

  /// 인덱스 기준 개별 삭제
  static Future<void> deleteAt(int index) async {
    final currentList = await load();
    if (index >= 0 && index < currentList.length) {
      currentList.removeAt(index);
      await updateAll(currentList);
    }
  }

  /// 기록 전체 삭제
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// 특정 일시(생성일 등) 기준 판매 대상 로또 추첨 회차 계산
  /// 매주 토요일 20:00 이전 생성 -> 이번 주 토요일 추첨 회차
  /// 매주 토요일 20:00 이후 생성 -> 다음 주 토요일 추첨 회차
  static int calculateTargetDrawNo(DateTime dateTime) {
    final firstDrawSaturday = DateTime(2002, 12, 7, 20, 0, 0);
    if (dateTime.isBefore(firstDrawSaturday)) return 1;

    int daysUntilSaturday = DateTime.saturday - dateTime.weekday;
    if (daysUntilSaturday < 0) {
      daysUntilSaturday += 7;
    } else if (daysUntilSaturday == 0) {
      if (dateTime.hour > 20 || (dateTime.hour == 20 && dateTime.minute >= 0)) {
        // 토요일 20:00 이후 판매 마감 -> 다음 회차
        daysUntilSaturday = (dateTime.hour == 20 && dateTime.minute == 0 && dateTime.second == 0)
            ? 0
            : 7;
      }
    }

    final targetSaturday = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day + daysUntilSaturday,
      20,
      0,
      0,
    );
    final diff = targetSaturday.difference(firstDrawSaturday);
    return (diff.inDays / 7).round() + 1;
  }

  /// 보관함 상단 '이번 주 추첨 예정' 안내용 회차 계산 (추첨 발표 토요일 20:45 기준)
  /// 토요일 20:00 판매가 마감되어도, 20:45 추첨 발표 전까지는 이번 주 회차가 유지됩니다.
  static int calculateUpcomingDrawNo(DateTime dateTime) {
    final firstDrawSaturday = DateTime(2002, 12, 7, 20, 45, 0);
    if (dateTime.isBefore(firstDrawSaturday)) return 1;

    int daysUntilSaturday = DateTime.saturday - dateTime.weekday;
    if (daysUntilSaturday < 0) {
      daysUntilSaturday += 7;
    } else if (daysUntilSaturday == 0) {
      final isDrawn = dateTime.hour > 20 || (dateTime.hour == 20 && dateTime.minute >= 45);
      if (isDrawn) {
        daysUntilSaturday = 7;
      }
    }

    final targetSaturday = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day + daysUntilSaturday,
      20,
      45,
      0,
    );
    final diff = targetSaturday.difference(firstDrawSaturday);
    return (diff.inDays / 7).round() + 1;
  }
}
