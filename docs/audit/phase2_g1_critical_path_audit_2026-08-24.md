# P2 G1 关键路径事实审计

日期：2026-08-24
基线：`6941bca57299df6d7c5c97476610f1d18eb0bea4`

## 结论

G1 的四个非终态登记中，两个 integration 是状态漂移，两个 partial 是真实生产缺口。没有理由重跑 Batch1/Batch2 或继续创建证据型微任务。

## 状态漂移

- Batch1 分支 tip `29f04073b811012b9c217c944175cfb4d512e2ef` 的提交前缀为 `[READY]`，是当前 HEAD 祖先；审计记录联合 173/173、全仓 analyze 0，Pi/Qoder 复核完成。
- Batch2 分支 tip `56450ba309000c5562c0db73632f7ac6046634a0` 的提交前缀为 `[READY]`，是当前 HEAD 祖先；审计记录联合 100/100、C11 33/33、全仓 analyze 0，Pi/Qoder 复核完成。
- 两项只从 `ready_candidate` 订正为 `ready_reviewed`，不改代码、不重做门禁、不把 C11/C12 partial 伪装成完成。

## C11 真实缺口

生产代码仍有三处明确读方：

- `phase0a_stage_content_mapper.dart:_numericSkillBindings`：`cooldownTurns × playerAttackCooldownSeconds`，当前基线间隔 0.55 秒；
- `_enemyPhaseSkillBindings`：`cooldownTurns × enemyAttackCooldownSeconds`，当前基线间隔 1.0 秒；
- `_chargeCast`：同上，当前基线间隔 1.0 秒。

Q/R 已用显式 5 秒/8 秒，不属于剩余阻塞。同一技能可能跨玩家与敌方复用，故不能猜一个通用秒值同时覆盖两种旧执行语义。推荐冻结详批次计划；用户未批准前保持 `ready_reviewed_partial`。

## C12 真实缺口

`Phase0aBotTacticPolicy.seekGap/assault/steadyGuard` 与确定性测试已经存在，但当前生产 `Phase0aPlayerBotAdapter` 构造均未注入显式 policy，实际只消费默认 `production()` 兼容画像。三战术没有产品 selector，也未形成“同角色快照、同 seed、同战术”的 production live/headless 验收链，因此保持 `ready_reviewed_partial`。

## 调度边界

下一工作只允许 C11/C12 关闭、Ch1 production catalog、`stage_01_03` 黑风岭纵切和 G2 八项。远征/驱散独立小批不会混入；G2 前不扩面 M3/M4、五武器、其余生态、21 章或 49 塔。
