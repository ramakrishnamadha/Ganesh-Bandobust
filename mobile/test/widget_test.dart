import 'package:flutter_test/flutter_test.dart';
import 'package:ganesh_bandobust_mobile/main.dart';

void main() {
  testWidgets('Ganesh Bandobust app starts successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GaneshBandobustApp());

    expect(find.text('GANESH FESTIVAL'), findsOneWidget);
    expect(find.text('Official Login'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}