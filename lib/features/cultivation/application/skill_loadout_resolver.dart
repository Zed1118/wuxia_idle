import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/skill_unlock_entry.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/skill_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/numbers_config.dart';

/// P1b Task5/Task9 共享：从持久化角色解析 autoFill 所需的三组招式源
/// （主修招 / 辅修招 / joint 共鸣招），供 [SkillLoadoutService.applyAutoFill] 使用。
///
/// 抽出此 helper 避免 `StageBattleSetup`（进战斗前 autoFill）与
/// `CangJingGeScreen`（进藏经阁 autoFill）重复同一段心法→招解析逻辑。
class SkillLoadoutResolver {
  const SkillLoadoutResolver({required this.isar});

  final Isar isar;

  /// 与 skills.yaml 定义一致的 joint_skill id（人剑合一共鸣招），单一真相源。
  static const jointSkillId = 'skill_joint_skill';

  /// 一次性解析角色的主修招 / 辅修招 / joint 招，打包成 [ResolvedLoadoutSources]。
  Future<ResolvedLoadoutSources> resolve(
    Character c, {
    GameRepository? repository,
    NumbersConfig? numbers,
  }) async {
    final repo = repository ?? GameRepository.instance;
    final n = numbers ?? repo.numbers;
    return ResolvedLoadoutSources(
      mainTechniqueSkills: await resolveMainSkillDefs(c, repo),
      assistTechniqueSkills: await resolveAssistSkillDefs(c, repo),
      jointSkill: await resolveJointSkill(c, n, repo),
      interruptSkills: resolveInterruptSkills(repo),
      dropSkills: await resolveUnlockedDropSkills(c, repo),
    );
  }

  /// 波B:已解锁的真解/残页招(source ∈ {mainlineDrop, fragment} &&
  /// SaveData.skillUnlockProgress.isUnlocked && style == 角色流派)。
  /// 流派 gate 与破招槽先例一致(build 流派一致性);境界 gate 在
  /// picker/service 按 canEquipAtRealm 做,此处不过滤。
  /// SaveData 单例缺失(极早期/test fixture)→ 返空,不抛。
  Future<List<SkillDef>> resolveUnlockedDropSkills(
    Character c,
    GameRepository repo,
  ) async {
    final school = c.school;
    if (school == null) return const [];
    final SaveData? save = await isar.saveDatas.get(0);
    if (save == null) return const [];
    final unlocked = save.skillUnlockProgress;
    final result = repo.skillDefs.values
        .where((s) =>
            (s.source == SkillSource.mainlineDrop ||
                s.source == SkillSource.fragment) &&
            s.style == school &&
            unlocked.isUnlocked(s.id))
        .toList()
      ..sort((a, b) {
        final t = (a.tier ?? 0).compareTo(b.tier ?? 0);
        return t != 0 ? t : a.id.compareTo(b.id);
      });
    return result;
  }

  /// 波A 破招槽候选:全部 canInterrupt=true 招(流派过滤在 autoFill / picker
  /// 按 character.school 做,此处不过滤,便于 picker 未来显示灰显他流派招)。
  List<SkillDef> resolveInterruptSkills(GameRepository repo) =>
      repo.skillDefs.values.where((s) => s.canInterrupt).toList();

  /// 主修心法 skillIds → `List<SkillDef>`。
  /// mainTechniqueId 为 null（无主修）→ 返空列表。
  Future<List<SkillDef>> resolveMainSkillDefs(
    Character c,
    GameRepository repo,
  ) async {
    final tid = c.mainTechniqueId;
    if (tid == null) return const [];
    final tech = await isar.techniques.get(tid);
    if (tech == null) return const [];
    final techDef = repo.techniqueDefs[tech.defId];
    if (techDef == null) return const [];
    return techDef.skillIds
        .where(repo.skillDefs.containsKey)
        .map(repo.getSkill)
        .toList();
  }

  /// 辅修心法（可多本）的所有 skillIds → `List<SkillDef>`（扁平化合并）。
  Future<List<SkillDef>> resolveAssistSkillDefs(
    Character c,
    GameRepository repo,
  ) async {
    final result = <SkillDef>[];
    for (final tid in c.assistTechniqueIds) {
      final tech = await isar.techniques.get(tid);
      if (tech == null) continue;
      final techDef = repo.techniqueDefs[tech.defId];
      if (techDef == null) continue;
      for (final id in techDef.skillIds) {
        if (repo.skillDefs.containsKey(id)) result.add(repo.getSkill(id));
      }
    }
    return result;
  }

  /// joint 解锁判定：任一武器 resonanceStage 达 unlocksJointSkill=true 阶 → 返回
  /// skill_joint_skill SkillDef；否则返 null（共鸣槽不自动填，玩家手动装配）。
  Future<SkillDef?> resolveJointSkill(
    Character c,
    NumbersConfig numbers,
    GameRepository repo,
  ) async {
    final wid = c.equippedWeaponId;
    if (wid == null) return null;
    final weapon = await isar.equipments.get(wid);
    if (weapon == null) return null;
    final stage = weapon.resonanceStage(numbers);
    final stageConfig = numbers.resonanceStages.firstWhere(
      (s) => s.stage == stage,
      orElse: () => _shengShuFallback,
    );
    if (!stageConfig.unlocksJointSkill) return null;
    if (!repo.skillDefs.containsKey(jointSkillId)) return null;
    return repo.getSkill(jointSkillId);
  }

}

/// [SkillLoadoutResolver.resolve] 的解析结果三元组。
class ResolvedLoadoutSources {
  const ResolvedLoadoutSources({
    required this.mainTechniqueSkills,
    required this.assistTechniqueSkills,
    required this.jointSkill,
    this.interruptSkills = const [],
    this.dropSkills = const [],
  });

  final List<SkillDef> mainTechniqueSkills;
  final List<SkillDef> assistTechniqueSkills;
  final SkillDef? jointSkill;

  /// 波A:全部破招技(canInterrupt=true,未按流派过滤)。
  final List<SkillDef> interruptSkills;

  /// 波B:已解锁 + 本流派的真解/残页招(主修/大招槽 picker 候选注入;
  /// autoFill 不消费——掉落招玩家主动换装,不自动顶,§5.7)。
  final List<SkillDef> dropSkills;
}

/// joint 判定用的 shengShu fallback（防御性，正常配置 4 段全覆盖不触发）。
const _shengShuFallback = ResonanceStageConfig(
  stage: ResonanceStage.shengShu,
  minBattleCount: 0,
  maxBattleCount: 0,
  bonusMultiplier: 1.0,
);
