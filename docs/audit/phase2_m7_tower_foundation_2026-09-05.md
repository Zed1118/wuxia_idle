# Phase 2 M7 塔迁移基础门审计（2026-09-05）

## 结论

本批在绿色 `main == origin/main == 7c10ff17583addda4dd9039372f6f1b918d3a60e` 上完成塔迁移基础门 `1/1`。`[READY]` 候选 `431f28532b6ebd1ea07dadad22d2755192955f61` 已通过标准 Gate 并 no-ff 合入 main。生产 migration set 明确保持为空，所以 49 层全部继续走兼容路径，塔迁移工程水位仍为 `0/49`。本批不关闭正式 M7，也不改变 Phase 2 `1/10`。

## 实现合同

| 基础门 | 候选结果 |
| --- | --- |
| 内容身份 | 新增内部 `CombatContentRef(mainline/tower + contentId)`，保留既有 mainline facade |
| route authority | production migration set 为空；只有显式 migrated floor 才能进入 typed path |
| definition/runtime source | migrated 后 encounter 或 runtime binding 缺失立即报错，不静默回退 |
| 多敌绑定 | 每个 spawn entry 显式携带 `sourceEnemyDefId`，与 `TowerFloorDef.enemyTeam` 按顺序一一双射；缺失、重复、错序或多绑拒绝启动 |
| guardian 翻译 | actor runtime ID 分配后统一将 guardian EnemyDef ID 翻译为 runtime ID；悬空、重复、自引用或非唯一映射拒绝启动 |
| encounter/objective | 每层保持一个 encounter，`activeLimit` 等于当前敌人数，现有塔胜利语义映射为 `defeat-all` |
| 三入口 | 可见挑战、即时挂机、durable 恢复统一消费 `Phase0aTowerCombatSessionFactory` |
| owner 边界 | settlement、首通、奖励、个人记录与持久事务 owner 原样保留 |

兼容 mapper 已集中在 factory 内唯一调用点，但生产的三个入口仍可达该兼容分支；按治理合同仍挂账为三处 legacy 入口，不冒充退役。

## 验证证据

| 验收项 | 结果 |
| --- | --- |
| 有效初始 RED | 新测试因缺少计划中的 content ref、route authority、binding source 与 factory API 编译失败 |
| 基础门 focused | `9/9 PASS` |
| 基础门 + 既有 wiring/headless | `20/20 PASS` |
| 塔域宽回归 | `157/157 PASS` |
| 代表层 | `1/7/14/32/42/49 × cycle 1/2`，actor、技能、Boss phase、charge、vulnerability、guardian ward 与 settlement 对 legacy 精确一致 |
| live/headless | 上述 12 组相同 seed 的 outcome、final state、events 精确一致 |
| mutation 1 | runtime source 将多敌 source 退化为首敌重复绑定，正向测试失败 1；反向 patch 恢复后通过 |
| mutation 2 | guardian lookup 强制查 missing key，正向测试因 dangling guardian 失败 1；反向 patch 恢复后通过 |
| mutation 3 | 即时挂机入口绕过统一 injectable factory，静态生产路径测试失败 1；反向 patch 恢复后通过 |
| analyze | `flutter analyze --no-pub lib test tool`：No issues found |
| format | 11 个本批 Dart 文件，0 changed；最终整仓格式门待标准 Gate 复核 |
| 持锁全量 | `6010/6010 PASS`，5m36s，exit 0，锁已释放 |
| 标准 Gate | exact READY `431f2853`：独立 full `6010/6010`、analyze 0、format `1740/0 changed`、receipt matched，最终 `PASS` |

## 边界与挂账

- 没有迁任何塔层，没有修改数值、技能、奖励、经济、解锁、周目、结算 owner、`schemaVersion`、`saveVersion`、GDD、CLAUDE 或玩家可见文案。
- 没有给现有塔 AI 引入 attack-token throttling；typed path 显式保留旧塔同时在场与既有 actor ID 行为，避免改变碰撞、选敌与手感。
- 自动化、mutation、候选 READY、后续 main 集成与 exact-SHA CI 均不能代替真人桌面、视觉/音频/手感或 Windows 验收。
- 本次 push 的 exact-SHA CI 由集成收尾实时核验；塔楼层迁移、legacy 退役和真人门仍另行挂账。
