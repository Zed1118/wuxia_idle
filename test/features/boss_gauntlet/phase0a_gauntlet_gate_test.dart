import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_combat_selector.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/phase0a_gauntlet_gate.dart';

/// Phase 0A 断魂庄灰度门 + 战斗路径选择器契约测试。
///
/// 冻结接口：`Phase0aGauntletGate.enabled` / `shouldUsePhase0a(memberCount:)`
/// 与 `gauntletCombatPathFor(memberCount:)`。断言聚焦灰度路线：默认关走旧
/// 3v3；灰度开 + 单成员走 Phase 0A；2/3 成员回落旧 runner；非法成员数
/// fail-fast。开关经 `testOverride` 注入，tearDown 复原。
void main() {
  tearDown(() => Phase0aGauntletGate.testOverride = null);

  group('Phase0aGauntletGate 灰度门', () {
    test('默认关闭', () {
      expect(Phase0aGauntletGate.enabled, isFalse);
    });

    test('testOverride 控制开关并在 tearDown 复原', () {
      Phase0aGauntletGate.testOverride = true;
      expect(Phase0aGauntletGate.enabled, isTrue);
      Phase0aGauntletGate.testOverride = false;
      expect(Phase0aGauntletGate.enabled, isFalse);
    });

    test('灰度开启：仅单成员走 Phase 0A，历史多成员回落', () {
      Phase0aGauntletGate.testOverride = true;
      expect(Phase0aGauntletGate.shouldUsePhase0a(memberCount: 1), isTrue);
      expect(Phase0aGauntletGate.shouldUsePhase0a(memberCount: 2), isFalse);
      expect(Phase0aGauntletGate.shouldUsePhase0a(memberCount: 3), isFalse);
    });
  });

  group('gauntletCombatPathFor 战斗路径选择器', () {
    test('默认关闭：所有会话走旧 3v3', () {
      expect(
        gauntletCombatPathFor(memberCount: 1),
        GauntletCombatPath.legacy3v3,
      );
      expect(
        gauntletCombatPathFor(memberCount: 2),
        GauntletCombatPath.legacy3v3,
      );
      expect(
        gauntletCombatPathFor(memberCount: 3),
        GauntletCombatPath.legacy3v3,
      );
    });

    test('灰度开启 + 单成员 → Phase 0A', () {
      Phase0aGauntletGate.testOverride = true;
      expect(gauntletCombatPathFor(memberCount: 1), GauntletCombatPath.phase0a);
    });

    test('灰度开启 + 2/3 成员回落旧 runner', () {
      Phase0aGauntletGate.testOverride = true;
      expect(
        gauntletCombatPathFor(memberCount: 2),
        GauntletCombatPath.legacy3v3,
      );
      expect(
        gauntletCombatPathFor(memberCount: 3),
        GauntletCombatPath.legacy3v3,
      );
    });

    test('非法成员数 fail-fast', () {
      expect(
        () => gauntletCombatPathFor(memberCount: 0),
        throwsA(isA<StateError>()),
      );
      expect(
        () => gauntletCombatPathFor(memberCount: 4),
        throwsA(isA<StateError>()),
      );
    });
  });
}
