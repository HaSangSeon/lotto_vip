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
  /// 현재 시점 기준 예상 최신 회차 번호 계산
  static int calculateMaxPossibleDrawNo() {
    final firstDraw = DateTime(2002, 12, 7, 21, 0, 0);
    final diff = DateTime.now().difference(firstDraw);
    final currentDraw = (diff.inDays / 7).floor() + 1;
    return currentDraw + 2; // 최대 2회차 미래까지 구매 가능 여유
  }

  /// 동행복권 QR URL 또는 v 파라미터를 정밀하게 파싱하고 유효성을 검증합니다.
  static QRLotteryParseResult parseDetailed(String input) {
    try {
      final rawInput = input.trim();
      if (rawInput.isEmpty) {
        return const QRLotteryParseResult.failure(
          QRErrorType.invalidFormat,
          'QR 코드 데이터가 비어 있습니다.',
        );
      }

      // 연금복권 등 다른 복권인 경우 감지 (예: 720+, 520 등)
      if (rawInput.contains('720') || rawInput.contains('pension') || rawInput.contains('pr.do')) {
        return const QRLotteryParseResult.failure(
          QRErrorType.pensionLottery,
          '연금복권 QR 코드입니다. 로또 6/45 용지의 QR 코드를 스캔해 주세요.',
        );
      }

      String rawV = '';
      if (rawInput.contains('v=')) {
        final uri = Uri.tryParse(rawInput);
        if (uri != null && uri.queryParameters.containsKey('v')) {
          rawV = uri.queryParameters['v'] ?? '';
        } else {
          final vIndex = rawInput.indexOf('v=');
          rawV = rawInput.substring(vIndex + 2).split('&').first;
        }
      } else {
        rawV = rawInput;
      }

      rawV = rawV.trim();

      // 회차 번호 추출 (앞부분 3~5자리 숫자)
      final drwMatch = RegExp(r'^(\d{3,5})').firstMatch(rawV);
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
          '회차 번호($drwNo회)가 현재 진행 중인 회차보다 너무 큽니다.',
        );
      }

      final rest = rawV.substring(drwMatch.group(1)!.length);
      final List<QRLotteryGame> games = [];
      final labels = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

      // q 또는 기타 영문자로 구분된 게임 토큰 분리
      final gameTokens = rest.split(RegExp(r'[a-zA-Z]')).where((s) => s.isNotEmpty).toList();

      if (gameTokens.isEmpty) {
        return const QRLotteryParseResult.failure(
          QRErrorType.invalidFormat,
          '로또 게임 번호 정보를 찾을 수 없습니다.',
        );
      }

      for (int i = 0; i < gameTokens.length; i++) {
        final token = gameTokens[i];
        if (token.length < 12) continue;

        final numPart = token.substring(0, 12);
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
          final label = i < labels.length ? labels[i] : '${i + 1}';
          games.add(QRLotteryGame(label: label, numbers: nums));
        }
      }

      if (games.isEmpty) {
        return const QRLotteryParseResult.failure(
          QRErrorType.invalidNumbers,
          '올바른 6개 번호 조합을 추출할 수 없습니다.',
        );
      }

      return QRLotteryParseResult.success(
        QRLotteryData(
          drwNo: drwNo,
          games: games,
          rawUrl: rawInput,
        ),
      );
    } catch (e) {
      return QRLotteryParseResult.failure(
        QRErrorType.invalidFormat,
        'QR 코드 분석 중 알 수 없는 오류가 발생했습니다.',
      );
    }
  }

  /// 간단 파싱 (하위 호환)
  static QRLotteryData? parse(String input) {
    final res = parseDetailed(input);
    return res.data;
  }
}
