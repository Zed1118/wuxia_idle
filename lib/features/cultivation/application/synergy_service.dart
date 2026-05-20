import '../../../core/domain/character.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/synergy_def.dart';
import '../../../data/defs/technique_def.dart';

/// W18-A1 · 心法相生检测服务(GDD §4.5)。
///
/// 对单角色 (mainTech, assistTech[0]) 组合应用 [SynergyDef.matches],按
/// 优先级 [SynergyRequirementType.specificTechniques] >
/// [SynergyRequirementType.schoolPair] > [SynergyRequirementType.sameSchool] >
/// [SynergyRequirementType.sameTier] 找到首个命中即返回(单角色至多 1 个相生
/// 激活,与 UI chip 0/1 显示一致)。candidate 2(2026-05-21)加 specificTechniques
/// 作最高优先级,贴 GDD §4.5 原意「具体心法对」彩蛋。
///
/// 调用位置:
/// - [StageBattleSetup.buildTeams](战斗 init 时注入 multiplier)
/// - CharacterPanelScreen(UI 显示已激活相生 chip)
class SynergyService {
  /// 检测角色当前 (mainTech, assistTech[0]) 命中的相生。
  ///
  /// 返回 null 的情况:
  /// - [Character.mainTechniqueId] 为 null
  /// - [Character.assistTechniqueIds] 为空
  /// - main/assist 在 [ownedTechniques] 找不到对应 [Technique]
  /// - [Technique.defId] 在 [techDefLookup] 找不到 [TechniqueDef]
  /// - 5 组合无任何一个命中
  static SynergyDef? detectActive({
    required Character character,
    required List<Technique> ownedTechniques,
    required TechniqueDef? Function(String defId) techDefLookup,
    required List<SynergyDef> synergies,
  }) {
    if (synergies.isEmpty) return null;
    final mainId = character.mainTechniqueId;
    if (mainId == null) return null;
    if (character.assistTechniqueIds.isEmpty) return null;
    final assistId = character.assistTechniqueIds.first;

    final mainTech = _findById(ownedTechniques, mainId);
    final assistTech = _findById(ownedTechniques, assistId);
    if (mainTech == null || assistTech == null) return null;

    final mainDef = techDefLookup(mainTech.defId);
    final assistDef = techDefLookup(assistTech.defId);
    if (mainDef == null || assistDef == null) return null;

    // 严格优先级:specificTechniques > schoolPair > sameSchool > sameTier。
    // enum 声明顺序 = 优先级顺序,遍历 values 自动按优先级。每个 type 内部
    // 按 yaml 声明顺序,首个命中即返。
    for (final type in SynergyRequirementType.values) {
      for (final s in synergies) {
        if (s.requirementType != type) continue;
        if (s.matches(
          mainSchool: mainDef.school,
          assistSchool: assistDef.school,
          mainTier: mainDef.tier,
          assistTier: assistDef.tier,
          mainTechniqueId: mainTech.defId,
          assistTechniqueId: assistTech.defId,
        )) {
          return s;
        }
      }
    }
    return null;
  }

  static Technique? _findById(List<Technique> list, int id) {
    for (final t in list) {
      if (t.id == id) return t;
    }
    return null;
  }
}
