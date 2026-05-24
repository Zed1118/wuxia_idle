# P4.1 §12.2 帮派门派 Phase 0 地基预备(草案 · 不实装)

> 日期:2026-05-25 / 模型:Opus 4.7 high / ~30min(nightshift T21)
> 范围:Phase 0 6 维 grep + Q1-Q8 候选清单 + 默认决议草案
> 6h 挂机 nightshift T21 拓荒 P4.1 入口 · 主轴拍板留用户起床
> 上游引用:GDD.md(§7.1 师徒传承 + §12 接口)/ ROADMAP_1_0.md:209-216

## TL;DR

P4.1 = **§12.2 帮派门派**结构性扩展(member 模型 + 山头占领 territory + 门派内升迁 + member ↔ disciple/founder 角色对应)。**与已实装系统区分明确**:
- P1.1 收徒池(`SaveData.recruitmentOffered/recruitedDiscipleIds`)→ disciple 角色,非门派成员
- P3.4 sect_event(`Sect/SectEvent` Isar · sectLevel + sectReputation)→ 门派事件触发,非门派创建/成员管理
- P5+ 真传位(`AscendService.promotedDiscipleId`)→ 飞升传位 disciple,非招收外部 NPC 入派

**Phase 0 6 维 ~45% 利用率**(Sect/Character/UI 体例可复用 · SectMember/Territory/SectRank 0→1 新建)。**主轴未拍板**(SectMember schema 粒度 / Character.isInSect 复用 vs 独立 / Territory yaml 静态 vs Isar / sectRank 阶数 / 招收 trigger 维度 / sect_event 关联),本 doc 列 Q1-Q8 候选 + 默认决议草案给用户起床拍板。

## 1. Phase 0 6 维 grep 实测

### 1.1 schema 维(已有 vs 新建)

| 概念 | 现状 | 决议 |
|---|---|---|
| `Sect` Isar Collection | `lib/features/sect/domain/sect.dart`(name/founderId/sectLevel 1-7/sectReputation 0-100/totalWins/lastEventAt · P3.4 ship) | 复用扩展(本 task 加 `territoryIds: List<String>` + `memberCount: int` derived cache) |
| `Character.isFounder` + `LineageRole` enum | `lib/core/domain/character.dart:71` + `enums.dart:146`(founder/disciple)| 复用(P5+ 真传位已实装 · founder ↔ promotedDisciple 接管语义)|
| Member 关系 | **无**(P1.1 `recruitedDiscipleIds` 单层 disciple · 无 sect 隔离)| **新建**(Q2 双向 fk · Q3 复用 Character + `isInSect/sectId` 字段)|
| 山头占领 Territory | **无** | **新建 `data/territories.yaml` 静态 + `Sect.territoryIds` 动态 owner**(Q4)|
| sectRank 内升 | **无** | **新建 `SectRank` enum(初入/内门/长老 三阶 · Q5)** |

### 1.2 caller 维(谁会触发本 feature)

- 主线 stage_03_05 boss kill cleared → 解锁创建门派 hook(spec §3 创建入口)
- AscensionScreen 飞升后 `performAscend(promotedDiscipleId)` → 新祖师接管门派(P5+ 已 ship · sect.founderId rewire 由本 task 加 hook)
- P1.2(spec-only · 未 ship)江湖恩怨 enmity 累积 → 跨派系 member 招收 trigger(P1.2 落地后 wire)
- P3.4 sect_event `mission` 触发 → member 招收 hook(Q7=B mission 合流)

### 1.3 邻近目录维(类似 feature 已实装代码体例)

- `lib/features/sect/` P3.4 ship 全段(application 3 service · domain 4 file · presentation sect_screen + widgets)→ 本 task 沿同目录扩 SectMemberService / TerritoryService
- `lib/features/inheritance/application/founder_buff_service.dart` → disciple ↔ founder 关系 wire 体例参考(无 domain 子目录 · 纯 application service)
- `lib/features/encounter/` recruit 系列 encounter(P1.1)→ member 招收 trigger 体例(softProbability 公式 · `encounter_service.dart:216` fortune 软概率)

### 1.4 UI widget 维(现有 panel / list 体例)

- `lineage_panel_screen.dart`(三段式卡片 · disciple list + founder + heritage 体例)→ SectManagementScreen 卡片结构沿例
- `sect_screen.dart`(顶部 sectLevel + sectReputation + active/history TabBar)→ P3.4 sect_event 入口 · 本 task 加「管理」TabBar 第三段 OR 独立 panel(Q8)
- main_menu 入口数:**17**(nightshift context · base 14 + 江湖/PVP/Sect 3 入口)→ P4.1 加 1 = **18**(Q8=A 独立 panel)

### 1.5 红线层维(§5.x 数值不破)

- §5.4 红线:**不破**(本 feature 无新数值 multiplier · member buff 复用 founder_buff_service)
- §5.3 七阶锁:member 内升 sectRank 是否新阶? **决议**:Q5=A 三阶简化(初入/内门/长老 · 组织层阶位 ≠ 修炼境界,不触 §5.3 三系锁) · sectLevel 1-7 仍按 §5.3 沿用
- §5.1 反留存:**不破**(无每日招收任务 / 无 sect 签到)
- §5.5 在线=离线:**不破**(member 招收靠 encounter / stage_boss / sect_event mission trigger · 无后台累积)

### 1.6 公式真参战维(已有公式是否被影响)

- `damage_calculator`:**不破**(本 feature 无战斗 multiplier)
- `derived_stats`:**不破**(member 无属性加成 · 只组织层 · founder buff 已 P1.1 实装复用)
- `founder_buff_service`:**0 改**(现 `enabled_when_alive=true` 玩家=祖师自享 · P4.1 加 member 后自然扩 buff 作用域到 `isInSect=true && sectId==player.sectId` 全员,buff 公式不动)
- `BattleStrategy` / `BattleAi`:**0 改**

## 2. Q1-Q8 候选清单(默认决议草案 · 用户拍板)

| Q | 主轴 | 候选 | 默认决议 | 理由 |
|---|---|---|---|---|
| Q1 | feature 拆批 | A 一波 / B 4 batch(schema+service+UI+R5)/ C 多 phase 子系统串行 | **B 4 batch** | 沿 P1.2 spec B1-B4 体例 · 粒度合适 ~15-20h xhigh |
| Q2 | SectMember schema 粒度 | A 全 fk(独立 Member 实体 · sectId+characterId)/ B 嵌入 Sect(`List<int> memberCharacterIds`)/ C 双向 fk(`Character.sectId` + `Sect.memberCount cache`)| **C 双向 fk** | 查询性能 + 多 sect 隔离扩展性 · `Character.sectId` 字段沿 SaveData fk 体例 |
| Q3 | Member 模型 vs 独立 Member 实体 | A 复用 Character(加 `isInSect: bool` + `sectId: int?` + `sectRank: SectRank?`)/ B 独立 SectMember Isar 引用 Character / C 嵌入 Sect | **A 复用 Character** | 沿 P1.1 disciple/founder 体例 · 无需新实体 · 减 Isar Collection 数 |
| Q4 | Territory schema | A 静态 yaml + dynamic ownership(`Sect.territoryIds` 引 yaml id)/ B Isar Collection 全字段 / C 留 1.1 | **A 静态 yaml + dynamic owner** | Demo 4-6 territory 不需 Isar · 真 stage boss 占领 hook 留 1.1 |
| Q5 | sectRank 阶数 | A 三阶(初入/内门/长老)/ B 七阶沿 §5.3 / C 五阶 | **A 三阶** | 组织层阶位 ≠ 修炼境界 · 不开新七阶 anti-pattern · GDD §5.3 锁 |
| Q6 | 招收 member trigger | A encounter NPC 招收 / B stage_boss 失败收降 / C 主动 recruitment 入口 / D A+B+C 全开 | **D 全开** | 多维度 trigger · 沿 P1.1 recruitment 体例 · Demo 内容足量 |
| Q7 | 与 P3.4 sect_event 关联 | A 独立 / B mission 触发 → member 招收 hook / C 完全合并 | **B mission hook** | 复用 sect_event 框架不重写 · `SectEventType.mission` P3.4 已 stub 留 1.0 现激活 |
| Q8 | UI 入口 | A main_menu 单入口独立 panel / B 嵌 lineage_panel TabBar / C 嵌 sect_screen TabBar | **A 独立 panel** | 沿 PVP/Sect 单 panel 体例 · main_menu 第 18 入口 · 信息密度高拆出 |

## 3. 现有内容利用 vs 新建 ratio

| 子系统 | 现有 | 新建 | 利用率 |
|---|---|---|---|
| Sect 实体 | P3.4 ship | 加 `territoryIds` + `memberCount` 字段 | 80% |
| Character 关系字段 | isFounder/lineageRole/discipleIds | 加 `isInSect/sectId/sectRank` 字段 | 75% |
| SectMember 双向 fk | 无 | Character 端字段 + Sect 端 cache | 0%(新建)|
| Territory | 无 | 新 yaml `data/territories.yaml` + Sect.territoryIds | 0%(新建)|
| SectRank enum + 升迁 | 无 | 新 enum + SectMemberService | 0%(新建)|
| sect_event mission hook | P3.4 ship 但 stub(`mission` enum 占位 / 无 resolve 路径)| 激活 mission resolve + member 招收 hook | 40% |
| UI | lineage_panel + sect_screen 体例 | 新 sect_management_screen | 60% |
| founder_buff 扩作用域 | service 实装(`enabled_when_alive=true`)| 0 service 改 · 作用域自然扩到 `isInSect=true` 全员 | 100% |
| **平均** | | | **~45%**(合理 · 不是「半完成当 0→1」)|

## 4. 风险 / 挂账

- **R1**:**factions.yaml 当前不存在**(grep 实测) · P1.2 江湖恩怨 spec-only 未 ship。本 task 不依赖 factions.yaml,自创门派与「既有门派 NPC」概念隔离:`Character.sectId` 仅指向玩家 `Sect` 实例 · NPC 不入玩家 sect。P1.2 落地后再 wire 跨派系交互
- **R2**:**与 P5+ 真传位飞升语义冲突** — `AscendService.performAscend(promotedDiscipleId)` 已 ship `promotedDisciple.isFounder=true` + 旧 founder 保 `isFounder=true`。本 task 加 hook:飞升时 `sect.founderId` rewire 到新祖师,旧 member 关系保留(`Character.sectId` 不动)。**Q4 多代 sect 传递留 1.1**(Demo 不验证)
- **R3**:**Territory 占领系统未实装 stage boss 关联** — Demo 战斗未生成 territory owner change。**决议**:Q4=A 静态 yaml + Demo 4-6 territory 初始 owner 写死 yaml · 1.1+ 接 stage boss 占领触发
- **R4**:**sectRank 升迁触发条件未定** — 默认决议:totalWins 累积 + 玩家手动指派(沿 sectLevel 升级体例)· 自动升迁规则细化挂账 spec §3
- **R5**:**member 招收文案 narrative ~30 条挂账 1.1**(Demo 阶段 trigger logic 优先 · 文案占位 + 中文短句)

## 5. 不实装边界 · 估时 · 起床 first-read

- **不实装**:0 Isar schema 真改 / 0 `lib/features/sect_management/` / 0 `data/territories.yaml` / 0 enum / spec §0 Q1-Q8 默认决议草案留用户拍板
- **估时**:spec 起草 ~1h xhigh(本 task) + B1 schema 3-4h + B2 service 4-5h + B3 UI 4-5h + B4 R5+closeout 3-4h = **~15-20h xhigh**(memory `feedback_opus_xhigh_interactive_duration` 0.5-0.7× 系数 → 实测)
- **起床 first-read**:① 本 doc Q1-Q8 + 默认决议草案 ② spec doc §0 决议表 + §8 batch 拆分 ③ AskUserQuestion Q1-Q8 拍板(或全收默认决议直推 B1)④ 起新 worktree `feat/p4_1_sect_management_impl` 走 B1
