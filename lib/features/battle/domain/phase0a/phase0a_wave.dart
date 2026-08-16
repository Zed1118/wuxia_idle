import 'phase0a_combat_model.dart';

/// 战斗终局三态:全场至多一次翻转离开 ongoing(唯一终局)。
enum Phase0aBattleOutcome { ongoing, victory, defeat }

/// 一波敌人的不可变配置(波次/终局状态机的 domain 值对象)。
///
/// 构造期 fail-fast:空波、波内混入非 enemy side actor 一律拒绝;
/// 敌人列表做防御性不可修改副本,外部 list 构造后 mutation 不得污染
/// 同 seed 回放(沿 `Phase0aDamageSnapshot` 体例)。
final class Phase0aWave {
  Phase0aWave({required List<Phase0aActor> enemies})
    : enemies = _checkedEnemies(enemies);

  /// 本波敌人(不可修改副本,仅 enemy side,非空)。
  final List<Phase0aActor> enemies;

  static List<Phase0aActor> _checkedEnemies(List<Phase0aActor> enemies) {
    if (enemies.isEmpty) {
      throw ArgumentError.value(enemies, 'enemies', '波次敌人列表不得为空');
    }
    for (final enemy in enemies) {
      if (enemy.side != Phase0aSide.enemy) {
        throw ArgumentError.value(
          enemy.id,
          'enemies',
          '波次内 actor 必须为 enemy side',
        );
      }
    }
    return List.unmodifiable(List.of(enemies));
  }
}
