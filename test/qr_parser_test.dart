import 'package:flutter_test/flutter_test.dart';
import 'package:lotto_vip/services/qr_lottery_parser.dart';

void main() {
  group('QRLotteryParser 정밀 검증 및 예외 처리 테스트', () {
    test('1. 동행복권 표준 5게임 QR URL 정상 파싱', () {
      const url = 'http://m.dhlottery.co.kr/qr.do?method=winQr&v=1100q010203040506q070809101112q131415161718q192021222324q2526272829301234567890';
      final res = QRLotteryParser.parseDetailed(url);

      expect(res.isSuccess, isTrue);
      final data = res.data!;
      expect(data.drwNo, equals(1100));
      expect(data.games.length, equals(5));
      expect(data.games[0].label, equals('A'));
      expect(data.games[0].numbers, equals([1, 2, 3, 4, 5, 6]));
      expect(data.games[4].label, equals('E'));
      expect(data.games[4].numbers, equals([25, 26, 27, 28, 29, 30]));
    });

    test('2. 연금복권 QR 코드 감지 시 친절한 예외 반환', () {
      const pensionUrl = 'http://m.dhlottery.co.kr/pr.do?method=winQr&v=720p123456';
      final res = QRLotteryParser.parseDetailed(pensionUrl);

      expect(res.isSuccess, isFalse);
      expect(res.errorType, equals(QRErrorType.pensionLottery));
      expect(res.errorMessage, contains('연금복권'));
    });

    test('3. 로또 형식이 아닌 일반 QR 코드 예외 처리', () {
      const invalidUrl = 'https://www.google.com';
      final res = QRLotteryParser.parseDetailed(invalidUrl);

      expect(res.isSuccess, isFalse);
      expect(res.errorType, equals(QRErrorType.invalidFormat));
    });

    test('4. 유효하지 않은 회차 번호 (너무 먼 미래) 예외 처리', () {
      const futureUrl = 'http://m.dhlottery.co.kr/qr.do?method=winQr&v=99999q010203040506';
      final res = QRLotteryParser.parseDetailed(futureUrl);

      expect(res.isSuccess, isFalse);
      expect(res.errorType, equals(QRErrorType.invalidDrawNo));
    });

    test('5. 1~45 범위 밖의 이상한 번호 포함 시 예외 처리', () {
      const badNumUrl = 'http://m.dhlottery.co.kr/qr.do?method=winQr&v=1100q010203040599';
      final res = QRLotteryParser.parseDetailed(badNumUrl);

      expect(res.isSuccess, isFalse);
      expect(res.errorType, equals(QRErrorType.invalidNumbers));
    });

    test('6. 회차 추첨일 계산 및 추첨 여부 확인', () {
      const url = 'http://m.dhlottery.co.kr/qr.do?method=winQr&v=1100q010203040506';
      final data = QRLotteryParser.parse(url)!;

      expect(data.drawDate, isNotNull);
      // 1100회는 이미 과거 회차이므로 isDrawnTimePassed는 true
      expect(data.isDrawnTimePassed, isTrue);
    });
  });
}
