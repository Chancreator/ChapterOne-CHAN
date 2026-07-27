import 'package:flutter_test/flutter_test.dart';
import 'package:chapterone/main.dart';

void main() {
  testWidgets('ChapterOne app builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ChapterOneApp());
    // The bookshelf home screen should show the app title in the AppBar.
    expect(find.text('ChapterOne'), findsOneWidget);
  });
}
