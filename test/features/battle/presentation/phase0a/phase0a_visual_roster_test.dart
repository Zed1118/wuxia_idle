import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_stage_content_mapper.dart';
import 'package:wuxia_idle/features/battle/presentation/phase0a/phase0a_visual_roster.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_skill_loadout.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';

import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

/// D10 动态视觉名册红测:
/// ① [Phase0aVisualRoster.fromCombatants] 在 runtime 状态变化前为全量
///    combatant(reserve / warning / active 等价输入)各构造恰一个视觉;
/// ② 玩家沿用祖师战斗兜底图、敌人取 snapshot iconPath;
/// ③ 空 asset、重复 actor id、玩家缺失/重复均稳定 fail closed;
/// ④ [Phase0aVisualRoster.fromMapping] 委托后输出口径不变(真实主线关回归)。

Phase0aCombatantInput enemy(
  String actorId, {
  String? iconPath = 'assets/enemies/test_enemy.png',
  bool isBoss = false,
  String name = 'test enemy',
}) => Phase0aCombatantInput(
  actorId: actorId,
  snapshot: testCombatantSnapshot(
    name: name,
    iconPath: iconPath,
    isBoss: isBoss,
  ),
);

Phase0aCombatantInput player(String actorId) => Phase0aCombatantInput(
  actorId: actorId,
  snapshot: testCombatantSnapshot(
    name: 'test player',
    iconPath: 'assets/should_not_be_used.png',
  ),
);

void main() {
  group('fromCombatants 全量合同', () {
    test('为每个传入 combatant 构造恰一个视觉(含 reserve/warning/active 全量输入)', () {
      final roster = Phase0aVisualRoster.fromCombatants(
        playerId: 'player',
        combatants: [
          player('player'),
          enemy('reserve_a', name: 'reserve unit'),
          enemy('warning_b', name: 'warning unit'),
          enemy('active_c', name: 'active unit'),
          enemy('boss_d', name: 'boss unit', isBoss: true),
        ],
      );

      expect(
        roster.visualFor('player').assetPath,
        WuxiaUi.battleFounderFallback,
      );
      expect(roster.visualFor('player').name, 'test player');
      expect(roster.visualFor('player').isElite, isFalse);

      for (final actorId in const ['reserve_a', 'warning_b', 'active_c']) {
        final visual = roster.visualFor(actorId);
        expect(visual.assetPath, 'assets/enemies/test_enemy.png');
        expect(visual.isElite, isFalse);
      }
      expect(roster.visualFor('reserve_a').name, 'reserve unit');
      expect(roster.visualFor('warning_b').name, 'warning unit');
      expect(roster.visualFor('active_c').name, 'active unit');

      final bossVisual = roster.visualFor('boss_d');
      expect(bossVisual.isElite, isTrue);
      expect(bossVisual.assetPath, 'assets/enemies/test_enemy.png');
    });

    test('玩家忽略 snapshot iconPath,固定走祖师战斗兜底图', () {
      final roster = Phase0aVisualRoster.fromCombatants(
        playerId: 'player',
        combatants: [player('player'), enemy('foe')],
      );
      expect(
        roster.visualFor('player').assetPath,
        WuxiaUi.battleFounderFallback,
      );
    });
  });

  group('fromCombatants fail closed', () {
    test('敌人 asset 为 null 时抛稳定 StateError', () {
      expect(
        () => Phase0aVisualRoster.fromCombatants(
          playerId: 'player',
          combatants: [player('player'), enemy('foe', iconPath: null)],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Phase0a roster requires a non-empty asset: actor foe',
          ),
        ),
      );
    });

    test('敌人 asset 为空串时抛稳定 StateError', () {
      expect(
        () => Phase0aVisualRoster.fromCombatants(
          playerId: 'player',
          combatants: [
            player('player'),
            enemy('foe', iconPath: ''),
          ],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Phase0a roster requires a non-empty asset: actor foe',
          ),
        ),
      );
    });

    test('敌人 asset 为空白时抛稳定 StateError', () {
      expect(
        () => Phase0aVisualRoster.fromCombatants(
          playerId: 'player',
          combatants: [
            player('player'),
            enemy('foe', iconPath: '  \t'),
          ],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Phase0a roster requires a non-empty asset: actor foe',
          ),
        ),
      );
    });

    test('空白 player id 抛稳定 StateError', () {
      expect(
        () => Phase0aVisualRoster.fromCombatants(
          playerId: ' \t',
          combatants: [player('player')],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Phase0a roster requires a non-empty player id',
          ),
        ),
      );
    });

    test('空白 actor id 抛稳定 StateError', () {
      expect(
        () => Phase0aVisualRoster.fromCombatants(
          playerId: 'player',
          combatants: [player('player'), enemy(' \t')],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Phase0a roster requires a non-empty actor id',
          ),
        ),
      );
    });

    test('重复 actor id 抛稳定 StateError', () {
      expect(
        () => Phase0aVisualRoster.fromCombatants(
          playerId: 'player',
          combatants: [player('player'), enemy('foe'), enemy('foe')],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Phase0a roster received a duplicate actor id: foe',
          ),
        ),
      );
    });

    test('玩家缺失抛稳定 StateError', () {
      expect(
        () => Phase0aVisualRoster.fromCombatants(
          playerId: 'player',
          combatants: [enemy('foe_a'), enemy('foe_b')],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Phase0a roster is missing the player: player',
          ),
        ),
      );
    });

    test('玩家重复按重复 actor id fail closed', () {
      expect(
        () => Phase0aVisualRoster.fromCombatants(
          playerId: 'player',
          combatants: [player('player'), player('player')],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Phase0a roster received a duplicate actor id: player',
          ),
        ),
      );
    });

    test('visualFor 查未登记 actor 抛稳定 StateError', () {
      final roster = Phase0aVisualRoster.fromCombatants(
        playerId: 'player',
        combatants: [player('player'), enemy('foe')],
      );
      expect(
        () => roster.visualFor('ghost'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Missing Phase0a visual for actor: ghost',
          ),
        ),
      );
    });
  });

  group('fromMapping 委托兼容(真实主线关回归)', () {
    test('stage_01_01 玩家兜底图与敌人 iconPath 口径不变', () {
      return loadTestGameRepository().then((repo) {
        final mapping = Phase0aStageContentMapper.map(
          stage: repo.getStage('stage_01_01'),
          playerSnapshot: testCombatantSnapshot(
            characterId: 1,
            name: '兼容玩家',
            realmTier: RealmTier.xueTu,
            realmLayer: RealmLayer.qiMeng,
            school: TechniqueSchool.gangMeng,
            maxHp: 15000,
            skillLoadout: CombatantSkillLoadout(
              basicAttack: repo.skillDefs['skill_gangmeng_jichu_basic'],
            ),
          ),
          numbers: repo.numbers,
        );

        final roster = Phase0aVisualRoster.fromMapping(mapping);

        expect(
          roster.visualFor(mapping.initialState.player.id).assetPath,
          WuxiaUi.battleFounderFallback,
        );
        for (final combatant in mapping.combatants) {
          if (combatant.actorId == mapping.initialState.player.id) continue;
          final visual = roster.visualFor(combatant.actorId);
          expect(visual.name, combatant.snapshot.name);
          expect(visual.assetPath, combatant.snapshot.iconPath);
          expect(visual.isElite, combatant.snapshot.isBoss);
        }
      });
    });
  });
}
