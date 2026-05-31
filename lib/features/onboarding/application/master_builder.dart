import 'package:isar_community/isar.dart';

import '../../../core/domain/attributes.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/master_def.dart';
import '../../../data/game_repository.dart';
import '../../../shared/utils/rng.dart';
import '../../equipment/application/equipment_factory.dart';

/// 师徒角色构造 helpers(Phase 3 Week 4 T54 原在 phase2_seed_service.dart 内,
/// 2026-05-25 P0-1 onboarding fix 抽出为 top-level 公用 · debug 与 production 共用)。
///
/// 5 个 helpers:
/// - [buildMasterCharacter]:按 MasterDef 构造 Character(满血默认)
/// - [defaultMasterName]:占位名(祖师/大弟子/二弟子)
/// - [equipMasterStarting]:按 startingEquipmentIds 装备
/// - [learnMasterStarting]:按 startingTechniqueIds 学心法(首项 main / 余 assist)
/// - [seedBasicMaterials]:基础物料(磨剑石 + 心血结晶)
///
/// 沿 GDD §7.1 + masters.yaml 既定数值,不变量 §5.4 红线 / §5.3 三系锁 / §6 公式。

/// 按 [MasterDef] 构造 Character(slotIndex 决定占位名)。
///
/// `internalForce` 满血默认(境界对应 [RealmDef.internalForceMax])。
Character buildMasterCharacter(MasterDef def, {required DateTime now}) {
  final realmDef = GameRepository.instance.getRealm(
    def.defaultRealm,
    def.defaultLayer,
  );
  return Character.create(
    name: defaultMasterName(def),
    realmTier: def.defaultRealm,
    realmLayer: def.defaultLayer,
    attributes: Attributes()
      ..constitution = def.attributeProfile.constitution
      ..enlightenment = def.attributeProfile.enlightenment
      ..agility = def.attributeProfile.agility
      ..fortune = def.attributeProfile.fortune,
    rarity: RarityTier.biaoZhun,
    lineageRole: def.lineageRole,
    isFounder: def.lineageRole == LineageRole.founder,
    createdAt: now,
    internalForce: realmDef.internalForceMax,
    internalForceMax: realmDef.internalForceMax,
    experienceToNextLayer: realmDef.experienceToNext,
    portraitPath: def.portraitPath,
    isActive: true,
  );
}

String defaultMasterName(MasterDef def) {
  switch (def.slotIndex) {
    case 0:
      return '祖师';
    case 1:
      return '大弟子';
    case 2:
      return '二弟子';
    default:
      return '师徒_${def.id}';
  }
}

/// 按 [defIds] 顺序生成装备实例并装在 [character] 对应槽位上。
///
/// 通过 [EquipmentFactory.fromDef] 走标准 roll 路径(与 DropService 一致),
/// 自动设 `ownerCharacterId`。同 slot 多件覆盖(后写入的胜出)。
Future<void> equipMasterStarting(
  Isar isar, {
  required Character character,
  required List<String> defIds,
  required Rng rng,
  required DateTime now,
}) async {
  final repo = GameRepository.instance;
  for (final id in defIds) {
    final def = repo.getEquipment(id);
    final eq = EquipmentFactory.fromDef(
      def,
      rng: rng,
      obtainedAt: now,
      obtainedFrom: 'master_starting',
      ownerCharacterId: character.id,
    );
    await isar.equipments.put(eq);
    switch (def.slot) {
      case EquipmentSlot.weapon:
        character.equippedWeaponId = eq.id;
        break;
      case EquipmentSlot.armor:
        character.equippedArmorId = eq.id;
        break;
      case EquipmentSlot.accessory:
        character.equippedAccessoryId = eq.id;
        break;
    }
  }
}

/// 按 [techDefIds] 顺序学心法:首项 [TechniqueRole.main],其余 [TechniqueRole.assist]。
///
/// 不走 [TechniqueLearningService.learn](种子场景跳过 fail-fast 校验 +
/// 不消耗领悟点)。直接构造 [Technique] 实例并写 Isar,同步 character 的
/// `mainTechniqueId` / `assistTechniqueIds` / `school`(主修流派透传)。
Future<void> learnMasterStarting(
  Isar isar, {
  required Character character,
  required List<String> techDefIds,
  required DateTime now,
}) async {
  final repo = GameRepository.instance;
  final numbers = repo.numbers;
  for (var i = 0; i < techDefIds.length; i++) {
    final def = repo.getTechnique(techDefIds[i]);
    final role = i == 0 ? TechniqueRole.main : TechniqueRole.assist;
    final tech = Technique.create(
      defId: def.id,
      ownerCharacterId: character.id,
      tier: def.tier,
      school: def.school,
      role: role,
      learnedAt: now,
      cultivationProgressToNext:
          numbers.cultivationProgressToNext[CultivationLayer.chuKui]!,
    );
    await isar.techniques.put(tech);
    if (role == TechniqueRole.main) {
      character.mainTechniqueId = tech.id;
      character.school = def.school;
    } else {
      character.assistTechniqueIds = [
        ...character.assistTechniqueIds,
        tech.id,
      ];
    }
  }
}

/// 基础物料 seed(磨剑石 + 心血结晶 InventoryItem 两行)。
///
/// defId 统一为 item_* 体系(与 towers.yaml / stages.yaml drop +
/// tower_entry_flow 映射对齐),避免同 ItemType 多 defId 行分裂。
Future<void> seedBasicMaterials(
  Isar isar, {
  required int mojianshi,
  required int jieJing,
  DateTime? at,
}) async {
  final now = at ?? DateTime.now();
  final moj = InventoryItem()
    ..defId = 'item_mojianshi'
    ..itemType = ItemType.moJianShi
    ..quantity = mojianshi
    ..firstObtainedAt = now
    ..lastObtainedAt = now;
  final jie = InventoryItem()
    ..defId = 'item_xinxuejiejing'
    ..itemType = ItemType.xinXueJieJing
    ..quantity = jieJing
    ..firstObtainedAt = now
    ..lastObtainedAt = now;
  await isar.inventoryItems.putAll([moj, jie]);
}
