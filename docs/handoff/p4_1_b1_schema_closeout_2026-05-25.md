# 会话 closeout · 2026-05-25 P4.1 §12.2 帮派门派 B1 schema

> 体量 ≤80 行 · Mac+Opus xhigh ~1h · spec `p4_1_sect_management_spec_2026-05-25` Q1-Q8 默认决议直推
> 范围:5 modified + 3 new = 8 file · `feat/p4_1_sect_management_b1_schema` branch
> 0 analyze · 1458 测全过(基线一致 · 0 regression)

## TL;DR

P4.1 4-batch 拆分第 1 批 schema-only 全闭环:`SectRank` enum 三阶(Q5=A)+ `Character` 加 `isInSect/sectId/sectRank` 3 字段(Q2=C 双向 fk + Q3=A 复用 Character)+ `Sect` 加 `territoryIds/memberCount` 2 字段 + `data/territories.yaml` 6 territory 跨 2-5 阶 + `numbers.yaml sect_management` 段 4 子段 + `NumbersConfig.sectManagement` 强类型(`SectManagementConfig` + 4 子类带 empty 兜底)+ `TerritoryDef` 静态 def + `GameRepository.territoryDefs` graceful 加载。speed 锚点 ×0.05-0.08(spec 估 3-4h · 实测 ~1h xhigh)。**B2 service + trigger / B3 UI / B4 R5+closeout 留下波**。

## 1. 改动一览

| 文件 | 改动 | 行数 |
|---|---|---|
| `lib/features/sect/domain/sect_rank.dart` | 新 enum 三阶(initiate/inner/elder) | 17 |
| `lib/features/sect/domain/territory_def.dart` | 新 def(id/name/description/baseDefenseLevel/initialOwnerSectId) | 36 |
| `data/territories.yaml` | 新文件 6 territory(yan_zhi_shan ~ tian_yuan_feng 跨 §5.3 阶 2-5) | 51 |
| `lib/core/domain/character.dart` | +3 字段(isInSect/sectId/sectRank)+ factory create 加 3 named 参 + import sect_rank | +25 |
| `lib/features/sect/domain/sect.dart` | +2 字段(territoryIds/memberCount) | +14 |
| `data/numbers.yaml` | 尾部 append `sect_management` 4 子段(member_cap/rank_promote_threshold/recruit/territory) | +20 |
| `lib/data/numbers_config.dart` | 加 SectManagementConfig + 4 子类(SectMemberCapConfig/SectRankPromoteThresholdConfig/SectRecruitConfig/SectTerritoryNumbersConfig)带 const empty + fromYaml + NumbersConfig 字段/构造/fromYaml wire | +160 |
| `lib/data/game_repository.dart` | import + `territoryDefs` 字段 + graceful 加载(沿 encounters/synergies 体例) | +25 |

## 2. 关键设计决议(对齐 spec Q1-Q8 默认草案)

- **Q2=C 双向 fk**:`Character.sectId` + `Sect.memberCount` cache,B2 SectMemberService writeTxn 同步维护。`Sect.memberCount` **不含 founder 本人**(founder 通过 `Sect.founderId` 索引,但 founder `Character.isInSect=true && sectId=this.id`)。
- **Q5=A 三阶组织阶位**:`SectRank.{initiate,inner,elder}` enum 注释明示**组织层 ≠ 修炼境界**,不破 §5.3 七阶锁。单向不可降阶 enforce 留 B2 SectMemberService.promoteRank。
- **Q4=A 静态 territory yaml**:6 territory 全 `initialOwnerSectId: null`(中立无主)。真 stage_boss 占领 trigger 留 1.1(spec §9 R3 / closeout §5)。
- **NumbersConfig empty 兜底**:5 子 Config 类全带 static const empty(数值与 yaml 默认值同),fixture / 老存档 yaml 无 `sect_management` 段时不破任何运行时行为。

## 3. Isar schema migration

`Character` 加 3 字段 + `Sect` 加 2 字段。build_runner 重生 `character.g.dart` / `sect.g.dart`(2 outputs · 6s)。Isar `@collection` 自动 ALTER,旧 save:
- `isInSect` 默认 false / `sectId` 默认 null / `sectRank` 默认 null
- `territoryIds` 默认 [] / `memberCount` 默认 0

测族 1458 全过(无 Isar 升级回归)。

## 4. 不变量沿用

- §5.4 数值红线不动(本 batch 无新数值 multiplier)· §5.3 七阶锁:sectRank 三阶组织层独立维度,**不破** RealmTier 七阶锁
- §5.5 在线=离线 / §5.1 反留存 不动
- doc 体量:本 closeout 80 行内 / PROGRESS 净增长 ≤ 0(本批顺手压 line 14-22 五段 nightshift v2 历史归档)
- 不动 GDD.md / CLAUDE.md(本批 schema 不需 GDD 升档,B4 closeout 统一升)

## 5. 挂账事项(对齐 spec §9 风险表)

- **B2 service**:SectMemberService(recruit/promote/dismiss)+ TerritoryService(loadDefs/claim/release)+ Q6 ABC 三 trigger hook 接入 + P5+ AscendService sect.founderId rewire hook + founder_buff 作用域扩
- **B3 UI**:SectManagementScreen 三段式 + main_menu 第 18 入口 + UiStrings ~12-15 段
- **B4 R5+closeout**:R5.1-5.7 测族 + GDD §12.2 升档(占位 → 实装 ✅)+ stage_audit 1.0 复跑
- **1.1 留**:真 stage_boss territory 占领 trigger(Q4 R3)/ sectRank 自动升迁规则(Q5 R4)/ 多代 sect 传递验证(R7 单代验)/ member 招收 narrative ~30 条占位

## 6. memory 影响

- 无新增 memory(本批照 spec 直推,无新教训沉淀)
- 沿用:`feedback_phase0_grep_two_axes`(B1 起草前 6 维 grep verify spec phase0 准 → 0 drift)/ `feedback_opus_xhigh_interactive_duration`(实测 0.30× 系数 · schema-only ×0.05-0.08 比 spec 估更快)

## 7. 下波(用户选)

| # | 候选 | 模型 | 时长 |
|---|---|---|---|
| 1 | P4.1 B2 service + trigger | xhigh | ~4-5h(spec 估 · 实测可能 ×0.3-0.5) |
| 2 | PR squash → main 后再起 B2 | — | ~5min |
| 3 | 切 B3 UI(B2 跳过)| xhigh | ~4-5h |
| 4 | 切别项目 | — | — |

**建议**:本会话 commit + push feature branch → PR squash merge 后再起新会话 B2。理由:① B1 schema-only 独立 commit 干净 ② B2 涉及 service + trigger 多触点,新会话上下文更轻。

---

**P4.1 B1 schema 闭环 ✅** · 5 modified + 3 new file · 8 commit 待打包(spec 估 3-4h · 实测 ~1h xhigh)
