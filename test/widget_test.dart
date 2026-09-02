import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotto_vip/widgets/lotto_ball.dart';

void main() {
  testWidgets('LottoBall rendering test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LottoBallRow(
            numbers: [7, 12, 23, 31, 40, 45],
          ),
        ),
      ),
    );

    expect(find.text('7'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
  });
}

