import 'package:flutter_test/flutter_test.dart';
import 'package:lotto_vip/services/history_service.dart';

void main() {
  group('LottoHistoryEntry 묶음 티켓 및 하위 호환성 테스트', () {
    test('1. 단일 생성 번호 (구형 포맷) 하위 호환 직렬화/역직렬화', () {
      final oldJson = {
        'title': '오늘의 VIP 번호',
        'numbers': [3, 11, 15, 22, 35, 44],
        'createdAt': '2026-09-01T12:00:00.000',
        'isFavorite': true,
      };

      final entry = LottoHistoryEntry.fromJson(oldJson);
      expect(entry.isTicket, isFalse);
      expect(entry.gameCount, equals(1));
      expect(entry.entryType, equals(LottoEntryType.vipLucky));
      expect(entry.numbers, equals([3, 11, 15, 22, 35, 44]));
      expect(entry.games, isNull);
      expect(entry.isFavorite, isTrue);
    });

    test('2. 묶음 실물 복권 (5게임) 신규 포맷 직렬화 및 역직렬화', () {
      final ticket = LottoHistoryEntry(
        title: '[QR스캔] 제1158회 실물 복권 (5게임)',
        numbers: [1, 2, 3, 4, 5, 6],
        games: [
          const SavedLotteryGame(label: 'A', numbers: [1, 2, 3, 4, 5, 6]),
          const SavedLotteryGame(label: 'B', numbers: [7, 8, 9, 10, 11, 12]),
          const SavedLotteryGame(label: 'C', numbers: [13, 14, 15, 16, 17, 18]),
          const SavedLotteryGame(label: 'D', numbers: [19, 20, 21, 22, 23, 24]),
          const SavedLotteryGame(label: 'E', numbers: [25, 26, 27, 28, 29, 30]),
        ],
        createdAt: DateTime.parse('2026-09-02T14:00:00.000'),
      );

      expect(ticket.isTicket, isTrue);
      expect(ticket.gameCount, equals(5));
      expect(ticket.entryType, equals(LottoEntryType.qrScan));
      expect(ticket.drawNo, equals(1158));

      final json = ticket.toJson();
      expect(json['games'], isNotNull);
      expect((json['games'] as List).length, equals(5));

      final restored = LottoHistoryEntry.fromJson(json);
      expect(restored.isTicket, isTrue);
      expect(restored.gameCount, equals(5));
      expect(restored.games![0].label, equals('A'));
      expect(restored.games![0].numbers, equals([1, 2, 3, 4, 5, 6]));
      expect(restored.games![4].label, equals('E'));
      expect(restored.games![4].numbers, equals([25, 26, 27, 28, 29, 30]));
    });
  });
}
