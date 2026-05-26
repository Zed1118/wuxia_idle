import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/isar_setup.dart';
import '../../../data/numbers_config.dart';

/// 祖师爷 buff 激活态判定(P1.1 A1 E.5,GDD §7.1 + P4.1 1.1 cross_sect 扩)。
///
/// 决议方案 E.5.A(audit `p1_1_a1_recruitment_audit_2026-05-21.md` 后续 + 用户拍板):
/// `enabled_when_alive: true` 时,**active 集合中存在 isFounder=true 角色** → buff 激活。
/// caller 端拿到 [computeBuffActive] / [isBuffActiveFor] 返回值传给
/// `CharacterDerivedStats.*` 的 `founderBuffActive` 可选参数。
///
/// **P4.1 1.1 cross_sect 扩**(spec `p4_1_founder_buff_cross_sect_spec_2026-05-26.md`):
/// 新 per-character API [isBuffActiveFor] 跨派系判定:
///   - target.isInSect=false → fallback 单 founder 享(P1.1 体例维持)
///   - target.isInSect=true && sectId==playerSectId → 享
///   - target.isInSect=true && sectId!=playerSectId → 不享(NPC 跨派系)
/// 旧 [computeBuffActive] API 保留向后兼容(character_panel / lineage_panel UI 调用)。
///
/// **设计纪律**:
/// - 纯 read service,无 writeTxn
/// - 静态 + Isar 注入(对齐 [TutorialService] 体例)
/// - Phase 5+ 飞升机制实装时,本 service 扩展 trigger 条件
///   (eg. 改判「founder 是否已飞升退出 active」)
class FounderBuffService {
  final Isar isar;

  FounderBuffService(this.isar);

  /// buff 是否处于激活态(整体 · 老 API · P1.1 体例):
  /// 1. yaml `enabled_when_alive=true`(`FounderAncestorBuff.isActive`)
  /// 2. SaveData.activeCharacterIds 中存在 isFounder=true 角色
  ///
  /// 任一条件不满足 → false(buff 不应用)。
  /// SaveData 未初始化 / activeCharacterIds 空 → false。
  Future<bool> computeBuffActive(NumbersConfig n) async {
    if (!n.founderAncestorBuff.isActive) return false;
    final save = await isar.saveDatas
        .filter()
        .slotIdEqualTo(IsarSetup.currentSlotId)
        .findFirst();
    if (save == null) return false;
    final ids = save.activeCharacterIds;
    if (ids.isEmpty) return false;
    for (final id in ids) {
      final c = await isar.characters.get(id);
      if (c != null && c.isFounder) return true;
    }
    return false;
  }

  /// **per-character buff 激活态**(P4.1 1.1 cross_sect 扩)。
  ///
  /// 判定规则:
  /// 1. yaml `enabled_when_alive=true` + SaveData active 含 isFounder=true(同 [computeBuffActive])
  /// 2. **跨派系**(本扩展):
  ///    - `target.isInSect=false` → fallback 单 founder 自享(P1.1 维持 · 不破 R5)
  ///    - `target.isInSect=true && target.sectId == playerSectId` → 享
  ///    - `target.isInSect=true && target.sectId != playerSectId` → 不享(NPC 跨派系)
  ///
  /// `playerSectId=null` 时 fallback 单 founder isInSect=false 路径维持(Sect lazy-init
  /// race · sect_providers `currentSectProvider` 未触发场景 · 沿 spec §3 R2 修体例)。
  Future<bool> isBuffActiveFor({
    required Character target,
    required NumbersConfig numbers,
    required int? playerSectId,
  }) async {
    final active = await computeBuffActive(numbers);
    if (!active) return false;
    if (!target.isInSect) return true; // P1.1 fallback 维持
    return target.sectId == playerSectId;
  }
}
