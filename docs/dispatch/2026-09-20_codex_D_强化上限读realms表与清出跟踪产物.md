# 派单包 D · 强化上限读 realms 表 + 清出 12 个跟踪产物（用户 2026-09-20 拍板「1A 2A」）

- 执行端：codex（`codex exec`，默认模型）
- worktree：`/Users/a10506/Codex/2026-09-20/cap-and-untrack/wt`（分支 `codex/cap-and-untrack-20260920`，基线 `67dca7567`；已预热：libisar.dylib / pub get / build_runner）
- 派单基线（Gate 用）：`base_sha = 67dca7567`
- 拍板依据：`docs/dispatch/reports/2026-09-19_afk_report.md` 决策菜单 1A（清出 `test/tools/output/*` 12 个跟踪产物）与 2A（`_enhanceLevelCap` 的 49 硬编码改读 realms 表绝对层数上限）。**用户已拍板，不重新论证**。两目标文件域不相交，各自独立 commit。

## 0. 总则（硬约束）

- **语言**：commit message、代码注释、文档一律简体中文；commit message 中文动宾。
- **可写范围（白名单，精确路径）**：
  - `lib/shared/battle_shared/derived_stats.dart`（只加 `RealmUtils.maxAbsoluteLevel`，不动其他公式）
  - `lib/features/equipment/application/enhancement_service.dart`
  - `lib/features/equipment/presentation/enhance_dialog.dart`（只把 `_capHardLimit` 常量改读 `RealmUtils.maxAbsoluteLevel`，不动 UI 结构/文案）
  - `data/numbers.yaml`（只改 `:727` 那一行 `UNUSED` 头注的文字，**不改任何 key、不改任何数值**）
  - `test/combat/derived_stats_test.dart`
  - `test/features/equipment/application/enhancement_service_test.dart`
  - `test/features/equipment/application/enhancement_cap_realms_test.dart`（新建）
  - `test/tools/output/battle_intervention_value_2026-07-18.csv`
  - `test/tools/output/battle_intervention_value_2026-07-18.md`
  - `test/tools/output/phase0a_ch1_real_skill_profile_2026-08-20.csv`
  - `test/tools/output/phase0a_ch1_real_skill_profile_2026-08-20.md`
  - `test/tools/output/phase0a_fragment_economy_diagnostic.csv`
  - `test/tools/output/phase0a_fragment_economy_diagnostic.md`
  - `test/tools/output/phase0a_full_content_balance_diagnostic.csv`
  - `test/tools/output/phase0a_full_content_balance_diagnostic.md`
  - `test/tools/output/phase0a_idle_island_parity_diagnostic.csv`
  - `test/tools/output/phase0a_idle_island_parity_diagnostic.md`
  - `test/tools/output/phase2_g2_stage_01_03_acceptance_record.md`
  - `test/tools/output/progression_attribute_playtest_2026-07-13.csv`
  - `docs/audit/phase2_g2_stage_01_03_acceptance_record.md`（新建，由 `git mv` 产生，见目标 3）
  - `docs/dispatch/2026-08-26_night_plan.md`（仅改上一条的路径引用）
  - `docs/dispatch/G2_playtest_runbook_20260827.md`（同上）
  - `docs/dispatch/phase0a_overhaul/task_registry.yaml`（同上）
  - `docs/dispatch/phase2_wiring/N15_density_fx_evidence.md`（同上）
  - `docs/superpowers/plans/2026-09-20-codex-d-cap-and-untrack.md`（新建，恢复点）
  - `docs/dispatch/reports/2026-09-20_codex_D_receipt.yaml`（新建，收据）
  - **其余一律禁改**，特别是 `GDD.md`、`PROGRESS.md`、`BACKLOG.md`、`CLAUDE.md`、`AGENTS.md`、`.gitignore`（`:89` 已覆盖 `test/tools/output/`，无需改）、`pubspec.yaml`、`lib/shared/strings.dart`、`lib/data/**`、`tools/**`、`docs/audit/**` 其他文件。协调者以 `git diff --name-only` 机器判定：出现白名单外路径整单 FAIL。若确需改白名单外文件，**停下打 `[BLOCKED]`** 写明路径与原因，不要自行扩围。
- **git 边界**：只在自己的 worktree 提交；禁 push / merge / rebase / revert；禁碰 `main` 与 `codex/p2-player-flow-20260910`。
- **环境边界**：禁安装任何软件。
- **不碰真实存档**（`~/Library/Containers/com.pen.wuxia.wuxiaIdle/` 只读），不启动游戏 GUI。
- **就绪标记**：最后实质 commit S 带 `[READY]`/`[BLOCKED]` 前缀；收据放独立包装 commit R（`R^ == S`，只含收据 + 恢复点），R 消息以同样标记开头。
- **数值零变更**：realms 表当前最大 `absolute_level` = 49，与原硬编码同值，生产运行时行为逐位相同。
- **TDD + 双向破坏证红**：目标 1 先写红测再实装；实装 commit 后做两向 mutation，还原后重跑绿，结果写进收据 `break_red`。
- **commit 顺序固定**：先做目标 3（`git rm --cached` / `git mv`，**单独一个 commit S0**，标题含「清出跟踪产物」，不带 `[READY]`）→ 再做目标 1 + 目标 2（可同一 commit，即最后实质 commit **S**，带 `[READY]`）→ R。协调者用 `S0..S` 跑 Gate（避免 12 个产物的删除行被 `test_deletions` 误计），对 S0 单独核「只有删除/改名/路径引用改动」。

## 1. 目标清单

### 目标 1：`_enhanceLevelCap` 与 `_capHardLimit` 改读 realms 表绝对层数上限

- 现状：`lib/features/equipment/application/enhancement_service.dart:292-294` `_enhanceLevelCap` 写死 `49`；`lib/features/equipment/presentation/enhance_dialog.dart:65` `static const int _capHardLimit = 49`。同一终点的事实源是 `data/numbers.yaml` `realms.tiers[*].layers[*].absolute_level`（当前最大 49，`:498`），由 `GameRepository.instance.realms`（`List<RealmDef>`，字段 `absoluteLevel`）装载。**拍板口径：读 realms 表最大 `absoluteLevel`，不读 `progression.release_cap.max_absolute_realm_level`**（后者是内容发布门，语义不同，对照单 §5 已辨析）。
- 做法：
  1. `lib/shared/battle_shared/derived_stats.dart` `RealmUtils` 新增 `static int get maxAbsoluteLevel`，= `GameRepository.instance.realms` 中 `absoluteLevel` 的最大值（空表抛 `StateError`，不给默认值）。放在 `absoluteLevelOf` 旁，注释写明「强化上限事实源」。
  2. `_enhanceLevelCap` 改为 `min(characterAbsoluteLevel, RealmUtils.maxAbsoluteLevel)`；`:69` 与 `:290-291` 两处注释里的「min(49, …)」改成「min(realms 表最大 absoluteLevel, …)」。
  3. `enhance_dialog.dart` `_capHardLimit` 由 `static const int = 49` 改为读 `RealmUtils.maxAbsoluteLevel`（getter 或在 build 内取值均可），`:28` 头注同步；其余逻辑不动。
- 测试（先红后绿）：
  - `test/combat/derived_stats_test.dart` 加 1 条：`RealmUtils.maxAbsoluteLevel == 49` 且等于 `GameRepository.instance.realms.map((r) => r.absoluteLevel).reduce(max)`（从生产数据算，不写第二个 49 字面量之外的常量）。
  - 新建 `test/features/equipment/application/enhancement_cap_realms_test.dart`：用 `GameRepository.resetForTest()` + `GameRepository.loadAllDefs(loader: …)` 注入一份**改过的 `numbers.yaml`**（参考 `test/features/tower/domain/tower_floor_def_test.dart:270-277` 的 `makeLoader` 写法；其他 yaml 走原 `loadTestAsset`）：把 realms 表武圣·登峰那一层删掉（或把最后一层 `absolute_level` 与 `release_cap.max_absolute_realm_level` 同步降到 48），使表最大值 = 48；断言 `RealmUtils.maxAbsoluteLevel == 48`、`tryEnhance(eq.enhanceLevel = 48, characterAbsoluteLevel: 490)` → `EnhanceOutcome.capped`、`enhanceLevel` 仍 48。**这是唯一能让「硬编码 49 回退」变红的测试，必须做出来**；若装载期校验拒绝改过的表，先看是哪条校验、在 fixture 里把相关字段一起改一致；仍不行 → `[BLOCKED]` 写明抛错原文，不得删校验、不得改 `lib/data/**`。
  - `enhancement_service_test.dart:278` 既有「display Lv490 不抬 cap 超 49」断言原值通过。
- 双向证红（commit 后做，写进收据）：① `_enhanceLevelCap` 临时改回 `< 49 ? … : 49` → `enhancement_cap_realms_test` 必红；② `RealmUtils.maxAbsoluteLevel` 临时改 `return 49` → 同一测试必红；各自还原后重跑绿。

### 目标 2：`numbers.yaml:727` 头注同步（注释一行，零 key/数值变更）

- 现文：`# UNUSED(2026-09-19 二轮·头注): max_level_formula 为公式名文档锚,上限规则写死 enhancement_service._enhanceLevelCap(min(49, absoluteLevel))。`
- 改为：`# UNUSED(2026-09-19 二轮·头注): max_level_formula 为公式名文档锚,上限规则 = enhancement_service._enhanceLevelCap(min(realms 表最大 absolute_level, 角色 absoluteLevel)),2026-09-20 起读表不再写死 49。`
- 保留 `UNUSED(` 令牌与 `max_level_formula:` 那一行原样。`python3 -c "import yaml;yaml.safe_load(open('data/numbers.yaml'))"` 通过；`git diff 67dca7567 -- data/numbers.yaml` 只允许出现这一行的 `-`/`+`。

### 目标 3：清出 12 个 `test/tools/output/*` 跟踪产物（单独 commit）

- 现状：`git ls-files test/tools/output` 列出 12 个文件（白名单里逐一列出），`.gitignore:89` 早已忽略该目录，但历史上被 `add -A` 误提交。11 个是测试/试玩生成物或历史数据；`phase2_g2_stage_01_03_acceptance_record.md` 是**手写的 G2 正式验收记录**（无生成器，被 4 份 dispatch 文档作为证据引用），不能只是丢掉。
- 做法：
  1. 11 个生成物：`git rm --cached <file>`（**只解除跟踪，不删磁盘文件**）。
  2. `git mv test/tools/output/phase2_g2_stage_01_03_acceptance_record.md docs/audit/phase2_g2_stage_01_03_acceptance_record.md`，并把 `docs/dispatch/2026-08-26_night_plan.md`、`docs/dispatch/G2_playtest_runbook_20260827.md`、`docs/dispatch/phase0a_overhaul/task_registry.yaml`、`docs/dispatch/phase2_wiring/N15_density_fx_evidence.md` 四处对旧路径的引用改为新路径（`git grep -n phase2_g2_stage_01_03_acceptance_record` 定位；只改路径串，不改其他文字）。
  3. 完成后 `git ls-files test/tools/output` 必须为空；`git grep -n 'test/tools/output/phase2_g2_stage_01_03_acceptance_record' -- docs` 为 0 命中。
- 不改 `.gitignore`，不改任何 `test/tools/*_test.dart`（它们仍写入该目录，目录被 ignore 即可）。

## 2. 验证（全部完成后）

- `flutter analyze --no-pub lib test tool` 0 issue；`dart format --output=none --set-exit-if-changed lib test docs` 0 changed（写完 dart 必 `dart format`）。
- targeted 逐文件确认 `All tests passed!`：`test/combat/derived_stats_test.dart`、`test/features/equipment/application/enhancement_service_test.dart`、`test/features/equipment/application/enhancement_cap_realms_test.dart`、`test/features/equipment/presentation/enhance_dialog_test.dart`、`test/features/inventory/presentation/equipment_detail_screen_test.dart`、`test/data/truth_source_guard_test.dart`。
- 全量 `flutter test --no-pub`（**前台跑**，不放后台），收据写 reporter 末行原文与 `[E]` 块数。
- 残留检查：`git grep -n -E '\b49\b' -- lib/features/equipment/application/enhancement_service.dart lib/features/equipment/presentation/enhance_dialog.dart` 只允许出现在注释里对「当前值 49」的说明，代码路径 0 命中。

## 3. 禁止的修法

- 禁止改任何生效数值（realms 表、release_cap、强化曲线）。
- 禁止给 `maxAbsoluteLevel` 兜底默认值（空表 fail-fast）。
- 禁止改读 `progression.release_cap.max_absolute_realm_level` 代替 realms 表。
- 禁止在测试里手设字段绕开生产路径（判据：「破坏那行生产代码，这条断言必然红吗」）。
- 禁止用 `git rm`（不带 `--cached`）删磁盘文件；禁止改 `.gitignore`。
- 禁止把目标 3 与目标 1/2 混在同一个 commit。

## 4. 收据与恢复点

- 按 `~/.claude/skills/afk/scripts/receipt.schema.md` 产 `docs/dispatch/reports/2026-09-20_codex_D_receipt.yaml`：`base_sha` = **S0** 全 40 位（Gate 以 S0 为基线）、`head_sha` = S 全 40 位、`changed_files` = `git diff --name-only S0..S` 全部、三条 last_line 真跑原文（不得 NOT_RUN）、`error_block_count`、`break_red` 两向各写失败测试名与失败条数。
- 恢复点 `docs/superpowers/plans/2026-09-20-codex-d-cap-and-untrack.md`：状态 / 最后完成 / 下一步 / 已跑验证 / 阻塞项。

## 5. [BLOCKED] 出口条件

- 改过 realms 表的 fixture 被装载期校验拒绝且无法在 fixture 内自洽解决。
- 任一向 mutation 不红（断言无牙）。
- 需要改白名单外文件。
- `enhance_dialog` 相关 widget 测试在未装载 `GameRepository` 的路径上抛错且无法在测试 `setUp` 内装载解决（说明 UI 有不经 repo 的入口，需协调者判）。

## 6. 验收方式（协调者怎么查）

- `gate.sh <worktree> <S0> <S> --whitelist-from <本派单包> --allow-forbidden data/numbers.yaml --wrap-tip <R>`（目标 1/2 的 commit 范围，含全量；`--allow-forbidden` 是本单唯一豁免，对应 `numbers.yaml:727` 注释一行）；S0 单独核：`git show --stat S0` 只有 11 个 `D`、1 个 `R`、4 个文档路径引用改动；`git ls-files test/tools/output` 为空；`git diff 67dca7567..S0 -- lib data` 为空且 `test/` 下无 `.dart` 改动。
- 协调者复跑：`enhancement_cap_realms_test` 绿；抽做 mutation ①；`git grep` 残留 49 为 0（代码路径）。
