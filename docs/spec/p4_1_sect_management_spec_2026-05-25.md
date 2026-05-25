# P4.1 §12.2 帮派门派 spec(默认决议草案)

> 日期:2026-05-25 / 模型:Mac + Opus 4.7 xhigh / 估时 ~15-20h xhigh(B1 3-4h + B2 4-5h + B3 4-5h + B4 3-4h)
> 上游 Phase 0:`docs/phase0/p4_1_sect_management_phase0_2026-05-25.md`(Q1-Q8 候选 · 6 维 ~45% 利用)
> 沿例:`docs/spec/p1_2_jianghu_enmity_spec_2026-05-24.md`(148 行 · 9 章节)+ `docs/spec/p2_3_ascension_spec_2026-05-24.md`
> ⚠ **本 spec 基于 Q1-Q8「默认决议草案」起草** · 用户起床改 Q1-Q8 后改本文件 §0 表 + §2-7 局部即可,不需要重写。

---

## 0. Q1-Q8 决议(默认占位 · 用户拍板后填)

| Q | 主轴 | 默认决议 | 理由 |
|---|---|---|---|
| Q1 | feature 拆批 | **B 4 batch**(schema + service + UI + R5)| 沿 P1.2 spec B1-B4 体例 · 粒度合适 ~15-20h xhigh |
| Q2 | SectMember schema 粒度 | **C 双向 fk**(`Character.sectId` + `Sect.memberCount cache`)| 查询性能 + 多 sect 隔离扩展性 |
| Q3 | Member 模型 | **A 复用 Character**(加 `isInSect/sectId/sectRank` 字段)| 沿 P1.1 disciple/founder 体例 · 无需新 Isar 实体 |
| Q4 | Territory schema | **A 静态 yaml + dynamic owner**(`data/territories.yaml` + `Sect.territoryIds`)| Demo 4-6 territory 不需 Isar · 真 stage boss 占领 hook 留 1.1 |
| Q5 | sectRank 阶数 | **A 三阶**(初入 / 内门 / 长老)| 组织层阶位 ≠ 修炼境界 · 不开新七阶 anti-pattern · §5.3 锁 |
| Q6 | 招收 trigger | **D 全开**(encounter + stage_boss 收降 + 主动 recruitment 入口)| 多维度 · 沿 P1.1 recruitment 体例 |
| Q7 | P3.4 sect_event 关联 | **B mission hook**(`SectEventType.mission` 现激活 · resolve 时触发 member 招收)| 复用 sect_event 框架不重写 |
| Q8 | UI 入口 | **A 独立 panel**(main_menu 第 18 入口 `SectManagementScreen`)| 信息密度高拆出 · 沿 PVP/Sect 单 panel 体例 |

## 1. 范围

- **核心 deliverable**:① `Character.{sectId,isInSect,sectRank}` 3 字段(Q2+Q3+Q5)② `Sect.{territoryIds,memberCount}` 2 字段(Q2)③ `SectRank` enum 三阶(初入/内门/长老 · Q5)④ `SectMemberService`(招收/内升/退派 · Q6 D 全 trigger)⑤ `TerritoryService`(yaml 加载 + dynamic owner CRUD · Q4 A)⑥ `data/territories.yaml`(4-6 · static def + initialOwnerSectId)⑦ `SectManagementScreen` 三段式(Q8 A · main_menu 第 18 入口)⑧ `UiStrings` 12-15 段 ⑨ R5 红线 5-6 族
- **配套**:encounter_service 加 `affects_sect_membership` 字段(Q6 A)· battle_result_service stage_boss 失败 → 招降(Q6 B)· sect_event_service resolve mission → 招收候选(Q7 B)· founder_buff_service 0 改
- **范围 OUT**:Q4 真 stage_boss territory 占领 trigger 留 1.1 / Q5 sectRank 升迁规则细化留 1.1 / 多代 sect 传递语义留 1.1(本 task 加 founderId rewire hook · 但 member 跨代不验证)/ member 招收 narrative ~30 条留 1.1 / P1.2 跨派系 wire 留 P1.2 后

## 2. schema 改动

```dart
// lib/core/domain/character.dart(扩字段 · 沿 isFounder 体例 · 不改 factory 现签名,只加 named 可选参)
class Character {
  // ... 现有字段
  bool isInSect = false;            // 是否入派
  int? sectId;                       // 双向 fk → Sect.id(Q2 C · isInSect=true 时必非 null)
  @Enumerated(EnumType.name)
  SectRank? sectRank;                // 三阶(Q5 A · isInSect=true 时必非 null)
}

// lib/features/sect/domain/sect.dart(扩字段)
class Sect {
  // ... 现有字段(name/founderId/sectLevel/sectReputation/totalWins/lastEventAt)
  List<String> territoryIds = [];   // 引 data/territories.yaml id(Q4 A 静态 owner)
  int memberCount = 0;               // cache(Q2 C · SectMemberService writeTxn 时同步)
}

// lib/features/sect/domain/sect_rank.dart(新 enum · Q5 A 三阶)
enum SectRank {
  initiate,   // 初入
  inner,      // 内门
  elder,      // 长老
}
```

```yaml
# data/territories.yaml(新文件 · Q4 A · Demo 4-6 territory · 静态 def + dynamic owner 由 Sect.territoryIds 引)
- id: yan_zhi_shan
  name: "雁支山"
  description: "三流境界山贼聚居"
  baseDefenseLevel: 2          # 沿 §5.3 七阶映射
  initialOwnerSectId: null     # null = 中立无主 · int = 初始 owner(Demo 测试)
# ... 共 4-6 个 territory(hei_feng_zhai / ...)
```

```yaml
# data/numbers.yaml(尾部加 sect_management 段)
sect_management:
  member_cap:                       # 沿 sectLevel 1-7 阶递进
    by_sect_level: [3, 5, 8, 12, 18, 25, 35]
  rank_promote_threshold:           # 内升触发条件
    inner_min_contribution: 10       # totalWins 贡献阈值
    elder_min_contribution: 30
  recruit:
    encounter_base_prob: 0.15       # Q6 A · softProbability base
    stage_boss_fail_recover_prob: 0.30  # Q6 B · 失败收降概率
    mission_recruit_prob: 0.50      # Q7 B · sect_event mission resolve 触发
  territory:
    demo_initial_count: 6           # Q4 A · Demo 4-6 territory
    max_per_sect_by_level: [1, 2, 3, 5, 8, 12, 18]
```

> **不改 numbers.yaml**(实装时 B1 加) · 此处仅 schema 引用 `numbers.yaml.sect_management.<key>` 锚字段名。

## 3. SectMemberService + TerritoryService 设计(~180 行 · `lib/features/sect/application/`)

- **`SectMemberService`**(沿 `founder_buff_service.dart` provider 体例):
  - `recruit(targetCharacterId, sectId)` writeTxn:cap 校验(`sect.memberCount < by_sect_level[sectLevel-1]`) → target.{isInSect=true, sectId, sectRank=initiate} + sect.memberCount++ → 返 `RecruitResult.{success, fullCap, alreadyInSect}`
  - `promoteRank(characterId)`:totalWins ≥ threshold → initiate→inner→elder 单向不降阶
  - `dismiss(characterId)`:target 三字段清空 + sect.memberCount--
  - invalidate:`sectMembersProvider(sectId)` + `sectMemberCountProvider(sectId)`
- **`TerritoryService`**(沿 `numbers_config.dart` yaml 加载体例):
  - `loadDefs()` 启动加载 `data/territories.yaml` → `Map<String, TerritoryDef>` 静态 def
  - `ownerOf(territoryId) → int?` 查 sect.territoryIds 反向索引(Demo 单玩家 sect 简化 O(N) sweep)
  - `claim(sectId, territoryId)` writeTxn(sect.territoryIds.add + cap 校验)/ `release` / `availableForClaim()`
- **Trigger Hook**:① `EncounterIntegration`(Q6 A · `affects_sect_membership=recruit_candidate` → 候选入 UI 弹窗) ② `BattleResultService`(Q6 B · stage_boss 失败 + `recruitable=true` 软概率招降) ③ `SectEventService.resolveMission`(Q7 B · win → 50% rng 招收候选)

## 4. UI 接入(`lib/features/sect/presentation/sect_management_screen.dart`)

- **`SectManagementScreen`**(Q8 A · 沿 `lineage_panel_screen.dart` 三段式卡片)
  - **顶段**:sectName / sectLevel chip(7 阶 §5.3 色板)/ memberCount progress(`N / cap`)/ sectReputation chip(P3.4 已 ship)
  - **中段 Tab 1 member list**:ListView · 每行 character avatar / name / realmTier / sectRank chip(三阶颜色) / `promoteRank` 按钮(条件可见)/ `dismiss` 按钮 · 排序:sectRank elder→initiate · realm 降序
  - **中段 Tab 2 territory grid**:GridView 2 列 · 每格 territory name / baseDefenseLevel chip / 状态(已占领 / 中立 / `claim` 按钮)· 沿 `sect_screen.dart` 历史 TabBar 体例
  - **底段**:招收候选 list(`recruitmentOffered=true` candidates · 沿 P1.1 体例)+ 「主动招收」按钮(Q6 C · push `RecruitmentScreen` 已 ship)
- **main_menu 入口**(`lib/features/main_menu/presentation/main_menu.dart`):加第 18 entry「门派管理」· 条件可见:`sect != null && sect.founderId == playerId`(沿 sect_screen 入口判断体例)
- **`UiStrings`**(`lib/features/sect/presentation/widgets/` 或 i18n 集中):`sectManagementTitle` / `memberListLabel` / `territoryGridLabel` / `sectRankLabels[3]`(初入/内门/长老)/ `recruitButtonLabel` / `promoteRankSuccess` / `dismissConfirm` / `territoryClaimSuccess` / `memberCapReached` / `recruitFailedFullCap` 共 ~12-15 段

## 5. 联动(sect_event mission hook + 跨系统)

- **Q7=B mission hook**:`SectEventService.resolveMission` outcome=win → 50% rng(`mission_recruit_prob`)触发候选 → `recruitmentOffered=true` + UI 弹窗确认 → `SectMemberService.recruit`
- **P5+ 真传位 sect 接管**:`AscendService.performAscend(promotedDiscipleId)` 加 hook(B2 wire):若 sect.founderId==旧 founder.id 且 promotedDisciple!=null → sect.founderId rewire writeTxn。member 关系不动(旧 member 自然挂新 founder)。多代留 1.1
- **founder_buff_service 0 改**:作用域扩 `isInSect=true && sectId==player.sectId` 全员 · 加 isInSect 判断在 derived_stats 入口。**范围 OUT**:P1.2 跨派系 wire 留 P1.2 落地后

## 6. 数据流(yaml schema + 加载层)

- **`data/territories.yaml`**(新 · 4-6 territory)字段 `{id, name, description, baseDefenseLevel, initialOwnerSectId}` · 沿 `techniques.yaml` 列表体例 · 启动 `TerritoryService.loadDefs()` 解析
- **`numbers.yaml`**:加 `sect_management` 段(§2 列出 cap / promote / recruit / territory 4 子段)· 沿 `MassBattleConfig` 解析体例 · `NumbersConfig.sectManagement` 扩字段
- **Isar schema migration**:`Character` 加 3 字段 + `Sect` 加 2 字段 + `SectRank` enum → schema v 升 1 · 沿 P3.4 sect 升级体例(Isar `@collection` 自动 ALTER · 旧 save isInSect 默认 false / sectId/sectRank 默认 null · memberCount/territoryIds 默认 0/[])

## 7. R5 红线测族(~10-12 测 · `test/sect_management/`)

- **R5.1 招收 e2e**:recruit 后 target 三字段 + sect.memberCount++ 正确(1 测)/ 满 cap 拒绝(1 测)
- **R5.2 sectRank 升迁三阶单向**:initiate→inner→elder · 阈值不足拒绝(2 测)· 不可降阶(1 测)
- **R5.3 双向 fk 一致性**(Q2=C):`Character.sectId` 实例校验 · dismiss 后字段全 null + memberCount--(1 测)
- **R5.4 territory claim e2e**:claim 后 sect.territoryIds 含 id + availableForClaim 不含(1 测)/ cap 校验(1 测)
- **R5.5 §5.3 sectRank 不破七阶锁**:`SectRank.values.length==3` · 无 layer 嵌套 · 与 `RealmTier` schema 隔离(1 测 schema-level · **禁 grep 校验** 沿 P1.2 R5.6 体例)
- **R5.6 founder_buff 作用域扩**:isInSect=true && sectId==player.sectId → buff 激活;NPC 不享(2 测)
- **R5.7 P5+ 真传位 sect 接管**:performAscend(promotedDiscipleId) 后 sect.founderId rewire · 旧 founder.isFounder 保 true · member.sectId 不动(1 测 · 多代留 1.1)
- **baseline ~1297 + delta ~10-12**(B4 实测 · 沿 P1.2 体例)

## 8. Batch 拆分(估时 ~15-20h xhigh)

| Batch | 内容 | 估时 |
|---|---|---|
| B1 schema + yaml | Character 3 字段 + Sect 2 字段 + SectRank enum + `data/territories.yaml` + `numbers.yaml.sect_management` + `NumbersConfig.sectManagement` 解析 + Isar schema migration | ~3-4h |
| B2 service + trigger | `SectMemberService`(recruit/promote/dismiss)+ `TerritoryService`(loadDefs/claim/release)+ provider 4 项 + Q6 ABC 三 trigger hook 接入(encounter / battle_result / sect_event mission resolve)+ P5+ AscendService sect.founderId rewire hook + founder_buff_service derived_stats 作用域查询 isInSect=true 扩判断 | ~4-5h |
| B3 UI + main_menu | `SectManagementScreen` 三段式(顶/Tab member/Tab territory/底招收)+ main_menu 第 18 入口 + UiStrings 12-15 段 + 沿 lineage_panel 卡片体例 | ~4-5h |
| B4 R5 + closeout | R5.1-5.7 测族 + closeout doc + GDD §12.2 升档(占位 → P4.1 实装 ✅)+ PROGRESS 顶段 + ROADMAP P4.1 段(0% → 100%)+ stage_audit 1.0 复跑 | ~3-4h |

## 9. 估时 + 风险 + 挂账

- **估时**:B1 3-4h + B2 4-5h + B3 4-5h + B4 3-4h = **~15-20h xhigh**(对齐 phase0 估)
- **风险**:① Q4 真 stage_boss territory trigger 挂 1.1(Demo 静态 owner)② Q5 sectRank 升迁自动规则挂 1.1(Demo 手动) ③ 多代 sect 传递 R5.7 单代验 / 多代挂 1.1 ④ P1.2 跨派系 wire 留 P1.2 后 ⑤ member 招收 narrative ~30 条占位挂 1.1
- **不变量沿用**:§5.4 红线不动 · §5.3 三系锁死(sectRank 三阶 ≠ 修炼七阶) · §5.5 在线=离线 · §5.1 反留存 · BattleStrategy/DamageCalculator/founder_buff_service 0 改 · §6 公式不动
- **doc 体量**:本 spec ≤150 行 · B4 closeout ≤80 行 · PROGRESS 净增长 ≤ 0(memory `feedback_phase05_diagnose_before_solve`:R5 挂账时 B4 不直上候选)

---

**P4.1 spec 收口(默认决议草案)**:Q1=B / Q2=C / Q3=A / Q4=A / Q5=A / Q6=D / Q7=B / Q8=A · B1-B4 拆 · ~15-20h xhigh · ⚠ 用户改 Q1-Q8 后改 §0 + §2-7 局部 · 起 worktree `feat/p4_1_sect_management_impl` 走 B1
