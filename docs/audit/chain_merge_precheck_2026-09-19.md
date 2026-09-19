# 链 → main 合并预检证据单（2026-09-19 · 派单包 A）

只读证据单：本单零修复，发现问题只登记。所有数字均为本次在 tip 上实测，未转抄 PROGRESS / 历史报告。

## 基线与命令环境

- worktree：`/Users/a10506/Qoder/2026-09-19/a-merge-precheck/wt`，分支 `qoder/a-merge-precheck-20260919`，开跑时 `git status --porcelain` 行数 0。
- `base_sha` / 被检 tip：`5d9bbdeafbc93361a6f0fa64d7a500c6e6b86b92`（= `codex/p2-player-flow-20260910` tip）；`origin/main` = `342d1927529b8306582431be597ef1975bd69deb`。
- 工具链：Flutter 3.41.5 / Dart 3.11.3 stable（`flutter --version`），与 `.github/workflows/ci.yml:41` 钉死版本一致；`/opt/homebrew/bin/flutter`、`/opt/homebrew/bin/dart`。
- 快进事实：`git merge-base --is-ancestor origin/main HEAD` 退出 0；`git rev-list --count HEAD..origin/main` = 0；`git rev-list --count origin/main..HEAD` = 101；`git diff --name-only origin/main..HEAD | wc -l` = 336；`git merge-tree --write-tree origin/main HEAD` 退出 0，输出树 `99de5147efc8e9883c99c75a70809379fc4cb79b`（无冲突）。范围提交日期跨 2026-09-12 → 2026-09-18。
- 墙钟一律取 `date +%T` 起止，不从 reporter 的 `mm:ss` 推断小时。

## 目标 1：CI 同套命令本地镜像

| # | 命令原文（worktree 根） | 退出码 | 末 3 行（关键行原文） | 墙钟起止 |
|---|---|---|---|---|
| 1 | `flutter pub get --enforce-lockfile` | 0 | `Got dependencies!` / `58 packages have newer versions incompatible with dependency constraints.` / ``Try `flutter pub outdated` for more information.`` | 17:10:03 → 17:10:06 |
| 2 | `dart run build_runner build --delete-conflicting-outputs` | 0 | `  0s source_gen:combining_builder on 1693 inputs; lib/core/application/character_providers.dart` / `  0s source_gen:combining_builder on 1693 inputs: 1693 skipped` / `  Built with build_runner/aot in 1s; wrote 0 outputs.` | 17:10:15 → 17:10:18 |
| 3 | `dart format --output=none --set-exit-if-changed lib test docs` | 0 | `Formatted 1758 files (0 changed) in 3.71 seconds.`（仅此一行非空） | 17:10:28 → 17:10:33 |
| 4 | `flutter analyze --no-pub lib test tool` | 0 | `Analyzing 3 items...` / `No issues found! (ran in 18.1s)` | 17:10:33 → 17:10:52 |
| 5 | `flutter test --no-pub 2>&1 \| tee /Users/a10506/Qoder/2026-09-19/a-merge-precheck/full_test.log` | 0 | 末非空 reporter 行 `09:14 +6976: All tests passed!`；`grep -c '^\[E\]' full_test.log` = 0（grep 退出 1 即零命中）；日志 9935 行 / 2162440 B | 17:11:20 → 17:20:42（9 分 22 秒） |
| 6 | `flutter build macos --debug --no-pub` | 0 | `               ^` / `warning: Run script build phase 'Run Script' will be run during every build because it does not specify any outputs. ...` / `✓ Built build/macos/Build/Products/Debug/wuxia_idle.app` | 17:21:20 → 17:21:48 |
| 7 | `flutter test --no-pub --coverage` → `dart run tool/coverage_ratchet.dart` | 0 / 0 | `16:46 +6976: All tests passed!` / `Line coverage: 50827/58422 (87.00%), minimum=81.25%` | 17:32:17 → 17:49:08 → 17:49:10 |

- 第 5 步未加 `--exclude-tags` / `-j1` / 路径过滤 / `--name`，并发用默认；一次通过，无失败测试，因此不触发 flaky 复跑。
- 执行纪律披露：第 1 步首次在 17:09:49 → 17:09:53 跑过一次，因 zsh 无 `PIPESTATUS` 未取到退出码，随即以文件重定向重跑（表中 17:10:03 那次）取到 `EXIT=0`；两次输出一致。
- Gate 口径补测（`gate.sh` 实际重跑的命令，与 CI 口径不同，两者都留档）：`flutter analyze --no-pub lib test` 退出 0，末行 `No issues found! (ran in 3.0s)`（17:10:57 → 17:11:01）；`dart format --output=none --set-exit-if-changed .` 退出 0，末行 `Formatted 1860 files (0 changed) in 4.13 seconds.`（17:10:52 → 17:10:57）。收据三条 last_line 取 Gate 口径。

### 第 7 步覆盖率

- 阈值来源与判定逻辑：`tool/coverage_ratchet.dart:64` 默认读 `.github/coverage-ratchet.json` 的 `lineCoverageMinimum`，当前值 **81.25**（`sampledAt: 2026-07-12`，note 记当时全量 81.31% = 27115/33348，留 0.05 容差）；ratchet 剔除 `.g.dart` / `.freezed.dart` / `.mocks.dart`，按「源文件路径 + 行号」取各报告最大命中数，`covered/total ≥ minimum` 才过。CI 实跑形态是 4 分片 `dart run tool/run_test_shard.dart 4 <shard>`（内部即 `flutter test --coverage --no-pub --file-reporter=json:...`）再 `cat` 合并 4 份 `lcov.info`；本地等价形态为单次 `flutter test --no-pub --coverage` 生成全量 `coverage/lcov.info` —— 因 ratchet 取行级最大值，单跑全量与合并分片对同一测试集合等价。
- 实测结果：`flutter test --no-pub --coverage` 退出 **0**（17:32:17 → 17:49:08，16 分 51 秒），末非空 reporter 行 `16:46 +6976: All tests passed!`，`grep -c '^\[E\]'` = 0 → 与第 5 步同为 6976 通过 / 0 失败。随后 `dart run tool/coverage_ratchet.dart` 退出 **0**（17:49:08 → 17:49:10），输出原文单行为 `Running build hooks...Running build hooks...Line coverage: 50827/58422 (87.00%), minimum=81.25%`（前两段 `Running build hooks...` 是 `dart run` 无换行进度前缀，非本工具输出）→ 行覆盖 **87.00%**，高于门槛 81.25% 共 5.75 个百分点，**ratchet PASS**。
- 未为此安装任何软件：`flutter test --coverage` 自产 `coverage/lcov.info`，无需 lcov 等外部工具。`coverage/`（`.gitignore:13`）与 `build/`（`.gitignore:10`）均被忽略，两步跑完 `git status --porcelain` 仍为 0 行。

## 目标 2：§8.2 合并 Gate ⓐ–ⓔ（范围 `origin/main..5d9bbdeaf`）

### ⓐ 中文文案 / 数值常量散写进 Dart

- 口径：`git diff --unified=3 --no-color origin/main..HEAD -- 'lib/*.dart'` 的新增行（`^+`，排除 `+++`），CJK 类 `[\u4e00-\u9fff]`；豁免 `lib/shared/strings.dart`、`lib/**/enum_localizations.dart`、`lib/**/battle_log.dart`（CLAUDE.md:314 正名的集中式合法 sink）、整行注释、`throw`/`ArgumentError`/`StateError` 表达式内字符串。
- 改动 `lib/*.dart` 文件 116 个，新增行 9733 行；含 CJK 的新增行 **295** 行，分类：豁免文件 27 / 整行注释 247 / throw 类 sink 16 / 行尾注释 4 / **剩余疑似 1**。
- 剩余 1 条：`lib/features/debug/application/visual_route.dart:51` → `stageListEscort('stage_list_escort', '第二章护送·隔离档真实选关、键鼠战斗与失败返回验收'),`。判定 **合法**：`VisualRoute` 是 `--dart-define=VISUAL_ROUTE=<id>` 的开发者视觉验收路由标签，非玩家可见文案；同文件在 `origin/main` 上已有 89 行同类中文标签（`git show origin/main:lib/features/debug/application/visual_route.dart | grep -c '[一-龥]'` = 89），属既有集中式 debug 工具模式，非新增散写。严格读 §5.6「presentation / domain 散写」不覆盖 `features/debug/application`，故列为知悉项而非阻断。另 4 条行尾注释（`gauntlet_service.dart:1028`、`:1077`、`:1210`、`:1247`，形如 `if (run == null) return; // 幂等`）同判合法：中文在注释里，不是字符串文案。
- 数值字面量：派单口径 `= \d{3,}`（排除 `const`/注释）命中 **1**；放宽到「新增行任意位置的 3 位以上数字字面量」命中 11 处 / **10 行**，逐条判定：

| file:line | 字面量 | 判定 |
|---|---|---|
| `lib/data/isar_setup.dart:1067` | 30793 | 合法：MDBX 引擎错误码诊断串（`MdbxError (-30793)`），非玩法数值 |
| `lib/features/battle/presentation/phase0a/phase0a_presentation_tokens.dart:24` | 1280 | 合法：具名 `static const double crowdReferenceWidth`，表现层布局基准 token |
| 同上 `:170` | 104 | 合法：具名 `static const double defendedEntityHeight` |
| `lib/features/debug/application/production_battle_frame_profile.dart:112` | 900 | 合法：debug 帧耗采样器采样间隔（`Duration(milliseconds: 900)`） |
| 同上 `:547` | 67108864 | 合法：debug 采样器 64 MiB RSS 容差闸门 |
| `lib/features/debug/application/production_profile_keyboard_driver.dart:87`、`:133`、`:142`、`:148` | 100 / 180 / 130 / 570 | 合法：debug 无界面基准 bot 的按键间隔、索敌距离、攻击距离与活动范围边界（`:148` 同行另有 220，为 2 位数未入口径） |
| `lib/features/expedition/application/expedition_service.dart:1052` | 4096 | **疑似散写（低危）**：`_settleToNow` 默认参数 `int maxBatches = 4096`，技术性防死循环批次上界、非玩法数值；同函数 `maxNodesPerBatch` 已用具名 `defaultMaxNodesPerBatch`，此处未具名。建议后续提为具名 const 或外置配置。本单只登记不修 |

- ⓐ 结论：**0 处玩家可见中文文案散写、0 处玩法数值硬编码**；1 处低危登记（4096）+ 1 处 debug 标签知悉项。

### ⓑ 高频路径 debug 日志

- 口径：新增行扫 `\b(debugPrint|print|log)\s*\(`，排除注释行。命中 **5**，全部为 `debugPrint(`，`print(` / `log(` 命中 0。

| file:line | 所在函数 | 高频路径？ |
|---|---|---|
| `lib/features/debug/application/production_battle_frame_profile.dart:311` | `initState()`（同文件 `:289`） | 否：一次性，且被「证据文件已存在则 `PRODUCTION_BATTLE_PROFILE_REJECTED` 并 return」闸门包住 |
| 同上 `:622` | `_writeEvidence(String reason)`（`:523`） | 否：采样收尾一次性输出 `PRODUCTION_BATTLE_PROFILE_RESULT` |
| 同上 `:629` | 同 `_writeEvidence` 的 `on Object catch` | 否：仅写盘失败才输出 |
| `lib/features/mainline/application/mainline_settlement.dart:424` | `_resolveTechName`（`:412`）catch 内 | 否：调用点 `:339`/`:367` 属 `buildDefeatLossEntries`（`:311`）战败结算路径，非 `build(`/`paint(`/reducer tick |
| `lib/features/seclusion/application/online_presence_controller.dart:169` | `_settlePresenceSafe`（`:161`）catch 内 | 否：被 `IsarSetup.instanceOrNull != null` 包住；触发源为 focus/blur 与 60 秒心跳（`:35 Duration(seconds: 60)`），最坏 1 行/分且仅异常时 |

- ⓑ 结论：**0 处落在 `build(` / `paint(` / reducer tick / `didUpdateWidget` 等高频路径**（`didUpdateWidget` 在 `production_battle_frame_profile.dart:361`，其内无新增日志）。PASS。

### ⓒ 误提交

- `git -c core.quotePath=false diff --name-only origin/main..HEAD`（336 文件）按模式 `\.g\.dart$|\.log$|coverage/|^build/|\.dart_tool/|test/tools/output/|screenshot|capture|\.png$|\.jpg$|\.tmp$|\.bak$|\.orig$|\.DS_Store` 扫 → 命中 **0**。
- 体积：`--diff-filter=A` 得新增文件 **132** 个，逐个 `git cat-file -s HEAD:<f>`，> 1 MiB 的 **0** 个；最大为 `docs/audit/numbers_yaml_unused_keys_review_2026-09-17.md` 685331 B，次大 `test/fixtures/golden/phase0a_reducer/tower_32_vulnerability.json` 464569 B。
- `git ls-files '*.g.dart'` = **0**（`.gitignore:16` 覆盖）。HEAD 全树 > 1 MiB 的仅 `assets/audio/bgm/mainMenu.mp3`（3086568）与 `assets/audio/bgm/seclusion.mp3`（3562415），两者 `origin/main` 已存在且范围内未改（`assets/` 未出现在 336 文件里）。
- `git ls-files` 匹配上述产物模式的共 12 条，全为 `test/tools/output/*.csv|*.md`；逐个 `git cat-file -e origin/main:<f>` 均存在 → **全为 main 既有，范围内 0 新增**（登记为知悉项，非本次引入）。
- 工作区清洁：本单开跑前、目标 1–3 全程、覆盖率与 macOS build 跑完后，`git status --porcelain` 行数均为 0（`build/`、`coverage/` 被 `.gitignore` 覆盖）。40 个 docs/ 改动文件全落在既有约定目录内 —— `docs/audit`(main 195 → tip 209)、`docs/dispatch`(139 → 152)、`docs/dispatch/reports`(19 → 25)、`docs/sessions`(310 → 312)、`docs/superpowers/plans`(555 → 559)、`docs/spec`(137 → 137)，无临时草稿类新目录。
- ⓒ 结论：**范围内 0 误提交**。PASS。

### ⓓ commit message 中文动宾

- `git --no-pager log --format='%h %s' origin/main..HEAD` → **101** 条，逐条机器判定（CJK 类 `[\u4e00-\u9fff]`）。
- 不含任何中文的：**2** 条 —— `5da8ab178 feat(settings): reduce decorative battle effects with full combat parity`、`85b7db79d fix(expedition): settle passive growth on the node timeline`。
- 剥掉 `[READY]`/`[BLOCKED]`/`[WIP]`/`[schema]`/`[GDD]` 前缀后首字非中文的：同样 **2** 条（即上两条）。其余 **99** 条均以中文动词起头（登记/落盘/修复/补齐/收口/合入/更新/交接/记录/整合/迁移/贯通/增加/补记/拆分/收紧/修正/标注/外置/阻止/接入/恢复/让/将/为/给/删除/汇总/固化/评估/清点/补核/核对/分类/建立/对齐/刷新/提交/重锚/补捞/完成/补）。
- 判定：99/101 合规；2 条英文 conventional-commit 前缀属历史 drift（`CLAUDE.md:467` 记「2026-07-13 三批英文前缀 drift 后补入 gate」，此 2 条同类）。按派单口径 **只登记、不建议改写历史**（SHA 已被既有证据引用）。

### ⓔ format

- CI 口径（目标 1 第 3 步）：退出 0，`Formatted 1758 files (0 changed) in 3.71 seconds.`。Gate 口径 `dart format --output=none --set-exit-if-changed .`：退出 0，`Formatted 1860 files (0 changed) in 4.13 seconds.`（17:10:52 → 17:10:57）。
- ⓔ 结论：PASS，零文件需重排。

## 目标 3：与 main 的差异面摘要

`git diff --numstat origin/main..HEAD` 按顶层目录聚合（含中文文件名的 5 个 docs 路径由 `core.quotePath=false` 归并回 `docs/`）：

| 顶层目录 | 文件数 | +行 | −行 |
|---|---|---|---|
| `test/` | 157 | 52694 | 577 |
| `docs/` | 40 | 17151 | 63 |
| `lib/` | 116 | 9733 | 3780 |
| `tools/` | 5 | 1371 | 0 |
| `tool/` | 5 | 1143 | 0 |
| `macos/` | 4 | 257 | 0 |
| `data/` | 3 | 104 | 123 |
| `.github/` | 1 | 66 | 3 |
| `data_schema.md` | 1 | 18 | 0 |
| `PROGRESS.md` | 1 | 17 | 1 |
| `GDD.md` | 1 | 5 | 3 |
| `analysis_options.yaml` | 1 | 5 | 0 |
| `build.yaml` | 1 | 1 | 0 |
| **合计** | **336** | **82565** | **4550** |

与 `git diff --stat` 末行 `336 files changed, 82565 insertions(+), 4550 deletions(-)` 一致。`data/` 三文件为 `data/numbers.yaml`、`data/equipment.yaml`、`data/narratives/stages/stage_02_01_defend_guidance.yaml`；`.github/` 唯一文件为 `workflows/ci.yml`（+66 −3，即分片测试与覆盖率合并 job）；`macos/` 四文件为 `project.pbxproj`、`AppDelegate.swift`、`MacosSfxPool.swift`、`MainFlutterWindow.swift`。

### 触及红线层的文件（`git log --oneline origin/main..HEAD -- <file>`）

| 文件 | commit 数 | commit 列表 |
|---|---|---|
| `data/numbers.yaml` | 9 | `bc6cb8b8b` `ffd6167e0` `a27a7ed04` `49cf33494` `583e54f99` `8d6a00299` `76031a91b` `c93b50512` `8bb82d2c4` |
| `lib/data/numbers_config.dart` | 6 | `bc6cb8b8b` `5335f8300` `76031a91b` `384417960` `4b18c4c67` `8bb82d2c4` |
| `lib/data/validation/**` | 3 | `00ca60825` `5335f8300` `76031a91b` |
| `data_schema.md` | 2 | `ffd6167e0` `8bb82d2c4` |
| `GDD.md` | 1 | `49cf33494` |
| `pubspec.yaml` | 0 | —（依赖未动） |
| `pubspec.lock` | 0 | —（锁文件未动） |

### saveVersion / Isar schema

- **saveVersion 变化**：`_currentSaveVersion` 由 `origin/main` 的 `0.49.0`（`git show origin/main:lib/data/isar_setup.dart` 第 247 行）升到 HEAD 的 `0.50.0`（`lib/data/isar_setup.dart:252`，注释 `0.50.0 Preserve island product identity and persistent ordinary idle fractions.`）。
- 迁移链完整：`:696` `if (_compareVersion(fromVersion, '0.49.0') < 0)` → `SectMemberCountRepair.repairInTxn`；`:700` `if (_compareVersion(fromVersion, '0.50.0') < 0)` → `IsarMissingFieldDefaults.repairPassiveRemaindersInTxn` + `PlayerYieldMigration.migrateIslandStocks` + `PlayerYieldMigration.initializePassiveAnchor`；末尾 `save.saveVersion = _currentSaveVersion`。另有「新档比当前版本新则拒绝」守卫（`:942`、`:1086` `_compareVersion(save.saveVersion, _currentSaveVersion) > 0`）。
- 派单给的 `lib/data/models/` 路径在 HEAD 不存在（`ls: lib/data/models: No such file or directory`），故改用「含 `@collection` 的 lib 文件 ∩ 范围改动文件」判定，命中 3 个：
  - `lib/core/domain/character.dart`（+5 −0）：新增字段 `double passiveExperienceRemainder = 0;` 及同名构造参数。
  - `lib/core/domain/save_data.dart`（+14 −0）：新增 5 字段 `DateTime? passiveLastSettledAt`、`double passiveMojianshiRemainder = 0`、`int? pendingPassiveRecapExperience = 0`、`int? pendingPassiveRecapMojianshi = 0`、`DateTime? pendingPassiveRecapStartedAt`。
  - `lib/features/seclusion/domain/retreat_session.dart`（+1 −2）：仅类文档注释改写（active session 约束表述），**无字段变化**。
- 新增注解行 0：`git diff origin/main..HEAD -- 'lib/*.dart' | grep -cE '^\+.*@(collection|Collection|Name|Index|Id)'` = 0 → 无新增/删除 collection、无新增索引，schema 变化为**纯增字段**（Isar 向后兼容方向），且 `lib/data/isar_setup.dart` 自身 +122 −43 承接迁移。
- 配套改动：`build.yaml` +1 行注册旧档回归夹具 `test/fixtures/legacy_player_yield.dart`；`analysis_options.yaml` +5 行排除独立子包 `tools/phase0minus_probe/**`（该子包 `origin/main` 与 HEAD 均 196 文件、范围内未改，排除理由为根目录裸 analyze 会因缺自身 package_config 报千余条噪声）。

## 结论

**可合并但需知悉（列条目）**

依据：CI 同套 7 步在 tip 上全绿（pub get / build_runner / format / analyze / 全量测试 6976 通过 0 失败 / macOS debug build / 覆盖率 87.00% 高于 ratchet 门槛 81.25%，各步退出码均为 0）；Gate ⓐⓒⓔ 零阻断、ⓑ 零高频日志；`origin/main` 是 tip 祖先且 `merge-tree` 无冲突，合并为纯快进。无阻断项，故不判「不可合并」；但存在下列需用户在拍板前知悉的条目，故不判「可合并（证据齐）」：

1. **存档版本会升版且不可回退**：`saveVersion` `0.49.0` → `0.50.0`，`character` 增 1 字段、`saveData` 增 5 字段。合并后首次启动会把既有存档迁移升版；此后退回 0.49 客户端会触发「存档比当前版本新」拒绝守卫。迁移段与旧档夹具（`legacy_player_yield.dart`）均在位。
2. **2 条英文 commit message**（`5da8ab178`、`85b7db79d`）违 §11 中文动宾口径，属历史 drift；SHA 已被既有证据引用，**只登记、不建议改写历史**。
3. **1 处低危数值字面量**：`lib/features/expedition/application/expedition_service.dart:1052` `int maxBatches = 4096`（技术性批次上界，非玩法数值，同函数其余参数已具名）。建议后续单独提为具名 const 或外置配置。
4. **1 处 debug 中文标签**：`lib/features/debug/application/visual_route.dart:51`（开发者视觉验收路由标签，非玩家文案，同文件 main 上已有 89 行同类）。严格读 §5.6 属灰区，登记备查。
5. **main 既有 12 个 `test/tools/output/` 产物**（csv/md）仍被跟踪，非本次范围引入；是否清出跟踪属另一议题。
6. **CI 与本地口径差异**：CI 跑 4 分片 + 合并 lcov，本地为单次全量 `--coverage`；ratchet 按行级最大命中数聚合，两者对同一测试集合等价。CI 另有两项本地未跑的 macOS 原生测试（`test/native/run_macos_sfx_pool_tests.sh`、`run_macos_window_termination_tests.sh`），本单未执行，其状态**未能判定**（原因：派单未授权、且会另起 Xcode 构建，超出本单只读证据范围）。

合并动作不在本单；本单不 push / merge / rebase / revert，未安装任何软件，未触碰真实存档，未启动游戏 GUI。
