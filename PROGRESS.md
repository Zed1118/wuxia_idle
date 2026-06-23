# 挂机武侠 · 开发进度

> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。
>
> **当前阶段：1.0 长线打磨期（质量优先 · 不设上线时间压力）** — Demo ✅(2026-05) → 1.0 内容周期 ✅(P1-P5+) → 打磨中。阶段一变只改本行；工作原则见 CLAUDE.md §7。

## 当前阶段

> ✅ **2026-06-23 续49(第五阶段·掉落优化 子系统配置卫生批 F5/F7/F8 · Phase0证伪审计前提→TDD · 合 main `3af2423d` 已 push · opus high)**：审计溢出 backlog 三项一批纯自动验。**F5 删 StageDef 死字段** `dropEquipmentDefIds`/`dropItemDefIds`——Phase0 证伪审计「0引用·低风险」前提(runtime 0 消费但 yaml 47关94行+`game_repository_test` 反向引用校验+2 红线测试拿它当 stages.yaml 锚点字符串);已证 `dropTable` 超集删字段零信息丢失→清 stage_def 字段/构造/fromYaml + stages.yaml 94 key 行 + ~15 测试参数 + 2 红线测试换锚 `stage_01_01` 声明行 + 删 game_repo 反向引用段(dropTable 校验留)。**F7 dropTable 引用校验器**(`enforceDropTableReferences` static·`_enforceRedLines` 启动期 fail-fast):stage+tower 全表 `EquipmentDrop.equipmentDefId`∈equipmentDefs / `ItemDrop` 经 `ItemType.fromDefId` 解析非 miscMaterial,补此前无校验的爬塔 floor 盲区。**F8 shop §5.7「仅掉落不上架」守门**(`_enforceShopRedLines` 扩展):秘籍(techniqueScroll)+大还丹(大档经验丹 layerFraction=1.0)不得上架,小/中档不限。audit F5/F7/F8 标 resolved。analyze**0**/全量**2855+1skip**(基线2848 **+7**:F7×4+F8×3·零回归·worktree 实测)。session `docs/sessions/2026-06-23_2330_F5F7F8配置卫生.md`。**下一步**:F3/F4 边界待拍板 / 战斗节奏 A+C 真机校值(续45 遗留),待用户指定。

> ✅ **2026-06-23 续48(第五阶段·掉落优化 子系统 B · F2 主线 preview 首通门控 · brainstorm→Phase0→TDD · 合 worktree `4772c5be` merge main 待 push · opus high)**：承接续47 审计 F2(真 bug)。**Bug**:主线 3 本秘籍 `item_scroll_*`(dropChance=1.0)运行时逐 defId 首通门控(`shouldSkipScrollDrop`),但 preview 整表硬编码 `isFirstClearGated:false`→错归「常可得」,实为「首通必得·重打不补」;根因=preview 的 gated 是**整表单布尔**,表达不了同表内秘籍门控、装备不门控。用户拍板**全面修**+footer 文案「秘籍首通必得,重打不补」。**改 11 文件**:`DropRumorTable.fromDropTable` 表级布尔→`FirstClearGating` 枚举(scrollOnly 主线逐条/wholeChannel 爬塔整渠道)逐条判 gated;抽 `isTechniqueScrollDefId` 谓词入 core/domain/enums,runtime `shouldSkipScrollDrop`+`enums.fromDefId`+preview **三方共用**消除 `item_scroll_` 前缀散 3 处 drift;dialog footer 按 gating 选串(`hasFirstClearGatedEntry` 驱动·主线含秘籍才显);2 call site(stage_list→scrollOnly/tower→wholeChannel)。`bucketOf`/爬塔/runtime 掉落行为**零变**(纯去重)。audit F2 标 resolved。analyze**0**/全量**2848+1skip**(基线2839 **+9** 新测:谓词3+F2桶4+footer2·零回归·worktree 实测)。session `docs/sessions/2026-06-23_2300_F2掉落preview首通门控.md`。**下一步**:F5/F7/F8 配置卫生批 / F3/F4 边界待拍板 / 战斗节奏真机校值,待用户指定。

> ✅ **2026-06-23 续47(第五阶段·掉落优化 子系统 A 审计 + F1 实装 · brainstorm→spec→plan→自主执行 · 合 main 待 push · opus xhigh)**：**A 掉落表一致性审计**(4 路只读扇出 47+30 dropTable→逐条 grep 亲核)结论=掉落整体健康(tier 梯度 98.7%/7 阶无缺口/0 悬空/9 本秘籍 100% 必得),查出 **F1 真 content bug**(3 件 special 装备 `dropSourceTags` 声明授予通道但 0 实装→永不可得)+ F6 死字段 + 6 配置卫生项。审计**无 evidence 撑掉落太苦→子系统 C 防衰用户拍板不做**。**F1 方案 A 实装**(7 task TDD):`SaveData.grantedMilestoneEquipmentIds` 防重 + saveVer `0.27→0.28` + numbers.yaml `milestone_equipment_grants` 映射 + `MilestoneEquipmentGrantService`(按 dropSourceTags 筛授予,F6 同修变 live)+ 群战/心魔首通终点关 post-victory hook(stage_mass_battle_05→百战甲/stage_inner_demon_07→心魔珠)+ 飞升 performAscend 授无名剑(grantForTagInTxn 避嵌套 txn)。audit `docs/audit/drop_consistency_2026-06-23.md` + spec/plan `docs/spec/2026-06-23-f1-milestone-equipment-grant-{design,plan}.md`。analyze**0**/全量**2839+1skip**(基线2826 **+13** 零回归·worktree 实测)。**下一步**:B(F2 首通秘籍 preview 标签偏差)/F3-F8 配置卫生/战斗节奏真机校值,待用户指定。

> **2026-06-23 续45-46 已压缩归档**(git log/各 closeout 可溯·2815→2826测):续45 战斗节奏可读性 A+C(纯表现层·ATB 一拍一行动 `advanceOneAction`+关键帧顿帧 `keyMomentHoldMs`+节奏 retune·`d10346ee`·**待真机校 `action_interval_ms`/`key_moment_hold_ms`/`damage_popup_ms` 初值** backlog 九)·续46 审计修 bug 批(心魔关战败双重惩罚/奇遇属性奖励失效/招式倍率红线缺口/配而不用注释·`a3fb2d52`)。spec `2026-06-23-battle-pacing-readability-*`。

> **2026-06-22..23 续34-44 已压缩归档**(P4长期档案子项1-6全闭环+续42审查+续43散写中文复扫+续44 backlog checkbox 同步/清 _formatAction 死字段：续31战绩册`4669fbac`/续33兵器谱`2e4b7ed6`/续34-38材料经济`5f3899fb`/续39门派谱1.1`4cfc1565`/续40奇遇录`fe4c0751`/续41藏经阁2.0武学图鉴(P4全6子项闭环里程碑)/续43迁4处真违规进UiStrings`de290e6c`/续44 backlog 8 stale checkbox 翻[x]+删 default_ground_strategy._formatAction 死字段`15d4235b`·均纯展示层零saveVer·2676→2815测·spec `2026-06-2{0,1,2}-p4-*`)

> **2026-06-17..20 续19-续30 已压缩归档**(第五~七阶段·git log/各closeout可溯·2301→2605测)：续19上下文帮助系统·续20主线一战斗UI表达+aoe全体伤害·续22主线三掉落传闻UI·续23即放时序2.3+首通门控2.5·续24打击感表现层2.4·续25三人协同破绽窗口·续26战后体验英雄镜头·续27Boss多阶段/弱点抗性/技能珍稀·续28批二目检+帮助按钮修·续29队伍成长渐进解锁+二弟子控制·续30四批真机目检全PASS+hero_camera路由。spec `2026-06-1{7,8,9}-*`。

> **2026-06-16 续16-18 已压缩归档**(规则层全域摸排+按级修复 `c384a0d3` + M6 心魔失败惩罚实装 `cf694faf` + M6 余毒战败摘要 UI 上下文感知标题视觉验收 · 2247→2286 测 · 详 git log + `docs/audit/full_audit_2026-06-16.md`)

> ✅ **2026-06-16 续15 已压缩归档**(全功能真审计 + 按级修复 · 合 main `b8330c14` · 2247 测):纠上会话幻觉(谎称落盘的「45 项」审计全仓查无)→重跑真审计(1 High+7 Med+1 Low+2 drift,3 个吹的 High 红线项实证全误报,报告 `docs/audit/full_audit_2026-06-16.md`)。修 H1 爬塔周目迁移数据丢失版本门 + §6 路径 drift + EnumL10n/battle_log 正名合法 sink + M3-M5 散写中文迁 UiStrings + M6 确认心魔惩罚未 wire 留拍板。

> **2026-06-15 续10-续14 五条已压缩归档**(全 commit/spec/closeout 可溯 · 2190→2245 测):续10 L3 闭关非阻塞 + M2 离线收益范围A(`7efb82c8`)+ L1 显示设置 window_manager 全屏/3 档分辨率(`130b40ac`) · 续11 L1 Codex 验收 + 两 fail 回修(720p overflow / F11→Alt+Enter `a0f77a8b`) · 续12 M2 范围B 通用被动离线挂机(saveVer0.24.0 · 9 决策 · `212b572c`) · 续13 P1b MeridianBar wiring(StageProgressRow 四系统收口) · 续14 P3 战报失败诊断(三段式复盘 `BattleDiagnosis` 5 规则 · `6a32901a`)。spec `2026-06-15-*`。

> **2026-06-14 红线/战斗交互重做批已压缩归档**(git log `7adc8532→3edc99ae` · 详各 closeout · 2160→2165 测):战斗交互重做 Phase1-4(自动播放+随时拖招,废半手动/录制回放净 -2050 行)+ 周目按章(saveVer0.23)+ 周目进化 A-F1(敌人 scale/5 反制词条/Boss HP 红线 50000→60000 · Codex 视觉 10/10)+ 拖招表现层微调(引导线外发光/蓄势呼吸光晕 · Codex 5/5)+ **红线语义收口分两层**(硬=配置基础表值 schema 拦截 / 软=极值满 build 实战可见值不进百万,balance_simulator 极值×周目诊断证伪「不进十万」)+ towers 注释补漏。

> **2026-06-13 半手动战斗 master spec + P0 全闭环已压缩归档**(详 `2026-06-13-semi-manual-battle-*` spec/plan + 各 closeout · 2011→2067 测):半手动+seed重放+周目进化 master spec 定稿 → P0 步骤 3b-5 全闭环(逐 actor 单步 stepOne/单步 UI/重放执行/schema 0.19 落盘 BattleReplayRecord/全局+per-stage 自动开关 UI · 自/手印章 glyph)+ AGENTS.md 瘦身 stub 根治双文档漂移。

> **2026-06-12 UX 整合 + 爆品展示 + 音视频批已压缩归档**(详 `2026-06-12-*` spec + 各 closeout · 1950→2002 测):战斗/装备 UX 整合方案 12/12(藏经阁+装备链路+战斗指令台 · Codex R2 5/5)+ 爆品展示(印章盖落动画/tagline 35句/时序重排爆品当第一高潮)+ BGM 扩 8 轨细分 + D 四类养成进度五要素标准化(StageProgressRow)+ UI 视觉 sweep + 神物金光 TreasureGlowLayer + E 音频 Phase0 摸底。

> **2026-06-11 长线打磨 波A/波B + 音频批已压缩归档**(详 `2026-06-11-wave-{a,b}-*` spec + 各 session · 1888→1932 测):波A P1 机制深度(破招 build gate §9.1/interrupt_power_pct/per-skill 熟练度铺广/来源统一 skillUnlockProgress)+ 波B 24 招全内容+机制 Boss×6+装配池 wiring+30 关高熟练度 sweep + 平A 命中音 6 变体 + 战斗 BGM 短前奏版 + jingle 扩槽 + 工程清理。

> **2026-06-09/10 可玩性 P1a/P1b 养成内核批已压缩归档**(详 `p1a_cultivation_core_closeout_2026-06-10.md` + 各 closeout · 1778→1883 测):P1a 养成内核(per-skill 熟练度 1.00→1.30/解锁进度 SkillUnlockService/Boss 掉书+残页)+ P1b 藏经阁技能装配(Character 5 装配槽 saveVer0.17/SkillLoadout autoFill)+ B3 破招「破!」题字+B5 败北页路由 + P0 手动 Boss 破招全闭环 + 音频系统全闭环(SoundManager/三类 hook)。

> ✅ **2026-06-05..09 归档**(UI kit v1 序 0 = 9 组件 + `WuxiaUi` token · Codex 两天 UI 包装/MJ 56 张接入 `a195547` · §5.6 硬编码审计抽 UiStrings/T5 闭关地图化/截图基建/心法 cover 重出 `c991984` · 1713→1763 测/0 analyze):详 git log `feat/ui-kit-v1`→`e767c42` + 各 closeout/plan。

> **2026-06-04 两条已压缩归档**(8 张装备图重出+工作树清理+UI 包装方案 v1 `9ea8f4f` / P0-3 ②③ 主修 hero+心魔瓶颈面板 `f9425b8` · 1697→1712 测):详 git log + 各 spec/closeout。

> **2026-06-01..03 详条已压缩归档**(git log/closeout 完整可溯 · 1661→1697 测/0 analyze):① **P0-2 战斗单位可见化全闭环**(玩家立绘+单位放大 110+死亡 grayscale+弹道笔触+受击闪+折叠日志+胜负 vignette · 弹道/受击走 actionLog 不写 BattleState 红线 · `c7fb79c`)② **P0-3 角色卡 ① 装备外观可视化**(装备槽 iconPath+tier 色 _EquipGlyph)③ **P0-4b 仓库格子化实装**(列表→部位分组网格+tier 边框+强化徽章+师承标+境界锁灰化 · `2049265` · Codex R3 PASS `880d7f7`)④ **装备 detail 45 件 + 敌人图 37/37 全归位**(美术缺口归零 `239d1d9` · 129 敌人图 + 80 装备 detail)⑤ **验收提速基建**(`VISUAL_ROUTE=hub` 一次 build 点遍 12 路由 + `tool/build_acceptance.sh` 预编 · `d94a56a`)。详 `docs/handoff/overnight_2026-06-03_handoff.md` + 各 closeout。

> **2026-05-30..06-02 出版美术 pass(1.0 Presentation Pass)全闭环已归档**(1581→1667 测/0 analyze · `docs/PUBLISHING_ART_PASS_1_0.md`):战斗屏(主菜单水墨山门 + B1 背景按 biome 接线+scrim+胜负仪式 overlay + B2 大招题字+Boss 金边)+剧情屏(narrative_scene 基建+30 图)+战斗场景 16 biome 全覆盖+角色页档案化+章节封面 6 章 · Codex 多门视觉验收 PASS · D 段性能稳定性验证(8h/leak/ANR 逻辑层已验)+窗口 min size Pen 3/3 PASS + B1 release audit doc 同步(CLAUDE v1.17 测数 1667)+ P5.2 敌人内力按境界对称化 scale=0.20 + 文案 polish H 段全角标点 + #4③ 数值迁 yaml + V3 神物金掉落验收 3/3 PASS。git log `c97c682→880d7f7` 区间 + 各 closeout 完整可溯。


---

## 已知偏差 / 挂账事项

- ~~#37-#45 / stage_05_05 跨阶墙 / equipment_detail '(基 $base)' nit~~ 全销账(2026-05-17..06-08):详各 closeout + 末尾归档

> 已销账条目(#1-#45)详见末尾归档。**P1 阶段全销账 ✅** + **Demo §8.4 14/14 全达标 ✅** + **1.0 ~95% release ready ✅**(A+B+C 全 PASS · 剩 D-G 留 M15-16)。

## 关键约束(每次开局必读)

- 数值硬红线(配置基础表值·schema 拦截):装备基础攻击 ≤2000 / 玩家血 ≤20000 / 内力 ≤15000 / Boss 血 60000+(GDD §5.4)
- 数值软红线(极值满 build 实战可见值·保可读):核心唯一线=不进百万膨胀(普攻真实峰值~13.5万 / 大招~21万,均六位可读)
- 不硬编码数值/文案(走 numbers.yaml / data/narratives, lore, events)
- Riverpod 状态管理;Isar 本地存储;data/ asset 根
- 不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md(数值/规则层 · 改前 ask)
- Mac 端写 lib/、data/(顶层)、test/、文案(v1.8 起 DeepSeek 退役)

## 远程仓库

- GitHub:https://github.com/Zed1118/wuxia_idle · 主分支 main
- 协作:Mac 单端代码+数值+文案;视觉验收 Mac 本地 Codex(Pen Windows AI 工具 2026-06-11 全下线)

## 归档

### 已解决挂账(逆时序)
- **心法 7 阶 cover 伪书法 G5.1 红线**(2026-06-08):重出透明无字卷轴替换(`c991984`)· flood-fill 抠白底+收边 · 真木底自检无白晕

- **Phase 1-2 + W1-W13 全销账**(2026-05-10..14):#1/5/12-16/19-29/32 + #18 伪挂账

### Phase 1-4 早期详条已迁出

- Phase 1-3 + W4-W11:`phase{1,2,3}_summary.md` + tags `v0.1.0-phase1` / `v0.3.0-w11`
- W14-W15 + Phase 5 #2/#3 销账详条:git log + handoff/各 closeout

### W17-W18 详条迁出 2026-05-19/20

13 段销账(P1 #42-45 / Nightshift 9 task / P0 4 段 / 外部审查 6 项 / 路线图 launched / Codex 视觉)。详 `p1_4{2,3,4}_*` / `nightshift_20260519_handoff.md` / `p0_38_maxhp_rebalance_closeout_2026-05-17.md` 11 closeout。

- **P1.1 候选 1-5**(2026-05-21):5 候选全收口(4 实装 + 1 doc)— 收徒池 E.1 / 祖师爷 sect_wide_buff / 共鸣度 4 子任务 + joint_skill / 开锋 build / CLAUDE.md §12 对齐 · `p1_1_*_closeout_2026-05-21.md`。

### M4 #46 美术 + Ch4 Phase 2 详条迁出 2026-05-20/22

- **M4 #46 美术** 5 段(2026-05-20/21):Stage 2 W1-W6 74/74 + assets 89 张 + stage_audit + #45 Demo §8.4 · 详 art_poc_* / art_assets_integration_* / p1_45_demo_polish_*
- **Ch4 1.0 P2 第二条主线第 1 章**(2026-05-21/22):Phase 2.1-2.5 全收口 + 13 narrative ~5,880 字 · 详 p1_x_chapter4_phase2_*

### 2026-05-22/23/24 详条归档

- **2026-05-22 Ch5 + Ch6 飞升 P2 主线全闭环**(2 章 ~12,438 字 · 师父三句遗言完整连通 · 小铜镜+玉佩 hook 闭环 · 详 `p2_x_chapter{5,6}_phase2_full_closeout_2026-05-22.md`)
- **2026-05-23 心魔 Batch 2.1-2.5 + P3.1 轻功对决**(8h overnight worktree · 7+5 关 · 详 `p2_x_inner_demon_final_closeout_2026-05-23.md` + `p3_1_lightfoot_closeout_2026-05-23.md`)
- **2026-05-24 P3.2 群战守城 + P3.1.B 子批 + P5+ 多代飞升 + 真传位 + 8h overnight v2/v3 + nightshift v2 首跑 + UI polish**(git log `efc7604 → b6d8191` 区间 · 详 handoff `p3_2_*` / `p3_1_b_*` / `p5_lineage_full_closeout_2026-05-24.md` / `nightshift_v2_first_run_closeout_2026-05-24.md` / `8h_autonomous_handoff_2026-05-24.md`)
- **2026-05-25 v2.1 工具完善 + T17-T22 cherry-pick + T23/T24 6 关键问题闭环批**(main `74ba519 → b6d8191` · 1458 测 / 0 analyze · 批次质量 A 9.05/10 · P1.2 江湖恩怨+声望 100% + 技术债 3 合一 · 详 `session_closeout_2026-05-25_nightshift_6h_review.md` + `p1_2_jianghu_full.md` + `p3_tech_debt.md`)
- **2026-05-26 P4.1 1.1 四项+audit v3+P5.2+Boss 招降叙事**(1484→1505 测 · 详各 closeout)
- **2026-05-27 Boss 招降叙事+debug 招募+R2 派单**(1505 测 · 详 `session_closeout_2026-05-27_boss_narrative_debug_recruit.md`)
- **2026-05-28 过夜清理+P3 三项+P2.1 4 批+drop 全覆盖+CHECKLIST v1.5+R4 派单**(1505→1519 测 · 详 `overnight_1_1_cleanup_handoff_2026-05-28.md` / `session_closeout_2026-05-28_p3_p1_triple.md` / `codex_dispatch_r4_p2_1_content_drop_2026-05-28.md`)
