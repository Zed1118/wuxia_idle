# 祖师起手回归学徒新手（空手 · 放宽 T55 师承遗物起手要求）· design

> 状态：design（用户逐项拍板：B 方向 + 学徒·启蒙 + 空手 + 入门功 → 待 review → 实装）
> 阶段：1.0 长线打磨期 · 平衡/叙事一致性修正
> 范围：onboarding 配置（masters.yaml 祖师）+ 放宽一条加载期红线（T55）。**无 schema/saveVer 改动；老档 slot1 幂等不重建。**
> 模型建议：实装期 high（动红线校验 + 平衡，但单点、有加载期校验兜底）。

## 1. 由来 & 诊断

用户真机试玩多存档槽新档，发现"全新祖师"自带利器/好家伙级装备、属性碾压早期学徒野怪 6-8×。诊断（本会话）：

- **非 bug、非泄漏**：存档隔离正确（每槽独立 db），新祖师是正常 seed。
- **是 Demo fixture 漂移**：`masters.yaml` 祖师 `defaultRealm: yiLiu`（一流/第4阶）+ 3 件高阶装备，源自 `week4_d_minimal_spec`（2026-05-13）。该决策两个理由——①开局展示完整师徒队伍 ②全员<武圣避免飞升锚点——**现已全部失效**：弟子已改终局 stage_06_05 才拜入（开局单人）、飞升已实装（P5+）。
- **与 GDD 章节进程矛盾**：GDD Ch1「学武出山」=新手，Ch1-3=学徒→一流，Ch4-6=一流→武圣。祖师起手一流 = 直接跳到 Ch3 终点，架空前三章成长弧。早期关卡野怪本就是学徒级 = 关卡按低境界配，漂的是祖师。

**用户拍板**：祖师降到**学徒·启蒙**、**空手起家**、心法降**入门功**。

## 2. 红线决策：放宽 T55「祖师起手必带师承遗物」

`game_repository.dart` `_enforceMasterRedLines` 的 **T55 校验**要求祖师 `startingEquipmentIds` 至少含 1 件 `isLineageHeritage==true`。"空手"撞此校验，**本 spec 放宽（移除）该校验**。

**放宽依据（全部本会话证伪）**：
- **叙事**：学徒新手不该已持有「师承遗物」（传家宝）。novice 应在游戏中获得/铸成。
- **GDD §6.1 一致**：line 369 定义师承遗物 = 「师父留给徒弟的兵器，每代传 1-2 件」——是**传递机制**，非「祖师开篇即有」。「开篇即有」只在 T55 注释 + masters.yaml（Demo 期加），**GDD 本身无此要求 → GDD 不改**。
- **飞升不依赖起手遗物**：`ascend_service.dart:119` 飞升时玩家**任选已装备/库存**传徒，不预过滤 isLineageHeritage；`:144` 空选优雅兜底 `if (ids.isEmpty) return []`。祖师无遗物 → 飞升传空，不崩。
- **自然获得**：两件 heritage 装备 Ch3 掉（锦袍）/ tower25+一流任务（龙泉剑），祖师爬到武圣前自然拥有 → 飞升时有得传。

## 3. 改动清单

| 文件 | 改动 |
|---|---|
| `data/masters.yaml`（祖师块） | `defaultRealm: yiLiu→xueTu`；`defaultLayer: qiMeng`（不变）；`startingEquipmentIds: []`（清空 3 件）；`startingTechniqueIds: [tech_gangmeng_jichu, tech_lingqiao_jichu]`（mingjia 3阶→jichu 入门功；lingqiao_jichu 本就入门功保留）；更新头注（Demo fixture 退役 + 回归 GDD 进程 + 空手新手） |
| `lib/data/game_repository.dart` | 移除 `_enforceMasterRedLines` 的 T55 `hasHeritage` 校验块（含 throw）；更新函数 doc 注释（删 T55 行，注明放宽依据指向本 spec） |
| `data/equipment.yaml` | **不改**（heritage 装备保留，仍 Ch3/tower 掉落供游戏中获得） |
| `GDD.md` | **不改**（§6.1 已一致） |

## 4. 不破（红线核验）

- **三系锁死**：祖师学徒 + 空手（0 装备）+ 入门功（1阶）全在学徒 cap 内；`game_repository` 加载期 tier≤realm 校验兜底（改错即 fail-fast）。
- **飞升传承**：读 live-owned heritage（`derived_stats.dart:277` 装备件数 / `ascend_service` 任选）→ 不破。
- **老档**：slot1 已有 founder，`ensureFoundingMasters` 幂等跳过 → 不迁移、不受影响。
- **弟子**：本次**不动**大/二弟子 defaultRealm（他们终局拜入的境界匹配是另一平衡点，范围外，单列）。

## 5. 验收

- 加载：`GameRepository` 加载 masters.yaml **不抛**（T55 移除后空 startingEquipmentIds 合法）；三系锁死校验通过。
- 单测：新增/改测断言新档祖师 = `xueTu·qiMeng` / `startingEquipmentIds` 空 / `startingTechniqueIds` 全 ruMenGong tier；移除/更新原断言祖师 yiLiu/带装备的测试。
- 全量 `flutter analyze` 0 / `flutter test` 绿。
- 真机：`flutter run -d macos` 删测试槽重开新档 → 祖师学徒·空手、早期关卡（学徒野怪）难度匹配、可正常推进（空手能否过 01_01 属真机校值，不可过则属早期平衡另调）。
