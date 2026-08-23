import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum LottoEntryType {
  vipLucky, // 오늘의 VIP 행운 번호
  custom, // 맞춤 번호 조합
  qrScan, // 실제 구매 복권 (QR 스캔)
}

class LottoHistoryEntry {
  final String title;
  final List<int> numbers;
  final DateTime createdAt;
  bool isFavorite;

  LottoHistoryEntry({
    required this.title,
    required this.numbers,
    required this.createdAt,
    this.isFavorite = false,
  });

  LottoEntryType get entryType {
    if (title.contains('QR') || title.contains('스캔')) {
      return LottoEntryType.qrScan;
    } else if (title.contains('VIP') || title.contains('행운')) {
      return LottoEntryType.vipLucky;
    } else {
      return LottoEntryType.custom;
    }
  }

  String get typeBadgeLabel {
    switch (entryType) {
      case LottoEntryType.qrScan:
        return '🎫 실물 복권';
      case LottoEntryType.vipLucky:
        return '👑 VIP 행운';
      case LottoEntryType.custom:
        return '⚙️ 맞춤 조합';
    }
  }

  /// 번호가 속한 회차 계산 (제목에 명시된 회차 우선, 없으면 생성일 기준 공식 회차)
  int get drawNo {
    final match = RegExp(r'제?(\d{3,5})회').firstMatch(title);
    if (match != null) {
      final parsed = int.tryParse(match.group(1)!);
      if (parsed != null && parsed > 0) return parsed;
    }

    // 1회차: 2002년 12월 7일 (토) 20:00 마감
    final firstDrawDate = DateTime(2002, 12, 7, 20, 0, 0);
    final diff = createdAt.difference(firstDrawDate);
    if (diff.isNegative) return 1;
    return (diff.inDays / 7).floor() + 1;
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'numbers': numbers,
        'createdAt': createdAt.toIso8601String(),
        'isFavorite': isFavorite,
      };

  factory LottoHistoryEntry.fromJson(Map<String, dynamic> json) =>
      LottoHistoryEntry(
        title: json['title'] ?? '보관된 번호',
        numbers: List<int>.from(json['numbers'] ?? []),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        isFavorite: json['isFavorite'] ?? false,
      );
}

class HistoryService {
  static const _key = 'lotto_history';
  static const _maxEntries = 30;

  /// 최근 생성순(최신순)으로 정렬하여 로드
  static Future<List<LottoHistoryEntry>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
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
}
