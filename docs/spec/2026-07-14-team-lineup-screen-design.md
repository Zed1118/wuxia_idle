# 出战编成屏 · design spec(2026-07-14 用户拍板)

> backlog §十三 #4 收口。历史:06-27 祖师塑形批否过 → 06-29 进 rejected registry →
> 07-14 玩法评估用户重开 → 本日拍板。取代 `2026-07-05-team-lineup-ui-design-brief.md`
> (其「无第 4 人,做了=空 UI」前提已过时,见下现状)。

## 拍板记录(2026-07-14,三问三答)

| # | 问题 | 拍板 |
|---|---|---|
| 1 | 范围 | **C 完整编成屏**(独立界面,3 槽+替补池+角色对比;非最小 toggle) |
| 2 | 境界差/成长 | **纯编成不动成长**:编成屏如实展示差距,inactive 成长渠道留后续独立拍板;追赶补助仍在 rejected 不碰 |
| 3 | PR #36 观察① | **并入**(研习心法主/辅修选择流,范围收窄版见 §3) |

## 现状事实(拍板依据,2026-07-14 现查)

- 出战队 = `SaveData.activeCharacterIds` 固定 3 人(祖师 + join 管线 2 名命名弟子,
  `numbers.yaml:1990` disciple_joins 仅 2 条),战斗组队取前 3(`stage_battle_setup.dart:225`),
  全仓无 UI 可改。
- inactive 弟子池四条进入管线已实装,产出全部 `isActive: false`、不入出战列表:
  一流收徒 3 选 1(`recruitment_service.dart:103`)/ Boss 战胜招降 40%(`numbers.yaml:1917`)/
  战败收降 30% / 门派任务 50%(`sect_recruit_handler.dart:113`)。
- inactive 弟子唯一用途 = 门派谱/档案展示;不参与战斗/闭关经验,零成长(战斗经验只给出战队
  `combat_progression_settlement_service.dart:32`,闭关给闭关角色本人)——**只进不出,招降奖励感为空**。
- 换人是真策略维度:junior 控场 / senior 破绽集火 AI 分支(`battle_ai.dart:76`);
  slotIndex 有轻量战斗意义(同血量前排优先被集火,`battle_ai.dart:199-213`)+ 站位视觉。
- `save_data.dart:71` 注释早留口:「1.0 后续扩 active 上限时,可作为升级依据」。

## 1. 入口与布局

- 入口:门派谱(`LineagePanelScreen`)顶部动作位「出战编成」按钮 → 独立编成屏。主菜单不加入口。
- 布局:上半 **3 出战槽**(槽序=站位序,slot 0 标「前排」并注明更易被集火);
  下半**替补池**(全部 inactive 弟子卡片)。
- 交互:点替补卡→选出战槽交换;点出战卡→下场(校验通过时);出战卡间可互换槽序。
  **点选交换,不做拖拽**。
- 角色卡如实展示差距:名字 / 境界层 / 流派 / AI 倾向(senior 破绽集火 · junior 控场)/ 装备攻击。
  境界低于出战最低者的替补卡带弱势提示色,**只提示不拦截**。
- 替补池空态:一句引导文案(招降/收徒管线自然填充,守 §5.7 不做教程弹窗)。

## 2. 校验规则(存档写路径,核心风险面)

- 出战 1–3 人;**祖师(isFounder)必在**——founder buff 读 activeCharacterIds 找 founder
  (`founder_buff_service.dart:45`),祖师下场 = buff 静默消失 + 叙事怪。
- 仅非战斗态可改;**闭关中角色锁定**(灰显 +「闭关中」标注,防换下后闭关结算悬空;
  实装时以 seclusion session 结构现查为准)。
- **单一真相源收敛**:`activeCharacterIds`(列表序 = 站位序)为唯一真相,
  `Character.isActive` 为镜像随写路径同步。新建 `LineupService`(单事务)作为**编成操作**唯一写入口
  并保证镜像同步;join / recruitment 既有写点行为不动(各自测试已覆盖),不在本批重构。
- 保存后 invalidate `activeCharacterIdsProvider`(`post_combat_invalidation.dart:32` 同款),
  下场战斗自动生效——`stage_battle_setup` 已按此列表组队,战斗侧零改动。

> **实装订正(2026-07-15 实装批,as-implemented)**:
> ① 「仅非战斗态可改」落地为**路由结构性保证**——全仓无「战斗进行中」持久信号
> (战斗 roster 于 `StageBattleSetup._buildPlayerTeam` 进场时快照,结算 roster 由
> caller 传快照列表),编成屏与 BattleScreen 路由互斥,服务层不做(也无从做)战斗态校验。
> ② 校验矩阵补条:**加入者必须已修主修且 Technique 行在库**(镜像
> `stage_battle_setup._playerToBattle` 硬前置——否则换上后下一场战斗直接抛错;
> 既有出战成员不回溯,重排/移除不受影响)。设计期缺口,实装期编成→组队 wiring
> 回归测发现;替补卡「未修主修」标注+入口拦截,与 §3 择路流(研习立为主修)天然衔接。

## 3. PR #36 观察① 并入(范围收窄版)

- 研习新心法时:**无主修 → 弹「学为主修/辅修」选择**(消费预留的
  `UiStrings.learnTechniqueAsMain`);**有主修 → 维持现状仅辅修**(换主修 = 散功语义,
  走既有散功入口,本批零新散功路径)。

## 4. 红线与存档影响

- 零数值改动;零 schema / saveVersion(`activeCharacterIds` / `isActive` 均既有字段,零迁移)。
- 三系锁死无涉(换人不动装备/心法,上场弟子装备已按其境界锁);§5.1 反主流无涉;
  中文全进 `UiStrings`(§5.6)。

## 5. 测试

- 服务层:LineupService 校验矩阵(祖师必在 / 1–3 人 / 战斗态拒 / 闭关锁 / 交换与下场后
  列表序正确 / isActive 镜像同步)。
- widget:编成屏三态(正常 / 替补空 / 闭关锁定)+ 心法选择流两分支(无主修选主修 / 选辅修)。
- 回归:换人后 battle setup 组队与 founder buff per-character 重算;
  1280×720 / 1440×900 视觉 smoke。
- 触存档写路径 → 批末全量测试。

## 6. 明确不做(本批边界)

拖拽阵型 / inactive 成长渠道(后续独立拍板项)/ 追赶补助(rejected 维持)/ 战斗中换人 /
有主修时「学为主修」/ active 上限扩到 >3 / 站位数值化(前排减伤之类,slotIndex 现状语义不动)。

## 实装批建议

跨 lineage / battle / save 写路径 + 状态一致性,建议 **opus xhigh**;估 spec 已定、
实装 + 测试 0.5–1 天(编成屏 UI + LineupService + 选择流 + 测试矩阵)。
