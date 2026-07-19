import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/save_slot/application/slot_list_provider.dart';
import 'package:wuxia_idle/features/save_slot/presentation/save_select_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/error_fallback.dart';

import '../support/isar_test_support.dart';

void main() {
  late Directory tempDir;
  final preservedAt = DateTime(2026, 7, 19, 12, 34, 56);

  setUpAll(initializeTestIsarCore);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_forward_save_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.currentSaveData())!;
      save
        ..saveVersion = '0.99.0'
        ..slotName = '未来档勿改'
        ..totalPassiveExperience = 9876
        ..jianghuJourneyUnlocked = true
        ..lastSavedAt = preservedAt;
      await IsarSetup.instance.saveDatas.put(save);
    });
    await IsarSetup.close();
  });

  tearDown(() async {
    final open = Isar.getInstance('wuxia_save_slot1');
    if (open != null) await open.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('0.99.0 真 Isar 档拒绝迁移且代表字段零改写', () async {
    await expectLater(
      IsarSetup.init(directory: tempDir, inspector: false),
      throwsA(
        isA<UnsupportedSaveVersionException>()
            .having((e) => e.actualVersion, 'actualVersion', '0.99.0')
            .having(
              (e) => e.supportedVersion,
              'supportedVersion',
              IsarSetup.currentSaveVersion,
            ),
      ),
    );
    expect(IsarSetup.instanceOrNull, isNull, reason: '拒绝后不得留下可继续写入的实例');

    final raw = await Isar.open(
      IsarSetup.schemasForTesting,
      directory: tempDir.path,
      name: 'wuxia_save_slot1',
      inspector: false,
    );
    try {
      final save = (await raw.saveDatas.get(0))!;
      expect(save.saveVersion, '0.99.0');
      expect(save.slotName, '未来档勿改');
      expect(save.totalPassiveExperience, 9876);
      expect(save.jianghuJourneyUnlocked, isTrue);
      expect(save.lastSavedAt, preservedAt);
    } finally {
      await raw.close();
    }

    await expectLater(
      IsarSetup.listSlots(directory: tempDir),
      throwsA(isA<UnsupportedSaveVersionException>()),
      reason: '存档列表须把同一异常交给既有 AsyncValue.error 呈现路径',
    );
  });

  testWidgets('未来版本档在存档选择屏命中既有 ErrorFallback', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          slotListProvider.overrideWithValue(
            const AsyncValue.error(
              UnsupportedSaveVersionException(
                actualVersion: '0.99.0',
                supportedVersion: '0.37.0',
              ),
              StackTrace.empty,
            ),
          ),
        ],
        child: const MaterialApp(home: SaveSelectScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ErrorFallback), findsOneWidget);
    expect(find.text(UiStrings.errorFallbackMessage), findsOneWidget);
  });
}
