import 'dart:math';

class QRLotteryGame {
  final String label; // A, B, C, D, E
  final List<int> numbers; // 6 numbers

  const QRLotteryGame({
    required this.label,
    required this.numbers,
  });
}

enum QRErrorType {
  invalidFormat, // 로또 6/45 형식이 아님
  invalidNumbers, // 번호 범위(1~45) 또는 개수 불일치
  invalidDrawNo, // 유효하지 않은 회차 (예: 음수 또는 너무 먼 미래)
  pensionLottery, // 연금복권 등 다른 복권
}

class QRLotteryData {
  final int drwNo;
  final List<QRLotteryGame> games;
  final String rawUrl;

  const QRLotteryData({
    required this.drwNo,
    required this.games,
    required this.rawUrl,
  });

  /// 해당 회차의 추첨 예정일 계산 (1회차: 2002-12-07 토요일 기준)
  DateTime get drawDate {
    final firstDraw = DateTime(2002, 12, 7);
    return firstDraw.add(Duration(days: (drwNo - 1) * 7));
  }

  /// 현재 시간 기준으로 추첨이 완료되었는지 여부 (추첨일 오후 8시 45분 기준)
  bool get isDrawnTimePassed {
    final drawTime = DateTime(
      drawDate.year,
      drawDate.month,
      drawDate.day,
      20,
      45,
    );
    return DateTime.now().isAfter(drawTime);
  }
}

class QRLotteryParseResult {
  final QRLotteryData? data;
  final QRErrorType? errorType;
  final String? errorMessage;

  const QRLotteryParseResult.success(this.data)
      : errorType = null,
        errorMessage = null;

  const QRLotteryParseResult.failure(this.errorType, this.errorMessage)
      : data = null;

  bool get isSuccess => data != null;
}

class QRLotteryParser {
  /// 현재 시점 기준 예상 최신 회차 번호 계산 (기기 시간 오차 방어 포함)
  static int calculateMaxPossibleDrawNo() {
    final firstDraw = DateTime(2002, 12, 7, 21, 0, 0);
    final diff = DateTime.now().difference(firstDraw);
    final currentDraw = (diff.inDays / 7).floor() + 1;
    // 기기 시스템 시간이 잘못 설정된 경우에도 정상 복권이 거부되지 않도록 최소 기준선 및 여유분 확보
    return max(currentDraw + 5, 1300);
  }

  /// 동행복권 QR URL 또는 v 파라미터를 정밀하게 파싱하고 유효성을 검증합니다.
  static QRLotteryParseResult parseDetailed(String input) {
    try {
      String rawInput = input.trim();
      if (rawInput.isEmpty) {
        return const QRLotteryParseResult.failure(
          QRErrorType.invalidFormat,
          'QR 코드 데이터가 비어 있습니다.',
        );
      }

      // URL 인코딩이 포함된 경우 안전하게 디코딩
      try {
        if (rawInput.contains('%')) {
          rawInput = Uri.decodeFull(rawInput).trim();
        }
      } catch (_) {}

      final lowerInput = rawInput.toLowerCase();

      // 연금복권 전용 URL 경로/식별자인 경우 감지
      // (주의: 로또 번호 조합 '07','20'이나 일련번호에 '720'이 포함될 수 있으므로 단순 '720' 문자열 포함 검사는 절대 금지)
      if (lowerInput.contains('pension') ||
          lowerInput.contains('pr.do') ||
          lowerInput.contains('lp720') ||
          lowerInput.contains('win720')) {
        return const QRLotteryParseResult.failure(
          QRErrorType.pensionLottery,
          '연금복권 QR 코드입니다. 로또 6/45 용지의 QR 코드를 스캔해 주세요.',
        );
      }

      String rawV = '';
      final vParamMatch = RegExp(r'[?&]v=([^&\s#]+)', caseSensitive: false).firstMatch(rawInput);
      if (vParamMatch != null) {
        rawV = vParamMatch.group(1) ?? '';
      } else if (lowerInput.contains('v=')) {
        final vIndex = lowerInput.indexOf('v=');
        rawV = rawInput.substring(vIndex + 2).split(RegExp(r'[&\s#]')).first;
      } else {
        // URL 없이 v 값만 입력했거나 전체 문자열 속에 포함된 경우
        final directMatch = RegExp(r'(\d{3,5}[qmsQMS][0-9qmsnQMSN]+)').firstMatch(rawInput);
        if (directMatch != null) {
          rawV = directMatch.group(1)!;
        } else {
          rawV = rawInput.split(RegExp(r'\s+')).first;
        }
      }

      rawV = rawV.trim();

      // 회차 번호 추출 (앞부분 3~5자리 숫자 + 영문 구분자)
      final drwMatch = RegExp(r'^(\d{3,5})(?=[a-zA-Z])').firstMatch(rawV) ??
          RegExp(r'^(\d{3,5})').firstMatch(rawV);
      if (drwMatch == null) {
        return const QRLotteryParseResult.failure(
          QRErrorType.invalidFormat,
          '로또 6/45 QR 코드 형식이 아닙니다.\n용지 우측 상단의 QR 코드를 확인해 주세요.',
        );
      }

      final drwNo = int.tryParse(drwMatch.group(1)!);
      if (drwNo == null || drwNo < 1) {
        return const QRLotteryParseResult.failure(
          QRErrorType.invalidDrawNo,
          '유효하지 않은 회차 정보입니다.',
        );
      }

      final maxDraw = calculateMaxPossibleDrawNo();
      if (drwNo > maxDraw) {
        return QRLotteryParseResult.failure(
          QRErrorType.invalidDrawNo,
          '회차 번호($drwNo회)가 유효 범위를 벗어났습니다.\n로또 6/45 QR 코드인지 확인해 주세요.',
        );
      }

      final rest = rawV.substring(drwMatch.group(1)!.length);
      final List<QRLotteryGame> games = [];
      const labels = ['A', 'B', 'C', 'D', 'E'];

      // q(자동), m(수동), s(반자동), n(빈게임) 또는 기타 영문자로 구분된 게임 토큰 분리
      final gameTokens = rest
          .split(RegExp(r'[a-zA-Z]+'))
          .where((s) => s.isNotEmpty)
          .toList();

      if (gameTokens.isEmpty) {
        return const QRLotteryParseResult.failure(
          QRErrorType.invalidFormat,
          '로또 게임 번호 정보를 찾을 수 없습니다.',
        );
      }

      for (int i = 0; i < gameTokens.length; i++) {
        // 로또 6/45 용지는 한 장당 최대 5게임(A~E)까지만 존재
        if (games.length >= 5) break;

        final token = gameTokens[i];
        if (token.length < 12) continue;

        final numPart = token.substring(0, 12);
        // 빈 슬롯(000000000000)은 건너뜀
        if (numPart == '000000000000') continue;

        final List<int> nums = [];
        bool valid = true;

        for (int j = 0; j < 12; j += 2) {
          final n = int.tryParse(numPart.substring(j, j + 2));
          if (n == null || n < 1 || n > 45 || nums.contains(n)) {
            valid = false;
            break;
          }
          nums.add(n);
        }

        if (valid && nums.length == 6) {
          nums.sort();
          final label = games.length < labels.length
              ? labels[games.length]
              : '${games.length + 1}';
          games.add(QRLotteryGame(label: label, numbers: nums));
        }
      }

      if (games.isEmpty) {
        // 만약 v= 파라미터는 있었지만 유효한 1~45 번호 6개가 하나도 없다면 연금복권 등 타 복권일 가능성 안내
        return const QRLotteryParseResult.failure(
          QRErrorType.invalidNumbers,
          '로또 6/45 번호(1~45)를 추출할 수 없습니다.\n연금복권이 아닌 로또 6/45 용지의 QR 코드인지 확인해 주세요.',
        );
      }

      // 공식 웹 연결을 위한 정규화된 URL 보장
      final normalizedUrl = (rawInput.startsWith('http://') || rawInput.startsWith('https://'))
          ? rawInput
          : 'https://m.dhlottery.co.kr/qr.do?method=winQr&v=$rawV';

      return QRLotteryParseResult.success(
        QRLotteryData(
          drwNo: drwNo,
          games: games,
          rawUrl: normalizedUrl,
        ),
      );
    } catch (e) {
      return const QRLotteryParseResult.failure(
        QRErrorType.invalidFormat,
        'QR 코드 분석 중 오류가 발생했습니다.\n다시 스캔해 주세요.',
      );
    }
  }

  /// 간단 파싱 (하위 호환)
  static QRLotteryData? parse(String input) {
    final res = parseDetailed(input);
    return res.data;
  }
}
