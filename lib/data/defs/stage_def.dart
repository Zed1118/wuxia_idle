import '../../core/domain/enums.dart';
import 'boss_phase_def.dart';
import 'drop_entry.dart';

/// 关卡配置（data_schema.md §5.4，纯 Dart，不入 Isar）。
///
/// `enemyTeam` 长度 0–3：剧情关卡可空，普通关卡 1–3 个敌人。
///
/// 掉落机制（phase2_tasks T27）：
///   - `dropTable` 是带 dropChance 的精细化掉落表，由 `DropService.rollDrops` 消费，
///     是唯一的 live 掉落来源（F5/2026-06-23：已删 Phase 1 占位的
///     `dropEquipmentDefIds` / `dropItemDefIds` 冗余简化列表，dropTable 为其超集）
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

  /// M4 Stage 3 美术(2026-05-21):战斗屏场景背景 png 路径。
  /// 仅主线核心关卡在 yaml 配置(章节开篇关 + 章末 BOSS 关);
  /// null 时 battle_screen 走 backgroundColor 兜底。
  final String? sceneBackgroundPath;

  /// 战斗机制地形(1.0 P3.1 §12.3,GDD v1.11)。
  /// 仅 `stageType: lightFoot` 关卡配置(LightFootStrategy 烘焙 terrain modifier
  /// 到 BattleCharacter critRate/evasionRate/defenseRate);其他 stageType null。
  final TerrainBiome? terrainBiome;

  /// 群战守城 wave 数(1.0 P3.2 §12.3,GDD v1.13)。
  /// 仅 `stageType: massBattle` 关卡配置(1-4 wave,wave_count=1 即单场群战、
  /// =N 即多波守城);其他 stageType null。MassBattleStrategy 循环消费。
  final int? massBattleWaveCount;

  /// 群战守城每 wave 敌人数(1.0 P3.2 §12.3,GDD v1.13)。
  /// 长度 = [massBattleWaveCount],每元素 5-7(玩家 3 vs 敌 5-7「以少胜多」语境)。
  /// 仅 `stageType: massBattle` 关卡配置;其他 stageType null。
  final List<int>? massBattleEnemyCounts;

  /// P1.2 §6 boss NPC 关联(GDD §12.1 江湖恩怨)。
  /// 仅 boss stage(`isBossStage: true`)配置 · null = 该 boss 无 NPC 身份(纯敌人)。
  ///
  /// UNUSED-PENDING-1.1(审计 D3 2026-06-24 · 与 B3 江湖恩怨同源):当前 5 处配置
  /// 0 读取——江湖恩怨整链 dormant(`NpcRelationService.upsert` 0 caller),需先在此
  /// 字段双写真 NPC 关系才激活(详 `npc_relation_service.dart` UNUSED-PENDING-1.1 头注)。
  /// 1.1+ 接入真 NPC schema 后映射 `NpcRelation.targetCharacterId`。故意延期留底,非死码误删。
  final String? npcId;

  /// P4.1 1.1 Q6B · Boss 战胜后招降配置(spec p4_1_q6b_stage_boss_recruit_spec_2026-05-26)。
  /// 仅 `isBossStage: true` 关卡可配 · null = 该 Boss 战胜后不触发招降(1.0 ship 默认全 null)。
  /// 触发链:victory → rng pick(`numbers.yaml stage_boss_recruit_prob` 默认 0.40)→
  /// markTriggered 1 次性守(防玩家刷)→ confirm dialog → 复用 `runSectRecruitFlow`。
  final BossRecruitConfig? bossRecruit;

  /// P1.2 Boss 所属门派(江湖恩怨 · Boss 战胜后触发声望 delta)。
  /// 仅主线 Boss stage 配;null = 无派系归属(爬塔/轻功/群战/心魔 Boss 不沾声望)。
  final String? factionId;

  /// Boss 掉技能书(可玩性 P1a · spec §二)。仅 isBossStage=true 可配。
  /// dropSkillManualId:主线 Boss 首通必给真解;dropSkillFragmentId:爬塔 Boss 概率掉残页。
  final String? dropSkillManualId;
  final String? dropSkillFragmentId;

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
    this.dropTable = const [],
    required this.baseExpReward,
    required this.difficultyMultiplier,
    this.biome,
    this.weather,
    this.sceneBackgroundPath,
    this.terrainBiome,
    this.massBattleWaveCount,
    this.massBattleEnemyCounts,
    this.npcId,
    this.bossRecruit,
    this.factionId,
    this.dropSkillManualId,
    this.dropSkillFragmentId,
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
      sceneBackgroundPath: y['sceneBackgroundPath'] as String?,
      terrainBiome: (y['terrainBiome'] as String?) == null
          ? null
          : TerrainBiome.values.byName(y['terrainBiome'] as String),
      massBattleWaveCount: (y['massBattleWaveCount'] as num?)?.toInt(),
      massBattleEnemyCounts: (y['massBattleEnemyCounts'] as List?)
          ?.map((e) => (e as num).toInt())
          .toList(growable: false),
      npcId: y['npcId'] as String?,
      factionId: y['factionId'] as String?,
      dropSkillManualId: y['dropSkillManualId'] as String?,
      dropSkillFragmentId: y['dropSkillFragmentId'] as String?,
      bossRecruit: y['bossRecruit'] == null
          ? null
          : BossRecruitConfig.fromYaml(
              Map<String, dynamic>.from(y['bossRecruit'] as Map),
            ),
    );
  }

  @override
  String toString() =>
      'StageDef(id=$id, type=${stageType.name}, '
      'requiredRealm=${requiredRealm.name}, enemies=${enemyTeam.length})';
}

/// P4.1 1.1 Q6B · Boss 战胜后招降配置(spec §2 · 沿 `AffectsSectMembership` 体例)。
///
/// `candidateRef` 引 `data/sect_candidates.yaml id`(红线 `_enforceBossRecruitRedLines`
/// 守必存)· `baseProbability` 省略走 numbers.yaml `stage_boss_recruit_prob` 默认 0.40。
class BossRecruitConfig {
  final String candidateRef;
  final double baseProbability;

  const BossRecruitConfig({
    required this.candidateRef,
    this.baseProbability = 0.40,
  });

  factory BossRecruitConfig.fromYaml(Map<String, dynamic> y) =>
      BossRecruitConfig(
        candidateRef: y['candidateRef'] as String,
        baseProbability: (y['baseProbability'] as num?)?.toDouble() ?? 0.40,
      );
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

  /// 出版美术 B2:此敌人是否为 Boss。true → 战斗屏头像金色加粗边框。
  /// 缺省 false 向后兼容。仅 isBossStage 关卡的语义 Boss 敌人标 true。
  final bool isBoss;

  /// P0 破招:此敌人的招牌蓄力技 skillId。null = 不蓄力(普通敌人)。
  /// 配了则必须在 [skillIds] 内(`_enforceBossChargeRedLines` 校)。
  /// 战斗中被 BattleAI 选中此 skill 时进入蓄力,可被玩家破招打断踉跄。
  final String? chargeSkillId;

  /// 批二①：Boss 阶段配置（null = 单阶段旧行为，向后兼容）。
  /// 仅 [isBoss]=true 的敌人有意义；各阶段 unlockSkillIds 引用的
  /// skill id 须在 skills.yaml 中存在（`enforceBossPhaseSkillIds` 校验）。
  final List<BossPhaseDef>? bossPhases;

  /// 批二②：按攻方流派的弱点/抗性受伤乘子（null = 无弱点抗性，全 ×1.0）。
  /// key=攻方 [TechniqueSchool]，value>1.0 弱点（多受伤）/ <1.0 抗性（少受伤）。
  /// 与三流派克制对称，叠乘在伤害末端（Task 7 由 caller 透传到 DamageCalculator
  /// `defenderSchoolDamageMult`）。值域 [min_mult, max_mult] 由 numbers.yaml
  /// `combat.weakness` 定，加载期 `enforceWeaknessRedLines` 校（守 §5.4 ≤2.0）。
  final Map<TechniqueSchool, double>? schoolDamageTakenMult;

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
    this.isBoss = false,
    this.chargeSkillId,
    this.bossPhases,
    this.schoolDamageTakenMult,
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
      isBoss: y['isBoss'] as bool? ?? false,
      chargeSkillId: y['chargeSkillId'] as String?,
      bossPhases: y['bossPhases'] == null
          ? null
          : BossPhaseDef.parseList(y['bossPhases'] as List),
      schoolDamageTakenMult: y['schoolDamageTakenMult'] == null
          ? null
          : (y['schoolDamageTakenMult'] as Map).map(
              (k, v) => MapEntry(
                TechniqueSchool.values.byName(k as String),
                (v as num).toDouble(),
              ),
            ),
    );
  }

  @override
  String toString() =>
      'EnemyDef(id=$id, name=$name, '
      'realm=${realmTier.name}/${realmLayer.name}, school=${school.name})';
}
