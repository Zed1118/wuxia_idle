# Ch6 后纯挂机 → Ch7 解锁门槛墙钟时长量化（只读分析单）

> 日期：2026-07-19 ｜ 分支：`kimi/progression-simulation` ｜ worktree：`.worktrees/progression-simulation`
> 性质：**只读分析工具 + 报告**。零生产改动（不动 `lib/`、`data/*.yaml`、既有测试、PROGRESS、pubspec）。
> 背景：2026-07-19 外部审查提出「Ch6 后可能存在较长无主线挂机段」。本单量化该段墙钟时长，供用户拍板节奏（降门槛 / 补中段内容 / 接受长挂机）。

## 目标

量化「Ch1-6+塔+全内容吃满」实测终态（Lv91）纯挂机到 Ch7 首关门槛（`stage_07_01 requiredRealm: erLiu` = 二流 = 绝对境界层 15 = 显示级 Lv141）所需墙钟时长，至少三场景，附每层递进曲线与逐条假设来源。

## 验收标准（§8.2 四证据转写）

1. 生产接线证据：模拟只读 production yaml 配置 + 调生产纯函数（SeclusionService / OfflinePassiveService / CharacterAdvancementService / ItemUseService 同公式 / 联合经济模型），无 fixture 重造。
2. targeted test：新工具测试全绿 + `flutter analyze` 0 issue。
3. 红线影响说明：逐条声明（本单应全否）。
4. 残留风险：列清。

## 任务切片

- [x] 建 worktree + 预热（pub get 镜像 / build_runner / 冒烟 progression_release_budget_test 4 绿；pubspec.lock 零漂移——build_runner 首跑曾因未带 `PUB_HOSTED_URL` 改写 lock URL 为 pub.dev，已 `git checkout` 恢复，后续所有 flutter/dart 命令均带镜像变量）
- [x] 读配置真相：numbers.yaml（realms / retreat / passive_idle / taohua_island / inner_demon / release_cap）、items.yaml、shop.yaml、expeditions.yaml、stages.yaml
- [x] 新模拟工具 `test/tools/progression_idle_horizon_simulation_test.dart`（4 测试全绿）
- [x] 报告写进本 plan（不落 CSV——test/tools/output 误提交历史坑）

## 一、起点与缺口（锚点对账）

起点 = 与 `test/features/cultivation/application/progression_release_budget_test.dart:52` 同口径复现的参考路线终态：

| 项 | 值 | 来源 |
|---|---|---|
| 终态显示级 | Lv91 | budget 测试锚点（本工具锚点测同步断言） |
| 终态境界 | 三流·熟练（绝对层 10），层内余量 15 EXP | 复现路径实测 |
| 缺口 Lv91→Lv141 | **8285 EXP** | realms 表 abs10→14 阈值 950+1250+1600+2000+2500 = 8300 − 余量 15（data/numbers.yaml:298-316） |
| 里程碑缺口 | Lv100 = 840 EXP；Lv120 = 3625 EXP | RealmProgressDisplay 段公式（lib/features/cultivation/domain/realm_progress_display.dart:46,56） |
| 发布上限 | abs17 ≥ 目标 abs15，不拦 | data/numbers.yaml:205-206 |
| 心魔锁 | 节点最高 sanLiu·ruMen(abs9)，起点 abs10 已全过 | data/numbers.yaml:1675-1682 |

## 二、三场景天数估算（任务要求口径）

| 场景 | 有效速率（三流段） | Lv100 | Lv120 | **Lv141（终点）** |
|---|---|---|---|---|
| A 最优闭关地图连续挂（藏经阁 72h 循环收功） | 3.0×1.3 = 3.9 EXP/h（72h cap 内） | 216h ≈ 9.0 天 | 932h ≈ 38.8 天 | **2131h ≈ 88.8 天** |
| B 普通离线挂（passive_idle 每日结算） | 3.0×1.6 = 4.8 EXP/h（无 cap） | 176h ≈ 7.3 天 | 757h ≈ 31.5 天 | **1730h ≈ 72.1 天** |
| C 混合典型（闭关常开、每 7 天收一次：72h 全速率 + 96h 溢出 passive 速率） | 加权 ≈ 4.40 EXP/h | 194h ≈ 8.1 天 | 825h ≈ 34.4 天 | **1886h ≈ 78.6 天** |

逐层递进（abs11→abs15 累计小时，A / B / C）：

| 到达层 | A | B | C |
|---|---|---|---|
| abs11（三流·精通） | 241 | 196 | 218 |
| abs12（三流·圆熟） | 562 | 456 | 497 |
| abs13（三流·化境） | 974 | 790 | 862 |
| abs14（三流·登峰） | 1488 | 1208 | 1316 |
| abs15（二流·启蒙 = Lv141） | 2131 | 1730 | 1886 |

**结论（任务要求口径下）：纯闭关/离线挂机到 Ch7 门槛 ≈ 72–89 天墙钟。** 且呈单调后段变缓——后三层（abs13→15，阈值 2000+2500）占总时长约 54%。

## 三、加速通道场景（排查中发现的既有挂机经验源，同样量化）

| 场景 | 口径 | Lv141 总时长 |
|---|---|---|
| E1 桃花岛丹房酿凝神丹（丹房 L1 + 药草园 L1 自供给，丹即产即用） | 1 丹/h × 0.1 层/丹（与 ETL 无关）→ 10h/层 | **50h ≈ 2.1 天** |
| E3 丹房 L3（三流升级上限） | 3 丹/h | **17h ≈ 0.7 天** |
| D 专挂百草岭远征（联合经济探针中档口径：一战到底方针·代表深度 20·24h 满挂） | 34.97 EXP/h（模拟实测） | **237h ≈ 9.9 天** |
| F 闭关 + 银两全购小丹（藏经阁 72h 循环，银两即时换丹） | 3.9 EXP/h + 18.2 银/h ÷ 6 银/EXP ≈ 6.9 EXP/h | **1219h ≈ 50.8 天** |

## 四、关键假设（逐条 + 来源）

1. 起点终态复现自 budget 测试（全战斗奖励 1750 EXP + 藏经阁 72h = 280 + 离线 24h = 115 + 小/中/大丹各一），层内余量 15 EXP；真实玩家终态 ±一层内，天数影响 <1%。来源：test/features/cultivation/application/progression_release_budget_test.dart:52-100。
2. 闭关经验速率 = `experience_per_hour × realm_scale_per_tier^tier`，三流 ×1.3；藏经阁/山林并列三流可达最高 3.0 EXP/h。来源：data/numbers.yaml:1082（cangJingGe 3.0）、:1006（shanLin 3.0）、:1238（realm_scale 1.3）、lib/features/seclusion/application/seclusion_service.dart:256-259。
3. 72h cap：单次闭关 actualHours = min(elapsed, 72)；超时部分按 passive_idle 速率结算（computeSettlement → splitHours）。来源：data/numbers.yaml:1239、lib/features/seclusion/application/retreat_settlement_calculator.dart:16-27、seclusion_service.dart:329-372。
4. 普通离线速率 = `base_exp_per_hour 3.0 × 1.6^tier`（三流 4.8 EXP/h），**无时长 cap**。来源：data/numbers.yaml:1273-1277、lib/features/seclusion/application/offline_passive_service.dart:33-50。
5. 挂机 = 离线，按 24h/天满挂换算（§5.5 在线=离线）。来源：CLAUDE.md §5.5；联合经济探针同口径 test/tools/joint_economy_probe_test.dart:30-31。
6. 经验丹 = `(当前层 ETL × layer_fraction).round()`，小/中/大 = 10%/20%/30%，使用无冷却。来源：data/items.yaml:15-17、lib/features/inventory/application/item_use_service.dart:48-53。
7. 商店小/中丹无限购（无 stock 字段），动态标价 `ETL × 0.6 / 1.2` → buyRatio 恒定 6 银/EXP。来源：data/shop.yaml:24-34、lib/features/shop/application/shop_service.dart:25-29、lib/data/defs/shop_item_def.dart（无限购字段）。
8. 丹房产丹 = `ratePerHour 1.0 × 建筑等级`（基线无灵泉协同加成，协同仅再加速），药草园同级 6.0/h 恰好覆盖 6 药草/丹消耗（不断料），成品仓 cap 80/级 ≥ 72h 产量。来源：data/numbers.yaml:2150（brew_ningshen）、:2086-2097（cao_yao_yuan）、:2140-2141（cap）、lib/features/taohua_island/application/island_production_service.dart:93,106。
9. 丹房升级境界 gate [0,1,2,3] → 三流最高 L3（L3→4 需二流）。来源：data/numbers.yaml:2144（upgrade_realm_levels）。
10. 桃花岛 Ch2 通关即解锁，默认 Ch6 终点玩家已建丹房/药草园 L1（边界假设，见残留风险）。来源：data/numbers.yaml:2066。
11. 江湖远行（远征）解锁里程碑 = abs10，起点 abs10 恰已满足，远征场景从第 0 小时可用。来源：lib/features/expedition/application/journey_unlock.dart:13-15。
12. 远征场景沿用联合经济探针既有口径（一站到底方针、代表深度 20、节点全胜、24h 满挂、170 EXP/战中档），复用 `test/support/joint_economy_model.dart` 纯函数；交叉对账 abs10→17 = 17.9 天 ≈ yaml 注释「~18天专挂」。来源：data/expeditions.yaml:4-5、test/tools/joint_economy_probe_test.dart:27-31。
13. 节气日闭关 ×1.3（每年 12 天）未计入——忽略它偏保守；子时/正午加成只作用内力维度，与 EXP 无关。来源：data/numbers.yaml:1200-1235。
14. 场景 C「混合典型」= 闭关常开、每 7 天收一次（挂机玩家自然节奏假设）；场景 B 每日开一次 App 结算。

## 五、意外事实 / 配置观察（只记录，不修）

1. **速率倒挂**：三流段普通离线（4.8 EXP/h）> 最优闭关图（3.9 EXP/h）。根源 = passive_idle 境界倍率 1.6/阶 vs retreat 1.3/阶（data/numbers.yaml:1238 vs :1276）。「挂闭关练级」在三流段严格劣于「关掉游戏等离线」。是否设计本意待用户判断。
2. **鸡生蛋结构**：下一档经验图悬崖瀑布 175 EXP/h 要求二流（data/numbers.yaml:1118-1120）——正是本缺口要挂到的境界，缺口段内不可用；断崖绝壁 500/h 更在宗师。中段无过渡经验图。
3. **丹房路径使"长挂机段"基本消失**：凝神丹按层百分比推进（0.1 层/丹，与 ETL 脱钩），丹房 L1 即 10h/层，全缺口 ~2.1 天。外审担忧的「较长无主线挂机段」仅在玩家不建/不用丹房、不打远征时成立（72–89 天）。
4. **requiredRealm 是软推荐非硬门**：`stage_07_01 requiredRealm: erLiu`（data/stages.yaml:1596）在主线入口仅作 UI 推荐展示（lib/features/mainline/presentation/stage_list_screen.dart:1007,1046 `recommendedRealm`），进入关卡无境界硬校验；真正的硬门只有发布 cap(abs17) 与心魔锁(≤abs9)。即玩家理论上可以三流越级硬打 Ch7（敌二流，境界差修正 ×0.7/×1.4），本报告按设计口径（推荐境界 = 门槛）量化。
5. 远征解锁线（abs10）与参考路线终点（abs10）精确重合——Ch6 毕业即开远征，衔接良好。

## 六、红线影响说明（逐条）

- 数值硬红线（§5.4）：**否**。零 yaml/lib 改动，纯读取。
- 三系锁死（§5.3）：**否**。模拟遵守，未让低境界用高阶图（瀑布图在缺口段被正确排除）。
- 在线 = 离线（§5.5）：**否**。所有场景按 24h 等价换算，未引入任何加速设计。
- §5.1 反主流不做：**否**。无新机制。
- 文案/数值不硬编码（§5.6）：**否**。无 UI 文案；测试内锚点期望值与 budget/balance 测试同体例（对账断言，非生产数值）。
- test/tools/output 历史坑：**守**。输出仅 print，数字人工转录本 plan，无 CSV 落盘。

## 七、四证据交付

1. **生产接线证据**：本单是只读分析工具，"接线"= 读取真实 data 配置路径并调用生产纯函数——`GameRepository.loadAllDefs` 载 production yaml；速率取 `SeclusionService.computeOutputs` / `OfflinePassiveService.compute` / `ItemUseService` 同公式丹药推进 / `IslandProductionService` 配置 / `joint_economy_model`（远征）；升层走 `CharacterAdvancementService.applyExperience` + `ProgressionGateService.isLayerLocked`（含发布 cap + 心魔锁，与生产收功一致）。
2. **targeted test**：`flutter test test/tools/progression_idle_horizon_simulation_test.dart` → **4/4 通过**（锚点对账 / 配置锚点 / 三场景 / 加速通道）；冒烟 `flutter test test/features/cultivation/application/progression_release_budget_test.dart` → 4/4 通过；`flutter analyze` → **No issues found!**；新文件已 `dart format`。
3. **红线影响**：见 §六，逐条全否。
4. **残留风险**：
   - 远征场景是探针口径外推（节点全胜、无操作间隔、深度 20 代表性假设），真值待 Phase C 战斗探针校准——但即使打 5 折也仅 ~20 天，不改变量级结论。
   - 丹房场景假设 Ch6 终点已建丹房/药草园 L1；若未建，需追加建设银两积累时间（丹房 L1→L3 共 2600 银 + 药草园 1700 银 + 建造费，按藏经阁 18.2 银/h 约 +10–15 天，仍远快于场景 A/B/C）。
   - 节气日 ×1.3、奇遇/探索随机 EXP 未计入，均为加速方向——场景 A/B/C 是偏保守上界。
   - 起点余量 15 EXP 为参考路线口径，个体差 ±1 层内进度 → 天数 ±1% 内。

## 八、当前恢复点（§8.0 五项）

- **状态**：完成，待评审（tip 打 [READY]）。
- **已完成**：worktree 预热零漂移；模拟工具 4 测全绿 + analyze 0 issue；报告（本文件 §一–§七）数字全部来自工具实测 print。
- **已跑验证**：`flutter test test/tools/progression_idle_horizon_simulation_test.dart`（4/4）；`flutter test test/features/cultivation/application/progression_release_budget_test.dart`（4/4 冒烟）；`flutter analyze`（0 issue）；`dart format`（已应用）。
- **阻塞**：无。
- **下一步**：主会话独立复跑对账（命令同上）→ 用户拍板节奏（降 Ch7 门槛 / 补中段内容 / 接受现状）；本单不含任何生产改动建议的实装。
