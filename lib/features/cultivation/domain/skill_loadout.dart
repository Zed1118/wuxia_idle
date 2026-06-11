import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';

/// 技能装配 7 槽值对象（奇遇槽独立在 Character.equippedEncounterSkillId，不在此）。
/// autoFill 只填空槽，永不覆盖非空槽（非空=玩家保留）。
/// 波A:keySkillId 破招槽,只装 canInterrupt && style == school 的破招技。
class SkillLoadout {
  final String? mainSkillId1;
  final String? mainSkillId2;
  final String? assistSkillId;
  final String? resonanceSkillId;
  final String? ultimateSkillId;
  final String? keySkillId;

  const SkillLoadout({
    this.mainSkillId1,
    this.mainSkillId2,
    this.assistSkillId,
    this.resonanceSkillId,
    this.ultimateSkillId,
    this.keySkillId,
  });

  factory SkillLoadout.fromCharacter(Character c) => SkillLoadout(
        mainSkillId1: c.mainSkillId1,
        mainSkillId2: c.mainSkillId2,
        assistSkillId: c.assistSkillId,
        resonanceSkillId: c.resonanceSkillId,
        ultimateSkillId: c.ultimateSkillId,
        keySkillId: c.keySkillId,
      );

  /// 非空槽 id（去 null），= 该角色战斗可用心法/共鸣/大招/破招招（不含奇遇）。
  List<String> get equippedIds => [
        mainSkillId1,
        mainSkillId2,
        assistSkillId,
        resonanceSkillId,
        ultimateSkillId,
        keySkillId,
      ].whereType<String>().toList();

  /// 自动填充空槽。只填空槽，永不覆盖非空槽（非空=玩家保留）。
  ///
  /// - 主修2槽：从 [mainTechniqueSkills] 中取 powerMultiplier < [ultimatePowerThreshold]
  ///   且通过 [SkillDef.canEquipAtRealm] 的招式，按 power 降序填。
  /// - 大招槽：从 [mainTechniqueSkills] 中取 powerMultiplier ≥ [ultimatePowerThreshold]
  ///   且通过境界 gate 的第一个招式。
  /// - 辅修槽：从 [assistTechniqueSkills] 中取通过境界 gate 的第一个招式。
  /// - 共鸣槽：[jointSkill] 非 null 且通过境界 gate 时填入。
  /// - 破招槽（波A）：从 [interruptSkills] 中取 style == [school] 且过境界 gate
  ///   的第一个（school null → 不填，无流派无破招技）。
  static SkillLoadout autoFill({
    required List<SkillDef> mainTechniqueSkills,
    required List<SkillDef> assistTechniqueSkills,
    required SkillDef? jointSkill,
    required RealmTier realmTier,
    required SkillLoadout existing,
    required int ultimatePowerThreshold,
    List<SkillDef> interruptSkills = const [],
    TechniqueSchool? school,
  }) {
    bool gate(SkillDef s) => s.canEquipAtRealm(realmTier);

    // 大招槽：主修招中 power ≥ 阈值的第一个（按原列表顺序）
    final ults = mainTechniqueSkills
        .where((s) => gate(s) && s.powerMultiplier >= ultimatePowerThreshold)
        .toList();
    final ultimate = existing.ultimateSkillId ?? (ults.isNotEmpty ? ults.first.id : null);

    // 主修2槽：power < 阈值，按 power 降序
    final mains = mainTechniqueSkills
        .where((s) => gate(s) && s.powerMultiplier < ultimatePowerThreshold)
        .toList()
      ..sort((a, b) => b.powerMultiplier.compareTo(a.powerMultiplier));
    final mainIds = mains.map((s) => s.id).toList();
    final used = <String?>{existing.mainSkillId1, existing.mainSkillId2};
    final pool = mainIds.where((id) => !used.contains(id)).toList();
    final m1 = existing.mainSkillId1 ?? (pool.isNotEmpty ? pool.removeAt(0) : null);
    final m2 = existing.mainSkillId2 ?? (pool.isNotEmpty ? pool.removeAt(0) : null);

    // 辅修槽
    final assists = assistTechniqueSkills.where(gate).toList();
    final assist = existing.assistSkillId ?? (assists.isNotEmpty ? assists.first.id : null);

    // 共鸣槽（人剑合一招式）
    final resonance = existing.resonanceSkillId ??
        ((jointSkill != null && gate(jointSkill)) ? jointSkill.id : null);

    // 破招槽（波A build gate:canInterrupt && style == school）
    String? key = existing.keySkillId;
    if (key == null && school != null) {
      for (final s in interruptSkills) {
        if (s.canInterrupt && s.style == school && gate(s)) {
          key = s.id;
          break;
        }
      }
    }

    return SkillLoadout(
      mainSkillId1: m1,
      mainSkillId2: m2,
      assistSkillId: assist,
      resonanceSkillId: resonance,
      ultimateSkillId: ultimate,
      keySkillId: key,
    );
  }
}
