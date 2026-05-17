# equipment id ↔ lore yaml 一致性扫描(2026-05-17)

> Nightshift T02 产出。当前基线:equipment.yaml ↔ lore/*.yaml 一致性快照。

## 0. 扫描范围
- 工作树:`/Users/a10506/Desktop/wuxia-idle-T02`(基于 main HEAD `fc25207`)
- 输入 1:`data/equipment.yaml`(35 装备 def)
- 输入 2:`data/lore/*.yaml`(35 lore yaml)

## 1. 统计

| 集合 | 数量 |
|---|---|
| equipment.yaml id | 35 |
| data/lore/*.yaml | 35 |

## 2. 双向对账

### 2.1 equipment.yaml id → lore/ 文件
- 全部命中(0 个 missing-lore)

### 2.2 lore/ 文件 → equipment.yaml id
- 全部命中(0 个 orphan-lore)

## 3. 7 阶分布抽样校验

| tier | equipment.yaml 件数 | lore yaml 件数 | 匹配 |
|---|---|---|---|
| xunChang(寻常货) | 5 | 5 | yes |
| xiangYang(像样货) | 5 | 5 | yes |
| haoJiaHuo(好家伙) | 5 | 5 | yes |
| liQi(利器) | 5 | 5 | yes |
| zhongQi(重器) | 5 | 5 | yes |
| baoWu(宝物) | 5 | 5 | yes |
| shenWu(神物) | 5 | 5 | yes |

7 阶 × 5 件 = 35，W15 #35 全交付，tier 分布完整。

## 4. 结论

**0 漂移，基线建立。**

`data/equipment.yaml` 35 个 id 与 `data/lore/*.yaml` 35 个文件名完全双向命中，无 missing-lore、无 orphan-lore、无命名漂移。7 阶每阶 5 件分布整齐。

## 5. 后续维护建议

- W18+ 任何新增装备 def:同步加 `data/lore/<id>.yaml`，id 严格匹配
- 装备永退役场景:`mv data/lore/<id>.yaml data/lore/_archive/` 路径需先在 GDD/CLAUDE 加锚点(目前未约定)
- 建议在 CI/加载层加强校验:装备 id ∉ lore 文件集时抛错而非静默跳过(与 CLAUDE.md §8.1 encounter 域同等约束)
