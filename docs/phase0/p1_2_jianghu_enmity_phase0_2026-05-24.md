# P1.2 江湖恩怨 · 声望 Phase 0 地基预备(草案 · 不实装)

> 日期:2026-05-24 凌晨 / 模型:Opus 4.7 high / ~30min
> 范围:Phase 0 reality check + spec Q&A 候选清单 + GDD §12.4 升档草案
> 8h overnight 流批 4/5(D · 半自主)· 主轴拍板留用户起床
> 上游引用:GDD.md:643 / ROADMAP_1_0.md:77-80,243,292

## TL;DR

P1.2 = **§12.1 江湖恩怨**(NPC 关系网)+ **§12.2 声望**(累积值)联合扩段。**Phase 0 6 维全 greenfield ✅**(0 schema / 0 caller / 0 邻近模块 / 0 UI / 0 公式)· 仅红线层 GDD/ROADMAP 占位段。**主轴未拍板**(schema 字段名 / Isar 实体粒度 / 触发条件维度 / NPC 反应影响 / §12.1 与 §12.2 是否合批),本 doc 列 5 项 Q&A 候选给用户起床拍板。

## Phase 0 6 维 reality check 结论

| 维度 | grep 命中 | 结论 |
|---|---|---|
| A schema(NpcRelation / Enmity / Disposition / Sentiment / Reputation) | 0 hit lib/ | ✅ greenfield · 0 旧 schema 漂移 |
| B caller | 0 hit | ✅ greenfield · 不破现有 service |
| C 邻近系统(class Npc / NPC / JianghuNpc) | 0 hit | ✅ greenfield · 无前置 abstraction |
| D UI widget(reputation/enmity/relation panel) | 0 hit | ✅ greenfield · UI 入口待设计 |
| E 红线层(GDD §12 / ROADMAP P1.2) | GDD:643 一行占位 + ROADMAP:77-80,243,292 已规划 | ✅ 占位 OK · 设计自由度高 |
| F 公式层 numbers.yaml(reputation/enmity/disposition) | 0 hit | ✅ greenfield · 数值待设计 |

## spec Q&A 候选清单(5 项 · 起床拍板 · **无推荐 · 主轴拍板留用户**)

| Q | 主轴 | 候选方案 |
|---|---|---|
| Q1 | §12.1 + §12.2 合批 vs 拆批 | A 合批 6-8h 一次扩 / B 拆批 ~4-6 + 6-8h(声望先) / C 只 §12.2 声望 1.0 留 §12.1 江湖恩怨 1.1 |
| Q2 | NpcRelation schema 粒度 | A 全连接 N×N 矩阵 / B 稀疏 NpcRelation{source,target,type,level} / C 单向 enmity 只玩家→NPC |
| Q3 | 触发维度 | A 仅 stage_boss kill / B + encounter NPC / C + 学敌对心法 / D + Ch4-6 narrative 选项分支(行侠/行恶) |
| Q4 | NPC 反应影响 | A UI narrative 分支 / B 战斗 ±15-25% / C A+B 全包(沿 P3.1.B 体例)/ D + enmity ≥80 援军 stage |
| Q5 | 声望分阶 | A 沿 GDD §5.2 七阶节奏(学徒→武圣 7 阶)/ B 简化为 4 阶(无名/侠/枭/魔)/ C 双轴(行侠 + 行恶 各 [-100,+100]) |

## GDD §12.4 升档草案(用户审稿)

§12.4.X P1.2:触发(杀/救/学心法)· Isar `Reputation` Collection 多门派 [-100,+100] + `NpcRelation` 稀疏(type enum friend/foe/master/disciple/owed)· 影响 UI narrative 分支 + 战斗 ±15-25% + enmity ≥80 援军 stage + encounter 周期性。红线:不破 §5.2/§5.4 · enmity buff 沿 P3.1.B `attackPowerMultiplier` view layer 体例。

## 不实装边界 · 估时 · 起床 first-read

- **不实装**:0 Isar schema / 0 lib/features/jianghu / 0 data/jianghu / 0 enum / GDD §12.4 正式拍板留用户
- **估时**:spec ~45min + Batch 1 schema 2h + B2 trigger 2h + B3 UI 1.5h + B4 R5/doc 1.5h = **~7-8h opus xhigh**(memory `feedback_opus_xhigh_interactive_duration` 0.5-0.7× spec → 实测)
- **起床 first-read**:① 本 doc Q1-Q5 ② GDD:643 + ROADMAP:77-80 ③ AskUserQuestion 5 项拍板 ④ 起 spec(沿 p2_3_ascension_spec 体例)⑤ Batch 1-4 实装
