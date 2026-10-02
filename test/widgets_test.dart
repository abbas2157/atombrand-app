import 'package:atombrand_app/widgets/code_input.dart';
import 'package:atombrand_app/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('Varification is displayed as Verification', (tester) async {
    await tester.pumpWidget(_wrap(StatusBadge.order('Varification')));
    expect(find.text('Verification'), findsOneWidget);
    expect(find.text('Varification'), findsNothing);
  });

  test('badge labels and tones match the web portal', () {
    expect(StatusBadge.product('Published').label, 'Live');
    expect(StatusBadge.product('Published').tone, BadgeTone.success);
    expect(StatusBadge.product('Pending').label, 'In review');
    expect(StatusBadge.product('Out of Stock').tone, BadgeTone.danger);
    expect(StatusBadge.order('Completed').tone, BadgeTone.success);
    expect(StatusBadge.order('Cancelled').tone, BadgeTone.danger);
    expect(StatusBadge.order('Pending').tone, BadgeTone.neutral);
    expect(StatusBadge.bulk('New Lead').tone, BadgeTone.warning);
    expect(StatusBadge.bulk('Quoted').tone, BadgeTone.info);
    expect(StatusBadge.payment(isCash: true, tenure: 1).label, 'Paid in full');
    expect(StatusBadge.payment(isCash: false, tenure: 6).label, '6-month plan');
  });

  testWidgets('CodeInput completes after six digits', (tester) async {
    String? code;
    await tester.pumpWidget(_wrap(SizedBox(width: 360, child: CodeInput(onCompleted: (c) => code = c))));
    await tester.enterText(find.byType(TextField), '12ab3456');
    await tester.pump();
    expect(code, '123456');
    expect(find.text('6'), findsOneWidget);
  });
}
