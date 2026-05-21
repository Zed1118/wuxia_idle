import 'package:isar_community/isar.dart';

import '../../../core/domain/attributes.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/recruit_candidate_def.dart';
import '../../../data/game_repository.dart';
import '../../../shared/utils/rng.dart';
import '../../equipment/application/equipment_factory.dart';

/// 收徒服务(P1.1 A1 E.1,GDD §7.1)。
///
/// audit doc `p1_1_a1_recruitment_audit_2026-05-21.md` 方案 3 决议:
/// **inactive 池收徒**(active 上限不动,新弟子入 Isar.characters 但不入
/// SaveData.activeCharacterIds)。
///
/// 触发流程:玩家境界突破到一流 → tutorial step 6 banner → 玩家点 banner →
/// 进 [RecruitmentDialog] → 显 3 候选(D2.b)→ 选 [acceptCandidate] 或
/// [declineRecruitment] → 双路径都 markOffered=true(D3.a 一次性 only)。
///
/// **设计纪律**:
/// - **caller 持锁**(对齐 [TutorialService] / [GameEventService] 体例):
///   service 方法不开 `writeTxn`,caller 必须在 `isar.writeTxn` 内 await,
///   保证多表写入原子性(memory `feedback_isar_pitfalls` §1)。
/// - **幂等**:`recruitmentOffered=true` 后再调 [acceptCandidate] /
///   [declineRecruitment] 直接 no-op(防 dialog 重入)。
/// - **三系锁死**:RecruitCandidateDef yaml 加载期红线已校
///   (`GameRepository._enforceRecruitCandidateRedLines`),service 端
///   不重复校验装备 tier vs realm。
class RecruitmentService {
  final Isar isar;

  RecruitmentService(this.isar);

  /// 读 SaveData.recruitmentOffered(默认 false)。
  ///
  /// SaveData 未初始化(test 路径 / 全新存档)→ false。
  Future<bool> hasOffered() async {
    final save = await isar.saveDatas.get(0);
    return save?.recruitmentOffered ?? false;
  }

  /// 读 SaveData.recruitedDiscipleIds(默认空 list)。
  Future<List<int>> getRecruitedIds() async {
    final save = await isar.saveDatas.get(0);
    return save?.recruitedDiscipleIds ?? const [];
  }

  /// 收徒候选列表(按 yaml id 升序)。GameRepository 未加载 → 空 list。
  static List<RecruitCandidateDef> getCandidates() {
    if (!GameRepository.isLoaded) return const [];
    final map = GameRepository.instance.recruitCandidates;
    final list = map.values.toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  /// 拜师候选 [candidateId] → 创 Character 入 Isar(inactive 池语义,**不入**
  /// activeCharacterIds)+ 装 starting 装备 + 学 starting 心法 + markOffered。
  ///
  /// 返回新弟子 Character.id。
  ///
  /// **caller 持锁**:caller 必须在 `isar.writeTxn` 内 await 本方法。
  ///
  /// **幂等**:`recruitmentOffered=true` 时 no-op,返回 -1(防 dialog 重入)。
  /// candidateId 不在 yaml 中时抛 [StateError]。
  Future<int> acceptCandidate(String candidateId, {DateTime? now}) async {
    final save = await isar.saveDatas.get(0);
    if (save == null) {
      throw StateError('SaveData 未初始化,acceptCandidate 调用前请确认 IsarSetup.init');
    }
    if (save.recruitmentOffered) return -1; // 幂等 no-op

    final repo = GameRepository.instance;
    final def = repo.recruitCandidates[candidateId];
    if (def == null) {
      throw StateError('收徒候选 $candidateId 未在 recruit_candidates.yaml 中');
    }
    final realmDef = repo.getRealm(def.defaultRealm, def.defaultLayer);
    final t = now ?? DateTime.now();
    final rng = DefaultRng();

    // 1. 创 Character(isActive=false / lineageRole=disciple / isFounder=false)
    final c = Character.create(
      name: def.name,
      realmTier: def.defaultRealm,
      realmLayer: def.defaultLayer,
      attributes: Attributes()
        ..constitution = def.attributeProfile.constitution
        ..enlightenment = def.attributeProfile.enlightenment
        ..agility = def.attributeProfile.agility
        ..fortune = def.attributeProfile.fortune,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.disciple,
      isFounder: false,
      createdAt: t,
      internalForce: realmDef.internalForceMax,
      internalForceMax: realmDef.internalForceMax,
      experienceToNextLayer: realmDef.experienceToNext,
      isActive: false, // inactive 池语义 (D1.b)
      school: def.school,
    );
    await isar.characters.put(c);

    // 2. 双向师徒关系:founder.discipleIds 追加 + c.masterId = founder.id
    final founderId = save.founderCharacterId;
    if (founderId != null) {
      final founder = await isar.characters.get(founderId);
      if (founder != null) {
        founder.discipleIds = [...founder.discipleIds, c.id];
        await isar.characters.put(founder);
        c.masterId = founder.id;
      }
    }

    // 3. starting 装备(EquipmentFactory.fromDef 走标准 roll)
    for (final equipId in def.startingEquipmentIds) {
      final eqDef = repo.getEquipment(equipId);
      final eq = EquipmentFactory.fromDef(
        eqDef,
        rng: rng,
        obtainedAt: t,
        obtainedFrom: 'recruitment_$candidateId',
        ownerCharacterId: c.id,
      );
      await isar.equipments.put(eq);
      switch (eqDef.slot) {
        case EquipmentSlot.weapon:
          c.equippedWeaponId = eq.id;
          break;
        case EquipmentSlot.armor:
          c.equippedArmorId = eq.id;
          break;
        case EquipmentSlot.accessory:
          c.equippedAccessoryId = eq.id;
          break;
      }
    }

    // 4. starting 心法(首项 main + 写 mainTechniqueId/school)
    final numbers = repo.numbers;
    for (var i = 0; i < def.startingTechniqueIds.length; i++) {
      final techDef = repo.getTechnique(def.startingTechniqueIds[i]);
      final role = i == 0 ? TechniqueRole.main : TechniqueRole.assist;
      final tech = Technique.create(
        defId: techDef.id,
        ownerCharacterId: c.id,
        tier: techDef.tier,
        school: techDef.school,
        role: role,
        learnedAt: t,
        cultivationProgressToNext:
            numbers.cultivationProgressToNext[CultivationLayer.chuKui]!,
      );
      await isar.techniques.put(tech);
      if (role == TechniqueRole.main) {
        c.mainTechniqueId = tech.id;
        c.school = techDef.school;
      } else {
        c.assistTechniqueIds = [...c.assistTechniqueIds, tech.id];
      }
    }
    await isar.characters.put(c);

    // 5. SaveData: markOffered + recruitedDiscipleIds 追加
    save.recruitmentOffered = true;
    save.recruitedDiscipleIds = [...save.recruitedDiscipleIds, c.id];
    await isar.saveDatas.put(save);

    return c.id;
  }

  /// 拒绝收徒(D3.a 一次性 only)→ markOffered = true,不创任何 Character。
  ///
  /// **caller 持锁**:caller 必须在 `isar.writeTxn` 内 await 本方法。
  /// `recruitmentOffered=true` 时 no-op(幂等)。
  Future<void> declineRecruitment() async {
    final save = await isar.saveDatas.get(0);
    if (save == null) return;
    if (save.recruitmentOffered) return;
    save.recruitmentOffered = true;
    await isar.saveDatas.put(save);
  }
}
