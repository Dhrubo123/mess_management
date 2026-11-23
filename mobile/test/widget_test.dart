import 'package:flutter_test/flutter_test.dart';
import 'package:mess_management/main.dart';

void main() {
  testWidgets('MessMateApp boots cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const MessMateApp());
    await tester.pump();
    expect(find.byType(MessMateApp), findsOneWidget);
  });
}
