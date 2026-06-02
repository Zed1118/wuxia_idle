# P0 缺图门禁 — 设计 spec（2026-06-02）

> 范围：1.0 出版美术 pass 执行 tracker P0 工程地基（`docs/PUBLISHING_ART_PASS_1_0.md` §20.4）。纯代码，不卡美术。
> 决议来源：brainstorming 2026-06-02，用户拍 **A+B** + 三点细节（单一覆写报告 / allowlist 双轨 / badge 叠加不替换）。

## 1. 背景与目标

外部 UI 审查 + Phase 0 亲验坐实大量资产引用缺图（敌人 107/129、装备 detail 44/160），且现有 errorBuilder 静默隐藏 → QA 看不出缺。本工具三目标：
- 产出**权威缺图清单**（喂 Phase D MJ prompt 输入单 + 美术线进度看板）。
- **防回归**：新增坏引用要 fail，已知 backlog 不堵线。
- **debug 可见**：run app 时缺图一眼可见，release 仍优雅兜底。

> 注：107/44 是 Phase 0 亲验量级，**权威数以审计工具实跑为准**，spec 不写死（防 doc drift）。

## 2. 范围

- **A** build-time 审计（扫引用 vs 存在 → md 报告）
- **A′** allowlist + guard test（防回归 + 强制美术补齐后清账）
- **B** kDebugMode 缺图角标（badge 叠加不替换）

**非目标（YAGNI）**：游戏内 debug QA 面板（C 否决，.md 报告足够）；硬 fail CI gate（会堵 107+44 backlog）；改 release fallback 行为。

## 3. A — 资产审计

### 3.1 引用枚举源

走现有生产 def loader（精确 loader 入口实装时 grep 确认），收集 路径 + 类别 + 引用源 id：

| 类别 | 源数据 | 字段 |
|---|---|---|
| equipment | equipment.yaml | iconPath（必填）/ detailPath（可空）|
| enemy | stages.yaml + towers.yaml | 敌人 def iconPath（`stage_def.dart:205`）·（encounters.yaml 经亲验不含敌人 def）|
| portrait | master / recruit_candidate / sect_candidate def | portraitPath（可空）|
| scene | stages.yaml + tower_floor | sceneBackgroundPath（可空）|
| chapterCover | 章数枚举 | `chapterCoverPath(i)` |
| narrative | stages 枚举 | `stageNarrativePath(id)` |

可空字段为 null → **不算引用**（不缺）；非 null 才纳入检查。

### 3.2 存在性 & 产出

- `File(path).existsSync()`，test cwd = 项目根。
- 写 `test/tools/output/asset_audit.md`（**单一覆写文件**，不堆 dated）：分类别汇总表（引用 N / 存在 M / 缺 K）+ 缺图清单按类别分组、**附引用源 id**（写 MJ prompt 时知道每个缺的敌人是谁）。
- loader 抛错 → 审计 fail（顺带暴露 yaml 问题）。

## 4. A′ — allowlist + guard

- `test/fixtures/known_missing_assets.txt`：当前已知缺图路径排序清单（**= 权威缺图清单 / MJ 工作队列**）。初始用审计实跑结果填充。
- guard 两条断言：
  1. `live 缺图 ⊄ allowlist`（有引用缺图且不在 allowlist）→ **FAIL**（新增坏引用 = 回归）。
  2. allowlist 条目**已存在磁盘** → **FAIL** 提示删除（补齐即清账，allowlist → 空 = 门全绿 = 美术完工）。
- 初始 allowlist 含全部当前缺图 → **现在就绿**，不堵其他工作。

## 5. B — kDebugMode 缺图角标

- `lib/shared/widgets/asset_fallback.dart`：`wuxiaAssetErrorBuilder(fallback)` 工厂。release：只渲染 fallback；kDebugMode：fallback 上叠 `Positioned` 小角标「缺图」。
- 接入点：`CharacterAvatar` / `PortraitFrame` / `equipment_detail` / 场景背景 errorBuilder 改走工厂。
- **叠加不替换**：原 fallback（首字头像 / 纯色底）照常渲染 → 保现有 widget 测（测试在 debug 跑仍找得到首字）+ release 干净。
- **头号风险**：非 Stack 的 fallback（如装备详情纯色 Container）包一层 Stack 加角标可能动 widget 树、打破精确 finder 的测试 → TDD 逐站点跑 `flutter test` 锚（memory `feedback_image_asset_error_builder`）。

## 6. 文件清单

- 新增 `test/tools/asset_audit.dart`（纯扫描逻辑，可 import）
- 新增 `test/tools/asset_audit_test.dart`（test：生成报告 + 2 guard）
- 新增 `test/fixtures/known_missing_assets.txt`
- 新增 `lib/shared/widgets/asset_fallback.dart` + 其 widget 测
- 改：4 接入点 errorBuilder 走工厂
- 产出 `test/tools/output/asset_audit.md`

## 7. 验收（DoD）

- `flutter test` + `flutter analyze` 全绿。
- `asset_audit.md` 生成，分类别缺图数与 Phase 0 亲验量级一致。
- allowlist 初始化后 guard 绿；故意引用一个不存在路径 → guard 1 fail（验防回归）；删 allowlist 一条已补齐项 → guard 2 fail（验清账）。
- debug run 缺图见角标；release build 无角标；现有 widget 测不破。

## 8. 后续衔接

- 审计产出的敌人缺图清单 → 直接喂 Phase D 第一批 MJ prompt。
- 实装走 `feat/` 分支（当前 main，开工先 branch）。
