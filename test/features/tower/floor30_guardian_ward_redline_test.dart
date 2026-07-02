import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// Task 7 · floor30 护法结界红线守护测
///
/// 覆盖(GDD §5.4 红线 + 三系锁死):
///   1. Boss HP 红线:baseHp == 42000 且 <= bossHpMax(60000),护法结界不得
///      变相把 Boss 血量堆到红线之上。
///   2. 护法结界承伤倍率 ∈ (0, 1],不允许 >=1(等于没结界)或 <=0(免疫)。
///   3. Scope 收敛:guardianWard 仅 floor30 主 Boss 配置,遍历全部 30 层验证。
///   4. 三系锁死:floor30 主 Boss + 两名护法均为 zongShi 境界,结界/HP 改动
///      不应连带偷改境界档位。
///   5. 护法 HP 校准值钉死:9000 / 8500(Task 5 平衡校准结果),防止后续
///      改动静默漂移。
///   6. 招式倍率红线:floor30 相关招式 powerMultiplier <= 8000 —— 全仓已有
///      `_enforceEncounterSkillRedLines`(在 loadAllDefs 内对全部 skillDefs
///      强制校验)覆盖此红线,此处仅对 floor30 实际引用的招式做一次轻量
///      复核,不重复造轮子。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return (await f.readAsString()).replaceAll('\r\n', '\n');
  }

  tearDown(GameRepository.resetForTest);

  test('floor30 Boss HP 红线:baseHp==42000 且 <= bossHpMax(60000)', () async {
    final repo = await GameRepository.loadAllDefs(loader: fileLoader);
    final floor30 = repo.towerFloors.firstWhere((f) => f.floorIndex == 30);
    final boss = floor30.enemyTeam.firstWhere((e) => e.isBoss);

    expect(
      boss.id,
      'enemy_tower_boss_30',
      reason: 'floor30 主 Boss id 应为 enemy_tower_boss_30',
    );
    expect(boss.baseHp, 42000, reason: '护法结界校准不应连带改动 Boss 基础血量(应仍为 42000)');
    final bossHpMax = repo.numbers.combat.redLines.bossHpMax;
    expect(bossHpMax, 60000, reason: 'GDD §5.4 Boss HP 上限应为 60000,drift 需人工确认');
    expect(
      boss.baseHp,
      lessThanOrEqualTo(bossHpMax),
      reason: '护法结界不得把 Boss HP 变相推过 GDD §5.4 上限',
    );
  });

  test('floor30 Boss 护法结界承伤倍率 ∈ (0, 1]', () async {
    final repo = await GameRepository.loadAllDefs(loader: fileLoader);
    final floor30 = repo.towerFloors.firstWhere((f) => f.floorIndex == 30);
    final boss = floor30.enemyTeam.firstWhere((e) => e.isBoss);

    final ward = boss.guardianWard;
    expect(ward, isNotNull, reason: 'floor30 主 Boss 必须配置 guardianWard');
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

  test('guardianWard 仅 floor30 配置,其余 29 层全部为 null(非空遍历)', () async {
    final repo = await GameRepository.loadAllDefs(loader: fileLoader);

    expect(
      repo.towerFloors.length,
      greaterThanOrEqualTo(30),
      reason: '塔层数据应至少覆盖 30 层,遍历才有意义',
    );

    var floor30WardCount = 0;
    var otherFloorsChecked = 0;
    for (final f in repo.towerFloors) {
      for (final e in f.enemyTeam) {
        if (f.floorIndex == 30) {
          if (e.guardianWard != null) floor30WardCount++;
          continue;
        }
        otherFloorsChecked++;
        expect(
          e.guardianWard,
          isNull,
          reason:
              'floor ${f.floorIndex} 敌人 ${e.id} 不应配 guardianWard'
              '(guardianWard 是 floor30 专属机制)',
        );
      }
    }

    expect(
      floor30WardCount,
      1,
      reason: 'floor30 应恰好 1 个敌人(主 Boss)配置 guardianWard',
    );
    expect(
      otherFloorsChecked,
      greaterThan(0),
      reason: '非 floor30 敌人遍历不能是空集,否则上面的断言是空跑',
    );
  });

  test('三系锁死:floor30 主 Boss + 两护法均为 zongShi 境界', () async {
    final repo = await GameRepository.loadAllDefs(loader: fileLoader);
    final floor30 = repo.towerFloors.firstWhere((f) => f.floorIndex == 30);
    final boss = floor30.enemyTeam.firstWhere((e) => e.isBoss);
    final guardianA = floor30.enemyTeam.firstWhere(
      (e) => e.id == 'enemy_tower_30_cultist_a',
    );
    final guardianB = floor30.enemyTeam.firstWhere(
      (e) => e.id == 'enemy_tower_30_cultist_b',
    );

    expect(
      boss.realmTier,
      RealmTier.zongShi,
      reason: 'floor30 主 Boss 境界不应被护法结界/HP 校准连带偷改',
    );
    expect(
      guardianA.realmTier,
      RealmTier.zongShi,
      reason: '护法(左使)境界不应被提血校准连带偷改',
    );
    expect(
      guardianB.realmTier,
      RealmTier.zongShi,
      reason: '护法(右使)境界不应被提血校准连带偷改',
    );
  });

  test('护法 HP 校准值钉死:左使 9000 / 右使 8500', () async {
    final repo = await GameRepository.loadAllDefs(loader: fileLoader);
    final floor30 = repo.towerFloors.firstWhere((f) => f.floorIndex == 30);
    final boss = floor30.enemyTeam.firstWhere((e) => e.isBoss);
    final guardianA = floor30.enemyTeam.firstWhere(
      (e) => e.id == 'enemy_tower_30_cultist_a',
    );
    final guardianB = floor30.enemyTeam.firstWhere(
      (e) => e.id == 'enemy_tower_30_cultist_b',
    );

    expect(guardianA.baseHp, 9000, reason: 'Task 5 平衡校准值(左使),漂移需人工复核');
    expect(guardianB.baseHp, 8500, reason: 'Task 5 平衡校准值(右使),漂移需人工复核');
    // 双重保险:即使校准值未来微调,护法 HP 也应保持在原初值(4200/4000)
    // 与 Boss HP 之间的合理区间内。
    expect(guardianA.baseHp, greaterThan(4200));
    expect(guardianB.baseHp, greaterThan(4000));
    expect(guardianA.baseHp, lessThan(boss.baseHp));
    expect(guardianB.baseHp, lessThan(boss.baseHp));
  });

  test('招式倍率红线:floor30 相关招式 powerMultiplier <= 8000(轻量复核)', () async {
    final repo = await GameRepository.loadAllDefs(loader: fileLoader);
    final floor30 = repo.towerFloors.firstWhere((f) => f.floorIndex == 30);

    final floor30SkillIds = <String>{
      for (final e in floor30.enemyTeam) ...e.skillIds,
    };
    expect(floor30SkillIds, isNotEmpty, reason: 'floor30 敌人应至少引用一个招式,遍历才有意义');

    // 全局红线已由 GameRepository._enforceEncounterSkillRedLines 在
    // loadAllDefs 内对全部 skillDefs 强制校验(见 lib/data/game_repository.dart
    // 附近 GDD §5.4 max_skill_multiplier=8000 注释);loadAllDefs 未抛异常即
    // 说明该红线已过。此处仅对 floor30 实际引用的招式做一次显式复核,
    // 确认 Task 5 的数值校准(仅改 baseHp/damageTakenMult)没有连带动到招式倍率。
    for (final skillId in floor30SkillIds) {
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
