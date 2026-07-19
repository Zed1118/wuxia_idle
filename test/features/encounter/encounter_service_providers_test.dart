import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/skill_unlock_entry.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_provider.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/encounter/application/encounter_service_providers.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// `encounter_service_providers` 三 provider 行为测（2026-07-19 夜批
/// coverage 补强，基线 2/17 行）。
///
/// 真 Isar + 真 GameRepository + ProviderContainer 真读，钉：
///   - `encounterServiceProvider` nullable propagation(带 numbers 构造)
///   - `currentEncounterProgressProvider` 按 currentSlotId 查行/无行 null
///   - `unlockedSkillIdSetProvider` 只收 unlocked=true 的 skillId(波A A4 单一真相源)
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_encounter_providers_',
    );
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('service:Isar 未 init → null;init + invalidate → 非 null', () async {
    final container = makeContainer();
    final sub = container.listen(encounterServiceProvider, (_, _) {});
    addTearDown(sub.close);

    expect(container.read(encounterServiceProvider), isNull);

    await IsarSetup.init(directory: tempDir, inspector: false);
    container.invalidate(isarProvider);
    expect(container.read(encounterServiceProvider), isNotNull);
  });

  test('currentEncounterProgress:无行 → null;建行后按槽位查到', () async {
    final container = makeContainer();
    expect(
      await container.read(currentEncounterProgressProvider.future),
      isNull,
      reason: 'Isar 未 init → null(UI 兜底,不抛)',
    );

    await IsarSetup.init(directory: tempDir, inspector: false);
    container.invalidate(isarProvider);
    final sub = container.listen(currentEncounterProgressProvider, (_, _) {});
    addTearDown(sub.close);
    expect(
      await container.read(currentEncounterProgressProvider.future),
      isNull,
      reason: 'getOrCreate 未跑过 → 无行 null',
    );

    await container
        .read(encounterServiceProvider)!
        .getOrCreate(saveDataId: IsarSetup.currentSlotId);
    container.invalidate(currentEncounterProgressProvider);
    final row = await container.read(currentEncounterProgressProvider.future);
    expect(row, isNotNull);
    expect(row!.saveDataId, IsarSetup.currentSlotId);
  });

  test('unlockedSkillIdSet:只收 unlocked=true;未解锁/空档排除', () async {
    final container = makeContainer();
    expect(
      await container.read(unlockedSkillIdSetProvider.future),
      isEmpty,
      reason: 'Isar 未 init → 空集',
    );

    await IsarSetup.init(directory: tempDir, inspector: false);
    container.invalidate(isarProvider);
    final sub = container.listen(unlockedSkillIdSetProvider, (_, _) {});
    addTearDown(sub.close);
    expect(
      await container.read(unlockedSkillIdSetProvider.future),
      isEmpty,
      reason: '全新 SaveData skillUnlockProgress 空 → 空集',
    );

    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!
        ..skillUnlockProgress = [
          SkillUnlockEntry()
            ..skillId = 'skill_a'
            ..unlocked = true,
          SkillUnlockEntry()
            ..skillId = 'skill_b'
            ..unlocked = false,
        ];
      await IsarSetup.instance.saveDatas.put(save);
    });
    container.invalidate(unlockedSkillIdSetProvider);
    expect(
      await container.read(unlockedSkillIdSetProvider.future),
      {'skill_a'},
      reason: '只 unlocked=true 进池(奇遇/真解/残页单一真相源)',
    );
  });
}
