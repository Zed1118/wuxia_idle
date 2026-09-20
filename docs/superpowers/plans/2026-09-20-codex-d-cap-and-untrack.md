# 派单 D：强化上限读表与清出跟踪产物

- 目标：强化服务与对话框共读 realms 表最大 absoluteLevel；生产数值零变更；保留产物磁盘文件并迁移正式验收记录。
- 分支：`codex/cap-and-untrack-20260920`。
- 原始基线：`67dca75670db7c91d64505206c798128543f335b`。
- 提交顺序：S0 `cddf20b4ae4979b9e4544638f1f9fd09cdbeac5b` → S `bcfa2fef26c8ab11e91d5ac18c45199101bb45d5` → R（本恢复点与收据所在包装提交）。
- Gate 基线：S0；收据 head_sha：S；R 仅含收据与本恢复点。
- 收据：`docs/dispatch/reports/2026-09-20_codex_D_receipt.yaml`。

## 验收标准与生产接线

- S0 恰为 11 个删除、1 个原样改名、4 份文档路径替换；11 个产物只解除跟踪，磁盘文件与初始 SHA-256 一致。
- 正式验收记录已原样迁至 `docs/audit/phase2_g2_stage_01_03_acceptance_record.md`，四份引用已更新；输出目录跟踪为空，旧路径引用零命中。
- `RealmUtils.maxAbsoluteLevel` 对 realms 全表求最大值，空表由 reduce 抛出 StateError，无默认值；未改其他公式。
- `EnhancementService._enhanceLevelCap` 与 `EnhanceDialog._capHardLimit` 均接入该 getter；UI 结构和文案未改。
- `numbers.yaml` 与原始基线逐行比较仅第 727 行头注变化，解析后的全部 key 和数值相同。
- 红线影响：不改数值硬红线、三系锁死、在线离线规则、概率或奖励；去除强化上限代码硬编码。

## 已跑验证

- TDD：先新增测试得到 getter 缺失编译红；添加 getter 后，真实装载的 48 上限 fixture 令旧服务返回 success 而非 capped，实测红 1 条；接通服务后绿 2 条。
- fixture：装载器要求 49 行，因此仅在内存 YAML 中将武圣登峰 absolute_level 和 release_cap 同降至 48，保留全部行，其余资产走 loadTestAsset；不修改生产 YAML 数值。
- 六个定向测试逐文件执行 `flutter test --no-pub <文件>`，各有独立 All tests passed!：
  - `test/combat/derived_stats_test.dart`：42 条。
  - `test/features/equipment/application/enhancement_service_test.dart`：29 条，原 display Lv490 断言通过。
  - `test/features/equipment/application/enhancement_cap_realms_test.dart`：2 条。
  - `test/features/equipment/presentation/enhance_dialog_test.dart`：6 条。
  - `test/features/inventory/presentation/equipment_detail_screen_test.dart`：21 条。
  - `test/data/truth_source_guard_test.dart`：9 条。
- S 提交后两向破坏证红：服务改回硬编码 49，红 1 条；getter 改为 return 49，红 2 条；每向均完整还原后复跑绿 2 条，lib/test/data 与 S 完全一致。
- `flutter analyze --no-pub lib test tool`：退出码 0，`No issues found! (ran in 18.1s)`。
- `dart format --output=none --set-exit-if-changed lib test docs`：退出码 0，`Formatted 1764 files (0 changed) in 3.57 seconds.`。
- 前台 `flutter test --no-pub`：退出码 0，`07:59 +7030: All tests passed!`；原始日志按 `grep -c '^\[E\]'` 计数为 0。
- `python3 -c "import yaml;yaml.safe_load(open('data/numbers.yaml'))"` 通过；生产 YAML 解析内容与原始基线一致。
- 强化服务和对话框的可执行代码中 49 零命中；剩余两处为当前强化范围的既有说明和表最大值说明。
- S0 提交边界、S 的 6 个白名单文件和生产接线均经独立只读复核；`git diff --check` 通过。
- 原始日志目录：`/var/folders/qf/5z9_0qjx23d15ny1lv62rhqh0000gp/T/codex-d-cap-20260920-4gj5xpv1`。

## 当前恢复点

- 状态：READY，派单实现与本地自动验证完成。
- 最后完成：S0 清理、S 读表实装、先红后绿、提交后两向破坏证红、六个定向文件、分析、格式与前台全量全部通过；收据由保存的原始输出生成。
- 下一步：协调者以 S0..S 运行独立 Gate，并以 R 作 wrap-tip；按派单独立核 S0、抽查 mutation。执行端不继续修改。
- 已跑验证：见上节及机器收据。
- 阻塞项：无。
- 残留边界：未运行协调者独立 Gate，未合并、推送或发布；本 READY 不代替集成、Windows 或真人验收。
- 安全边界：未修改白名单外跟踪文件，未安装软件，未访问真实存档，未启动游戏 GUI，未操作 main 或其他分支。

## Gate 打回 → 6 个黄金文件恢复跟踪

- 2026-09-20 09:41 独立 Gate FAIL：干净临时 checkout 全量 `08:39 +7027 -3`，三条诊断测试因缺少 `test/tools/output/` 下已提交文件而报 `PathNotFoundException`。
- 根因：三对 CSV/MD 是测试读取的黄金文件，原 S0 将其误当产物解除跟踪；本地磁盘仍保留文件，导致此前 `07:59 +7030` 不能证明干净 checkout 可通过。原子集 format 的 `1764 files` 也不符合 Gate 整仓命令口径。前文记录保留为历史，本节覆盖前文当前状态与交付口径。
- 按 `67dca7567` 原样恢复三对黄金文件：`phase0a_idle_island_parity_diagnostic.{csv,md}`、`phase0a_full_content_balance_diagnostic.{csv,md}`、`phase0a_ch1_real_skill_profile_2026-08-20.{csv,md}`。已核 index、磁盘与基线逐字节一致，`git ls-files test/tools/output` 恰好六项。
- 其余五个产物继续不跟踪并保留磁盘内容；G2 正式验收记录仍在 `docs/audit/phase2_g2_stage_01_03_acceptance_record.md`，内容与原始基线相同。本续单不改任何 `_test.dart`、`.gitignore` 或生产代码/数值。
- 提交顺序：原 S0 → S → R `b81e626131246256841c9777faec200ff68aa5aa` → S'（仅六个黄金文件与本恢复点）→ R'（仅重出的收据，`R'^ == S'`）。收据 `base_sha` 仍为 S0，`head_sha` 为 S'，`changed_files` 完整取 `git diff --name-only S0..S'`（包含原 R 已加入的恢复点与旧收据路径）；原两组 `break_red` 保留。

### 已跑验证（D-续）

- `flutter test --no-pub test/tools/phase0a_idle_island_parity_diagnostic_test.dart`：退出码 0，`00:00 +1: All tests passed!`。
- `flutter test --no-pub test/tools/phase0a_full_content_balance_diagnostic_test.dart`：退出码 0，`00:02 +1: All tests passed!`。
- `flutter test --no-pub test/tools/phase0a_ch1_real_skill_profile_diagnostic_test.dart`：退出码 0，`00:01 +1: All tests passed!`。
- 前台 `flutter test --no-pub 2>&1 | tee /Users/a10506/Codex/2026-09-20/full_test_2.log`（启用 `pipefail`）：退出码 0，`08:07 +7030: All tests passed!`；同份原始日志的 `grep -c '^\[E\]'` 为 0，带时间戳的 reporter 失败行也为 0。
- `flutter analyze --no-pub lib test tool`：退出码 0，`No issues found! (ran in 3.8s)`。
- `NO_COLOR=1 dart format --output=none --set-exit-if-changed .`：退出码 0，`Formatted 1866 files (0 changed) in 3.83 seconds.`；使用整仓命令，与 Gate 的文件数口径一致。
- 全量后再次核对六个黄金文件：index、磁盘与 `67dca7567` 逐字节一致；本续单实质 diff 仅六个黄金文件与本恢复点；`git diff --check` 和 `git diff --cached --check` 均通过。
- 本次原始验证日志目录：`/var/folders/qf/5z9_0qjx23d15ny1lv62rhqh0000gp/T/codex-d-followup-20260920-1_qkfw_8`。

### 当前恢复点（D-续）

- 状态：READY，本续单修复及本地自动验证完成，等待协调者独立 Gate 复核。
- 最后完成：六个黄金文件原样恢复跟踪、三条逐文件验证、前台全量 7030 条、analyze 零问题、整仓 format 1866 files/0 changed；Gate 失败根因与修正后的收据边界已登记。
- 下一步：协调者按 S0..S' 重跑独立 Gate，以仅含收据的 R' 作 wrap-tip；执行端交付后不继续修改。
- 已跑验证：见本节；全量日志指定为 `/Users/a10506/Codex/2026-09-20/full_test_2.log`。
- 阻塞项：无。
- 残留边界：独立 Gate 待协调者重跑；不合并、不推送、不启动 GUI、不访问真实存档，不以本地验证替代独立 Gate 或真人/Windows 验收。
