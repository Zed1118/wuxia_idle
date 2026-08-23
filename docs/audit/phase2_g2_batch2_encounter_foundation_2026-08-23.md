# Phase 2 G2 Batch2 遭遇基础合同审计

## 结论

G2 Batch2 的三条纯领域合同已完成集成和主控复审，可进入 READY。本批没有改动 reducer、伤害、奖励、伤势、存档、UI 或生产关卡数据，也没有启用刷怪或攻击令牌调参。

## 交付内容

- D01 `SpawnDirector`：显式入口、total/active/warning/pending/removed 状态、补兵阈值、入场预警、攻击宽限、确定性事件。所有 tuning 由调用方显式传入。
- D02 `AttackTokenDirector`：近战/远程/冲锋/支援预算、安全闸门、每批最多一个不可阻挡大范围攻击、确定性优先级。仅交付无状态分配合同，未接入 intent 过滤。
- E01 `ActivityParticipationRequest`：content/character/loadout/participation/controller/clock/entry 全显式请求，不选角色、不写 fallback、不替用户决定重打/扫荡/`MainlineRun` 语义。

## 主控修正

- 将 D01 `enemyId` 锁定为全局唯一的敌人实例 ID，与可重复的敌人类型分离；重复 `entryId` / `enemyId` 均 fail closed。
- 将 D02 `actorId` 收紧为调用方已规范化的 trimmed non-empty ID，并将 `AttackTokenDecision` 改为私有构造，避免表达非法 granted/denial 组合。
- 补齐 D01 状态计数守恒、重复实例 ID 输入顺序和同拍事件顺序测试；补齐 D02 安全闸门优先级、grace 边界与无跨调用状态测试。

## 复审

- Codex D01 独立复审：0 P0 / 0 P1；3 个 P2 测试缺口已在集成态关闭。
- Codex D02/E01 独立复审：0 P0 / 0 P1；可接受进入 Batch2 READY。

## 验证

- 三条新合同 targeted tests：64/64 通过。
- realtime rules + reducer + headless kernel：63/63 通过。
- mainline live/headless wiring + wave flow：38/38 通过。
- `flutter analyze --no-pub`：0 issues。
- `git diff --check`：通过。

## 边界与下一步

本 READY 只代表遭遇基础合同完成，不代表黑风岭 35–45 总量 / 8–16 活跃 / 2–4 令牌的生产纵切已完成。下一批应先抽取 `Phase0aBattleFlow` 小接口，建立 `Phase0aEncounterFlow` 的 compatibility/observe-only seam，保留单 reducer/session/headless 内核；仅在关卡数据和产品语义冻结后才启用 token enforce。
