import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App boots to the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GuangyuApp());
    await tester.pump();

    // Brand + the primary import call-to-action are visible on launch.
    expect(find.text('光屿'), findsOneWidget);
    expect(find.text('从相册导入'), findsOneWidget);
  });
}
