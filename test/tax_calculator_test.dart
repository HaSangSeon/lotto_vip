import 'package:flutter_test/flutter_test.dart';
import 'package:lotto_vip/utils/lottery_tax_calculator.dart';

void main() {
  group('LotteryTaxCalculator Tests', () {
    test('5등 (5,000원) 및 4등 (50,000원) 비과세 검증', () {
      final rank5 = LotteryTaxCalculator.calculate(5000);
      expect(rank5.isTaxFree, true);
      expect(rank5.taxAmount, 0);
      expect(rank5.netAmount, 5000);

      final rank4 = LotteryTaxCalculator.calculate(50000);
      expect(rank4.isTaxFree, true);
      expect(rank4.taxAmount, 0);
      expect(rank4.netAmount, 50000);
    });

    test('3등 200만 원 이하 비과세 검증 (2023년 개정)', () {
      final rank3 = LotteryTaxCalculator.calculate(1500000);
      expect(rank3.isTaxFree, true);
      expect(rank3.taxAmount, 0);
      expect(rank3.netAmount, 1500000);
      expect(rank3.taxDescription, contains('비과세'));
    });

    test('2등 (200만 원 초과 ~ 3억 이하) 22% 과세 검증', () {
      // 50,000,000원 당첨
      // 과세표준 = 49,999,000원
      // 세금 = 49,999,000 * 0.22 = 10,999,780원
      // 실수령액 = 50,000,000 - 10,999,780 = 39,000,220원
      final rank2 = LotteryTaxCalculator.calculate(50000000);
      expect(rank2.isTaxFree, false);
      expect(rank2.taxAmount, 10999780);
      expect(rank2.netAmount, 39000220);
      expect(rank2.taxDescription, '세금 22% 공제');
    });

    test('1등 (3억 원 초과) 누진세율 검증 (3억 이하 22% + 초과 33%)', () {
      // 3,000,000,000원 (30억) 당첨
      // 3억 이하 세금 = 299,999,000 * 0.22 = 65,999,780원
      // 3억 초과 세금 = 2,700,000,000 * 0.33 = 891,000,000원
      // 총 세금 = 956,999,780원
      // 실수령액 = 3,000,000,000 - 956,999,780 = 2,043,000,220원
      final rank1 = LotteryTaxCalculator.calculate(3000000000);
      expect(rank1.isTaxFree, false);
      expect(rank1.taxAmount, 956999780);
      expect(rank1.netAmount, 2043000220);
      expect(rank1.taxDescription, '세금 약 33% 공제');
    });
  });
}
