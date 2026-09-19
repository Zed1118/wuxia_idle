# 派单包 B · Phase 0A 满 build 真实路径极值探针（TDD 测试工程单）

- 执行端：qoderclicn（Qwen3.8-Max）
- worktree：`/Users/a10506/Qoder/2026-09-19/b-fullbuild-probe/wt`（分支 `qoder/b-fullbuild-probe-20260919`，基线 `5d9bbdeaf`；已预热 libisar.dylib + pub get + build_runner，`lib/` 下 69 个 `.g.dart`）
- 派单基线（Gate 用）：`base_sha = 5d9bbdeaf`

## 0. 总则（硬约束）

- **语言**：commit message、文档、测试名一律简体中文；commit message 中文动宾（如「新增 Phase 0A 满 build 真实路径极值探针」）。
- **可写范围（白名单，精确路径）**：
  - `test/tools/phase0a_full_build_extreme_probe_test.dart`（新建，本单主产出）
  - `test/support/phase0a_full_build_profile.dart`（新建，满 build 画像夹具；只在确需与现有 support 分离时新建）
  - `test/support/phase0a_full_build_profile_test.dart`（新建，夹具自检）
  - `docs/audit/phase0a_full_build_extreme_probe_2026-09-19.md`（新建，探针报告）
  - `docs/superpowers/plans/2026-09-19-qoder-b-fullbuild-probe.md`（新建，恢复点）
  - `docs/dispatch/reports/2026-09-19_qoder_B_receipt.yaml`（新建，收据）
  - **其余一律禁改**，特别是 `lib/**`（本单零生产改动）、`data/**`、`data/numbers.yaml`、既有 `test/**` 文件（含 `test/support/phase0a_profile_harness.dart`、`phase0a_ch1_founder_profile.dart`、`test/tools/phase0a_full_content_balance_diagnostic_test.dart`、`test/balance/full_build_damage_redline_test.dart`）、`pubspec.yaml`、`GDD.md`、`CLAUDE.md`、`PROGRESS.md`、`BACKLOG.md`、`lib/shared/strings.dart`。协调者以 `git diff --name-only` 机器判定：出现白名单外路径整单 FAIL。若夹具确需现有 support 暴露新参数，**不改它**，在新文件里复制最小必要逻辑并在报告登记「建议上提」。
- **git 边界**：只在自己的 worktree 提交；禁 push / merge / rebase / revert；禁碰 `main` 与 `codex/p2-player-flow-20260910`。
- **环境边界**：禁安装任何软件；禁改本机配置。
- **不碰真实存档**（`~/Library/Containers/com.pen.wuxia.wuxiaIdle/`），不启动游戏 GUI，测试用 `initializeTestIsarCore` + 临时目录（照 `test/tools/phase0a_full_content_balance_diagnostic_test.dart` 的做法）。
- **就绪标记**：最后实质 commit S 带 `[READY]`/`[BLOCKED]`；收据放独立包装 commit R（`R^ == S`），R 消息带同样标记。
- **数值红线**：本单不改任何数值。探针若发现 ≥ 1,000,000 的伤害，**不调数值、不改断言阈值、不放宽**——记录并打 `[BLOCKED]`。

## 1. 背景（一句话）

CLAUDE.md §5.4 与 GDD 明文登记的缺口：现有两道守卫，`test/balance/full_build_damage_redline_test.dart` 是满 build 但只走 `DamageCalculator` 不经 Phase 0A reducer；`test/tools/phase0a_full_content_balance_diagnostic_test.dart` 走真实 reducer 但只用 Ch1 祖师起手画像（`test/support/phase0a_ch1_founder_profile.dart`），**不覆盖满 build、飞升阶差、周目**。本单补上「满 build × 真实 reducer 路径 × 全部生产内容 × 最大周目」的极值探针，硬断言 `maxResolvedDamage < 1,000,000`。

## 2. 目标清单（TDD：先红后绿，每目标收口 commit 一次）

### 目标 1：满 build 画像夹具（走生产装配器，不手拼快照）

- 用与 `seedPhase0aCh1FounderProfile` 相同的方式造角色（Isar 临时库 + `GameRepository`），但把角色推到**武圣·登峰**（`RealmTier.wuSheng` 最高层，经验用 `CharacterAdvancementService` 走生产路径推进；不得直接改 `realmTier` 字段绕过），三槽装神物阶装备并强化到 `equipment.enhancement` 的最大等级（+49）、共鸣度到最高阶、开锋 3 槽满、主修心法为传说神功且修炼度最高层、辅修按 `numbers.yaml` 允许上限配满；三流派各一套（刚猛 / 灵巧 / 阴柔），流派内选**攻击最高**的神物武器与心法（从 `data/equipment.yaml` / `data/techniques.yaml` 程序化选取，禁止硬编码 id 清单——用 `where`+`reduce` 取 max 并在报告里打印选中的 id）。
- 快照必须由 `PlayerCombatantSnapshotAssembler` 生成（同 `phase0a_ch1_founder_profile.dart:74`），任何一步装备/心法失败（三系锁死校验拒绝）即 `throw`，不得静默降级。
- 夹具自检测试（`test/support/phase0a_full_build_profile_test.dart`）：断言快照的境界 = wuSheng、装备阶 = shenWu、强化 = 最大、三流派 id 互不相同、装备攻击派生值 > 2000（证明强化×共鸣×开锋连乘生效，见 CLAUDE §5.4「派生有效攻击远超 2000 是有意终局爽感」）。

### 目标 2：极值探针测试（`test/tools/phase0a_full_build_extreme_probe_test.dart`）

- 内容集合：与 `phase0a_full_content_balance_diagnostic_test.dart` 相同的生产 manifest（`test/support/phase0a_production_preflight_manifest.dart`，105 主线 + 49 塔 = 154 条；实测数以 manifest 为准，报告里写实测值）。
- 维度：3 流派 × 154 内容 × 周目 {1, `numbers.yaml cycle_evolution.max_cycle_mainline`（主线）/ `max_cycle_tower`（塔）}（通过 `Phase0aStageContentMapper` 的 `cycleIndex` 参数，见 `lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:183/211`；周目上限从 `NumbersConfig` 读，禁写死 3/2）× 熟练度取最高档（沿用现有诊断的最高 `minUses` 档）。每局固定 seed（照现有诊断的 seed 派生方式），`deltaSeconds`/`maxTicks` 沿用现有诊断常量。
- 硬断言（每局）：`observation.maxResolvedDamage < 1000000`；另断言 `outcome` 不为 timeout 的局数占比 ≥ 现有诊断的 timeout 口径（现有 2310 局 0 timeout；若出现 timeout 原样记录，不放宽）。
- 输出：Markdown 汇总表（与现有诊断 `:282` 行同列格式）写到 `test/tools/output/`**之外**——写到 `docs/audit/phase0a_full_build_extreme_probe_2026-09-19.md`（由测试通过 `Platform.environment['PROBE_REPORT']` 指定路径时才写，默认不写文件，避免测试产物污染）；报告至少含：全局 max 伤害及其（流派/内容/周目/tick）、按周目分组的 max、Top 10 伤害局、胜率/均 tick 分布、与现有 calculator 探针（~5.8 万普攻 / ~8.7 万暴击，本次从 `full_build_damage_redline_test` 的实测值取，不转抄）的对比。
- 运行成本：先跑单流派单周目估时，若全矩阵 > 15 min，把内容按 manifest 顺序分成 ≤ 4 组各一个 `test(...)`，**不减内容、不抽样**。

### 目标 3：破坏证红（commit 之后做，两向，然后完整还原）

1. 临时把夹具的强化等级改成 0（或境界改成 xueTu）→ 自检测试必红；
2. 临时把探针断言阈值改成 `lessThan(1)` → 探针必红（证明断言真的在比较伤害而不是恒真）。
   每向记录失败数与失败测试名，`git checkout -- <file>` 还原，`git status` 干净后**重跑绿**。写进收据 `break_red`（本单是代码单：`changed_files` 只有 test/docs 但 Gate 以 `lib/` 改动判类型——本单 lib 零改动，Gate 会判为审计单；因此 `break_red` 留空、按审计单填 `audit_verification`，但目标 3 的两向证红结果**必须写进报告与恢复点**）。

### 目标 4：报告 + 结论

`docs/audit/phase0a_full_build_extreme_probe_2026-09-19.md`（≤ 150 行）：夹具构成（选中的 id、派生攻击值）/ 矩阵规模与墙钟 / 结果表 / 结论三选一：`软红线守住（max < 1e6）` / `触线（列局）` / `未能判定（原因）`。若发现「满配对普通终局内容一回合秒杀」以外的异常（如机制型 Boss floor25/30 被秒、或某内容 timeout），单独一节登记，不建议改数值。

## 3. 禁止的修法

- 禁止手拼 `CombatantSnapshot`（绕开三系锁死与装配器）；禁止直接写 `character.realmTier = ...` 绕过成长服务；禁止硬编码装备/心法 id。
- 禁止改断言阈值、跳过 timeout 局、抽样内容、缩小周目集合、调 `deltaSeconds`/`maxTicks` 让局数变短。
- 禁止改任何既有测试或 support 文件来「借」参数——需要就在新文件里复制并登记「建议上提」。
- 禁止改 `lib/`。

## 4. 收据与恢复点

- 按 `~/.claude/skills/afk/scripts/receipt.schema.md` 产 `docs/dispatch/reports/2026-09-19_qoder_B_receipt.yaml`；本单必须跑 `flutter test --no-pub`（全量）、`flutter analyze --no-pub lib test`、`dart format --output=none --set-exit-if-changed .`，三条 last_line 填真实输出（不得 `NOT_RUN`）。全量预算 10–20 min，不得过滤。
- 收据自引用口径：`head_sha` = 最后实质 commit S；收据单独提交为 R（`R^ == S`）。
- 恢复点 `docs/superpowers/plans/2026-09-19-qoder-b-fullbuild-probe.md`：目标 / 分支 / 验收标准 / 任务切片 / 当前恢复点。

## 5. [BLOCKED] 出口条件

- 任一局 `maxResolvedDamage ≥ 1,000,000` → 探针红，**保留红测**（不放宽），报告写清局参数，tip 打 `[BLOCKED]`。
- 生产装配器拒绝满 build（例如某神物装备无法在武圣装备、传说神功不可修）→ 说明三系锁死或数据不自洽，记录拒绝原文，打 `[BLOCKED]`，不绕过。
- 全矩阵墙钟 > 30 min 且分组后仍超 → 记录实测，打 `[BLOCKED]` 让协调者决定是否接受为慢测。

## 6. 验收方式（协调者怎么查）

- `gate.sh <worktree> 5d9bbdeaf <S> --whitelist-from <本派单包> --wrap-tip <R>` 全 PASS；协调者独立复跑 `flutter test --no-pub test/tools/phase0a_full_build_extreme_probe_test.dart test/support/phase0a_full_build_profile_test.dart` 并自做一次目标 3 的两向证红。
- 抽检：报告里的选中 id 在 `data/equipment.yaml`/`techniques.yaml` 里确为该流派攻击最高的神物/传说神功；周目上限与 `numbers.yaml:2093-2094` 一致。
