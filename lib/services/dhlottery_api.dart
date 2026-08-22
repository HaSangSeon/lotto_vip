import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DHLotteryResult {
  final int drwNo;
  final String drwNoDate;
  final List<int> numbers;
  final int bonusNo;
  final int firstWinamnt;     // 1등 1인당 당첨금
  final int firstWinCount;    // 1등 당첨자 수
  final int firstSumWinamnt;  // 1등 총 당첨금

  // 1등 당첨 유형 (자동 / 수동 / 반자동)
  final int winTypeAuto;
  final int winTypeManual;
  final int winTypeSemi;

  // 2등 ~ 5등 상세 정보
  final int rank2Count;
  final int rank2Amount;
  final int rank3Count;
  final int rank3Amount;
  final int rank4Count;
  final int rank4Amount;
  final int rank5Count;
  final int rank5Amount;

  final int totalSalesAmount; // 총 판매금액

  DHLotteryResult({
    required this.drwNo,
    required this.drwNoDate,
    required this.numbers,
    required this.bonusNo,
    required this.firstWinamnt,
    required this.firstWinCount,
    required this.firstSumWinamnt,
    this.winTypeAuto = 0,
    this.winTypeManual = 0,
    this.winTypeSemi = 0,
    this.rank2Count = 0,
    this.rank2Amount = 0,
    this.rank3Count = 0,
    this.rank3Amount = 0,
    this.rank4Count = 0,
    this.rank4Amount = 0,
    this.rank5Count = 0,
    this.rank5Amount = 0,
    this.totalSalesAmount = 0,
  });

  /// 1등 당첨자가 없으면 이월
  bool get isRollover => firstWinCount == 0;

  static int _parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  factory DHLotteryResult.fromJson(Map<String, dynamic> json) {
    // 날짜 형식 변환: 20231230 -> 2023-12-30
    String rawDate = json['ltRflYmd']?.toString() ?? json['drwNoDate']?.toString() ?? '';
    if (rawDate.length == 8 && !rawDate.contains('-')) {
      rawDate = '${rawDate.substring(0, 4)}-${rawDate.substring(4, 6)}-${rawDate.substring(6, 8)}';
    }

    List<int> parsedNumbers;
    if (json['numbers'] != null && json['numbers'] is List) {
      parsedNumbers = (json['numbers'] as List).map((e) => _parseInt(e)).toList();
    } else {
      parsedNumbers = [
        _parseInt(json['tm1WnNo']),
        _parseInt(json['tm2WnNo']),
        _parseInt(json['tm3WnNo']),
        _parseInt(json['tm4WnNo']),
        _parseInt(json['tm5WnNo']),
        _parseInt(json['tm6WnNo']),
      ];
    }

    return DHLotteryResult(
      drwNo: _parseInt(json['ltEpsd'] ?? json['drwNo']),
      drwNoDate: rawDate,
      numbers: parsedNumbers,
      bonusNo: _parseInt(json['bnsWnNo'] ?? json['bonusNo']),
      firstWinamnt: _parseInt(json['rnk1WnAmt'] ?? json['firstWinamnt']),
      firstWinCount: _parseInt(json['rnk1WnNope'] ?? json['firstWinCount']),
      firstSumWinamnt: _parseInt(json['rnk1SumWnAmt'] ?? json['firstSumWinamnt']),
      winTypeAuto: _parseInt(json['winType1'] ?? json['winTypeAuto']),
      winTypeManual: _parseInt(json['winType2'] ?? json['winTypeManual']),
      winTypeSemi: _parseInt(json['winType3'] ?? json['winTypeSemi']),
      rank2Count: _parseInt(json['rnk2WnNope'] ?? json['rank2Count']),
      rank2Amount: _parseInt(json['rnk2WnAmt'] ?? json['rank2Amount']),
      rank3Count: _parseInt(json['rnk3WnNope'] ?? json['rank3Count']),
      rank3Amount: _parseInt(json['rnk3WnAmt'] ?? json['rank3Amount']),
      rank4Count: _parseInt(json['rnk4WnNope'] ?? json['rank4Count']),
      rank4Amount: _parseInt(json['rnk4WnAmt'] ?? json['rank4Amount']),
      rank5Count: _parseInt(json['rnk5WnNope'] ?? json['rank5Count']),
      rank5Amount: _parseInt(json['rnk5WnAmt'] ?? json['rank5Amount']),
      totalSalesAmount: _parseInt(json['wholEpsdSumNtslAmt'] ?? json['rlvtEpsdSumNtslAmt'] ?? json['totalSalesAmount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'drwNo': drwNo,
        'drwNoDate': drwNoDate,
        'numbers': numbers,
        'bonusNo': bonusNo,
        'firstWinamnt': firstWinamnt,
        'firstWinCount': firstWinCount,
        'firstSumWinamnt': firstSumWinamnt,
        'winTypeAuto': winTypeAuto,
        'winTypeManual': winTypeManual,
        'winTypeSemi': winTypeSemi,
        'rank2Count': rank2Count,
        'rank2Amount': rank2Amount,
        'rank3Count': rank3Count,
        'rank3Amount': rank3Amount,
        'rank4Count': rank4Count,
        'rank4Amount': rank4Amount,
        'rank5Count': rank5Count,
        'rank5Amount': rank5Amount,
        'totalSalesAmount': totalSalesAmount,
      };
}

class DHLotteryApi {
  static const String _baseUrl =
      'https://www.dhlottery.co.kr/lt645/selectPstLt645Info.do?srchLtEpsd=';
  static const String _cacheKey = 'dh_lottery_cached_result';

  static DHLotteryResult? _memoryCachedResult;
  static final Map<int, DHLotteryResult> _drawCache = {};

  /// 오늘 날짜 기준으로 대략적인 최신 회차를 계산
  static int _calculateLatestDrawNo() {
    final firstDraw = DateTime(2002, 12, 7, 21, 0, 0); // 1회차 추첨일
    final now = DateTime.now();
    final diff = now.difference(firstDraw);
    return (diff.inDays / 7).floor() + 1;
  }

  /// 최신 당첨 번호 가져오기 (네트워크 실패 시 로컬 캐시 자동 제공)
  static Future<DHLotteryResult?> fetchLatest() async {
    int guessNo = _calculateLatestDrawNo();

    // 최신 회차부터 최대 3회차 이전까지 시도
    for (int i = 0; i < 3; i++) {
      final res = await fetchByDrawNo(guessNo - i);
      if (res != null) {
        _memoryCachedResult = res;
        _saveToLocalCache(res);
        return res;
      }
    }
    
    // 실패 시 로컬 persistent 캐시 로드
    return await _loadFromLocalCache();
  }

  /// 특정 회차 당첨 번호 및 상세 데이터 가져오기
  static Future<DHLotteryResult?> fetchByDrawNo(int drwNo) async {
    if (_drawCache.containsKey(drwNo)) {
      return _drawCache[drwNo];
    }
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl$drwNo'))
          .timeout(const Duration(seconds: 4));
          
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic>? list = body['data']?['list'];
        if (list != null && list.isNotEmpty) {
          final result = DHLotteryResult.fromJson(Map<String, dynamic>.from(list[0]));
          _drawCache[drwNo] = result;
          return result;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<void> _saveToLocalCache(DHLotteryResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(result.toJson()));
    } catch (_) {}
  }

  static Future<DHLotteryResult?> _loadFromLocalCache() async {
    if (_memoryCachedResult != null) return _memoryCachedResult;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> json = jsonDecode(raw);
        _memoryCachedResult = DHLotteryResult.fromJson(json);
        if (_memoryCachedResult != null) {
          _drawCache[_memoryCachedResult!.drwNo] = _memoryCachedResult!;
        }
        return _memoryCachedResult;
      }
    } catch (_) {}
    return null;
  }
}
