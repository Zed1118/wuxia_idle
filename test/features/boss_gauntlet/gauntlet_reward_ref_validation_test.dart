import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

/// C2.4a：断魂庄通关奖励引用完整性加载期红线（§6.2/§8.2「引用不得悬空」）。
/// 走 brokenLoader 注入悬空引用，断言 loadAllDefs fail-fast（沿 enemy_validation 体例）。
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

  test('happy path：真实奖励引用（秘籍 + 三候选装备）自洽，不抛', () async {
    await load();
  });

  test('reward_candidate_equipment_id 悬空 → fail-fast', () {
    expect(
      load(
        mutateGauntlet(
          'weapon_haojiahuo_qing_feng_jian',
          'weapon_ghost_reward_xxx',
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('first_clear_reward_skill_id 悬空 → fail-fast', () {
    expect(
      load(
        mutateGauntlet(
          'first_clear_reward_skill_id: skill_suo_mai_zhen',
          'first_clear_reward_skill_id: skill_ghost_manual_xxx',
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });
}
