# §12.1 心魔系统 Phase 0 reality check(1.0 P2.2 起步)

> 日期:2026-05-22 / 模型:Mac + Opus 4.7 xhigh
> 1.0 P2.2 §12.1 心魔系统(ROADMAP_1_0.md:110/200/247 / P2 阶段子任务,P2.1 主线 ✅ → P2.2 心魔 → P2.3 飞升)spec doc 起草前 5 维 reality check + 4 主轴拍板。**用户拍板 B+B+A 微调+B 组合,Phase 1 spec doc 起草接续**。

## TL;DR

5 维 grep 完成。codebase **0 心魔引用**(B 完全独立)。RealmTier 7 × RealmLayer 7 = 49 层均为 EXP 自动升层(`character_advancement_service.dart:30 applyExperience` while-loop),**0 玩家主动突破环节** → 心魔需新加 unlock 拦截 hook。`EncounterType.trial` 留 Phase 2+ 但**语义不合心魔**(必经突破非奇遇偶遇)→ stages.yaml 新 `stageType: innerDemon`。`BattleStrategy` 抽象 plug-in 就绪(`InnerDemonStrategy` 直接挂)。`EncounterBiome` 缺「心象」(新增 `innerRealm`)。

---

## 一 · 5 维 reality check 矩阵

| 维度 | 现状 | 心魔系统影响 |
|---|---|---|
| **D1 突破系统** | `character_advancement_service.dart:30 applyExperience` while-loop 自动消费 EXP 升层(`nextLayer` dengFeng → 下 tier qiMeng);**0 玩家主动突破环节**;dispel_service 散功公式 GDD §6 ×0.5 模板可参 | layer 升级前加 unlock 拦截 hook,若 lock → 弹「需先过心魔关」UI;**非破坏性扩展**(默认 unlock=true 不影响 Demo 全境界) |
| **D2 cultivation 邻近** | application 层 service(advancement / cultivation / synergy / technique_learning),无 domain layer 共用 | 新 `lib/features/inner_demon/` 模块(domain + application + presentation),与 cultivation 解耦但 application 层订阅 advancement hook |
| **D3 EncounterType** | `techniqueInsight / fortuneEvent / trial⭐ / karma⭐`,trial+karma 留 Phase 2+(战斗向+剧情向奇遇) | trial 复用语义不合(奇遇偶遇 vs 必经突破)→ **不复用 EncounterType**,走 stages.yaml 新 type |
| **D4 BattleStrategy** | abstract 3 method(tick / runToEnd / requestUltimate)无 mutable state plug-in 就绪;`DefaultGroundStrategy` 唯一实装 | `InnerDemonStrategy implements BattleStrategy` 直接挂;与 GDD §12.4.1 战斗形态扩 1→4 路线对齐 |
| **D5 EncounterBiome** | 17 个 biome(山道/客栈/...desert/frontier);desert 已 Ch4 复用 `stage_04_03 沙海迷踪` ✅ | 新增 `EncounterBiome.innerRealm` 1 项 |
| **D6 散功代价对照** | GDD §6 v1.1 散功公式:内力 ×0.5 / 主修修炼度 ×0.5 / 辅修不动 | 失败惩罚做阉割版 ×0.85 / ×0.9 + 临时「心魔余毒」debuff(闭关 8h 清) |
| **D7 Realm/Layer 枚举** | RealmTier 7(xueTu→wuSheng) × RealmLayer 7(qiMeng→**huaJing**→dengFeng;huaJing 第 6 位「化境」字面意提示)| 心魔触发拍板:wuSheng 内部 6 跨越点 + 1 飞升前置 = 7 关 |

---

## 二 · 4 主轴拍板(用户接受)

| # | 决策 | 拍板 | 理由 |
|---|---|---|---|
| 1 | 触发时机 | **B**(wuSheng 6 内部 + 1 飞升前置 = 7 关) | 严格「高境界」(GDD §12.1) + Ch6 飞升 hook 紧扣 + 节奏匀(Ch6 末 Boss → 自动 wuSheng·qiMeng → 6 内部突破 → 飞升前置 → A1 飞升 spec 接管) |
| 2 | 关卡形态 | **B**(stages.yaml 新 `stageType: innerDemon`) | 心魔必经突破非奇遇 → trial/encounter 语义不合;独立 stage_id + narrative + biome `innerRealm` + UI 「需先过心魔关」 |
| 3 | 数值模型 | **A 微调**(镜像自己 +10-20%) | 「直面自己」叙事最深 + 镜像略强解释「心魔比真我狡诈」 + 数值天然平衡不破 §5.4 + 内容投放成本最小 |
| 4 | 失败惩罚 | **B**(散功阉割版 + 心魔余毒 debuff) | 失败 = 内力 ×0.85 / 主修修炼度 ×0.9 + 闭关 8h 清「心魔余毒」debuff;有重量但柔和,与 §6 散功体系对齐,不破 §5.1 反留存焦虑 |

---

## 三 · 工程总量预估

- **schema**:stages.yaml 7 entries(`stage_inner_demon_01..07`)+ `EncounterBiome.innerRealm` + `StageType.innerDemon` 新枚举(待 Phase 1 spec 查现 stages.yaml type 字段)+ numbers.yaml `inner_demon` 段(镜像强化系数 / 失败惩罚系数 / unlock 触发点 7 配)
- **代码**:`lib/features/inner_demon/`(domain `InnerDemonDef` + `InnerDemonOutcome` + application `InnerDemonService` + `InnerDemonStrategy implements BattleStrategy` + presentation `InnerDemonScreen` + `InnerDemonBreakthroughBlocker`)+ `character_advancement_service` 加 unlock 拦截 hook(若 next layer 心魔关未过 → 阻断升层)
- **narrative**:`data/narratives/stages/inner_demon_01..07.yaml` 7 关 ~3,000-4,000 字(每关 opening + victory + defeat ~500 字)+ 可选 chapter-style 总章节文 ~800 字
- **测试**:R1 unit(InnerDemonService 拦截 hook)+ R2 integration(突破前置流程)+ R3 strategy(InnerDemonStrategy 镜像数值)+ R4 narrative(7 文件)+ R5 跨阶红线压测(镜像 +20% 不破 §5.4)
- **doc**:Phase 0(本文)+ Phase 1 spec + GDD §12.1 升档(`§12.1 未决项: 无` → `§12.1 心魔系统: 1.0 P2.2 spec 拍板`)+ ROADMAP P2.2 细化(本 spec 落地)+ PROGRESS 联动

## 四 · 估时(opus xhigh 单 context 锚点,memory `feedback_opus_xhigh_interactive_duration`)

- **Phase 0 doc**(本批):~20min ✅
- **Phase 1 spec doc**(≤150 行):~2-2.5h
- **Phase 2+ 实装**(spec 拍板后另起批次):~6-8h(对照 Ch6 ~3h,心魔多 strategy + 拦截 hook + UI 入口 +50-100%)

## 五 · spec 起草启动条件 ✅

- 用户拍板 4 主轴 ✅
- codebase 0 引用心魔(B 完全独立)✅
- D1-D7 矩阵完整 ✅
- 估时锚点对齐(opus xhigh 1.0-1.15×)✅
- §5.4 数值红线策略已锚定(镜像 +10-20% / 失败惩罚 ×0.85-0.9)✅

**Phase 1 spec doc 起草接续,详 `docs/handoff/p3_x_inner_demon_spec_2026-05-22.md`(待产)。**
