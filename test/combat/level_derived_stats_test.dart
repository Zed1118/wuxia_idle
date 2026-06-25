import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/derived_stats.dart';

/// 第八阶段 · 角色等级 Lv 对派生属性的小幅有界加成(TDD)。
///
/// 注入读 `Character.level`:bonus = (level-1) × per_level(level 1 = 0 加成)。
/// maxHp/内力经 §5.4 clamp 硬守红线;速度无红线。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return f.readAsString();
  }

  setUp(() async {
    await GameRepository.loadAllDefs(loader: fileLoader);
  });
  tearDown(GameRepository.resetForTest);

  Character mkChar({int level = 1}) => Character.create(
        name: '测试',
        realmTier: RealmTier.erLiu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.xunChang,
        lineageRole: LineageRole.founder,
        createdAt: DateTime(2026, 6, 26),
        internalForce: 1000,
        internalForceMax: 3000,
        level: level,
      )..mainTechniqueId = null;

  test('maxHp:level 11 比 level 1 多 10×bonus_max_hp_per_level', () {
    final n = GameRepository.instance.numbers;
    final lo = CharacterDerivedStats.maxHp(mkChar(level: 1), [], n);
    final hi = CharacterDerivedStats.maxHp(mkChar(level: 11), [], n);
    expect(hi - lo, 10 * n.level.bonusMaxHpPerLevel);
  });

  test('maxHp:level 1 无加成(新角色不白给)', () {
    final n = GameRepository.instance.numbers;
    // level 1 与「假想无 Lv 系统」一致 → 加成项 = 0。
    final atL1 = CharacterDerivedStats.maxHp(mkChar(level: 1), [], n);
    final atL2 = CharacterDerivedStats.maxHp(mkChar(level: 2), [], n);
    expect(atL2 - atL1, n.level.bonusMaxHpPerLevel);
  });

  test('内力上限:level 加成进 base 后再 clamp', () {
    final n = GameRepository.instance.numbers;
    final lo = CharacterDerivedStats.internalForceMaxWithLineage(
        mkChar(level: 1), [], n);
    final hi = CharacterDerivedStats.internalForceMaxWithLineage(
        mkChar(level: 21), [], n);
    // base 3000 远低于红线 15000,无 clamp 截断 → 差 = 20×bonus。
    expect(hi - lo, 20 * n.level.bonusInternalForceMaxPerLevel);
  });

  test('速度:level 加成线性叠加(无红线)', () {
    final n = GameRepository.instance.numbers;
    final tech = Technique.create(
      defId: 'test_tech',
      ownerCharacterId: 1,
      tier: TechniqueTier.ruMenGong,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime(2026, 1, 1),
    );
    final lo = CharacterDerivedStats.speed(mkChar(level: 1), [], tech, n);
    final hi = CharacterDerivedStats.speed(mkChar(level: 11), [], tech, n);
    expect(hi - lo, 10 * n.level.bonusSpeedPerLevel);
  });

  test('红线安全:满 Lv 100 + 高内力 base 仍 ≤ §5.4 血量红线(clamp 兜底)', () {
    final n = GameRepository.instance.numbers;
    final c = mkChar(level: 100)
      ..internalForce = 15000
      ..attributes.constitution = 10;
    final hp = CharacterDerivedStats.maxHp(c, [], n);
    expect(hp, lessThanOrEqualTo(n.combat.redLines.playerHpMax));
  });
}
