# 二阶段 G7 退役伤害诊断引用收口审计（2026-08-24）

## 范围与结论

- 基线：G0 READY `44e42497b9e4968e6baa64ed10ad940034664220`。
- 本批只纠正文档、注释、标签与试玩证据说明；不改数值、公式、断言、生产行为、registry 或 `PROGRESS.md`。
- 2026-06-14 的普攻约 13.5 万、大招约 21 万来自旧 3v3 极值×周目诊断。该测试在 `ca548a3a7ff647d0678a9b5b4b570835c7c7dde0` 删除，旧核原子删除随后由 `597a243b2506610b5cbb74e2919be79bbf99e283` 合入 `main`；因此该值只保留为历史测量记录，不能签当前 Phase 0A 红线。
- GDD 证据订正并入同日 v1.33 G0 摘要，头部继续保留 v1.33/v1.32 两版；本批不新开 v1.34，避免在禁止改历史 archive 的边界下丢失或越权迁移 v1.32。

## 当前可重跑守卫

| 守卫 | 真实覆盖 | 不覆盖 |
|---|---|---|
| `test/balance/full_build_damage_redline_test.dart` | 满强化神物、共鸣、双攻击开锋等真实派生装备构造进入 `DamageCalculator` 的 calculator 极值探针；含现有弱点、破甲、破绽窗口等探针断言 | Phase 0A mapper/reducer、完整真实战斗动作链、周目与全部末端组合 |
| `test/tools/phase0a_full_content_balance_diagnostic_test.dart` | Ch1 祖师起手画像；3 流派 × 105 主线 + 49 塔 × 5 熟练阶段 = 2310 次 Phase 0A headless reducer；每次 `maxResolvedDamage < 1,000,000` | 满 build、飞升阶差、周目、地形/阵型/恩怨极值、连续同会话稳定性 |

两类证据互补但不等价。当前不能从 2310 条起手画像推出 Phase 0A 满 build 真实路径极值，也不能把历史 13.5–21 万写成当前测试结果。

## 后续独立任务

`P2-G7-FOLLOWUP-PHASE0A-FULL-BUILD-REAL-PATH`：在独立 worktree 中新增 Phase 0A 满 build 真实 reducer 极值探针，复用生产内容 mapper、玩家 snapshot 构造与 reducer；候选组合必须先核对当前生产可达性，再逐单击断言不进百万。任务不得直接移植旧 3v3 runner，也不得为复刻历史数值修改生产公式或 YAML。

另有一项独立稳定性缺口：旧核 1000 场连续 `runToEnd` 记录不能由 2310 次独立 Phase 0A run 自动继承；如 G7 后续要求同会话连续稳定性，应另立压力任务。

受本批冻结边界保护的历史残留不作为活动守卫：`PROGRESS.md`、`docs/ROADMAP_1_0.md`、`docs/RELEASE_CHECKLIST_1_0.md`、旧 spec/plan/session/audit，以及 `data/stages.yaml` 的校准出处注释仍可追溯旧诊断。活动真相源、README、`lib/`、`test/` 与 `tools/` 不再用已删除诊断名签当前覆盖。

## 验证记录

- `flutter test --no-pub --no-test-assets -r compact`（满 build、Phase 0A 全内容、P1a、跨系统、压力、挂机经济、商店、材料经济、被动离线、truth-source guard 共 10 文件）：45/45 通过；Phase 0A 报告 `content=154; proficiencyStages=5; runs=2310; maxDamage=4419`。
- `flutter analyze --no-pub`（12 个相关 Dart 项）：0 issue。
- `bash -n tools/playtest/decision_session.sh`、Markdown 非空检查、`git diff --check`：通过。
- `rg -n 'balance_simulator_test|balance_simulator' CLAUDE.md GDD.md README.md lib test tool tools`：0 条活动引用。
- DeepSeek V4 Flash 首轮只读审查：P0/P1 = 0/0，5 个 P2；Qwen3.8-Max 首轮只读审查：P0/P1 = 0/0，3 个 P2。已修 README 漏标、试玩步骤旧 30 关/+8.3pt 活动措辞、删除 commit 双锚点、扫描范围与冻结残留说明。DeepSeek 增量复核 P0/P1/P2 = 0/0/0；Qwen 增量复核指出的 v1.34/v1.32 跳版已按 archive 冻结边界改成同日 v1.33 in-place 订正，最终聚焦复核 P0/P1/P2 = 0/0/0。
- 最终实现 commit：`381d591bfb2fda17f0c1600253c1a945c6e3088e`。
- READY：本验证记录提交后的 `[READY][CODEX][P2-G7]` 空提交；该空提交不改变已验证树。
