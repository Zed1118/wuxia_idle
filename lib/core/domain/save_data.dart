import 'package:isar_community/isar.dart';
import 'skill_unlock_entry.dart';

part 'save_data.g.dart';

/// 全局存档元数据（data_schema.md §4.1）。
///
/// **每槽单例**：每个存档槽位对应独立的 Isar db 文件，每个 db 内 SaveData
/// 只有一行，`id` 固定为 0。多存档完全隔离。
///
/// Phase 1 简化：只用 slotId=1，多槽切换推迟到 Phase 5。
@collection
class SaveData {
  /// 每个槽位 db 文件内单例（id 固定为 0）。
  Id id = 0;

  /// 存档槽位号，与 db 文件名 `wuxia_save_slot{slotId}` 对应。冗余存储以
  /// 便存档选择界面快速识别。Phase 1 只用 1。
  int slotId = 1;

  /// 玩家自定义存档名，存档选择界面展示用。
  String? slotName;

  /// 存档版本（semver）。未来 schema migration 用 major.minor 判断。
  late String saveVersion;

  late DateTime createdAt;
  late DateTime lastSavedAt;

  /// 最后在线时间，离线挂机用，玩家关游戏时写入。
  late DateTime lastOnlineAt;

  String? sectName;
  int? founderCharacterId;

  /// 当前出战阵容（FK → Character.id），长度 ≤3。
  List<int> activeCharacterIds = [];

  int totalPlaySeconds = 0;
  bool isOnboardingCompleted = false;
  int highestTowerLayer = 0;

  DateTime? towerLeaderboardSyncedAt;

  /// 新手引导步骤(P1 #42 Phase 2 §10 P1.x 消费)。
  /// 本批 schema 落地 0 业务读写,留接口给 §10 引导骨架按节奏递增解锁。
  int tutorialStep = 0;

  /// 新手引导 banner 已读状(P1 #42 Phase 2 §10 P1.y)。
  /// 值域 `{6, 7, 8}`,玩家点 banner 后 `markHintRead(step)` 同事务 add。
  /// 单调追加不删,UI 端取 `step ∈ {6,7,8} && step ∉ tutorialHintsRead` 渲染。
  List<int> tutorialHintsRead = [];

  /// 收徒提议已发出(P1.1 A1 E.1,GDD §7.1)。
  ///
  /// 玩家在 tutorialStep == 6 时点收徒 banner 进入收徒弹窗,无论接受或拒绝
  /// (D3.a 一次性 only)弹窗 dismiss 时 markOffered → true。一次性 gate,
  /// 防止重触发(audit doc 方案 3 + D3.a 决议)。
  bool recruitmentOffered = false;

  /// 已收徒弟 Character id 列表(P1.1 A1 E.1)。
  ///
  /// inactive 池语义(audit doc 方案 3 + I2 决议):**不入** [activeCharacterIds]
  /// 但 Character 已写 Isar.characters,通过本字段反查「玩家通过收徒新增的弟子」。
  /// 与 lineageRole=disciple + isFounder=false 联合判定(active 弟子也在该字段,
  /// 但本字段只含通过收徒新增的)。1.0 后续扩 active 上限时,可作为升级依据。
  List<int> recruitedDiscipleIds = [];

  /// 已触发 Boss 招降 dialog 的 stage id 列表(P4.1 1.1 Q6B · spec §0 Q8=A)。
  ///
  /// 防玩家刷:Boss 战胜后 `runStageBossRecruitHookAfterVictory` 前置守 — 已含
  /// stage.id 直接 return,不再 rng pick / 不弹 dialog。一次招降成功后 markTriggered
  /// 追加;玩家拒绝 / cap 满 / rng 不命中均不 markTriggered(可重战重遇)。
  List<String> triggeredBossRecruitStageIds = [];

  /// 技能解锁进度(可玩性 P1a · spec §一)。账号级,Boss 真解/残页来源。
  /// 真解首通直接 markUnlocked;爬塔残页 addFragment 累加,达阈值自动 markUnlocked。
  /// 不含奇遇技能(走 equippedEncounterSkillId,两套并存)。
  List<SkillUnlockEntry> skillUnlockProgress = [];
}
