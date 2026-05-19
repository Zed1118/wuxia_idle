# P1 #43 高阶内容占位 audit · 2026-05-19

> Nightshift T02 audit 产出。**只调研,不改 yaml**。

## §1 占位现状表

### equipment.yaml drop_source_tags

| 文件 | line | 字段值 | 是否占位 | 期望 |
|---|---|---|---|---|
| equipment.yaml | 11 (注释) | `drop_source_tags 当前为占位` | — | 说明行,非字段 |
| equipment.yaml | 404,419,434,448,462 | `dropSourceTags: ["zongShi_unlock"]` | ✅ 占位 | tower_id + quest_id（Phase 4 掉装备 service 落地后补） |
| equipment.yaml | 478,493,508,522,536 | `dropSourceTags: ["wuSheng_unlock"]` | ✅ 占位 | 同上，武圣境界解锁触发点待 Phase 4+ 定义 |

> 注：重器(zhongQi) `dropSourceTags: ["tower_30", "jueDing_unlock"]`、利器(liQi) `["tower_25", "yiLiu_quest"]` 已有具体来源，无占位问题。

### towers.yaml 21-30 层 skillIds + dropTable

> **⚠️ 境界曲线修正**：towers.yaml header 明确标注 21-25=jueDing(绝顶)、26-30=zongShi(宗师)，武圣留 Phase 4 飞升；任务描述中期望的 zongShi/wuSheng 对应层段有偏差，以 yaml 实际为准。

| stage_id | realmTier (实际) | skillIds (实际) | skillIds (期望) | dropTable equip (实际) | dropTable equip (期望) |
|---|---|---|---|---|---|
| floor 21 | jueDing | mingjia_basic/skill | jianghumiquan_* | 无装备 | zhongQi |
| floor 22 | jueDing | mingjia_basic/skill | jianghumiquan_* | 无装备 | zhongQi |
| floor 23 | jueDing | mingjia_basic/skill/ult | jianghumiquan_* | weapon_liqi | zhongQi |
| floor 24 | jueDing | mingjia_basic/skill/ult | jianghumiquan_* | armor_haojiahuo | zhongQi |
| floor 25 (小Boss) | jueDing | mingjia_basic/skill/ult | jianghumiquan_* | liqi+haojiahuo | zhongQi |
| floor 26 | zongShi | mingjia_basic/skill/ult | shichuanshen_* | 无装备 | baoWu |
| floor 27 | zongShi | mingjia_basic/skill/ult | shichuanshen_* | 无装备 | baoWu |
| floor 28 | zongShi | mingjia_basic/skill/ult | shichuanshen_* | weapon_liqi | baoWu |
| floor 29 | zongShi | mingjia_basic/skill/ult | shichuanshen_* | liqi+haojiahuo | baoWu |
| floor 30 (大Boss) | zongShi | mingjia_basic/skill/ult | shichuanshen_* | liqi×1+haojiahuo×2 | baoWu |

## §2 风险评估

**Demo 主线**(15-20 关,玩家境界停二流/一流)**可暂不阻塞**当前占位:战斗结算不会因 skillIds 层级偏低而崩溃(mingjia 技能集已存在),掉表偏低也不影响主线体验。

**但爬塔 30 层是 Demo 必交付内容**(CLAUDE.md §7 + GDD §8.4 内容总量表:30 层 = 3 小 Boss [5/15/25] + 3 大 Boss [10/20/30]),**Demo 验收前 21-30 层必须补齐**(skillIds + dropTable 到位 + Boss 数值红线 ≤50000 + 战斗体验过得去),否则测试玩家爬到 25+ 层会感知到明显技能/掉率断档,影响 Demo 上线口碑。**降级验收路径**(若工时不足):至少补 25 / 30 两个 Boss 层的 skillIds + dropTable(其余 21-24 / 26-29 层用 mingjia/liQi 兜底接受),文档明示「21-29 层 placeholder 待 P1.1 补齐」。

## §3 推荐补齐方案

| 方案 | 时机 | 工作量 | 风险 |
|---|---|---|---|
| A · P1.1 起手 | 主线 15-20 关完成后立即 | 中（需新增 jianghumiquan/shichuanshen skill 集 × 3 流派 × 3 阶 = 18 条 + baoWu 掉表配置 10 层） | 数值红线校验（Boss HP ≤ 50000） |
| B · P2 起手 | 1.0 路线图 P2 | 低（届时 zongShi/wuSheng 内容整包落） | 内测阶段高阶层体验断档 |
| C · Demo 永久占位 | — | 0 | 21-30 层技能/掉率与境界严重断档，影响发布后口碑 |

**推荐：方案 A**(强,Demo 必交付 30 层)。21-30 层是爬塔的后半程,补齐 skillIds 和 dropTable 工作量可控(18 条 skill 定义 + 掉表),且技能层级断档会直接影响战斗体验,不适合带占位上线。**若工时不足**:至少补齐 25 / 30 两个 Boss 层 + 文档明示其余 placeholder(降级验收路径,详 §2 末段)。

## §4 closeout

本批 audit 确认 3 类占位：equipment.yaml 宝物/神物 `dropSourceTags` 纯字符串占位（Phase 4 掉装备 service 后填），towers.yaml 21-30 层 skillIds 全停在 mingjia 阶（jueDing 应用 jianghumiquan、zongShi 应用 shichuanshen），21-30 层 dropTable 装备停在 liQi/haoJiaHuo（jueDing 应补 zhongQi、zongShi 应补 baoWu）。后续落地由 Mac 端 Opus 在 P1.1 session 开头处理，优先新增 jianghumiquan/shichuanshen skill YAML 集，再回填 towers.yaml 21-30 层，估时 1-2 session（1.5h）。
