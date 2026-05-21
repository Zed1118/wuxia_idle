import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/isar_setup.dart';
import '../../../data/numbers_config.dart';

/// 祖师爷 buff 激活态判定(P1.1 A1 E.5,GDD §7.1)。
///
/// 决议方案 E.5.A(audit `p1_1_a1_recruitment_audit_2026-05-21.md` 后续 + 用户拍板):
/// `enabled_when_alive: true` 时,**active 集合中存在 isFounder=true 角色** → buff 激活。
/// caller 端拿到 [computeBuffActive] 返回值传给 `CharacterDerivedStats.*` 的
/// `founderBuffActive` 可选参数。
///
/// **设计纪律**:
/// - 纯 read service,无 writeTxn
/// - 静态 + Isar 注入(对齐 [TutorialService] 体例)
/// - Phase 5+ 飞升机制实装时,本 service 扩展 trigger 条件
///   (eg. 改判「founder 是否已飞升退出 active」)
class FounderBuffService {
  final Isar isar;

  FounderBuffService(this.isar);

  /// buff 是否处于激活态:
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
}
