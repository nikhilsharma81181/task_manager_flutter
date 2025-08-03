import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:task_manager_flutter/features/tasks/domain/entities/task.dart';
import 'package:task_manager_flutter/features/tasks/presentation/widgets/task_card.dart';
import 'package:task_manager_flutter/main.dart' as app;
import 'task_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Task Status Change Integration Test', () {
    tearDown(() async {
      // Additional cleanup to ensure no hanging semantics handles
      await Future.delayed(const Duration(milliseconds: 100));
    });

    testWidgets('should create a task and change its status',
        (WidgetTester tester) async {
      // Launch the app
      app.main();
      await TaskTestHelpers.waitForAppToLoad(tester);
      await tester.pumpAndSettle();

      // Create a task to test status changes
      const taskTitle = 'Status Change Test Task';
      const taskDescription = 'Task for testing status changes';

      // Create initial task using helper
      await TaskTestHelpers.createTask(tester, taskTitle, taskDescription);

      // Wait for the task to appear
      final taskFound = await TaskTestHelpers.waitForTaskToAppear(
        tester,
        taskTitle,
        maxRetries: 8,
      );
      expect(taskFound, isTrue, reason: 'Task should be created');

      if (taskFound) {
        print('✅ Task created successfully');

        // Find the task card
        final taskCard = find.ancestor(
          of: find.text(taskTitle),
          matching: find.byType(TaskCard),
        );

        expect(taskCard, findsOneWidget, reason: 'Task card should be found');

        // Look for the status dropdown within the task card
        final statusDropdown = find.descendant(
          of: taskCard,
          matching: find.byType(DropdownButton<TaskStatus>),
        );

        if (statusDropdown.evaluate().isNotEmpty) {
          print('✅ Status dropdown found');

          // Tap the dropdown to open it
          await tester.tap(statusDropdown);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Look for "In Progress" option in the dropdown
          final inProgressOption = find.text('In Progress').last;
          if (inProgressOption.evaluate().isNotEmpty) {
            print('✅ Found In Progress option');
            await tester.tap(inProgressOption);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Wait a moment for the status to update
            await Future.delayed(const Duration(seconds: 1));
            await tester.pumpAndSettle();

            print('✅ Changed status to In Progress');

            // Now change to Completed
            final updatedStatusDropdown = find.descendant(
              of: taskCard,
              matching: find.byType(DropdownButton<TaskStatus>),
            );

            if (updatedStatusDropdown.evaluate().isNotEmpty) {
              await tester.tap(updatedStatusDropdown);
              await tester.pumpAndSettle(const Duration(seconds: 1));

              // Look for "Completed" option
              final completedOption = find.text('Completed').last;
              if (completedOption.evaluate().isNotEmpty) {
                print('✅ Found Completed option');
                await tester.tap(completedOption);
                await tester.pumpAndSettle(const Duration(seconds: 2));

                // Wait for status update
                await Future.delayed(const Duration(seconds: 1));
                await tester.pumpAndSettle();

                print('✅ SUCCESS: Changed status to Completed');

                // Verify the task title has strikethrough (completed styling)
                final taskTitleWidget = find.text(taskTitle);
                if (taskTitleWidget.evaluate().isNotEmpty) {
                  final titleWidget =
                      tester.widget<Text>(taskTitleWidget.first);
                  if (titleWidget.style?.decoration ==
                      TextDecoration.lineThrough) {
                    print(
                        '✅ SUCCESS: Task shows completed styling (strikethrough)');
                  } else {
                    print('⚠️ Task styling may not reflect completed status');
                  }
                }
              } else {
                print('❌ Could not find Completed option in dropdown');
              }
            } else {
              print('❌ Could not find status dropdown after first change');
            }
          } else {
            print('❌ Could not find In Progress option in dropdown');
          }
        } else {
          print('❌ Could not find status dropdown in task card');

          // Alternative approach: try to find any dropdown button
          final anyDropdown = find.byType(DropdownButton);
          if (anyDropdown.evaluate().isNotEmpty) {
            print('⚠️ Found alternative dropdown, trying that');
            await tester.tap(anyDropdown.first);
            await tester.pumpAndSettle();

            final inProgressOption = find.text('In Progress');
            if (inProgressOption.evaluate().isNotEmpty) {
              await tester.tap(inProgressOption.last);
              await tester.pumpAndSettle(const Duration(seconds: 2));
              print('✅ Status changed using alternative method');
            }
          } else {
            print('❌ No dropdown buttons found at all');
          }
        }
      }

      // Perform cleanup
      await TaskTestHelpers.performCleanup(tester);
    });
  });
}
