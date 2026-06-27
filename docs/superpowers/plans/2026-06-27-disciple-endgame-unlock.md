# 弟子加入战斗后移至终局解锁 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把大弟子/二弟子的拜入触发关从 Ch2末/Ch3末（`stage_02_05`/`stage_03_05`）后移到全主线通关后（`stage_06_05`），使整条主线变为「祖师单人挑战」，组队爽感留到终局。

**Architecture:** 方案 A 纯配置后移 + 服务/hook 适配「一关触发多条 join」。核心是 `numbers.yaml` 两条 `disciple_joins` 的 `stage_id` 改 `stage_06_05`；`DiscipleJoinService.joinForClearedStage` 从「单条匹配 + break」改为「遍历该关所有匹配条目，逐条懒创建」并返回 `List<Character>`；`disciple_join_hook` 按拜入顺序依次弹拜师叙事 + 立绘。**关键陷阱**：关级防重标记 `triggeredDiscipleJoinStageIds` 必须在遍历完所有匹配后**一次性**写入，否则 senior 拜入先标记 06_05 会挡掉同关 junior。飞升/真传/师承遗物逻辑**不改**（06_05 通关与两弟子拜入同一时点，时序天然吻合）。

**Tech Stack:** Flutter Desktop / Riverpod 3.x / Isar / YAML 配置。验收 `flutter test`（Isar 无 web target）+ `flutter analyze` 0 issue。

**硬约束（spec §4/§6）：** 不在本任务静默调主线平衡（单人 Ch4-6 可通性是下游独立验证项）；不抽走旧档已有弟子（grandfather）；不改飞升/真传/师承遗物逻辑。

**恢复点（执行中更新）：** 状态=计划已定稿，环境已预热（worktree disciple-endgame-unlock，55 .g.dart + dylib + 冒烟绿）。下一步=Task 1 配置后移。

---

## File Structure

- `data/numbers.yaml` — `disciple_joins` 两条 `stage_id` → `stage_06_05` + 注释同步
- `lib/features/lineage/application/disciple_join_service.dart` — `joinForClearedStage` 返回 `List<Character>`，遍历多匹配 + 抽 `_createDiscipleIfAbsent` + 关级标记后移
- `lib/features/lineage/presentation/disciple_join_hook.dart` — 遍历多弟子，按 role 匹配 join 取 narrativeId，依次弹叙事 + 立绘
- `test/features/lineage/application/disciple_join_service_test.dart` — 时机改 06_05 + 一关两拜 + 旧档祖年化
- `test/features/lineage/team_growth_e2e_test.dart` — 全弧线改 06_05 单关满队
- `test/features/lineage/presentation/disciple_join_hook_test.dart` — stageId 改 06_05，驱动 senior→junior 两段
- `test/features/ascension/application/ascend_service_test.dart` — fixture 语义注释 + 「无弟子 → canAscend=false」

---

## Task 1: 配置后移（numbers.yaml）

**Files:** Modify `data/numbers.yaml:1798-1804`

- [ ] Step 1: 两条 stage_id → stage_06_05 + 注释同步（见主计划代码块）
- [ ] Step 2: 跑 service 测试确认仅断言失败、非 yaml 解析异常
- [ ] Step 3: commit `弟子拜入触发关后移至 stage_06_05(spec A 配置层)`

## Task 2: 服务遍历多匹配 + 幂等修正
- 重写 `joinForClearedStage` 返回 `List<Character>`，抽 `_createDiscipleIfAbsent`，关级标记遍历后一次性写。
- 先写「一关 06_05 两拜满队 + 幂等」失败测试 → 实现 → 绿 → commit。

## Task 3: 更新 service 旧用例（时机 + 旧档祖年化）
## Task 4: hook 遍历多弟子依次弹叙事
## Task 5: 更新 hook widget 测试（驱动 senior→junior 两段）
## Task 6: 更新 team_growth e2e（单关满队）
## Task 7: 飞升测试补「无弟子 → canAscend=false」+ fixture 语义注释
## Task 8: 全量 analyze 0 issue + flutter test 全绿 + PROGRESS

> 详细每步代码见会话内主计划（本文件为恢复锚点 + 任务索引，控制体量）。

---

## 平衡独立项（spec §4 · 不在本计划内静默做）
主线变单人后必须单独验证武圣单人能通 Ch4-6（尤其 stage_06_05 Boss 52000 血），用 `balance_simulator` 跑单人正常+极值 build。不可通 → 敌人/关卡调参作为单独待用户拍板项，不在本次静默 buff/nerf。

## 验收标准
`flutter analyze` 0 issue + 全量 `flutter test` 全绿（弟子族/飞升族/e2e/hook）。旧档不抽走弟子，飞升时序吻合无 StateError。
