# 挂机武侠 · 开发进度

> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。
>
> **当前阶段：1.0 长线打磨期（质量优先 · 不设上线时间压力）** — Demo ✅(2026-05) → 1.0 内容周期 ✅(P1-P5+) → 打磨中。阶段一变只改本行；工作原则见 CLAUDE.md §7。

## 当前阶段

> 📐 **2026-06-25 体力系统需求 → 守红线写实替代设计(brainstorm→spec·先不写代码)**：用户提加体力系统,直接撞 §5.1 反主流红线第一项(+§5.5 在线=离线/§9)。Brainstorm 厘清真实目标=推进刹车/战斗张力/挂机循环(用户未选「要体力本身」),拍板**不做体力、三套守红线机制替代全上**:① 内力弹药(强化现有内力·战斗内弹药取舍·开战即满非战斗间闸) ② 境界门槛(强化 §5.3 锁步·跨阶推进刹车) ③ 双层 per-角色伤势(唯一新系统·小伤连战累积调息即恢复/重伤硬仗后留挂机疗养·铁律:带伤永远能打+疗伤非必需+无加速疗养+不留存焦虑)。串成 `挂机养内力境界疗伤→闯关受门槛→战斗内力取舍→带伤撑/换二弟子/疗养` 写实循环。spec/plan `docs/spec/2026-06-25-combat-tension-loop-{design,plan}.md`(含红线决策史)。**✅ ③ 双层伤势已实装(subagent-driven 10 task TDD + 两段 review + final holistic review READY_TO_MERGE·xhigh)**:Character +lightInjuryStacks/injuryHoursRemaining(saveVer 0.29)→ InjuryConfig/numbers.yaml injury 段 → InjuryService(重伤设值/轻伤累积/applyBattleInjuries)→ derived_stats(重伤减内力上限+轻伤减速度·clamp 前注入红线仍守)→ BattleCharacter 烘焙(攻击 outputMultiplier 连乘折扣)→ 战斗结算(硬仗战败全员/惨胜低血存活重伤+连战轻伤)→ caller(主线 stage.isBossStage/塔 floor.isBoss)→ 闭关+离线疗养递减+轻伤清零(守 §5.5 无加速)→ UI(角色面板 chip+战败 banner)。**红线全守**(带伤永远能打无战斗闸/疗养真实时间/不留存焦虑/数值全 numbers.yaml)。analyze**0**/全量**2931+1skip**(~26 新伤势测·0 回归·含修 6 处 saveVer 断言同步)。**🎯 三套全收口(2026-06-25 用户逐项拍板)**:① 内力弹药=指令台已显「耗内 N/内力不足」既有 UI 满足(无需改·YAGNI);② 境界门槛=balance_simulator 实测中后期已成立(Ch2/3 末弱 build 18-23% 胜率)+伤势加厚,Ch1 末有意宽松(开篇章降门槛·拍板接受);③ 双层伤势已实装合入 main。**已知设计取舍(故意非 bug)**:塔 Boss 战败不触发重伤(拍板不接·避免越败越弱螺旋·塔胜利仍接)+ Ch1 宽松+非Boss战败不累轻伤。**pending**:伤势 balance 初值待真机校(疗养8h/减内力15%/攻击×0.85/惨胜阈值25%)。详 spec §9 收口决策。

> ✅ **2026-06-25 健康报告 #3 收口·11 招搁浅 encounter skill 接线(调查定性→spec→TDD→11 奇遇文案创作→验·opus·用户睡觉自主推进)**：阶段性健康报告查出 encounter_skills 池 40 招仅 29 挂 encounter,11 招零引用→玩家不可达。**定性=漏接非预留**(code-grounded:11 招全有完整武侠文案非占位/tier 跨早期含 tier1/违背池「奇遇解锁」用途/零延期标注;唯一解锁路径=encounter unlockSkill→SaveData.skillUnlockProgress)。**处置=方案 A 接线**:11 招各配 1 个 techniqueInsight 奇遇(encounters.yaml +11 块·trigger 按 tier 难度递增 fortune 2→8 + biome/weather 门槛主题匹配·outcomeMapping insight_success/practice_partial/skip)+ events/ +11 篇文案(content_guide 风格:镜头切入/古龙铺氛围+金庸物候/无现代词/无虚构地名/细品类名词/重留白)。**TDD**:新建 `encounter_skill_pool_wiring_test` 红线锁「池中每招都被 encounter 引用·0 搁浅」(RED 列 11 招→GREEN);C2 启动期强校验兜底 11 新 events 文件存在+outcome_id 对齐;计数 57→68 同步(2 测断言)。#4 顺手:encounter_skills 头注 35→40 订正。**范围纪律**:#2 §7 PVP(规则层·PVP 实装 vs 不做清单语义)不擅改留拍板、#5 techniques stale 注释留底。0 碰战斗数值/红线/skills 倍率。analyze**0**/全量**2905+1skip**(2904 **+1** wiring 测·0 回归)。spec `docs/spec/2026-06-25-wire-11-encounter-skills-design.md`。**同日续(用户拍板)**:#2 §7/§9 PVP 从「仍然不做」移到「已实装」(P3.3 本地 mirror 对战+ELO+UI·ELO 持久化留 Phase5+·不违 §5.1·CLAUDE v1.21→v1.22)+ #5 techniques 头注 stale 注释清(DeepSeek 退役引用)。**同日续2·Windows 真机验收(用户提供局域网 Windows·Claude SSH 自驱)**:自行定位 Windows 主机(192.168.1.244)+ 建 SSH 通道(用户装公钥一次)+ Mac→Win LAN 直传源码(GitHub clone 大传输 SSL 中断,改 scp -O)+ pub get/build_runner(108 输出同 Mac)/`flutter test`**2905+1skip 逐位同 Mac**/`flutter build windows`**√ 出 wuxia_idle.exe(94.8s)**/exe 启动存活不崩。**Isar 在 Windows 自带 libisar.dll 无需手拷**。平台风险实测清零→#1 CI 降级「非必要」(Windows 验收可按需 SSH 自驱)。报告 `docs/audit/windows_acceptance_2026-06-25.md`。**健康报告 #1-#5 全收口/降级**。**下一步**:GUI 手感/中文渲染 ship 前人工目检(SSH 无图形回传)/ 战斗节奏定稿 / 实玩深度打磨 / 新方向,待用户指定。

> **2026-06-24 全系统审计 A-E 全闭环已压缩归档 🎯**(38 子系统·git log `5aa89cf2→3ed20d7b` + audit `full_system_audit_2026-06-24.md` + 健康报告 + 各 session 可溯·2855→2904测):**A** 开锋吸血/破甲接通战斗(calculateResolved 真消费 pierce/lifesteal·+21测)·**B** 系统接 game loop(B1 门派事件月锚 SectMonthlyTickService+16/B2 闭关掉落 DropService.rollOneWeighted+8/B3 江湖恩怨注释止血 pending-1.1 dormant)·**C** 设计冲突拍板(C1 GDD §6.1 授权 ETL 动态标价/C2 奇遇加载层强校验 `_validateEncounterEventReferences` 兑现 §8.1+4测/C3 §5.4 招式倍率改全局≤8000单线·CLAUDE v1.21)·**D** 死字段+注释 drift 8 项 honest 化(D2 fragment_threshold wire·D1/D3-D7 注释·D8 改3 stale)·**E** 散写中文迁 UiStrings(角色不存在×3+跳过)。specialSkill 槽3 单列 backlog。

> **2026-06-23..24 续47-51 已压缩归档**(git log/audit `drop_consistency_2026-06-23.md`/各 session 可溯·2826→2855测):续51 F4 终局塔层去水分(清 floor 23-30 共 10 件回掉低阶装备 long_quan×5/jin_pao×2/yu_pei_lao×2·保同阶 zhongqi/baowu+秘籍+经验丹+心血结晶补偿·shenWu 不进塔·towers.yaml -28/+14·`0105eaf9`·审计 F1-F8 全闭环🎯·残留 floor 20 一流 yu_pei_lao -1 阶留底)·续47 子系统 A 掉落表一致性审计(4 路扇出 47+30 dropTable 逐条核)+ F1 真 content bug 实装(special 装备 dropSourceTags 声明授予但 0 实装→`MilestoneEquipmentGrantService` 按 tag 筛授·saveVer 0.27→0.28)·续48 F2 主线 preview 首通门控偏差全面修(`FirstClearGating` 枚举·`isTechniqueScrollDefId` 谓词三方共用·footer「秘籍首通必得,重打不补」)·续49 配置卫生 F5/F7/F8(删 StageDef 死字段·`enforceDropTableReferences` 启动期 fail-fast·shop §5.7 守门)·续50 F3 章末护甲越阶修正(`armor_baowu_jin_si_jia` baoWu+2阶→`armor_zhongqi_han_tie_zhong_jia` zhongQi+1·dropChance 0.40→0.30·`346712eb`)。spec `docs/spec/2026-06-23-f1-milestone-equipment-grant-*`。

> **2026-06-23 续45-46 已压缩归档**(git log/各 closeout 可溯·2815→2826测):续45 战斗节奏可读性 A+C(纯表现层·ATB 一拍一行动 `advanceOneAction`+关键帧顿帧 `keyMomentHoldMs`+节奏 retune·`d10346ee`·**待真机校 `action_interval_ms`/`key_moment_hold_ms`/`damage_popup_ms` 初值** backlog 九)·续46 审计修 bug 批(心魔关战败双重惩罚/奇遇属性奖励失效/招式倍率红线缺口/配而不用注释·`a3fb2d52`)。spec `2026-06-23-battle-pacing-readability-*`。

> **2026-06-22..23 续34-44 已压缩归档**(P4长期档案子项1-6全闭环+续42审查+续43散写中文复扫+续44 backlog checkbox 同步/清 _formatAction 死字段：续31战绩册`4669fbac`/续33兵器谱`2e4b7ed6`/续34-38材料经济`5f3899fb`/续39门派谱1.1`4cfc1565`/续40奇遇录`fe4c0751`/续41藏经阁2.0武学图鉴(P4全6子项闭环里程碑)/续43迁4处真违规进UiStrings`de290e6c`/续44 backlog 8 stale checkbox 翻[x]+删 default_ground_strategy._formatAction 死字段`15d4235b`·均纯展示层零saveVer·2676→2815测·spec `2026-06-2{0,1,2}-p4-*`)

> **2026-06-17..20 续19-续30 已压缩归档**(第五~七阶段·git log/各closeout可溯·2301→2605测)：续19上下文帮助系统·续20主线一战斗UI表达+aoe全体伤害·续22主线三掉落传闻UI·续23即放时序2.3+首通门控2.5·续24打击感表现层2.4·续25三人协同破绽窗口·续26战后体验英雄镜头·续27Boss多阶段/弱点抗性/技能珍稀·续28批二目检+帮助按钮修·续29队伍成长渐进解锁+二弟子控制·续30四批真机目检全PASS+hero_camera路由。spec `2026-06-1{7,8,9}-*`。

> **2026-06-16 续16-18 已压缩归档**(规则层全域摸排+按级修复 `c384a0d3` + M6 心魔失败惩罚实装 `cf694faf` + M6 余毒战败摘要 UI 上下文感知标题视觉验收 · 2247→2286 测 · 详 git log + `docs/audit/full_audit_2026-06-16.md`)

> ✅ **2026-06-16 续15 已压缩归档**(全功能真审计 + 按级修复 · 合 main `b8330c14` · 2247 测):纠上会话幻觉(谎称落盘的「45 项」审计全仓查无)→重跑真审计(1 High+7 Med+1 Low+2 drift,3 个吹的 High 红线项实证全误报,报告 `docs/audit/full_audit_2026-06-16.md`)。修 H1 爬塔周目迁移数据丢失版本门 + §6 路径 drift + EnumL10n/battle_log 正名合法 sink + M3-M5 散写中文迁 UiStrings + M6 确认心魔惩罚未 wire 留拍板。

> **2026-06-15 续10-续14 五条已压缩归档**(全 commit/spec/closeout 可溯 · 2190→2245 测):续10 L3 闭关非阻塞 + M2 离线收益范围A(`7efb82c8`)+ L1 显示设置 window_manager 全屏/3 档分辨率(`130b40ac`) · 续11 L1 Codex 验收 + 两 fail 回修(720p overflow / F11→Alt+Enter `a0f77a8b`) · 续12 M2 范围B 通用被动离线挂机(saveVer0.24.0 · 9 决策 · `212b572c`) · 续13 P1b MeridianBar wiring(StageProgressRow 四系统收口) · 续14 P3 战报失败诊断(三段式复盘 `BattleDiagnosis` 5 规则 · `6a32901a`)。spec `2026-06-15-*`。

> **2026-06-14 红线/战斗交互重做批已压缩归档**(git log `7adc8532→3edc99ae` · 详各 closeout · 2160→2165 测):战斗交互重做 Phase1-4(自动播放+随时拖招,废半手动/录制回放净 -2050 行)+ 周目按章(saveVer0.23)+ 周目进化 A-F1(敌人 scale/5 反制词条/Boss HP 红线 50000→60000 · Codex 视觉 10/10)+ 拖招表现层微调(引导线外发光/蓄势呼吸光晕 · Codex 5/5)+ **红线语义收口分两层**(硬=配置基础表值 schema 拦截 / 软=极值满 build 实战可见值不进百万,balance_simulator 极值×周目诊断证伪「不进十万」)+ towers 注释补漏。

> **2026-06-12..13 半手动战斗 master spec/P0 + UX 整合/爆品展示批已压缩归档**(详 `2026-06-1{2,3}-*` spec + 各 closeout · 1950→2067 测):半手动+seed重放+周目进化 master spec 定稿 → P0 3b-5 全闭环(逐 actor stepOne/单步 UI/重放/schema 0.19 BattleReplayRecord/自手印章)+ AGENTS.md 瘦身根治双文档漂移;战斗/装备 UX 整合 12/12(藏经阁+装备链路+指令台 Codex 5/5)+ 爆品展示(印章动画/tagline 35句/时序重排)+ BGM 扩 8 轨 + StageProgressRow + 神物金光 + E 音频 Phase0。

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
