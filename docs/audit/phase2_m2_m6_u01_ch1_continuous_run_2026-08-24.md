# 二阶段 M2/M6 U01 第一章连续首通生产切片审计（2026-08-24）

## 1. 裁决

- 基线：`1a7bc866ffd11b6032a918363daa4c8d656d81f3`，即 G2 后 M5/M6 最小整合 READY。
- 本批只关闭第一章首次推进的“结算后选择下一关 + 同一参与者五关 run”生产切片。
- 不关闭持久崩溃恢复/重复结算键、随行听剑生产接线、replay/manual/auto/headless/扫荡全模式一致性、U04/U05、M2、M6 或整个二阶段。
- 未修改 `data/**`、数值、奖励、解锁、存档 schema、`TUNE-*`、`main` 或 `origin/main`，未 push。

## 2. 红测与实现

真实红测提交 `0b293a6c`：首次推进且有后继关时，胜利弹层找不到“进入下一关”。

实现由一个外层非递归 `MainlineRunCoordinator` 组合既有单关流程：

1. 关卡列表仅在 cycle 1 且该关为当前 `available` 时开启连续模式；重打和特殊模式保持旧单关行为。
2. run 起点只解析一次当前掌门；宿主优先消费 coordinator 注入的锁定快照，不会在下一场改跟后来变更的掌门指针。
3. 每次进入下一关前，按同一 participantId 重新读取 canonical 角色与装配，生成新的不可变 `CombatantSnapshot`；opaque snapshot ID 与版本同步推进 1..5。
4. 第一章第 1–4 关结算层显示“进入下一关/返回江湖地图”，第 5 关结束 run；每关的结算、进度和全部后置 hook 完成后 executor 才返回 coordinator。
5. 角色不存在、死亡、无主修、被既有活动占用、快照错人、装配异常、当前关/后继关系不精确、战败/退出或主动返回均不发布下一关。
6. 伤势仍沿既有生产口径：没有发明重伤阈值；只要 canonical 角色仍可按现有规则装配，就允许继续。

没有新增 reducer、session、headless 内核、持久 run schema、mapper、observer 或通用 registry。

## 3. 直接证据

| 门禁 | 结果 |
|---|---|
| 红测 A：胜利弹层下一关入口 | 先红后绿，提交 `0b293a6c` / `9ded14e3` |
| coordinator + 真实 Ch1 配置 | 10/10 PASS |
| 主线完整目录 | 367/367 PASS |
| G2 验收记录直接引用关键链 | 53/53 PASS |
| 1280×720 / 1440×900 | 胜利弹层与真实 Ch1 宿主 widget smoke PASS |
| scoped analyze | 0 issue |
| root analyze | `flutter analyze --no-pub lib test tool`：0 issue |
| 全量 test | `flutter test --no-pub --no-test-assets`：5274/5274 PASS |
| YAML / diff / whitelist | task/decision registry YAML、`git diff --check` 与提交白名单均 PASS |

五关测试读取真实 `data/stages.yaml`，断言顺序精确为
`stage_01_01 → stage_01_02 → stage_01_03 → stage_01_04 → stage_01_05`，
参与者恒定，run snapshot version 为 `1..5`，不存在第六关或跨章推进。

## 4. Fail-closed 矩阵

| 场景 | 结果 |
|---|---|
| 首关胜利后返回地图 | 记本关完成；不装配、不启动下一关 |
| 战前退出/战败/认输 | 不记本关为 coordinator 完成；不装配下一关 |
| 下一关参与者不可战 | 停在已完成关与原版本，显示事实提示 |
| next snapshot 返回不同角色 | 抛错，下一关零启动 |
| snapshot loader 异常 | 原 run 不变，下一关零启动 |
| resolver 返回当前关/非直接后继 | 在 loader 前拒绝，避免无限推进 |
| 初始 stage/participant 与 run 不一致 | 首战前拒绝 |

## 5. 保留风险与后续依赖

1. 当前 `MainlineRun` 仍是进程内值对象；跨崩溃恢复和 durable settlement identity 没有在本批伪造，需要独立持久事务设计与真实破坏证。
2. `recordVictory` 既有幂等与 settlement participant 归属由原测试保护，但不能把它外推为掉落、成长、伤势在崩溃重放下全部幂等。
3. 关间重新装配已允许同一角色读取最新装备；胜利弹层未新增完整换装面板，该产品交互仍可后续增强。
4. 随行听剑占用/成长对象的合同存在，但比例/cap 仍为 `TUNING`，本批没有接入生产选择或发放。
5. replay/manual/auto/headless/扫荡参与者、记录、成长、伤势与奖励的全模式矩阵仍未关闭。

因此下一批应在不触及调优值的前提下，优先做 durable settlement/recovery 最小事务切片；若其需要 schema 或产品选择，先停下向用户报告，再考虑 U04/U05。
