import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/tutorial/application/tutorial_service.dart';

/// P1 #42 Phase 2 §10 P1.x · TutorialService 红线契约。
///
/// 验证语义(memory `feedback_red_line_test_semantics`):
/// - getCurrentStep 默认 0(SaveData 未 seed)
/// - advanceToStep 单调递增 + 幂等防回退
/// - advanceForStageCleared Ch1 stage 映射 step 1-5,非 Ch1 no-op
/// - caller 持锁(本服务方法不开 writeTxn,test 端 writeTxn 包裹)
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_tutorial_svc_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<void> seedSave({int initialStep = 0}) async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.saveDatas.put(SaveData()
        ..slotId = IsarSetup.currentSlotId
        ..saveVersion = '0.10.0'
        ..createdAt = DateTime.now()
        ..lastSavedAt = DateTime.now()
        ..lastOnlineAt = DateTime.now()
        ..tutorialStep = initialStep);
    });
  }

  test('getCurrentStep 未 seed SaveData → 默认 0', () async {
    final svc = TutorialService(IsarSetup.instance);
    expect(await svc.getCurrentStep(), 0);
  });

  test('advanceToStep(3) 从 0 写入 + getCurrentStep 回读', () async {
    await seedSave();
    final isar = IsarSetup.instance;
    final svc = TutorialService(isar);

    await isar.writeTxn(() => svc.advanceToStep(3));

    expect(await svc.getCurrentStep(), 3);
  });

  test('advanceToStep(2) 在 step=3 时 no-op(幂等 + 防回退)', () async {
    await seedSave(initialStep: 3);
    final isar = IsarSetup.instance;
    final svc = TutorialService(isar);

    await isar.writeTxn(() => svc.advanceToStep(2));

    expect(await svc.getCurrentStep(), 3);
  });

  test('advanceToStep(5) 等值 no-op(currentStep == targetStep)', () async {
    await seedSave(initialStep: 5);
    final isar = IsarSetup.instance;
    final svc = TutorialService(isar);

    await isar.writeTxn(() => svc.advanceToStep(5));

    expect(await svc.getCurrentStep(), 5);
  });

  test('advanceForStageCleared(stage_01_03) → step 3', () async {
    await seedSave();
    final isar = IsarSetup.instance;
    final svc = TutorialService(isar);

    await isar.writeTxn(() => svc.advanceForStageCleared('stage_01_03'));

    expect(await svc.getCurrentStep(), 3);
  });

  test('advanceForStageCleared(stage_02_01) → no-op(非 Ch1)', () async {
    await seedSave();
    final isar = IsarSetup.instance;
    final svc = TutorialService(isar);

    await isar.writeTxn(() => svc.advanceForStageCleared('stage_02_01'));

    expect(await svc.getCurrentStep(), 0);
  });

  test('advanceForStageCleared 5 关顺序通 → step 1→2→3→4→5', () async {
    await seedSave();
    final isar = IsarSetup.instance;
    final svc = TutorialService(isar);

    for (var i = 1; i <= 5; i++) {
      final stageId = 'stage_01_0$i';
      await isar.writeTxn(() => svc.advanceForStageCleared(stageId));
      expect(await svc.getCurrentStep(), i,
          reason: '$stageId cleared 后 step 应 = $i');
    }
  });

  test('advanceForStageCleared 跳关后回头通低关 → step 不回退', () async {
    await seedSave();
    final isar = IsarSetup.instance;
    final svc = TutorialService(isar);

    await isar.writeTxn(() => svc.advanceForStageCleared('stage_01_05'));
    expect(await svc.getCurrentStep(), 5);

    await isar.writeTxn(() => svc.advanceForStageCleared('stage_01_02'));
    expect(await svc.getCurrentStep(), 5, reason: '低关回头不应回退已达 step');
  });

  // ── P1.y · step 6/7/8 业务门槛 hook ──────────────────────────────────

  group('§10 P1.y · 高阶 hook', () {
    test('advanceForRealmBreakthrough(yiLiu) 从 step 5 → step 6', () async {
      await seedSave(initialStep: 5);
      final isar = IsarSetup.instance;
      final svc = TutorialService(isar);

      await isar.writeTxn(() => svc.advanceForRealmBreakthrough(RealmTier.yiLiu));

      expect(await svc.getCurrentStep(), 6);
    });

    test('advanceForRealmBreakthrough(yiLiu 及以上各 tier)均推 step 6', () async {
      for (final tier in [
        RealmTier.yiLiu,
        RealmTier.jueDing,
        RealmTier.zongShi,
        RealmTier.wuSheng,
      ]) {
        await seedSave(initialStep: 5);
        final isar = IsarSetup.instance;
        final svc = TutorialService(isar);

        await isar.writeTxn(() => svc.advanceForRealmBreakthrough(tier));

        expect(await svc.getCurrentStep(), 6,
            reason: '$tier (>= yiLiu) 应推到 step 6');
        await IsarSetup.close();
        await IsarSetup.init(directory: tempDir, inspector: false);
      }
    });

    test('advanceForRealmBreakthrough(三流及以下)→ no-op', () async {
      await seedSave(initialStep: 5);
      final isar = IsarSetup.instance;
      final svc = TutorialService(isar);

      await isar.writeTxn(() => svc.advanceForRealmBreakthrough(RealmTier.xueTu));
      expect(await svc.getCurrentStep(), 5);

      await isar.writeTxn(() => svc.advanceForRealmBreakthrough(RealmTier.sanLiu));
      expect(await svc.getCurrentStep(), 5);

      await isar.writeTxn(() => svc.advanceForRealmBreakthrough(RealmTier.erLiu));
      expect(await svc.getCurrentStep(), 5,
          reason: '二流 < 一流 也不应推到 step 6');
    });

    test('advanceForFirstAdventure → step 7', () async {
      await seedSave(initialStep: 6);
      final isar = IsarSetup.instance;
      final svc = TutorialService(isar);

      await isar.writeTxn(() => svc.advanceForFirstAdventure());
      expect(await svc.getCurrentStep(), 7);

      // 第 2 次靠 advanceToStep 单调 no-op
      await isar.writeTxn(() => svc.advanceForFirstAdventure());
      expect(await svc.getCurrentStep(), 7);
    });

    test('advanceForFirstEnhanceLevel10 → step 8', () async {
      await seedSave(initialStep: 7);
      final isar = IsarSetup.instance;
      final svc = TutorialService(isar);

      await isar.writeTxn(() => svc.advanceForFirstEnhanceLevel10());
      expect(await svc.getCurrentStep(), 8);

      // 第 2 次 no-op
      await isar.writeTxn(() => svc.advanceForFirstEnhanceLevel10());
      expect(await svc.getCurrentStep(), 8);
    });
  });

  // ── P1.y · markHintRead / getHintsRead ──────────────────────────────

  group('§10 P1.y · banner 已读状', () {
    test('markHintRead(6) → tutorialHintsRead = [6]', () async {
      await seedSave();
      final isar = IsarSetup.instance;
      final svc = TutorialService(isar);

      await isar.writeTxn(() => svc.markHintRead(6));

      expect(await svc.getHintsRead(), [6]);
    });

    test('markHintRead 6/7/8 顺序 → [6,7,8]', () async {
      await seedSave();
      final isar = IsarSetup.instance;
      final svc = TutorialService(isar);

      await isar.writeTxn(() => svc.markHintRead(6));
      await isar.writeTxn(() => svc.markHintRead(7));
      await isar.writeTxn(() => svc.markHintRead(8));

      expect(await svc.getHintsRead(), [6, 7, 8]);
    });

    test('markHintRead(6) 二次 → no-op(单调追加)', () async {
      await seedSave();
      final isar = IsarSetup.instance;
      final svc = TutorialService(isar);

      await isar.writeTxn(() => svc.markHintRead(6));
      await isar.writeTxn(() => svc.markHintRead(6));

      expect(await svc.getHintsRead(), [6]);
    });

    test('markHintRead 无 def step(2/9/0)→ no-op', () async {
      await seedSave();
      final isar = IsarSetup.instance;
      final svc = TutorialService(isar);

      await isar.writeTxn(() => svc.markHintRead(2));
      await isar.writeTxn(() => svc.markHintRead(9));
      await isar.writeTxn(() => svc.markHintRead(0));

      expect(await svc.getHintsRead(), isEmpty);
    });

    test('markHintRead(3) → [3](§5.7 心法解锁锚点)', () async {
      await seedSave();
      final svc = TutorialService(IsarSetup.instance);

      await IsarSetup.instance.writeTxn(() => svc.markHintRead(3));

      expect(await svc.getHintsRead(), [3]);
    });

    test('markHintRead(5) → [5](§5.7 Ch1 通关解锁锚点)', () async {
      await seedSave();
      final svc = TutorialService(IsarSetup.instance);

      await IsarSetup.instance.writeTxn(() => svc.markHintRead(5));

      expect(await svc.getHintsRead(), [5]);
    });

    test('getHintsRead 未 seed SaveData → []', () async {
      final svc = TutorialService(IsarSetup.instance);
      expect(await svc.getHintsRead(), isEmpty);
    });
  });
}
