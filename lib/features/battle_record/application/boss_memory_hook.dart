import 'package:flutter/foundation.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/save_data.dart';
import '../../battle/domain/battle_stats.dart';
import '../../equipment/application/drop_service.dart';
import '../domain/boss_memory_source.dart';
import 'boss_memory_service.dart';

/// Boss 胜利 → 战绩册留档（纯数据写，无 UI）。Isar 未 ready → no-op。
///
/// 幂等由 [BossMemoryService] 保证（首胜建完整纪念 / 重打仅累加 defeatCount），
/// 故调用方无需判断 isFirstClear。
///
/// 主线/爬塔共用：[source] / [bossKey] / [groupIndex] / [bossName] 由调用方
/// 按形态显式传入（保持 hook 本身无业务假设）。
///
/// **treasure**：[drops.equipments] 中 tier.index 最高的一件装备名 + tier；
/// 无装备掉落 → null。
///
/// **roster**：从当前存档 `activeCharacterIds` 按序读角色 name + portraitPath
/// （空字符串代替 null），与阵容顺序对齐。
Future<void> runBossMemoryHookAfterVictory({
  required BossMemorySource source,
  required String bossKey,
  required int groupIndex,
  required String bossName,
  required BattleStatsSummary stats,
  required DropResult drops,
  String? topContributorName,
  int? topContributorDamage,
}) async {
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return;

  // best-effort：战绩册是非关键档案，留档失败绝不打断玩家胜利流（庆祝/叙事/进度）。
  // 故整体包 try-catch 降级，仅记日志（区别于既有更核心的 skillDrop hook 不吞错）。
  try {
    // 1. 取 saveDataId。
    final saveDataId = IsarSetup.currentSlotId;

    // 2. roster：读 activeCharacterIds → 各 Character name + portraitPath。
    final save = await isar.saveDatas.get(0);
    final activeIds = save?.activeCharacterIds ?? const <int>[];
    final rosterNames = <String>[];
    final rosterPortraits = <String>[];
    for (final cid in activeIds) {
      final c = await isar.characters.get(cid);
      if (c != null) {
        rosterNames.add(c.name);
        rosterPortraits.add(c.portraitPath ?? '');
      }
    }

    // 3. treasure：drops.equipments 中 tier.index 最高的一件。
    String? treasureName;
    EquipmentTier? treasureTier;
    if (drops.equipments.isNotEmpty) {
      final best = drops.equipments.reduce(
        (a, b) => a.tier.index >= b.tier.index ? a : b,
      );
      treasureTier = best.tier;
      // 尝试从 GameRepository 取 def name；若 def 不存在（测试占位 defId）→ defId 兜底。
      final def = GameRepository.instance.equipmentDefs[best.defId];
      treasureName = def?.name ?? best.defId;
    }

    // 4. 写入战绩册（service 幂等）。
    await BossMemoryService(isar: isar).recordBossVictory(
      saveDataId: saveDataId,
      bossKey: bossKey,
      source: source,
      groupIndex: groupIndex,
      bossName: bossName,
      totalDamage: stats.totalDamage,
      critCount: stats.critCount,
      totalTicks: stats.totalTicks,
      topContributorName: topContributorName,
      topContributorDamage: topContributorDamage,
      treasureName: treasureName,
      treasureTier: treasureTier,
      rosterNames: rosterNames,
      rosterPortraits: rosterPortraits,
      now: DateTime.now(),
    );
  } catch (e, s) {
    debugPrint('runBossMemoryHookAfterVictory 留档失败(降级,不影响胜利流): $e\n$s');
  }
}
