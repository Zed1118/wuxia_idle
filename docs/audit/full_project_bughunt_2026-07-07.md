# 挂机武侠 · 全面体检找 bug 报告

**日期**:2026-07-07 · **基线**:main `5a71a876`(工作树干净)
**方法**:6 并行只读审计代理(战斗结算/状态管理/存档离线/新增diff/配置一致性/UI边界)+ 主会话对最高严重度逐条交叉证伪。与 07-02 全面审查(`full_project_review_2026-07-02.md`,偏工程面)互补,本轮火力集中**行为性 bug**。

## 实测基线(本会话)

- `flutter analyze`:1 info(docs/audit 探针文件名不合 snake_case,卫生项)· lib/test 干净
- 全量 `flutter test --no-pub`:开局 **3719 pass / 1 skip / 1 fail** → 失败为 `audit_paper_text_contrast_test`(今早 c599e8cb 字体批只跑 targeted 漏跑 tools 守卫,闭关地点标题浮实景浅字被词法误报)→ **已补豁免注解合入 `5a71a876`,守卫测回绿**。再证「scoped 绿 ≠ 全仓绿」。
- 红线:GDD §5.2 ↔ numbers.yaml `red_lines` 段(20000/15000/60000/2000/8000/1M/0.95)人读一致;可执行层随全量跑,balance 测全绿。

## P0(玩家可见 · 行为性 · 建议尽快修)

1. **群战守城波次+阵型在生产完全不生效**(主会话证伪坐实):wave 循环/formation 烘焙只在 `MassBattleStrategy.runToEnd`(`mass_battle_strategy.dart:86-127`),`tick`(:64-70)直接委派 DefaultGroundStrategy;生产 timer 只调 tick/stepOne,lib 全仓 `runToEnd` 零生产调用方。5 个 massBattle 关配的 `enemyTeamsPerWave` 与玩家选的阵型全部无效,实际只打 `stage.enemyTeam` 3 人一波。即 memory `feedback_strategy_immutable_vs_ui_tick` 同型坑。
2. **轻功对决地形修正同病**:terrain 烘焙只在 `light_foot_strategy.dart:65-73` 的 runToEnd;5 个 lightFoot 关的水面/屋脊/竹林修正全为 no-op。
3. **离线被动收益丢失+双吃**(坐实):`main.dart:64-78` 失焦/退出仅 `touchOnlineNow` 重置基准**不结算**,被动结算唯一入口 `home_feed_screen.dart:44`(启动一次)。app 常驻挂后台 8h→重新聚焦继续玩→收益静默清零;`onDetach` fire-and-forget 写不进→反向把在线时段双吃。违 §5.5 核心承诺。
4. **拖招插队常速下同角色一 tick 双出手、AP 变 -1000**:`default_ground_strategy.dart:198-201` 自述 interveneNow 须在 tick 边界调用,但常速播放走 `advanceOneAction`(mid-queue 常态,主会话证伪 `battle_playback_controller.dart:449`),`battle_screen.dart:290-306` 无边界检查。常速+interactive(首通强制)可触,伤战斗爽感主旋律。
5. **新档三个隐藏入口当次会话永不解锁**(坐实):`shopUnlockedProvider`/`equipmentCatalogCountProvider`/`bossMemoryCountProvider` 全仓 **0 invalidate**(grep 计数 0),主菜单栈底 watch 钉活缓存→首银两/首装备/首杀 Boss 后入口不出现,重启才解锁。

## P1(应排期)

6. **扫荡结算漏 invalidate 角色/装备/心法 family**(`sweep_settlement.dart:29-133` 只 invalidate mainlineProgress):整章扫荡后主菜单/角色面板/仓库全旧数据。W13-v3 修过的 bug 类在扫荡路径复发,正确写法就在 `stage_entry_flow.dart:374-380`。
7. **强化连点扣材料成负数**:校验用 UI 快照(`enhancement_service.dart:116-129`),`persistResult` txn 内不重查不 clamp,`enhance_dialog.dart` 按钮无 in-flight 守卫。同类:桃花岛升级 check-then-act 跨 txn+无防抖(`island_action_service.dart:127-171`)、settle 旧快照整覆盖 islandBuildings 可回滚升级(`island_settle_service.dart:140-160`)。
8. **塔首通掉落 invalidate 时序错**(`tower_entry_flow.dart:212-251`):invalidate 在 roll+落库**之前**,落库后无人再 invalidate→仓库看不到塔奖。
9. **敌方 ultimate 型招式 AI 永不释放**(坐实):`battle_ai.dart:142` 强力技 loop 只认 powerSkill,ultimate 只能走玩家 pending 或相位解锁;`enemy_erLiu_huiyi`/`enemy_tower_boss_30` kit 里的 ult(stages.yaml:729/1237)不在任何相位表→纯摆设,floor30 Boss 最强 AOE 从未用过。
10. **存档迁移段 2 无版本门**(`isar_setup.dart:288-297`):唯独此段缺 `_compareVersion` 门(段1/3/tower 都有),每次 saveVer bump 重跑 `#1` 周目键回填,污染周目首通判定。
11. **疗伤两处 invalidate 缺口**:战后面板不 invalidate character(`post_battle_healing_panel.dart:72-74`);伤势面板只 invalidate 面板角色但疗伤目标是全队最伤者(`injury_status_view.dart:114` vs `item_use_service.dart:147-172`)。
12. **心魔镜像立绘清空失效**(坐实):`inner_demon_service.dart:237` 传 `iconPath: null` 被 `battle_state.dart:576` copyWith `??` 吞→镜像顶玩家立绘而非首字降级。改 `_unset` 哨兵(同文件 internalInjury 已有先例)。
13. **InkEmptyState 空态文字近隐形**:body 从 ink2 迁 surface.secondary 后,深屏底×半透浅框合成底(~#837E72)上对比 3.1:1→~1.56:1。影响百科空 feed/招募无候选/兵器谱未加载(`ink_empty_state.dart:71`)。
14. **AOE 按命中数多倍记账**(需拍板语义):一次 AOE 打 3 人=修炼度/熟练度 +3(`default_ground_strategy.dart:549` 每 target 一条 action,`battle_resolution.dart:126-133` 逐条计数)。若意图「每施放记 1」是 bug,若「每命中记 1」补文档钉死。

## P2(拍板/防御/卫生,压缩列)

- 红线双轨:enforcement 硬编码(`game_repository.dart:1031` `>8000`/`:1214` `>2000`/`:1037` tierCaps 数组)vs `RedLinesConfig` 读 yaml,改 yaml 只动 debug 面板不动真校验(boss_hp_max 已 config-driven,同文件风格不一)。
- numbers.yaml 死配置未标注(违 `feedback_yaml_config_unused_field`):`equipment.tiers` 整段(equipment.yaml 头注声称对齐实无 enforcement)、`techniques.tiers[].max_skill_multiplier`(普通心法不执行 per-tier)、`character.attributes`+`rarity_distribution`(稀有度写死 biaoZhun 概率表从未 roll)、`inheritance.unlock_rules`、`internal_force_growth_bonus`。
- 战斗防御缺口:相位蓄力无内力校验可扣负(`default_ground_strategy.dart:648-664`);蓄力释放目标列表来自重新 decide 的另一招(数据一变即炸,:416-418);踉跄不消费 pendingUltimates 违「一次机会」文档;`_playTimer` cancel 不置 null 致结束边沿空转 timer;runToEnd 波间不清 actorQueue(修 P0-1 时会暴露)。
- 存档防御:closeRetreat 无 status 守卫(新调用点即双发奖);闭关地图 def 丢失无兜底可锁死战斗入口;时钟回拨白关一场;`@enumerated` ordinal 存储枚举永不可重排(约束提醒)。
- UI:桃花岛热点 720p 低高度 PLAUSIBLE 溢出(`taohua_island_screen.dart:383-430`,需真机定性);装备摘要卡 348px 属性行贴边;闭关进度条 durationHours==0 无守卫(当前数据安全);`_onUse` async gap 后先用 ref 后查 mounted(`inventory_screen.dart:1449-1453`)。
- 卫生:docs/audit 探针 dart 文件名不合 snake_case(analyze 唯一 issue);`shop_screen.dart:405` technique_clue 死分支;shop.yaml itemType 与 items.yaml type 无交叉校验;equipment specialSkillCandidates 不进红线(配错 id 无声不生效);`item-icons-wire` worktree 已合入未清理。
- 审计盲区注记:UI 代理被 session limit 打断,sect/tower/shop 深层 dialog 的 Row 溢出扫描与 720p 真机验证未覆盖;yaml 代理的 skills.yaml visualEffect 映射/lore 交叉引用未覆盖。

## 修复候选表(附推荐)

| # | 批次 | 内容 | 模型 | 预估 | 备注 |
|---|---|---|---|---|---|
| 1 | **离线结算闭环(推荐先做)** | P0-3:失焦结算或统一基准写入者 | opus xhigh | 半天 | §5.5 核心承诺,挂机游戏命门;并发/生命周期属 xhigh 域 |
| 2 | **战斗 wiring 批** | P0-1/2(wave/formation/terrain 进 tick 路径)+P2 波间清队 | opus xhigh | 半天-1天 | 跨 strategy 结构改,配 memory 同型坑 spec 维度 grep;修完 battle_engine 死代码(07-02 P1-7)一并拍板 |
| 3 | **invalidate 速修批** | P0-5+P1-6/8/11(统一战后/道具后 invalidate helper 或门控改 watchLazy) | opus high | ~2h | 同根问题一把收;sect_providers 有 watchLazy 先例 |
| 4 | **战斗小修批** | P0-4(interveneNow 边界)+P1-9(ultimate 进 AI)+P1-12(iconPath 哨兵) | opus high | ~2-3h | P1-9 或需 balance 复测(Boss 强度会真变) |
| 5 | 存档/负数防御批 | P1-7(txn 内校验+防抖)+P1-10(段2版本门)+P2 存档防御 | opus high | ~3h | 迁移改动附守卫测 |
| 6 | 视觉/空态批 | P1-13 InkEmptyState+P2 UI 项+720p 真机补验 | opus high | ~2h | 配视觉验收 |
| 7 | 配置收账批 | P2 红线双轨统一读 config+死配置段 ⚠️ 标注/砍 | opus high | ~2h | 部分需拍板(rarity 表接不接) |

推荐顺序 **1→3→2→4**:1 是产品承诺级;3 便宜且新手可见;2 改动面大单独一波;4 里 P1-9 会改 Boss 难度需拍板。P1-14 AOE 记账语义先拍板再归批。

---
*生成:2026-07-07 全面体检会话(6 并行审计代理+主会话交叉证伪);上一份为 full_project_review_2026-07-02.md(工程面),两份合看。*
