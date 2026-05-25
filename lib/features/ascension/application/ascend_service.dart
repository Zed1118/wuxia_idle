import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/isar_setup.dart';
import '../../../data/numbers_config.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../sect/domain/sect.dart';
import '../domain/ascension_models.dart';

/// P2.3 飞升 + 遗物 transfer service(spec p2_3_ascension_spec_2026-05-24)。
///
/// **职责**:
/// 1. [computeEligibility]:聚合 5 子条件 + canAscend(R · async)
/// 2. [listHeritageCandidates]:玩家 founder 全部装备列表(选件 UI 源)
/// 3. [listDiscipleTargets]:active 中 disciple 且 isAlive 的徒弟列表
/// 4. [performAscend]:transfer 主流程 + founder 退出 active(W · caller 持锁)
///
/// **设计纪律**(对齐 [RecruitmentService] / [FounderBuffService] 体例):
/// - **caller 持锁**:写方法 [performAscend] 不开 `writeTxn`,caller 必须在
///   `isar.writeTxn` 内 await(对齐 memory `feedback_isar_pitfalls` §1)
/// - **0 schema 改动**:复用 Character.{isFounder/isActive/lineageRole} +
///   Equipment.{isLineageHeritage/inheritFrom/ownerCharacterId} +
///   SaveData.{founderCharacterId/activeCharacterIds}
/// - **`founder_buff_service` 自然失效**:performAscend 完后 founder.isActive=false +
///   activeCharacterIds remove founder → `FounderBuffService.computeBuffActive`
///   自然返 false(无需扩 trigger · spec §6 注)
class AscendService {
  final Isar isar;
  final NumbersConfig numbers;

  AscendService(this.isar, this.numbers);

  /// 计算飞升 eligibility(5 子条件 · async 读 Isar + MainlineProgress)。
  ///
  /// [clearedStageIds] 注入便于 test(生产路径走 [MainlineProgress] · 沿
  /// `InnerDemonService.isLayerLocked` 体例)。null = service 内自动读
  /// `isar.mainlineProgress` 当前存档行的 `clearedStageIds`。
  ///
  /// **SaveData / MainlineProgress 未初始化**(test 路径未 IsarSetup.init)→ 返
  /// [AscensionEligibility.blocked](canAscend=false 安全兜底)。
  Future<AscensionEligibility> computeEligibility({
    Set<String>? clearedStageIds,
  }) async {
    final save = await isar.saveDatas.get(0);
    if (save == null) return AscensionEligibility.blocked;

    final founderId = save.founderCharacterId;
    if (founderId == null) return AscensionEligibility.blocked;

    final founder = await isar.characters.get(founderId);
    if (founder == null) return AscensionEligibility.blocked;

    final inActive = save.activeCharacterIds.contains(founderId);

    final realmTier = numbers.ascension.requiredRealmTier ?? RealmTier.wuSheng;
    final realmLayer =
        numbers.ascension.requiredRealmLayer ?? RealmLayer.dengFeng;
    final realmAtPeak =
        founder.realmTier == realmTier && founder.realmLayer == realmLayer;

    final cleared = clearedStageIds ?? await _readClearedFromProgress();
    final required = numbers.ascension.clearedStagesRequired;
    final innerDemon07Cleared = required.contains('stage_inner_demon_07')
        ? cleared.contains('stage_inner_demon_07')
        : true; // 配置不带 → 不拦截(空兜底语义,与 InnerDemonDef.empty 对齐)
    final mainline0605Cleared = required.contains('stage_06_05')
        ? cleared.contains('stage_06_05')
        : true;

    final discipleTargets = await listDiscipleTargets();
    final hasDisciple = discipleTargets.isNotEmpty;

    return AscensionEligibility(
      inActiveCharacters: inActive,
      realmAtPeak: realmAtPeak,
      innerDemon07Cleared: innerDemon07Cleared,
      mainline0605Cleared: mainline0605Cleared,
      hasDiscipleTarget: hasDisciple,
    );
  }

  /// 当前 founder 是否持有「从前人真传过来」的装备(即「这是 gen2+ 多代飞升」)。
  ///
  /// **判定**:不是看 `isLineageHeritage`(def 自带的祖师装备 gen0 起就标 true),
  /// 而是看 `previousOwnerCharacterIds.isNotEmpty`(真有前任持有者列表 = 多代续传)。
  /// gen0 founder 装的祖师 def 装备 prev=[](创世遗物,无前任)→ 一代飞升 ·
  /// gen1+ founder 装的飞升传承装备 prev=[id1,...] → 多代续传。
  ///
  /// 用法:UI 层 _performAscend 之前调,选 narrative 文件:
  /// - true → `ascension_lineage_chant`(P5+ 多代续传弧 · 太祖→师父→我→新弟子)
  /// - false → `ascension_complete`(P2.3 一代飞升 · 师父别山 + 化境门开)
  ///
  /// SaveData / founder 未初始化 → false(安全兜底)。
  Future<bool> isLineageContinuation() async {
    final save = await isar.saveDatas.get(0);
    final founderId = save?.founderCharacterId;
    if (founderId == null) return false;
    final founder = await isar.characters.get(founderId);
    if (founder == null) return false;
    final ids = [
      founder.equippedWeaponId,
      founder.equippedArmorId,
      founder.equippedAccessoryId,
    ].whereType<int>().toList();
    for (final id in ids) {
      final eq = await isar.equipments.get(id);
      if (eq != null && eq.previousOwnerCharacterIds.isNotEmpty) return true;
    }
    return false;
  }

  /// 玩家 founder 当前所有装备(选件 UI 源 · `ownerCharacterId == founderId`)。
  ///
  /// 不预过滤 `isLineageHeritage`(spec §3:飞升时任选已装备 / 库存皆可)。
  /// founder 不存在 → 空 list。
  Future<List<Equipment>> listHeritageCandidates(int founderId) async {
    final founder = await isar.characters.get(founderId);
    if (founder == null) return const [];
    return isar.equipments
        .filter()
        .ownerCharacterIdEqualTo(founderId)
        .findAll();
  }

  /// active 中 `lineageRole == disciple` 且 `isAlive == true` 且 `isFounder == false`
  /// 的徒弟列表(transfer target · UI 下拉源)。
  ///
  /// SaveData 未初始化 / activeCharacterIds 空 → 空 list。order 按 activeCharacterIds
  /// 顺序(UI 默认选第 1 个 = 大弟子语义)。
  ///
  /// P5+ 真传位后 promoted disciple 的 `isFounder=true`(`lineageRole` 仍为 disciple ·
  /// 沿 spec Q2 不真切语义)→ 必须从 target 列表排除,否则下一代飞升时玩家可能把已
  /// 接任 founder 身份的「新祖师」再次选作 promoted target(语义循环)。R5.9 防回
  /// 退测验证。
  Future<List<Character>> listDiscipleTargets() async {
    final save = await isar.saveDatas.get(0);
    if (save == null) return const [];
    final ids = save.activeCharacterIds;
    if (ids.isEmpty) return const [];
    final result = <Character>[];
    for (final id in ids) {
      final c = await isar.characters.get(id);
      if (c == null) continue;
      if (c.lineageRole != LineageRole.disciple) continue;
      if (!c.isAlive) continue;
      if (c.isFounder) continue;
      result.add(c);
    }
    return result;
  }

  /// 飞升 transfer 主流程(W · **caller 必须在 `isar.writeTxn` 内 await**)。
  ///
  /// [selections] = `{equipmentId: targetDiscipleCharacterId}` 玩家分配 map。
  /// [promotedDiscipleId] = P5+ 真传位 disciple(接任 founder 身份)· null = 不传位
  /// (P2.3 一代飞升兼容路径 · 原 R5.1-5.5 14 测保持)。非 null 时副作用 4 + 7 触发。
  /// 校验失败抛 [StateError](messages 含未达条件 / 字段错误清单)。
  ///
  /// **副作用**:
  ///   1. 每件装备 `inheritFrom(founderId, numbers)`(共鸣 ×0.7 + isLineageHeritage=true +
  ///      previousOwner 链 push)
  ///   2. 每件装备 `ownerCharacterId = targetDiscipleId`(batch transfer)
  ///   3. founder 端槽位脱钩(equippedWeaponId/ArmorId/AccessoryId 若指本 eq 清空)
  ///   4. **disciple 端槽位自动接新遗物**(Q3 conflict_slot_resolution=auto_swap):
  ///      `disciple.equipped{Slot}Id` 指向新 eq.id · 旧装 ownerCharacterId 不变
  ///      (disciple 仍持入背包语义 · spec `p5_lineage_full_spec` §Q3)
  ///   5. founder.isActive=false(出阵 · isAlive 不动 · GDD §7.1 飞升渡劫后仍存在)
  ///   6. SaveData.activeCharacterIds remove founderId
  ///   7. **promotedDisciple.isFounder=true**(Q1+Q2 · 真传位 · 不动 lineageRole ·
  ///      founder.isFounder 保 true「太祖」语义 · founder_buff_service 自然接管 · §Q5)
  ///   8. **不动 founder.realm**(已 wuSheng·dengFeng · 飞升非升层)
  Future<AscensionResult> performAscend(
    Map<int, int> selections, {
    int? promotedDiscipleId,
  }) async {
    // 1. 5 子条件复查(避 UI invalidate 漏窗口 · 防 race)
    final eligibility = await computeEligibility();
    if (!eligibility.canAscend) {
      throw StateError(
        '飞升条件未满足:${eligibility.missingReasons.join(' / ')}',
      );
    }

    // 2. selections 校验
    final n = numbers.heritageItems;
    if (selections.length < n.piecesPerGenerationMin ||
        selections.length > n.piecesPerGenerationMax) {
      throw StateError(
        '飞升传出件数 ${selections.length} 超 [${n.piecesPerGenerationMin}, '
        '${n.piecesPerGenerationMax}] 范围',
      );
    }

    final save = (await isar.saveDatas.get(0))!;
    final founderId = save.founderCharacterId!;
    final founder = (await isar.characters.get(founderId))!;

    final discipleTargets = await listDiscipleTargets();
    final discipleIds = discipleTargets.map((c) => c.id).toSet();

    // 3. 装备 / disciple 引用校验
    final equipmentsByOrder = <Equipment>[];
    for (final entry in selections.entries) {
      final eq = await isar.equipments.get(entry.key);
      if (eq == null) {
        throw StateError('装备 ${entry.key} 不存在');
      }
      if (eq.ownerCharacterId != founderId) {
        throw StateError(
          '装备 ${entry.key} owner=${eq.ownerCharacterId} 非 founder=$founderId',
        );
      }
      if (!discipleIds.contains(entry.value)) {
        throw StateError(
          'target ${entry.value} 非 disciple(active+alive disciples=$discipleIds)',
        );
      }
      equipmentsByOrder.add(eq);
    }

    // 3a. promotedDisciple 校验(P5+ 真传位 · spec §Q1)
    if (promotedDiscipleId != null &&
        !discipleIds.contains(promotedDiscipleId)) {
      throw StateError(
        'promotedDiscipleId $promotedDiscipleId 非 disciple'
        '(active+alive disciples=$discipleIds)',
      );
    }

    // 4. transfer 副作用(单 writeTxn · caller 持锁)
    for (final eq in equipmentsByOrder) {
      eq.inheritFrom(founderId, numbers);
      eq.ownerCharacterId = selections[eq.id]!;
      // 副作用 3:founder 端槽位脱钩
      if (founder.equippedWeaponId == eq.id) founder.equippedWeaponId = null;
      if (founder.equippedArmorId == eq.id) founder.equippedArmorId = null;
      if (founder.equippedAccessoryId == eq.id) {
        founder.equippedAccessoryId = null;
      }
      await isar.equipments.put(eq);

      // 副作用 4 · Q3 conflict_slot_resolution=auto_swap:disciple 端槽位自动接
      // 新遗物 · 旧装 ownerCharacterId 不变(disciple 仍持入背包语义 · §Q3)
      final disciple = (await isar.characters.get(selections[eq.id]!))!;
      switch (eq.slot) {
        case EquipmentSlot.weapon:
          disciple.equippedWeaponId = eq.id;
          break;
        case EquipmentSlot.armor:
          disciple.equippedArmorId = eq.id;
          break;
        case EquipmentSlot.accessory:
          disciple.equippedAccessoryId = eq.id;
          break;
      }
      await isar.characters.put(disciple);
    }

    // 5. founder 出阵
    founder.isActive = false;
    await isar.characters.put(founder);

    // 6. SaveData.activeCharacterIds remove founderId
    save.activeCharacterIds = save.activeCharacterIds
        .where((id) => id != founderId)
        .toList();
    await isar.saveDatas.put(save);

    // 7. promotedDisciple 接管 founder 身份(P5+ 真传位 · §Q1+Q2+Q5)
    //   - promotedDisciple.isFounder=true(不动 lineageRole · 沿 P2.3 Q2c 体例)
    //   - founder.isFounder 保 true(不切 · 「太祖」语义)
    //   - founder_buff_service 自然接管(active 中找到 isFounder=true → buff 激活)
    if (promotedDiscipleId != null) {
      final promoted = (await isar.characters.get(promotedDiscipleId))!;
      promoted.isFounder = true;
      await isar.characters.put(promoted);

      // 8. P4.1 §12.2 B2 sect.founderId rewire(spec §5 P5+ 真传位 sect 接管):
      // 若 sect.founderId==旧 founder.id 且 promotedDisciple!=null →
      // rewire 到 promotedDiscipleId。member 关系不动(旧 member.sectId 仍
      // 指原 sect · 自然挂新 founder)。多代场景留 1.1(本 hook 单代验证)。
      // 单 sect 假设:Demo 阶段全局唯一 sect(p4_1 spec §1 范围)。
      final sectsToRewire =
          await isar.sects.filter().founderIdEqualTo(founderId).findAll();
      for (final sect in sectsToRewire) {
        sect.founderId = promotedDiscipleId;
        await isar.sects.put(sect);
      }
    }

    return AscensionResult(
      transferredCount: selections.length,
      founderRetired: true,
      heritageEquipmentIds: equipmentsByOrder
          .map((e) => e.id)
          .toList(growable: false),
      beneficiaryDiscipleIds:
          selections.values.toSet().toList(growable: false),
      promotedDiscipleId: promotedDiscipleId,
    );
  }

  /// 私有:从 [MainlineProgress] 读当前存档的 `clearedStageIds`(Set 视图)。
  /// MainlineProgress 行不存在(test fixture / 全新存档)→ 空集合。
  Future<Set<String>> _readClearedFromProgress() async {
    final progress = await isar.mainlineProgress
        .filter()
        .saveDataIdEqualTo(IsarSetup.currentSlotId)
        .findFirst();
    if (progress == null) return const <String>{};
    return progress.clearedStageIds.toSet();
  }
}
