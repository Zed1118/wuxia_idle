# Phase 2 M6 九霄塔实际参与者结算报告审计

日期：2026-08-25  
分支：`codex/phase2-m6-tower-participant-settlement-report-20260825`  
基线：`81feab07bd0d79ec6ee7c4f568dc7b50644810cd`  
代码候选：`e261a14d66a6baa649dd96d55266ad3a9b8dd1f4`

## 结果合同与门变化

本门只关闭“九霄塔既有真实结算结果向胜利身份报告贯通”这一 M6 必要生产子门：`0/1 → 1/1`。顶层 M0–M9 仍为 `1/10`，M6 仍 WIP；不将本子门 READY 解释为 M6 或二阶段完成。

## 生产路径

`主菜单 → 江湖地图 → 九霄塔地点详情 → 既有逐次 eligible 选人 → 既有 exact snapshot → 真实 Phase0aTowerBattleHost → 既有共享 CombatResolutionService settlement → TowerVictoryContent 身份报告`

`applyTowerCombatResolution` 继续是塔胜负结算后的生产 owner。本次仅从其已验证的单一 `characters.single` 结果返回 `participantName`，由 `runTowerFlow` 传入原有胜利弹层；没有新建 reducer、session、provider、headless 或 settlement 真相源，也没有使用可选的 `HeroCameraData` 代替身份。

## 证据

- RED：新增胜利报告所需参数后，旧调用点编译失败；实现后定向测试 `8/8 PASS`。
- 塔域：`flutter test --no-pub test/features/tower`，`117/117 PASS`。
- 相邻域：塔、轻功、守城、断魂庄联合，`328/328 PASS`。
- 应用路径：`flutter analyze --no-pub lib test`，0 issue。
- 全量：`flutter test --no-pub --no-test-assets --reporter compact`，`5550/5550 PASS`，耗时 `4:46`。
- `git diff --check`：通过。

全量期间出现的 Isar 未初始化、测试中故意验证悬空心法的日志均未形成失败；测试进程最终退出码为 0。默认不带路径的 workspace analyze 仍会进入独立退役 `tools/phase0minus_probe`，因其自身 package 依赖缺失而阻塞；本门使用应用范围 `lib test` analyze，不把该独立基线冒充通过。

## 语义与边界复核

通过既有塔选人/结算契约保留无效掌门、跨代/死亡/疗养、无主修、重复占用、provider 异常、悬空装备/心法及错人 settlement 的 fail-closed 行为；胜利报告姓名只在共享结算确认唯一实际参与者后产生。阵型语义、塔层/周目、首通奖励、重打、排行榜、仪式和既有战斗规则未改变。每角色塔层最好成绩因缺少持久模型仍 BLOCKED，本审计不外推该门。

## 文件、谱系与整合状态

业务 diff 仅触及塔结算返回值、胜利报告及两组对应测试；同步计划、审计、task registry 与 CLAUDE/GDD/PROGRESS/变更摘要。主线 `/Users/a10506/Desktop/Projects/挂机武侠` 未修改，未 merge、push 或改写历史。收口前需确认本 worktree 最终 `git status --short` 为空、HEAD 在本门 READY 收口提交、且 owner/谱系与 registry 一致。

## 剩余 blocker 与下一门

1. M6 还有其他特殊模式/在线与离线同契约等未关闭子门，不能由本门代替。
2. 每角色塔层最好成绩需要持久模型与 schema/产品决策，本门明确不猜测。
3. 独立退役 tools/phase0minus_probe 的 package 依赖仍使默认全 workspace analyze 不可用，但不阻塞应用范围门。

下一最高价值门：在不触碰塔持久模型和本门已锁路径的前提下，从 M6 剩余真实生产模式中选择一个能使顶层验收分母产生可审查增量的端到端子门。
