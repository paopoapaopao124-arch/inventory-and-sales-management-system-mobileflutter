
import 'package:flutter_test/flutter_test.dart';
import 'package:dark_system/main.dart';

void main() {
  testWidgets('StockSmart app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const StockSmartApp());

    expect(find.byType(StockSmartApp), findsOneWidget);
  });
}
