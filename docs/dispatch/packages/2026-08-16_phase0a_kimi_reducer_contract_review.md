# Phase 0A reducer / 输入 / 事件闭环交叉复核（Kimi）

## 目标

在 Qoder 第二批实现冻结后做独立交叉复核：验证统一 reducer、玩家/AI 适配器、已结算事件是否兑现反馈契约与生产边界。默认只审查、补测试；发现确定缺陷时可做最小修复，禁止扩展 UI 或数值。

## 输入与必读

- 执行基线由派单方在 Qoder `[READY]` tip 后提供。
- 必读：Qoder 计划/实现/测试；`docs/spec/2026-08-16-phase0a-production-feedback-contract.md`；`docs/audit/phase0a-production-wiring-audit-2026-08-16.md` §4-§6；`CLAUDE.md` §5/§8.0/§8.2/§8.3/§9。

## 复核清单

1. 创建 `docs/superpowers/plans/2026-08-16-phase0a-kimi-reducer-contract-review.md`（≤120 行），记录证据、问题、修复、验证与恢复点。
2. 从根 application 会话入口追踪玩家输入和 AI 输入，确认最终只到一个 reducer/结算入口；搜索是否复制命中、扣血、CD、真气或目标选择规则。
3. 对照反馈契约逐事件核字段与顺序：
   - `hit_landed` 必有 `resolvedDamage` / `remainingHealth`；未命中无假 hit；
   - Q/R applied 为稳定有序逐目标 outcomes，含 defeated/statusApplied/可选伤害；
   - `skill_availability_changed` 的 cooldown/qi 运行时字段可直接驱动按钮亮暗；
   - 每目标死亡只发一次，死亡后不再作为 actor/target；事件可相等、可确定性回放。
4. 补足能证红的缺口测试；若代码缺陷明确，仅做最小修复并单独 commit。不得以改文档掩盖实现偏差。
5. 核 §8.2 四证据、源码依赖禁区、Dart 中文/调优常量、范围越界和工作树洁净。

## 验证与出口

- 运行 Qoder targeted tests、首片 24 项、probe 对照 8 项、根 `flutter analyze --no-pub`、`git diff --check`。
- 输出逐项 PASS/FAIL 与残留风险；tip 用 `[READY]` 或 `[BLOCKED]`，worktree 干净。
- 禁 UI、YAML、GDD、PROGRESS、pubspec、probe、旧 3v3、schema/saveVersion、push/merge/rebase/revert/碰 main。
