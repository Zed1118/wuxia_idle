# P2 批三 B2 百科可达性计划

## 目标与判定

- 目标：判定 `BaikeScreen` 典故页的 `GameRepository` 未加载分支在真实启动流程是否可达，并按冻结派单二选一落地。
- 分支：`codex/p2-b3-f3-baike-reachability-20260827`；基线：B1 `[READY]` tip `686379a33635616161d38a91eadd12c0ec60e3fd`。
- 只改 `test/`、本计划与被既有 `build/` ignore 覆盖的外置 receipt；`lib/` 零最终 diff，不改加载语义、单例注入、UI 文案、数值、schema、存档语义。
- 生产链判定：`WuxiaApp` 首屏为 `SplashScreen`；其 `_bootstrap` 在生产分支 `await GameRepository.loadAllDefs()` 完成后才置 `_loaded` 并导航到 `SaveSelectScreen`。两个百科入口均在选档后的主界面下游。因此玩家沿真实启动链到达 `BaikeScreen` 时 `GameRepository.isLoaded` 必为 true，“Repository 未加载显占位”不可达。
- 二选一结论：走 B（不可达）。删除原来只断言 `GameRepository.isLoaded == true`、却把测试名声称为“未加载显占位”的错误 case；新增真实 `SplashScreen` 生产加载到 `BaikeScreen(initialTab: 1)` 的 widget 合同，断言目的页构建时已 loaded、典故空占位不上屏且真实列表渲染。

## 固定八步验收

1. 实现测试与本计划并 commit（中文动宾）。
2. commit 后按序两向破坏证红并精确反向补丁恢复：
   - `remove_implementation`：临时删除启动合同里的真实 definitions 加载调用，让导航在 repository 未加载时继续；目的页 loaded 断言必须红。
   - `force_degenerate_value`：临时把目的页 builder 退化为 `BaikeScreen(initialTab: 0)`；`baikeLoreEmpty`/典故列表合同必须红。
3. 逐文件 targeted：原 `baike_screen_test.dart` 与新 `baike_startup_reachability_test.dart` 各自出现 `All tests passed!`。
4. `flutter analyze --no-pub lib test`。
5. `dart format --output=none --set-exit-if-changed .`。
6. 独占 `/Users/a10506/.claude/locks/wuxia_full_test.lock` 跑一次 `flutter test --no-pub`，读取 reporter 末行和 `[E]` 计数并精确删除锁。
7. `git diff --check 686379a33635616161d38a91eadd12c0ec60e3fd..HEAD` 与固定 patch SHA-256。
8. 让 plan 证据 commit 后的空 `[READY]` commit 成为最终 tip；生成不提交的 `build/phase2_wiring_receipts/B2/receipt.yaml`，其 head/patch 对最终 tip；S5 由 Claude 独立复核。

## test_deletions 明示例外表

以下是删除错误声称所必需的原始测试行；不为 Gate 伪装纯追加。最终以 `git diff --unified=0` 逐条复核。

| # | 被删原行 | 删除原因 |
|---:|---|---|
| 1 | 空白分隔行 | 删除错误 case 后不保留多余空行。 |
| 2 | `testWidgets('典故 tab Repository 未加载显占位', (tester) async {` | 测试名声称未加载，测试体却未制造或观察该状态。 |
| 3 | `// 临时清掉 repo 单例 — 但 setUpAll 已加载,这里跳过实现(占位 case 留存)。` | 明示“跳过实现”，属于假绿说明。 |
| 4 | `// 实际生产路径 GameRepository.isLoaded 必 true(main.dart 启动 loadAllDefs),` | 事实应由真实启动合同验证，不应只写在注释。 |
| 5 | `// 测试 fixture setUpAll 一致。` | fixture 已加载只能证明 fixture，不证明启动可达性。 |
| 6 | ``// 见 `_LoreTab` source:`if (!GameRepository.isLoaded) return 占位`。`` | 读取/描述源码分支不证明玩家启动路径可达。 |
| 7 | `expect(GameRepository.isLoaded, isTrue);` | 与“未加载显占位”的测试名相反，不能构成该声称的证据。 |
| 8 | `});` | 删除错误 testWidgets 外壳收尾。 |

## 收工记录

1. 实现 commit：待填。
2. 两向破坏证红：待填。
3. targeted：待填。
4. analyze：待填。
5. format：待填。
6. 带锁全量：待填。
7. diff/patch：待填。
8. 外置 receipt + `[READY]` tip：待填。

## 当前恢复点

- 状态：WIP；可达性只读判定完成，选择不可达方案 B，测试与计划已落地但未提交。
- 下一步：先运行开发期 targeted，修正测试后提交，再按八步完成 mutation 与正式门禁。
- 阻塞项：无；无需改 `lib/` 或注入单例。
