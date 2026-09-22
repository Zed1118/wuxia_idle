import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/reward_entry.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';

import '../fixtures/legacy_gauntlet_cooldown.dart';
import '../support/isar_test_support.dart';

const _newFields = {
  'phase0aCooldownsRecorded',
  'phase0aCooldownKeys',
  'phase0aCooldownSeconds',
};
const _runId = 73;

void main() {
  setUpAll(initializeTestIsarCore);

  test('frozen old schema omits only the three new seconds fields', () {
    for (final (oldSchema, currentSchema, omitted)
        in <(Schema, Schema, Set<String>)>[
          (LegacyGauntletCooldownRunSchema, BossGauntletRunSchema, {}),
          (
            LegacyGauntletCooldownMemberSchema,
            ActivityMemberSnapshotSchema,
            _newFields,
          ),
          (LegacyGauntletCooldownRewardSchema, RewardEntrySchema, {}),
        ]) {
      expect(oldSchema.name, currentSchema.name);
      expect(oldSchema.id, currentSchema.id);
      expect(
        oldSchema.properties.keys.toSet(),
        currentSchema.properties.keys.toSet()..removeAll(omitted),
      );
      for (final property in oldSchema.properties.values) {
        final current = currentSchema.properties[property.name]!;
        expect(current.type, property.type, reason: property.name);
        expect(current.target, property.target, reason: property.name);
        expect(current.enumMap, property.enumMap, reason: property.name);
      }
    }
    expect(
      LegacyGauntletCooldownRunSchema.embeddedSchemas.keys.toSet(),
      BossGauntletRunSchema.embeddedSchemas.keys.toSet(),
    );
    expect(
      ActivityMemberSnapshotSchema.properties['phase0aCooldownsRecorded']!.type,
      IsarType.bool,
    );
    expect(
      ActivityMemberSnapshotSchema.properties['phase0aCooldownKeys']!.type,
      IsarType.stringList,
    );
    expect(
      ActivityMemberSnapshotSchema.properties['phase0aCooldownSeconds']!.type,
      IsarType.doubleList,
    );
  });

  for (final hasLegacyCooldowns in [false, true]) {
    test('real old schema cold open preserves every field; '
        'legacy cooldowns=$hasLegacyCooldowns', () async {
      final directory = await Directory.systemTemp.createTemp(
        'gauntlet_cooldown_legacy_',
      );
      Isar? db;
      try {
        db = await _openLegacy(directory);
        final original = _oldRun(hasLegacyCooldowns: hasLegacyCooldowns);
        await db.writeTxn(
          () => db!.collection<LegacyGauntletCooldownRun>().put(original),
        );
        final before = await db
            .collection<LegacyGauntletCooldownRun>()
            .where()
            .exportJson();
        await db.close();

        // 直接用当前 schema 打开，不执行 SaveData 迁移或应用恢复策略，
        // 以测量 Isar 的真实缺字段默认值。
        db = await _openCurrent(directory);
        final migrated = (await db.bossGauntletRuns.get(_runId))!;
        final member = migrated.members.single;
        expect(member.phase0aCooldownsRecorded, isFalse);
        expect(member.phase0aCooldownKeys, isEmpty);
        expect(member.phase0aCooldownSeconds, isEmpty);
        expect(
          member.skillCooldownKeys,
          original.members.single.skillCooldownKeys,
        );
        expect(
          member.skillCooldownTurns,
          original.members.single.skillCooldownTurns,
        );
        expect(
          _withoutNewFields(await db.bossGauntletRuns.where().exportJson()),
          before,
        );
      } finally {
        if (db?.isOpen ?? false) await db!.close();
        await directory.delete(recursive: true);
      }
    });
  }

  test(
    'fractional seconds and an explicitly empty checkpoint survive cold reopen '
    'without changing old turns',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'gauntlet_cooldown_seconds_',
      );
      Isar? db;
      try {
        db = await _openLegacy(directory);
        await db.writeTxn(
          () => db!.collection<LegacyGauntletCooldownRun>().put(
            _oldRun(hasLegacyCooldowns: true),
          ),
        );
        final before = await db
            .collection<LegacyGauntletCooldownRun>()
            .where()
            .exportJson();
        await db.close();

        const keys = ['gather', 'phase0a_skill_1', 'phase0a_skill_2'];
        const seconds = [2.8, 1.1, 0.125];
        for (final empty in [false, true]) {
          db = await _openCurrent(directory);
          final run = (await db.bossGauntletRuns.get(_runId))!;
          final member = run.members.single
            ..phase0aCooldownsRecorded = true
            ..phase0aCooldownKeys = empty ? [] : List.of(keys)
            ..phase0aCooldownSeconds = empty ? [] : List.of(seconds);
          expect(member.skillCooldownTurns, [2, 3]);
          await db.writeTxn(() => db!.bossGauntletRuns.put(run));
          await db.close();

          for (var reopen = 0; reopen < 2; reopen++) {
            db = await _openCurrent(directory);
            final saved = (await db.bossGauntletRuns.get(
              _runId,
            ))!.members.single;
            expect(saved.phase0aCooldownsRecorded, isTrue);
            expect(saved.phase0aCooldownKeys, empty ? <String>[] : keys);
            expect(saved.phase0aCooldownSeconds, empty ? <double>[] : seconds);
            expect(
              saved.phase0aCooldownSnapshot(),
              empty
                  ? <String, double>{}
                  : {for (var i = 0; i < keys.length; i++) keys[i]: seconds[i]},
              reason: 'Recorded empty seconds must not revive retained turns',
            );
            expect(
              _withoutNewFields(await db.bossGauntletRuns.where().exportJson()),
              before,
            );
            await db.close();
          }
        }
      } finally {
        if (db?.isOpen ?? false) await db!.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

Future<Isar> _openLegacy(Directory directory) => Isar.open(
  [LegacyGauntletCooldownRunSchema],
  directory: directory.path,
  name: 'gauntlet_cooldown_compatibility',
  inspector: false,
);

Future<Isar> _openCurrent(Directory directory) => Isar.open(
  [BossGauntletRunSchema],
  directory: directory.path,
  name: 'gauntlet_cooldown_compatibility',
  inspector: false,
);

LegacyGauntletCooldownRun _oldRun({required bool hasLegacyCooldowns}) =>
    LegacyGauntletCooldownRun()
      ..id = _runId
      ..saveDataId = 0
      ..seed = 820225
      ..cycleSeedEnabled = true
      ..currentStage = 2
      ..cycleIndex = 3
      ..sessionPhase = LegacyGauntletCooldownPhase.interlude
      ..members = [
        LegacyGauntletCooldownMember()
          ..characterId = 19
          ..reservedEquipmentIds = [31, 37, 41]
          ..reservedTechniqueIds = [43, 47]
          ..currentHp = hasLegacyCooldowns ? 421 : 0
          ..currentQi = 23
          ..isDowned = !hasLegacyCooldowns
          ..maxHp = 700
          ..maxQi = 89
          ..skillCooldownKeys = hasLegacyCooldowns
              ? ['skill_gangmeng_jichu_skill', 'skill_gangmeng_jichu_ultimate']
              : []
          ..skillCooldownTurns = hasLegacyCooldowns ? [2, 3] : [],
      ]
      ..escrowItemDefIds = ['item_healing_pill', 'item_supply_pack']
      ..escrowLoadedQty = [2, 1]
      ..escrowUsedQty = [1, 0]
      ..rewardCandidateDefIds = ['reward-a', 'reward-b', 'reward-c']
      ..isFirstClearPending = true
      ..stagedRewards = [
        LegacyGauntletCooldownReward()
          ..rewardKey = 'exp'
          ..quantity = 17,
        LegacyGauntletCooldownReward()
          ..rewardKey = 'internal_force'
          ..quantity = 29,
      ];

List<Map<String, dynamic>> _withoutNewFields(List<Map<String, dynamic>> rows) =>
    [
      for (final row in rows)
        {
          ...row,
          'members': [
            for (final member in row['members'] as List)
              Map<String, dynamic>.from(member as Map)
                ..removeWhere((key, _) => _newFields.contains(key)),
          ],
        },
    ];
