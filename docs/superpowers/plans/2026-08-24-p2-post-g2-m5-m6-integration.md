# P2 G2 后 M5/M6 在途 READY 整合

## 目标与基线

- integration base：`e7932cc35be42a5228a14f9707135f96656e20b1`
  (`[READY][CODEX][P2-G2] 收口黑风岭生产验收`)。
- source M5：`ee527d90f775e1ba1a6abe622a886cfa21ac6d0e`
  (`P2-M5-EXPEDITION-ENTRY-AVAILABILITY-GUARD`)。
- source M6：`5e1edac2a939d09c0f36cea9c6b295e70996befb`
  (`P2-M6-A12-DISPEL-ACTIVITY-LOCK-ENFORCEMENT`)。
- 三条分支共同祖先为 `8296db0c033b64faa1eb09b24f2f22269f281363`；
  source 与 G2、两个 source 之间的 `base..tip` 文件交集均为空。
- 本批只关闭两个既有小切片并修正状态漂移，不关闭 M2、M5、M6 或整个二阶段。

## Source-owned 文件（只允许保持 source blob 语义）

### M5

1. `lib/features/expedition/application/expedition_service.dart`
2. `test/features/expedition/expedition_dispatch_test.dart`
3. `docs/superpowers/plans/2026-08-24-p2-m5-expedition-entry-availability-guard.md`

### M6

1. `lib/features/dispel/application/dispel_service.dart`
2. `lib/features/technique_panel/presentation/technique_panel_screen.dart`
3. `test/features/dispel/application/dispel_persist_test.dart`
4. `test/features/technique_panel/presentation/technique_panel_screen_test.dart`
5. `docs/superpowers/plans/2026-08-24-p2-m6-a12-dispel-activity-lock-enforcement.md`

## Integration-authored 白名单

1. `CLAUDE.md`
2. `GDD.md`
3. `PROGRESS.md`
4. `docs/dispatch/phase0a_overhaul/task_registry.yaml`
5. `docs/dispatch/phase0a_overhaul/decision_registry.yaml`
6. `docs/audit/phase2_post_g2_m5_m6_integration_2026-08-24.md`
7. 本计划文件

`BACKLOG.md`、G2 验收记录、玩法数值、schema、奖励、解锁与 main/origin main
均禁止修改。

## 依赖与验收

1. 逐提交纳入两个 source，核对最终 owned-file blob/patch 与 source tip 一致。
2. M5：dispatch focused 14/14、完整 `test/features/expedition` 108/108。
3. M6：persist 10/10、service 16/16、UI 20/20、完整
   `test/features/dispel` 27/27。
4. G2 关键回归只跑既有 94 项定向套件；本批不重复最终全量 5249 项。
5. changed/scoped analyze、format、`git diff --check`、YAML 解析、白名单检查通过。
6. 主控独立复核整合 diff；P0/P1 清零后才提交本批 `[READY]`，worktree clean。
7. 文档必须明确：G2 已关闭，但只代表黑风岭纵切；连续五关、U01/U04/U05、
   M3-M9 与六模式完整迁移仍未关闭；20 项 `TUNE-*`、七心魔 AI、渐进解锁不升级。

## 当前恢复点

- 已从 G2 READY 建立独立 branch/worktree，并逐提交纳入两个 source READY。
- 八个 source-owned 文件与 source tip blob 逐文件一致；主控实际 diff 复核 P0/P1=0。
- M5 14/14 + 108/108、M6 10/10 + 16/16 + 20/20 + 27/27、G2 94/94 全绿。
- 6 个 changed Dart format 0 改动；应用 analyze 0 issue；嵌套 probe 补齐离线 package metadata 后根 analyze 0 issue。
- 已同步 G2/M5/M6 真实状态并生成整合审计；下一步只剩 YAML/diff/白名单复核、提交 READY 与 clean-tree 验签。
