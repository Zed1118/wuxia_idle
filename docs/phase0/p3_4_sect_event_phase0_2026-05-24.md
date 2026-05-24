# P3.4 门派事件 Phase 0 地基预备(草案 · 不实装)

> 日期:2026-05-24 凌晨 / 模型:Opus 4.7 high / ~1.5h
> 范围:Phase 0 6 维 reality check + P3.4 ↔ P1.2 依赖梳理 + spec Q&A 候选清单 + GDD §12.x 升档草案
> 8h overnight 流批 D · 主轴拍板留用户起床
> 上游引用:GDD.md:645,647,651 · ROADMAP_1_0.md:203-205,265,312 · numbers.yaml:1100-1133(sect_wide_buff 已隐式)

## TL;DR

P3.4 = **§12.1 门派事件**(地图上动态出现的门派冲突 / 武林大会 / 寻宝事件)。**Phase 0 6 维基本 greenfield**(0 Sect/SectEvent schema · 0 SectService · 0 SectScreen),**唯一隐式锚点**=`numbers.yaml:1107 sect_wide_buff`(P1.1 founder buff 借「门派」语义 · 仅 buff 不含事件 / 关系 / reputation)+ GDD:269「少林正宗」7 大门派典籍归类(纯文案 tag)。**P3.4 与 P1.2 弱耦合**(ROADMAP:205「与声望联动」),但 strong dep / soft dep / 独立 三种关系皆可成立,本 doc 不预设。主轴未拍板(sect 粒度 / 事件类型 / sect_reputation 维度 / 建筑层 / 与 P5+ 师徒整合),5 项 Q&A 候选起床拍板。

## Phase 0 6 维 reality check 结论

| 维度 | grep 命中 | 结论 |
|---|---|---|
| A schema(Sect / SectEvent / SectTask / SectBuilding / SectDisciple) | 0 hit lib/ | ✅ greenfield · 0 旧 schema 漂移 |
| B caller(SectService / enterSect / joinSect) | 0 hit | ✅ greenfield · 0 现有 service 破坏 |
| C 邻近系统 | `lib/features/inheritance/` 仅 `founder_buff_service.dart`(P5+ 师徒)· `numbers.yaml:1100-1133 sect_wide_buff`(P1.1 founder 借门派语义 · buff 不含事件 / 关系) | ⚠️ **半 greenfield** · sect 概念存于 yaml 「门派 buff」 + GDD 7 大门派典籍归类(269 行,纯文案 tag)· 0 实体类 / 0 service |
| D UI widget(SectPanel / SectEventScreen) | 0 hit | ✅ greenfield · UI 入口待设计(候选挂 MainMenu 平级 LineagePanelScreen) |
| E 红线层(GDD §12 / ROADMAP P3.4) | GDD:645 江湖恩怨「门派追杀」+ GDD:647 P3.4 占位 + GDD:651 P4.1 帮派门派(玩家自建)+ ROADMAP:203-205,265 P3.4 与声望联动 + ROADMAP:312 P1.2→P3.4→P4.1 依赖链 | ✅ 占位 OK · 设计自由度高 · §12.1 / §12.2 / P4.1 三者边界待 Q 厘清 |
| F 公式层 numbers.yaml(sect / event) | `sect_wide_buff:1107`(founder buff)+ `inheritance:1100+`(P5+ 师徒)· 0 `sect_event` / `sect_reputation` 段 | ⚠️ sect_wide_buff 名义占了「sect」keyword · P3.4 新段需避名冲突(候选 `sect_event:` `sect_affairs:`) |

## P3.4 ↔ P1.2 依赖梳理(3 维 · 不预设 strong coupling)

| 维度 | if P1.2 先 | if P3.4 先 | 备注 |
|---|---|---|---|
| **sect_reputation** | P3.4 复用 P1.2 reputation 字段(Q3.B/C)· 不重造 | P3.4 自带独立 sect_reputation 轴(Q3.A)· 1.1 与 P1.2 reputation 合表 | ROADMAP:205「与声望联动」← 指 P1.2 §12.2 声望,但语义层级 = 玩家行侠/行恶 ≠ 门派内的尊位,Q3 待拍板 |
| **NpcRelation** | P3.4 触发条件可用 P1.2 NpcRelation(eg. enmity ≥80 触发门派 raid)· 触发维度更丰富 | P3.4 触发仅基于境界 / 关卡进度 · 不依赖 NPC 关系 | P1.2 D 批 Q3.D 已列「Ch4-6 narrative 选项分支」触发,门派事件可同维度挂 |
| **触发链路** | 门派 raid / 武林大会**可由 P1.2 enmity / reputation 事件触发** | 门派事件**独立 cooldown / 关卡进度触发** · 无外部依赖 | 与 ROADMAP:312「P1.2 → P3.4 → P4.1」依赖链一致但**不强制 strong dep** |

**结论**:P3.4 **可独立实装**(if 选 Q3.A 独立 sect_reputation 轴 + Q2.A 比武大会主轴 + 触发独立 cooldown / 境界门槛 → 0 P1.2 依赖)· 也**可强依赖 P1.2**(if 选 Q3.B 共用 reputation + Q2.C 门派危机由 enmity 触发)· **主轴拍板见 Q3**。

## spec Q&A 候选清单(5 项 · 起床拍板 · **无推荐 · 主轴拍板留用户**)

| Q | 主轴 | 候选方案 |
|---|---|---|
| Q1 | sect 粒度 | A 玩家自建门派(Founder=开派祖师 · 沿 numbers.yaml:1107 sect_wide_buff 语义)/ B 加入既有门派(选少林 / 武当 / 峨眉... · 沿 GDD:269 7 大门派典籍)/ C 双轨可切(早期加入既有 · 高境界自立) |
| Q2 | sect_event 类型 | A 比武大会(每 N 月触发 · 全门派 PVP-lite)/ B 弟子任务(挂机外包 · sect 派 disciple 出任务回报资源)/ C 门派危机(防御战 · 敌对门派 raid 沿 P1.2 enmity)/ D A+B+C 全 |
| Q3 | sect_reputation 与 P1.2 声望关系 | A 独立轴(`sect_reputation` 单 sect 内尊位 0-100)/ B 共用 P1.2 reputation(玩家声望直接映射门派内地位)/ C P3.4 派生于 P1.2 NpcRelation(门派事件触发条件由 enmity / friendship 计算) |
| Q4 | sect_building 是否做 | A 是(主殿 / 藏经阁 / 演武场 建筑层 · 升级提供 buff)/ B 否(纯抽象 sect_level int · 无建筑 UI)/ C P3.4 否 · 留 P4.1 帮派门派统一做 |
| Q5 | 与 P5+ 师徒系统整合 | A sect 即 lineage(founder=掌门 · disciple=门人 · 共用现有 inheritance schema)/ B 独立(sect 包 founder + 多代 lineage + 外部 disciple)/ C P5+ 飞升后才解锁 sect 升级(Demo / 1.0 P1-P2 不开放 sect 自建) |

## GDD §12.x 升档草案(用户审稿)

§12.1.X P3.4:触发(月度 cooldown / 境界 ≥ 一流 / 主线进度门槛)· Isar `SectEvent` Collection(type enum tournament/mission/crisis · cooldown_days · trigger_realm · 与 P1.2 NpcRelation 弱关联)· UI 入口 SectEventScreen(挂 MainMenu 平级 LineagePanelScreen 或 PvPArchive 同级)· 影响 sect_reputation 与 sect_level(if Q4.A 建筑层)· 红线:不破 §5.4(sect_event 战斗复用 default ground strategy · 不引入新数值轴)· sect 命名空间避 `sect_wide_buff` 冲突(候选 `sect_event:` `sect_affairs:`)。

## 不实装边界 · 估时 · 起床 first-read

- **不实装**:0 Isar schema / 0 lib/features/sect / 0 data/sect / 0 enum / GDD §12.x 正式拍板留用户 / 0 numbers.yaml `sect_event` 段
- **估时**:spec ~45min + B1 schema 2-2.5h(if Q4.A 建筑层 +1h) + B2 trigger 2h + B3 UI 1.5h + B4 R5/doc 1.5h = **~7-9h opus xhigh**(memory `feedback_opus_xhigh_interactive_duration` 0.5-0.7× spec → 实测)
- **起床 first-read**:① 本 doc Q1-Q5 + 依赖梳理表 ② GDD:645,647 + ROADMAP:203-205,312 ③ AskUserQuestion 5 项拍板(Q3 决定是否阻塞 P1.2)④ 起 spec(沿 p2_3_ascension_spec 体例)⑤ Batch 1-4 实装
