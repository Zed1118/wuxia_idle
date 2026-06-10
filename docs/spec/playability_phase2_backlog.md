# 可玩性加强 · 二期 Backlog（P1a 之后的滚动任务清单）

> 滚动文档,不带日期。每推进一项就勾选/更新,不重复写。
> **上游 master spec**:`docs/spec/playability_upgrade_master_spec_2026-06-09.md`(P0-P4 全规划 + §16 待确认)
> **P1a 实施 spec**:`docs/spec/2026-06-09-playability-p1a-cultivation-core-design.md`(养成内核,待落)
> **用途**:汇总 P1a 砍掉/推迟/默认拍板/待复核的所有项 + master spec 后续阶段指针,作为二期任务继续推进。
> **每条格式**:`[ ] 任务 — 一句话 + 指针(master spec §x / GDD §x)`。

---

## 一 · P1a 内已推迟(P1a spec §5「P1a 不做」)

- [ ] **技能装配限制 UI**(§2.6):每名角色主修 2 招 / 辅修 1 / 共鸣 1 / 大招 1 的装配栏。涉及战斗 UI 技能栏(presentation),与 P0 战斗 UI 同区,排 P1b/P2。
- [ ] **藏经阁 screen**(§三 / §8 / P1 验收):新 screen,聚合全角色技能树 + 熟练度阶段 + 真解/残页进度展示 + 装配入口。P1b 最大头(~8-10h)。
- [ ] **统一进度展示组件 wiring**(§三):`MeridianBar` 已就绪,但熟练度/共鸣度/修炼度/残页四系统统一接到"当前阶段+进度+当前效果+下一阶段效果+来源"的展示规范,需逐处 wire。P1b。
- [ ] **24 招全内容**(§16 #1):P1a 只做框架 + 最小集(3 主线真解 + 1-2 套残页 + 少数 per-skill 效果)。24 招完整名字/流派/倍率/效果/占位 key 是独立内容批。
- [ ] **战报诊断规则**(§11.4):killed_by_charge / mob_overrun 等失败复盘提示 + jump_target。归 P3 战后体验,不在 P1a。
- [ ] **per-skill 熟练度效果铺广**:P1a 只给真解/招牌/破招技配 per-skill 效果,其余 166 招吃全局阶段倍率统一底。二期可给更多关键招精修个性效果。

## 二 · P1a 默认拍板(用了默认值,二期可推翻)

- [ ] **残页集齐数量**:P1a 取 §16 #4 默认 = 真解 1 本即解锁 / 爬塔残页 5 片一套(进 numbers.yaml)。实玩后可调。
- [ ] **奇遇旧 unlock 池不并入新结构**:P1a 让奇遇技能池(`equippedEncounterSkillId` + EncounterProgress)与新 `skillUnlockProgress` 两套并存,避免大改。二期若要统一来源模型,在此合并。
- [ ] **§9.1 破招技按 build gate**(P0 遗留):P0 破招技(破势)是广发主控的简化,二期改为按心法/build 赋予(谁配了对应心法/装备才有破招技)。依赖装配限制 UI。

## 三 · P1b(P1 的表现层半,P1a 之后接着做)

- [ ] 藏经阁 screen(见一)。
- [ ] 统一进度展示组件 wiring(见一)。
- [ ] 技能装配限制 UI(见一)。
- [ ] P1 验收项收口:UI 可见当前/下一阶段效果 · 低境界无法装配高阶技能(装配 gate 后端在 P1a,UI 在 P1b)。

## 四 · master spec 后续阶段(P2/P3/P4,仅指针,细案见 master spec)

- [ ] **P2 队伍成长与三人协同**(master spec §四 / §13 P2):队伍人数渐进解锁 / 2-3 人技能栏动态适配 / 三人默认职责模板 / 至少 1 Boss 协同窗口。
- [ ] **P3 Boss 标准与战后体验**(§六 / §七 / §13 P3):Boss 六字段配置(阶段/弱点/抗性)· 战后复盘三段式 + 战报诊断(见一)· 珍稀掉落展示 · 英雄镜头最小版。
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
- [ ] **解锁态消费(注入战斗可用池)**:`SkillUnlockService.isUnlocked` 目前只存进度,无人消费把已解锁招注入 `BattleCharacter.availableSkills`。spec §六 明确这是 P1b/装配 UI 的活(P1a 只做 source plumbing),非缺口。P1b 接。
- [ ] **interrupt_power_pct 实装**:per-skill 「破招力」字段已解析(schema)但未消费。当前 P0 破招是二元(清蓄力+固定 stagger),无对应标量目标;是否缩放破招伤害 vs 加深减防是设计决策,需先定再落。
- [ ] **166 招 source tag**:plan D1 提的技能级来源标(沿 techniques.yaml acquireSourceTags 体例)本批降级——P1a 无消费方(装配 gate 走境界非 source),不阻塞验收路径。二期统一来源模型时补。
- [~] **高熟练度全量平衡扫描**(2026-06-10 焦点版已做 · `ce2ebdba`):balance_simulator 已加 `proficiencyUses` 维度,焦点扫了 3 真解 Boss 关 floor+ceiling(floor +8~57pt / ceiling 不破 100%,未破甜区)。**剩**:全 30 关高熟练度 sweep(扩到 _summarize 全表)留二期。

## 七 · 音频二期(v1 接入后的滚动项 · 2026-06-10 起)

- [~] **jingle 扩槽**:~~victory/rareDrop~~(2026-06-10 迭代1 已接:`SfxId.victory` 接「勝」overlay / `reward` 接主线+塔胜利 dialog 装备掉落,V1 3s 剪辑版)。**剩** defeat/realmAdvance 需扩 `SfxId` + 败北页/境界突破处 hook(defeat_v2_02 已被 battleChargeStart 转用,defeat 槽用 v2_01 或 V1 剪辑版)。
- [ ] **uiPaperOpen 素材**:V2 方案有 prompt 但 Suno 未产出,当前留空 no-op。重生成后直接落 `assets/audio/sfx/uiPaperOpen.mp3` 即接通,零代码。
- [ ] **转用素材听感复核**:battleUlt(realmAdvance_v2_01 裁 2.4s)/ battleChargeStart(defeat_v2_02 负向预警)是转用,真玩听感不合再重打专属 prompt。
- [ ] **扩展 BGM 8 轨**:mainline/tower/boss/innerDemon/lightFoot/massBattle/lineage/baike,V1 候选已躺 `assets/audio/_suno_candidates/`,需扩 `BgmTrack` + 各 screen hook。
