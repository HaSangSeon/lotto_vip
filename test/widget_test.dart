import 'package:flutter_test/flutter_test.dart';
import 'package:lotto_vip/main.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    await tester.pumpWidget(const LottoVipApp());
    expect(find.text('로또 신통'), findsOneWidget);
  });
}
