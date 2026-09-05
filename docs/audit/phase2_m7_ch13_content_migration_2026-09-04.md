# Phase 2 M7 第十三章分层考校内容迁移审计（2026-09-04）

> 2026-09-05 独立复核补充：下列集成/CI 与覆盖计数属实，但“保留单敌身份与原数值、知客僧最后入场”的验收结论存在缺口。13-01/03 被生态模板替换姓名/立绘/技能；13-03/05 继承 1.1 倍 HP/速度；知客僧因 director 的 ID 排序进入首批。原测试未覆盖这些事实。三类缺陷现已在独立本地候选完成修复与 6017 项全量验证，见 `phase2_m7_ch13_contract_fix_2026-09-05.md`；未集成前不得把 main 写成已修复。

## 结论

本分支基于 clean 的 `main == origin/main == 571708a7ddb5c5eb23a197b0b4e52ca3ec95145f`，按用户明确拍板的“分层考校”方案完成第十三章工程迁移。候选 `a6bd6366ab1a609da8efde0c6f8bd0a54c1352e3` 已经 no-ff merge `7c10ff17583addda4dd9039372f6f1b918d3a60e` 合入 `main/origin/main`，merge exact-SHA CI run `33895342001` 为 `completed/success`。第十三章由 `1/5` 推进为集成 `5/5`，全主线 typed production catalog 由 `101/105` 推进为集成 `105/105`。

这是工程集成结论，不是正式里程碑结论：塔仍为 `0/49`，五处 legacy production seam 仍开放，真人/Windows 依赖未关闭，故正式 M7 与 Phase 2 `1/10` 均未关闭。

## 冻结实现

| 合同 | 候选结果 |
| --- | --- |
| `stage_13_01/03` | 保持单敌 StageDef identity，接入 singleton typed route |
| `stage_13_02` | 保持 25 actors、`active_limit: 10`、`melee/ranged/charge/support = 2/1/1/1` |
| 分层考校 | 前 24 人为生态考校者，最后 `ch13_s02_guard_02` 为非 Boss commander“半山知客僧” |
| objective | `all`：24 人 defeat-targets + 知客僧 defeat-commander，两种击杀顺序均须完成 |
| commander identity | 保留 StageDef 姓名、图标、流派与完整技能；不注入 Boss phase/charge/vulnerability |
| `stage_13_04/05` | 保持原 Boss identity、技能、阶段、掉落与数值快照 |
| 叙事 | 只改 13-02 opening/victory 的必要一致性，保留“半山也很好”“留”与继续向上主题 |

runtime adapter 的改动只把“精确 identity 保留”从 Boss commander/pursuit target 泛化到所有明确 commander entry；Boss mechanics 仍只在 base StageDef 是 Boss 时保留，普通生态 entry 不受影响。

## 实时证据

| 验收项 | 结果 |
| --- | --- |
| 有效初始 RED | Ch13 精确合同 `0/8`，覆盖缺 assignment/route/commander/narrative/objective/identity/factory/dynamic |
| Ch13 focused | `8/8 PASS` |
| M4 remaining ecologies | `3/3 PASS` |
| Ch3/12/14 邻接 | `18/18 PASS` |
| Phase 2 adjacent | `188/188 PASS` |
| mainline application | `183/183 PASS` |
| 可逆 mutation | 删除 13-01 assignment、错绑 13-05 base、回退非 Boss commander identity 规则三向均精确失败 |
| mutation 恢复 | 三个被改文件均以反向 patch 恢复，并由施工前 SHA-256 精确核对 |
| 测试契约迁移门 | `PASS`；expect 删 3/增 64，用例删 0/增 8，登记 3 条 |
| analyze | `flutter analyze --no-pub lib test tool`：No issues found |
| format | `dart format .`：1737 files，0 changed |
| 持锁全量 | `flutter test --no-pub --reporter compact`：`6001/6001 PASS`，exit 0，锁已释放 |
| 合入后持锁全量 | `6001/6001 PASS`，exit 0 |
| merge exact-SHA CI | run `33895342001`，head `7c10ff17583addda4dd9039372f6f1b918d3a60e`，`completed/success` |

## 边界与挂账

- 未改玩家/敌人数值、奖励、经济、解锁、周目、结算 owner、`schemaVersion`、`saveVersion`、GDD、CLAUDE 或新玩法规则。
- 测试中的高耐久 player 只是 dynamic headless 终局 fixture，不是生产平衡值；生产数据与红线未改变。
- 自动化、mutation、main/origin 集成与 exact-SHA CI 均不代替真人验收。
- 真人桌面、视觉、音频、手感与 Windows 全部保持 `DEFERRED`。
