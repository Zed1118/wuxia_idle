# 挂机武侠 · 1.0 版本路线图

> **v1.2** · 修订日 2026-05-17 晚续 · 状态:**P0 阶段 4 项 100% 收口**(P0.1 #38 / P0.2 strategy 重构 / P0.3 #41 决议 + 新销账段 spec 起步段闭环)
> **v1.0** · 起草日 2026-05-17 · 状态:**已 launched(开发未启动,P0 待开工)**
> 决策来源会话:Mac + Opus 4.7,W18 起步段全收口当晚
> 路线图本身是规划文档,实际推进可能因实测调整 — 修订记录见末尾

---

## 总览

- **目标**:Demo(2026-05-17 W18 全收口)→ 1.0 Steam 买断版一次性上线
- **总时长估算**:**16 个月**(2026-06 → 2027-09)
- **上线节奏**:一次性 1.0 Steam 上线(不发 EA)
- **美术策略**:AI 出图为主(水墨风 LoRA),UI 仍 Flutter Widget
- **范围定位**:激进派(Demo + §12 大部分 + 上线打磨全套),留 §12.5 长期愿景给 2.0

### 时间线

| 阶段 | 月份 | 核心交付 | 关键里程碑 |
|---|---|---|---|
| **P0 数值前置 + 战斗 strategy 重构** | M1-M2 | #38 base maxHp 重平衡 + battle_engine 抽 strategy 层 | 数值红线全过 + strategy e2e 全过 |
| **P1 系统纵深 + 美术 PoC + DeepSeek 产能压测** | M2-M4 | A1 师徒 E.1/E.5 / A3 共鸣度 / A4 开锋 / 节日内容 / 江湖恩怨 / 声望 + 水墨 LoRA 训练 + 装备 35 张 | M4 美术 PoC 公开(LoRA 风格定稿) + DeepSeek 流程定稿 |
| **P2 第二条主线主战场** | M5-M10(**6 月**) | §12.4 第二条主线 3 章 15-20 关 / §12.1 心魔 / A1 飞升 E.2/E.3 + 遗物 transfer / 文案 +6-10k 字 / 装备 35→80 / 心法 21→50 / 典故 80→160 | M10 主线全跑通(一流→武圣) |
| **P3 战斗形态扩展** | M10-M12 | §12.3 轻功对决 / 群战守城 / Supabase PVP / 门派事件 | M12 战斗形态 3 种全交付 |
| **P4 社交收尾** | M12-M14 | §12.2 帮派门派 / 翻译(可选英文) | M14 全系统收口 |
| **P5 上线收尾** | M15-M16 | C1 教程 / C2 难度曲线 / C4 音乐音效配音 / C5 Steam 集成 / C6 时长校准 / Steam 上线 | M16 Steam 1.0 上线 |

### 关键决策记录(2026-05-17 用户拍板)

| 决策 | 选项 | 备注 |
|---|---|---|
| 1.0 范围定位 | 激进派(雄心版) | A + C + §12 大部分,留 §12.5 给 2.0 |
| 优先级偏好 | 三者并行,按依赖排 | 不设 上线/纵深/广度 单一优先 |
| 美术策略 | AI 出图(水墨风 LoRA) | M4 PoC 硬门槛 |
| 上线节奏 | 一次性 1.0 上线 | 不发 EA |
| 第二条主线工期 | 放宽到 5-6 月 | 从原 4 月 |
| §12 砍项 | 婚姻后代 + MOD 支持 | 全放 2.0 |
| Phase 5 第 7 批战斗 strategy | 插 P0 | 先付重构债再建战斗形态 |
| itch.io 中间发布砍 | 不走 itch.io | 2026-05-17 v1.1 决议:聚焦游戏本身,R6 对策改 P5.4b closed beta + Google 表单 + Steam Demo 版 |

---

## P0 数值前置 + 战斗 strategy 重构(M1-M2)

### P0.1 #38 base maxHp 重平衡
- **估时**:opus xhigh ~8-15h(完整 numbers.yaml + equipment.yaml 7 阶 × 装备 + 属性 + 内力维度全审)
- **产物**:
  - base maxHp ≤ 16667(让 hpPct 0.20 仍 ≤ §5.4 红线 20000)
  - 全维度数值压测(wushen + 满 attr + 神物装备 + 心法相生 cap 兜底)
  - 红线测试加 P0 压测 case(7 阶 × 3 流派 × 心法相生 5 组合矩阵)
- **前置依赖**:无(P0 起手)
- **阻塞影响**:P2 第二条主线扩到武圣体验路径全依赖此

### P0.2 battle_engine 抽 strategy 层 — **✅ 2026-05-17 销账**(v1.2)
- **实测**:Mac + Opus 4.7 xhigh ~2h(vs 预估 6-12h 快 3-5×,Batch 1+2 同会话续跑)
- **产物**(详 `docs/handoff/p0_battle_strategy_closeout_2026-05-17.md`):
  - `BattleStrategy` 抽象基类(3 method 粗粒度)+ `DefaultGroundStrategy`(地面 3v3 实装,11 method 搬迁公式零变化)
  - `BattleEngine` 改 facade(467 → 50 行)委派 const DefaultGroundStrategy()
  - `BattleNotifier` 接 strategy injection(_strategy instance field + startBattle 可选参数)
  - e2e 红线压测 `test/balance/battle_strategy_e2e_test.dart` 333 行 55 case(主线 15 + 爬塔 30 + 心法相生 5 + backwards compat 5,单文件 ~3s 全过)
- **commit 链(4 commit 全 push)**:`6748582` [arch] Phase 1 → `456349b` [refactor] Phase 2 → `14d62b1` [refactor] Phase 3 → `68a6365` [test] Phase 4
- **校正记录**:闭关地图实测 0 战斗(spec §2.4 reality check 修正原 R4 prompt "5 闭关地图战斗"误解)
- **阻塞解除**:P3 §12.3 三战斗形态(轻功 / 群战 / PVP)扩展时 implements BattleStrategy + startBattle 传自定义实装即可 plug-in,生产 4 callsite 不必改

> **P0.3 itch.io Demo 公开免费版** — **2026-05-17 v1.1 砍**(方案 C 决议):聚焦游戏本身,MSIX + itch.io + Sentry + Google 表单 5 项全推 P5.4b closed beta + Steam Demo 版。

---

## P1 系统纵深 + 美术 PoC + DeepSeek 产能压测(M2-M4)

### P1.1 A 类系统纵深
- A1 师徒系统真实化(E.1 收徒弹窗 / E.5 founder_ancestor_buff sect buff,sonnet 各 1-3h)
- A3 共鸣度满级体验完整化(joint_skill 表现层 / banner 时机 / 拆分提示,sonnet 2-4h)
- A4 开锋 3 槽 build 内容扩(审计每件装备开锋方案,sonnet 2h)

### P1.2 §12 独立模块组(与主线解耦)
- §12.4 节日活动:W16/W17 框架已建,补内容(DeepSeek 12 节日文案,~2 周)
- §12.1 江湖恩怨:NPC 关系网独立模块,数据 schema 设计 + Isar 持久化 + 触发条件(opus xhigh ~6-8h)
- §12.2 声望:独立累积值模块(行侠 / 行恶累积,影响 NPC 反应 / 剧情分支,opus high ~4-6h)

### P1.3 美术 PoC + LoRA 训练
- 水墨风 LoRA 训练(Stable Diffusion / Midjourney,~1 月,可与系统开发并行)
- 装备 35 张图首批出图(对照 Demo 现有 35 件)
- **M4 硬门槛**:风格统一度 / 上手识别度 / 数量节奏(35/80 装备)
- **失败分支**:M4 PoC fail → 触发外包 / 极简几何 决策

### P1.4 DeepSeek 产能压测
- Demo 期 DeepSeek 文案产能基线测算(3-5k 字 / ~3 周)
- 1.0 文案量 ~2x,需流程优化(批量派单模板 / 文案审计自动化)
- M4 末出 DeepSeek 产能优化文档 + 流程定稿

---

## P2 第二条主线主战场(M5-M10,6 月)

### P2.1 §12.4 第二条主线 3 章
- 主线 15-20 关(一流→绝顶→宗师→武圣,玩家境界路径) — **拟升档 25-30 关上限**(Ch4 已落 + Ch5/Ch6 spec 起草前正式拍板,GDD §8.4 Demo 表保持不动)
- DeepSeek 文案 +6-10k 字 — **Mac+Opus 单端文案产线(v1.8 CLAUDE.md 起 DeepSeek 退役)**
- 装备扩 35→80(每阶 5-7 件 → 全 7 阶 80 件)
- 心法扩 21→50(全 7 阶 × 3 流派,每阶 ~7 心法)
- 典故扩 80→160(每装备 2 段 anecdote → 7 阶 80 件 × 2 段)

**※ Ch4「西出阳关」P1 启动**(2026-05-21 桥头堡 ✅):yiLiu 全章 + 跨 jueDing·qiMeng 末 Boss(西凉霸主三人组 · 沉默克敌出手即决型 + 留 hook Ch5/Ch6 西凉小铜镜遗物)+ 西北边塞地理(玉门关 / 河西走廊 / 大漠 / 嘉峪关)+ ~5,880 字 narrative(10 段 stage v1 + 1 段 stage_04_04_defeat v1 + 1 段 stage_04_05_defeat v1)+ ~1,420 字 chapter_04 章首尾 v1。本批 ~50% P2.1 字数预算(预算 +6-10k 字 / Ch4 落 ~5,880,留 Ch5/Ch6 各 ~3,000)。详 spec `docs/handoff/p1_x_chapter4_spec_2026-05-21.md` + closeout `docs/handoff/p1_x_chapter4_phase2_batch1_closeout_2026-05-21.md`。

### P2.2 §12.1 心魔系统
- 高境界突破前心魔关卡(剧情化的内心战斗)
- 前置依赖:第二条主线推进到关键境界(绝顶 / 宗师)
- 数值平衡:心魔不应破 P0 数值红线

### P2.3 A1 飞升 + 遗物 transfer E.2/E.3
- E.2 武圣飞升 + 遗物 transfer:全部跨 cultivation / inheritance / character / equipment / save_data 模块,需写 transfer 流程 + ascendToWusheng trigger + 遗物逐件分配 UI(opus xhigh ~4h+)
- E.3 multi_disciple_allocation player_pick UI(sonnet ~2h)
- 前置依赖:第二条主线有 wushen 体验路径

---

## P3 战斗形态扩展(M10-M12)

### P3.1 §12.3 轻功对决
- 水面 / 屋脊 / 竹林特殊战斗形态
- BattleStrategy 抽象层挂 `LightFootStrategy`
- 数据:特殊地图 yaml + 轻功招式 yaml

### P3.2 §12.3 群战守城
- 5v5 或更大规模特殊关卡
- BattleStrategy 抽象层挂 `MassBattleStrategy`
- AI 行为:多角色协作(P0 strategy 层可能需要扩展协作接口)

### P3.3 §12.3 PVP(Supabase 异步)
- 排行榜模块已落(Demo 期),扩 PVP
- 异步:玩家阵容快照上传 → 其他玩家挑战
- BattleStrategy 抽象层挂 `PvpStrategy`(可能与 Default 共享 75%)

### P3.4 §12.1 门派事件
- 地图上动态出现的门派冲突 / 武林大会 / 寻宝事件
- 与 §12.2 声望联动(P1 已建立)

---

## P4 社交收尾(M12-M14)

### P4.1 §12.2 帮派门派
- 玩家创建门派可招收弟子 / 占领山头
- 与师徒系统 A1 升级链联动(P2 已实装飞升)
- 跨多个 service:CharacterRecruitmentService / SectService / TerritoryService

### P4.2 §12.4 翻译(可选英文)
- 英文翻译(主线 / UI / 系统提示)
- 决策点:M12 评估是否投入,可放 2.0

---

## P5 上线收尾(M15-M16)

### P5.1 C1 教程完整度审计
- GDD §10 三种引导方式(剧情 / 气泡提示 / 百科)全审计
- 新手 30 min 路径全跑通

### P5.2 C2 难度曲线打磨
- 30-35 关全玩家路径数值再平衡
- itch.io Demo 反馈(P0.3 收集)纳入数据源

### P5.3 C4 音乐音效配音
- BGM(主线 / 战斗 / 闭关)
- SFX(战斗 / UI)
- 配音(关键剧情)

### P5.4 C5 Steam 集成
- 成就 / 云存档 / 玩家统计
- 商品页 / 评测 / 锁国问题 / Demo 版策略
- **预留 1 月 buffer**(首次 Steam 上线 ops 类工作未压测)

### P5.4b R6 对策:closed beta + Google 表单 + Steam Demo 版(2026-05-17 v1.1 加)
- 招募 ~10 人 closed beta(测试玩家 / 论坛 / Discord)
- Google 表单结构化反馈(难度评分 / 数值 bug / 流程卡点 / 通关时长)
- Steam Demo 版上架(C5 子项):公开渠道补充,替代原 P0.3 itch.io 中间态
- MSIX 打包工具链 + Sentry release 监控接入(原 P0.3 砍项的内容全在此期落地)
- 数据源喂 P5.5 C6 内容时长校准 + P5.2 C2 难度曲线打磨
- **前置依赖**:Steam developer 账号 + Demo 版打包链路(P5.4 C5 完成)

### P5.5 C6 内容时长校准
- Demo ~5-10h → 1.0 目标 40-60h
- 校准方式:外部玩家测试(~10 人)平均通关时间

### P5.6 Steam 1.0 上线
- 商品上架 / Demo 版上架 / 首发活动

---

## §12 范围决议表

| GDD §12 子项 | 1.0 范围 | 阶段 | 备注 |
|---|---|---|---|
| §12.1 江湖恩怨 | ✅ 1.0 | P1 | 独立 NPC 关系网模块 |
| §12.1 心魔系统 | ✅ 1.0 | P2 | 依赖第二条主线 |
| §12.1 门派事件 | ✅ 1.0 | P3 | 与声望联动 |
| §12.2 帮派门派 | ✅ 1.0 | P4 | |
| §12.2 婚姻后代 | ❌ 2.0 | -- | **本批砍** |
| §12.2 声望 | ✅ 1.0 | P1 | 独立累积值模块 |
| §12.3 轻功对决 | ✅ 1.0 | P3 | strategy 层 P0 准备 |
| §12.3 群战守城 | ✅ 1.0 | P3 | strategy 层 P0 准备 |
| §12.3 PVP(异步) | ✅ 1.0 | P3 | strategy 层 P0 准备 |
| §12.4 第二条主线 | ✅ 1.0 | P2 | 6 月,放宽 |
| §12.4 节日活动 | ✅ 1.0 | P1 | W16/W17 框架已建 |
| §12.4 MOD 支持 | ❌ 2.0 | -- | **本批砍** |
| §12.4 翻译英文 | ✅ 1.0 | P4 | 可选,M12 评估 |
| §12.5 角色寿命传承 | ❌ 2.0 | -- | 长期愿景 |
| §12.5 江湖编年史 | ❌ 2.0 | -- | 长期愿景 |
| §12.5 跨周目元数据 | ❌ 2.0 | -- | 长期愿景 |

---

## Demo → 1.0 内容 delta 表

| 维度 | Demo | 1.0 目标 | 倍数 |
|---|---|---|---|
| 主线关卡 | 15 | 30-35 | 2x |
| 章节 | 3 | 6 | 2x |
| 主线文字 | 3-5k | 6-10k | 2x |
| 装备 | 35 | 80 | 2.3x |
| 心法 | 21 | 50 | 2.4x |
| 典故 | 80 段 | 160 段 | 2x |
| 武学领悟 | 35 招 + 20 触发 | 70 招 + 40 触发 | 2x |
| 心法相生 | 5 组合 | 10-15 组合 | 2-3x |
| 师徒角色 | 3 硬种 | 飞升传承动态扩展 | 系统级 |
| 战斗形态 | 1(地面 3v3) | 4(地面 + 轻功 + 群战 + PVP) | 4x |
| 社交系统 | 0 | 4(帮派 / 声望 / 江湖恩怨 / 门派事件) | 0→4 |
| 内容时长 | ~5-10h | ~40-60h | 4-6x |
| 美术 | 0(几何 UI) | AI 出图水墨风全套 | 0→1 |
| 音频 | 0 | 配音(关键剧情)+ BGM + SFX | 0→1 |

---

## 关键依赖图

```
P0.1 #38 ──────→ P2 第二条主线(扩到 wushen 必须 base ≤ 16667)
P0.2 strategy 层 ──→ P3 §12.3 战斗形态扩展(3 种新形态全挂 strategy)
P5.4b closed beta + Steam Demo ──→ P5.2 C2 难度曲线打磨(外部反馈数据源,2026-05-17 v1.1 改)
P1.3 美术 PoC ───→ P1-P5 全程美术出图(节奏伴生)
P1.4 DeepSeek 产能 ──→ P2 文案大扩
P2.1 主线推进 ───→ P2.2 心魔(突破前置) ──→ P2.3 飞升 + 遗物 transfer
P1.2 江湖恩怨 + 声望 ──→ P3.4 门派事件 ──→ P4.1 帮派门派
P2 文案大扩 ────→ P4.2 翻译(可选)
全程 P1-P4 ─────→ P5 上线收尾
```

---

## 风险列表(按风险度排序)

1. **R1 AI 美术风格一致性 + 节奏脱节**(最高):水墨 LoRA M4 PoC 不达标 → P1 后半要重新决策(外包 / 极简几何)。**M4 设硬门槛**。
2. **R2 第二条主线文案量爆炸**:已放宽到 6 月分配 + DeepSeek 产能 P1 期压测,降低风险但仍是单线工期最长项。
3. **R3 #38 数值平衡级联**:base maxHp 改完带动全维度,P0 估时建议 opus xhigh **8-15h**(不是 2-3h)。
4. **R4 P0 Phase 5 第 7 批 strategy 重构成本未压测**:battle_engine.dart 当前是单形态专写,抽 strategy 层涉及 damage_calculator / battle_state / battle_runner 全链路。**预估 opus xhigh 6-12h**,P0 早期 design review 决定是否分 2-3 batch 渐进迁移。
5. **R5 Steam 集成 + 商品上线**:首次在 Steam 发游戏,**P5 留 1 月 buffer**。
6. **R6 数值打磨需外部玩家测试**:对策 = **P5.4b closed beta(~10 人 + Google 表单结构化反馈) + Steam Demo 版公开渠道补充**(2026-05-17 v1.1 砍 P0.3 itch.io 中间态后改)。P0/P1/P2 内部 dogfood + 数值红线测试 + Phase 0 reality check 兜底,不依赖中间态公开发布。

---

## 2.0+ 留项

- §12.2 婚姻后代(本批砍)
- §12.4 MOD 支持(本批砍)
- §12.5 全部:角色寿命传承 / 江湖编年史 / 跨周目元数据
- 多平台扩展:Mac / Linux / Switch
- 长期运营:DLC / 资料片 / 持续更新

---

## 修订记录

- **v1.2**(2026-05-17 晚续,P0 strategy 重构销账):Mac + Opus 4.7 xhigh ~2h(vs 6-12h 预估快 3-5×),Batch 1+2 同会话续跑。① P0.2 段从「待开工」改为销账(实测 + 产物清单 + 4 commit 链 + 校正记录:闭关地图实测 0 战斗);② P0 阶段 4 项 100% 收口(P0.1 / P0.2 / P0.3 决议 + 新销账)。详 closeout `docs/handoff/p0_battle_strategy_closeout_2026-05-17.md`。
- **v1.1**(2026-05-17 晚续,#41 决议方案 C):Mac + Opus 4.7,「聚焦游戏本身」原则下决议方案 C 砍 P0.3 itch.io Demo 公开整段。① 删 P0.3 段(MSIX + itch.io + Sentry + Google 表单 5 项推 P5.4b);② R6 对策改 P5.4b closed beta + Google 表单 + Steam Demo 版;③ 关键决策记录加「itch.io 中间发布砍」条 + 时间线表 P0 交付物移除 itch.io Demo;④ 加 P5.4b 新段;⑤ 依赖图更新;⑥ PROGRESS #41 从挂账段删除归档。**P0 真正剩余 1 项:battle_engine 抽 strategy 层重构**(原 P0.2 升回 P0,opus xhigh 6-12h)。
- **v1.0**(2026-05-17,起草):Mac + Opus 4.7 起草,W18 起步段全收口当晚。用户拍板:激进派 + 三者并行按依赖排 + AI 美术 + 一次性 1.0 上线 + 第二条主线放宽 5-6 月 + 砍婚姻后代 + 砍 MOD + Phase 5 第 7 批插 P0 + itch.io Demo 纳入 P0。
