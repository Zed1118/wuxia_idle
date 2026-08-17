# Kimi 派单：Phase 0A 波次与唯一终局状态机

## 环境与目标

- 从协调分支 `codex/phase0a-production-batch4-dispatch` 冻结 tip 派生独立 worktree。
- 先读 `CLAUDE.md`、协调计划、反馈事件契约、Phase0a model/events/reducer/session，以及旧 `battle_resolution.dart` 的副作用边界。
- 实现确定性的波次/终局 flow，真实包装 `Phase0aCombatSession`；禁止复制 reducer 或伤害公式。

## 必须实现

1. 在 `domain/phase0a` 增加强类型 wave/outcome 事件与必要的不可变值对象；在 `application/phase0a` 增加薄 flow/session 编排层。
2. 首波事件、清波、换波、胜负的严格顺序按协调计划冻结；所有事件复用全场单调 `seq`，tick 取实际边界拍。
3. 玩家死亡优先 defeat；玩家存活且敌人空才清波。最后一波 cleared 后 victory；非末波 cleared 后立即装入下一波并发 started。
4. 换波只替换 enemies，保留玩家、技能槽、tick/seq 的完整运行态；终局后 advance 必须完全幂等且不触发任何下游调用。
5. 波次/敌人集合防御性不可修改；空波、非 enemy actor、全场重复 id、首态与首波不一致等配置在构造期 fail-fast。
6. 不得 import/call `BattleResolutionService`；它包含掉落、成长、伤势等副作用，只登记为未来终局事件下游。

## 红测与证伪

- 单波：首个 advance 事件以 wave_started 开头，末敌死亡后 cleared→victory，全场唯一。
- 战败：命中/伤害事件之后 defeat；不得同时 cleared/victory。
- 双波：第一波 cleared→第二波 started，同拍 seq 连续；玩家 HP/真气/CD/技能槽/tick 连续，敌人换为下一波。
- 终局后至少再调两次：空事件、state/outcome/tick/seq 不变；用计数 resolver 证明零调用。
- 同 seed 两实例执行同命令序列，事件、state、outcome 全等。
- 构造期非法配置逐项 fail-fast；外部 list 构造后 mutation 不影响 flow。
- 从新 flow 的 `advance` 穿透 `Phase0aCombatSession → adapters → reducer → DamageCalculator adapter` 至少一项真实链路测试，不只测 fake helper。

## 禁区与交付

- 禁改 UI、奖励、存档、Isar、YAML/schema/saveVersion、GDD/PROGRESS、probe、旧 3v3、生产路由、`BattleResolutionService`、`DamageCalculator` 数学。
- 不新增调优数值默认值或中文玩家文案；不引入 Flutter/Flame/probe 依赖。
- 小切片 commit；最终跑 Phase0a 全套、damage calculator 回归、nested probe 8 项、`flutter analyze --no-pub`、`git diff --check`。
- 最终 tip 用 `[READY]` 或 `[BLOCKED]`，worktree 干净；报告测试计数、范围与残留风险。
