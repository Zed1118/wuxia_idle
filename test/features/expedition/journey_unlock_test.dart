import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/expedition/application/journey_unlock.dart';

import '../../support/isar_test_support.dart';

/// 里程碑批切片3:任一角色首达 Lv100(三流·熟练=绝对层10)永久解锁「江湖远行」
/// (companion §L53/§Q3;发布上限 10→17 后仍以 Lv100 为解锁线,不随 cap 走)。

Character _charAt(RealmTier tier, RealmLayer layer) => Character()
  ..realmTier = tier
  ..realmLayer = layer;

SaveData _save({bool unlocked = false}) => SaveData()
  ..id = 0
  ..jianghuJourneyUnlocked = unlocked;

void main() {
  group('unlockJianghuJourneyIfReached（纯里程碑判定·无 Isar 依赖）', () {
    test('角色达 Lv100(三流·熟练=绝对层10)且未解锁 → 置真返 true', () {
      final save = _save();
      final changed = unlockJianghuJourneyIfReached(
        save: save,
        characters: [_charAt(RealmTier.sanLiu, RealmLayer.shuLian)],
      );
      expect(changed, isTrue);
      expect(save.jianghuJourneyUnlocked, isTrue);
    });

    test('角色停在绝对层9(三流·入门)未达里程碑 → 不解锁', () {
      final save = _save();
      final changed = unlockJianghuJourneyIfReached(
        save: save,
        characters: [_charAt(RealmTier.sanLiu, RealmLayer.ruMen)],
      );
      expect(changed, isFalse);
      expect(save.jianghuJourneyUnlocked, isFalse);
    });

    test('已解锁 → 幂等不重复写(返 false 即便有 ≥Lv100 角色)', () {
      final save = _save(unlocked: true);
      final changed = unlockJianghuJourneyIfReached(
        save: save,
        characters: [_charAt(RealmTier.wuSheng, RealmLayer.dengFeng)],
      );
      expect(changed, isFalse);
      expect(save.jianghuJourneyUnlocked, isTrue);
    });

    test('多角色任一达标即解锁', () {
      final save = _save();
      final changed = unlockJianghuJourneyIfReached(
        save: save,
        characters: [
          _charAt(RealmTier.xueTu, RealmLayer.dengFeng), // 绝对层7 未达
          _charAt(RealmTier.erLiu, RealmLayer.qiMeng), // 绝对层15 达标
        ],
      );
      expect(changed, isTrue);
      expect(save.jianghuJourneyUnlocked, isTrue);
    });

    test('旧档已有二流角色(绝对层17)未置标志 → 补解锁', () {
      final save = _save();
      final changed = unlockJianghuJourneyIfReached(
        save: save,
        characters: [_charAt(RealmTier.erLiu, RealmLayer.shuLian)], // 绝对层17
      );
      expect(changed, isTrue);
      expect(save.jianghuJourneyUnlocked, isTrue);
    });

    test('空角色列表 → 不解锁', () {
      final save = _save();
      expect(
        unlockJianghuJourneyIfReached(save: save, characters: const []),
        isFalse,
      );
      expect(save.jianghuJourneyUnlocked, isFalse);
    });
  });

  group('unlockJianghuJourneyOnOpen（Isar 落库核心·同 settle-on-open 体例）', () {
    late Directory tempDir;

    setUpAll(() => initializeTestIsarCore());

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wuxia_journey_unlock_');
      await IsarSetup.init(directory: tempDir, inspector: false);
      await IsarSetup.instance.writeTxn(() async {
        await IsarSetup.instance.saveDatas.put(
          SaveData()
            ..id = 0
            ..saveVersion = '0.37.0'
            ..createdAt = DateTime(2026, 7, 16)
            ..lastSavedAt = DateTime(2026, 7, 16)
            ..lastOnlineAt = DateTime(2026, 7, 16),
        );
      });
    });

    tearDown(() async {
      await IsarSetup.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Future<void> seedChar(RealmTier tier, RealmLayer layer) async {
      await IsarSetup.instance.writeTxn(() async {
        await IsarSetup.instance.characters.put(
          Character()
            ..name = '门人'
            ..realmTier = tier
            ..realmLayer = layer
            ..attributes = Attributes()
            ..rarity = RarityTier.biaoZhun
            ..lineageRole = LineageRole.disciple
            ..createdAt = DateTime(2026, 7, 16)
            ..isFounder = false
            ..mainTechniqueId = 5,
        );
      });
    }

    test('角色达 Lv100 → 落库置真返 true', () async {
      await seedChar(RealmTier.sanLiu, RealmLayer.shuLian);
      final unlocked = await unlockJianghuJourneyOnOpen(IsarSetup.instance);
      expect(unlocked, isTrue);
      final save = await IsarSetup.instance.saveDatas.get(0);
      expect(save!.jianghuJourneyUnlocked, isTrue);
    });

    test('角色未达 Lv100 → 不写返 false', () async {
      await seedChar(RealmTier.sanLiu, RealmLayer.ruMen);
      final unlocked = await unlockJianghuJourneyOnOpen(IsarSetup.instance);
      expect(unlocked, isFalse);
      final save = await IsarSetup.instance.saveDatas.get(0);
      expect(save!.jianghuJourneyUnlocked, isFalse);
    });

    test('已解锁 → no-op 返 false(不重复写)', () async {
      await IsarSetup.instance.writeTxn(() async {
        final s = await IsarSetup.instance.saveDatas.get(0);
        s!.jianghuJourneyUnlocked = true;
        await IsarSetup.instance.saveDatas.put(s);
      });
      await seedChar(RealmTier.sanLiu, RealmLayer.shuLian);
      final unlocked = await unlockJianghuJourneyOnOpen(IsarSetup.instance);
      expect(unlocked, isFalse);
    });

    test('首帧并发写入发生在解锁事务前时不被旧 SaveData 快照覆盖', () async {
      await seedChar(RealmTier.sanLiu, RealmLayer.shuLian);
      final reachedBarrier = Completer<void>();
      final releaseBarrier = Completer<void>();
      final unlock = unlockJianghuJourneyOnOpen(
        IsarSetup.instance,
        beforeWriteTxn: () async {
          reachedBarrier.complete();
          await releaseBarrier.future;
        },
      );

      await reachedBarrier.future;
      await IsarSetup.instance.writeTxn(() async {
        final current = (await IsarSetup.currentSaveData())!;
        current.totalPassiveExperience = 321;
        await IsarSetup.instance.saveDatas.put(current);
      });
      releaseBarrier.complete();
      expect(await unlock, isTrue);

      final saved = (await IsarSetup.currentSaveData())!;
      expect(saved.jianghuJourneyUnlocked, isTrue);
      expect(saved.totalPassiveExperience, 321);
    });
  });
}
