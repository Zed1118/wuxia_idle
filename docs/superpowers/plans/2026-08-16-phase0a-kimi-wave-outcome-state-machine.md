# Phase 0A 波次与唯一终局状态机(Kimi 执行计划 · 第四批切片 2)

> 派单:`docs/dispatch/packages/2026-08-16_phase0a_kimi_wave_outcome_state_machine.md`
> 协调计划:`docs/superpowers/plans/2026-08-16-phase0a-production-batch4-dispatch.md`
> 反馈契约:`docs/spec/2026-08-16-phase0a-production-feedback-contract.md`(§波次与终局)

## 目标

在 `domain/phase0a` 增加强类型 wave/outcome 事件与不可变波次值对象,在
`application/phase0a` 增加薄 flow 编排层,真实包装既有 `Phase0aCombatSession`,
产出 `wave_started` / `wave_cleared` / `battle_victory` / `battle_defeat`,
冻结模拟核到 session 的唯一终局。不接奖励、存档、UI、旧 3v3、生产路由。

## 分支 / worktree

- worktree:`.worktrees/phase0a-kimi-wave-outcome`
- 分支:`feat/phase0a-kimi-wave-outcome`(从协调分支冻结 tip `a543a1f8` 派生)

## 已冻结边界(协调计划 + 2026-08-16 用户补充拍板)

- 事件顺序:首波 `wave_started` 全场一次、排在首个战斗事件前;击杀末敌固定
  `enemy_defeated → wave_cleared → next wave_started | battle_victory`。
- 终局唯一:每拍 reducer 结束后唯一派生;玩家死亡优先 `battle_defeat`
  (病态双方同时为空也按 defeat);终局事件全场至多一条。
- **拍板Ⓐ(用户补充)**:事件 payload 的 `waveIndex` 用 **1-based**(首波=1,
  直对「第 N 波」);flow 内部 list index 保持 0-based 但不外泄。
- **拍板Ⓑ(用户补充)**:所有 flow 自发事件都把消耗的 seq 持久化回 state
  (`nextSeq` 含终局事件);「终局后不变」以已含终局事件的 state 为基准。
- 终局后 `advance` 返回空事件,不推进 tick/seq,不调用 adapter/resolver/reducer。
- 换波只替换 enemies:玩家 HP/真气/普攻 CD、技能槽 CD/可用态、tick/seq 全保留;
  换波不消耗额外拍(cleared 与下一波 started 同拍)。
- `wave_started` / `wave_cleared` / 终局事件的 tick 取实际边界拍(首波 = 首个
  advance 的拍;换波/终局 = 末敌死亡拍)。
- 波次列表与敌人列表防御性不可修改副本;波次非空、每波敌人非空/均 enemy side、
  全场 actor id 唯一、首态 enemies 与首波一致、玩家 side=player,构造期 fail-fast。
- 禁 `BattleResolutionService`(含 import);数值默认值禁令沿源码契约测。
- 不复制 reducer/移动/AI/命中/伤害/CD/真气规则;flow 只做事件序与波次装配。

## 设计要点

- domain: `phase0a_combat_events.dart` 增 4 个 sealed 事件子类(sealed 约束
  必须同库);新文件 `phase0a_wave.dart` 放 `Phase0aWave`(不可变、自校验)
  与 `Phase0aBattleOutcome` 枚举。
- application: 新文件 `phase0a_wave_battle_flow.dart` 的
  `Phase0aWaveBattleFlow` 包装 `Phase0aCombatSession`,不新增任何结算规则。
- **拍板Ⓒ(用户架构纠偏,2026-08-16)**:`Phase0aCombatSession` 不增任何
  public `replaceState`/`setState` 可变后门。flow 自存构造依赖(initialState、
  playerAdapter、enemyAiAdapter、damageResolver、waves)与 mutable 私有
  `_session`;需预留 seq / 换波装敌 / 固化终局 seq 时,用新
  `Phase0aArenaState` 重建私有 `_session`,但复用同一 adapter/resolver 实例,
  保证 seeded RNG 连续、外部无法任意注入状态。
- 首波 seq 预留:reducer 从 `state.nextSeq` 起分配,flow 在首个 advance 前以
  `nextSeq+1` 的新 state 重建 `_session`,再用预留 seq 发 `wave_started`;
  advance 抛错时恢复原 `_session` 与 `_started` 标记。

## 验收标准(红测逐项对应)

1. 单波:首个 advance 事件以 `wave_started(1/1)` 开头;末敌死亡拍
   `enemy_defeated → wave_cleared → battle_victory` seq 严格连续;终局全场唯一。
2. 战败:命中/伤害事件后 `battle_defeat`;同拍不得有 cleared/victory。
3. 双波:第一波 cleared → 第二波 started 同拍 seq 连续;玩家 HP/真气/CD/
   技能槽/tick 连续;敌人换为下一波;waveIndex 1-based(1→2)。
4. 终局后再 advance ≥2 次:空事件、state/outcome/tick/seq 不变(基准 = 含终局
   事件的 state);计数 resolver 证明零调用。
5. 同初态同命令序列两实例:事件/state/outcome 全等。
6. 非法配置逐项构造期 fail-fast;外部 list 构造后 mutation 不影响 flow。
7. flow.advance 穿透 `Phase0aCombatSession → adapters → reducer →
   Phase0aDamageCalculatorAdapter` 真实链路(真实 numbers fixture + direct
   `calculateResolved` 对照 + 同 seed 回放)。
8. 源码契约测扩展:application/phase0a 禁 `BattleResolutionService` /
   `battle_resolution.dart`。
9. Phase0a 全套、damage calculator 回归、nested probe 8 项、
   `flutter analyze --no-pub`、`git diff --check` 全绿;worktree 干净。

## 切片

1. [ ] 本计划档 commit。
2. [ ] 红测:`phase0a_wave_flow_test.dart` + 源码契约扩展 commit(证红)。
3. [ ] 最小实现:domain 事件/值对象 + flow(私有重建 session)commit(转绿)。
4. [ ] 全验证 + 恢复点更新 + `[READY]` tip。

## 当前恢复点

- 状态:计划档已冻结并勘误(拍板Ⓒ),红测编写中。
- 最后完成:通读派单/协调计划/反馈契约/CLAUDE.md/既有 phase0a 源码与测试;
  确认 worktree 干净、基线 HEAD=`a543a1f8`、probe 8 项 =
  `tools/phase0minus_probe test/gameplay/combat_rules_test.dart`;
  计划档 commit `43dac7e0`;按用户架构纠偏完成拍板Ⓒ勘误(未写过任何
  replaceState 代码,红测未受影响)。
- 下一步:commit 红测并证红 → 最小实现。
- 已跑验证:无(仅只读勘察)。
- 阻塞项:无。
