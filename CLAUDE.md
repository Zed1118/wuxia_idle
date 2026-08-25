# CLAUDE.md

> Claude Code 启动必读。本文件用最小篇幅让你立刻能在本项目中正确工作。
> 任何细节冲突时，以 [`GDD.md`](./GDD.md) 为准；本文件提供操作层指引。
> 内容文案规范见 GDD §6.6 装备典故 / §10.2 江湖见闻录 / `data/lore/_templates/` 既有体例(原 `WINDOWS_DEEPSEEK_GUIDE.md` 已归档 `docs/_archive/`,2026-05-19 协作模式切换 Mac+Opus 单端接管文案后退役)。
>
> **版本:v1.84**
>
> v1.84 变更摘要(2026-08-25 二阶段 M6 断魂庄亲战结算报告生产纵切):断魂庄 live controller 与 headless runner 现从同一 Phase 0A 终态生成共享 settlement，`GauntletService` 在推进关次的同一事务内复核实际单人、HP 检查点、装备和心法并调用 `CombatResolutionService`；装备战斗次数与招式使用归实际参与者。逐关不重复伤势/经验/领悟/奖励/补给，胜利页显示真实亲历者，悬空或错人 fail closed，随机源由 `rngProvider` 注入。旧多人待选奖存档保持恢复路径。该纵切只关闭断魂庄共享账本/参与者报告子门，不晋升 M6/二阶段，不改 schema/saveVersion、YAML、调优、奖励、经济、解锁、叙事或战斗规则。
>
> v1.83 变更摘要(2026-08-25 二阶段 M6 九霄塔实际参与者生产纵切):九霄塔每次挑战现从当前掌门与当代存活门人逐次选一名 eligible 空闲角色，同一角色 ID 经真实 `Phase0aTowerBattleHost` exact snapshot 进入战斗；胜负 settlement 均校验单一实际参与者，成长、伤势、装备 battleCount 与心法使用写回该角色。身份/代际、死亡、疗养、无主修、闭关/远征/断魂庄占用、悬空装备或错人 settlement 均 fail closed，不回退掌门；塔层、周目、首通奖励、重打、排行榜与仪式不变。该纵切只关闭塔逐次选人和既有个人战斗账本归属子门；每角色塔层最好成绩仍因缺持久模型保持 BLOCKED，不晋升 M6/二阶段，不改 schema/saveVersion、YAML、调优、奖励、经济、解锁或叙事。
>
> v1.82 变更摘要(2026-08-25 二阶段 M6 掌门支线准入生产纵切):百草岭与断魂庄的真实候选页、地点详情和写事务现允许存活、空闲且有主修的当前掌门参与；掌门身份经 `CurrentLeaderResolver` 核实，占用经 `CharacterOccupancyService` 在 provider 与 service 两层复核。无效/悬空掌门、历史祖师、死亡、无主修、闭关或活动重复占用均 fail closed，不回退其他角色。原单人、方针、周目、补给、恢复、战斗、离线推进、结算、召回、奖励和返程不变。本纵切只关闭掌门参加两项支线的 M6 必要子门，不晋升 U08/M6/二阶段；零 schema/saveVersion、YAML、调优、奖励、经济、解锁、叙事或战斗变更。
>
> v1.81 变更摘要(2026-08-25 二阶段 M6 U08 门人调度当前态纵切):宗门 Hub 与门派谱两个生产入口已从旧 `TeamLineupScreen` 切到只读 `DiscipleSchedulingScreen`，不再暴露全局三席编成写路。当前掌门经 `CurrentLeaderResolver` 核实，当代门人沿既有门派谱口径组合直系列表、`masterId` 及 active/recruited 兼容引用，闭关/百草岭/断魂庄仅读 `CharacterOccupancyService`。无效掌门、悬空当代成员、掌门直系列表跨代、重复占用或 provider 异常均 fail closed。新页不写 `activeCharacterIds` / `isActive`，参与者仍由各活动入口逐次选择；旧屏与 `LineupService` 只留兼容/debug。本纵切只关闭 U08 的必要生产子门，不新增差遣策略，不晋升 U08/M6/二阶段；零业务写入、schema/saveVersion、YAML、调优、奖励、经济、解锁或战斗变更。
>
> v1.80 变更摘要(2026-08-25 二阶段 M6 U06 江湖恩怨统一地点详情纵切):江湖地图“江湖恩怨”现先进入统一地点详情，只读第一章生产解锁门、六门派定义、稀疏持久声望、七阶连续区间与现有 Boss/互动声望来源；未产生记录的门派明确保持未记录，不补零。缺少生产 repository/service、门派数不是六个、门派/七阶/trigger/持久行异常或 provider 错误均 fail closed 且无 CTA；详情 CTA 仍进入原 `ReputationPanelScreen`，声望写入、clamp、阶位、Boss/encounter 触发、NPC 关系战斗语义与原面板不变。本纵切不猜测当前角色或 NPC 仇敌数量，不新增关系面板或参与者 policy，只关闭当前六地点统一详情首轮覆盖；U06/U14/M6/二阶段仍开放；零 schema/saveVersion、YAML、调优、奖励、经济或战斗变更。
>
> v1.79 变更摘要(2026-08-25 二阶段 M6 U06 百草岭统一地点详情纵切):江湖地图百草岭现先进入统一地点详情，只读生产解锁门、历史/进行中深度、战败、方针、周目、敌队、节点时长、实际奖励类别、候选人与进行中真实参与者，明确基础推荐境界、当前仅单名非祖师门人差遣和占用。隐藏门、配置/奖励、进度、候选、参与者或 provider 异常均 fail closed 且无 CTA；legacy 周目 0 按第一周目展示。idle/active CTA 均进入原 `ExpeditionOverviewScreen`，原选人、方针、周目、离线推进、召回、结算与返程不变。本纵切不新增亲战、前台 bot、多人、新自动化、参与者 policy 或渐进解锁，只关闭百草岭地点详情首缺口；声望详情、U06/U14/M5/M6/二阶段仍开放；零 schema/saveVersion、YAML、调优、奖励、经济或战斗变更。
>
> v1.78 变更摘要(2026-08-25 二阶段 M6 U06 断魂庄统一地点详情纵切):江湖地图断魂庄现先进入统一地点详情，只读生产解锁门、庄局进度、断魂帖/补给、真实候选人与进行中参与者，展示基础推荐境界、三关敌方生态、首通/失败奖励、当前可用人选、亲战方式与会话占用。隐藏门、配置/引用、参与者或 provider 异常均 fail closed 且无 CTA；进行中庄局保留原恢复入口。CTA 仍直接进入 `GauntletLoadoutScreen`，原选人、补给、周目、恢复、战斗、结算与奖励选择不变。本纵切不新增差遣、前台 bot、自动化、参与者 policy 或渐进解锁，只关闭断魂庄地点详情首缺口；其他地点详情、U06/U14/M5/M6/二阶段仍开放；零 schema/saveVersion、YAML、调优、奖励、经济或战斗变更。
>
> v1.77 变更摘要(2026-08-25 二阶段 M6 U06 守城统一地点详情纵切):江湖地图守城试炼现先进入统一地点详情，只读生产解锁链、连续进度与下一可挑战关，展示推荐境界、推荐阵型、波次/敌数、敌方姓名/流派、掉落/修为和经 `CurrentLeaderResolver` 核实的当前掌门。非法图(多根、汇合、环、截断)、关卡配置不一致、未解锁、身份或 provider 异常均 fail closed 且无 CTA；五关全通保留重打。CTA 仍经 `guardBattleEntry` 进入 `MassBattleScreen`，原阵型选择、周目与战斗流不变。本纵切不新增角色选择、派遣、自动化、持久占用或渐进解锁，只关闭守城地点详情首缺口；其他地点详情、U06/U14/M5/M6/二阶段仍开放；零 schema/saveVersion、YAML、调优、奖励、经济或战斗变更。
>
> v1.76 变更摘要(2026-08-25 二阶段 M6 U06 轻功统一地点详情纵切):江湖地图轻功试炼现先进入统一地点详情，只读生产解锁链、连续进度与下一可挑战关，展示推荐境界、路线地形、敌方姓名/流派、掉落/修为和经 `CurrentLeaderResolver` 核实的当前掌门。非法图(多根、汇合、环、截断)、未解锁、身份或 provider 异常均 fail closed 且无 CTA；五路全通保留重打。CTA 仍经 `guardBattleEntry` 进入 `LightFootScreen`。本纵切不新增角色选择、派遣、自动化、持久占用或渐进解锁决策，只关闭轻功地点详情首缺口；其他地点详情、U06/U14/M5/M6/二阶段仍开放；零 schema/saveVersion、YAML、调优、奖励、经济或战斗变更。
>
> v1.75 变更摘要(2026-08-25 二阶段 M6 主菜单“当前要事”精确角色路由纵切):闭关、伤势与突破摘要现携带真实 active roster 角色；闭关同时携带角色境界。点击前重新核验 active roster、角色实体及闭关 session/境界，缺失、非正数、悬空、重复或 provider 异常均 fail closed，不再回退角色 1。摘要优先级、文案、最多五项、桃花岛/主线路由与业务规则不变。本纵切只关闭当前要事角色路由缺口，U05/U06/U07/M6/二阶段仍开放；零 schema/saveVersion、YAML、调优、数值、奖励、经济或解锁变更。
>
> v1.74 变更摘要(2026-08-25 二阶段 M6 U06 九霄塔统一地点详情首纵切):江湖地图九霄塔现先进入统一地点详情，只读生产塔进度与下一层配置，展示推荐境界、敌方姓名/流派、首通掉落与基础修为；实际参与者经 `CurrentLeaderResolver` 解析并与真实塔战 Host 一致。身份、进度或 provider 异常时 fail closed 且无进入 CTA；登顶明确无下一层但保留重打。详情 CTA 仍经 `guardBattleEntry` 进入 `TowerFloorListScreen`。本纵切不新增派遣、自动化、持久占用或 U14 决策，只关闭九霄塔地点详情首缺口；其余地点详情、U06/U14/M6/二阶段仍开放；零 schema/saveVersion、YAML、调优、数值、奖励、经济或解锁变更。
>
> v1.73 变更摘要(2026-08-25 二阶段 M6 U07 宗门行止当前态纵切):宗门 Hub 顶部新增只读“宗门行止”，真实掌门经 `CurrentLeaderResolver` 解析，门人闭关/百草岭/断魂庄占用经 `CharacterOccupancyService` 聚合，远征深度/战败与断魂庄关次/阶段只读既有 active provider。掌门指针缺失、悬空、重复占用或占用角色悬空均 fail closed，不猜测身份。原七条宗门路由/门控不变；不新增疗伤/听剑占用，不恢复已拒绝的统一完成报告。本纵切只关闭 U07 当前态摘要首缺口，U07/M6/二阶段仍开放；零业务写入、schema/saveVersion、YAML、调优、奖励、经济或解锁变更。
>
> v1.72 变更摘要(2026-08-25 二阶段 M6 U06 江湖地图声望第六地点纵切):“江湖恩怨”从主菜单平铺区迁为江湖地图第六个生产地点；锁定与开放继续复用 `kFirstChapterFinalStageId`，数据未决或异常时 fail closed，点击仍进入既有 `ReputationPanelScreen`。宗门 Hub 仍消费同一社交门槛，江湖商店保持主菜单条件入口。本纵切只关闭声望地点归位缺口；统一地点详情、U06/U14/M6/二阶段仍开放；零 schema/saveVersion、YAML、调优、声望算法、奖励、经济或解锁变更。
>
> v1.71 变更摘要(2026-08-25 二阶段 M6 U05 九霄塔排行榜归位纵切):本地排行榜从九霄塔标题栏重新获得生产入口，点击复用既有 `LeaderboardScreen`，继续只读 `towerProgressProvider` 的最高层、最佳耗时、挑战次数和派生胜率。主菜单不恢复平铺入口，江湖纪事仍为六类。本纵切只关闭排行榜归位缺口，不晋升 U05/U06/M6/二阶段；`LeaderboardSyncService` 仍为 Noop，零 cloud/account/network、schema/saveVersion、YAML、调优、奖励、经济或解锁变更。
>
> v1.70 变更摘要(2026-08-25 二阶段 M6 U06 江湖地图百草岭远征第五地点纵切):“百草岭”作为江湖地图第五个生产地点；可见性只读既有 `jianghuJourneyUnlocked` 隐藏门，未决或异常时 fail closed，active 状态只读 `activeExpeditionProvider`，点击仍直达 `ExpeditionOverviewScreen`。宗门 Hub 的远征派遣/管理入口保留，与地图共享同一生产页。本纵切只关闭百草岭第五地点缺口；其他地点、统一地点详情、U06/U14/M5/M6/二阶段仍开放；零 schema/saveVersion、YAML、调优、数值、参与者、占用、奖励、经济、解锁或离线推进变更。
>
> v1.69 变更摘要(2026-08-25 二阶段 M6 U06 江湖地图断魂庄第四地点纵切):“断魂庄”从主菜单平铺区迁为江湖地图第四个生产地点；可见性只读既有 `jianghuJourneyUnlocked` 隐藏门，未决或异常时 fail closed，进行中状态只读 `activeGauntletProvider`，点击仍直达 `GauntletLoadoutScreen` 并由原页处理恢复。本纵切只关闭断魂庄第四地点缺口；其他地点、统一地点详情、U06/U14/M5/M6/二阶段仍开放；零 schema/saveVersion、YAML、调优、数值、参与者、奖励、经济、解锁或叙事变更，不开放前台 bot 或代选奖励。
>
> v1.68 变更摘要(2026-08-25 二阶段 M6 U06 江湖地图守城第三地点纵切):“守城试炼”从主菜单平铺区迁为江湖地图第三个生产地点；锁定与五关进度只从 `MainlineProgress`、`MassBattleService` 和生产配置派生，数据未决或链异常时 fail closed，点击仍经 `guardBattleEntry` 进入 `MassBattleScreen`。本纵切只关闭守城第三地点缺口；其他地点、统一地点详情、U06/U14/M5/M6/二阶段仍开放；零 schema/saveVersion、YAML、数值、阵型、概率、奖励、经济、解锁或叙事变更。
>
> v1.67 变更摘要(2026-08-25 二阶段 M6 U06 江湖地图轻功第二地点纵切):“轻功试炼”从主菜单平铺区迁为江湖地图第二个生产地点；锁定与五关进度只从 `MainlineProgress`、`LightFootService` 和生产配置派生，数据未决或链异常时 fail closed，点击仍经 `guardBattleEntry` 进入 `LightFootScreen`。本纵切只关闭轻功第二地点缺口；群战等其他地点、统一地点详情、U06/U14/M5/M6/二阶段仍开放；零 schema/saveVersion、YAML、数值、概率、奖励、经济、解锁或叙事变更。
>
> v1.66 变更摘要(2026-08-25 二阶段 M6 U06 江湖地图九霄塔首地点纵切):“继续江湖”仍保持直达当前关的一级主动作，同卡片内新增次级“江湖地图”动作，未增加第五个一级卡片。九霄塔从主菜单平铺区迁为地图首个生产地点，进度仍消费原塔生产数据，点击继续经 `guardBattleEntry` 进入 `TowerFloorListScreen`。本纵切只关闭九霄塔首地点缺口；其他地点、统一地点详情、U06/U14/M6/二阶段仍开放；零 schema/saveVersion、数值、概率、奖励、经济、解锁或叙事变更。
>
> v1.65 变更摘要(2026-08-25 二阶段 M6 U05 心魔入口归位纵切):按冻结方案 §11.2 删除主菜单重复“心魔境”入口；无论原 Ch6 门槛是否满足，心魔均不再占一级菜单。角色面板突破阻断区继续读取原 `innerDemonProgressProvider`/`resolveInnerDemonPanel`，并由原 CTA 进入 `InnerDemonScreen`。未改心魔解锁、战斗、失败或奖励语义。本纵切只关闭心魔入口归位缺口；U06 地图迁移、排行榜归位、U05/M6/二阶段仍开放；零 schema/saveVersion、数值、概率、奖励、经济或叙事变更。
>
> v1.64 变更摘要(2026-08-25 二阶段 M6 U05 主菜单角落工具区纵切):资源总览不再占养成玩法卡片，设置不再占独立玩法分区；资源、设置与既有退出统一进入主菜单右上角工具区，并继续复用 `ResourceOverviewScreen`、`SettingsPanel.show` 与 `AppExit.confirmAndQuit` 的生产语义。四个一级入口及其现有门控未改。本纵切只关闭冻结方案的角落工具区缺口；U06 地图迁移、排行榜归位、U05/M6/二阶段仍开放；零 schema/saveVersion、数值、概率、奖励、解锁阈值、经济与叙事变更。
>
> v1.63 变更摘要(2026-08-25 二阶段 M6 U05 “江湖纪事”一级 Hub 纵切):主菜单原先平铺的档案入口收拢为一个“江湖纪事”，内部提供章节卷轴、人物、地点、敌手、装备典故与待处理江湖事六路；四路复用既有生产 Screen，地点只读主线 cleared/available 关卡且不泄露锁定名称，待处理事项只读现有 `MainlineSettlementJournal` typed FIFO 并由既有 `runStageFlow` 恢复。敌手/装备典故保留原隐藏门控，异常 journal 与缺失 stage fail closed。本纵切关闭 U05 四个一级入口中的第四项；四项均有独立 READY，但资源总览角落工具化、排行榜归位、U05/M6/二阶段仍开放；零 schema/saveVersion、数值、概率、奖励、解锁阈值、经济与叙事变更。
>
> v1.62 变更摘要(2026-08-25 二阶段 M6 U05 “宗门”一级 Hub 纵切):主菜单不再平铺角色面板、闭关修炼、桃花岛、门派事务与江湖远行，改由一个“宗门”入口汇聚角色档案、门人调度、闭关、疗伤、远征、桃花生产和门派事务七条既有生产路由。角色相关入口绑定 active roster 第一位角色，加载中、空 roster 或悬空角色均 fail closed；闭关 step 5、远征存档标志、桃花第二章与门派第一章门控原值透传。活跃闭关状态仍由主菜单常驻 banner 承载。本纵切只关闭 U05 四个一级入口中的第三项，“江湖纪事”、资源角落工具、U05/M6/二阶段仍开放；零业务写入、schema/saveVersion、数值、概率、奖励、解锁阈值与叙事变更。
>
> v1.61 变更摘要(2026-08-25 二阶段 M6 U05 “武学与行囊”一级 Hub 纵切):主菜单不再平铺装备仓库、心法面板与藏经阁，改为一个“武学与行囊”入口；Hub 复用既有生产 Screen，明确分出招式配置、主修心法、装备与物品，装备/物品分别进入库存 Tab 0/1。招式与主修继续沿用 tutorial step 3 门控并绑定 active roster 第一位角色，角色未决或为空时 fail closed；库存保持开局可用。本纵切只关闭 U05 四个一级入口中的第二项，“宗门”“江湖纪事”、U05/M6/二阶段仍开放；零业务写入、schema/saveVersion、数值、概率、奖励、解锁与叙事变更。
>
> v1.60 变更摘要(2026-08-25 二阶段 M6 U05 “继续江湖”直达纵切):主菜单首要入口从“主线”改为“继续江湖”，进度加载后从生产主线数据动态派生完整章节集合并解析唯一待首推当前关，点击经既有战斗入口守卫后直接进入 `runStageFlow(targetCycle:1, continueFirstClearRun:true)`；不再硬编码只扫描前 15 章。进度未决或 21 章全通时仍回退章节地图以保留重打。本纵切只关闭 U05 四个一级入口中的第一项，不实现其余三个 Hub，不关闭 U05/M6/二阶段；零 schema/saveVersion、数值、概率、奖励、解锁与叙事变更。
>
> v1.59 变更摘要(2026-08-25 二阶段 M2/M6 U01 可见重打参与者归属纵切):已通关主线的可见真人重打现在从 active roster 选择存活、有主修且空闲的角色，经既有参与政策解析并把同一角色快照传入真实 `Phase0aMainlineBattleHost`；占用、角色/主修/装备悬空或领队指针损坏均 fail closed，不回退掌门。经验、熟练度、伤势与无主掉落历史事件归实际参与者，founder tutorial 语义不变。本纵切不开放前台 bot，不改 headless/扫荡/特殊模式，不关闭听剑、U01/U05、M2/M6 或整个二阶段；零 schema/saveVersion、数值、奖励、概率、解锁与叙事变更。
>
> **前版:v1.58**
>
> v1.58 变更摘要(2026-08-25 二阶段 M2/M6 U04 第一章待处理江湖事持久队列纵切):复用 `0.40.0` `MainlineSettlementJournal` 现有 outbox，以严格版本化 typed ref 持久互动奇遇与 Boss 招降，在权威 core settlement 事务内生成 canonical 来源、稳定 seed 与 FIFO 顺序。展示中仍保持 pending，重启重现；玩家选择、属性/声望/招收/来源标记与 claim 同一 Isar 事务，失败整体回滚，已完成旧队首重放幂等返回。返回/下一关动作可先记录，但只在队列排空后关闭/交接 receipt。本纵切只关闭第一章连续首通的 U04 互动事项恢复，不代表非主线全局队列、U01/U05、M2/M6 或整个二阶段完成；零 schema/saveVersion、数值、概率、奖励、解锁与文案变更。
>
> v1.57 变更摘要(2026-08-24 二阶段 M2/M6 U01 第一章持久结算恢复切片):存档 schema 以加法迁移升至 `0.40.0`，新增专用 `MainlineSettlementJournal`/outbox，持久身份严格绑定 `runId + stageId + loadoutVersion + participantId`。第一章连续首通在战前写入 `prepared`：权威结算前崩溃只能以同一参与者重试同关；角色/装备/心法/掉落/伤势/进度及确定性战绩、图鉴、击杀计数和声望与 `coreApplied` receipt 同一 Isar 事务落库，已提交 receipt 重启只恢复结算后 UI/推进且不重复发放。“返回/下一关”动作持久化，进入下一关时原子关闭旧 receipt 并创建新 `prepared`，保持同 run/同人且快照版本递增。本切片**仍不关闭**互动奇遇/招降的 U04 持久待处理队列、听剑生产接线、replay/manual/auto/headless/扫荡一致性、U05、M2、M6 或整个二阶段；未改任何调优值。
>
> v1.56 变更摘要(2026-08-24 二阶段 M2/M6 U01 第一章连续首通切片):第一周目当前可挑战主线关接入非递归连续 run，真实 `stage_01_01→stage_01_05` 在每关完整结算与后置 hook 成功后才允许选择下一关；整段锁定同一掌门，关间按同一角色重新装配不可变快照并把 run 内版本单调推进 1..5。主动返回、战败/退出、角色缺失/死亡/无主修/被既有活动占用、快照错人或装配异常均在发布下一关前停止；重打和特殊模式保持单关旧行为。本切片不新增伤势阈值、数值、奖励、解锁、schema 或调优，也**不关闭**持久崩溃恢复/重复结算键、随行听剑生产接线、replay/manual/auto/headless/扫荡全模式一致性、U04/U05、M2、M6 或整个二阶段。
>
> v1.55 变更摘要(2026-08-24 二阶段 G2 后最小整合):黑风岭 `stage_01_03` G2 正式记录 8/8、定向 94/94、全量 5249/5249、双视口正式矩阵均已关闭，后续二阶段分支以 G2 READY `e7932cc3` 为唯一整合基线；这只关闭第一章黑风岭纵切，不代表连续五关、U01/U04/U05、M2/M5/M6 或整个二阶段完成。另纳入两个互不重叠的 READY 小批：远征入口在权威事务内拒绝死亡角色且零副作用，散功在同一权威事务内重检闭关/远征/断魂庄占用与 canonical tuple，拒绝 stale/occupied 写入及假成功。20 项 `TUNE-*`、听剑比例/cap、七心魔 AI、渐进解锁和其余生态分配均未升级，main/origin main 未动。
>
> v1.54 变更摘要(2026-08-24 二阶段 G1 收口，状态快照已由 v1.55 取代):21 项 G1 生产合同与 1 项关键路径审计全部 `ready_reviewed`。C11 按用户批准将玩家数字技冷却物化为当前 `turns × 0.55s`，敌方阶段/蓄力技物化为 `turns × 1.0s`，Q/R 保持 5s/8s，Phase 0A mapper 对 `cooldownTurns` 零读方。C12 在扫荡开跑前必选寻隙/强攻/稳守，typed policy 原值透传到同核 player bot adapter；不表示前台主线 bot 已开放。当时 Ch1 production catalog、黑风岭纵切和 G2 八项仍未关闭；现以 v1.55 为准，候选数值仍不得冒充冻结事实。
>
> v1.53 变更摘要(2026-08-24 二阶段 M6 Batch1 · 主线叙事去阻塞与断魂庄自动准入):全部 105 个主线关的 opening/victory/defeat 自动阅读器已关闭，252 个既有叙事 ID 通过严格 manifest 搬入现有章节卷轴可选阅读；主线 Boss 战败仍先结算并显示事实性损失，特殊模式叙事不变。断魂庄前台可见 bot 与 headless 首通继续拒绝，仅允许 exact gauntlet 已完整首通后的确定性 headless 重刷，胜利硬停奖励选择、败局只结算一次。本批不代表 U01/U04/U05、完整五连关或 G2 已完成；零数值、schema/saveVersion、解锁和奖励改动。
>
> v1.52 变更摘要(2026-08-24 二阶段 M5 Batch1 · G0 心魔失败语义生产迁移):`INNER-DEMON-CULTIVATION-01` 已落实到生产：删除旧 10% 主修修炼度失败惩罚的配置、类型、调用参数与写回，任意退役 `failure_penalty` 配置均 fail-closed；心魔失败只保留有上限的内息紊乱，战败摘要不再声称内力/修炼度回退或把入场前既有伤势误报为本次后果。普通 Boss 战败结算与摘要不变，零存档 schema/saveVersion 迁移。
>
> **版本:v1.51**
> **2026-08-24 G7 退役平衡诊断口径收口**：随旧 3v3 删除的历史平衡诊断不再被写成活动守卫；13.5–21 万仅保留为 2026-06-14 历史测量记录。当前可重跑守卫分为 `test/balance/full_build_damage_redline_test.dart` 的满 build calculator 探针，以及 `test/tools/phase0a_full_content_balance_diagnostic_test.dart` 的 Ch1 祖师起手画像 × 154 条生产内容 × 5 熟练阶段 × 3 流派（2310 次）真实 Phase 0A reducer 路径。后者不是满 build / 飞升阶差 / 周目 / 地形阵型恩怨极值；Phase 0A 满 build 真实路径极值探针须另立后续任务。
> v1.51 变更摘要(2026-08-24 二阶段 G7 · 0 改数值/公式/断言/生产行为):清除已删除旧 3v3 平衡诊断的活动引用，给历史 13.5–21 万加退役标签，拆清当前两道伤害守卫的覆盖边界并登记真实路径满 build 极值缺口。
> **2026-08-24 二阶段 G0 决议收口**：用户已按推荐方案批准 G0，产品合同与旧否边界以 `docs/dispatch/phase0a_overhaul/decision_registry.yaml` 为准。七心魔 AI 与渐进解锁选择的是“先补矩阵/迁移表再逐项冻结”，属于显式延期流程；20 项 `TUNE-*` 只获候选生成授权，未经 YAML、红线、自动模拟、适用的双平台 Profile 与真人试玩，不得写成生产定值。实现按 M2/M5/M6 独立批次推进，G0 登记不等于代码已上线。
> v1.50 变更摘要(2026-08-24 二阶段 G0 推荐方案拍板 · 0 改代码数值):冻结主线 replay/连续 run/听剑对象与占用/心魔失败惩罚/生态审核边界，以及“断魂庄不开放前台可见 bot”的决议，登记 AI 与解锁的显式延期流程；五项旧否继续不重开，失败原因只部分放开事实展示；20 项调优只授权候选生成。详 decision registry 与 `docs/audit/phase2_g0_recommended_closeout_2026-08-24.md`。
> **版本:v1.49**
> **2026-08-23 二阶段事实同步（P2-M0-F01，已由 v1.50 G0 决议取代）**：当前事实以 `data/stages.yaml` 核验的 21 章/105 主线关为准；当时尚未冻结的事项只按 `PROPOSED`/`TUNING` 索引保留。
> v1.49 变更摘要(2026-08-23 Phase 0A 战斗爽感批):主线普通关统一扩为 2/3/4 人三波小怪，Boss 关为 2/3 人铺垫波后原 Boss 单独收尾；波间保留 HP/真气并恢复 25% 气海。键盘移动改为固定模拟拍持续采样，不依赖系统按键重复；普攻范围由 YAML 360 调至 420；战斗反馈统一单帧源并补克制水墨飞溅、残笔、墨洗与击杀散墨。在线/headless 仍共用 reducer，Boss 蓄力、破招、踉跄、脆弱窗口和数值红线不变。
> v1.48 变更摘要(2026-08-23 路线 C 双平台 Gate 收口 · 0 改玩法数值):旧 3v3 原子删除已在 commit `597a243b2506610b5cbb74e2919be79bbf99e283` 快进合入 `main`；同 commit 的 Mac 与 Windows 本地物理机矩阵均为 1280×720/1440×900 各 3 轮、合计 6/6 PASS，独立 preflight PASS，全量 4218/4218、analyze 0。六人真人 Gate 已由用户取消；Windows 结果仅证明当前实体基线兼容，不定义产品最低配置。证据索引见 `docs/audit/route_c_gate_closeout_2026-08-23.md`。
> **版本:v1.47**
> v1.47 变更摘要(2026-08-23 路线 C Windows Gate 标准调整 · 0 改玩法数值):Route C 外部硬锁由目标最低档性能 Gate 改为 Windows 本地物理机生产兼容性 Gate；当前 Ryzen 7 5800X + RTX 4070 SUPER + 16GB + 143Hz 实体机具备签字资格。该结果不得外推为产品最低配置；RDP/VM/云机/隐藏 service session、混 commit/AOT、缺失主机事实或不实 attestation 仍直接否决。
> **版本:v1.46**
> v1.46 变更摘要(2026-08-23 路线 C Gate 改判 · 0 改玩法数值):用户取消六人真人 Gate；当时 Route C merge 仅硬锁最低档 Windows 物理机生产根应用矩阵，历史真人工具与报告不参与 preflight。**该硬件档口径已被 v1.47 取代。**
> **版本:v1.45**
> v1.45 变更摘要(2026-08-22 路线 C 当前态同步 · 0 改玩法数值):五个生产战斗消费面统一使用 Phase 0A 单角色 ARPG，live/headless 共用 reducer；历史多人会话安全退役且不再回落旧 runner。旧 3v3 已在独立删除候选中原子移除，当时 merge 仍硬锁六人主观 Gate 与最低档 Windows 物理机 Gate；§1 漂移指针已改为当前生产口径。**外部 Gate 已由 v1.46/v1.47 连续改判。**
> **版本:v1.44**
> v1.44 变更摘要(2026-08-19 §7.4 路线 C 四子项拍板 · 0 改代码数值):与 GDD v1.27 同批同口径——v1.43 批所遗「4 子项未决」同日调研拍板全收口(全 α):headless 内核=复用 0A reducer(补玩家 bot adapter+快进循环)/65 路由=删路由·证据原地标注/共享层=拆分迁移(enum_localizations 等迁 lib/shared)/空窗=原子切换·零空窗;调研事实详 `docs/audit/legacy_3v3_removal_scope_2026-08-18.md` §8。§1 漂移指针与正文措辞仍随 ADR 执行批改写,禁单独改。
> **版本:v1.43**
> v1.43 变更摘要(2026-08-19 §7.4 ADR 拍板 + 战斗形态漂移指针 · 0 改代码数值):① 存量战斗 ADR 用户拍板**路线 C 终态替换·前置排程**(终态=0A 单角色 ARPG 替换旧 3v3;硬前提=6 人 Gate+Windows 实机+Phase 1 纵切+共享层/headless 内核安置先行;4 子项未决;事实底座 `docs/audit/legacy_3v3_removal_scope_2026-08-18.md`);② §1 一句话加漂移指针(与 GDD v1.26 同批同口径,措辞改写随 ADR 执行批,禁单独改);③ AGENTS.md 一句话随动同改。
> **版本:v1.42**
> v1.42 变更摘要(2026-08-05 BACKLOG 一区拍板批 · 0 改代码数值):§12.2 #5 归档行闭关产出倍率表述订正——2026-07-19 经验倍率拆分批后 stale:实况为 retreat 双倍率 `realm_scale_per_tier: 1.3`(银两/材料/心法/内力)+ `experience_realm_scale_per_tier: 1.65`(经验专用,防闭关经验劣于纯离线的速率倒挂),passive_idle 被动经验另有专用 1.6(numbers.yaml:1236-1237/:1275 现查)。源:BACKLOG 一#7 用户拍板。
> **版本:v1.41**
> v1.41 变更摘要(2026-07-24 真相源收口批 · 外审 07-24 triage · 0 改数值):① §5.4 Boss 血量红线措辞「60,000+」→「上限 60,000」(消除字面歧义,与 schema/生产 ≤60,000 一致);② GDD v1.24 同批:头部「当前状态块」制(`test/data/truth_source_guard_test.dart` 自动校验 cap/章数/关数)+排行榜 Noop 口径订正+战败死配置 `boss_internal_force_penalty` 退役删除。
> **版本:v1.40**
> v1.40 变更摘要(2026-07-18 校验符号迁位订正 · 0 改代码):GameRepository 拆分批(overnight 审查落地批·2402→1137 行)后符号位置同步——① §5.4 招式倍率 schema 真 sink:`game_repository.dart` `_enforceEncounterSkillRedLines` → `lib/data/validation/encounter_red_lines_validator.dart` 公名 `enforceEncounterSkillRedLines`(仍由 `GameRepository.loadAllDefs` 消费,enforce 语义零变);② §5.3 种子/收徒 yaml 层兜底两符号:`_enforceMasterRedLines`/`_enforceRecruitCandidateRedLines` → 同名公函数(`lib/data/validation/lineage_recruit_red_lines_validator.dart`);③ §8.1 现查无 drift:lore/events 联结校验 `_validatePresetLoreReferences`/`_validateEncounterEventReferences` 仍在 `game_repository.dart` 未迁,引用不动(handoff 待办原列 §8.1,实测证伪)。源:`docs/handoff/overnight_audit_batch_closeout_2026-07-18.md` 已知风险#1 + followup backlog #1。
> **版本:v1.39**
> v1.39 变更摘要(2026-07-15 出战编成屏 · 0 改数值):玩法评估 §十三 #4 实装——门派谱「出战编成」入口→编成屏(3 席+替补池,点选交换);`LineupService` 单事务唯一编成写入口(`activeCharacterIds` 唯一真相源=列表序即站位序,`Character.isActive` 镜像),校验=祖师必在/1-3 人/闭关锁(增删拦、纯重排放行)/已飞升太祖禁回场/**加入者须已修主修**(镜像 `stage_battle_setup._playerToBattle` 硬前置);替补池口径=`isActive==false` 索引查询(覆盖四条 inactive 进入管线,recruitedDiscipleIds 只覆盖 E.1 不可用)。研习首门心法弹「立为主修/纳为辅修」择路(PR #36 观察① 收窄版,有主修维持仅辅修零新散功),零心法态保留研习入口。无 schema/saveVersion 变更。源:spec `docs/spec/2026-07-14-team-lineup-screen-design.md`(含 §2 实装订正块)。
> **版本:v1.37**
> v1.37 变更摘要(2026-07-14 全量审查收口 · 0 改数值):① §4 注记 skills.yaml camelCase 历史例外(文档与现实收口,不迁移 206 招 key);② §8.2 合并 Gate 补 ⓓ commit message 中文检查项。源:`~/Desktop/挂机武侠全量审查报告_2026-07-14.md` P3-2/P3-4。
> **版本:v1.38**
> v1.38 变更摘要(2026-07-14 心法学习闭环 · 0 改数值):研习新心法接线——技能面板心法区新增「研习新心法」入口,消耗领悟点(闭关挂机产出·`numbers.yaml learning_cost` 辅修100/主修500,值未改)学境界内未持有心法,经 `TechniqueLearnFlowService` 落库并记 `techniqueLearned` 事件;超阶心法 UI 灰显不可学(§5.3)。领悟点第二个 sink(与凝练并列)。无 schema/saveVersion 变更。源:backlog §十三 #1。
> **版本:v1.36**
> v1.36 变更摘要(2026-07-13 境界派生 490 级):`Character.experience` 成为唯一可写角色经验账；49 个真实境界层各细分 10 个纯展示段，形成 Lv1～Lv490。数字等级不加战力、不参与装备/心法门槛或强化上限。武圣·登峰的 1,250,000 经验只完成 Lv490 刻度，不生成第 50 层。旧 `Character.level/levelExp` 仅保留 Isar schema 兼容，生产零读写；主线、爬塔、闭关、普通离线与经验丹统一走 `CharacterAdvancementService`。
> v1.35 变更摘要(2026-07-13 角色四项属性职责统一):根骨除血量外缩短新生成重伤时长；悟性统一影响心法修炼、招式熟练度成长与武学领悟概率；身法只管速度/闪避，基础暴击平移至 7.5%；机缘只管普通奇遇概率和显式特殊选项，不参与商店定价/掉落倍率。旧角色属性值、schema、saveVersion 均不迁移。
> v1.34 变更摘要(2026-07-12 内力/真气拆分):永久内力由闭关增长并决定伤害，战斗不消耗；每角色使用有界真气循环（基础气海100；玩家基础开场40、普通敌人20、主线Boss40、塔Boss60；招式显式产耗气、流派单行动最多一次附加产气、连战恢复25%）。内力不再贡献血量。失败改施加可恢复的内息紊乱，不再永久扣内力；0.35旧档迁至0.36时保护性补满永久内力并迁移旧余毒。
> v1.32 变更摘要(2026-07-08 外部审查速修 · 低风险修订):① 战斗结算 `BattleResolutionService.resolve` 默认胜负从 `finalState.result` 派生，避免未显式传参时战败误走胜利掉落；② `interveneNow` 补 request 后 null-check，消除拖招边界崩溃点；③ `_enforceEncounterSkillRedLines` 招式倍率上限改读 `numbers.combat.redLines.skillPowerMultiplierMax`；④ 文档 drift 速修：data_schema 降级历史快照、content_guide 清退役 DeepSeek/Windows 引用、README/AGENTS/IDS/GDD 同步已知偏差。
> **版本:v1.31**
> v1.31 变更摘要(2026-07-04 批次3 心魔机制型实例登记 · 2026-07-08 调优后口径):心魔 05/06/07 镜像脆弱窗口(承伤乘子 0.16/0.16/0.14)+ 机制镜像攻击折减 0.75 + 07 限时生存(survive 20 tick 或击败任一即胜);纯实例追加对齐 v1.30 机制型 Boss 例外条款,减伤方向/新胜负条件不膨胀数字。
> **版本:v1.30**
> v1.30 变更摘要(2026-07-03 §5.4 机制型 Boss 例外条款 · 0 改代码):终局机制型 Boss（batch1/2 已合 main·爬塔 floor25/30 配 vulnerability 承伤乘子 [0.05,1.0] / 护法结界 ward 0.15）**有意让满配也不能纯 DPS 秒杀**,与 §5.4 原「满配秒杀/周目对满配无效=有意爽感·不动」句冲突,加例外条款正名:机制型 Boss 是**减伤方向**的机制门槛（窗口外承伤减免·floor30 复合≈0.03·须抓脆弱窗口输出）,只压低有效伤害不膨胀数字、不触及「不进百万」硬线,承伤乘子 schema 有界非属性 buff;「满配秒杀爽感」仍适用普通终局内容（含周目膨胀）。同步 GDD §5.2 红线块。源:终局 Boss 特性 batch1/2 + session 记「用户拍板局部收口 §5.4 满配秒杀」。
> **版本:v1.29**
> v1.29 变更摘要(2026-07-03 测试节奏收口 · 0 改代码):去掉「无脑全量 + `-j1`」的罚时。① **全量默认改并发**:`flutter test --no-pub`(不带 `-j1`)——10 核实测 **2m34s / 3587 pass 0 fail** vs `-j1` 9m42s(3.8× 提速·零覆盖损失·每文件独立 isolate + 每测试 `createTemp` 独立目录本就隔离);`-j1` 仅在排查隔离型 flaky(如 `drop_table_reference_redline`)时临时用。② **何时跑全量**(§8.0 执行纪律):自包含改动(纯资产/文案/单 feature 表现层)只 targeted + `analyze`,跨切面改动(numbers/结算/schema/saveVer/公式/全仓 sed/迁移)或批末合并才全量。③ **交接/开局不无脑全量**:`HEAD=origin/main` + 树干净 + 上会话验绿并 push 时只 `analyze`,绿状态已是 PROGRESS/session 记录的事实。源:2026-07-03 用户反馈「测试太频繁费时」+ 本会话并发实测。
> **版本:v1.28**
> v1.28 变更摘要(2026-07-02 全面审查速修批 · 文档 drift 订正 + P0 资产声明修复):① **pubspec 补声明 `data/lore/sect_event/` 与 `data/narratives/`(P0)**:Flutter asset 目录声明不递归,两目录漏声明致 10 篇门派事件文案 + 14 篇爬塔 Boss/收徒叙事(narratives 根扁平文件)运行期 rootBundle 不可达、静默走兜底/占位,构建产物复核证实;新增 `test/data/pubspec_asset_declaration_test.dart` 守卫(data/ 下含 yaml 的非 `_archive` 目录必须逐个声明);② **§5.3 校验点符号订正**:`EquipmentRepository.canEquip()`/`TechniqueRepository.canPractice()` 两符号不存在,改指真实闸门(`Equipment.isEquippableAtRealm` + `EquipmentService.equip` / `TechniqueLearningService.learn`);③ **§8.1 口径订正**:「任一端缺失抛错」只对 encounters↔events、equipment↔lore 成立,stages↔narratives 实为 placeholder 兜底不抛,如实标注。源:`docs/audit/full_project_review_2026-07-02.md` P0-1/P2-1。
> **版本:v1.27**
> v1.27 变更摘要(2026-06-29 Codex→Claude 就绪信号 · git 原生标记 · 0 改代码):解决「codex 在多个 worktree 持续写时,Claude 分不清哪个分支冻结可评、哪个还在写(tip 随时变 / 工作区脏)」的并行 race。新增 §8.3:codex 任务写完须 ① 工作区干净(全 commit) ② 把分支 tip commit 消息前缀打成 `[READY]`(需用户拍板的打 `[BLOCKED]`,其余视为 WIP)。Claude 只评审/合并 tip 以 `[READY]` 开头且 worktree 干净的分支;codex 再提交→tip 不再是 `[READY]`→Claude 自动当其仍在写跳过(freeze 自动判定);`[BLOCKED]` 不合、汇报用户拍板。无新文件、单一事实源 git、主分支可见、零文档漂移。源:2026-06-29 4 个 codex 在途 worktree 实测(taohua 4min 前提交 / equipment-drop 脏未 commit)证明无就绪信号则只能逐个问用户。
> **版本:v1.26**
> v1.26 变更摘要(2026-06-29 协作交付门槛 + 合并 Gate 固化 · 0 改代码):3 梯队批量合并验证「Codex 产任务 + Claude 合并审核」工作流有效后,把交付门槛与合并 gate 写入 §8.2 长期规则(Codex 子任务交付标准 4 项 + UI 视口/桌面语义加码 + 外部审查只进 triage + Claude 合并审核 Gate + 批末验证/清理/PROGRESS 四态)。源:2026-06-29 Codex 全量审查(无 P0/P1 阻断 · analyze/3391 test 全过 · 风险=PlaqueButton 桌面语义/ErrorFallback rebuild 日志/超高视口非常规体验/残留 worktree)。
> **版本:v1.25**
> v1.25 变更摘要(2026-06-27 可恢复任务协议):① 长任务默认采用「主窗口调度 + 独立 worktree/分支执行」;② 每个子任务必须有 `docs/superpowers/plans/` 计划文件、明确恢复点、小切片 commit;③ 依赖型任务不提前空转,由主窗口在前置分支稳定后唤醒,并统一复核/合并顺序。
> **版本:v1.24**
> v1.24 变更摘要(2026-06-27 PVP 功能切除 · 保旧档兼容):① 删除/停用 PVP 玩家入口、PvpScreen 占位 UI、PVP provider/service/strategy、`numbers.yaml pvp` 配置、PVP lore 文案与测试;② `StageType.pvp` 与 `PvpRecord`/`PvpSnapshot` Isar collection 仅作为旧存档/旧枚举反序列化兼容保留,生产路径不再读写;③ §7/§9 现状口径改回无 PVP,1.0 当前战斗形态为地面 3v3 + 轻功 + 群战 + 心魔等单机内容。
> **版本:v1.23**
> v1.23 变更摘要(2026-06-26 推翻装备永久收藏品/只买不卖红线 · 0 改代码数值):① **GDD §2.1 装备分解反主流项推翻**:「装备分解→装备永久保留收藏品」从「不做」清单标注推翻，改为「装备可出售换银两 / 可分解成强化材料」；② **CLAUDE §5.1 同步**:反主流清单移除「装备分解」一项；③ **`shop_service.dart` 头注订正**:「只买不卖」→购买/出售分离注释。理由：玩家处理冗余装备真实痛点；出售/分解为良性 sink，非氪金/留存机制。spec：`docs/spec/2026-06-26-equip-sell-decompose-inventory-design.md` §红线决策史。
> **版本:v1.21**
> v1.21 变更摘要(2026-06-24 全系统审计 C 组设计冲突拍板 · 0 改战斗数值):三项文档 vs 代码 drift 收口(用户逐项拍板)。① **C1 §6.1 商店经验丹「ETL 恒定兑换率动态标价」明文授权**:经验丹标价随祖师境界 ETL 上涨锁定兑换率恒定(防囤丹套利),明确区分「进度锚定动态标价」≠ §5.1 废除的「机缘定价」(后者按机缘属性变价制留存焦虑),材料类仍固定价;② **C3 §5.4 招式倍率改「全局 ≤8,000 单线」**:旧「强力 1,000–3,000 / 大招 5,000+」per-type 分档是 7 阶系统铺开前早期参考值,与 §5.2 锁死七阶缩放矛盾(实测 powerSkill 32/73 超 3000、ultimate 41/55 低于 5000,低阶大招＜高阶强力是曲线必然),schema 唯一真 sink 本就只全局 enforce ≤8000,改单线消除 drift;③ **C2 奇遇 events 加载层强校验实装(代码)**:仿 lore `_validatePresetLoreReferences` 在 `loadAllDefs` 末尾加 `_validateEncounterEventReferences`,缺 events 文件 / id 不自洽 / 越界 outcome_id 启动期 fail-fast,兑现 §8.1「任一端缺失直接抛错」(此前 catch 全吞静默降级);57/57 现状干净不误报。详 `docs/audit/full_system_audit_2026-06-24.md` C 组 + PROGRESS。
> **版本:v1.20**

---

## 1. 项目一句话

买断制、写实武侠挂机游戏，**发布目标 Windows**（开发与验收在 macOS）。Flutter Desktop，Phase 0A 单角色横版水墨 ARPG + 同核离线挂机；旧 3v3 仅存在于历史记录，不是产品模式。Demo 里程碑已达成（§8.4 14/14），当前处于 **1.0 长线打磨期**（质量优先，不设上线时间压力，见 §7）。

### GDD 快速索引

| 我想查 | 看 GDD 章节 |
|---|---|
| 项目定位与基调 | §1 |
| 反主流不做清单 | §2.1 |
| 7 阶节奏与三系对应 | §3 |
| 角色 4 项属性 / 稀有度 | §4.1 |
| 心法搭配 / 修炼度 9 层 | §4.2 – §4.3 |
| 三流派克制 | §4.4 |
| 心法相生组合 | §4.5 |
| 战斗数值范围（红线） | §5.2 |
| 伤害 / 血量 / 速度公式 | §5.3 – §5.6 |
| 装备获取 / 强化 / 心血结晶 | §6.1 – §6.3 |
| 共鸣度（人剑合一） | §6.4 |
| 开锋（3 槽 build） | §6.5 |
| 典故系统 | §6.6 |
| 师徒传承 | §7.1 |
| 武学领悟（替代抽卡） | §7.2 |
| 时间锚点闭关 | §7.3 |
| 主线 / 爬塔 / 闭关地图 | §8.1 – §8.3 |
| Demo 内容总量 | §8.4 |
| 核心循环（5 阶段） | §9 |
| 新手引导节奏 | §10 |
| 扩展系统实装现状 / 仍不做清单 | §12 |

## 2. 技术栈

| 层 | 选型 | 备注 |
|---|---|---|
| 引擎 | Flutter Desktop | 发布目标 Windows；开发/验收在 macOS（`-d macos`，Isar 无 web target） |
| 状态管理 | **Riverpod 3.x**（已迁，`flutter_riverpod ^3.0.0`） | 不引入 BLoC 等其他方案 |
| 本地存储 | Isar | 角色、装备、进度、共鸣度计数等 |
| 排行榜同步 | 本地榜 + `LeaderboardSyncService` 抽象 | 当前 Noop、0 Supabase 包/网络调用；GDD 保留未来云榜方向 |
| 战斗表现 | 纯 Flutter Widget + AnimationController | 不引入 Flame 等游戏引擎 |
| 打包 | MSIX，内测先发 itch.io | — |
| 数据格式 | YAML | 数值、配置统一 yaml |

## 3. 目录结构

```
project_root/
├── CLAUDE.md                  # 本文件
├── GDD.md                     # 主设计文档（你维护）
├── docs/_archive/             # 退役文档归档（含 WINDOWS_DEEPSEEK_GUIDE.md，v1.8 起退役）
├── lib/                       # Dart 源码 ── 你的领地
│   ├── core/                  # 公式、常量包装、领域模型（纯 Dart，无 Flutter 依赖）
│   ├── data/                  # yaml 加载、Isar 仓储与配置校验
│   ├── features/              # 按功能切分（battle / equipment / cultivation / ...）
│   │   └── <feature>/
│   │       ├── domain/        # 实体与用例
│   │       ├── application/   # Notifier
│   │       └── presentation/  # Widget
│   ├── shared/                # 跨 feature 复用（主题、组件、工具）
│   └── main.dart
├── data/                      # 全部配置与文案
│   ├── ranks.yaml             # 境界配置                    [你]
│   ├── equipment.yaml         # 装备数值                    [你]
│   ├── techniques.yaml        # 心法数值                    [你]
│   ├── stages.yaml            # 关卡配置                    [你]
│   ├── encounters.yaml        # 奇遇触发条件与数值          [你]
│   ├── narratives/            # 主线/章节剧情               [你 · v1.8 起接管]
│   ├── lore/                  # 装备典故                    [你 · v1.8 起接管]
│   └── events/                # 奇遇事件文本                [你 · v1.8 起接管]
├── assets/                    # 图片、字体、音频（AI 产出；audio/{bgm,sfx} 按 enum.name 命名）
└── test/                      # 单元 + widget/视觉路由 + 平衡红线测试
```

**[你] = Mac + Opus 4.7 写**;v1.8 起单端接管全部文件类型(数值 + 文案 + 代码 + 测试 + GDD)。

## 4. 命名规范

| 对象 | 规则 | 示例 |
|---|---|---|
| Dart 文件 | snake_case.dart | `equipment_repository.dart` |
| 类 / Enum | UpperCamelCase | `EquipmentRepository`, `RealmTier` |
| 变量 / 函数 | lowerCamelCase | `currentRealm`, `calculateDamage()` |
| 私有 | 前缀 `_` | `_internalCache` |
| 常量 | lowerCamelCase（不用 SCREAMING） | `maxStrengthenLevel` |
| YAML key | snake_case | `attack_power: 1500` |
| 文案文件名 | snake_case | `chapter_01_opening.yaml` |
| 提交分支 | `feat/<feature>` `fix/<bug>` `balance/<topic>` | — |

> **YAML key 历史例外**(2026-07-14 注记):`data/skills.yaml` 全文件沿用 camelCase(`qiDelta`/`powerMultiplier`/`cooldownTurns`,loader 按 camelCase 读),为 7 阶铺开前的历史惯例,**该文件内新增字段保持 camelCase 一致**;其余 yaml(numbers/equipment/stages 等)及新建文件一律 snake_case。

**枚举命名锁死 GDD 词汇**：境界用 `Realm`，层用 `RealmStratum`，装备阶用 `EquipmentTier`，心法阶用 `TechniqueTier`，流派用 `Style { rigid, agile, sinister }`（刚猛/灵巧/阴柔）。**不要用 `legendary` `epic` 这类网游词汇**——本项目不存在这些概念。

## 5. 关键设计原则（红线）

> 这一节是底线。实现任何功能前若发现冲突，**停下来与人类确认**，不要自作主张地"折中"。

### 5.1 反主流不做清单
不做：传统体力 / 每日任务 / 登录奖励 / 战令 / 抽卡 / VIP / 强化破防降级 / 留存焦虑通知。任何 PR 涉及以上功能 → 停。
**2026-07-08 口径补充**：允许“扫荡战备 / 副本凭证 / 劳损调息”等非日课型节奏资源，但只能用于限制主线已通关扫荡刷资源、后期强力副本入场或高难连续挑战压力；不得做全局体力、每日重置、登录领取、付费恢复、任务奖励体力，且恢复必须在线=离线、可跨天囤积。详 GDD §2.3。
（装备出售/分解已于 2026-06-26 用户拍板推翻，不再列入此清单。spec：`docs/spec/2026-06-26-equip-sell-decompose-inventory-design.md`）

### 5.2 七阶节奏（统一锚点）
所有可量化进阶系统共用同一套 7 阶：
- **境界**：学徒 / 三流 / 二流 / 一流 / 绝顶 / 宗师 / 武圣（每阶 7 层 → 49 个真实层）。每层经验进度再切 10 个纯展示段，角色面板显示修为等级 Lv1～Lv490；它不是第二套成长账，也不提供战力或解锁。
- **装备阶**：寻常货 / 像样货 / 好家伙 / 利器 / 重器 / 宝物 / 神物
- **心法阶**：入门功 / 常练功 / 名家功 / 门派绝学 / 江湖秘传 / 失传神功 / 传说神功

新增任何"阶/品/级"概念前先问：能否复用 7 阶？不能 → 找人类讨论。

### 5.3 三系锁死同步（不可破，无例外）
境界 ↔ 装备阶 ↔ 心法阶 一一对应。例：二流境界 → 最多装备「好家伙」、最多修「名家功」。**任何允许低境界使用更高阶装备/心法的设计都是错的**。校验点实符号(v1.28 订正,旧文引用的 `EquipmentRepository.canEquip()`/`TechniqueRepository.canPractice()` 不存在):装备侧 `Equipment.isEquippableAtRealm()`(`lib/core/domain/equipment.dart`,唯一换装路径 `EquipmentService.equip` 消费,战斗入场/飞升 auto-swap 再校验);心法侧 `TechniqueLearningService.learn`(`RealmUtils.techniqueTierCapOf` 硬拦;2026-07-14 起技能面板「研习新心法」入口经 `TechniqueLearnFlowService` 消费此校验,超阶心法 UI 灰显不可学;种子/收徒来源另由 yaml 层 `enforceMasterRedLines`/`enforceRecruitCandidateRedLines`(`lib/data/validation/lineage_recruit_red_lines_validator.dart`·v1.40 迁位订正)兜底);奇遇招式侧 `EncounterService.canEquipEncounterSkillByTier`。在这些校验点上保持硬约束。

**例外说明（v1.1 明确）**：
- **师承遗物同样受锁死约束**：虽自带传承 buff（内力上限 +5%），但徒弟境界未达对应阶时不可装备，只能存放在背包等到达阶时才可装备。规则统一，无网开一面。
- **奇遇所得 / 失传神物等"高于当前境界"的物品**同理：可获得、可携带、可观摩，但**不可装备 / 不可修炼**，等境界到了自动解锁。

### 5.4 数值红线（两层语义 · v1.20 收口 2026-06-14）

> **2026-06-14 红线语义收口（用户拍板分两层；2026-08-24 G7 证据标签订正）**：原「普通伤害 ≤8000 不得突破」与现实分裂——满强化神物极值 build 普攻 calculator 探针约 5.8 万（暴击 8.7 万）；当时旧 3v3 极值×周目诊断记录的**真实战斗峰值约 13.5 万、大招约 21 万**（含 per-skill 熟练度 ×1.30 + 地形/阵型/恩怨 APM 末端乘 + 飞升 +1 阶差距），均「进十万、不进百万」。该诊断已随旧 3v3 于 2026-08-22 删除，13.5–21 万是**历史已退役测量记录，不是当前可重跑守卫**；且 `test/data/p1a_redline_test.dart` 早已自承「≤8000 是设计层指南，极值已越界」。故红线分两层：**配置基础表值=硬约束**（schema 拦截）；**极值满 build 实战可见值=软可读区间**（核心唯一线 = 不进百万膨胀，2026-06-14 诊断后用户拍板从「不进十万」放宽，历史 13–21 万仍为 6 位可读参考）。

**硬红线（配置基础表值 · 不得突破 · schema 校验拦截）**：

| 项目 | 上限 |
|---|---|
| 装备基础攻击 | 2,000 |
| 玩家血量 | 20,000 |
| 内力 | 15,000 |
| Boss 血量 | 上限 60,000（不许进 1M；2026-06-14 由 50,000 上调） |
| 招式倍率 | **全局 ≤8,000 单线**（schema 唯一真 sink = `lib/data/validation/encounter_red_lines_validator.dart` 公名 `enforceEncounterSkillRedLines`(由 `GameRepository.loadAllDefs` 消费·v1.40 迁位订正)全局 enforce ≤8000）。per-type 数值按 §5.2 七阶缩放（普攻~500 基准；强力/大招随阶 1,500→6,400，低阶大招＜高阶强力是 7 阶曲线必然），**不按招式类型钉固定区间**——旧「强力 1,000–3,000 / 大招 5,000+」per-type 分档是 7 阶系统铺开前的早期参考值，与锁死的七阶哲学矛盾，2026-06-24 拍板改全局单线消除 drift |

**软红线（极值满 build 实战可见值 · 保可读 · 不进百万膨胀）**：

| 项目 | 区间 |
|---|---|
| 普通伤害 | 典型 build 设计目标 8,000；当前满强化神物极值 build 普攻 calculator 探针 ~5.8 万；旧 3v3 已退役诊断的历史真实战斗峰值记录 ~13.5 万（含熟练度 ×1.30 + APM + 飞升阶差），**不进百万** |
| 大招暴击 | 当前 calculator 探针 ~8.7 万；旧 3v3 已退役诊断的历史真实战斗峰值记录 ~21 万，**不进百万** |

**理由**：玩家一眼能读懂——核心唯一线是**不进百万级膨胀**，不是钉死每个极值 build ≤8000、也不钉死十万（2026-06-14 旧核诊断记录 13–21 万后用户拍板放宽）。配置基础表值（装备攻击/血量/内力/招式倍率）yaml 写完 schema 校验拦下越界；当前实战可见值有两类守卫：`test/balance/full_build_damage_redline_test.dart` 用真实派生装备构造跑 `DamageCalculator`，覆盖满 build calculator 极值探针并硬断言不进百万，但不经过 Phase 0A reducer；`test/tools/phase0a_full_content_balance_diagnostic_test.dart` 用 Ch1 祖师起手画像跑 3 流派 × 154 条生产主线/塔内容 × 5 熟练阶段 = 2310 次 Phase 0A headless reducer，并逐次硬断言 `maxResolvedDamage < 1,000,000`，但不覆盖满 build、飞升阶差、周目或地形/阵型/恩怨极值。旧 3v3 的 13.5–21 万只保留为历史参考，不能再当当前守卫；Phase 0A 满 build 真实路径极值探针是明确后续缺口。装备派生有效攻击（强化×共鸣×开锋连乘）远超 2000 是**有意终局爽感**，不是越界；终局极值 build 一回合秒杀普通终局内容（周目进化对满配无效）同属既有设计意图。 **例外·终局机制型 Boss（2026-07-03 局部收口）**：配「脆弱窗口」承伤乘子（vulnerability 承伤 [0.05,1.0]）或「护法结界」减伤（ward 0.15）的终局机制型 Boss（爬塔 floor25/30 等），**有意让满配也不能纯 DPS 秒杀**——窗口外承伤大幅减免（floor30 复合 ward×vuln≈0.03），玩家须抓脆弱窗口（敌蓄招／破招踉跄／血阈相位开窗）集中输出。此为**减伤方向**的机制门槛，只压低有效伤害、不膨胀伤害数字，**不与「伤害不进百万」硬线冲突**；承伤乘子 schema 有界 [0.05,1.0]、非属性 buff（守本红线）。「满配秒杀爽感」仍适用普通终局内容（含周目膨胀），机制型 Boss 是刻意引入机制层的**局部**例外。**批次3 心魔追加（2026-07-04，2026-07-08 调优）**：心魔高层关（inner_demon 05/06/07）镜像同配脆弱窗口（承伤乘子 05=0.16/06=0.16/07=0.14，运劲蓄力开窗），机制镜像攻击乘 0.75；心魔终关 07 另配限时生存胜负条件（survive 20 tick 或击败镜像任一即胜，胜负与纯 DPS 脱钩）。均属**减伤方向/新胜负条件**，不膨胀伤害数字、不触「不进百万」硬线，承伤乘子 schema 同守 [0.05,1.0] 有界、非属性 buff。

**心魔复校补充（2026-07-12）**：心魔 05/06 在既有装备攻击 ×0.75 外，另配总输出 ×0.52；07 不套总输出折减，以维持限时生存压力。

### 5.5 在线 = 离线
挂机就是挂机。**不允许任何"在线 buff""挂机加速""快进券"**。关游戏 8 小时回来 = 一直挂着 8 小时。

### 5.6 不硬编码
- **Dart 代码里不写中文文案**——叙事文案(剧情/旁白/事件)全部走 `data/narratives/` `data/lore/` `data/events/`;UI 文案(标签/提示/错误串)走集中归集层 `lib/shared/strings.dart`(`UiStrings`)。禁止的是在 presentation / domain 各处**散写**中文字面量。
- **集中式格式化 / 本地化层是合法 sink(v1.20 正名)**:单一文件集中维护、非散落各处的中文,与 `UiStrings` 同类,**不算「散写硬编码」**——计有 `enum_localizations.dart`(`EnumL10n` 枚举→显示名,带 `switch` 穷尽检查)、`battle_log.dart`(战报格式化,大量插值句子集中一处)。新增此类文本进对应集中层,不要在调用点内联中文。
- **Dart 代码里不写数值常量**——全部走 `data/*.yaml`。
- 唯一例外：开发期占位字符串可临时用，但合并 main 前必须迁出。

### 5.7 让玩家先感受问题，再给答案
新系统通过剧情或战斗自然出现，**不要写教程弹窗**。未解锁系统的菜单按钮直接灰掉或隐藏。

## 6. 核心公式（实现层必须遵循）

```
基础伤害 = (内力 × 0.4) + (装备攻击 × 1.0) + 招式倍率

最终伤害 = 基础伤害
        × 心法修炼度加成 (1.0 ~ 3.0)
        × 流派克制 (0.75 / 1.0 / 1.25)
        × 暴击系数 (1.0 / 1.5 ~ 2.5)
        × (1 - 目标防御率)
        × 境界差距修正

最大血量 = 1,129 + (境界绝对层级 - 1) × 156 + 根骨 × 400 + 装备血量
出手速度 = 100 + 身法 × 8 + 装备速度 + 心法速度加成
```

> 注（v1.34）：伤害读取实际永久内力；内力不再进入最大血量。血量旧曲线由 `base=1129`、`realm_level_factor=156` 与根骨/装备承接，仍守玩家血量 20,000 硬线。

**真气循环**：基础气海100；玩家基础开场40，无心法普通敌人20、主线Boss40、塔Boss60。所有招式由 `qiDelta` 显式声明产气/中性/耗气。最终气海80~140、开场≤80、产气倍率≤1.5、减耗≤20%；溢出丢弃，多波战斗保留并追加恢复25%。刚猛命中/承伤、阴柔控制/内伤/持续效果、灵巧闪避/暴击/连击时可追加产气，同一行动每角色最多一次。

**境界差距修正**（攻方/守方）：同 1.0/1.0｜差 1 阶 1.4/0.7｜差 2 阶 2.5/0.3｜差 3+ 阶 —/**0.05（近免疫）**。

**招式倍率**：硬约束 = **全局 ≤8,000 单线**（schema 真 sink，见 §5.4）。普攻~500 为基准，强力/大招按 §5.2 七阶随阶缩放（实测 1,500→6,400，均 ≤8000），不按类型钉固定区间。

**散功代价**（玩家更换主修心法时触发，v1.1 新增）：
```
永久内力       = 不变
内息紊乱       = +6h（总计不超过12h，可由有效战斗或闭关/离线恢复）
新主修修炼度   = 原主修修炼度 × 0.5    （原修炼度记录保留，重学时不归零）
辅修不受影响   = 不动
```
修炼度损失与临时紊乱保留换流派的决策成本，但不抹除挂机/闭关积累的永久内力。

公式实现集中放 `lib/features/battle/domain/`(`damage_calculator.dart` 伤害 + `derived_stats.dart` 派生属性,系数全从 `numbers.yaml` 读),**任何战斗结果计算都必须走这里**,禁止在 Widget 或 Notifier 里散写。散功流程封装在 `lib/features/dispel/application/dispel_service.dart` + `lib/core/domain/technique.dart`(`TechniqueDispersion`)。

## 7. 当前开发阶段

**阶段：1.0 长线打磨期**（2026-06-11 用户定调）——Demo 里程碑已完成（下表 §8.4 14/14 全达标，留作内容量历史锚），1.0 内容周期已闭环。**长期打磨游戏质量，不设上线时间压力**；Steam/法律等外部项不催，性能实机/beta 等在打磨自然成熟后做。

**打磨期工作原则**（用户拍板，规划任何任务前必守）：
- **不用 Demo/冲刺心态规划任务**：不为赶进度切「最小闭环」，方案对比时质量优先于工期。
- **能一次做全面的就一次做全面**：不偷懒先挑简单的活做、把难活硬活留成一堆后期工作。
- **backlog 只承载两类项**：依赖未解除的、需用户拍板的。「本次没空做/偷懒没做」不是合法的 backlog 理由。

Demo 必交付内容量（已全部达标）：

| 项目 | 数量 |
|---|---|
| 主线关卡 | 15–20 |
| 章节 | 3 章（学武出山 / 武林初识 / 名扬江湖） |
| 主线剧情字数 | 3,000–7,000 |
| **爬塔** | **30 层（3 小 Boss [5 / 15 / 25 层] + 3 大 Boss [10 / 20 / 30 层]）** |
| 闭关地图 | 5 |
| 武学领悟触发（techniqueInsight encounter） | 20–30 |
| 基础奇遇（fortuneEvent，非节日） | 15–25 |
| 节日 encounter（festivalRequired 独立通道） | 6–10 |
| 装备 | 30–50（覆盖 7 阶，每阶 5–7） |
| 心法 | 20–30（覆盖 7 阶 + 3 流派） |
| 典故 | 50–80 段 |
| 武学领悟招式 | 30–50 招 |
| 心法相生组合 | ≥ 5 |
| 师徒角色 | 祖师 + 大弟子 + 二弟子（共 3） |

**扩展系统现状**（v1.24 更新）：江湖恩怨/声望（P1.2）、心魔（Batch 2.x）、帮派门派（P4.1）、轻功对决（P3.1）、群战守城（P3.2）、第二条主线 Ch4-6、多代飞升/真传位（P5+）均已在 1.0 周期实装。**PVP 已切除**：不保留玩家入口、路由、service/provider、占位 UI 或玩法配置；`StageType.pvp` 与 `PvpRecord`/`PvpSnapshot` 仅作旧档兼容忽略。**仍然不做**：GDD §2.1 反主流清单（见 §5.1，永久红线）+ PVP + MOD / 跨周目元数据 / 节日活动系统级框架（GDD §12.4，1.0 后评估）——动这几项前必须先与人类讨论。

## 8. 工作流

### 8.0 可恢复任务协议

长任务、跨模块任务、并行开发任务默认按「可恢复计划」执行,目标是用量限制/线程中断后能从最后一个稳定点继续,不丢上下文也不重复返工。

**主窗口职责**:
- 只做调度、方案拍板、状态检查、续跑、复核、合并顺序管理;不要在主窗口吞下大量实现细节。
- 为每个独立任务开独立分支/worktree/线程,分支名前缀按当前工具约定走 `codex/` 或项目既有规范。
- 定期查看子线程状态;对子线程 `idle` 但未完成的任务发续跑指令;对依赖阻塞任务等前置分支稳定后再唤醒。

**子任务计划文件**:
- 每个子任务必须有 `docs/superpowers/plans/<date>-<topic>.md`。
- 计划文件至少包含:目标、分支、验收标准、任务切片、当前恢复点。
- 「当前恢复点」必须写清:状态、最后完成、下一步、已跑验证、阻塞项。

**执行纪律**:
- 每个子线程只处理一个明确切片,不要把设计、多个大功能、全量测试、合并都塞进同一线程。
- 每完成一个可独立验证的小切片就 commit 一次,并同步更新计划文件的恢复点。
- 接近中断、测试失败、依赖未满足或需要人类拍板时,先更新恢复点再停。
- **测试节奏(v1.29·别无脑全量)**:自包含改动(纯资产/文案/单 feature 表现层)只跑 targeted + `flutter analyze`,不跑全量;跨切面改动(numbers/结算/schema/saveVer/公式/全仓 sed/迁移)或批末合并才跑全量。全量默认用**并发** `flutter test --no-pub`(10 核实测 2m34s / 3587 pass 0 fail·2026-07-03),`-j1` 慢 3.8×,仅排查隔离型 flaky 时临时用。大范围视觉验收由主窗口在合并前统一安排。
- **交接/开局不无脑全量**:session 开始若 `HEAD=origin/main` + 工作树干净 + 上会话已验绿并 push(PROGRESS/session 文档记录在案)→ 只 `flutter analyze` 即可,跳过全量(绿状态已是记录事实);仅当树脏、或要在此基础上做跨切面大改时才开局全量。
- 依赖型任务不提前空转,不复制前置分支尚未稳定的 API;等待主窗口唤醒。

| 端 | 工具 | 写什么 |
|---|---|---|
| Mac | Claude Code + Opus 4.7 | `lib/` / `data/` 全部(`*.yaml` 数值 + `narratives/` + `lore/` + `events/` 文案) / `test/` / `GDD.md` |

**汇合**:GitHub 主分支(`Zed1118/wuxia_idle`)。**单端写入,无跨端冲突**(v1.8 起 DeepSeek 端退役)。

**Windows 端 AI 工具已全下线**(2026-06-11 用户拍板):Pen Windows 不再参与任何 AI 工作流(视觉验收/代码备份/文案全停)。视觉验收唯一在 **Mac 本地 Codex**;Windows 仅作为发布目标平台,ship 前实机验证(D 段)时人工操作。

### 8.1 数值与文案的联结约定

`data/encounters.yaml`（数值与触发条件）与 `data/events/<id>.yaml`（文案）通过 `id` 字段联结（v1.8 起两端均你写）。**`id` 必须严格相等且唯一**，加载时若任一端缺失对应 id 直接抛错而非静默跳过。

**示例**：

```yaml
# data/encounters.yaml （你写：纯数值与触发条件）
- id: bamboo_listen_rain
  type: technique_insight        # 类型枚举：领悟 / 奇缘 / 试炼 / 因果
  trigger:
    biome: bamboo_forest
    weather: rain
    enemy_class: swordsman
    kill_count_threshold: 100
  fortune_required: 8            # 机缘属性门槛
  unlock_technique_id: ting_yu_jian
  cooldown_days: 30
```

```yaml
# data/events/bamboo_listen_rain.yaml （你写：纯文案）
id: bamboo_listen_rain           # 必须与 encounters.yaml 完全一致
title: 听雨悟剑
opening: |
  竹叶上水珠成串而下，雨声渐密。你伫立林间，
  忽觉百日来斩落的剑影，皆与雨势暗合……
choices:
  - text: 闭目静听
    outcome: insight
  - text: 拔剑试招
    outcome: practice
```

同样的 fail-fast 规则适用于装备 (`equipment.yaml` ↔ `lore/<equipment_id>.yaml`,`_validatePresetLoreReferences` 启动期抛错)。**关卡叙事口径不同(v1.28 如实订正)**:`stages.yaml`/`towers.yaml` ↔ `narratives/<id>.yaml` 缺文件**不抛错**,`NarrativeLoader` 走「[剧情待补]」placeholder 兜底(见 `lib/data/narrative_loader.dart` 头注),完整性由 `test/tools/asset_audit.dart` 与 pubspec 声明守卫测兜底,不属加载期强校验。

### 8.2 Codex/Claude 协作交付门槛与合并 Gate

> 2026-06-29 v1.26 固化:3 梯队批量合并验证「Codex 产任务 + Claude 合并审核」工作流有效后定为长期 exit criteria。换线程 / 压缩上下文 / 多人并行时按此守,防漂移。Codex 规划任务、Claude 合并审核共同遵守。**Codex 在规划任务时必须先读 `docs/spec/rejected_task_registry.md`,再把本节 §8.2 转成该任务的验收 checklist**(逐项落到子任务计划文件的验收标准里),不得只在脑内默认。

**Codex 子任务交付标准**(恢复点/交付说明必带,缺项视作未交付不可合):
1. **生产接线证据**——接入真实 production path,非停在 fixture/demo/孤立组件;说明入口与消费方在哪。
2. **targeted test 结果**——至少跑任务直接相关测试,贴命令 + 通过数(不能只 analyze)。
3. **红线影响说明**——是否触及数值硬红线 / 三系锁死 / 在线=离线 / §5.1 反主流不做项 / 文案数值不硬编码;触及则附守门测试或验证方式。
4. **残留风险**——未覆盖测试 / 未目检 / 日志噪声 / 性能 / 数据迁移风险列清。
- **UI/UX 任务加码**:widget test 外必顾常规桌面视口——做 1280×720 / 1440×900 visual smoke,**禁只用超高视口(如 1024×2400)证「内容存在」**(证不了常规窗口体验);改交互组件(按钮/输入等)须验 semantics / 键盘激活 / focus / mouse cursor(`InkWell`→`GestureDetector` 一类改动易丢这些桌面语义)。
- **外部审查只进 triage**:WorkBuddy 等外部报告**先证伪再修复**,false positive 多、前提常错,**不得直接转任务清单照单执行**。

**Claude 合并审核 Gate**(合每个 Codex 分支前逐项过):核上述 4 证据齐全 + UI 视口/视觉口径 + 外审项已证伪;另查 ⓐ 无中文文案 / 数值常量散写进 Dart ⓑ 无高频路径 debug 日志噪声(如 `build()` 内 `debugPrint` 随 rebuild 刷屏)ⓒ 无误提交(未清 worktree / 未跟踪文件 / capture 目录 / 临时文档 / `.g.dart` / log / 截图,**用户指定保留的 worktree/分支除外**)ⓓ commit message 守 §11 中文动宾(2026-07-13 三批英文前缀 drift 后补入 gate)。

**批次合并后必做**(每梯队/批末):`flutter analyze` 0 issue → 相关 targeted tests → 批末一次全量 `flutter test --no-pub`(默认并发·10 核 ~2.5min;`-j1` 仅排查 flaky) → UI 密集改动至少一轮常规桌面视口 smoke → 清理或归档已合并 worktree/分支 + capture 文件(**用户指定保留的除外**)→ PROGRESS 顶段更新区分四态:**已完成 / 已验证 / 已知风险 / 下批建议**(避免 N 个分支各自堆叠进度段)。

### 8.3 Codex→Claude 就绪信号(git 原生标记)

> 2026-06-29 v1.27 新增。解决并行 race:codex 在多个 worktree 持续写,Claude 负责评审+合并,但无显式「写完了」信号时 Claude 分不清哪个分支是冻结可评、哪个还在写(tip 随时变 / 工作区脏)→ 只能逐个问用户。本节用 git 自带的 tip commit 消息做信号,无新文件、单一事实源、主分支可见、freeze 自动判定。

**Codex 任务写完时必做(否则视为未交付,Claude 不会碰)**:
1. **冻结 worktree**:所有改动 commit,工作区干净(`git status` 无未提交实质改动 / 无未跟踪源码或 plan)。tip 不再变动。
2. **打就绪标记**:让分支 **tip commit 的消息前缀** = `[READY]`(写完待评)或 `[BLOCKED]`(需用户拍板,不要合)。其余任何前缀一律视为 `WIP`(进行中)。标记可用最后一个真实 commit 直接带该前缀,也可追加空 commit:`git commit --allow-empty -m "[READY] <一句话交付摘要>"`。
3. 仍按 §8.0 在 plan 文件恢复点写清状态/验证/阻塞(供 Claude 读交付证据),但**就绪与否以 tip 前缀为准**(plan 文本会漂移,git tip 不会)。

**Claude 评审/合并纪律(扫 tip 前缀,不问用户)**:
- 一个分支同时满足 ⓐ `git log -1 --format=%s <branch>` 以 `[READY]` 开头 ⓑ 对应 worktree `git status` 干净 → 进入 §8.2 合并 Gate 评审。
- tip 前缀是 `[BLOCKED]` → **不合**,把待拍板点汇报用户。
- tip 不以 `[READY]` 开头(WIP)或 worktree 脏 → **跳过不碰**,等 codex 冻结。
- **freeze 自动判定**:评审某分支后、合并前 codex 又提交(tip 变了、不再是当初那个 `[READY]`)→ 视为又进 WIP,本轮不合,等下次重新冻结。
- 合并通过后 `git branch -d`(就绪标记随分支消失,无残留;用户指定保留的分支除外)。

**例外**:用户显式点名「现在评审 X 分支」→ 直接走 §8.2,不要求先打 `[READY]`。

## 9. 不要做的事（操作清单）

❌ Dart 代码里写硬编码数值（`damage = 1500`、`hp = 5000`）
❌ Dart 代码里写中文字符串文案（`"你战胜了山贼头子"`）
❌ 引入其他状态管理库（已锁定 Riverpod 3.x）
❌ 引入第三方游戏引擎（Flame、Forge2D 等）
❌ 未经讨论实装仍未启动的扩展（MOD / 跨周目元数据 / 节日系统级框架，见 §7）
❌ 给玩家做"每日任务""登录奖励""快进券""传统体力"等留存机制；扫荡战备 / 副本凭证 / 劳损调息只允许按 GDD §2.3 的非日课边界实现
❌ 让任何系统的数值突破 §5.4 的红线
❌ 让 yaml 配置在没有 schema 校验的情况下被静默接受
❌ 让 `data/encounters.yaml` 的 id 与 `data/events/` 下文件名失联（加载层必须强校验）
❌ 用 Material 默认饱和色彩——基调是水墨克制（青、墨、宣纸黄、绛红点缀）
❌ 写教程弹窗——用剧情、气泡提示、百科三种方式（见 GDD §10.2）
❌ 让"低境界 + 神物装备"或"低境界 + 高阶心法"的组合在任何代码路径上能跑通（**师承遗物也不例外**）

### §9.1 执行端操作坑速查（2026-08-05 从 Claude memory 沉降，所有执行端必读）

- fresh worktree 里 `libisar.dylib` 会被截断：跑测试前从主仓拷完整 dylib
- `.g.dart` 已 gitignore：fresh checkout / merge schema 批后必跑 `dart run build_runner build`，否则静默丢字段或编译红
- 两套色板不可混用：深色底用 `WuxiaColors.text*`，浅宣纸底用 `WuxiaUi.ink / muted`
- `WuxiaPaperPanel` 滚动列表 tile 外层包 `IntrinsicHeight`（内部 StackFit.expand 遇无界高度会炸）
- `Image.asset` 一律带 `errorBuilder`（守 widget test 与 release 布局）
- sub-screen 加 Tab 前检查有无 AppBar：无 AppBar 的 TabBar 页会卡死
- 需要确定性的逻辑走 `rngProvider`，不要新接 `dart:math Random` 签名的 service（会绕开 override）；确定性测试在纯函数层 stub
- 编辑 `stages.yaml` 从 `- id:` 正向定位目标关卡，禁从 `isBossStage` 反搜
- `flutter test` 传多个显式文件路径可能静默漏跑：验收逐文件确认「All tests passed」出现次数
- `testWidgets` 体内不要 await 真 IO（dart:io / Isar 会挂 10min）：init 收进 `setUp` 或 `tester.runAsync`
- 测试不得绕开生产路径（手设字段/手动改队列/常量比自己）：自检「破坏那行生产代码，这条断言必然红吗」
- 列表行悬停浮层用 `IgnorePointer` 包纯展示层，否则浮层盖后续行吃鼠标事件

## 10. 拿不准时的处理顺序

1. 查 `GDD.md` 对应章节（用 §1 的快速索引定位）
2. 查 §12 待人类决策清单——是否在已登记的未决项中？
3. 查 `data/*.yaml` 既有结构是否已暗示约定
4. 查同类 feature 下已实现代码的模式
5. 仍不清楚 → **停下来问人类**，不要凭推测落代码

## 11. 提交规范

- commit message 用中文，动宾结构，简明
- 涉及 GDD 修改：标题前加 `[GDD]`，并简述变更影响范围
- 涉及数值平衡：标题前加 `[balance]`
- 涉及配置 schema 变化：标题前加 `[schema]`，并在 PR 描述中列影响的 yaml 文件
- 普通代码改动可省略前缀

## 12. 待人类决策清单（v1.5 收口 · §12.1 清零）

> v1.5（2026-05-16）：§12.1 #10 师承遗物规则层 4 子项决议收口（详 v1.5 变更摘要 + §12.2 归档），**§12.1 真硬阻塞清零**。所有 13 条原始待决条目已 100% 收口(11 条 yaml/代码层默认决议 + 2 条本批方案 A / v1.4 / v1.5 决议)。完整销账见 §12.2 归档。

### §12.1 未决项

**无**(2026-05-16 v1.5 全收口)。后续进 Phase 5 师徒系统升级 / 1.0 版本扩展系统时若出现新待决项,在此区段重开。

`#12` 江湖商店 Demo 不列(`§7` 内容总量表无)— 已知 Demo 不阻塞挂账,Phase 5+ 自然实装时再回头。(`#11` 祖师爷 buff 已于 2026-05-21 P1.1 候选 2 激活,详 §12.2 #11 v1.9 更新)

### §12.2 已消解归档（W1-W15 实装中默认决议）

| # | 条目 | 实质决议位置 |
|---|---|---|
| 1 | 境界 7 层 vs 修炼度 9 层名重叠 | 代码层严格不同名：境界用「启蒙/入门/熟练/精通/圆熟/化境/登峰」，修炼度用「初窥/小成/中成/大成/圆满/巅峰/通神/无瑕/极境」，见 `lib/features/battle/domain/enum_localizations.dart`（`RealmLayer.qiMeng / dengFeng` + `CultivationLayer.wuXia / jiJing`，符号引用不钉行号防 drift） |
| 2 | 单项属性范围 | `numbers.yaml character.attributes`：单项 [1,10] / 总和 [16,24] / 正态 μ=5.5 σ=1.5 / `rerollable: false` |
| 3 | 强化 +20-49 成功率与材料 | `numbers.yaml equipment.enhancement.success_curve`：`max(0.30, 0.50 - 0.02*(level-19))`，磨剑石 18/25 颗，心血结晶保底 8 颗 |
| 4 | 暴击系数 + 防御率 | `numbers.yaml combat.critical`：基础 7.5%，身法不再提供暴击；上限 50%，倍率 1.5-2.5（灵巧固定 2.0）。防御率走 `realms.tiers.defense_rate` 按境界固定档（学徒 5%→武圣 35%） |
| 5 | 闭关产出公式 | `numbers.yaml retreat`:5 地图 base_outputs + 双倍率 `realm_scale_per_tier: 1.3`(银两/材料/心法/内力)+ `experience_realm_scale_per_tier: 1.65`(经验专用,2026-07-19 拆分防速率倒挂);前 `cap_hours: 72` 是地图完整收益阶段,溢出转无上限 `passive_idle`(其被动经验专用倍率 1.6);装备每12h判定、最多6次、无保底(2026-07-12 决议) |
| 6 | 武学领悟与普通奇遇概率 | 不单独累积“机缘值”。`techniqueInsight` 使用悟性：`p = baseProbability × (1 + enlightenment/20)`；其他奇遇使用机缘：`p = baseProbability × (1 + fortune/20)`。统一规则见 `numbers.yaml attribute_effects` + `AttributeEffectPolicy`。 |
| 8 | 心法速度加成 | `numbers.yaml techniques.tiers[*].speed_bonus`：7 阶 0/5/10/15/25/40/60，直接进 GDD §5.6 公式，无独立上限 |
| 9 | 人剑合一招式定义位置 | `numbers.yaml combat.resonance.unlocks_joint_skill: true`（默契阶段解锁）+ `skills.reference_multipliers.joint_skill.base: 4500`，**统一固定倍率，不绑流派/不绑装备类型**，由共鸣度系统统管。**v1.9 补**:P1.1 候选 3-b(2026-05-21,commit `15ff8aa`)已实装 battle 释放路径 — `skills.yaml` `skill_joint_skill`(mult=4500 / cost=250 / cd=4)+ `ResonanceStageConfig.unlocksJointSkill/hasSwordSongEffect` 解析 + `battle_ai` 优先级 `pending>jointSkill>powerSkill>normalAttack`,红线 27,421 < 100,000 ✅ |
| 13 | 节气日完整清单 | v1.2 决议方案 A（2026-05-15）：12 个节气均匀覆盖四季，公历 hardcode 不引入农历库；删除原中秋（属农历节日非节气）。已落 `numbers.yaml retreat.solar_term_bonus.days_2026` |
| 7 | 三流派 extra_effect 数值 + 正午阳刚定向 | v1.4 决议（2026-05-16）：① 刚猛震伤每招 +500 固定(穿透防御不暴击,主攻击命中才触发);② 阴柔内伤 N=3 守方 tick × 200/tick 固定(穿透防御 + 同源刷新覆盖,可致死);③ 正午阳刚 +20% 乘到 `internalForcePoints` 维度且仅 `character.school==gangMeng` 触发;④ 灵巧 crit_rate +0.20 已在 §6 公式实装 (v1.0 起)。已落 `numbers.yaml combat.schools.gang_meng_quake / yin_rou_internal_injury / retreat.time_of_day_bonus[zhengWu].target_attribute & applies_to_school` + 代码层 damage_calculator 震伤分支 / BattleState internalInjurySlot / battle_engine tick 衰减 / seclusion_service 正午阳刚 wire |
| 10 | 师承遗物规则层(4 子项)| v1.5 决议(2026-05-16):① 传递时机:武圣飞升时自动传(GDD §7.1 原意);② 多徒弟归属:玩家进选件界面逐件分配;③ 累代叠加:只取当代不叠加(数值不爆炸 + UI 可显传承链路但 buff 不叠);④ 同部位冲突:自动卸下原装入背包 + 新遗物入槽。已落 `numbers.yaml inheritance.heritage_items` 加 4 规则字段。**v1.14 P2.3 已实装 ✅**(2026-05-24 Batch 3.1-3.3):①+② 真消费(LineagePanel→AscensionScreen→performAscend · player_pick DropdownButton 真分配);③+④ Demo 一代飞升不验证 YAGNI 留 P5+。**v1.15 P5+ 多代飞升 + 真传位完整实装 ✅**(2026-05-24,④+⑤ 合并 batch 4 commit `1e875d6 → 1b1bb86`):③ `stackAcrossGenerations=false` derived_stats §244 按 isLineageHeritage instance count 不按 prev len 累加(R5.8 防回退测) + ④ `conflictSlotResolution=auto_swap` 真消费 `AscendService.performAscend` 副作用 4(disciple 端 equipped{Slot}Id 接新遗物 · 旧装 owner 不变入背包语义) + **真传位**:`performAscend` 加 `promotedDiscipleId: int?` 可选参数 · `promotedDisciple.isFounder=true` · `founder.isFounder` 保 true 「太祖」语义 · `founder_buff_service` 0 代码改自然接管(active 中找 isFounder=true → buff 激活) + AscensionScreen 加 _PromotedDiscipleRow widget · R5 测族 14→18(R5.6 多代 e2e 2 + R5.7 auto_swap 2 + R5.8 stack enforce 1)。详 `docs/handoff/p5_lineage_full_closeout_2026-05-24.md`。 |
| 11 | 祖师爷门派 buff(v1.9 已激活)| **v1.9 反转**:P1.1 候选 2(2026-05-21,commit `a0eae82`)决议方案 E.5.A → `enabled_when_alive: true`,玩家=祖师自享 sect_wide_buff(internal_force_max_pct=0.05 / max_hp_pct=0.05 / crit_rate_bonus=0.02 / cultivation_progress_pct=0.03)。`apply_to_disciples_only: false` 即 active 中 founder + disciple 全员享。Phase 5+ 飞升后再切语义(founder 退 active → buff 作用于新一代继位者)。已落 `lib/features/inheritance/application/founder_buff_service.dart` + `derived_stats.dart` `maxHp / internalForceMaxWithLineage / criticalRate` 各加 `founderBuffActive` 可选参数 + `lineage_panel_screen.dart _FounderBuffSection` UI 显。**P1.1 简化**:玩家本人即 founder 自享 buff;cultivation_progress_pct 修炼度公式接入留 Phase 5+ |
| 12 | 江湖商店折扣公式(Demo 不列)| ~~Demo 内容总量表(§7)未列江湖商店,1.0 版需要时再补~~ **P4 材料经济 P1 已激活 ✅**(2026-06-21):固定货架·固定标价·无刷新·售炼器材料(磨剑石/心血结晶),银两货币(InventoryItem `item_silver`/`ItemType.silver`)·掉落+闭关产出·不卖出。**无折扣公式**(原「机缘定价」拍板废除,贴 §5.1)。GDD §6.1 同步改写。详 spec `docs/spec/2026-06-21-p4-material-economy-design.md`。**P2 新材料用途已激活 ✅**(2026-06-21):经验丹 3 档(凝神/培元/大还,调 `CharacterAdvancementService.applyExperience` 加经验推境界,守 isLayerLocked)+ 秘籍 9 本(对应 9 个 fragment 秘传招,`ItemUseService` inline `markUnlocked` 路径,**仅掉落不上货架**守 §5.7)+ 新建 `data/items.yaml` 道具效果配置层 + 背包"使用"入口。经验丹小/中上货架,大档/秘籍仅掉落。数值/掉落占位待 balance。详 spec/plan `2026-06-21-p4-material-economy-p2-{design,plan}.md` |

---

**遇到拿不准的设计决策，优先回到 `GDD.md`，查 §12 待决项，仍不清晰则停下来与人类确认。不自作主张是这个项目最重要的纪律。**
