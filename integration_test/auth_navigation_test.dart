import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:team_teleprompter/firebase_options.dart';
import 'package:team_teleprompter/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });
  setUp(() async {
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('auth flow smoke: login to signup and back', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Team Teleprompter'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);

    final signUpFinder = find.text('Sign Up').last;
    await tester.tap(signUpFinder);
    await tester.pump(const Duration(seconds: 1));

    expect(find.widgetWithText(FilledButton, 'Create Account'), findsOneWidget);

    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Team Teleprompter'), findsOneWidget);
  });
}
