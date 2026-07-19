import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// C1.3.2 Slice C：断魂庄敌队引用完整性加载期红线（design §8.2「敌人/招式引用不得悬空」）。
///
/// 现有 enforce* 只迭代 stageDefs+towerFloors，不覆盖 gauntlet 敌队；本批补
/// `_enforceGauntletEnemyRedLines`。走 brokenLoader 注入悬空引用，断言 loadAllDefs
/// fail-fast（沿 skill_qi_redline_test 体例）。
void main() {
  tearDown(GameRepository.resetForTest);

  Future<GameRepository> load([Future<String> Function(String)? loader]) =>
      GameRepository.loadAllDefs(
        loader: loader ?? (path) async => File(path).readAsString(),
      );

  Future<String> Function(String) mutateGauntlet(String from, String to) =>
      (path) async {
        final original = await File(path).readAsString();
        if (path != 'data/boss_gauntlets.yaml') return original;
        return original.replaceFirst(from, to);
      };

  test('happy path：真实 boss_gauntlets.yaml 敌队引用自洽，不抛', () async {
    await load(); // 不抛即通过
  });

  test('chargeSkillId 不在 skillIds → fail-fast', () {
    expect(
      load(
        mutateGauntlet(
          'chargeSkillId: skill_suo_mai_zhen',
          'chargeSkillId: skill_ghost_charge',
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('guardianIds 引用非本队 id → fail-fast', () {
    // 首个 enemy_gauntlet_zhizhang_a 出现在护阵 guardianIds（庄客 def 之前）→
    // replaceFirst 改护法引用为悬空 id，庄客 def 的 id 不变 = 单侧悬空。
    expect(
      load(mutateGauntlet('enemy_gauntlet_zhizhang_a', 'enemy_gauntlet_ghost')),
      throwsA(isA<StateError>()),
    );
  });

  test('bossPhase unlockSkillIds 引用不存在的招 → fail-fast', () {
    expect(
      load(
        mutateGauntlet(
          'skill_yinrou_changlian_fang_skill',
          'skill_ghost_phase',
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('敌人 skillIds 引用不存在的招 → fail-fast', () {
    // 苏无咎独有的非 charge 招（青衣护院无 ult），首现于其 skillIds → 干净测
    // skillIds 存在性，不牵连 chargeSkillId 校验。
    expect(
      load(mutateGauntlet('skill_lingqiao_jichu_ult', 'skill_ghost_in_list')),
      throwsA(isA<StateError>()),
    );
  });

  test('关次 enemy_team_id 无对应敌队定义 → fail-fast', () {
    // 首个 gauntlet_su_wujiu 出现在 stages（enemy_teams key 之前）→
    // replaceFirst 改关次引用为悬空 team id，敌队定义 key 不变。
    expect(
      load(mutateGauntlet('gauntlet_su_wujiu', 'gauntlet_ghost_team')),
      throwsA(isA<StateError>()),
    );
  });

  test('敌人 baseHp 超过生产 Boss HP cap → fail-fast', () {
    expect(
      load(mutateGauntlet('baseHp: 42000', 'baseHp: 60001')),
      throwsA(isA<StateError>()),
    );
  });

  test('敌人 baseAttack 超过保守攻击 cap → fail-fast', () {
    expect(
      load(mutateGauntlet('baseAttack: 1100', 'baseAttack: 2001')),
      throwsA(isA<StateError>()),
    );
  });
}
