import '../../../core/domain/character.dart';
import '../domain/level_config.dart';

/// 第八阶段 · 角色等级 Lv 升级服务(纯逻辑)。
///
/// 战斗 victory 现有 EXP 事件并行喂 [Character.levelExp](与境界 experience
/// 同源不同账),本服务消费 levelExp while-loop 升 [Character.level] 至
/// `config.maxLevel` 封顶。封顶后 levelExp 仍累加不破坏(仿
/// [CharacterAdvancementService] 满级体例)。
///
/// **跨境界连续涨,不随境界突破重置**(境界是独立大门槛)。
class LevelService {
  LevelService._();

  /// 累加 [delta] levelExp 并 while-loop 升级。**副作用(in-place 写 [ch])**:
  /// `ch.levelExp += delta` + 升级时 `ch.level++` 并扣减对应阈值。
  ///
  /// [delta] ≤ 0 时 no-op(不改 level/levelExp)。
  static LevelUpResult applyLevelExp(
    Character ch,
    int delta, {
    required LevelConfig config,
  }) {
    final before = ch.level;
    if (delta <= 0) {
      return LevelUpResult(
        levelsGained: 0,
        levelBefore: before,
        levelAfter: before,
      );
    }

    ch.levelExp += delta;
    var gained = 0;
    while (ch.level < config.maxLevel &&
        ch.levelExp >= config.expToNext(ch.level)) {
      ch.levelExp -= config.expToNext(ch.level);
      ch.level++;
      gained++;
    }

    return LevelUpResult(
      levelsGained: gained,
      levelBefore: before,
      levelAfter: ch.level,
    );
  }
}

/// [LevelService.applyLevelExp] 返回值。caller 用 [didLevelUp] 决定战斗内
/// 「晋」题字(D2)/ 战后 UI 升级 banner。
class LevelUpResult {
  final int levelsGained;
  final int levelBefore;
  final int levelAfter;

  const LevelUpResult({
    required this.levelsGained,
    required this.levelBefore,
    required this.levelAfter,
  });

  bool get didLevelUp => levelsGained > 0;
}
