// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:file_tidy_app/app/app_shell.dart';

void main() {
  testWidgets('Bootstraps splash', (WidgetTester tester) async {
    await tester.pumpWidget(const AppShell());
    expect(find.text('File Tidy Assistant'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 901));
    await tester.pumpAndSettle();
    expect(find.text('Sort out your files. Keep your memories close.'), findsOneWidget);
  });
}
