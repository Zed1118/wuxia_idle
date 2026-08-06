import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// Task 7 · floor49 护法结界红线守护测
///
/// 覆盖(GDD §5.4 红线 + 三系锁死):
///   1. Boss HP 红线:baseHp == 59500 且 <= bossHpMax(60000),护法结界不得
///      变相把 Boss 血量堆到红线之上(批 A 塔顶迁 49 层·wuSheng 数值)。
///   2. 护法结界承伤倍率 ∈ (0, 1],不允许 >=1(等于没结界)或 <=0(免疫)。
///   3. Scope 收敛:guardianWard 白名单 {42, 49} 内各仅主 Boss 配置,遍历全部
///      49 层验证(floor42 = 第八阶段敌方协同实例,2026-08-06 校准闭环后登记)。
///   4. 三系锁死:floor49 主 Boss + 两名护法均为 wuSheng 境界(塔顶层),
///      结界/HP 改动不应连带偷改境界档位。
///   5. 护法 HP 校准值钉死:30000 / 28000(批 A 塔顶重排值,A5 balance 复校),
///      防止后续改动静默漂移。
///   6. 招式倍率红线:floor49 相关招式 powerMultiplier <= 8000 —— 全仓已有
///      `enforceEncounterSkillRedLines`(validation/,loadAllDefs 内对全部 skillDefs
///      强制校验)覆盖此红线,此处仅对 floor49 实际引用的招式做一次轻量
///      复核,不重复造轮子。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  tearDown(GameRepository.resetForTest);

  test('floor49 Boss HP 红线:baseHp==59500 且 <= bossHpMax(60000)', () async {
    final repo = await GameRepository.loadAllDefs(loader: fileLoader);
    final floor49 = repo.towerFloors.firstWhere((f) => f.floorIndex == 49);
    final boss = floor49.enemyTeam.firstWhere((e) => e.isBoss);

    expect(
      boss.id,
      'enemy_tower_boss_49',
      reason: 'floor49 主 Boss id 应为 enemy_tower_boss_49',
    );
    expect(boss.baseHp, 59500, reason: '塔顶终关 Boss 基础血量漂移需人工复核');
    final bossHpMax = repo.numbers.combat.redLines.bossHpMax;
    expect(bossHpMax, 60000, reason: 'GDD §5.4 Boss HP 上限应为 60000,drift 需人工确认');
    expect(
      boss.baseHp,
      lessThanOrEqualTo(bossHpMax),
      reason: '护法结界不得把 Boss HP 变相推过 GDD §5.4 上限',
    );
  });

  test('floor49 Boss 护法结界承伤倍率 ∈ (0, 1]', () async {
    final repo = await GameRepository.loadAllDefs(loader: fileLoader);
    final floor49 = repo.towerFloors.firstWhere((f) => f.floorIndex == 49);
    final boss = floor49.enemyTeam.firstWhere((e) => e.isBoss);

    final ward = boss.guardianWard;
    expect(ward, isNotNull, reason: 'floor49 主 Boss 必须配置 guardianWard');
    expect(
      ward!.damageTakenMult,
      greaterThan(0.0),
      reason: 'damageTakenMult 必须严格 >0,否则等同 Boss 免疫',
    );
    expect(
      ward.damageTakenMult,
      lessThanOrEqualTo(1.0),
      reason: 'damageTakenMult 必须 <=1,否则结界变相放大 Boss 承伤',
    );
  });

  test('guardianWard 白名单 {42, 49} 内各恰 1 个主 Boss 配置,名单外全 null(非空遍历)', () async {
    final repo = await GameRepository.loadAllDefs(loader: fileLoader);

    expect(
      repo.towerFloors.length,
      greaterThanOrEqualTo(30),
      reason: '塔层数据应至少覆盖 30 层,遍历才有意义',
    );

    // 白名单语义:floor42 为第八阶段敌方协同实例(2026-08-06 校准闭环后登记);
    // 扩名单必须先过 floor42_coop_guard_diagnostic 同体例校准再改此处。
    const wardFloors = {42, 49};
    final wardCountByFloor = <int, int>{};
    var otherFloorsChecked = 0;
    for (final f in repo.towerFloors) {
      for (final e in f.enemyTeam) {
        if (wardFloors.contains(f.floorIndex)) {
          if (e.guardianWard != null) {
            wardCountByFloor[f.floorIndex] =
                (wardCountByFloor[f.floorIndex] ?? 0) + 1;
          }
          continue;
        }
        otherFloorsChecked++;
        expect(
          e.guardianWard,
          isNull,
          reason:
              'floor ${f.floorIndex} 敌人 ${e.id} 不应配 guardianWard'
              '(guardianWard 是白名单 {42, 49} 专属机制)',
        );
      }
    }

    for (final floor in wardFloors) {
      expect(
        wardCountByFloor[floor],
        1,
        reason: 'floor $floor 应恰好 1 个敌人(主 Boss)配置 guardianWard',
      );
    }
    expect(
      otherFloorsChecked,
      greaterThan(0),
      reason: '白名单外敌人遍历不能是空集,否则上面的断言是空跑',
    );
  });

  test('三系锁死:floor49 主 Boss + 两护法均为 wuSheng 境界(塔顶层)', () async {
    final repo = await GameRepository.loadAllDefs(loader: fileLoader);
    final floor49 = repo.towerFloors.firstWhere((f) => f.floorIndex == 49);
    final boss = floor49.enemyTeam.firstWhere((e) => e.isBoss);
    final guardianA = floor49.enemyTeam.firstWhere(
      (e) => e.id == 'enemy_tower_49_cultist_a',
    );
    final guardianB = floor49.enemyTeam.firstWhere(
      (e) => e.id == 'enemy_tower_49_cultist_b',
    );

    expect(
      boss.realmTier,
      RealmTier.wuSheng,
      reason:
          'floor49 主 Boss 境界不应被护法结界/HP 校准连带偷改'
          '(塔顶=wuSheng.dengFeng,1:1 锚死)',
    );
    expect(
      guardianA.realmTier,
      RealmTier.wuSheng,
      reason: '护法(左使)境界不应被提血校准连带偷改',
    );
    expect(
      guardianB.realmTier,
      RealmTier.wuSheng,
      reason: '护法(右使)境界不应被提血校准连带偷改',
    );
  });

  test('护法 HP 校准值钉死:左使 30000 / 右使 28000', () async {
    final repo = await GameRepository.loadAllDefs(loader: fileLoader);
    final floor49 = repo.towerFloors.firstWhere((f) => f.floorIndex == 49);
    final boss = floor49.enemyTeam.firstWhere((e) => e.isBoss);
    final guardianA = floor49.enemyTeam.firstWhere(
      (e) => e.id == 'enemy_tower_49_cultist_a',
    );
    final guardianB = floor49.enemyTeam.firstWhere(
      (e) => e.id == 'enemy_tower_49_cultist_b',
    );

    expect(guardianA.baseHp, 30000, reason: '批 A 塔顶重排值(左使),漂移需人工复核');
    expect(guardianB.baseHp, 28000, reason: '批 A 塔顶重排值(右使),漂移需人工复核');
    // 双重保险:护法保持正血量且显著低于主 Boss。
    expect(guardianA.baseHp, greaterThan(0));
    expect(guardianB.baseHp, greaterThan(0));
    expect(guardianA.baseHp, lessThan(boss.baseHp));
    expect(guardianB.baseHp, lessThan(boss.baseHp));
  });

  test('招式倍率红线:floor49 相关招式 powerMultiplier <= 8000(轻量复核)', () async {
    final repo = await GameRepository.loadAllDefs(loader: fileLoader);
    final floor49 = repo.towerFloors.firstWhere((f) => f.floorIndex == 49);

    final floor49SkillIds = <String>{
      for (final e in floor49.enemyTeam) ...e.skillIds,
    };
    expect(floor49SkillIds, isNotEmpty, reason: 'floor49 敌人应至少引用一个招式,遍历才有意义');

    // 全局红线已由 enforceEncounterSkillRedLines(validation/) 在
    // loadAllDefs 内对全部 skillDefs 强制校验(见 lib/data/game_repository.dart
    // 附近 GDD §5.4 max_skill_multiplier=8000 注释);loadAllDefs 未抛异常即
    // 说明该红线已过。此处仅对 floor49 实际引用的招式做一次显式复核,
    // 确认 Task 5 的数值校准(仅改 baseHp/damageTakenMult)没有连带动到招式倍率。
    for (final skillId in floor49SkillIds) {
      final skill = repo.skillDefs[skillId];
      expect(skill, isNotNull, reason: '招式 $skillId 应存在于 skillDefs');
      expect(
        skill!.powerMultiplier,
        lessThanOrEqualTo(8000),
        reason:
            '招式 $skillId powerMultiplier=${skill.powerMultiplier} '
            '违反 GDD §5.4 全局红线(<=8000)',
      );
    }
  });
}
