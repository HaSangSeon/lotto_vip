import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
