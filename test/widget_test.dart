import 'package:flutter_test/flutter_test.dart';
import 'package:treasure_of_temple/app.dart';

void main() {
  testWidgets('App boots', (tester) async {
    await tester.pumpWidget(const TreasureApp());
    expect(find.byType(TreasureApp), findsOneWidget);
  });
}
