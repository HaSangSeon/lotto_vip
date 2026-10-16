/// 대한민국 복권 당첨금 소득세 및 실수령액 계산기
/// 소득세법 제84조 (2023년 1월 1일 개정 시행 기준)
/// - 200만 원 이하: 전액 비과세 (세율 0%)
/// - 200만 원 초과 ~ 3억 원 이하: 기타소득세 20% + 지방소득세 2% = 총 22% 원천징수
/// - 3억 원 초과: 3억 원까지 22% + 3억 원 초과분 33% (소득세 30% + 지방소득세 3%)
class LotteryTaxResult {
  final int originalAmount; // 세전 당첨금
  final int taxAmount; // 원천징수 세금 합계
  final int netAmount; // 세후 실수령액
  final double effectiveTaxRate; // 실효 세율 (%)
  final String taxDescription; // 예: '비과세 (세금 0원)', '세금 22% 공제', '세금 33% 공제'
  final bool isTaxFree; // 비과세 여부

  const LotteryTaxResult({
    required this.originalAmount,
    required this.taxAmount,
    required this.netAmount,
    required this.effectiveTaxRate,
    required this.taxDescription,
    required this.isTaxFree,
  });
}

class LotteryTaxCalculator {
  /// 로또복권 1게임 구매 비용 (필요경비 공제)
  static const int ticketCost = 1000;

  /// 복권 당첨금 실수령액 계산 함수
  static LotteryTaxResult calculate(int amount) {
    if (amount <= 0) {
      return const LotteryTaxResult(
        originalAmount: 0,
        taxAmount: 0,
        netAmount: 0,
        effectiveTaxRate: 0.0,
        taxDescription: '비과세',
        isTaxFree: true,
      );
    }

    // 1. 200만 원 이하 비과세 (4등, 5등 및 200만원 이하 3등)
    if (amount <= 2000000) {
      return LotteryTaxResult(
        originalAmount: amount,
        taxAmount: 0,
        netAmount: amount,
        effectiveTaxRate: 0.0,
        taxDescription: '비과세 (세금 0원)',
        isTaxFree: true,
      );
    }

    // 과세 표준 = 당첨금 - 복권 구입비용 (1,000원)
    final taxableBase = (amount > ticketCost) ? (amount - ticketCost) : amount;

    // 2. 200만 원 초과 ~ 3억 원 이하 (22% 세율 적용)
    if (amount <= 300000000) {
      final tax = (taxableBase * 0.22).floor();
      final net = amount - tax;
      final rate = amount > 0 ? (tax / amount * 100) : 22.0;

      return LotteryTaxResult(
        originalAmount: amount,
        taxAmount: tax,
        netAmount: net,
        effectiveTaxRate: double.parse(rate.toStringAsFixed(1)),
        taxDescription: '세금 22% 공제',
        isTaxFree: false,
      );
    }

    // 3. 3억 원 초과 (3억까지 22% + 3억 초과분 33% 누진 세율 적용)
    final baseUpTo300M = 300000000 - ticketCost;
    final taxUpTo300M = (baseUpTo300M * 0.22).floor(); // 65,999,780원

    final baseOver300M = amount - 300000000;
    final taxOver300M = (baseOver300M * 0.33).floor();

    final totalTax = taxUpTo300M + taxOver300M;
    final net = amount - totalTax;
    final rate = amount > 0 ? (totalTax / amount * 100) : 33.0;

    return LotteryTaxResult(
      originalAmount: amount,
      taxAmount: totalTax,
      netAmount: net,
      effectiveTaxRate: double.parse(rate.toStringAsFixed(1)),
      taxDescription: '세금 약 33% 공제',
      isTaxFree: false,
    );
  }
}
