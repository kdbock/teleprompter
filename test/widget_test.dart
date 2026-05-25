import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_teleprompter/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Team Teleprompter'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });

  testWidgets('login layout handles narrow viewport without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(640, 960);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final exception = tester.takeException();
    expect(exception, isNull);

    expect(find.byType(Scaffold), findsWidgets);
  });
}
