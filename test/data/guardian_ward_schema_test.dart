import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';

void main() {
  group('GuardianWardDef', () {
    test('EnemyDef.fromYaml 解析 guardianWard', () {
      final e = EnemyDef.fromYaml({
        'id': 'boss',
        'name': 'B',
        'realmTier': 'zongShi',
        'realmLayer': 'dengFeng',
        'school': 'yinRou',
        'baseHp': 42000,
        'baseAttack': 2800,
        'baseSpeed': 245,
        'skillIds': <String>[],
        'iconPath': 'x.png',
        'isBoss': true,
        'guardianWard': {
          'damageTakenMult': 0.15,
          'guardianIds': ['g_a', 'g_b'],
        },
      });
      expect(e.guardianWard, isNotNull);
      expect(e.guardianWard!.damageTakenMult, 0.15);
      expect(e.guardianWard!.guardianIds, ['g_a', 'g_b']);
    });
    test('无 guardianWard → null（零回归）', () {
      final e = EnemyDef.fromYaml({
        'id': 'x',
        'name': 'X',
        'realmTier': 'xueTu',
        'realmLayer': 'qiMeng',
        'school': 'gangMeng',
        'baseHp': 100,
        'baseAttack': 10,
        'baseSpeed': 100,
        'skillIds': <String>[],
        'iconPath': 'x.png',
        'isBoss': false,
      });
      expect(e.guardianWard, isNull);
    });
  });

  group('enforceGuardianWardReferences', () {
    EnemyDef boss(List<String> gids, {double mult = 0.15}) =>
        EnemyDef.fromYaml({
          'id': 'boss',
          'name': 'B',
          'realmTier': 'zongShi',
          'realmLayer': 'dengFeng',
          'school': 'yinRou',
          'baseHp': 42000,
          'baseAttack': 2800,
          'baseSpeed': 245,
          'skillIds': <String>[],
          'iconPath': 'x.png',
          'isBoss': true,
          'guardianWard': {'damageTakenMult': mult, 'guardianIds': gids},
        });
    EnemyDef minion(String id) => EnemyDef.fromYaml({
      'id': id,
      'name': id,
      'realmTier': 'zongShi',
      'realmLayer': 'jingTong',
      'school': 'gangMeng',
      'baseHp': 4000,
      'baseAttack': 700,
      'baseSpeed': 220,
      'skillIds': <String>[],
      'iconPath': 'x.png',
      'isBoss': false,
    });
    test('guardianIds 全在 team → 不抛', () {
      GameRepository.enforceGuardianWardReferences([
        boss(['g_a']),
        minion('g_a'),
      ]);
    });
    test('guardianIds 悬空 → 抛 StateError(含坏 id)', () {
      expect(
        () => GameRepository.enforceGuardianWardReferences([
          boss(['ghost']),
        ]),
        throwsA(isA<StateError>()),
      );
    });
    test('damageTakenMult 越界(>1) → 抛', () {
      expect(
        () => GameRepository.enforceGuardianWardReferences([
          boss(['g'], mult: 1.5),
          minion('g'),
        ]),
        throwsA(isA<StateError>()),
      );
    });
    test('damageTakenMult == 0 → 抛', () {
      expect(
        () => GameRepository.enforceGuardianWardReferences([
          boss(['g'], mult: 0),
          minion('g'),
        ]),
        throwsA(isA<StateError>()),
      );
    });
    test('damageTakenMult 负值 → 抛', () {
      expect(
        () => GameRepository.enforceGuardianWardReferences([
          boss(['g'], mult: -0.2),
          minion('g'),
        ]),
        throwsA(isA<StateError>()),
      );
    });
    test('guardianIds 为空 → 抛', () {
      expect(
        () => GameRepository.enforceGuardianWardReferences([boss(<String>[])]),
        throwsA(isA<StateError>()),
      );
    });
    test('guardianIds 含自身 id → 抛（自引用）', () {
      expect(
        () => GameRepository.enforceGuardianWardReferences([
          boss(['boss']),
        ]),
        throwsA(isA<StateError>()),
      );
    });
    test('location 前缀进入错误消息', () {
      expect(
        () => GameRepository.enforceGuardianWardReferences([
          boss(['ghost']),
        ], location: 'tower floor 30 '),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('tower floor 30 '),
          ),
        ),
      );
    });
  });
}
