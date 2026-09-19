# Phase 0A 满 build 真实路径极值探针恢复点（派单包 B）

- 目标：补 CLAUDE.md §5.4 / GDD 记录的缺口——既有 calculator 探针不经 reducer，既有 reducer 诊断只用 Ch1 起手画像。造「满 build × 真实 Phase 0A reducer × 全生产内容 × 最大周目」极值探针，硬断言每轮单点结算伤害 < 1,000,000。
- 分支：`qoder/b-fullbuild-probe-20260919`（独立 worktree，仅本地提交，不 push/merge/rebase/revert）。
- 派单基线：`5d9bbdeafbc93361a6f0fa64d7a500c6e6b86b92`。
- 开始时间：2026-09-19（续作）；当前恢复点写入 2026-09-19 18:11:58 +0800。
- 写入范围：仅派单六个白名单新文件；`lib/**`、`data/**`、既有 `test/**`、`pubspec.yaml`、`GDD/CLAUDE/PROGRESS/BACKLOG.md`、`lib/shared/strings.dart` 全部只读。**零生产代码改动**。
- 单类型：零 `lib/` 改动 → Gate 判为**审计单**；收据 `break_red` 留空、改填 `audit_verification`。但改动含 `test/**/*.dart`（3 个）→ **`NOT_RUN` 口径不适用**，三项 last_line 必须实跑真值。
- 验收：三系锁死不静默降级（拒绝即 throw）；快照恒由生产装配器产出；周目上限/熟练度档读 numbers 不硬编码；差异仅白名单；中文提交；干净工作区；不改任何数值。

## 当前恢复点

- 状态：目标 1–4 全部落地并验证；探针 GREEN，软红线守住。待生成事实收据并封装 R。
- 已提交：
  - `2e0839eb0` 目标 1：满 build 画像夹具 + 自检（`test/support/phase0a_full_build_profile.dart` / `_test.dart`）。
  - `5b18a59cf` 目标 2：极值探针（`test/tools/phase0a_full_build_extreme_probe_test.dart`）。
  - 工作区另有 3 个 .dart 的 `dart format` 整形（纯排版，语义不变）+ 报告 + 本恢复点，将并入最后一个实质 commit S。
- 下一步：① 提交 S（格式化后的 3 个 .dart + 报告 + 本恢复点，消息带 `[READY]`）；② 在 S 上实跑 full test / analyze / format 取三项 last_line、算 `patch_sha256` 与 `diff_check_exit`；③ 写收据 `docs/dispatch/reports/2026-09-19_qoder_B_receipt.yaml`（`head_sha=S`）；④ 提交封装 R（仅收据，`R^==S`，消息带 `[READY]`）。

## 目标落地结果

- 目标 1（夹具）：与 `seedPhase0aCh1FounderProfile` 同源生产路径起档，经 `CharacterAdvancementService.applyExperience` 推到武圣·登峰（不直写 `realmTier`），神物三槽满强化 +49 / 心剑通灵共鸣 / 开锋三槽满，主修本流派传说神功推满极境，辅修循环学习到生产 `assistSlotsFull` 拒绝（派生上限 3），快照恒由 `PlayerCombatantSnapshotAssembler` 重装。自检三流派全绿。
- 目标 2（探针）：154 条生产内容（主线 105 + 爬塔 49）× 周目 {1, 上限}（主线 3 / 爬塔 2，读 `numbers.cycle_evolution`）× 3 流派 × 最高熟练度档（huaJing/800/×1.30），固定 seed=0，`deltaSeconds`/`maxTicks` 复用 `numbers.phase0aArena`。共 **924 轮**，单 `test`（未分组，wall clock ≈1s，远低于 15 分钟阈值）。
- 实测：**922 胜 / 2 负 / 0 超时**；全局最大单点伤害 **382584** @ lingQiao `stage/stage_13_01#c1`（余量 61.7%）；平均 ticks 27.4。软红线守住（max < 1e6）。
- 2 处败局：lingQiao `stage_19_05#c3` / `stage_20_05#c3`（终局主线周目 3），玩家单点仅 64886、ticks 65/80；非红线问题，已在报告异常段登记，不调值、不放宽 `timeouts==0` 断言。
- 目标 4（报告）：`docs/audit/phase0a_full_build_extreme_probe_2026-09-19.md`（97 行 ≤150）。

## 夹具程序化选取（实际 id，无硬编码清单）

| 流派 | 武器(神物) | 主修(传说神功) | 辅修 ×3 |
|---|---|---|---|
| gangMeng | weapon_shenwu_hun_yuan_chui | tech_gangmeng_chuanshuo | tech_gangmeng_chuanshuo_fang / _nei / tech_gangmeng_shichuan |
| lingQiao | weapon_shenwu_tian_wen_jian | tech_lingqiao_chuanshuo | tech_lingqiao_chuanshuo_fang / tech_lingqiao_shichuan / _fang |
| yinRou | weapon_shenwu_huan_meng_bian | tech_yinrou_chuanshuo | tech_yinrou_chuanshuo_fang / tech_yinrou_shichuan / _fang |

- 护甲/饰品三流派通用：`armor_shenwu_tian_can_bao_jia` / `accessory_shenwu_kun_lun_pei`。
- 三流派武器 id、主修 id 两两互异（自检 `hasLength(3)` 钉死）。
- 快照装备派生攻击 **20706**（含同流派心法相生 ×1.20），血 20000（红线钳制），速 1320；均越过基础表值红线 2000（派生值放行）。

## 破坏证红（目标 3，两向 + 还原重跑绿）

- 方向①（降强化）：临时把 `phase0a_full_build_profile.dart:223` `enhanceLevel: maxEnhance` 改为 `0`，复跑 `test/support/phase0a_full_build_profile_test.dart` → **1 失败**：「满 build 画像夹具：三流派均达终局构筑且选取互不相同」，`:83` `expect(equippedWeapon.enhanceLevel, profile.maxEnhanceLevel)` Expected `<49>` Actual `<0>`。`git checkout --` 还原。
- 方向②（压阈值）：临时把 `phase0a_full_build_extreme_probe_test.dart:145` `lessThan(_damageRedLine)` 改为 `lessThan(1)`，复跑该探针 → **1 失败**：「Phase 0A 满 build 真实路径全内容极值探针」，`:143` Expected `<1>` Actual `<103391>`（gangMeng `stage_01_01` 周目1）。`git checkout --` 还原。
- 两向还原后 `git status` 干净（仅余报告未跟踪），复跑自检 + 探针 **双绿（`+2: All tests passed!`）**——证自检与探针断言均有牙、非空过。
- 口径：本单审计单，收据 `break_red` 留空；上述两向结果按派单要求登记于报告与本恢复点。

## 建议上提（偏离生产经济/约束，均只登记不擅改）

1. 夹具直接 `Equipment.create` 设强化/共鸣/开锋，绕过 `EnhancementService`/`ForgingService` 材料经济路径——为极值探针有意跳过养成成本。
2. 开锋一、二同取 `attack`，违反生产「开锋二不得与开锋一同类型」约束；与既有红线 oracle `full_build_damage_redline_test.dart` 同体例，为可比性保留。
3. 辅修槽上限在生产 `technique_learning.dart` 写死为 3、未进 `numbers.yaml`；建议后续把该上限提为可配数值，夹具即可改为读配置而非依赖生产拒绝派生。
4. 同流派心法相生（攻击 +0.20）在三流派程序化选取下一律触发（`schoolPair`/`specificTechniques` 不匹配同源选取），故快照装备攻击 20706 高于 calculator 探针 17255。

## 与既有 calculator 探针对比（实测取值，非誊写）

- `test/balance/full_build_damage_redline_test.dart` 2026-09-19 实跑：满 build 普攻 × 克制1.25 × 弱点1.25 非暴击 72378 / 暴击 108567；满破甲 Σpierce0.60 finalDamage 134121；破绽窗口 effDef0.175 finalDamage 136261；装备攻击 17255（无心法相生）。
- 本探针经真实 reducer 全内容 × 周目横扫，全局最大单点 382584，与 calculator 单点同量级、均远不进百万，两路互为佐证。

## 验证命令（在 S 上取真值写收据）

- `flutter test --no-pub`（全量，无过滤）→ `full_test_last_line` + `error_block_count = grep -c '^\[E\]'`。
- `flutter analyze --no-pub lib test` → `analyze_last_line`（预跑：`No issues found!`）。
- `dart format --output=none --set-exit-if-changed .` → `format_last_line`（预跑：`Formatted 1863 files (0 changed)`）。
- `git diff --check <base>..<S>` 退出码 → `diff_check_exit`（须 0）。
- `LC_ALL=C git -c core.quotePath=false --no-pager diff --no-ext-diff --no-textconv --no-renames --binary --full-index --no-color <base>..<S> | shasum -a 256` → `patch_sha256`。

## 复跑

- 探针：`flutter test --no-pub test/tools/phase0a_full_build_extreme_probe_test.dart -r expanded`（默认不写报告）；生成报告前置 `PROBE_REPORT=1`。
- 自检：`flutter test --no-pub test/support/phase0a_full_build_profile_test.dart`。
