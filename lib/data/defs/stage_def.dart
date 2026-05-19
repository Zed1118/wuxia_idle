import '../../core/domain/enums.dart';
import 'drop_entry.dart';

/// 关卡配置（data_schema.md §5.4，纯 Dart，不入 Isar）。
///
/// `enemyTeam` 长度 0–3：剧情关卡可空，普通关卡 1–3 个敌人。
///
/// 掉落机制（phase2_tasks T27）：
///   - `dropTable` 是带 dropChance 的精细化掉落表，由 `DropService.rollDrops` 消费
///   - `dropEquipmentDefIds` / `dropItemDefIds` 是 Phase 1 占位的简化列表，
///     **当前未被任何 service 使用**；保留只为 yaml 向后兼容，Phase 5 整理时再清
class StageDef {
  final String id;
  final String name;
  final StageType stageType;
  final int? chapterIndex;
  final int? towerLayer;
  final RealmTier requiredRealm;
  final List<EnemyDef> enemyTeam;
  final bool isBossStage;

  /// 章节内顺序解锁：本关需要 prevStageId 已通关才能挑战；章节首关为 null。
  /// 必须与本关同 [chapterIndex]（[GameRepository._enforceRedLines] 校验）。
  final String? prevStageId;

  /// 进入关卡时播放的开场剧情 id（联结 `data/narratives/<id>.yaml`，
  /// 缺文件由 `NarrativeLoader` 兜底「[剧情待补]」）。
  final String? narrativeOpeningId;

  /// 战斗胜利后播放的剧情 id；战败不触发。
  final String? narrativeVictoryId;

  /// 战斗失败后播放的剧情 id（Phase 3 Week 5）；通常只在章末 Boss 关（4/5）配置，
  /// 章内普通关战败直接返回 stage list（缺文件由 NarrativeLoader 兜底）。
  final String? narrativeDefeatId;

  final List<String> dropEquipmentDefIds;
  final List<String> dropItemDefIds;
  final List<DropEntry> dropTable;
  final int baseExpReward;
  final double difficultyMultiplier;

  /// 场景生境(C-W14-2)。null = 未标(向后兼容旧 yaml + 测试 fixture)。
  /// 用于奇遇 [EncounterTrigger.biomeMinutes] 匹配维度 + 战斗 victory 喂奇遇
  /// recordKill 时附带 biome 累计(战斗 hook 当前只走 schoolKill 维度)。
  final EncounterBiome? biome;

  /// 天气/时段(C-W14-2)。null = 默认 clear 不喂(无累计)。配置时显式标
  /// `rain`/`snow`/`mist`/`night` 才会被 [EncounterTrigger.weatherMinutes] 看到。
  final EncounterWeather? weather;

  const StageDef({
    required this.id,
    required this.name,
    required this.stageType,
    this.chapterIndex,
    this.towerLayer,
    required this.requiredRealm,
    required this.enemyTeam,
    required this.isBossStage,
    this.prevStageId,
    this.narrativeOpeningId,
    this.narrativeVictoryId,
    this.narrativeDefeatId,
    required this.dropEquipmentDefIds,
    required this.dropItemDefIds,
    this.dropTable = const [],
    required this.baseExpReward,
    required this.difficultyMultiplier,
    this.biome,
    this.weather,
  });

  factory StageDef.fromYaml(Map<String, dynamic> y) {
    return StageDef(
      id: y['id'] as String,
      name: y['name'] as String,
      stageType: StageType.values.byName(y['stageType'] as String),
      chapterIndex: (y['chapterIndex'] as num?)?.toInt(),
      towerLayer: (y['towerLayer'] as num?)?.toInt(),
      requiredRealm: RealmTier.values.byName(y['requiredRealm'] as String),
      enemyTeam: ((y['enemyTeam'] as List?) ?? const [])
          .map((e) => EnemyDef.fromYaml(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
      isBossStage: y['isBossStage'] as bool? ?? false,
      prevStageId: y['prevStageId'] as String?,
      narrativeOpeningId: y['narrativeOpeningId'] as String?,
      narrativeVictoryId: y['narrativeVictoryId'] as String?,
      narrativeDefeatId: y['narrativeDefeatId'] as String?,
      dropEquipmentDefIds: List<String>.from(
        (y['dropEquipmentDefIds'] as List? ?? const []).map((e) => e as String),
      ),
      dropItemDefIds: List<String>.from(
        (y['dropItemDefIds'] as List? ?? const []).map((e) => e as String),
      ),
      dropTable: ((y['dropTable'] as List?) ?? const [])
          .map((e) => DropEntry.fromYaml(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
      baseExpReward: (y['baseExpReward'] as num).toInt(),
      difficultyMultiplier: (y['difficultyMultiplier'] as num).toDouble(),
      biome: (y['biome'] as String?) == null
          ? null
          : EncounterBiome.values.byName(y['biome'] as String),
      weather: (y['weather'] as String?) == null
          ? null
          : EncounterWeather.values.byName(y['weather'] as String),
    );
  }

  @override
  String toString() =>
      'StageDef(id=$id, type=${stageType.name}, '
      'requiredRealm=${requiredRealm.name}, enemies=${enemyTeam.length})';
}

/// 敌人配置，作为 [StageDef.enemyTeam] 的内嵌。Def 层不引入 Isar，
/// 因此这里是普通 plain class 而非 `@embedded`。
class EnemyDef {
  final String id;
  final String name;
  final RealmTier realmTier;
  final RealmLayer realmLayer;
  final TechniqueSchool school;
  final int baseHp;
  final int baseAttack;
  final int baseSpeed;
  final List<String> skillIds;
  final String iconPath;

  const EnemyDef({
    required this.id,
    required this.name,
    required this.realmTier,
    required this.realmLayer,
    required this.school,
    required this.baseHp,
    required this.baseAttack,
    required this.baseSpeed,
    required this.skillIds,
    required this.iconPath,
  });

  factory EnemyDef.fromYaml(Map<String, dynamic> y) {
    return EnemyDef(
      id: y['id'] as String,
      name: y['name'] as String,
      realmTier: RealmTier.values.byName(y['realmTier'] as String),
      realmLayer: RealmLayer.values.byName(y['realmLayer'] as String),
      school: TechniqueSchool.values.byName(y['school'] as String),
      baseHp: (y['baseHp'] as num).toInt(),
      baseAttack: (y['baseAttack'] as num).toInt(),
      baseSpeed: (y['baseSpeed'] as num).toInt(),
      skillIds: List<String>.from(
        (y['skillIds'] as List? ?? const []).map((e) => e as String),
      ),
      iconPath: y['iconPath'] as String,
    );
  }

  @override
  String toString() =>
      'EnemyDef(id=$id, name=$name, '
      'realm=${realmTier.name}/${realmLayer.name}, school=${school.name})';
}
