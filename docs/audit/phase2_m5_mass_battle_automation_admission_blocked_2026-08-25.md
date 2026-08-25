# Phase 2 M5 守城自动准入阻塞审计

## 结论

`P2-M5-MASS-BATTLE-AUTOMATION-ADMISSION` 固定门保持 `0/1 BLOCKED`。塔 READY 后复核确认即时 headless 可以复用既有 sweep application runner、`mapMassBattle` 与 production 阵型输入；但本门还要求差遣，当前没有守城 durable run/session、占用种类、阵型快照、离线推进或返程报告 owner，无法在红线内闭环。

- branch: `codex/phase2-mass-battle-automation-admission-requalified-blocked-20260825`
- base: `9b26ccac3c7efb4e696a8138be61e7f8717e268a`
- `ActivityParticipationRequest` consumers in `lib/features/mass_battle`: 0
- `Phase0aHeadlessRunner` consumers in `lib/features/mass_battle`: 0
- 守城域：`13/13 PASS`

## 重资格化 owner 结论

| 边界 | 当前 owner / 能力 | 结论 |
| --- | --- | --- |
| 手动入口 | `MassBattleScreen → runMassBattleChallenge` | 阵型、逐次选人、exact snapshot、共享 live flow 已成立 |
| 内容映射 | `Phase0aStageContentMapper.mapMassBattle` | 可消费 production 阵型并供既有同核 runner 复用 |
| headless 内核 | `Phase0aSweepHeadlessRunner` / `Phase0aHeadlessRunner` | 无需新内核；可扩展模式专用 application 方法 |
| durable 差遣 | 无守城 run/session | 阻塞 |
| 占用真相源 | `ActivityKind {retreat, expedition, bossGauntlet}` + `CharacterOccupancyService` | 无守城角色/装配占用与恢复表达 |
| 阵型持久快照 | 无差遣 owner | 阻塞，不能在运行时猜默认阵型 |
| 离线/返程报告 | 无守城 owner | 阻塞 |

现有进度链、阵型选择、实际参与者 snapshot、共享 live stage settlement 均保留。塔 runner 解除了即时 headless 的技术疑点，但没有提供守城差遣的 durable identity/formation/occupancy/offline/report 真相。固定门要求 bot/headless/差遣同链；只接 headless 会留下无法验收的半成品，因此未写 policy、入口或 runner 方法。解阻前不得复制执行内核或修改 schema/saveVersion、YAML、TUNING、奖励、经济、解锁、叙事、战斗规则或 main。
