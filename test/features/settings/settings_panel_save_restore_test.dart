import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/features/save_management/application/save_management_providers.dart';
import 'package:wuxia_idle/features/save_management/application/save_management_service.dart';
import 'package:wuxia_idle/features/save_management/domain/save_management_status.dart';
import 'package:wuxia_idle/features/save_management/domain/save_restore.dart';
import 'package:wuxia_idle/features/settings/presentation/settings_panel.dart';
import 'package:wuxia_idle/shared/app_exit.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  late void Function() originalQuit;

  setUp(() {
    originalQuit = AppExit.quit;
  });

  tearDown(() {
    AppExit.quit = originalQuit;
  });

  testWidgets('restore is disabled when there are no backups', (tester) async {
    final service = _FakeSaveManagementService(
      onRestore: (_) => throw UnimplementedError(),
    );
    await _pump(tester, service: service, backups: const []);

    await tester.tap(find.text(UiStrings.saveManagementRestore));
    await tester.pumpAndSettle();

    expect(find.text(UiStrings.saveManagementSelectBackupTitle), findsNothing);
    expect(service.restoreCalls, 0);
  });

  testWidgets('restore lists backups newest first and asks for confirmation', (
    tester,
  ) async {
    final older = _backup('wuxia_save_slot1_20260709_120000.isar', 1);
    final newer = _backup('wuxia_save_slot1_20260710_120000.isar', 2);
    final service = _FakeSaveManagementService(
      onRestore: (_) => throw UnimplementedError(),
    );
    await _pump(tester, service: service, backups: [newer, older]);

    await tester.tap(find.text(UiStrings.saveManagementRestore));
    await tester.pumpAndSettle();

    final dialog = find.byType(Dialog);
    final newerInDialog = find.descendant(
      of: dialog,
      matching: find.text(newer.fileName),
    );
    final olderInDialog = find.descendant(
      of: dialog,
      matching: find.text(older.fileName),
    );
    expect(
      find.text(UiStrings.saveManagementSelectBackupTitle),
      findsOneWidget,
    );
    expect(newerInDialog, findsOneWidget);
    expect(olderInDialog, findsOneWidget);
    expect(
      tester.getTopLeft(newerInDialog).dy,
      lessThan(tester.getTopLeft(olderInDialog).dy),
    );

    await tester.tap(newerInDialog);
    await tester.pumpAndSettle();
    expect(
      find.text(UiStrings.saveManagementRestoreConfirmTitle),
      findsOneWidget,
    );
    expect(
      find.text(UiStrings.saveManagementRestoreConfirmMessage(newer.fileName)),
      findsOneWidget,
    );
  });

  testWidgets('successful restore only offers closing the game', (
    tester,
  ) async {
    final selected = _backup('wuxia_save_slot1_20260710_120000.isar', 2);
    final safety = _backup('wuxia_save_slot1_20260710_130000.isar', 3);
    final service = _FakeSaveManagementService(
      onRestore: (backup) async => SaveRestoreResult(
        selectedBackup: backup,
        safetyBackup: safety,
        slotId: 1,
      ),
    );
    var quitCalls = 0;
    AppExit.quit = () => quitCalls++;
    await _pump(tester, service: service, backups: [selected]);

    await _startRestore(tester, selected);

    expect(
      find.text(UiStrings.saveManagementRestoreSucceededTitle),
      findsOneWidget,
    );
    expect(
      find.text(
        UiStrings.saveManagementRestoreSucceededMessage(safety.fileName),
      ),
      findsOneWidget,
    );
    expect(find.text(UiStrings.saveManagementCloseGame), findsOneWidget);

    await tester.tap(find.text(UiStrings.saveManagementCloseGame));
    expect(quitCalls, 1);
    expect(service.restoreCalls, 1);
  });

  testWidgets('preflight failure keeps the app open', (tester) async {
    final selected = _backup('wuxia_save_slot1_20260710_120000.isar', 2);
    final service = _FakeSaveManagementService(
      onRestore: (_) async => throw const SaveRestoreException(
        phase: SaveRestorePhase.preflight,
        requiresRestart: false,
        cause: 'bad backup',
      ),
    );
    var quitCalls = 0;
    AppExit.quit = () => quitCalls++;
    await _pump(tester, service: service, backups: [selected]);

    await _startRestore(tester, selected);

    expect(
      find.text(UiStrings.saveManagementRestoreFailedTitle),
      findsOneWidget,
    );
    expect(find.text(UiStrings.saveManagementAcknowledge), findsOneWidget);
    expect(find.text(UiStrings.saveManagementCloseGame), findsNothing);
    expect(quitCalls, 0);
  });

  testWidgets('post-close failure requires closing the game', (tester) async {
    final selected = _backup('wuxia_save_slot1_20260710_120000.isar', 2);
    final service = _FakeSaveManagementService(
      onRestore: (_) async => throw const SaveRestoreException(
        phase: SaveRestorePhase.swapFiles,
        requiresRestart: true,
        cause: 'swap failed',
      ),
    );
    var quitCalls = 0;
    AppExit.quit = () => quitCalls++;
    await _pump(tester, service: service, backups: [selected]);

    await _startRestore(tester, selected);

    expect(
      find.text(UiStrings.saveManagementRestoreRestartRequiredTitle),
      findsOneWidget,
    );
    expect(find.text(UiStrings.saveManagementCloseGame), findsOneWidget);
    expect(find.text(UiStrings.saveManagementAcknowledge), findsNothing);
    await tester.tap(find.text(UiStrings.saveManagementCloseGame));
    expect(quitCalls, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required SaveManagementService service,
  required List<SaveBackupInfo> backups,
}) async {
  final now = DateTime(2026, 7, 10, 12);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        saveManagementServiceProvider.overrideWith((ref) => service),
        saveManagementStatusProvider.overrideWith(
          (ref) async => SaveManagementStatus(
            slotId: 1,
            saveVersion: '0.34.0',
            createdAt: now,
            lastSavedAt: now,
            lastOnlineAt: now,
            databasePath: '/tmp/wuxia_save_slot1.isar',
            backupDirectoryPath: '/tmp/wuxia_save_backups',
            backups: backups,
          ),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: SaveManagementSection())),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _startRestore(WidgetTester tester, SaveBackupInfo selected) async {
  await tester.tap(find.text(UiStrings.saveManagementRestore));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(Dialog),
      matching: find.text(selected.fileName),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(UiStrings.saveManagementRestoreConfirmAction));
  await tester.pumpAndSettle();
}

SaveBackupInfo _backup(String fileName, int day) => SaveBackupInfo(
  path: '/tmp/wuxia_save_backups/$fileName',
  fileName: fileName,
  createdAt: DateTime(2026, 7, day, 12),
  sizeBytes: 2048 * day,
);

class _FakeSaveManagementService implements SaveManagementService {
  _FakeSaveManagementService({required this.onRestore});

  final Future<SaveRestoreResult> Function(SaveBackupInfo backup) onRestore;
  int restoreCalls = 0;

  @override
  Isar get isar => throw UnimplementedError();

  @override
  Directory get backupDirectory => throw UnimplementedError();

  @override
  Future<SaveBackupInfo> createBackup() => throw UnimplementedError();

  @override
  Future<void> deleteBackup(SaveBackupInfo backup) =>
      throw UnimplementedError();

  @override
  Future<List<SaveBackupInfo>> listBackups() => throw UnimplementedError();

  @override
  Future<SaveManagementStatus> loadStatus() => throw UnimplementedError();

  @override
  Future<SaveRestoreResult> restoreBackup(SaveBackupInfo backup) {
    restoreCalls++;
    return onRestore(backup);
  }
}
