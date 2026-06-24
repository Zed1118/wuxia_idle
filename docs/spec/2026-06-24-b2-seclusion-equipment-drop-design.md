# 闭关装备掉落死链接通 · 设计 spec

> **来源**：全系统审计 B2（`docs/audit/full_system_audit_2026-06-24.md`）——闭关 `equipment_drop_rate` 配齐、roll 也算，但 `if` 块体空 + writeTxn 不入库，配了却永不掉装备。
> **方向**（用户拍板）：接通真功能。手工 yaml 指定 defId / 压一阶定位 / 外层闸命中后加权抽 1 件必发。
> **基线**：HEAD `3b58ca85`，saveVer 不变（`SeclusionMapDef` 是 yaml def 非存档 schema；装备走现成 `Equipment` collection）。**不改产出数值**（mojianshi/silver/exp/内力全不动）。

## 1. 背景与现状

闭关掉落是「双断」死链，上游不产 + 下游不落库：
- **上游空块**（`seclusion_service.dart:251-259`）：`equipRoll = rng.nextDouble()`、`equipProb = def.equipmentDropRate × config.baseEquipDropProbability` 都真算了，但 `if (equipRoll < equipProb) {}` 块体仅注释（"Demo 阶段无 dropTable"），`equipDrops` 声明后再没 add → 恒空。
- **根因**：`SeclusionMapDef`（`seclusion_map_def.dart:6-72`）只有 `equipmentDropRate` 概率权重，**无 dropTable 字段**。对比 `StageDef`/`TowerFloorDef` 都带 `dropTable: List<DropEntry>`，由 `DropService`（`drop_service.dart:52-114`）消费。
- **下游不落库**（`completeRetreat` writeTxn `seclusion_service.dart:327-465`）：只落 mojianshi/silver，`outputs.equipmentDrops` 在 480 行**只透传给返回值给 UI**，从没写进 `isar.equipments`。（注：404 行的 `isar.equipments.put(eq)` 是给已装备武器累加 battleCount 共鸣，与掉落无关。）
- **命中率现配**（`numbers.yaml retreat`，不改）：`base_equip_drop_probability: 0.1`；5 图 `equipment_drop_rate` 1.0~1.5 → 外层闸 **10%~15% 每次闭关**。

## 2. 设计决策（已拍板）

| 项 | 决议 |
|---|---|
| 掉落来源 | 手工 yaml 指定 defId（同 stage/tower 体例，可控、守 §5.3） |
| 强度定位 | **压一阶**：掉落锁地图 requiredRealm 低一阶；低交互挂机不与主线/塔抢肥（守 §5.1），定位补给/兑材料 |
| 发放机制 | 外层闸（10~15%）决定出不出 → 命中后从 dropTable **加权抽 1 件必发** |
| 权重 | 用 `DropEntry.dropChance` 当**相对权重**（全 1.0 = 等概，可调稀；字段被消费，不留死配置） |
| 每图候选 | 3 件（weapon/armor/accessory 各 1，覆盖三槽），排除 `*_special_*` 里程碑装备 |

## 3. 压一阶映射（RealmTier ↔ EquipmentTier 一一对应，压 = max(0, 同阶−1)）

| 地图 | requiredRealm | 同阶 | **掉落 tier** | 候选 defId（weapon / armor / accessory） |
|---|---|---|---|---|
| 山林 shanLin | xueTu | 寻常货 | **寻常货**（边界·已最低压不动） | `weapon_xunchang_tie_jian` / `armor_xunchang_bu_yi` / `accessory_xunchang_yu_pei` |
| 古剑冢 guJianZhong | sanLiu | 像样货 | 寻常货 | `weapon_xunchang_zhe_dao` / `armor_xunchang_duan_gua` / `accessory_xunchang_tong_ling` |
| 藏经阁 cangJingGe | sanLiu | 像样货 | 寻常货 | `weapon_xunchang_ruan_bian` / `armor_xunchang_mian_jia` / `accessory_xunchang_yao_nang` |
| 悬崖瀑布 xuanYaPuBu | erLiu | 好家伙 | 像样货 | `weapon_xiangyang_gang_dao` / `armor_xiangyang_pi_jia` / `accessory_xiangyang_yin_jie` |
| 断崖绝壁 duanYaJueBi | zongShi | 宝物 | 重器 | `weapon_zhongqi_po_zhen_chui` / `armor_zhongqi_yin_lin_jia` / `accessory_zhongqi_qing_yu_huan` |

## 4. 接入点与数据流

> **API/字段已亲核**（`drop_service.dart` / `equipment_factory.dart` / `drop_entry.dart` / `strings.dart`）：DropEntry yaml key 为 **camelCase** `equipmentDefId`/`dropChance`（DropEntry.fromYaml 硬期望）；`EquipmentFactory.fromDef` 为**命名参数** `fromDef(def, {required rng, required obtainedAt, required obtainedFrom, ...})`；`DropService` 的 `obtainedFrom` 来自构造级 `defaultObtainedFrom` 字段（非逐调用参数）。

### 4.1 数据模型（`seclusion_map_def.dart`）
- 加 `final List<DropEntry> dropTable;`（默认 `const []`）。
- `fromYaml`：解析 `y['dropTable']`（无则空表）；逐条复用 `DropEntry.fromYaml`（含其 dropChance∈[0,1] + exactly-one-of 校验），仅放 `EquipmentDrop` 条目。

### 4.2 发放（`DropService` + `seclusion_service.dart`）
- `DropService` 加 `Equipment? rollOneWeighted(List<DropEntry> table, Rng rng)`：表空返回 null；否则按各条 `dropChance` 作**相对权重**累积选 1 条 `EquipmentDrop`，照 `_rollTable` 的 `EquipmentDrop` 分支体例 `EquipmentFactory.fromDef(def, rng: rng, obtainedAt: now(), obtainedFrom: defaultObtainedFrom)` 实例化（`equipmentDefLookup`/`now`/`defaultObtainedFrom` 均用 DropService 自身字段）。
- **接线**：seclusion 现**无** DropService 依赖（全新接）。`computeOutputs`（static，:177）新增 `DropService dropService` 参数，由 caller `completeRetreat`（:311）构造时注入，`defaultObtainedFrom: UiStrings.dropSourceSeclusion`（新增常量，避免散写中文 → 守审计 E）。computeOutputs 仍纯函数（不写 Isar），保持可测（注入 mock DropService）。
- `computeOutputs` 空 `if` 块体（:255-259）替换为：命中外层闸 → `final eq = dropService.rollOneWeighted(def.dropTable, rng); if (eq != null) equipDrops.add(eq);`。

### 4.3 落库（`completeRetreat` writeTxn）
- writeTxn 内加循环：`for (final eq in outputs.equipmentDrops) { await isar.equipments.put(eq); }`，照 mainline/tower flow 体例。`obtainedFrom` 已在 4.2 经 `defaultObtainedFrom` 标 `UiStrings.dropSourceSeclusion`。
- 返回值 480 行 `equipmentDrops` 保持透传（UI 已接收显示）。

### 4.4 配置（`numbers.yaml retreat.maps[]`）
- 5 图各补 `dropTable:` 区块（camelCase，与 DropEntry.fromYaml 对齐，同 stages.yaml 体例），按 §3 表填 3 条 `equipmentDefId` + `dropChance: 1.0`。

### 4.5 新增常量（`lib/shared/strings.dart`）
- `static const String dropSourceSeclusion = '闭关所得';`（紧随 `dropSourceStageDefault` 等同体例）。

## 5. 红线验证（守 §5.3 锁步）

闭关掉落 tier 必 ≤ 对应 requiredRealm 同阶（压一阶天然满足）。新增红线测断言「5 图 dropTable 所有装备 tier == 压一阶目标 tier」，防后续手填漂移。语义断言（白名单/集合自洽），不写具体数字。

## 6. 测试清单（TDD）

1. **掉落命中**：固定 seed 使外层闸命中 → `equipDrops.length == 1` 且 `eq.tier == 压一阶目标 tier`。
2. **闸不命中**：seed 使 `equipRoll ≥ equipProb` → `equipDrops` 空。
3. **加权抽 1**：表 3 件、权重不等时，固定 seed 命中确定那 1 件；全 1.0 时分布覆盖三槽。
4. **落库**：`completeRetreat` 后该装备真进 `isar.equipments`、`obtainedFrom == UiStrings.dropSourceSeclusion`。
5. **锁步红线**（§5）：5 图 dropTable tier 自洽。
6. **零回归**：dropTable 空 → 不掉、不入库；mojianshi/silver/exp/内力产出全不变。

## 7. 影响面

- 改：`seclusion_map_def.dart`（+dropTable 字段/解析）、`drop_service.dart`（+rollOneWeighted）、`seclusion_service.dart`（computeOutputs +dropService 参数 / 空块体 / writeTxn 落库 / completeRetreat 注入构造）、`numbers.yaml`（5 图 dropTable）、`strings.dart`（+dropSourceSeclusion）。
- 零 saveVer / 零产出数值变更 / dropTable 默认空 → 默认安全（同 A1 体例）。
- UI（`retreat_result_screen.dart`）已接收 `equipmentDrops`，无需改（此前恒空所以从不显示）。
