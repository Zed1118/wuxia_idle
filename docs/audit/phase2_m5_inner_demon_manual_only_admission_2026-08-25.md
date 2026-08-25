# Phase 2 M5 心魔本人手动准入生产纵切

## 结论

`P2-M5-INNER-DEMON-MANUAL-ONLY-ADMISSION` 固定验收门由 `0/1` 关闭为 `1/1 READY`。角色面板不再丢失当前目标 ID；心魔首通与重打均先提交 typed `direct + human + realtime` 请求，在开战前复核当前代、生死、疗养、占用与精确装配，然后只把该人的 exact snapshot 交给既有 live stage flow。

- branch: `codex/phase2-inner-demon-manual-only-admission-20260825`
- base: `3fa0655c0b0c88500946aba55dc4f0069cd8e504`
- code candidate: `c6368ce431d9596a5c218fec4b0d6599171a16b2`
- 顶层 M0–M9：仍 `1/10`
- M5 / U14 / M6 / Phase 2：仍开放

## 真实 owner 与生产路径

| 边界 | 真实 owner | 本门结果 |
| --- | --- | --- |
| 目标身份 | `CharacterPanelScreen` | 把 viewed `character.id` 传入心魔页 |
| typed request | `InnerDemonScreen` | 只构造本人 `firstClear|replay` 手动实时请求 |
| admission policy | `InnerDemonParticipationPolicy` | 其他 content/participation/controller/clock/entry 组合全拒绝 |
| 当代/掌门/占用 | `loadDiscipleSchedulingSummary` → `CurrentLeaderResolver` + `CharacterOccupancyService` | 无效掌门、跨代、死亡、疗养、重复占用 fail closed |
| participant snapshot | `resolveInnerDemonParticipantSnapshot` → `PlayerCombatantSnapshotAssembler.loadExactRoster` | 无主修、悬空/错主装备心法、stale 人物拒绝，不回退掌门 |
| controller / runner | `runStageFlow` → 既有 `Phase0aMainlineBattleHost` | 只放开 innerDemon direct snapshot 消费，不新建 runner 或内核 |
| settlement | `applyVictoryResolution` / `applyParticipantDefeatResolution` → `CombatResolutionService` | `expectedParticipantId` 与 settlement 不同人即拒绝 |
| 报告 | `showStageVictoryDialog` / 既有心魔失败事实摘要 | 身份来自 exact snapshot，不再默认掌门 |

## Fail-closed 证据

- 穷举 `ActivityContentKind × participation × controller × clock × entryKind`；只有 innerDemon + direct + human + realtime + `firstClear|replay` 允许。
- 错关、错人、伪造 loadout plan、跨代、死亡、疗养、占用、无主修、悬空装备/心法全部拒绝。
- provider/存档身份异常向上传播为准入失败；UI 只显示不可入场，不选替代角色。
- `runStageFlow` 仍禁止 innerDemon 与主线连续 run / visible replay participant 混用。

## 验证

- RED：3 个契约文件因 policy/service/目标 ID seam 不存在而编译失败。
- 定向首轮：`5/5 PASS`。
- 心魔全域 + 角色面板：`88/88 PASS`。
- 相邻 stage flow / Phase 0A Host / 共享结算 / 心魔失败域：`61/61 PASS`。
- `flutter analyze --no-pub lib test`：0 issue。
- `git diff --check`：0 issue。
- 未重跑数小时整仓全量：已按 90 分钟成本停止线使用风险匹配回归，不冒称全量全绿。

## 边界

零 reducer、session、headless 内核、provider、settlement 真相源、schema/saveVersion、YAML、TUNING/candidate、奖励、经济、解锁、叙事、战斗规则或 main 变更。自动、bot、headless、差遣、扫荡与离线恢复继续 fail closed。
