import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/jianghu/application/reputation_service.dart';

/// P1.2 §3 ReputationService 红线契约。
///
/// 验证语义(memory `feedback_red_line_test_semantics`):
/// - applyDelta upsert + clamp [-100, +100]
/// - tierOf 7 阶映射 + 边界 + 中间 fallback
/// - 多门派隔离 + 多 playerId 隔离
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('wuxia_reputation_test_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('JianghuConfig schema', () {
    test('numbers.yaml jianghu 段 7 阶加载', () {
      final n = GameRepository.instance.numbers;
      final tiers = n.jianghu.reputationTiers;
      expect(tiers.length, 7,
          reason: 'P1.2 §2 七阶沿 §5.2 · 不开新阶');
      expect(tiers.map((t) => t.tier).toList(), [
        'xueTu',
        'sanLiu',
        'erLiu',
        'yiLiu',
        'jueDing',
        'zongShi',
        'wuSheng',
      ]);
      expect(tiers.first.min, -100);
      expect(tiers.last.max, 100);
    });

    test('enmity_combat_modifier 加载 spec §2 决议', () {
      final emc =
          GameRepository.instance.numbers.jianghu.enmityCombatModifier;
      expect(emc.threshold, -50);
      expect(emc.playerAttackPowerMult, 1.15);
      expect(emc.enemyAttackPowerMult, 1.15);
      expect(emc.severeThreshold, -80);
      expect(emc.severeMult, 1.25);
      expect(emc.clampMax, 1.25);
    });

    test('triggers 加载', () {
      final t = GameRepository.instance.numbers.jianghu.triggers;
      expect(t.stageBossKillDelta, 5);
      expect(t.stageBossKillRivalDelta, 3);
      expect(t.encounterNpcDeltaMin, -8);
      expect(t.encounterNpcDeltaMax, 8);
    });
  });

  group('ReputationService.applyDelta', () {
    test('新建:首次 delta 入仓 + clamp', () async {
      final svc = ReputationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      await svc.applyDelta(1, 'shaolin', 10);
      expect(await svc.valueFor(1, 'shaolin'), 10);
    });

    test('累积:重复 delta 加和', () async {
      final svc = ReputationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      await svc.applyDelta(1, 'wudang', 5);
      await svc.applyDelta(1, 'wudang', 7);
      await svc.applyDelta(1, 'wudang', -3);
      expect(await svc.valueFor(1, 'wudang'), 9);
    });

    test('clamp 上限 +100:连续 +200 锁顶', () async {
      final svc = ReputationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      await svc.applyDelta(1, 'emei', 200);
      expect(await svc.valueFor(1, 'emei'), 100,
          reason: '§5.4 红线防越:applyDelta 必 clamp');
      await svc.applyDelta(1, 'emei', 50);
      expect(await svc.valueFor(1, 'emei'), 100, reason: '已到顶不再涨');
    });

    test('clamp 下限 -100:连续 -200 锁底', () async {
      final svc = ReputationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      await svc.applyDelta(1, 'jiaoMen', -200);
      expect(await svc.valueFor(1, 'jiaoMen'), -100);
    });

    test('多门派隔离', () async {
      final svc = ReputationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      await svc.applyDelta(1, 'shaolin', 30);
      await svc.applyDelta(1, 'jiaoMen', -50);
      expect(await svc.valueFor(1, 'shaolin'), 30);
      expect(await svc.valueFor(1, 'jiaoMen'), -50);
      final all = await svc.allFor(1);
      expect(all.length, 2);
    });

    test('多 playerId 隔离 · composite unique index 保', () async {
      final svc = ReputationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      await svc.applyDelta(1, 'shaolin', 20);
      await svc.applyDelta(2, 'shaolin', -10);
      expect(await svc.valueFor(1, 'shaolin'), 20);
      expect(await svc.valueFor(2, 'shaolin'), -10);
    });

    test('valueFor 未存在 → 0 sane fallback', () async {
      final svc = ReputationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      expect(await svc.valueFor(1, 'cijianzhuang'), 0);
    });
  });

  group('ReputationService.tierOf 7 阶映射 + 边界', () {
    test('21 测点 sweep 全 7 阶命中(R5.1)', () {
      final svc = ReputationService(
          IsarSetup.instance, GameRepository.instance.numbers);
      // (value, expected tier) · 覆盖每阶上下界 + 边界相邻
      const cases = <(int, String)>[
        (-100, 'xueTu'),
        (-90, 'xueTu'),
        (-71, 'xueTu'),
        (-70, 'sanLiu'),
        (-60, 'sanLiu'),
        (-41, 'sanLiu'),
        (-40, 'erLiu'),
        (-25, 'erLiu'),
        (-11, 'erLiu'),
        (-10, 'yiLiu'),
        (0, 'yiLiu'),
        (10, 'yiLiu'),
        (11, 'jueDing'),
        (25, 'jueDing'),
        (40, 'jueDing'),
        (41, 'zongShi'),
        (55, 'zongShi'),
        (70, 'zongShi'),
        (71, 'wuSheng'),
        (85, 'wuSheng'),
        (100, 'wuSheng'),
      ];
      for (final (v, expected) in cases) {
        expect(svc.tierOf(v), expected,
            reason: 'value=$v 应映射到 $expected');
      }
    });
  });
}
