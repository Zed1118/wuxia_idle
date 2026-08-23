# P2-M2-R17：迁移遭遇结算适配

## 目标与边界

从 `a952274781a11283ff5d7675ad270034a94cfd69` 出发，为 R11 已冻结的
`Phase0aEncounterMapping` 增加终局结算入口，使迁移遭遇与旧
`Phase0aStageMapping` 复用同一个结算 core，不复制伤害、暴击、技能
释放或参战者聚合规则。

- 工作树：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r17-migrated-encounter-settlement-adapter`
- 分支：`codex/phase2-m2-r17-migrated-encounter-settlement-adapter-20260824`
- owned files 严格仅：
  - `lib/features/battle/application/phase0a/phase0a_settlement_adapter.dart`
  - `test/features/battle/application/phase0a/phase0a_migrated_encounter_settlement_test.dart`
  - 本计划
- 禁止接入或推断 route / objective / reward / injury / host /
  persistence / data / candidate / tuning；不改 production caller。

## 冻结 API 与结算事实

```dart
static CombatSettlementSnapshot fromEncounterMapping({
  required Phase0aEncounterMapping mapping,
  required Phase0aBattleOutcome outcome,
  required Phase0aArenaState finalState,
  required List<Phase0aEvent> events,
})
```

- `fromMapping` 与新入口只解包各自 mapping 已冻结的
  `initialState` / `combatants` / `moveBindings`，随即委托同一个私有
  settlement core。
- core 只消费现有显式事实：初始玩家 actor ID、combatant 与
  character ID、move binding、终局 arena、终局 outcome 与语义事件。
- `ongoing` 拒绝结算；终局玩家 ID/阵营必须精确匹配；已映射
  combatants 中玩家 actor 必须恰好一次，否则 fail closed。
- 参战者顺序继承 combatants；玩家 HP 来自终局 player，其他角色
  若不在终局 active actor 集合中（后备或已离场）则 HP=0，不从
  director/roster 推断生存状态。
- 两个公开入口在进入 core 时对 combatants / move bindings / events
  建立防御性快照；返回的 `CombatSettlementSnapshot` 继续由其既有
  constructor 冻结 participants / casts / damage map。
- basic / gather / clear / 数字技能释放、暴击与伤害归属全部
  沿用现有聚合规则；未映射 actor 伤害仍进 total/暴击，但不
  写入 character 归属 map。

## TDD 与验收

- [ ] 新测试先因 `fromEncounterMapping` 缺失编译红，实现后转绿。
- [ ] 等价 legacy / encounter fixture 对一批混合事件逐字段全等：
  result / ticks / hadActions / participants / skillCasts / totalDamage /
  criticalCount / damageByCharacterId。
- [ ] 覆盖玩家 exact-once 成功与缺失，终局玩家 mismatch，
  ongoing，全部 fail closed。
- [ ] 覆盖 active / reserve / exited 参战者 HP，basic / gather / clear /
  数字技能 cast，暴击、未映射 actor 与已映射 actor 伤害归属。
- [ ] 证明 caller 列表/map/events 的后续突变不污染 mapping 或已产出
  settlement，返回集合仍不可修改。
- [ ] source guard 证明生产文件只新增 encounter mapping 依赖，不出现
  route / objective / reward / injury / host / persistence / repository /
  candidate / tuning 及双套聚合 loop。
- [ ] 复跑新测试与现有 numeric settlement / stage settlement /
  encounter mapping / migrated encounter plan 回归，scoped analyze 0 issue。
- [ ] `dart format --output=none --set-exit-if-changed`、`git diff --check`、
  baseline path audit、status / main refs 收口通过。
- [ ] Pi CLI 0.84.1 / exact `deepseek/deepseek-v4-flash` / thinking high
  完成编码前设计与最终 diff 两轮只读审查，如实记录。
- [ ] 中文动宾小提交，最终追加精确空提交
  `[READY][PI][P2-M2-R17] 建立迁移遭遇结算适配`。

## Pi 证据

### 编码前设计审查

- 待执行。

### 最终 diff 审查

- 待执行。

## 当前恢复点

- 状态：已确认精确 baseline / branch / 三份 owned files 与结算
  语义无缺口；尚未编写新测试或修改生产码。
- 环境：`flutter pub get --enforce-lockfile` 通过；`build_runner`
  写入 126 outputs，仓库现有 63 个 `.g.dart`；`libisar.dylib`
  SHA-256 = `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`。
- 下一步：提交本恢复点，执行指定 Pi 编码前只读审查，再
  先写红测。
- 阻塞项：无。
- 生产接线：未接；本切片只新增显式 adapter 入口。
