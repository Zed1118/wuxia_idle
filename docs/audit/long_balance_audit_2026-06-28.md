# 长线平衡审计 · 第一轮（2026-06-28）

## 范围

本轮只读审计掉落、银两、强化材料、心法修炼、离线收益、终局极值 build 与周目回报。未修改 `data/*.yaml`，调参建议均列为后续用户拍板项。

## 数据来源

- 规则文档：`AGENTS.md`、`CLAUDE.md` §5/§7/§8.0、`GDD.md` §5/§9、`docs/spec/playability_phase2_backlog.md` §十二。
- 配置：`data/numbers.yaml`、`data/stages.yaml`、`data/towers.yaml`、`data/shop.yaml`、`data/items.yaml`。
- 实现入口：`DropService`、`SeclusionService`、`OfflinePassiveService`、`EnhancementService`、`EquipmentDisposalService`、`cycle_drop_bonus`、桃花岛 production/action 配置。
- 测试输出：`test/tools/output/idle_economy_2026-05-29.md`、`balance_summary_2026-05-29.md`、`proficiency_sweep_2026-06-11.md`、`extreme_cycle_diagnosis_2026-06-14.md`。
- CodeGraph：本 worktree 未初始化，`codegraph_status` 返回 not initialized；本轮改用 `rg`、定向读文件和现有测试。

## 跑过的命令/测试

- `dart run build_runner build --delete-conflicting-outputs`：补齐本地生成产物，git 无变更。
- 目标测试集合：`flutter test test/tools/idle_economy_test.dart ... test/data/numbers_config_skill_proficiency_test.dart`
  - 结果：`108 pass / 1 fail`；唯一失败为并发加载 `libisar.dylib` 的环境错误。
- 单独复跑：`flutter test test/features/equipment/application/equipment_disposal_service_test.dart`
  - 结果：25/25 pass，确认上面的失败不是业务断言。
- 桃花岛相关：`flutter test test/features/taohua_island/island_upgrade_curve_b_test.dart test/features/taohua_island/island_offline_online_invariant_test.dart test/features/taohua_island/taohua_island_config_test.dart`
  - 结果：35/35 pass。
- 只读 Ruby YAML 统计：汇总主线/爬塔掉落期望、闭关 72h 产出、被动离线 72h 产出、强化成本、商店价、桃花岛总银两 sink。

## 关键量化结果

- 主线 47 关、爬塔 30 层；装备掉落 entry：主线 98、爬塔 26。
- 一轮主线全清物品期望：银两 1885、磨剑石 21.5、心血结晶 327.5、大还丹 1.5。
- 一轮爬塔首通物品期望：银两 1322.5、磨剑石 35、心血结晶 80.5、大还丹 3。
- 闭关 72h 基线：山林 7200 EXP / 72 磨剑石 / 576 银 / 36 凝练；悬崖瀑布 21294 EXP / 60 磨剑石 / 2920 银 / 60 凝练；断崖绝壁 133665 EXP / 534 磨剑石 / 16039 银 / 200 凝练。
- 被动离线 72h：学徒 1800 EXP / 18 磨剑石；武圣 8688 EXP / 86 磨剑石；不产银两。
- 强化磨剑石成本：+15 合计 41；+49 合计 757。
- 桃花岛真实配置：7 座建筑全满银两合计 88,800；现有测试仍有“四座 52,200”的 fixture 断言。
- 极值 build × 周目：全局单击峰值 213,015，普攻峰值 134,926；cycle 1/2/3 皆 100% 胜、1 tick，仍远低于百万。

## 发现分级

### Medium · 桃花岛银两总量口径漂移

`data/numbers.yaml` 注释仍写“四座全满 ≈ 52,200 银”，但 Phase 2 真实配置已扩到 7 座建筑，总银两 sink 为 88,800。相关测试 `island_upgrade_curve_b_test.dart` 仍只用四座 fixture 验证 52,200，没有对真实 `GameRepository.instance.numbers.taohuaIsland` 做全量银两总额断言。

影响：银两长线 sink 已显著变大，但目前只有结构/online=offline 测试，没有“真实 7 座总成本 vs 银两收入曲线”的红线。

### Medium · 心血结晶存在过量风险，需强化期望成本模拟确认

主线+爬塔一轮首通期望心血结晶约 408，而磨剑石约 56.5。心血结晶本质是强化失败保底资源，但当前掉落也直接大量给。若玩家不频繁用结晶保底，后期可能堆积；若每件 +20~+49 大量用保底，则又可能合理消耗。现有测试覆盖了单次强化/保底规则，但没有“从掉落+闭关+分解到 +49 的期望消耗模拟”。

影响：不是确认失衡，但这是本轮最值得优先量化的资源过量/断流风险。

### Low · 被动离线 fallback 不产银两

`OfflinePassiveService` 只产经验和磨剑石，银两主要来自主动战斗掉落、闭关、装备出售和桃花岛相关链路。若玩家没有安排闭关，只是离线回归，被动收益不会补银两。

影响：这可能是设计意图（闭关安排才是核心循环），但银两经济审计需要明确“无 active 闭关”的 fallback 是否应保持无银两。

### Info · 极值 build 爽感符合当前软红线

极值 build 在 Ch6 × cycle{1,2,3} 均 100% 胜、1 tick，峰值 213,015，不进百万。此行为与 CLAUDE/GDD 当前口径一致：终局满配秒杀与周目进化对满配无效属于已拍板爽感。

### Info · 周目回报未引入膨胀

`cycle_drop_bonus` 仅对材料类放大到 ×1.5，装备/经验丹/秘籍/银两不随周目放量；稀有彩头二周目概率提高。测试覆盖材料分类与 floor 后不低于原值。当前没有百万膨胀风险。

## 建议任务切片

1. **强化材料期望模拟**：新增只读工具/测试，按成功率、保底策略、掉落、闭关、分解，模拟一件装备 +15/+30/+49 的磨剑石与心血结晶供需。
2. **银两总量红线**：用真实桃花岛 7 建筑配置计算总成本，和闭关 8h/天、主线/爬塔、出售装备收入做天数区间断言；同步修正 52,200 注释/fixture。
3. **被动离线银两口径拍板**：确认无 active 闭关时是否继续不产银两；若要补，只做低强度 fallback，不引入在线 buff/加速。
4. **周目回报真机校准**：保留当前 ×1.5 材料、8%/3% 稀有彩头初值，等实玩数据决定是否调整。

## 需要用户拍板项

- 桃花岛 7 座总成本 88,800 是否是期望长线 sink？若是，更新注释和真实配置总量测试；若不是，另开 balance spec 调整。
- 心血结晶是否允许作为较慷慨的长期保底货币直接掉落？还是应更依赖强化失败/高阶分解产出？
- 无 active 闭关的被动离线是否应保持“无银两”。
- 终局满配 1 tick 清 cycle3 是否继续按既有拍板保留。
