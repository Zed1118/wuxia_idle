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
