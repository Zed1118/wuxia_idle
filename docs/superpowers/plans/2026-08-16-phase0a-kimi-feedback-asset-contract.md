# Phase 0A 根应用反馈事件与资产契约（Kimi · 只写规格）

> 基线 HEAD：`cd5268a7`（冻结 Phase 0A 生产化首批派单）。本单只产文档，不改 Dart / YAML / 资产 / probe。

## 目标

把 probe 已验证的七类战斗反馈收敛成根应用可消费的「语义事件 → 视觉/音频资产」契约，为下一片 reducer（Qoder deterministic simulation core 之后）与纯 Flutter 表现层提供稳定输入。

## 范围与禁区

- 只写三份 Markdown：本计划、`docs/spec/2026-08-16-phase0a-production-feedback-contract.md`、`docs/spec/2026-08-16-phase0a-production-asset-manifest.md`，各 ≤150 行。
- 禁改：任何 Dart / YAML / 资产 / `data/numbers.yaml` / `GDD.md` / `PROGRESS.md` / `lib/l10n/strings.dart` / `pubspec.yaml` / schema / saveVersion；probe 不再改。
- 禁 push / merge / rebase / revert / 碰 main；禁装依赖。仅本 worktree。
- 事件契约不含伤害倍率、CD 配置时长、技能半径等**调优/平衡常量**；但必须携带模拟核已结算的运行时结果（`resolved_damage`、`cooldown_remaining`、`qi_current` 等反馈数据，非平衡常量）。不绑定未实装的 Dart 类名。
- 若规格需要新美术方向或改战斗规则才能成立，只列证据/选项，`[BLOCKED]` 冻结，不代拍。

## 依据（全部本会话实测复核）

- 缺口事实：`docs/audit/phase0a-presentation-gap-audit-2026-08-16.md`（七类缺口 + 性能/资源基线）。
- 接线边界：`docs/audit/phase0a-production-wiring-audit-2026-08-16.md` §4/§6（纯 Flutter、单角色水墨 ARPG、probe 数字不直迁、共用确定性核）。
- 音频链路：`lib/shared/audio/audio_assets.dart`（SfxId 槽位，`battleDeath:55` 预留未接线）、`dedicated_audio_assets.dart:29-42`（battleUlt/battleChargeStart 借用登记）。
- 资产现状（`find <dir> -type f | wc -l` 逐目录实测）：`assets/audio/sfx/` 20（19 mp3 + .gitkeep）、`assets/audio/bgm/` 12（11 mp3 + .gitkeep）；`assets/characters/` 16、`assets/enemies/` 266、`assets/scenes/` 148；webp-in-png 约定见 `assets/README.md`。
- probe 事件模型参考：`tools/phase0minus_probe/lib/phase0b/feedback/feedback_events.dart` / `feedback_cues.dart`（语义事件 + 静音 cue 契约）。

## 验收标准

1. 三份文档存在、各 ≤150 行，行数 `wc -l` 实测。
2. 事件契约覆盖派单列出的全部语义事件：attack/projectile/hit/defeated、dash、gather started+applied、clear started+applied、elite telegraph/break window/broken、wave started/cleared、victory/defeat、skill availability 五态；每个事件写明触发时机、最小 payload（语义字段，不锁 Dart API）、顺序/去重规则、视觉、音频、无资产克制回退、可读性/性能约束。
3. manifest 按祖师/山贼/精英动作、掌风、Q、R、命中/死亡、破招、波次/HUD、音频分组；每组写明可复用/借用、缺失与建议落点+命名规则、可交付规格（比例/安全区表述，不伪造像素数）、P0/P1/P2、前置依赖、验收方式。
4. 规格明说：probe 不再改；正式验收对象 = 根应用真实入口；音频复用 `lib/shared/audio` 现有后端、不新增依赖。
5. 所有「已有/缺失/借用/未接线」结论附精确路径或搜索命令，文末列核心命令。
6. `git diff --check` 干净；`git status` 仅三份新文档；无新资产/生成物。

## 任务切片

- 切片 A（本切片）：三份文档成稿 + 自验收 + 冻结 commit，tip 前缀 `[READY]`。
- 后续（非本单）：Qoder deterministic simulation core / input adapter 冻结后，reducer 消费本契约；资产制作与接线按 manifest P0→P2 另行派单。

## 当前恢复点

- 状态：切片 A 返修完成已冻结（`5f4f2b9c` 后为返修 commit，非 amend/rebase）。
- 最后完成：按返修 7 点修订三份文档——契约总纲区分平衡常量与运行时结算结果；hit_landed 补 `resolved_damage`/`remaining_health`；gather/clear applied 改有序 `outcomes` 列表；skill_availability_changed 补 `cooldown_remaining`/`qi_current`/`qi_required`；attack_started 删强制配对；enemy_defeated 回退锁静音并禁借 battleStagger；复核命令改逐目录 `find`。
- 下一步：无（单切片任务）；评审按 §8.2 Gate。
- 已跑验证：`git diff --check`；`wc -l` 三份均 ≤150；`find <dir> -type f | wc -l` 逐目录实测。
- 阻塞项：无。

## 核心复核命令

```sh
find assets/audio/sfx -type f | wc -l                          # 20(19 mp3 + .gitkeep)
find assets/audio/bgm -type f | wc -l                          # 12(11 mp3 + .gitkeep)
find assets/characters -type f | wc -l                         # 16
find assets/enemies -type f | wc -l                            # 266
find assets/scenes -type f | wc -l                             # 148
grep -n "battleDeath" lib/shared/audio/audio_assets.dart       # :47,:55 预留未接线
grep -n "temporaryBorrowed" lib/shared/audio/dedicated_audio_assets.dart  # battleUlt/battleChargeStart 借用
grep -rn "AudioPlayer\|audioplayers" tools/phase0minus_probe/lib          # 0 命中(probe 无音频)
ls tools/phase0minus_probe/assets/phase0b/runtime/             # probe 4 张消费图仅参考
```
