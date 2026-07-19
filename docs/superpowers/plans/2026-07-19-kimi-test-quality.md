# 测试质量目标序列：flaky 根治 + coverage 补强 + 注释回中文

> 派单日期：2026-07-19。分支 `kimi/test-quality-20260719`（基点 main@2f74e192），
> worktree `.worktrees/test-quality-20260719`。执行协议：CLAUDE.md §8.0/§8.2/§8.3。

## 目标

1. **根治两个 main 既有隔离型 flaky（核心）**
   - `test/features/equipment/presentation/equipment_detail_screen_test.dart`
   - `test/data/drop_table_reference_redline_test.dart`
   - 先复现取 RED 证据（20 分钟为限，不复现改代码审读并写明推断依据）；
     根治隔离性根因（禁 retry/skip/-j1/加长 sleep 糊弄；先例 `98ea6873`/`34077732` 轮询根治）；
     证明：全量 `flutter test --no-pub` 连续 2 次全绿 + 两文件单跑绿。
2. **coverage 补强 2-3 个低覆盖生产文件**：实测 lcov 挑文件（排除 `lib/features/debug/**`、
   `lib/features/battle/**`、纯 def/生成文件），写行为测试，报改前→改后覆盖率。
3. **`lib/features/expedition/application/expedition_combat_runner.dart` 注释回中文**：
   类级/方法级英文 doc comment 全部翻回中文，零逻辑改动。

## 禁区

- `lib/features/battle/**`、`test/features/battle/**`（在途热区）
- `data/` 全目录、`pubspec.yaml`、`GDD.md`、`CLAUDE.md`、`PROGRESS.md`、saveVersion、
  结算公式层、`lib/shared/strings.dart`
- 除目标 3 注释外不改 lib/ 生产代码；flaky 根治若确需动生产代码 → 先写方案 + `[BLOCKED]` 冻结
- 主 checkout 只读

## 验收（§8.2 四证据）

1. 根因一句话+修法（每 flaky）；coverage 文件选择依据（实测数字）
2. targeted 命令+通过数；目标 1 另附全量两连绿（通过数+EXIT）
3. 红线影响声明（预期零触及）
4. 残留风险列清
- `flutter analyze --no-pub` 0 issue；改动文件 `dart format` 干净
- 完成：树净 + tip 前缀 `[READY] 测试质量批交付`

## 任务切片

- [ ] 切片 1：计划文件 + flaky 现场调查（记录在案失败模式取证）
- [ ] 切片 2：flaky RED 复现（并发组合，≤20min；不复现则审读取证）
- [ ] 切片 3：flaky 根治实施 + targeted 绿
- [ ] 切片 4：coverage 实测 + 2-3 文件行为测试
- [ ] 切片 5：expedition_combat_runner 注释回中文
- [ ] 切片 6：全量两连绿 + 四证据 + [READY] 冻结

## 现场调查记录（切片 1）

### 在案失败模式

- `drop_table_reference_redline`：CLAUDE v1.29 点名隔离型 flaky；session 记
  「全量并发跑偶发 4045/1+超时，单跑 4/4 绿」（2026-07-16）、「`-j1` 全量下偶 `-1`，
  单跑/复跑 PASS」（2026-07-01）。失败形态=**超时**，`-j1` 下也出现过 → 非跨文件并发态污染。
- `equipment_detail_screen_test`（equipment/presentation）：kimi A 单 plan 记
  `flutter test --no-pub test/features/equipment/` 首跑 198/199，1 例
  「锁定装备(isLocked=true)」用例失败，单文件复跑 5/5 过、目录重跑 202/202 过（2026-07-19）。
- 测试本体速览：
  - drop_table：4 个纯同步静态调用用例（`GameRepository.enforceDropTableReferences`），
    零 I/O 零计时器。文件内不存在可超时的代码路径 → 超时只能来自 harness 装载阶段
    （编译/进程拉起被机器负载拖过默认 30s 测试超时）或 CI 低配 runner 事件循环饥饿。
  - equipment_detail（equipment/presentation）：setUpAll 经 `loadTestGameRepository()`
    真盘加载 yaml；被测屏 `build` 期直读全局单例 `GameRepository.instance.numbers.disposal`
    （equipment_detail_screen.dart:102/:146/:317/:832）。

## RED 复现记录（切片 2）

1. **目录并发循环**（`test/features/equipment/` + 两同名 detail 测试，8 轮；
   `test/data/` 6 轮）：第 1 轮即红——**fresh worktree 首跑**（`libisar.dylib` 尚未
   生成）时 `equipment_disposal_service_test` / `equipment_inventory_invalidation_test`
   两 Isar 套件 setUpAll [E]：`dlopen(libisar.dylib): x86_64/arm64 slice extends
   beyond end of file`。dylib 下载完成后 2-8 轮全绿、data 6 轮全绿；
   **两个点名文件在风暴中全程绿**。
2. **风暴重建**（删 dylib + 同组合再跑）：同两套件同错复发，点名文件仍绿。
3. **全量 A**（删 dylib，`flutter test --no-pub`）：4440 pass / 3 fail——
   ① `attribute_role_sensitivity_diagnostic_test` setUpAll [E]（dylib 竞逐，00:03）；
   ② `expedition_combat_runner_test` 守卫 [E]（目标 3 中译撞旧守卫，已口径对齐）；
   ③ `apply_victory_resolution_test` 胜利全量 [E]（04:13，equipmentObtained 期望 1
   实际 2——**新观察**，非点名文件，见「发现项」）。

## 根因与修法（切片 3）

**根因（一句话）**：`Isar.initializeIsarCore(download: true)` 把原生库**非原子流写**
进所有套件进程共享的包根 `libisar.dylib`，并发首跑时后进进程 dlopen 到半截文件；
且包内 exists 检查不重下，截断文件留毒后续每一次跑测（项目史上「fresh worktree
dylib 截断需从主仓手动 cp」（5/28、6/01 等多篇 session 记录 + dispatch 模板内置
`cp 主仓/libisar.dylib`）正是同一根因的长期 workaround）。另有 11 个测试文件从不
显式初始化 IsarCore，靠别套件下载残留的 dylib 隐式过活——共享文件耦合的最深形态。
**两个点名文件本身无隔离缺陷**：纯静态/假异步路径，风暴复跑全程绿；其历史偶红
（detail 锁定用例 1 次无错误文本留存 / drop_table 全量「超时」）与本类根因同环境
（fresh worktree / 全量并发首跑窗口），符合本项目已记录的 flaky 归因漂移模式
（2026-05-28 leaderboardSync 错诊断先例），判定为同风暴窗口受害者/误归因。

**修法（零生产代码改动）**：
- `test/support/isar_test_support.dart`：弃用 `download: true`，改从
  `isar_community_flutter_libs` 包（pubspec 既有依赖）解析随版本发布的本地二进制
  （`libraries:` 显式路径）——无下载、无共享可写文件、无网络依赖，CI 新环境亦稳。
  解析器体例沿用 `visual_route_test.dart` 既有私有实现（已上移共享，原私有副本删除）。
- 11 个隐式依赖残留 dylib 的测试文件补显式 `setUpAll(() => initializeTestIsarCore())`
  （expedition×5 / boss_gauntlet×3 / activity×1 / sweep×1 / data×1）。
- `apply_victory_resolution_test.dart:364` 断言加诊断 reason（命中事件全量打印），
  不改断言语义——若「2 条 equipmentObtained」再现可直读第二条来源。

**修后冷态验证**：删 dylib 后跑 11 修文件所在目录 + 先前失败套件（expedition/
boss_gauntlet/activity/sweep/data/journey_migration + attribute_role_sensitivity）
→ 252/252 全绿，且包根**不再生成** libisar.dylib。

## 当前恢复点

- **状态**：切片 1-3 完成（计划/复现/根治），目标 3 完成；进入切片 4（coverage）。
- **最后完成**：Isar 初始化换 bundled 二进制 + 11 文件显式初始化 + avr 诊断加强；
  冷态 targeted 252/252 绿。
- **下一步**：全量 B（--coverage，兼产 lcov 供目标 2 选文件）→ 全量 C（第二连绿）
  → 目标 2 补测。
- **已跑验证**：目录并发 8+6 轮（RED 取证）；风暴重建 2 轮（RED）；全量 A（RED，
  4440/3）；修后冷态 targeted 252/252 绿；`expedition_combat_runner_test` 守卫口径
  对齐后随 expedition 目录复跑绿。
- **阻塞项**：无。

## 发现项（疑似生产 bug，只记录不修）

1. **apply_victory_resolution 胜利全量偶见 2 条 equipmentObtained**（全量 A 一次，
   单文件×10 + 目录×6 循环未复现）：静态排查唯一写点 `stage_entry_flow.dart:910`
   （每掉落一条一次），双写机制未明；已在断言加诊断 reason，若全量 B/C 再现可凭
   事件内容定位。非本单点名范围，暂列观察。
2. `isar_community` 与 `isar_community_flutter_libs` 版本须同步升级（lock 现同
   3.3.2）：bundled 解析遇版本不符会**响亮报错**（非静默 flaky），升级时两包同升即可。
