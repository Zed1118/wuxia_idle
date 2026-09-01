# P2 M7 第二章内容迁移工程审计

## 结论

第二章工程迁移候选已从 `2/5` 推进到 `5/5`，全主线 catalog 分母从 `11/105` 推进到 `14/105`，剩余主线 `91`；塔仍为独立的 `0/49` 缺口。本结果不关闭正式 M7，也不改变二阶段正式 `1/10` 口径。

| 检查项 | 工程候选 | 生产证据 |
|---|---|---|
| 三关真实路由 | PASS | `stage_02_03..05` 各有唯一 assignment、encounter、runtime binding，真实 factory 返回非空 host。 |
| 基敌与数值来源 | PASS | runtime `base_enemy_id` 必须等于各关唯一 `StageDef.enemyTeam`；未改 `stages.yaml`、`numbers.yaml` 或角色/技能数值。 |
| 普通关目标 | PASS | 02_03 复用第二章四职能生态与已建立的普通关 25/10 模板，25 个 authored target 全部完成后才终局。 |
| Boss 身份 | PASS | 02_04/05 仅 `defeat_commander` 指定实体保留原 Boss 姓名、美术、技能、蓄力和阶段；随从剥离 Boss 身份。 |
| 生产消费者 | PASS | 三关经 `createFreshPhase0aMainlineEncounter`、repository runtime adapter 和同一 Phase 0A flow 构造，不以 fixture 或字符串存在替代。 |
| 真人/Windows | DEFERRED | 按用户指示统一挂账，不纳入工程候选结论。 |

## 决策与边界

- 用户本轮授权自主决策并继续挂账目检；本批选择复用已集成的 `ch2_sects` 四职能生态，以及第一章已建立的 25 人普通关、3 人小 Boss、2 人章末 Boss 模板，不新增独立调优值。
- 02_03 使用 defeat-all；02_04 使用 commander + required adds；02_05 沿既有章末模板以 commander 败退结束。所有个体基础属性、Boss 招式、掉落、叙事和解锁仍由原 `StageDef`/结算 owner 持有。
- 本批不宣称第二章节奏或视觉已获真人认可，不把 5 关工程接线扩写成 105/105 或正式 M7 完成。

## 红绿证据

- 初始 RED：`4` 项失败，分别证明三关尚无 assignment、encounter、真实 factory host 和 runtime binding。
- 实现后定向与相邻回归：`20/20`；新增生产测试本身 `5/5`。
- 扩大回归覆盖 catalog、schema gateway、migration gate 与主线 application：`292/292`。
- remove-implementation：删除 02_03 assignment，catalog 因未分配 encounter 在加载期精确 `1` 项失败。
- force-degenerate-value：把 02_05 commander 指向随从，目标完成与 Boss 身份精确 `2` 项失败。
- 两次 mutation 均用精确反向补丁还原，原测试再次 `5/5`。
- `flutter analyze --no-pub lib test tool`：`No issues found!`。
- `dart format .`：`1716 files (0 changed)`。
- 持锁整仓 `flutter test --no-pub`：`+5879: All tests passed!`，退出码 `0`，`[E]` 块 `0`。

候选冻结后仍需在精确最终 tip 运行标准 Gate；该 Gate 结果不代替正式 M7、真人桌面或 Windows 验收。
