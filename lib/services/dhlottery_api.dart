import 'dart:convert';
import 'package:http/http.dart' as http;

class DHLotteryResult {
  final int drwNo;
  final String drwNoDate;
  final List<int> numbers;
  final int bonusNo;
  final int firstWinamnt;     // 1등 1인당 당첨금
  final int firstWinCount;    // 1등 당첨자 수
  final int firstSumWinamnt;  // 1등 총 당첨금

  DHLotteryResult({
    required this.drwNo,
    required this.drwNoDate,
    required this.numbers,
    required this.bonusNo,
    required this.firstWinamnt,
    required this.firstWinCount,
    required this.firstSumWinamnt,
  });

  /// 1등 당첨자가 없으면 이월
  bool get isRollover => firstWinCount == 0;

  factory DHLotteryResult.fromJson(Map<String, dynamic> json) {
    // 날짜 형식 변환: 20231230 -> 2023-12-30
    String rawDate = json['ltRflYmd']?.toString() ?? '';
    if (rawDate.length == 8) {
      rawDate = '${rawDate.substring(0, 4)}-${rawDate.substring(4, 6)}-${rawDate.substring(6, 8)}';
    }

    return DHLotteryResult(
      drwNo: json['ltEpsd'],
      drwNoDate: rawDate,
      numbers: [
        json['tm1WnNo'],
        json['tm2WnNo'],
        json['tm3WnNo'],
        json['tm4WnNo'],
        json['tm5WnNo'],
        json['tm6WnNo'],
      ],
      bonusNo: json['bnsWnNo'],
      firstWinamnt: json['rnk1WnAmt'] ?? 0,
      firstWinCount: json['rnk1WnNope'] ?? 0,
      firstSumWinamnt: json['rnk1SumWnAmt'] ?? 0,
    );
  }
}

class DHLotteryApi {
  static const String _baseUrl =
      'https://www.dhlottery.co.kr/lt645/selectPstLt645Info.do?srchLtEpsd=';

  static DHLotteryResult? _lastSuccessfulResult;

  /// 오늘 날짜 기준으로 대략적인 최신 회차를 계산
  static int _calculateLatestDrawNo() {
    final firstDraw = DateTime(2002, 12, 7, 21, 0, 0); // 1회차 추첨일
    final now = DateTime.now();
    final diff = now.difference(firstDraw);
    return (diff.inDays / 7).floor() + 1;
  }

  /// 최신 당첨 번호 가져오기
  static Future<DHLotteryResult?> fetchLatest() async {
    int guessNo = _calculateLatestDrawNo();

    // 최신 회차부터 최대 3회차 이전까지 시도
    for (int i = 0; i < 3; i++) {
      final res = await _fetchByDrawNo(guessNo - i);
      if (res != null) {
        _lastSuccessfulResult = res;
        return res;
      }
    }
    
    // 실패 시 캐시된 결과 반환
    return _lastSuccessfulResult;
  }

  static Future<DHLotteryResult?> _fetchByDrawNo(int drwNo) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl$drwNo'))
          .timeout(const Duration(seconds: 3));
          
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic>? list = body['data']?['list'];
        if (list != null && list.isNotEmpty) {
          return DHLotteryResult.fromJson(list[0]);
        }
      }
    } catch (_) {}
    return null;
  }
}
