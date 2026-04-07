import 'package:bluetooth_rc_car/core/constants/app_constants.dart';
import 'package:bluetooth_rc_car/presentation/screens/app_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows splash before revealing the home screen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppSplashScreen(
          child: Scaffold(
            body: Center(
              child: Text('Home Ready'),
            ),
          ),
        ),
      ),
    );

    expect(find.text(AppConstants.appTitle), findsOneWidget);
    expect(find.text('Home Ready'), findsNothing);

    await tester.pump(AppConstants.splashDuration);
    await tester.pumpAndSettle();

    expect(find.text('Home Ready'), findsOneWidget);
  });
}
