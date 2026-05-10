import '../models/enums.dart';

/// 关卡配置（data_schema.md §5.4，纯 Dart，不入 Isar）。
///
/// `enemyTeam` 长度 0–3：剧情关卡可空，普通关卡 1–3 个敌人。
class StageDef {
  final String id;
  final String name;
  final StageType stageType;
  final int? chapterIndex;
  final int? towerLayer;
  final RealmTier requiredRealm;
  final List<EnemyDef> enemyTeam;
  final bool isBossStage;
  final String? narrativeId;
  final List<String> dropEquipmentDefIds;
  final List<String> dropItemDefIds;
  final int baseExpReward;
  final double difficultyMultiplier;

  const StageDef({
    required this.id,
    required this.name,
    required this.stageType,
    this.chapterIndex,
    this.towerLayer,
    required this.requiredRealm,
    required this.enemyTeam,
    required this.isBossStage,
    this.narrativeId,
    required this.dropEquipmentDefIds,
    required this.dropItemDefIds,
    required this.baseExpReward,
    required this.difficultyMultiplier,
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
      narrativeId: y['narrativeId'] as String?,
      dropEquipmentDefIds: List<String>.from(
        (y['dropEquipmentDefIds'] as List? ?? const []).map((e) => e as String),
      ),
      dropItemDefIds: List<String>.from(
        (y['dropItemDefIds'] as List? ?? const []).map((e) => e as String),
      ),
      baseExpReward: (y['baseExpReward'] as num).toInt(),
      difficultyMultiplier: (y['difficultyMultiplier'] as num).toDouble(),
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
