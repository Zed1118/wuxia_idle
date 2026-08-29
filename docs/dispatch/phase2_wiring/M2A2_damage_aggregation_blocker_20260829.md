# M2A2 聚合伤害阻塞记录（2026-08-29）

## 结论

`[BLOCKED]`。当前生产架构只能可靠区分普通敌人、精英、Boss 与玩家的即时伤害，不能识别方案 §16.4 要求短窗口聚合的毒/内伤伤害。继续只做可达部分会缩小既定范围；自行补齐状态伤害生产链会引入尚未冻结的技能语义与伤害规则。两条路线分别触发作业宪法 §2.8 与 §10，故在写实现前停止。

## 本会话实测

- 基线：`a500248c4e58f055b6acf462d4eadf9693538df5`
- 分支：`codex/p2-m2-damage-aggregation-20260829`
- `Phase0aVfxController.consume` 只从 `Phase0aHitLanded`、`Phase0aGatherApplied`、`Phase0aClearApplied`、`Phase0aSkillApplied` 生成伤害飘字；这些事件均没有伤害来源类型字段。
- `TimedStatusType` 包含 `internalInjury` 与 `poison`，`StatusDamage` 也携带类型；但 `rg -n "TimedStatusLedger|StatusDamage|TimedStatusType" lib test` 的生产命中全部局限在 `lib/features/battle/domain/phase0a/status_effects.dart`，其余命中仅为该文件的单测，没有 reducer、flow、adapter、controller 或 screen 消费点。
- 反向复搜 `rg -n "status_effects|internalInjury|poison" lib/data lib/features` 仍未找到状态伤害进入生产战斗事件链的路径。
- 现有真实 BattleScreen 测试仍断言 R 的每个非零 outcome 各显示一个精确数字；聚合显示将改变该玩家可见契约，而 gate 又禁止删改原断言来求绿。

## 已冻结、可直接实现的部分

- 同一次攻击对普通敌人的伤害在显示居民层合并为“总伤害 + 命中目标数”。
- Boss、精英保留独立数字。
- 玩家受伤在 6–8 组居民上限内拥有最高保留优先级。
- 原始结算事件、逐目标命中/格挡/破势语义保持不变。

## 待用户拍板（推荐方案在前）

1. **推荐：批准两段式范围。** 先完成所有当前生产可达的聚合规则并保留真实逐目标事件；把毒/内伤短窗口聚合作为“状态伤害生产接线”前置完成后的同一 M2A2 后续，不把本批局部完成冒充整项通过。
2. **扩大本单。** 先冻结毒/内伤的生产技能来源、目标、tick cadence、事件 payload 与内容映射，再由本单一并接通状态伤害和聚合表现。

未获拍板前不修改 `lib/`、测试、数值、schema 或 gate。

## 用户决定（2026-08-29）

用户回复“同意按照推进方案”，批准上述推荐的两段式范围。本分支恢复为 M2A2a：先完成当前生产链可达的普通怪/Boss/精英/玩家聚合规则；M2A2 总项仍保持未关闭，毒/内伤必须在状态伤害生产接线具备真实消费点后补齐。

## M2A2a 实现与验收分母

- `Phase0aVfxController` 给每条原始伤害 entry 绑定事件 `seq` 分组键，并从同步 actor 的 `side/isBoss/defeatKind` 生成 typed 目标档；不修改结算事件历史。
- `Phase0aDamagePopupAggregator` 仅折叠同组的普通敌人，输出总伤害、命中数、任一暴击语义和稳定上方锚点；精英、Boss、玩家与未知目标逐条保留。
- 真实 `Phase0aBattleScreen` 首结算帧保留逐目标命中/致死确认，下一绘制帧收束普通群怪；居民仍受既有 8 组上限约束。
- 居民淘汰顺序为普通、未知、精英、Boss、玩家，同档内暴击优先保留；低优先级新组不能挤掉全玩家伤害池。
- 伤害数字在反馈 Stack 中先绘制，Boss 蓄力与破势反馈后绘制；双视口断言聚合组留在视口内且不覆盖玩家 HUD。
- M2A2a 的 targeted 分母为新增聚合单测、新增真实屏双视口测试、既有 event mapping、既有 BattleScreen 四个文件；M2A2 总项分母另含尚未可达的毒/内伤短窗口聚合。

### 当前 targeted 实测（提交前）

- `phase0a_damage_aggregation_test.dart`：`+4: All tests passed!`
- `phase0a_damage_aggregation_screen_test.dart`：`+2: All tests passed!`
- `phase0a_event_mapping_test.dart`：`+44: All tests passed!`
- `phase0a_battle_screen_test.dart`：`+28: All tests passed!`
- `flutter analyze --no-pub lib test`：`No issues found!`
- `dart format --output=none --set-exit-if-changed .`：`Formatted 1632 files (0 changed)`

## M2A2b 状态伤害生产接线与短窗聚合（2026-08-29）

### 结果合同与范围边界

- 单一目标：关闭 M2A2 剩余的 poison/内伤短窗口聚合，同时保持即时伤害、逐目标事件、格挡与破势语义不变。
- 验收分母：既有阴柔克灵巧 `internal_injury` 必须从生产 `DamageCalculator` adapter 进入 reducer；下一逻辑拍起按已有 `yin_rou_internal_injury` 配置固定扣血、同源刷新、可致死；事件排序、战后统计、objective 快照和真实 `BattleScreen` 双视口均消费同一 typed 事件；短窗外不得继续合并。
- 实时基线：`2c031ffbe32812df5ea6d9e9ce8bc46a03591157`（M2A2a 已合并并经 CI 通过）。
- 当前阻塞：无。原阻塞由用户批准两段式推荐方案解除；M2A2b 不新增毒技能、毒数值、配置字段、schema 或玩家文案。
- 预期增量：M2A2 从“普通即时伤害已聚合、状态伤害不可达”推进为全部既定聚合规则具备生产消费点。
- 成本上限：只接通已有状态候选与既有内伤配置，不扩 slow/root 行为、不改冻结数值、不新增内容来源。

### 实现判定

- `Phase0aResolvedHit.appliedStatus` 只承载 adapter 已解析的 typed 状态；reducer 不回查 numbers、不复制伤害公式。
- 生产 adapter 只把真实 `AttackResult.appliedEffects` 中的 `internal_injury` 映射到已有 3 拍/每拍 200/refresh 配置。主动闪避阻止 follows-main-hit 状态附着。
- `TimedStatusLedgerSnapshot` 让 actor 状态进入不可变 arena 回放；reducer 每逻辑拍统一推进 internal injury/poison，直接扣 HP 并发 `Phase0aStatusDamageApplied`，敌人死亡继续走既有 `Phase0aEnemyDefeated`。
- poison 只具备通用 typed 消费路径与预置状态测试，不虚构生产技能来源。
- VFX entry 使用 `statusType + source + target` 精确键；`BattleScreen` 仅在既有 `damagePopupSeconds` 短窗内合并总伤害与 tick 数。视觉验收延长 hold 不会扩大聚合窗口。

### TDD 证据

- 首次 targeted 编译按预期失败：`TimedStatusLedger.fromSnapshot` 与 `snapshot` 不存在，reporter 为 `+0 -1` 并含 `[E]`，证明测试先于实现。
- 实现后新增三文件联合 targeted：`+19: All tests passed!`；随后生产接线 + 双视口屏幕联合复跑：`+5: All tests passed!`。
- 扩大回归逐文件通过：status ledger `+14`、生产状态接线 `+3`、双视口短窗 `+2`、reducer `+29`、DamageCalculator adapter `+20`、旧 event mapping `+44`、wave flow `+21`、即时聚合单测 `+4`、即时聚合双视口 `+2`、BattleScreen `+28`；各文件 reporter 均为 `All tests passed!` 且 `[E]` 计数为 0。

### 提交后双向破坏证红

- `remove_implementation`：删除 `_reserveDamagePopupResident` 对状态短窗合并支点的调用，同一 19-case targeted 变为 `+17 -2: Some tests failed.`，双视口各红 1 个。
- `force_degenerate_value`：把聚合总额强制退化为仅保留最新 tick 伤害，同一 targeted 再次为 `+17 -2: Some tests failed.`，双视口各红 1 个。
- 两向均用精确反向补丁恢复；每次恢复后实测 `git diff --quiet` 为 `0`，`git status --short` 无输出。
- 全量回归修复 commit `e3172d9a` 后再次执行上述两向破坏，实测仍分别为 `+17 -2`；两次恢复后仍为 `git diff --quiet` rc=0 且空状态，证据绑定最终生产实现。

### 首次全量暴露的下层回归

- 首次带锁全量为 `08:47 +5676 -3: Some tests failed.`、`[E]` 3：两个 reducer guard 断言发现无状态 actor 被空 ledger timeline 污染；源码契约发现空快照存在字面量 `= 0`。
- 修复不改测试与数值：无 active status 时 reducer 完全不推进 ledger；空 ledger snapshot 归一为 const empty；timeline 初值改为语义常量。原失败文件及状态接线定向复跑为 `+54: All tests passed!`。

### 最终本地收工证据

- 关键 targeted 逐文件：status ledger `+14`、生产接线 `+3`、双视口短窗 `+2`、reducer guard `+17`、source contract `+20`、reducer `+29`，全部 `All tests passed!` 且 `[E]` 0。
- analyze：`No issues found! (ran in 6.5s)`。
- format：`Formatted 1634 files (0 changed)`。
- 第二次带锁全量：`07:53 +5679: All tests passed!`，`[E]` 0；锁由 trap 精确释放。
