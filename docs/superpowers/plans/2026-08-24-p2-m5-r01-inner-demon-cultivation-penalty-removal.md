# P2 M5 R01：心魔主修修炼度惩罚移除

## 目标与合同

- 基线：`f1dc0c9efd0a4548b31a3531e7332b91a1febbd4`。
- 分支：`codex/phase2-m5-r01-inner-demon-cultivation-penalty-removal-20260824`。
- 外部复核：Pi CLI，精确模型 `deepseek/deepseek-v4-flash`，thinking `high`；Pi
  只读复核，Codex 是唯一写入者。
- 仅修改任务登记的 R01 owned files，以及主控追加授权的
  `inner_demon_panel_test.dart`、`inner_demon_progress_test.dart` 两个直接构造夹具。
- 旧 `failure_penalty` 配置必须被拒绝，而不是继续兼容或默认为 1.0。
- 心魔失败不再扣主修修炼度；唯一保留的失败惩罚是受上限约束的内息紊乱。
- 主修进度、境界、永久内力不得发生失败惩罚写回；不得产生惩罚性装备回退或
  物理伤势。完整 BattleResolution 的正常装备 `battleCount` 增长必须保留。
- 结果允许保留主修修炼度 before/after 证据，但两者恒等且不得用于写回。
- 不修改 registry、GDD、CLAUDE、PROGRESS、R02，不扩 AI、调参或持久化。

## 实现切片

1. `data/numbers.yaml` 删除退役 `failure_penalty` 段，并更新同段配置注释。
2. `InnerDemonDef.fromYaml` 对存在的 `failure_penalty` 键 fail-fast；删除
   `InnerDemonFailurePenalty` 类型、字段、构造参数与默认值。
3. `InnerDemonService.applyFailurePenalty` 删除 penalty 参数与修炼度写回，只应用
   capped inner disorder；结果保留相同 before/after 证据。
4. `CombatResolutionService` 不再传递旧 penalty，保留通用技能使用、装备
   `battleCount`、持久化事务及其他正常结算。
5. 更新配置、领域、service、combat resolution 与两个直接构造夹具测试。

## Pi 设计复核证据

- 版本：Pi CLI `0.84.1`。
- 命令：
  `pi --no-session --no-skills --model deepseek/deepseek-v4-flash --thinking high --tools read,grep,find,ls --print <R01 design prompt>`。
- 权限：Read/Grep/Find/Ls-only，无仓库写入、无测试执行。
- 时长与结果：约 205 秒正常退出，`DESIGN PASS`。
- 结论：最小生产改动为 numbers/schema、service、combat resolution 四处；必须把
  numbers 删除与 schema 拒绝同批落地，避免中间态启动失败；R02 独占旧战败
  banner 文案订正。Pi 识别的 P0 是同批原子落地与穷举构造点，P1 是恒等证据字段
  说明和 R02 边界，均纳入本计划；历史文档/registry drift 不越界修改。

## TDD 与验证清单

- [x] 外部设计复核有命令、版本、精确模型和结论证据。
- [ ] 配置键与类型入口退役；任意 `failure_penalty` 键（含空 map）显式拒绝。
- [ ] service 仅应用 capped disorder，主修 before/after 恒等且不写回。
- [ ] combat resolution 锁主修、境界、永久内力、装备字段、伤势不变；正常
  `equipment.battleCount` 增长继续发生。
- [ ] targeted 覆盖死配置、配置加载、service、combat resolution、直接构造夹具及
  R02 兼容回归，逐文件记录 pass 数。
- [ ] scoped analyze 为零；format、diff check、exact owned paths、clean status 通过。
- [ ] Pi 以同一精确模型完成 actual diff 只读终审，Codex triage 后 P0/P1/P2=0。

## CLAUDE §8.2 四项证据

1. **生产接线**：真实路径为 `CombatResolutionService.resolveSnapshot` 心魔失败分支
   → `InnerDemonService.applyFailurePenalty` → `InnerBreathDisorder.apply`；删除唯一
   cultivation 写回，但保留完整通用结算与事务。
2. **Targeted tests**：待实现后回填逐文件命令与 pass 总数，不以 analyze 替代。
3. **红线影响**：不改伤害/血量/内力上限、三系、在线=离线、反主流项或玩家文案；
   删除的是已冻结退役的 10% 惩罚数值，schema 对死配置 fail-fast。
4. **残留风险**：R02 负责 defeat summary 文案对齐；本任务不改 AI、tuning、host、
   durable/schema persistence 结构或历史审计快照。最终回填未覆盖项。

## 当前恢复点（CLAUDE §8.0）

- 状态：设计复核完成，准备进入 TDD 红测。
- 最后完成：完整读取 CLAUDE、rejected registry、R01 计划、task/decision contract；
  核验基线与 clean；完成 Pi 0.84.1 exact model 只读设计复核并获 DESIGN PASS。
- 下一步：读取 owned production/tests 现状，先写退役配置与不变项红测。
- 已跑验证：仅只读合同核对与 Pi 设计复核；尚未运行任务测试。
- 阻塞项：无。R02 文案与本任务边界已明确。
