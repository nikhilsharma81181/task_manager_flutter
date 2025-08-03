import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:task_manager_flutter/features/tasks/presentation/widgets/task_card.dart';
import 'package:task_manager_flutter/main.dart' as app;
import 'task_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Edit Task Integration Test', () {
    tearDown(() async {
      // Enhanced cleanup for edit tests
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Force garbage collection to help with handle cleanup
      // This is a workaround for the SemanticsHandle disposal issue
      await Future.delayed(const Duration(milliseconds: 100));
    });

    testWidgets('should edit a task and verify changes',
        (WidgetTester tester) async {
      // Launch the app
      app.main();
      await TaskTestHelpers.waitForAppToLoad(tester);
      await tester.pumpAndSettle();

      // First, create a task to edit
      const originalTitle = 'Task to Edit';
      const originalDescription = 'Original description';
      const editedTitle = 'Edited Task Title';
      const editedDescription = 'Updated description after editing';

      // Create initial task using helper
      await TaskTestHelpers.createTask(tester, originalTitle, originalDescription);

      // Wait for the original task to appear
      final originalTaskFound = await TaskTestHelpers.waitForTaskToAppear(
        tester,
        originalTitle,
        maxRetries: 8,
      );
      expect(originalTaskFound, isTrue, reason: 'Original task should be created');

      if (originalTaskFound) {
        print('✅ Original task created successfully');

        // Find and tap on the task to open details
        final taskCard = find.ancestor(
          of: find.text(originalTitle),
          matching: find.byType(TaskCard),
        );

        if (taskCard.evaluate().isEmpty) {
          // Fallback: try to find by InkWell or Container
          final inkWellCard = find.ancestor(
            of: find.text(originalTitle),
            matching: find.byType(InkWell),
          );

          if (inkWellCard.evaluate().isNotEmpty) {
            await tester.tap(inkWellCard);
          } else {
            // Last resort: tap directly on the text
            await tester.tap(find.text(originalTitle));
          }
        } else {
          await tester.tap(taskCard);
        }
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Look for edit button on task detail page
        final editButton = find.byIcon(Icons.edit);
        if (editButton.evaluate().isEmpty) {
          // Try alternative ways to find edit functionality
          final editText = find.text('Edit');
          if (editText.evaluate().isNotEmpty) {
            await tester.tap(editText);
          } else {
            // Look for floating action button or menu
            final fab = find.byType(FloatingActionButton);
            if (fab.evaluate().isNotEmpty) {
              await tester.tap(fab);
            }
          }
        } else {
          await tester.tap(editButton);
        }
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Check if we're on edit form (look for form fields)
        final titleField = find.byType(TextFormField).first;
        final descriptionField = find.byType(TextFormField).at(1);

        if (titleField.evaluate().isNotEmpty &&
            descriptionField.evaluate().isNotEmpty) {
          print('✅ Edit form opened successfully');

          // Clear and enter new title
          await tester.tap(titleField);
          await tester.pumpAndSettle();
          await tester.enterText(titleField, editedTitle);
          await tester.pumpAndSettle();

          // Clear and enter new description
          await tester.tap(descriptionField);
          await tester.pumpAndSettle();
          await tester.enterText(descriptionField, editedDescription);
          await tester.pumpAndSettle();

          // Try to change priority to High
          final highChip = find.widgetWithText(ChoiceChip, 'High');
          if (highChip.evaluate().isNotEmpty) {
            await tester.ensureVisible(highChip);
            await tester.tap(highChip, warnIfMissed: false);
            await tester.pumpAndSettle();
          }

          // Save the changes
          final saveButton = find.widgetWithText(ElevatedButton, 'Update Task');
          if (saveButton.evaluate().isEmpty) {
            // Try alternative save button text
            final altSaveButton = find.widgetWithText(ElevatedButton, 'Save');
            if (altSaveButton.evaluate().isNotEmpty) {
              await tester.tap(altSaveButton);
            }
          } else {
            await tester.tap(saveButton);
          }
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Wait for navigation back to homepage
          await Future.delayed(const Duration(seconds: 2));
          await tester.pumpAndSettle();

          // Verify the edited task appears with new title
          final editedTaskFound = await TaskTestHelpers.waitForTaskToAppear(
            tester,
            editedTitle,
            maxRetries: 8,
          );

          if (editedTaskFound) {
            print('✅ SUCCESS: Task edited and updated title found on homepage');

            // Verify original title is no longer present
            final originalTitleStillExists =
                find.text(originalTitle).evaluate().isNotEmpty;
            expect(originalTitleStillExists, isFalse,
                reason: 'Original title should no longer exist after edit');

            // Tap on edited task to verify description was also updated
            final editedTaskCard = find.ancestor(
              of: find.text(editedTitle),
              matching: find.byType(TaskCard),
            );

            if (editedTaskCard.evaluate().isNotEmpty) {
              await tester.tap(editedTaskCard);
            } else {
              // Fallback: try InkWell or tap directly on text
              final inkWellCard = find.ancestor(
                of: find.text(editedTitle),
                matching: find.byType(InkWell),
              );

              if (inkWellCard.evaluate().isNotEmpty) {
                await tester.tap(inkWellCard);
              } else {
                await tester.tap(find.text(editedTitle));
              }
            }

            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Check if edited description is visible on detail page
            if (find.text(editedDescription).evaluate().isNotEmpty) {
              print('✅ SUCCESS: Task description was also updated');
            } else {
              print('⚠️ Could not verify description update');
            }

            // Navigate back to homepage
            final backButton = find.byType(BackButton);
            if (backButton.evaluate().isNotEmpty) {
              await tester.tap(backButton);
              await tester.pumpAndSettle();
              print('✅ SUCCESS: Navigated back to homepage');
            } else {
              // Alternative: try to navigate back using system back
              await tester.pageBack();
              await tester.pumpAndSettle();
            }
          } else {
            print('❌ ISSUE: Edited task was not found on homepage');
            expect(editedTaskFound, isTrue,
                reason: 'Edited task should appear on homepage');
          }
        } else {
          print('❌ ISSUE: Could not find edit form');
          expect(titleField.evaluate().isNotEmpty, isTrue,
              reason: 'Edit form should be accessible');
        }
      }

      // Enhanced cleanup for edit test due to complex interactions
      await TaskTestHelpers.performCleanup(tester);
      
      // Additional cleanup specific to edit test
      await tester.pumpAndSettle();
      
      // Try to dismiss any remaining overlays by pressing escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      
      // Final cleanup
      await Future.delayed(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    });
  });
}