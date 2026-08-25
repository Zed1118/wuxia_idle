# Phase 2 M5 守城自动准入阻塞审计

## 结论

`P2-M5-MASS-BATTLE-AUTOMATION-ADMISSION` 固定门保持 `0/1 BLOCKED`。真实链为 `MassBattleScreen → runMassBattleChallenge → resolveMassBattleParticipantSnapshot → runMassBattleStageFlow → runStageFlow`，只支持 realtime 手动亲战；不存在玩家可达的 bot/headless/差遣 runner。

- branch: `codex/phase2-mass-battle-automation-admission-blocked-audit-20260825`
- base: `b07b638ed5561f8580f1576e1c43b05b6052e26f`
- `ActivityParticipationRequest` consumers in `lib/features/mass_battle`: 0
- `Phase0aHeadlessRunner` consumers in `lib/features/mass_battle`: 0
- 守城域：`13/13 PASS`

现有进度链、阵型选择、实际参与者 snapshot、共享 live stage settlement 均保留。缺口是首通后的权威自动 runner owner，不是 enum 或 UI 开关。解阻前不得复制执行内核或修改 schema/saveVersion、YAML、TUNING、奖励、经济、解锁、叙事、战斗规则或 main。
