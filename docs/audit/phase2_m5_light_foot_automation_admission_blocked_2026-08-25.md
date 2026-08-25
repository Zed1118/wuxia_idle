# Phase 2 M5 轻功自动准入阻塞审计

## 结论

`P2-M5-LIGHT-FOOT-AUTOMATION-ADMISSION` 固定门保持 `0/1 BLOCKED`。塔 READY 后复核确认即时 headless 可以复用既有 sweep application runner 与 `mapLightFoot`，但本门还要求差遣；当前没有轻功 durable run/session、占用种类、离线推进或返程报告 owner，不能在禁止 schema/共享真相源变更的前提下形成完整生产闭环。

- branch: `codex/phase2-light-foot-automation-admission-requalified-blocked-20260825`
- base: `5b648cf07da5a15114816996ec8e869f688db345`
- `ActivityParticipationRequest` consumers in `lib/features/light_foot`: 0
- `Phase0aHeadlessRunner` consumers in `lib/features/light_foot`: 0
- 轻功域：`12/12 PASS`

## 重资格化 owner 结论

| 边界 | 当前 owner / 能力 | 结论 |
| --- | --- | --- |
| 手动入口 | `LightFootScreen → runLightFootChallenge` | 逐次选人、exact snapshot、共享 live flow 已成立 |
| 内容映射 | `Phase0aStageContentMapper.mapLightFoot` | 可供既有同核 runner 复用 |
| headless 内核 | `Phase0aSweepHeadlessRunner` / `Phase0aHeadlessRunner` | 无需新内核；可扩展模式专用 application 方法 |
| 共享结算/报告 | `runStageFlow` 的 shared stage settlement | live 已成立；headless 尚无玩家入口与写前 stale guard |
| durable 差遣 | 无轻功 run/session | 阻塞 |
| 占用真相源 | `ActivityKind {retreat, expedition, bossGauntlet}` + `CharacterOccupancyService` | 无法表达轻功差遣、锁装与恢复；扩展触及共享真相源/持久模型 |
| 离线/返程报告 | 无轻功 owner | 阻塞 |

## 边界

逐次参与者选择、当代身份、疗养/占用/主修、悬空装备心法与 exact snapshot 已由现有 service fail closed；共享 stage flow 负责 live 结算。塔 runner 只解除了“即时 headless 内核不可复用”的技术疑点，没有提供轻功差遣的 durable identity/occupancy/offline/report 真相。

固定门要求 bot/headless/差遣同链；只接 headless 会留下未关闭 WIP 且无权威分母变化，因此没有写孤立 policy、按钮或 runner 方法。解阻需要用户授权扩展持久活动/占用模型与 saveVersion，或明确把差遣移出本门；在此之前不得复制 `runStageFlow`、新增第二 headless 内核，亦不得改 schema/saveVersion、YAML、TUNING、奖励、经济、解锁、叙事、战斗规则或 main。
