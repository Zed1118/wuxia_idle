import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/level/domain/level_config.dart';
import 'package:wuxia_idle/features/level/application/level_service.dart';

/// 第八阶段 · 角色等级 Lv 升级纯逻辑 TDD。
///
/// 升级曲线 expToNext(L) = base + (L-1)*perLevel(从 L 升到 L+1 的消费)。
/// 测试用简单配置 base=100/perLevel=50/maxLevel=5 便于断言。
void main() {
  late LevelConfig cfg;

  setUp(() {
    cfg = const LevelConfig(
      maxLevel: 5,
      expToNextBase: 100,
      expToNextPerLevel: 50,
      bonusMaxHpPerLevel: 15,
      bonusInternalForceMaxPerLevel: 8,
      bonusSpeedPerLevel: 1,
    );
  });

  Character mkChar() => Character.create(
        name: '测试',
        realmTier: RealmTier.sanLiu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.xunChang,
        lineageRole: LineageRole.founder,
        createdAt: DateTime(2026, 6, 26),
      );

  test('expToNext 随等级递增:L1=100 / L2=150 / L3=200', () {
    expect(cfg.expToNext(1), 100);
    expect(cfg.expToNext(2), 150);
    expect(cfg.expToNext(3), 200);
  });

  test('delta<=0 不改 level / levelExp', () {
    final ch = mkChar();
    final r = LevelService.applyLevelExp(ch, 0, config: cfg);
    expect(ch.level, 1);
    expect(ch.levelExp, 0);
    expect(r.levelsGained, 0);
    final r2 = LevelService.applyLevelExp(ch, -50, config: cfg);
    expect(ch.levelExp, 0);
    expect(r2.levelsGained, 0);
  });

  test('未达阈值:levelExp 累积不升级', () {
    final ch = mkChar();
    final r = LevelService.applyLevelExp(ch, 60, config: cfg);
    expect(ch.level, 1);
    expect(ch.levelExp, 60);
    expect(r.levelsGained, 0);
  });

  test('正好达阈值:升 1 级,levelExp 归 0', () {
    final ch = mkChar();
    final r = LevelService.applyLevelExp(ch, 100, config: cfg);
    expect(ch.level, 2);
    expect(ch.levelExp, 0);
    expect(r.levelsGained, 1);
    expect(r.levelBefore, 1);
    expect(r.levelAfter, 2);
  });

  test('一次大 delta 连升多级,余数正确', () {
    final ch = mkChar();
    // L1→2 需 100,L2→3 需 150,L3→4 需 200。给 100+150+30=280 → 升到 L3 余 30。
    final r = LevelService.applyLevelExp(ch, 280, config: cfg);
    expect(ch.level, 3);
    expect(ch.levelExp, 30);
    expect(r.levelsGained, 2);
  });

  test('封顶 maxLevel 后不再升级,levelExp 仍累加不崩', () {
    final ch = mkChar();
    // 喂巨量 EXP 直接顶到 maxLevel=5。
    LevelService.applyLevelExp(ch, 100000, config: cfg);
    expect(ch.level, 5);
    final expAtCap = ch.levelExp;
    final r = LevelService.applyLevelExp(ch, 500, config: cfg);
    expect(ch.level, 5, reason: '封顶不再升');
    expect(ch.levelExp, expAtCap + 500, reason: '封顶后 levelExp 仍累加');
    expect(r.levelsGained, 0);
  });

  test('新建角色默认 level=1 / levelExp=0', () {
    final ch = mkChar();
    expect(ch.level, 1);
    expect(ch.levelExp, 0);
  });
}
