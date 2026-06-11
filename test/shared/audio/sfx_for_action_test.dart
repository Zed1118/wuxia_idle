import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';

/// 造一个命中结果（按 AttackResult 真实全参构造器，无 .normal 工厂）。
AttackResult _hit({required bool isCritical}) => AttackResult(
      finalDamage: 1500,
      mainDamage: 1500,
      quakeDamage: 0,
      isCritical: isCritical,
      isDodged: false,
      schoolCounterMultiplier: 1.0,
      realmDiffAttackerMod: 1.0,
      realmDiffDefenderMod: 1.0,
      cultivationMultiplier: 1.0,
      criticalMultiplier: isCritical ? 1.5 : 1.0,
      defenseRate: 0.15,
      evasionRate: 0.05,
      appliedEffects: const <String>[],
      formulaBreakdown: 'test',
    );

/// 造一个 BattleAction（attackResult 可空）。
BattleAction _action({AttackResult? attackResult}) => BattleAction(
      tick: 0,
      actorId: 1,
      targetId: 2,
      attackResult: attackResult,
      description: 'test',
    );

void main() {
  test('无 attackResult → null（非攻击 action 不出声）', () {
    final a = _action(attackResult: null);
    expect(sfxForAction(action: a, isUltimate: false), isNull);
  });

  test('闪避 → null', () {
    final a = _action(
      attackResult: AttackResult.dodged(evasionRate: 0.1, breakdown: 'dodge'),
    );
    expect(sfxForAction(action: a, isUltimate: false), isNull);
  });

  test('大招优先 → battleUlt', () {
    final a = _action(attackResult: _hit(isCritical: false));
    expect(sfxForAction(action: a, isUltimate: true), SfxId.battleUlt);
  });

  test('暴击 → battleCrit', () {
    final a = _action(attackResult: _hit(isCritical: true));
    expect(sfxForAction(action: a, isUltimate: false), SfxId.battleCrit);
  });

  test('普通命中 → battleHit', () {
    final a = _action(attackResult: _hit(isCritical: false));
    expect(sfxForAction(action: a, isUltimate: false), SfxId.battleHit);
  });

  group('battleHitAssetPath 平A 按单位变体映射', () {
    test('敌我 6 槽位 → 6 个不同变体文件', () {
      final paths = <String>{};
      for (final side in [0, 1]) {
        for (final slot in [0, 1, 2]) {
          paths.add(battleHitAssetPath(teamSide: side, slotIndex: slot));
        }
      }
      expect(paths, hasLength(6));
      expect(
        paths,
        everyElement(matches(r'^audio/sfx/battleHit_[01]_[012]\.mp3$')),
      );
    });

    test('越界 clamp 不产出缺失文件路径（群战多槽/异常 side 兜底）', () {
      expect(
        battleHitAssetPath(teamSide: 2, slotIndex: 7),
        'audio/sfx/battleHit_1_2.mp3',
      );
      expect(
        battleHitAssetPath(teamSide: -1, slotIndex: -1),
        'audio/sfx/battleHit_0_0.mp3',
      );
    });
  });
}
