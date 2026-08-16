# Phase 0A 根应用反馈事件与资产契约（Kimi）

## 目标

把已验证的七类战斗反馈收敛成根应用可消费的“语义事件 → 视觉/音频资产”契约，为下一片 reducer 与纯 Flutter 表现层提供稳定输入。本单只写规格文档，不生成资产、不写 Dart、不修改 probe。

## 必读

- `CLAUDE.md` §5/§8.0/§8.2/§8.3/§9，`GDD.md` §1/§5，`docs/spec/rejected_task_registry.md`。
- `docs/audit/phase0a-presentation-gap-audit-2026-08-16.md`。
- `docs/audit/phase0a-production-wiring-audit-2026-08-16.md` §4/§6。
- 根应用现有 `assets/audio/`、`assets/characters/`、`assets/enemies/`、`assets/scenes/`、`lib/shared/audio/`，以及 probe 四张实际消费图仅作参考。

## 交付物

1. 创建 `docs/superpowers/plans/2026-08-16-phase0a-kimi-feedback-asset-contract.md`（≤150 行），含目标/验收/切片/恢复点。
2. 创建 `docs/spec/2026-08-16-phase0a-production-feedback-contract.md`（≤150 行），至少定义以下语义事件（可改为更一致的 English identifier，但不得丢语义）：
   - attack started / projectile launched / hit landed / enemy defeated；
   - dash started；gather started + applied；clear started + applied；
   - elite telegraph started / break window opened / elite broken；
   - wave started / wave cleared / victory / defeat；
   - skill availability changed（ready/cooldown/qi/casting/down）。
3. 每个事件写明：触发时机、最小 payload（只列语义字段，不锁 Dart API）、顺序/去重规则、对应视觉、对应音频、无资产时的克制回退、可读性/性能约束。
4. 创建 `docs/spec/2026-08-16-phase0a-production-asset-manifest.md`（≤150 行），按祖师/山贼/精英动作、掌风、Q、R、命中/死亡、破招、波次/HUD、音频分组写明：
   - 现有可复用路径/语义是否临时借用；
   - 缺失资产、根 `assets/` 建议落点目录和命名规则；
   - 画布/帧格/透明边/脚底锚点/方向/循环性等可交付规格；如无仓库依据支持精确像素数，用比例/安全区而非伪造数字；
   - P0/P1/P2 优先级、前置依赖和验收方式。
5. 规格须明说：probe 不再改；正式验收对象是根应用真实入口；音频复用 `lib/shared/audio` 现有后端，不新增依赖。

## 验收

- 所有“已有/缺失/借用/未接线”结论用精确路径或搜索命令复核，文末列核心命令。
- 事件契约不包含玩家伤害、CD、半径等平衡数值，不绑定未实装的 Dart 类名。
- `git diff --check`；仅三份文档；行数不超限；无新资产/生成物。

## 明确禁区

- 禁改 Dart、任何 YAML、任何资产、`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/l10n/strings.dart`、`pubspec.yaml`、schema/saveVersion。
- 禁 push/merge/rebase/revert/碰 main，禁安装依赖/软件，只写自己 worktree。
- 如发现需要新美术方向或改战斗规则才能完成规格，仅列证据/选项，用 `[BLOCKED]` 冻结，不代拍。

## 冻结出口

- commit message 中文动宾；完成后 tip 以 `[READY]` 开头、worktree 干净。
- 结果必带 §8.2 四证据：根应用消费域、复核命令/计数、红线影响、残留风险。
