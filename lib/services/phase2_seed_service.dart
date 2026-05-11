import 'package:isar/isar.dart';

import '../data/game_repository.dart';
import '../data/isar_setup.dart';
import '../data/models/attributes.dart';
import '../data/models/character.dart';
import '../data/models/enums.dart';
import '../data/models/equipment.dart';
import '../data/models/game_event.dart';
import '../data/models/inventory_item.dart';
import '../data/models/technique.dart';

/// Phase 2 调试场景种子工厂（phase2_tasks.md T32 §492-509 子提交 3）。
///
/// 4 个静态方法 [seedP1] / [seedP2] / [seedP3] / [seedP4] 各对应一个调试场景：
/// 一次 writeTxn 清空业务表（SaveData 不动）+ 写入场景所需的 Character /
/// Equipment / Technique / InventoryItem。
///
/// **物料行 fail-fast 兼容**：每个场景都必创 `InventoryItem(moJianShi)` 与
/// `InventoryItem(xinXueJieJing)` 两行，匹配
/// [EnhancementService.persistResult] 的 fail-fast 约定（行不存在直接抛
/// [StateError]）。即便场景不强化，留两行 0 quantity 也合规。
///
/// **固定 id**：种子角色固定 `id=1`，便于 [CharacterPanelScreen] 与
/// [TechniquePanelScreen] 直接传 `characterId=1`。装备 / 心法 id 由
/// `Isar.autoIncrement` 决定（clear 后从 1 起）。
class Phase2SeedService {
  Phase2SeedService._();

  /// 场景 P1：强化曲线（玩家手动连点 +0 → +19 看成功率分布）。
  ///
  /// - 1 个二流·圆熟角色（absoluteLevel=19，cap +19 与 spec 对齐）
  /// - 1 件 +0 利器武器，已装备在角色身上
  /// - 1000 磨剑石 / 100 心血结晶（足够走完 +19 曲线）
  static Future<void> seedP1() async {
    final isar = IsarSetup.instance;

    await isar.writeTxn(() async {
      await _clearAll(isar);

      final eq = _buildLiQiWeapon(enhanceLevel: 0, battleCount: 0);
      await isar.equipments.put(eq);

      final ch = _buildCharacter(internalForce: 1500, internalForceMax: 2200)
        ..equippedWeaponId = eq.id;
      await isar.characters.put(ch);

      eq.ownerCharacterId = ch.id;
      await isar.equipments.put(eq);

      await _seedMaterials(isar, mojianshi: 1000, jieJing: 100);
    });
  }

  /// 场景 P2：共鸣触发（一件 battleCount=99 装备，再战一回合 →100 触发"趁手"）。
  ///
  /// 子提交 3 不直接接战斗（character_to_battle 转换 helper 留 Phase 3），
  /// 种子写完后 UI 跳 InventoryScreen 让玩家观察 battleCount=99 的装备；
  /// 共鸣 99→100 的数值正确性走子提交 4 phase2_scenarios_test 纯单测覆盖。
  static Future<void> seedP2() async {
    final isar = IsarSetup.instance;

    await isar.writeTxn(() async {
      await _clearAll(isar);

      final eq = _buildLiQiWeapon(enhanceLevel: 0, battleCount: 99);
      await isar.equipments.put(eq);

      final ch = _buildCharacter(internalForce: 1500, internalForceMax: 2200)
        ..equippedWeaponId = eq.id;
      await isar.characters.put(ch);

      eq.ownerCharacterId = ch.id;
      await isar.equipments.put(eq);

      await _seedMaterials(isar, mojianshi: 2000, jieJing: 200);
    });
  }

  /// 场景 P3：散功代价（主修 yuanMan/1500 progress + IF 10000 → daCheng/750 + IF 5000）。
  ///
  /// 算法对照 [DispelService._recalcLayerByRollback] 文档示例：
  ///   - disperse: progress 1500 × 0.5 = 750
  ///   - rollback: prevReq(daCheng→yuanMan)=900；750<900 → 回退 daCheng/750
  ///   - 停：prevReq(zhongCheng→daCheng)=500；750≥500
  /// 与 spec §502 完全一致。
  ///
  /// - 1 角色 internalForce=10000 / internalForceMax=10000
  /// - 主修：刚猛/名家功 cultivationLayer=yuanMan / progress=1500
  /// - 辅修：阴柔/名家功 cultivationLayer=daCheng（供玩家在面板上点"设为主修"）
  static Future<void> seedP3() async {
    final isar = IsarSetup.instance;
    final numbers = GameRepository.instance.numbers;

    await isar.writeTxn(() async {
      await _clearAll(isar);

      final main = _buildTechnique(
        defId: 'tech_gangmeng_mingjia',
        tier: TechniqueTier.mingJiaGong,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.main,
        cultivationLayer: CultivationLayer.yuanMan,
        cultivationProgress: 1500,
        cultivationProgressToNext:
            numbers.cultivationProgressToNext[CultivationLayer.yuanMan]!,
      );
      final assist = _buildTechnique(
        defId: 'tech_yinrou_mingjia',
        tier: TechniqueTier.mingJiaGong,
        school: TechniqueSchool.yinRou,
        role: TechniqueRole.assist,
        cultivationLayer: CultivationLayer.daCheng,
        cultivationProgress: 0,
        cultivationProgressToNext:
            numbers.cultivationProgressToNext[CultivationLayer.daCheng]!,
      );
      await isar.techniques.putAll([main, assist]);

      final ch = _buildCharacter(
        internalForce: 10000,
        internalForceMax: 10000,
        school: TechniqueSchool.gangMeng,
      );
      ch.mainTechniqueId = main.id;
      ch.assistTechniqueIds = [assist.id];
      await isar.characters.put(ch);

      main.ownerCharacterId = ch.id;
      assist.ownerCharacterId = ch.id;
      await isar.techniques.putAll([main, assist]);

      await _seedMaterials(isar, mojianshi: 2000, jieJing: 200);
    });
  }

  /// 场景 P4：全栈对比（+0 利器待玩家强化到 +19 + battleCount=2000 默契满）。
  ///
  /// 玩家在 InventoryScreen 操作：选 +0 装备强化到 +19 + 开锋 1/2/3，对比同
  /// defId 的裸装。battleCount=2000 预置在主装备上，进战斗时（子提交 4
  /// 单测覆盖）默契阶段加成自动生效。
  ///
  /// - 1 角色二流·圆熟
  /// - 装备 A：+0 利器武器 battleCount=2000（已装备在角色身上）
  /// - 装备 B：+0 利器武器 battleCount=0（裸装对照，未装备）
  /// - 2000 磨剑石 / 200 心血结晶（强化到 +19 足够 + 余裕）
  static Future<void> seedP4() async {
    final isar = IsarSetup.instance;

    await isar.writeTxn(() async {
      await _clearAll(isar);

      final eqMain = _buildLiQiWeapon(enhanceLevel: 0, battleCount: 2000);
      final eqRef = _buildLiQiWeapon(enhanceLevel: 0, battleCount: 0);
      await isar.equipments.putAll([eqMain, eqRef]);

      final ch = _buildCharacter(internalForce: 1500, internalForceMax: 2200)
        ..equippedWeaponId = eqMain.id;
      await isar.characters.put(ch);

      eqMain.ownerCharacterId = ch.id;
      // eqRef 留在背包（ownerCharacterId=null）
      await isar.equipments.put(eqMain);

      await _seedMaterials(isar, mojianshi: 2000, jieJing: 200);
    });
  }

  // ── private helpers ────────────────────────────────────────────────────────

  /// 清空业务 collection（保留 SaveData）。装备 / 心法 / 角色 / 物品 / 事件全清。
  static Future<void> _clearAll(Isar isar) async {
    await isar.characters.clear();
    await isar.equipments.clear();
    await isar.techniques.clear();
    await isar.inventoryItems.clear();
    await isar.gameEvents.clear();
  }

  static Future<void> _seedMaterials(
    Isar isar, {
    required int mojianshi,
    required int jieJing,
  }) async {
    final now = DateTime.now();
    final moj = InventoryItem()
      ..defId = ItemType.moJianShi.name
      ..itemType = ItemType.moJianShi
      ..quantity = mojianshi
      ..firstObtainedAt = now
      ..lastObtainedAt = now;
    final jie = InventoryItem()
      ..defId = ItemType.xinXueJieJing.name
      ..itemType = ItemType.xinXueJieJing
      ..quantity = jieJing
      ..firstObtainedAt = now
      ..lastObtainedAt = now;
    await isar.inventoryItems.putAll([moj, jie]);
  }

  /// 二流·圆熟角色模板（absoluteLevel=19，强化 cap +19 与 spec 对齐）。
  /// 出生时间 / 师徒关系 / 稀有度均用占位值，仅供调试场景演示。
  static Character _buildCharacter({
    required int internalForce,
    required int internalForceMax,
    TechniqueSchool? school,
  }) {
    final now = DateTime.now();
    return Character.create(
      name: '测试角色',
      realmTier: RealmTier.erLiu,
      realmLayer: RealmLayer.yuanShu,
      attributes: Attributes()
        ..constitution = 6
        ..enlightenment = 6
        ..agility = 6
        ..fortune = 6,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: now,
      internalForce: internalForce,
      internalForceMax: internalForceMax,
      school: school,
      isActive: true,
      isFounder: true,
    )..id = 1;
  }

  /// 利器·龙泉剑 +0 / +N 的快捷构造（spec §501 默认武器选 yaml `weapon_liqi_long_quan`）。
  static Equipment _buildLiQiWeapon({
    required int enhanceLevel,
    required int battleCount,
  }) {
    final now = DateTime.now();
    final def = GameRepository.instance.getEquipment('weapon_liqi_long_quan');
    return Equipment.create(
      defId: def.id,
      tier: def.tier,
      slot: def.slot,
      obtainedAt: now,
      obtainedFrom: 'phase2_seed',
      baseAttack: def.baseAttackMin,
      baseHealth: def.baseHealthMin,
      baseSpeed: def.baseSpeedMin,
      enhanceLevel: enhanceLevel,
      battleCount: battleCount,
    );
  }

  static Technique _buildTechnique({
    required String defId,
    required TechniqueTier tier,
    required TechniqueSchool school,
    required TechniqueRole role,
    required CultivationLayer cultivationLayer,
    required int cultivationProgress,
    required int cultivationProgressToNext,
  }) {
    final now = DateTime.now();
    return Technique.create(
      defId: defId,
      ownerCharacterId: 1,
      tier: tier,
      school: school,
      role: role,
      learnedAt: now,
      cultivationLayer: cultivationLayer,
      cultivationProgress: cultivationProgress,
      cultivationProgressToNext: cultivationProgressToNext,
    );
  }
}
