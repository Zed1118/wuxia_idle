# 可玩性加强 · 二期 Backlog（P1a 之后的滚动任务清单）

> 滚动文档,不带日期。每推进一项就勾选/更新,不重复写。
> **上游 master spec**:`docs/spec/playability_upgrade_master_spec_2026-06-09.md`(P0-P4 全规划 + §16 待确认)
> **P1a 实施 spec**:`docs/spec/2026-06-09-playability-p1a-cultivation-core-design.md`(养成内核,待落)
> **用途**:汇总 P1a 砍掉/推迟/默认拍板/待复核的所有项 + master spec 后续阶段指针,作为二期任务继续推进。
> **每条格式**:`[ ] 任务 — 一句话 + 指针(master spec §x / GDD §x)`。

---

## 一 · P1a 内已推迟(P1a spec §5「P1a 不做」)

- [x] **技能装配限制 UI**(§2.6):~~P1b 2026-06-10 落地~~(6 槽装配栏 + picker gate);波A 2026-06-11 扩第 7 破招槽(`keySkillId`,canInterrupt && style==school gate)。
- [x] **藏经阁 screen**:~~P1b 2026-06-10 落地~~(CangJingGeScreen 出战配置+武学库+残页区);波A 扩破招槽 tile。
- [x] **统一进度展示组件 wiring**(§三):~~2026-06-12 落地~~(spec `docs/superpowers/specs/2026-06-12-progress-stage-row-unification-design.md`)。固化纯表现层基元 `StageProgressRow`(五要素:阶段名/进度条 MeridianBar/当前效果/下一阶效果/来源)。三系统已接:熟练度→藏经阁 `skill_proficiency_row` · 修炼度→角色面板 `character_panel_screen:1601`+技能面板 `technique_panel_screen:528`(补倍率文案=原最大缺口) · 共鸣度→装备详情 `equipment_detail_screen:427`。残页 spec §⑤ 有意保留 `FragmentProgressRow` 独立(天然无阶段语义,只视觉对齐)。2026-06-20 续30 Phase 0 复核确认全接入,checkbox 此前 stale 未勾(`feedback_living_doc_state_drift`)。**扩到胜利弹窗/掉落 overlay/师承面板等奖励反馈语境=新范围,原 spec 故意排除,待拍板再开。**
- [x] **24 招全内容**(波B 2026-06-11):真解 6(章末 Boss 首通 · 同招=Boss 蓄力技双用 canon)+ 塔残页 6(Boss 层全配)+ 章末重打残页 3(Ch4-6 farm)+ 破招 3 = 玩家侧流派 6/6/6;Boss 技 6 = 真解双用。14 新招全内容(名/流派/倍率/效果/文案);装配池 wiring(resolver/picker/equip gate/武学库秘传组)+ standalone 招熟练度落账修复一并收口。spec `2026-06-11-wave-b-24-skills-content-design.md`。
- [x] **战报诊断规则**(§11.4):~~killed_by_charge / mob_overrun 失败复盘提示 + jump_target~~ 已实装(第七阶段:`BattleDiagnosis` 5 规则 + `DiagnosisJumpTarget{skills,equipment,cultivation}` + `battle_screen._handleDiagnosisJump`,进 victory_overlay)。
- [x] **per-skill 熟练度效果铺广**(波A 2026-06-11):53 ultimate(含 6 轻功)流派模板(刚猛伤害加速/灵巧CD/阴柔混合)+ 真解/招牌手工高半档;化境 damage_pct 系死配置(combinedMult cap 1.30)改 CD。normalAttack/powerSkill 留全局曲线(4 key 词汇表下无差异化空间,设计立场非砍量)。

## 二 · P1a 默认拍板(用了默认值,二期可推翻)

- [ ] **残页集齐数量**:P1a 取 §16 #4 默认 = 真解 1 本即解锁 / 爬塔残页 5 片一套(进 numbers.yaml)。实玩后可调。
- [x] **奇遇旧 unlock 池不并入新结构**:~~两套并存~~ 波A A4 已统一迁入 skillUnlockProgress(0.18 迁移);波B 装配池 wiring 后 drop/奇遇消费全走新池。
- [x] **§9.1 破招技按 build gate**(波A 2026-06-11):拆 fromCharacter 广发硬编码,三流派破招技各一(破势/截影/拂脉,SkillDef.style 红线)走第 7 装配槽;autoFill 自动填本流派 + 旧档 fallback 等价,P0 手感不倒退。

## 三 · P1b(P1 的表现层半,P1a 之后接着做)

- [x] 藏经阁 screen(见一,P1b 落地)。
- [x] 统一进度展示组件 wiring(见一,2026-06-12 落地 · 续30 复核确认)。
- [x] 技能装配限制 UI(见一,P1b 落地 + 波A 破招槽)。
- [x] P1 验收项收口(P1b 落地:藏经阁阶段效果可见 + picker 境界 gate 灰显;波A 加流派 gate)。

## 四 · master spec 后续阶段(P2/P3/P4,仅指针,细案见 master spec)

- [~] **P2 队伍成长与三人协同**(master spec §四 / §13 P2):**协同深度 + ①渐进解锁 + ④控制倾向已实装**(第六阶段破绽窗口 `2026-06-18-phase6-coop-break-window-*` · 第七阶段批三 `disciple_join_service` 开局单人→收徒扩队 · `LineageRole.senior/junior` + senior 破防倾向)。**续作待拍板(非漏做)**:② 出战编成/换人 UI(grep 零命中·挂机是否需手动换队=设计决策)③ Boss 协同窗口(「敌方协同」新概念·先讨论范围再动)。
- [x] **P3 Boss 标准与战后体验**(§六 / §七 / §13 P3):全部已实装(2026-06-18 批一战后体验:英雄镜头 `HeroCameraData`/珍稀掉落仪式/战后复盘三段式 `BattleDiagnosis` + jump_target · 2026-06-19 批二 Boss 机制:`bossPhases` 多阶段/`schoolDamageTakenMult` 弱点抗性 ×1.25·×0.75/会心 glyph/技能珍稀卷轴)。**仅余 Boss 协同窗口移交 P2③**(待讨论范围)。
- [x] **P4 长期档案与探索联动**(§八 / §九 / §13 P4):**全 6 子项闭环**(续31-41:战绩册 `4669fbac` / 兵器谱 `2e4b7ed6` / 材料经济 `5f3899fb` / 门派谱1.1 `4cfc1565` / 奇遇录 `fe4c0751` / 藏经阁2.0 武学图鉴)。均纯展示层(材料经济含真消费:经验丹/秘籍/银两)。

## 五 · §16 待确认问题(P1a 收了部分,其余留对应阶段拍板)

- [x] #1 首批 24 技能:P1a 收**框架 + 最小集**;24 招全内容留(见一)。
- [x] #2 主线 3 + 爬塔 3 Boss 机制细案:P3 已实装(`bossPhases` 多阶段+蓄力反扑+aiMode / 弱点抗性 `schoolDamageTakenMult`)。
- [x] #3 熟练度走不走闭关:P1a 定**否**(只看战斗放招,含挂机自动战斗)。
- [x] #4 残页集齐数量:P1a 默认真解 1 / 残页 5(可推翻,见二)。
- [x] #5 珍稀材料名称与用途:P4 材料经济 P1/P2 已实装(银两 `item_silver` + 经验丹 3 档 `jingYanDan` + 秘籍 9 本 `techniqueScroll` + `ItemUseService` + 江湖商店货架)。
- [x] #6 英雄镜头美术方案:P3 已实装(`HeroCameraData` + `hero_camera_overlay` 立绘切入定格 · 续26/30 真机目检 PASS)。
- [x] #7 藏经阁/兵器谱/战绩册/门派谱解锁时机:P4 已实装(战绩册首胜 / 兵器谱获得任一装备 / 藏经阁2.0 习招点亮 / 门派谱世代 · 各档案入口隐藏式解锁守 §5.7)。

## 六 · P1a 实装期新增 deferred(Phase 0 发现 · 2026-06-10)

- [x] **残页内容挂载 + tower flow wire**（2026-06-10 完成 · `f4b1c7b2`）：残页机制(SkillUnlockEntry.fragmentCount / addFragment 阈值解锁 / StageDef.dropSkillFragmentId / 红线 / hook fragment 分支)已**完整 + 单测覆盖**(stage_skill_drop_hook_test fragment 用例)。但爬塔楼层在 `data/towers.yaml`(独立 def 类型,非 StageDef),无法用 stages.yaml 的 dropSkillFragmentId 字段挂载;且 `tower_entry_flow.dart` 未 wire skill drop hook。**真解(主线)已全 wire+测,残页只差内容挂载**:需 towers.yaml schema 扩 dropSkillFragmentId + tower flow 调 runStageSkillDropHookAfterVictory(P0-READ tower 首通/重打判定)。 **已落**:`TowerFloorDef.dropSkillFragmentId` + 红线(仅Boss/id存在)+ hook 泛化(`_applySkillDrop` 核心 + Stage/Tower 两 wrapper)+ tower_entry_flow wire(floor 10/20 残页 · 每次Boss胜利 rng 掉,非首通限定)。
- [x] **解锁态消费**:P1b 装配槽注入 + 波A A4 收口(unlockedSkillIdSetProvider 单一真相源,奇遇 picker/character_panel 真消费 isUnlocked)。
- [x] **interrupt_power_pct 实装**(波A 2026-06-11 · 用户拍 b 方向):踉跄减防 = base × (1+当阶 pct) clamp `interrupt_power_cap` 0.5 红线;三破招技差异化(深度/窗口/均衡型)。
- [x] **source tag**(波A 2026-06-11):SkillDef.source 5 枚举,skills+encounter_skills **210 招**全量回填 + 5 条红线;奇遇旧池同步迁入 skillUnlockProgress(0.18 迁移)。消费方=红线+P4 藏经阁来源显示。
- [x] **高熟练度全量平衡扫描**(波B 2026-06-11 全表版):30 mainline × floor/ceiling × uses{0,800} × 25 seed 全表 sweep 入 balance_simulator(常驻测,容噪 10pt 单调断言 + mean delta ≥ 0)。首跑 mean +8.3pt 全过;蓄力 Boss 难度面变化一并入读数(01_05 floor 变易 / 05_05 ceiling fresh 0%→满熟练 76%,熟练度成跨阶杠杆)。难度微调候选待用户真玩拍板。

## 七 · 音频二期(v1 接入后的滚动项 · 2026-06-10 起)

- [x] **jingle 扩槽**:~~victory/rareDrop~~(2026-06-10 迭代1)+ ~~defeat/realmAdvance~~(2026-06-11 `3fb2ebc9`:defeat 接「敗」overlay / realmAdvance 接跨 tier 大境界突破〔主线+塔 dialog+闭关收功三处〕,同 dialog 优先于 reward 不叠播;素材 V1 推荐 3s 剪辑版与 victory 同产线)。四槽全收口,听感待用户终验。
- [x] **uiPaperOpen 素材**(2026-06-12 完成):Suno 已产出,用户听选 `uiPaperOpen_v1_01`(宣纸轻展 0.55s)落位 `assets/audio/sfx/`,接线 + 守卫测齐(`audio_assets_test.dart`)。
- [ ] **转用素材听感复核**:battleUlt(realmAdvance_v2_01 裁 2.4s)/ battleChargeStart(defeat_v2_02 负向预警)是转用,真玩听感不合再重打专属 prompt。
- [x] **扩展 BGM 8 轨**(波C 2026-06-12 `461c1e9a`):mainline/tower/boss/innerDemon/lightFoot/massBattle/lineage/baike 全接线(`BgmTrack` enum + `bgmTrackForStage` 路由 + 各 screen hook);A/B 验收 8 轨全采用 candidate_01。

## 八 · 阶段性审查发现技术债(2026-06-22)

- [x] **战报 `_formatAction` 死字段 + 双轨战报架构梳理(T13)**:已清(`15d4235b`)。实测攻击行动(attackResult!=null)的 description 从不显示——`BattleLog.formatAction` 从 attackResult 重格式化(闪避率/克制/效果/击杀全覆盖)才是 live 路径,description 仅 `battle_log.dart:37` 非攻击兜底(attackResult==null) + toString debug 读,无回放读(replay 按 seed 重跑)。故删 `_formatAction`(连带消其 5 处 §5.6 散写中文),攻击 description 留空 · 破招仍记 EnumL10n(合法 sink) · 非攻击 description(staggered/charging/phase 转换·EnumL10n)不动。无测试依赖其产出。

## 九 · 战斗体验打磨(第五阶段 · 2026-06-23)

- [ ] **战斗节奏真机校值**:A+C 已实装(spec/plan `2026-06-23-battle-pacing-readability-*` · 合 main)。初值 `action_interval_ms=1000`/`key_moment_hold_ms=400`/`damage_popup_ms=700` 待真机 `flutter run -d macos` 看常速战斗手感调定(纯 numbers.yaml 配置·连带同步 `AnimationNumbers.defaults`)。用户拍板先 merge 初值,真机后调。

## 十 · 桃花岛(养成经营 · 一期 2026-06-25 合入 main)

- [ ] **桃花岛主屏「场景化画面」重做(待美术·用户拍板 2026-06-25)**:一期主屏是**卡片列表**(4 建筑卡 `taohua_island_screen.dart`·功能完整可用)。用户要求改为**一整幅场景画面**——以桃花岛元素为背景(岛屿/桃林/水景等),各生产建筑(铁匠厂/草药园/打造台/丹房)作为**画面上摆布的视觉元素**(可点的建筑物/地块),而非抽象卡片。**依赖**:用户后期补一次美术素材(背景图 + 各建筑/生产元素立绘/图标)。**届时做**:presentation 层重构(场景 Stack 布局 + 建筑热区点击进升级/选配方/收取面板),数值/服务层(config/settle/action/provider)**不动**,纯换皮。卡片列表版作为功能底座保留到场景版就绪。临时 debug 直达路由(VISUAL_ROUTE=taohua_island)本次验收后已还原,场景版做时可重加。

## 十一 · 周目实际差异(待用户拍板 · 2026-06-26)

- [x] **① 难度侧已做**(2026-06-26 用户「双调·温和」拍板·合 main `9caef667`):`scale_per_cycle` 0.06→0.10(二周目敌+10%/三周目+20%)+ 主线二周目 assignment `[yuti]`→`[yuti, zhenqi]`(加真气词条·敌多放一次大招)。红线安全(生产 `.clamp(0,60000)`·西凉霸主 cycle3 命中 clamp·玩家伤害独立 scale·simulator peak 不进百万)。**balance 初值待真机校**。
- [x] **② 回报侧已做**(2026-06-26 xhigh·合 main `f03d5b34`):主线+扫荡二周目起回报加大。稀有彩头 cycle 感知(`RareBonusTier.chanceNgPlus`+`chanceFor`·+1阶5%→8%/+2阶1.5%→3%)+ 普通掉落材料加成(新 `CycleDropBonusConfig`+`applyCycleMaterialBonus`·材料类 miscMaterial/磨剑石/心血结晶 ×1.5·装备/经验丹/秘籍/银两不动)。cycle 透传:`resolve` 加 cycle ← `applyVictoryResolution`(主线 runStageFlow targetCycle·扫荡 settleMainlineSweepVictory cycle)。**爬塔不变**:rare bonus 仅 isFirstClear 触发,二周目非首通故不发(守 §5.1 防刷),无需接 cycle。红线全守。TDD +16/全量 3130+1skip。**balance 初值待真机校**(彩头 8%·3%/材料 ×1.5)。
  - 显示层已修(`ca8f7e4b`)·难度侧 ①(`9caef667`)·回报侧 ②(`f03d5b34`)——周目可见化+难度+回报全闭环。

## 十二 · 玩法/优化候选池(2026-06-28 头脑风暴筛选)

> 用户已排除:江湖传闻链 / 门派旧怨系统 / 心法走火入魔分支 / 闭关地图地域化 / 师徒临终遗愿 / 群战阵势事件 / 江湖见闻录收藏百科 / 战斗关键回合摘要 / Build 方案保存 / 失败原因诊断 / 敌人招式库差异化。以下为保留进入待办的条目。执行时先写独立 design/spec,再按小切片计划落地。

### 2026-06-28 晚间本轮选入待办

- [x] **桃花岛产物消费补齐**(2026-06-29 合 main `50accc12`):把锻材、开锋辅材、行囊补给等尚未形成终端用途的产物接进现有系统,让桃花岛生产链更闭环;不改在线=离线结算原则。
- [x] **单人主线 01_05→06_05 平衡调参**(2026-06-29 合 main `40cd3230`):祖师单人线前 4 关已修,后续 26 关仍可能单人 1v3;按关卡敌阵、Boss、掉落节奏做实际体验优化。
- [ ] **爬塔单人路径打磨**(⏸ 2026-06-29 暂缓·随塔Boss同分支 night-tower-solo-boss-mechanics 回退):塔只按境界解锁,不按弟子入队门槛;针对高境界单人爬塔补敌阵/机制/提示层优化。
- [ ] **塔 20/25/30 Boss 机制增强**(⏸ 2026-06-29 暂缓·验证缺失:floor30 二阶段仅 4/20 on-level 触发<80% 阈值·boss 血未跟上机制·待真机校+重调相位阈值):优先补阶段控场、多目标压力、反制窗口等机制杠杆,避免只靠堆数值制造挑战。
- [x] **招式熟练度可视化二期**(2026-06-29 合 main `ae6b46ca`):在既有藏经阁可见性基础上,继续统一战报、角色页、技能详情中的熟练度收益与当前效果说明。
- [x] **离线收益回归卡优化**(2026-06-29 合 main `e20c8c55`):隐藏 0 值项,按来源分组展示经验、材料、装备、熟练度等回归信息;只解释在线=离线结果,不引入加速。
- [x] **疗伤丹战后接入**(2026-06-29 合 main `50accc12`·与桃花岛消费同分支):战斗结束后可直接用疗伤丹处理伤势,消耗桃花岛丹房产物,减少有药但用不上的断裂。
- [x] **主线重打收益路线**(2026-06-29 合 main `65a61c06`):在已通关章节里突出刷装备、刷材料、刷熟练度的不同重打价值,让玩家知道为什么回头打。
- [x] **装备掉落后即时处理**(2026-06-29 合 main `d102aae6`):胜利结算里对新装备提供锁定、查看来源、标记常用、稍后处理等轻量操作,减少仓库堆积感。
- [x] **商店货架需求提示**(2026-06-29 合 main `1b84162d`):商店物品显示当前谁用得上、哪个系统会消耗,降低经验丹、材料、秘籍购买决策黑箱。

### 2026-06-28 晚间第二梯队

- [ ] **周目敌人词条可视化**:二周目、三周目的真气/玉体等词条在关卡行和战前情报里解释清楚,让周目差异不只是暗中变难。
- [ ] **闭关地图专属小产出**:五张闭关地图各自有一类轻量特色产出,例如草药、锻砂、残页线索、疗伤材料,让地图选择更有意义。
- [ ] **扫荡前收益预估**:一键扫荡前显示预计主收益类型、可能掉落、熟练度方向和材料缺口命中,不改变收益,只让决策更清楚。
- [ ] **角色伤势状态表现增强**:伤势不只在数值里体现,在角色卡、战斗前、战后摘要中有明确状态文案和恢复入口。
- [ ] **闭关溢出保护**:闭关达到收益上限后,主界面和回归卡提示已满,并给一键收功入口;不提高收益上限。
- [ ] **高周目 Boss 阶段差异**:二周目以上 Boss 不只加数值,追加轻量阶段变化或技能顺序变化,提升重复挑战感。
- [ ] **主线章节推荐刷点**:每章通关后标出 1-2 个适合刷材料/熟练度/装备的关卡,但不追踪个人缺口。
- [ ] **桃花岛建筑协同加成**:建筑之间形成固定协同,例如灵泉提升丹房产能、矿洞支援锻造台,不做随机或限时。
- [ ] **闭关地图解锁门槛可读化**:地图未解锁时展示需要的境界/章节/材料条件,减少灰按钮困惑。

### 2026-06-28 晚间本轮暂缓

- **暂不做**:终局装备目标追踪 / 匠人委托一期 / 战败后整备建议升级 / 关卡整备条二期。
- **本轮不要**:门派谱战斗影响接入 / 奇遇后续回访 / 装备共鸣阶段奖励扩展 / 章节通关后的江湖变化 / 传承遗物待解锁提示 / 章节 Boss 失败后的剧情分支小反馈。
- **本轮不要**:章节收束奖励选择 / 关卡失败后敌方状态保留提示 / 装备部位缺口提醒 / 心法相生缺口提示 / 轻功关卡收益差异化 / 群战守城战后民心反馈 / 奇遇选择代价可见 / 商店卖出前价值解释 / 武学残页来源聚合。
- **本轮不要**:周目首通差异奖励 / 关卡掉落缺口标记 / 药品行囊自动补位 / 闭关归来事件小结。
- **本轮不要**:江湖商店库存随章节扩容 / 装备修复残器玩法 / 心法残卷合成本 / 爬塔 Boss 战利品展示升级 / 主角换主修前损失预览 / 战斗中药品自动禁用提示 / 章节 Boss 重战入口优化。

- [ ] **装备出售/分解后的匠人委托(历史候选 · 本轮暂缓)**:冗余装备回收后积累材料与委托进度,解锁修复残器/定向开锋/铁匠请求;必须守买断制与非日课,不做限时刷新。
- [ ] **招式熟练度可视化打磨**:统一战报、角色页、藏经阁/心法页里的熟练度收益与当前效果说明,减少玩家不知道招式为什么变强的黑箱感。
- [ ] **长线平衡审计任务**:复核掉落、银两、强化材料、心法修炼、离线收益、终局极值 build 与周目回报,目标是爽感可见但数值不进百万膨胀。
- [ ] **装备筛选与锁定优化**:背包/仓库支持按阶、部位、流派、锁定/师承/已装备等条件筛选;出售/分解前保护高价值装备,减少误操作。
- [ ] **离线收益结算明细**:玩家回归后展示经验、银两、材料、心法/招式熟练度、装备掉落的来源明细;只解释在线=离线结果,不引入加速。
- [ ] **材料来源反查**:在强化、开锋、分解、商店等界面点击材料时,可查看主要来源关卡、闭关地图、分解路径或货架来源。
- [ ] **终局装备目标追踪(历史候选 · 本轮暂缓)**:允许标记一件装备作为长期养成目标,聚合强化、共鸣、开锋、材料缺口与可行动入口。
- [ ] **爬塔层数结构复核**:复核 30 层 Boss 节奏、小 Boss 间隔、掉落曲线与难度坡度,避免中段疲软或终局突刺。
- [ ] **新手前 30 分钟体验打磨**:不加教程弹窗,只优化解锁顺序、默认目标、初期掉落、首个失败点与首个成长反馈。

### 建议执行顺序

1. **装备链路一组**:装备筛选与锁定优化 → 材料来源反查 → 终局装备目标追踪 → 匠人委托。先补安全与可查性,再加长期目标与新委托系统。
2. **反馈可读性一组**:招式熟练度可视化 → 离线收益结算明细 → 新手前 30 分钟体验打磨。先让已有成长可解释,再打磨早期体验。
3. **审计校值一组**:爬塔层数结构复核 → 长线平衡审计任务。先做内容结构审计,再做全链路数值审计,避免重复调参。
