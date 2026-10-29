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
  static DHLotteryResult? get cachedResult => _memoryCachedResult;
  static final Map<int, DHLotteryResult> _drawCache = {};

  /// 오늘 날짜 기준으로 대략적인 최신 회차를 계산 (토요일 20:35 추첨 방송 기준)
  static int _calculateLatestDrawNo() {
    // 1회차: 2002-12-07 20:35:00 KST
    final firstDrawKst = DateTime.utc(2002, 12, 7, 11, 35, 0); // UTC 11:35 = KST 20:35
    final nowUtc = DateTime.now().toUtc();
    final diff = nowUtc.difference(firstDrawKst);
    if (diff.isNegative) return 1;
    return (diff.inSeconds / (7 * 86400)).floor() + 1;
  }

  /// 최신 당첨 번호 가져오기 (네트워크 실패 시 로컬 캐시 자동 제공)
  static Future<DHLotteryResult?> fetchLatest() async {
    int guessNo = _calculateLatestDrawNo();

    // 토요일 20:35 직후 등 신규 회차가 등록되었을 수 있으므로 guessNo + 1부터 시도
    for (int offset = 1; offset >= -2; offset--) {
      final targetNo = guessNo + offset;
      if (targetNo < 1) continue;
      final res = await fetchByDrawNo(targetNo);
      if (res != null && res.numbers.length == 6) {
        _memoryCachedResult = res;
        _saveToLocalCache(res);
        return res;
      }
    }
    
    // 실패 시 로컬 persistent 캐시 로드
    return await _loadFromLocalCache();
  }

  /// 특정 회차 당첨 번호 및 상세 데이터 가져오기 (메모리 & 영구 로컬 캐시 적용)
  static Future<DHLotteryResult?> fetchByDrawNo(int drwNo) async {
    // 1. 메모리 캐시 확인 (단, 당첨금 집계가 완료된 건만 유효)
    if (_drawCache.containsKey(drwNo)) {
      final mem = _drawCache[drwNo]!;
      if (_isDrawResultCompleted(mem)) {
        return mem;
      }
    }

    // 2. 영구 디스크 캐시(SharedPreferences) 확인
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRaw = prefs.getString('draw_result_$drwNo');
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        final Map<String, dynamic> json = jsonDecode(cachedRaw);
        final result = DHLotteryResult.fromJson(json);
        // 당첨금 집계가 완전히 끝난 데이터만 캐시로 인정 (미집계 0원 데이터 캐싱 방지)
        if (_isDrawResultCompleted(result)) {
          _drawCache[drwNo] = result;
          return result;
        }
      }
    } catch (_) {}

    // 3. 네트워크 통신
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl$drwNo'))
          .timeout(const Duration(seconds: 5));
          
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic>? list = body['data']?['list'];
        if (list != null && list.isNotEmpty) {
          final result = DHLotteryResult.fromJson(Map<String, dynamic>.from(list[0]));
          // 추첨 번호 6개와 보너스 번호가 모두 1~45 범위의 유효한 숫자인지 검증 ([0,0,0,0,0,0] 미추첨 데이터 방어)
          if (!_hasValidWinningNumbers(result)) {
            return null;
          }

          _drawCache[drwNo] = result;

          // 당첨금 및 당첨자 수 집계가 완전히 완료된 데이터만 영구 캐싱
          if (_isDrawResultCompleted(result)) {
            _saveDrawToDiskCache(drwNo, result);
          }
          return result;
        }
      }
    } catch (_) {}
    return null;
  }

  /// 당첨 번호 6개 및 보너스 번호가 모두 유효한 범위(1~45)인지 검증
  static bool _hasValidWinningNumbers(DHLotteryResult r) {
    if (r.numbers.length != 6) return false;
    if (r.bonusNo < 1 || r.bonusNo > 45) return false;
    return r.numbers.every((n) => n >= 1 && n <= 45);
  }

  /// 당첨금 및 당첨자 집계가 정상 완료된 데이터인지 판별 (미집계 0원 박제 방지)
  static bool _isDrawResultCompleted(DHLotteryResult r) {
    if (!_hasValidWinningNumbers(r)) return false;
    // 1등 당첨금이 있거나, 총판매금액이 집계되었거나, 2등/5등 당첨자수가 집계된 경우
    if (r.firstSumWinamnt > 0 || r.firstWinamnt > 0 || r.totalSalesAmount > 0) {
      return true;
    }
    // 이월된 경우(firstWinCount == 0)라도 totalSalesAmount나 2등 인원이 있으면 완료
    if (r.firstWinCount == 0 && (r.rank2Count > 0 || r.rank5Count > 0)) {
      return true;
    }
    return false;
  }

  static Future<void> _saveDrawToDiskCache(int drwNo, DHLotteryResult result) async {
    try {
      if (result.numbers.length == 6 && _isDrawResultCompleted(result)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('draw_result_$drwNo', jsonEncode(result.toJson()));
      }
    } catch (_) {}
  }

  static Future<void> _saveToLocalCache(DHLotteryResult result) async {
    try {
      if (_isDrawResultCompleted(result)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonEncode(result.toJson()));
      }
    } catch (_) {}
  }

  static Future<DHLotteryResult?> _loadFromLocalCache() async {
    if (_memoryCachedResult != null && _isDrawResultCompleted(_memoryCachedResult!)) {
      return _memoryCachedResult;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> json = jsonDecode(raw);
        final res = DHLotteryResult.fromJson(json);
        if (_isDrawResultCompleted(res)) {
          _memoryCachedResult = res;
          _drawCache[res.drwNo] = res;
          return res;
        }
      }
    } catch (_) {}
    return null;
  }

  static final Map<String, List<DHLotteryWinningStore>> _storeMemoryCache = {};

  /// 특정 회차의 당첨 판매점 목록 조회 API (rank 1: 1등, rank 2: 2등)
  static Future<List<DHLotteryWinningStore>> fetchWinningStores(int drwNo, {int rank = 1}) async {
    final cacheKey = 'winning_stores_${drwNo}_$rank';

    // 1. 메모리 캐시 확인 (rank 구분된 고유 키)
    if (_storeMemoryCache.containsKey(cacheKey) && _storeMemoryCache[cacheKey]!.isNotEmpty) {
      return _storeMemoryCache[cacheKey]!;
    }

    // 2. 로컬 디스크 캐시(SharedPreferences) 확인
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRaw = prefs.getString(cacheKey);
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedRaw);
        final cachedList = decoded
            .map((e) => DHLotteryWinningStore.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (cachedList.isNotEmpty) {
          _storeMemoryCache[cacheKey] = cachedList;
          return cachedList;
        }
      }
    } catch (_) {}

    // 3. 동행복권 공식 REST API 네트워크 통신
    try {
      final url = Uri.parse(
        'https://www.dhlottery.co.kr/wnprchsplcsrch/selectLtWnShp.do?srchWnShpRnk=$rank&srchLtEpsd=$drwNo',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final list = decoded['data']?['list'];
        if (list is List && list.isNotEmpty) {
          final resultList = list
              .map((item) => DHLotteryWinningStore.fromJson(Map<String, dynamic>.from(item)))
              .toList();

          _storeMemoryCache[cacheKey] = resultList;

          // 판매점 목록 영구 캐싱 저장
          try {
            final prefs = await SharedPreferences.getInstance();
            final rawJson = jsonEncode(resultList.map((e) => e.toJson()).toList());
            await prefs.setString(cacheKey, rawJson);
          } catch (_) {}

          return resultList;
        }
      }
    } catch (_) {}
    return [];
  }
}

class DHLotteryWinningStore {
  final int rank; // 1 (1등)
  final String name; // shpNm (상호명)
  final String address; // shpAddr (상세주소)
  final String region; // region (지역: 서울, 경기 등)
  final String winType; // atmtPsvYnTxt (자동, 수동, 반자동)
  final String? phone; // shpTelno (전화번호)
  final double? lat; // shpLat
  final double? lng; // shpLot

  DHLotteryWinningStore({
    required this.rank,
    required this.name,
    required this.address,
    required this.region,
    required this.winType,
    this.phone,
    this.lat,
    this.lng,
  });

  factory DHLotteryWinningStore.fromJson(Map<String, dynamic> json) {
    final rawAddr = (json['shpAddr'] ?? '').toString();
    final cleanAddr = rawAddr.replaceAll(RegExp(r'\s+'), ' ').trim();

    final rawType = (json['atmtPsvYnTxt'] ?? '').toString().trim();
    final winTypeStr = rawType.isNotEmpty ? rawType : (json['wnShpRnk'] == 1 ? '구분없음' : '-');

    return DHLotteryWinningStore(
      rank: json['wnShpRnk'] is int ? json['wnShpRnk'] : 1,
      name: (json['shpNm'] ?? '복권판매점').toString().trim(),
      address: cleanAddr.isNotEmpty ? cleanAddr : '주소 정보 없음',
      region: (json['region'] ?? '').toString().trim(),
      winType: winTypeStr,
      phone: json['shpTelno']?.toString(),
      lat: (json['shpLat'] is num) ? (json['shpLat'] as num).toDouble() : null,
      lng: (json['shpLot'] is num) ? (json['shpLot'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'wnShpRnk': rank,
        'shpNm': name,
        'shpAddr': address,
        'region': region,
        'atmtPsvYnTxt': winType,
        'shpTelno': phone,
        'shpLat': lat,
        'shpLot': lng,
      };
}
