import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/utils/snackbar_utils.dart';
import 'package:task_manager_flutter/core/themes/app_colors.dart';

void main() {
  group(
    'SnackbarUtils',
    () {
      late Widget testApp;
      late GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

      setUp(() {
        scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
        testApp = MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          home: const Scaffold(
            body: SizedBox.shrink(),
          ),
        );
      });

      group('showSuccess', () {
        testWidgets('should display snackbar with success styling',
            (WidgetTester tester) async {
          await tester.pumpWidget(testApp);

          final context = tester.element(find.byType(Scaffold));

          SnackbarUtils.showSuccess(context, 'Success message');
          await tester.pump();

          // Verify snackbar is displayed
          expect(find.byType(SnackBar), findsOneWidget);

          // Verify message text
          expect(find.text('Success message'), findsOneWidget);

          // Verify background color
          final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
          expect(snackbar.backgroundColor, AppColors.success);

          // Verify text styling
          final text = tester.widget<Text>(find.text('Success message'));
          expect(text.style?.color, Colors.white);
          expect(text.style?.fontWeight, FontWeight.w500);

          // Verify snackbar behavior and shape
          expect(snackbar.behavior, SnackBarBehavior.floating);
          expect(snackbar.shape, isA<RoundedRectangleBorder>());
        });

        testWidgets('should clear existing snackbars before showing new one',
            (WidgetTester tester) async {
          await tester.pumpWidget(testApp);

          final context = tester.element(find.byType(Scaffold));

          // Show first snackbar
          SnackbarUtils.showSuccess(context, 'First message');
          await tester.pump();

          expect(find.text('First message'), findsOneWidget);

          // Show second snackbar
          SnackbarUtils.showSuccess(context, 'Second message');
          await tester.pump();

          // Only the second snackbar should be visible
          expect(find.text('First message'), findsNothing);
          expect(find.text('Second message'), findsOneWidget);
        });
      });

      group('showError', () {
        testWidgets('should display snackbar with error styling',
            (WidgetTester tester) async {
          await tester.pumpWidget(testApp);

          final context = tester.element(find.byType(Scaffold));

          SnackbarUtils.showError(context, 'Error message');
          await tester.pump();

          // Verify snackbar is displayed
          expect(find.byType(SnackBar), findsOneWidget);

          // Verify message text
          expect(find.text('Error message'), findsOneWidget);

          // Verify background color
          final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
          expect(snackbar.backgroundColor, AppColors.error);

          // Verify text styling
          final text = tester.widget<Text>(find.text('Error message'));
          expect(text.style?.color, Colors.white);
          expect(text.style?.fontWeight, FontWeight.w500);
        });
      });

      group('showInfo', () {
        testWidgets('should display snackbar with info styling',
            (WidgetTester tester) async {
          await tester.pumpWidget(testApp);

          final context = tester.element(find.byType(Scaffold));

          SnackbarUtils.showInfo(context, 'Info message');
          await tester.pump();

          // Verify snackbar is displayed
          expect(find.byType(SnackBar), findsOneWidget);

          // Verify message text
          expect(find.text('Info message'), findsOneWidget);

          // Verify background color
          final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
          expect(snackbar.backgroundColor, AppColors.primary);

          // Verify text styling
          final text = tester.widget<Text>(find.text('Info message'));
          expect(text.style?.color, Colors.white);
          expect(text.style?.fontWeight, FontWeight.w500);
        });
      });

      group('showWarning', () {
        testWidgets('should display snackbar with warning styling',
            (WidgetTester tester) async {
          await tester.pumpWidget(testApp);

          final context = tester.element(find.byType(Scaffold));

          SnackbarUtils.showWarning(context, 'Warning message');
          await tester.pump();

          // Verify snackbar is displayed
          expect(find.byType(SnackBar), findsOneWidget);

          // Verify message text
          expect(find.text('Warning message'), findsOneWidget);

          // Verify background color
          final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
          expect(snackbar.backgroundColor, AppColors.warning);

          // Verify text styling
          final text = tester.widget<Text>(find.text('Warning message'));
          expect(text.style?.color, Colors.white);
          expect(text.style?.fontWeight, FontWeight.w500);
        });
      });

      group('_showSnackbar private method behavior', () {
        testWidgets('should handle custom duration',
            (WidgetTester tester) async {
          await tester.pumpWidget(testApp);

          final context = tester.element(find.byType(Scaffold));

          // Since _showSnackbar is private, we test it through public methods
          // We can verify that the default duration is used
          SnackbarUtils.showSuccess(context, 'Test message');
          await tester.pump();

          final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
          expect(snackbar.duration, const Duration(seconds: 2));
        });

        testWidgets('should have proper snackbar shape with rounded corners',
            (WidgetTester tester) async {
          await tester.pumpWidget(testApp);

          final context = tester.element(find.byType(Scaffold));

          SnackbarUtils.showSuccess(context, 'Test message');
          await tester.pump();

          final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
          expect(snackbar.shape, isA<RoundedRectangleBorder>());

          final shape = snackbar.shape as RoundedRectangleBorder;
          expect(shape.borderRadius, BorderRadius.circular(8));
        });

        testWidgets('should use floating behavior',
            (WidgetTester tester) async {
          await tester.pumpWidget(testApp);

          final context = tester.element(find.byType(Scaffold));

          SnackbarUtils.showSuccess(context, 'Test message');
          await tester.pump();

          final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
          expect(snackbar.behavior, SnackBarBehavior.floating);
        });
      });

      group('Context validation and error handling', () {
        testWidgets('should work with valid BuildContext',
            (WidgetTester tester) async {
          await tester.pumpWidget(testApp);

          final context = tester.element(find.byType(Scaffold));

          // Should not throw any exceptions
          expect(() => SnackbarUtils.showSuccess(context, 'Test'),
              returnsNormally);
          expect(
              () => SnackbarUtils.showError(context, 'Test'), returnsNormally);
          expect(
              () => SnackbarUtils.showInfo(context, 'Test'), returnsNormally);
          expect(() => SnackbarUtils.showWarning(context, 'Test'),
              returnsNormally);
        });

        testWidgets('should handle empty message gracefully',
            (WidgetTester tester) async {
          await tester.pumpWidget(testApp);

          final context = tester.element(find.byType(Scaffold));

          SnackbarUtils.showSuccess(context, '');
          await tester.pump();

          // Should still show snackbar with empty message
          expect(find.byType(SnackBar), findsOneWidget);
          expect(find.text(''), findsOneWidget);
        });

        testWidgets('should handle long messages properly',
            (WidgetTester tester) async {
          await tester.pumpWidget(testApp);

          final context = tester.element(find.byType(Scaffold));

          const longMessage =
              'This is a very long message that should be handled properly by the snackbar widget without causing any overflow or layout issues in the UI';

          SnackbarUtils.showSuccess(context, longMessage);
          await tester.pump();

          expect(find.byType(SnackBar), findsOneWidget);
          expect(find.text(longMessage), findsOneWidget);
        });
      });

      group('ScaffoldMessenger integration', () {
        testWidgets('should clear existing snackbars using ScaffoldMessenger',
            (WidgetTester tester) async {
          await tester.pumpWidget(testApp);

          final context = tester.element(find.byType(Scaffold));

          // Show multiple snackbars rapidly
          SnackbarUtils.showSuccess(context, 'Message 1');
          await tester.pump();

          SnackbarUtils.showError(context, 'Message 2');
          await tester.pump();

          SnackbarUtils.showWarning(context, 'Message 3');
          await tester.pump();

          // Only the last snackbar should be visible
          expect(find.text('Message 1'), findsNothing);
          expect(find.text('Message 2'), findsNothing);
          expect(find.text('Message 3'), findsOneWidget);
        });

        testWidgets('should properly use ScaffoldMessenger.of(context)',
            (WidgetTester tester) async {
          await tester.pumpWidget(testApp);

          final context = tester.element(find.byType(Scaffold));

          // Verify that the snackbar is shown through ScaffoldMessenger
          SnackbarUtils.showInfo(context, 'Test message');
          await tester.pump();

          // The snackbar should be present in the widget tree
          expect(find.byType(SnackBar), findsOneWidget);

          // And it should be managed by the ScaffoldMessenger
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          expect(scaffoldMessenger, isNotNull);
        });
      });
    },
  );
}
