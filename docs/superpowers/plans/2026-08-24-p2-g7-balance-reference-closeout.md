# P2-G7：退役伤害诊断引用收口

## 目标

从 G0 READY `44e42497b9e4968e6baa64ed10ad940034664220` 出发，清理随旧 3v3 删除的平衡诊断在活动真相源、测试注释、玩家可见审计说明和试玩脚本里的错误引用。保留 2026-06-14 的 13.5–21 万历史测量价值，但明确它不是当前可重跑证据。

## 文件边界

- 允许修改：`CLAUDE.md`、`GDD.md`、`README.md`、活动 `lib/` / `test/` 注释或标签、`tools/playtest/decision_session.sh`、本 plan 与本批 audit。
- 禁止修改：数值、公式、测试断言、生产行为、`data/`、task/decision registry、`PROGRESS.md`、历史 archive/session/旧计划。
- 分支：`codex/phase2-g7-balance-reference-closeout-20260824`。
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-g7-balance-reference-closeout`。

## 证据结论

1. 已删除旧 3v3 诊断曾测得普攻约 13.5 万、大招约 21 万，并断言极值×周目路径不进百万；该值仅保留为历史记录。
2. 当前 `test/balance/full_build_damage_redline_test.dart` 使用真实派生装备构造与 `DamageCalculator`，覆盖满 build calculator 探针，不经过 Phase 0A reducer。
3. 当前 `test/tools/phase0a_full_content_balance_diagnostic_test.dart` 使用 Ch1 祖师起手画像，覆盖 3 流派 × 154 条生产主线/塔内容 × 5 熟练阶段 = 2310 次真实 Phase 0A headless reducer，并逐次断言 `maxResolvedDamage < 1,000,000`；它不是满 build、飞升阶差、周目或地形/阵型/恩怨极值测试。
4. 后续任务 `P2-G7-FOLLOWUP-PHASE0A-FULL-BUILD-REAL-PATH` 应新增 Phase 0A 满 build 真实 reducer 极值探针；必须复用生产 mapper/reducer，覆盖有依据的末端乘与进阶组合，并单击断言不进百万。本批不新增假替代测试、不改数值。

## 验收 checklist（CLAUDE §8.2）

- [x] 生产接线证据：只改 `UiStrings.redlineNoteUltimateCrit` 的审计说明；消费方仍为 `lib/features/debug/application/redline_audit.dart`，无生产逻辑或路由变化。
- [x] targeted tests：满 build calculator、Phase 0A 全内容、P1a、跨系统、压力/经济/闭关/商店与 truth-source guard 合计 45/45 通过；Phase 0A 单测内部完成 2310 次 reducer run（maxDamage=4419）。
- [x] 红线影响：不改 YAML、公式、断言或生产数值；只纠正“不进百万”证据边界，不触及三系、在线=离线、反主流或硬编码边界。
- [x] 真相源与静态检查：truth-source guard 9/9（包含在上述 45）、12 文件 scoped analyze 0 issue、`bash -n`、`git diff --check` 通过；`CLAUDE.md` / `GDD.md` / `README.md` / `lib` / `test` / `tool` / `tools` 活动范围不存在已删除诊断名引用。
- [x] 残留风险：当前仍缺 Phase 0A 满 build 真实路径极值探针，也缺同会话连续战斗稳定性替代；均明确登记为后续，不伪称已覆盖。
- [x] 独立审查：DeepSeek V4 Flash 与 Qwen3.8-Max 首轮均为 P0/P1 = 0/0；逐项关闭 P2 后，两路最终增量复核均为 P0/P1/P2 = 0/0/0。
- [ ] 工作树干净，tip 为 `[READY][CODEX][P2-G7]`。

## 当前恢复点

- 状态：活动真相源、README、测试/标签和试玩脚本已完成改写；动态验证全绿，两路最终独立复核均为 P0/P1/P2 = 0/0/0。
- 最后完成：45/45 targeted、最终 truth-source guard 9/9、12 文件 analyze 0 issue、shell/diff/活动引用扫描通过；所有审查 P2 已关闭。
- 下一步：提交实现 commit，记录其 hash 后生成 `[READY][CODEX][P2-G7]` 空提交封签。
- 阻塞项：无。
