# Demo 完成度地图

> 对照 GDD §7-§8 Demo 内容量目标 vs 当前实现状态，用于 3 个月里程碑进度评估。每完成一波 T 任务后更新。

统计口径：只统计已落在仓库内的结构化数据与文案文件；`data/narratives/`、`data/lore/`、`data/events/` 为 DeepSeek 领地，本文件只读数量，不评价文案质量。

| 项目 | GDD 目标量 | 当前数量 | 状态 | 备注 |
|---|---:|---:|---|---|
| 主线关卡 | 15-20 | 6（`data/stages.yaml`） | 🚧 部分完成 | Phase 3 Week 1 T33-T39：主线最小闭环 3 章 × 2 关；DeepSeek 侧另有 `data/narratives/stages/` 15 个文案文件，但未接入 `stages.yaml`。 |
| 章节 | 3 | 3 | ✅ 已达标 | Phase 3 Week 1 T33-T39：章节 UI 与进度服务已落；`PROGRESS.md` / `phase3_summary.md` 记录 3 章。 |
| 主线剧情字数 | 3,000-5,000 | 5,836 字符（`data/narratives/chapters/` + `data/narratives/stages/`） | ✅ 已达标 | DeepSeek 已写 3 个章节文件 + 15 个 stage 文案文件；按当前字符统计法已超过下限。 |
| 爬塔层数 | 30（3 小 Boss + 3 大 Boss） | 30（`data/towers.yaml`） | ✅ 已达标 | Phase 3 Week 2 T40-T46：30 层 fixture，Boss 层为 5/10/15/20/25/30。 |
| 闭关地图 | 5 | 5（`numbers.yaml` `retreat.maps`） | ✅ 已达标 | Phase 3 Week 3 T47-T51：5 张闭关地图 + SeclusionService + 4 UI 屏；T52 Pen 视觉验收待跑。 |
| 奇遇 | 20-30 | `data/encounters.yaml` 文件未创建 | ⬜ 未启动 | Week 4 候选 C；DeepSeek 侧已有 `data/events/` 26 个事件文案文件，但 Mac 侧触发条件与联结校验未实现。 |
| 装备 | 30-50（覆盖 7 阶，每阶 5-7） | 10（`data/equipment.yaml`，覆盖 4 阶） | 🚧 部分完成 | Phase 1/2 T07/T19-T22：装备 fixture 与装备系统已落；当前仅 `xunChang`/`xiangYang`/`haoJiaHuo`/`liQi`。 |
| 心法 | 20-30（覆盖 7 阶 + 3 流派） | 6（`data/techniques.yaml`，覆盖 2 阶 + 3 流派） | 🚧 部分完成 | Phase 1/2 T07/T23-T25：TechniqueLearning / Cultivation / Dispel 已落；当前仅 `ruMenGong`、`mingJiaGong`。 |
| 典故 | 50-80 | 52（`data/lore/`） | ✅ 已达标 | DeepSeek 侧已写 52 个 lore yaml；Mac 侧只读数量，未修改。 |
| 武学领悟招式 | 30-50 | 18（`data/skills.yaml`）；`data/insights.yaml` 文件未创建 | 🚧 部分完成 | Phase 1/2 已有 18 个战斗招式与 TechniqueLearningService；Week 4 候选 E 的武学领悟系统未实现。 |
| 武学领悟触发条件 | 20-30 | `data/insights.yaml` 文件未创建 | ⬜ 未启动 | Week 4 候选 E；§12 #6 机缘值累积规则未定。 |
| 心法相生组合 | ≥5 | 5 个效果值（`numbers.yaml` `synergies.effect_values`） | 🚧 部分完成 | Phase 1 numbers 已有 5 个效果数值；未找到 `SynergyDef` / 组合判定数据实现。 |
| 师徒角色 | 3（祖师 + 大弟子 + 二弟子） | `data/masters.yaml` 文件未创建 | ⬜ 未启动 | Week 4 候选 D；`numbers.yaml` 仅有 `demo_max_characters: 3` 与遗物/buff 配置占位。 |

## 完成度总览

✅ 已达标：5 项；🚧 部分完成：5 项；⬜ 未启动：3 项。

事实描述：当前 Demo 已完成爬塔与闭关两块结构化内容，主线、装备、心法、武学领悟和相生组合仍处于 fixture / 部分实现状态，奇遇与师徒尚未建立 Mac 侧数据入口。
