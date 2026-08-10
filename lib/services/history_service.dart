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
        title: json['title'],
        numbers: List<int>.from(json['numbers']),
        createdAt: DateTime.parse(json['createdAt']),
        isFavorite: json['isFavorite'] ?? false,
      );
}

class HistoryService {
  static const _key = 'lotto_history';
  static const _maxEntries = 20;

  static Future<List<LottoHistoryEntry>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? [];
      return raw
          .map((e) => LottoHistoryEntry.fromJson(jsonDecode(e)))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> save(LottoHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(entry.toJson()));
    if (raw.length > _maxEntries) {
      raw.removeRange(0, raw.length - _maxEntries);
    }
    await prefs.setStringList(_key, raw);
  }

  static Future<void> updateAll(List<LottoHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    // Since load() reversed the list, we need to reverse it back when saving
    final toSave = entries.reversed.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, toSave);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
