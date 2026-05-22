import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:team_teleprompter/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('auth flow smoke: login to signup and back', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Team Teleprompter'), findsOneWidget);

    final signUpFinder = find.text('Sign Up').last;
    await tester.ensureVisible(signUpFinder);
    await tester.pumpAndSettle();
    await tester.tap(signUpFinder);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Create Account'), findsOneWidget);

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Team Teleprompter'), findsOneWidget);
  });
}
