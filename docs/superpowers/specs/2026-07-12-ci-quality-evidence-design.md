# CI 质量与 Windows 发布证据设计

## 背景与实测

最终优化方案建议将长平衡诊断移出 PR，并建立覆盖率渐进 ratchet 与当前 Windows
release 证据。复核后发现：被点名的 10 个 `diagnostic/stress/simulator` 文件单文件
均只需 1–3 秒，而且多数包含机制、胜率或数值硬断言。当前 `main` 的完整并发测试
实测 237525 ms 全绿；粗暴排除这些文件最多节省约 20 秒，却会弱化关键门禁。

因此本批不按文件名给测试贴 `slow` 标签，也不减少 PR 覆盖。

## 方案比较

### 方案 A：排除全部 diagnostic/stress（不采用）

- 优点：配置简单。
- 缺点：收益小；会漏掉脆弱窗口、Boss 软门槛、心魔机制等硬闸。

### 方案 B：CI 分片（暂不采用）

- 优点：双 runner 可降低墙钟时间。
- 缺点：Actions 用量翻倍，coverage 合并与 Isar native setup 更复杂；当前尚无足够证据
  表明 4 分钟基线值得增加该维护成本。

### 方案 C：保留全量 + 覆盖率 ratchet + 独立 Windows 证据（采用）

- PR 继续运行现有全量测试与 coverage。
- coverage 后运行仓库内 Dart 工具，按已覆盖/可执行行计算比例，与版本化基线比较。
- Windows release 使用独立 workflow，仅手动或每周定时触发并上传未签名产物。
- 不部署、不签名、不提交构建产物。

## 覆盖率 Ratchet

### 文件

- `tool/coverage_ratchet.dart`：解析 `coverage/lcov.info`、排除生成文件、读取基线并
  以明确退出码报告结果。
- `.github/coverage-ratchet.json`：记录 `lineCoverageMinimum`、采样日期和说明。
- `test/tools/coverage_ratchet_test.dart`：覆盖正常统计、重复行合并、生成文件排除、
  阈值通过与失败。
- `.github/workflows/ci.yml`：coverage 生成后执行 ratchet，再上传原始 lcov artifact。

### 统计规则

- 仅统计 `SF:` 记录中的 `DA:<line>,<hits>`。
- 同一源文件同一行重复出现时取最高 hits，避免重复计数。
- 排除 `*.g.dart`、`*.freezed.dart` 和 `*.mocks.dart`；业务手写 Dart 全部保留。
- 基线从本分支完整 `flutter test --coverage --no-pub` 新鲜结果测得，向下保留
  0.05 个百分点作为工具链/合并舍入容差；后续只能显式提高，不自动降低。
- lcov 缺失、无可统计行或低于基线均 fail-fast。

## Windows Release 证据

新增 `.github/workflows/windows-release.yml`：

- 触发：`workflow_dispatch` 与每周一次 `schedule`；不在每个 PR 自动运行。
- 环境：`windows-latest`、Flutter 3.41.5，与主 CI 对齐。
- 步骤：checkout → pub get → build_runner → analyze →
  `flutter build windows --release --no-pub` → 上传 Release 目录 artifact。
- artifact 保留 14 天，名称包含 commit SHA。
- 产物明确标为 unsigned；本 workflow 不处理 MSIX、证书、发布或生产配置。

## 测试与验收

1. TDD RED：覆盖率 parser/threshold 测试先引用不存在的工具；workflow contract 测试
   先要求不存在的 Windows workflow 和 ratchet step。
2. GREEN：实现最小 parser、基线文件和 workflows。
3. 运行工具单测、workflow contract、`flutter analyze --no-pub`。
4. 完整运行 `flutter test --coverage --no-pub`，用新工具验证真实基线。
5. 用 Ruby/Psych 解析两个 YAML，确认语法有效；本机不声称 Windows build 已执行。

## 红线与残留风险

- 不修改 GDD、CLAUDE、numbers、schema、依赖版本或游戏行为。
- 不减少现有 PR 测试覆盖。
- GitHub-hosted Windows job 是否成功仍需 workflow 实际触发确认；Mac 本地不能替代
  Windows runner、升级安装、签名、音频和长挂机实机验证。
