import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/isar_provider.dart';
import '../../main_menu/application/main_menu_status_summary_provider.dart';

/// 「江湖远行」解锁里程碑绝对境界层 = 三流·熟练(Lv100 顶)。任一角色达此层即永久
/// 解锁,永不回锁(companion §L53:「离队/传承/境界变化不回锁」)。**发布上限
/// 10→17 后,解锁线仍钉 Lv100(里程碑),不随 cap 上移**——Lv100 是「江湖远行」的
/// 内容起点,cap=17 只是其成长空间的上界。
const int kJianghuJourneyUnlockAbsoluteLevel = 10;

/// 角色绝对境界层(1-49),纯 tier/layer 派生,与 `RealmDef.absoluteLevel` 同布局
/// (7 层/阶),不依赖 GameRepository(启动 gate 轻量友好、单测无需加载 defs)。
int _absoluteLevelOf(Character c) =>
    c.realmTier.index * RealmLayer.values.length + c.realmLayer.index + 1;

/// 任一角色是否已达江湖远行解锁里程碑(≥Lv100)。
bool anyCharacterReachedJourneyMilestone(Iterable<Character> characters) =>
    characters.any(
      (c) => _absoluteLevelOf(c) >= kJianghuJourneyUnlockAbsoluteLevel,
    );

/// 纯里程碑判定:[save] 未解锁且任一角色 ≥Lv100 → in-place 置 true 返 true(已变更);
/// 已解锁或无人达标返 false。永久不可逆(只置真、永不清);持久化由 caller 负责。
bool unlockJianghuJourneyIfReached({
  required SaveData save,
  required Iterable<Character> characters,
}) {
  if (save.jianghuJourneyUnlocked) return false;
  if (!anyCharacterReachedJourneyMilestone(characters)) return false;
  save.jianghuJourneyUnlocked = true;
  return true;
}

/// Isar 落库核心(同 `settleActiveExpeditionOnOpen` 体例:注入 [isar] 单测友好)。
/// 读存档0 + 全角色 roster,任一 ≥Lv100 且未解锁 → 单 writeTxn 落库置真,返 true。
/// save 缺失 / 已解锁 / 无人达标 → 零写返 false。
Future<bool> unlockJianghuJourneyOnOpen(
  Isar isar, {
  @visibleForTesting Future<void> Function()? beforeWriteTxn,
}) async {
  final save = await isar.saveDatas.get(0);
  if (save == null || save.jianghuJourneyUnlocked) return false;
  final characters = await isar.characters.where().findAll();
  if (!anyCharacterReachedJourneyMilestone(characters)) {
    return false;
  }
  await beforeWriteTxn?.call();
  return isar.writeTxn(() async {
    final current = await isar.saveDatas.get(0);
    if (current == null ||
        !unlockJianghuJourneyIfReached(save: current, characters: characters)) {
      return false;
    }
    await isar.saveDatas.put(current);
    return true;
  });
}

/// 主菜单首帧调用(与 `maybeSettleExpedition` 并列,挂 `MainMenuStartupGate`
/// post-frame)。isar 缺失即 no-op(轻量启动 / 未 init Isar 安全)。新解锁后失效
/// `mainMenuSaveSnapshotProvider`,让主菜单「江湖远行」入口即时出现(§5.7 隐藏式)。
Future<void> maybeUnlockJianghuJourney(WidgetRef ref) async {
  final isar = ref.read(isarProvider);
  if (isar == null) return;
  final unlocked = await unlockJianghuJourneyOnOpen(isar);
  if (unlocked) ref.invalidate(mainMenuSaveSnapshotProvider);
}
