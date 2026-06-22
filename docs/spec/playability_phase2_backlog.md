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
- [ ] **战报诊断规则**(§11.4):killed_by_charge / mob_overrun 等失败复盘提示 + jump_target。归 P3 战后体验,不在 P1a。
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

- [~] **P2 队伍成长与三人协同**(master spec §四 / §13 P2):**协同深度已实装**(第六阶段 2026-06-18 · 破绽窗口链路 = 破招/破防开窗 + AI 集火 + 即放提示 + 表现层 + autoFill 软引导 · spec/plan `2026-06-18-phase6-coop-break-window-*`)。**续作 backlog**:① 渐进解锁(开局单人→收徒扩队)② 出战编成 UI ③ Boss 协同窗口(围绕破绽链路设计的 Boss)④ 二弟子→控制倾向(依赖 `LineageRole` 加 senior/junior 子枚举 + SkillDef 控制信号,当前两弟子都→破防)。
- [~] **P3 Boss 标准与战后体验**(§六 / §七 / §13 P3):**已完成**(2026-06-18 批一战后体验✅ + 2026-06-19 批二 Boss 机制✅):英雄镜头最小版 · 珍稀掉落展示(英雄镜头→技能珍稀→装备treasure 仪式接线)· 战后复盘三段式已 wire(`BattleDiagnosis` 进 victory_overlay)· Boss 多阶段(`bossPhases` hp 阈值+蓄力反扑+aiMode)· 弱点/抗性(`schoolDamageTakenMult` ×1.25/×0.75+会心 glyph)· 技能珍稀卷轴展示。**仍待**:战报诊断「队伍」跳转→批三 · ③ Boss 协同窗口(「敌方协同」新概念,先讨论范围再动)。
- [ ] **P4 长期档案与探索联动**(§八 / §九 / §13 P4):藏经阁/兵器谱/战绩册/门派谱 · 地图/行为/装备/战绩触发奇遇 · 目标型材料进度。

## 五 · §16 待确认问题(P1a 收了部分,其余留对应阶段拍板)

- [x] #1 首批 24 技能:P1a 收**框架 + 最小集**;24 招全内容留(见一)。
- [ ] #2 主线 3 + 爬塔 3 Boss 机制细案 → P3。
- [x] #3 熟练度走不走闭关:P1a 定**否**(只看战斗放招,含挂机自动战斗)。
- [x] #4 残页集齐数量:P1a 默认真解 1 / 残页 5(可推翻,见二)。
- [ ] #5 珍稀材料名称与用途 → P4 材料经济。
- [ ] #6 英雄镜头美术方案(纯 UI 定格 / 立绘切入 / 场景 zoom)→ P3。
- [ ] #7 藏经阁/兵器谱/战绩册/门派谱解锁时机 → P4。

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

- [ ] **战报 `_formatAction` 死字段 + 双轨战报架构梳理(T13)**：`default_ground_strategy.dart:857 _formatAction` 生成简化中文战报串写入 `BattleAction.description`，实测对攻击行动(`r != null`)**不被消费**——`battle_log.dart:35-37` 仅在非攻击 `r==null` 兜底用 description，攻击行动走 `BattleLog.formatAction` 完整重算(闪避率/流派克制/附带效果/击杀全覆盖）；UI `battle_screen.dart:2424` 读的是 `skill.description` 而非 action.description。故 `_formatAction` 对攻击行动是**事实死字段**(仅 toString debug + 非攻击兜底用到)。**待定方向**：(a) 删 `_formatAction`、攻击行动 description 传空/精简；(b) 先厘清 action.description 在非攻击行动/回放/UI 的真实角色再统一走 battle_log(合法 sink)。自带 T13「正式中文化」标记，审查列 Low(非阻塞·玩家无感·battle_log 已是主路径)。
