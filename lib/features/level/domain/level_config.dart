/// 第八阶段 · 角色等级 Lv 配置(numbers.yaml `level` 段)。
///
/// 升级曲线 [expToNext]：从 [level] 升到 level+1 的 levelExp 消费 =
/// `expToNextBase + (level-1)*expToNextPerLevel`(随等级线性递增)。
///
/// 三项 per-level 加成由 `CharacterDerivedStats` 注入(力量模型见
/// `docs/spec/2026-06-26-level-difficulty-lootpreview-design.md` A 块):
/// hp/内力经 §5.4 clamp 硬守红线,速度无红线。**初值保守,待真机校**。
class LevelConfig {
  final int maxLevel;
  final int expToNextBase;
  final int expToNextPerLevel;

  /// 每级 maxHp 加成(加在 §5.4 血量 clamp 前)。
  final int bonusMaxHpPerLevel;

  /// 每级内力上限加成(加在 §5.4 内力 clamp 前)。
  final int bonusInternalForceMaxPerLevel;

  /// 每级出手速度加成(速度无红线)。
  final int bonusSpeedPerLevel;

  const LevelConfig({
    required this.maxLevel,
    required this.expToNextBase,
    required this.expToNextPerLevel,
    required this.bonusMaxHpPerLevel,
    required this.bonusInternalForceMaxPerLevel,
    required this.bonusSpeedPerLevel,
  });

  /// 从 [level] 升到 level+1 的 levelExp 消费。level≥maxLevel 时无意义(caller 不调)。
  int expToNext(int level) => expToNextBase + (level - 1) * expToNextPerLevel;

  /// 容缺省解析(仿 `InjuryConfig.fromYaml`):缺段/缺键走默认(=生产初值),
  /// 真 numbers.yaml `level` 段覆盖,旧 fixture 不带该段不崩。
  factory LevelConfig.fromYaml(Map<String, dynamic> y) => LevelConfig(
        maxLevel: (y['max_level'] as num?)?.toInt() ?? 100,
        expToNextBase: (y['exp_to_next_base'] as num?)?.toInt() ?? 200, // 缺省=生产初值
        expToNextPerLevel: (y['exp_to_next_per_level'] as num?)?.toInt() ?? 80, // 缺省=生产初值
        bonusMaxHpPerLevel: (y['bonus_max_hp_per_level'] as num?)?.toInt() ?? 15,
        bonusInternalForceMaxPerLevel:
            (y['bonus_internal_force_max_per_level'] as num?)?.toInt() ?? 8,
        bonusSpeedPerLevel: (y['bonus_speed_per_level'] as num?)?.toInt() ?? 1,
      );
}
