# 挂机武侠 · 开发进度

> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。
>
> **当前阶段：1.0 长线打磨期（质量优先 · 不设上线时间压力）** — Demo ✅(2026-05) → 1.0 内容周期 ✅(P1-P5+) → 打磨中。阶段一变只改本行；工作原则见 CLAUDE.md §7。

## 当前阶段

> ✅ **2026-06-18 续25(第六阶段·三人协同 破绽窗口链路 · brainstorm→spec→plan→8 task subagent-driven TDD · 分支 `feat/phase6-coop-window` · opus xhigh)**:Demo 起即 3v3 但三单位**各打各的**(Phase 0 子代理证:协同深度≈0);本批让其真协同。**拍板**:① 范围=协同深度(不做渐进解锁/编成 UI)② 形式=破绽窗口链路(时序协同,非被动 buff)③ 开窗=破招(现有踉跄)+ 新增破防(`SkillDef.defenseBreakPct>0` 命中即开,不要求蓄力)④ 收益=减防(clamp `interrupt_power_cap` 0.5 上限=防御有地板)+ AI 集火 + 即放提示 + 表现层,**不走数值膨胀**⑤ 职责=软引导不锁(autoFill 倾向)。**架构=方案 A 泛化现有踉跄**(复用 `staggerTicksRemaining`/`staggerDefenseDownOverride` 零新 BattleState 字段)。8 task:T1 schema · T2 破防开窗(统一破招/破防窗口 + 刷新不叠加取 max + 减防上限 clamp · `BattleAction.openedBreakWindow` 纯破防与 interrupted 互斥)· T3 AI 集火(`_pickFocusTargetId` + notifier 确定性测)· T4 表现层(题字「破绽」复用 2.4 glyph + `_GlowAura` 敌方侧高亮)· T5 即放提示(gate `allowPlayerIntervention`)· T6 autoFill 软引导(弟子→破防/祖师→爆发,**经 2 轮修死接线+死代码**)· T7 破防技内容(三流派各挂开窗手 破甲掌/旋身刺/隐影爪 + trait 标签接 picker)· T8 红线测(破绽爆发极值探针 136261 < 百万 · 7.3× 余量)。每 task 两阶段 review(spec+quality)+ 最终 opus 整体 **READY TO MERGE**(链路端到端连贯 · §5.4 减防 clamp+refresh-max 不进百万 / §5.5 集火只改目标自动战斗等价 / §5.6 yaml+UiStrings / §5.7 爽感走表现层 全守)。亲测全量 **2418 测 +1 skip**(baseline 2382 **+36** 零回归)/ analyze **0**。**遗留 backlog**:二弟子→控制(依赖 LineageRole 子枚举,当前两弟子都→破防)+ 渐进解锁/编成 UI/Boss 协同窗口续作。**视觉验收**:题字/高亮/提示静态可截,集火/时序单帧截不出 → 待真机目检(沿 2.4 体例)。**下一步**:合 main + push;真机 `flutter run -d macos` 目检;或 P2 续作/P3。

> ✅ **2026-06-18 续24(第五阶段·主线二 2.4 打击感表现层 · brainstorm→spec→plan→subagent-driven TDD · 代码 HEAD `98187ff3` 并 main fast-forward · opus high)**:第五阶段唯一未做批闭环。**拍板**:① 触发分层(普攻保留现有受击闪+飞泥,重击才上四件套)② 题字双轨(大招/人剑合一全名题字 / 强力技·暴击普攻单字「斩·震·断」/ 破招继续「破!」)③ 分级递进(暴击普攻 light < 强力技 medium < 大招 heavy,hit-stop/震幅/闪白三参数按档增)。**架构=中央 `impactProfileFor(action,cfg)` 纯函数派生 + `_playAction` 单点调度**(tier/glyph 全派生现有 `SkillDef.type/style`+`action.interrupted`,零 schema)。四件套:hit-stop(`_applyHitStop` 延后 `_playTimer`,快进/拖招跳过守 2.3 时序)+ `ImpactGlyphOverlay` 单字水墨题字 + `ScreenFlashOverlay` 全屏闪白 + **分档屏震复用既有 `_shakeCtrl`**(Phase 0 补漏:发现 battle_screen 已有暴击固定振幅屏震 `screenShakeOffset`,删掉初版平行 `CameraShake` 防双抖,振幅改 profile 分档 + 删 `_spawnPopup` 旧暴击触发集中到 `_playAction`)。glyph 单字进 UiStrings、三参数进 `numbers.yaml combat.impact_feedback`。防重叠:任一 action 至多一题字通道(全名 XOR 单字 XOR 破!,大招/破招 glyph=null)。6 task 每 task implementer+spec+质量两阶段 review(快修:style switch 穷尽 + flash/shake mounted 守卫 + `_startTimer` 作废挂起 hit-stop + 标 `shakeOffsetPx` 已被分档取代)+ 最终 opus 整体 review **READY TO MERGE**(红线 §5.4 不写 BattleState/伤害零调用 · §5.5 hit-stop 只动屏上播放节拍后台挂机不触发 · §5.6 yaml/UiStrings · 2.3 不碰 interveneNow/AP 全 PASS)。亲测全量 **2382 测 +1 skip**(baseline 2368 **+14**:11 纯函数测 + 3 widget 测,零回归)/ analyze **0**。spec+plan `docs/spec/2026-06-18-phase5-mainline2-batch24-impact-feel-*.md`。**已知小缺口**(非阻塞):`_playAction` 端到端防重叠未单独 widget 测(逻辑已在纯函数层锚死,端到端需重型战斗 harness)。**视觉验收**:打击感=运动/时序效果(hit-stop/屏震单帧截不出),用户拍板**并 main + 真机 `flutter run -d macos` 手感复验**(待用户真机目检 hit-stop/震/题字/闪白手感)。**下一步**:第五阶段主线一✅+aoe✅+主线二✅(2.3/2.4/2.5)+主线三✅ **全闭环**,可收尾盘点 / 下一主线拍板。

> 🚧 **2026-06-18 续23(第五阶段·主线二 2.3 即放时序 + 2.5 首通门控 · brainstorm→spec→plan→subagent-driven TDD · 已并 main `a3efa5ec` · opus xhigh)**:**2.3 拍板=引擎级真插队·预支语义**;**2.5 拍板=首通强制 interactive**。**修正源 spec 两处 stale 前提**:① 2.3 前置「读 BattleReplayRecord 保重放」不成立(该 collection 在 saveVer0.23 随录制回放链删除,`isar_setup.dart:114`)→ 确定性只靠单一 `_rng`+advance 递进;② 2.5「自动推进」是 loose wording,实测无跨关自动链。**2.3**:`BattleStrategy.interveneNow`(抽象默认降级 `requestUltimate`/pending 保 LightFoot/MassBattle 零回归)+ `DefaultGroundStrategy` override(noop 守卫 finished/dead/normalAttack/踉跄/蓄力 → 置 pending → **借 AP=1000 → 复用单一真相源 `_resolveAction` 立即结算,出手 -=1000 自然归零**=预支,净出手频率近不变非数值杠杆)+ `BattleNotifier.interveneNow`(同 `_rng` 委托)+ `_onSkillCommand` 改调它退 C5 rush + 插队确定性红线测。**2.5**:`isFirstClear` 纯函数 + `resolveAutoPlayModeWithFirstClear`(首通→interactive 无视设置)+ `stage_entry_flow` initState 接入,**仅主线**(不含爬塔)。每 task spec+质量两阶段 review(修 I-1/I-2 踉跄/蓄力/普攻 noop 防线 + 4 处 stale 注释 + initState 兜底注释 + tick 边界不变量注释)。最终 opus 整体 review **READY TO MERGE**,**红线 §5.4(借AP预支不加总输出·内力不回复硬封顶)+ §5.5(只解锁拖招层不改速度)双守住**。亲测全量 **2368 测 +1 skip**(baseline 2356 **+12** 零回归)/ analyze **0**。spec+plan `docs/spec/2026-06-18-phase5-mainline2-tempo-firstclear-*.md`。**视觉验收**:Claude 真机自截 `battle_drag_live` 路由——interactive 拖招层/技能指令栏/3v3/单步控件渲染正常**无布局回归 PASS**;拖招即时出手纯手感单帧不可截,由 intervene+确定性测+opus review 端到端锁死(无 cliclick 不合成手势)。**下一步**:第五阶段主线一✅+aoe✅+主线二✅(2.3/2.5)+主线三✅,可收尾盘点 / 下一主线拍板;2.4 打击感表现层(high)仍未做,可选。

> 🚧 **2026-06-18 续22(第五阶段·主线三 掉落传闻 UI · brainstorm→spec→plan→subagent-driven TDD · 分支 `worktree-phase5-mainline3-loot-rumors` 未并 main)**:**4.3 首通必得数据源拍板 = B(派生不加字段)**——零 schema/迁移/奖励经济改动,纯展示层只读现有 `dropTable`。新建 feature `lib/features/loot_preview/`:`drop_rumor.dart`(桶映射纯函数 `bucketOf` + `DropRumorTable.fromDropTable/grouped/topRepresentatives`,桶=常可得/偶可得/少有人得/江湖传闻,**首通必得仅爬塔**[isFirstClearGated 上下文位])+ `drop_name_resolver.dart`(薄复用 GameRepository/EnumL10n,repo 未加载降级 raw defId)+ `loot_rumor_dialog.dart`(info 角标点弹 PaperDialog 分组列,越阶标「机缘可遇,火候未到」,塔层底部脚注「仅首通可得」)+ `loot_summary_line.dart`(卡片「可能收获:X·Y·Z」)。接入 `stage_list_screen`(stage=false)+ `tower_floor_card`(tower=true)。**T7 暴露并修正 spec 错误前提**:严格不越阶守卫被实测证伪(18 处「越阶」全是章末 Boss +1~+2 阶前瞻奖励,§5.3 锁境界,非 bug)→ 用户拍板守卫放宽 `tier.index ≤ requiredRealm.index + 2`。**T9 抓到并修真回归**(子代理只跑自测漏跨文件:info 角标增高卡片→列表超 4000px 测视口→自动滚动→楼层标签滚到背景图后挡命中,既有塔层测挂)→ 回退高度 + loot 独立底部行 + GestureDetector+Tooltip。文案全进 UiStrings(10 词条 · 白名单测拦网游稀有词+%)。全 9 task 每 task spec+质量两阶段 review。亲测全量 **2355 测 +1 skip**(baseline 2326 **+29** 零回归)/ analyze **0**。spec+plan `docs/spec/2026-06-18-phase5-mainline3-loot-rumors-*.md`。**视觉验收 ✅ 全 PASS**:Claude 自截第1层静态布局(stage_list+tower 简版行不溢出/塔层增高协调/ⓘ 渲染/真名)PASS;Codex 第2层弹窗 A 关卡(点 ⓘ 弹「本关传闻」分组列·不误触)+ B 爬塔(首通必得桶+脚注)PASS,无%无网游词(派单 `docs/handoff/codex_dispatch_phase5_mainline3_loot_dialog_2026-06-18.md`)。**下一步**:并 main;或主线二 2.5/2.3(xhigh)新会话开。

> 🚧 **2026-06-17 续20(第五阶段·战斗体验与掉落优化 开篇 + 主线一闭环 · opus xhigh · subagent-driven TDD · 分支 `feat/phase5-battle-experience` 未并 main)**:源桌面《战斗体验与关卡掉落优化完整方案》。**GDD §5.7 新增「战斗体验原则(爽感主旋律)」**(即拖即放立即出手 + 爽感走表现层边界:不数值膨胀守 §5.2、不抽卡稀有炫耀守 §2.1)+ spec `phase5_battle_experience_loot_spec_2026-06-17`(三主线:战斗UI表达 / 普攻节奏+即放打击感+首通门控 / 掉落传闻)。**主线一全 4 批闭环**:①1.1 内力条加「内 X/Y」标签 + 1.2 技能按钮「耗内N · CDM」+「内力不足」态(`d8f956e1`);②1.3 **点击技能方块=简介浮层**(PaperDialog 直读 SkillDef 活数据)+ **长按拖=下发**、退裸单击下发(`ba0f6227`);③1.4 buff/debuff(内伤/踉跄/剑鸣)贴头像 + 薄 GlossaryTip hover 释义(`3e7668f5`)。文案全进 UiStrings/EnumL10n,纯表现层不动战斗逻辑/伤害公式。中途 1.3 子代理撞 500 中断→恢复;暴露子代理只跑 scoped 测漏顶层 widget_test 真回归(已迁)。全量 **2314 测 +1 skip**(baseline 2301 +13)/ analyze **0**。**续21(本会话)**:Codex 首轮验收回——A 单击简介/B 不裸发/G 内力标签/H 布局 PASS;C 拖招/D aoe 单击简介/E 内力不足/F debuff hover 因验收路由自动战斗数秒结算没验上。诊断「群体直发」提示**是 stale 非 bug**(1.3 后 aoe 单击已弹简介,battle_screen:1902 无 aoe 分支)→ 修 6 处 aoe stale 文案/注释 + 补 `battle_drag_live` 起手暂停(`startPaused` gated 不污染生产挂机)+ 顶栏单步按钮(复用 `BattleNotifier.step()`)路由 + 4 widget 测。亲测全量 **2319 测 +1 skip**(2315→2319 零回归)/ analyze **0**,commit `01de03b9`+`a2a339d3` push。**aoe 全体伤害实装(Task 1-6)**:battle_ai `decide` 返回 targetIds 列表(single 单元素 / aoe 全体存活敌按 slotIndex 升序)+ `_resolveOneTarget` helper 各目标完整伤害独立结算(无衰减无均摊·暴击/克制/附加逐目标判)+ aoe 确定性测 + 红线断言(单次不抬高)。**Task 6 [GDD] 补 §5.8 招式目标类型**(single/aoe 规则·与 §5.7 拖招交互·守 §5.4 软红线·commit `5d1be323` 未 push)。drift grep:`§八#4`/`前瞻`/`AoE 引入后` 生产代码 0 残留(battle_ai:40「群体技自动」是描述实装行为的合法注释非 drift),余 `§八#4` 引用仅在 docs/spec/session 历史不动。全量 **2326 测 +1 skip** / analyze **0** 零回归。**aoe 全体伤害 + 主线一全验收通过并 main**:Codex v2 复验(`codex_phase5_aoe_reverify_2026-06-17.md`)C-aoe 拖招打全体 PASS(3 敌 40000→29713 全体扣血)、F 内伤标签 PASS;F hover 释义 = GlossaryTip 标准 Flutter Tooltip(桌面 hover 内置)实现正确 + widget 测覆盖(`avatar_status_tags_test.dart:120` 断言内伤标签 Tooltip message==释义),Codex CGEvent 合成 hover 注入不稳定未截到属**验收手段限制非缺陷**。主线一(战斗 UI 表达 1.1-1.4)+ aoe 全体伤害(GDD §5.8)已并 main。全量 **2326 测 +1 skip** / analyze **0**。**下一步**:主线二(普攻节奏/即放时序 2.3 xhigh/首通门控 2.5)或主线三(掉落传闻 UI,先拍 4.3 A/B)新会话开。

> ✅ **2026-06-17 续19(上下文帮助系统 阶段一~三 · overnight 自主 · spec→TDD · 合 main `49a46452`)**:新可玩性能力——高频页术语/页面级 `?`(悬停短释义 + 点击跳「江湖见闻录」)。源桌面修订稿,**核心砍双真相源**(中文全引 `UiStrings`,step/category 经 `CodexIndex` 派生)。①**基础设施**:新建 `features/help`——`HelpTopic`(23 词)+`HelpBinding`+`HelpCatalog` 薄映射 / `GlossaryTopicLabel`(薄包装委托 shared `GlossaryLabel`)/ `ContextHelpButton`(ConsumerWidget,复用 `codexListItemsProvider`+`currentTutorialStepProvider` 判解锁,解锁跳 `CodexEntryDetail`、未解锁灰显「阅历未至」吃 step gating)。②`WuxiaTitleBar` 加通用 `trailing` 槽(加法·shared 不依赖 features)。③**接入 9 屏**:角色面板→realm / 装备详情+仓库→equipmentTier / 藏经阁→mainTechnique / 战斗 `_Header`→combat_advanced / 闭关 4 屏→retreat。视觉:character_panel+equipment_detail CLI 自截 PASS(? 克制不溢出);battle/seclusion 两 route 本环境截图 flake(build 正常·route 不发 READY·与改动无关)→ widget 测兜底,留真机目检。全量 analyze **0** / 全量 **2301 测**+1 skip(+15)零回归(主 checkout 验)。**阶段四 backlog**(handoff):tower/stage 无 codex 待拍板·encounter 无 AppBar·后期系统 gating·首次金提示点·角色面板 11 处迁 topic。spec `contextual_help_system_spec_2026-06-16` · session `2026-06-17_help_system_phase123`。

> ✅ **2026-06-16 续18(M6 余毒战败摘要 UI 视觉验收 + 上下文感知标题 · opus high)**:补 VISUAL_ROUTE `defeat_inner_demon_residue`(复用真实 `NarrativeReaderScreen`+topBanner 渲染路径,两条样例余毒 entry 还原排版)→ CLI 自截 720p/1080p + Read 自验:**「余毒未消」段排版 PASS**(最长行「内力段·修炼度回退段·余毒未消段」三段单行无溢出/截断,两分辨率一致)。**真机验收暴露既有瑕疵**:`_DefeatLossBanner` 标题硬编码「散功代价」(Boss 散功术语),心魔关余毒场景(与 Boss 散功按关卡互斥)口径偏 → 改**上下文感知**(全余毒 entry→`defeatLossTitleInnerDemon`「战败·心魔反噬」/否则→「战败·散功代价」)。+`buildDefeatLossBanner` 公开薄暴露私有 banner(供 route+测复用,不改运行时行为)+ banner widget 测 2 条(余毒段渲染/标题双态)。全量 analyze **0** / 全量 **2286 测**+1 skip 零回归(+2)。route 验收基建永久留用。

> ✅ **2026-06-16 续17(M6 心魔失败惩罚实装 · brainstorm→spec→plan→9 task TDD subagent-driven · 合 main `cf694faf` · opus xhigh)**:**唯一实质挂账清账**——GDD §12.1 设计但零 wire 的心魔关战败惩罚接入战斗结算 + 存档。**惩罚**(`resolve` 战败 + `StageType.innerDemon` 分支,与 Boss 散功 isBossStage **天然互斥**):参战有主修角色内力 ×0.85(地板=`internalForceMax`×0.50 防无限重试归零,新 yaml `inner_demon.failure_penalty.internal_force_floor_pct`)+ 主修 progress ×0.90(**不掉层**,`InnerDemonService.applyFailurePenalty` 纯逻辑)+ 设余毒。**余毒 debuff**(新持久字段 `Character.innerDemonResidueHoursRemaining`):战斗输出 ×0.95(新 `BattleCharacter.outputMultiplier` 末端乘,独立于 SET 语义的 attackPowerMultiplier 不被覆盖)+ 闭关内力产出 ×0.80 + 闭关累计满 8h 清(按游戏内时长非墙钟 §5.5)。战败损失摘要展示心魔惩罚 +「余毒未消」。**决策(用户拍板)**:每败叠扣 + 地板 / 闭关满 8h 清 / 全参战角色。**红线全守**:系数全走 numbers.yaml(§5.6)· outputMultiplier 只降不升不放大伤害(§5.4)· 持久化走战败 putAll 自动写回。8 task 每 task spec reviewer + 最终整体 opus review **READY TO MERGE**(余毒生命周期闭环/互斥边界/持久化独立核实)。全量 analyze **0** / 全量 **2284 测** +1 skip(+37)零回归(主 checkout build_runner 后实测)。spec+plan `2026-06-16-m6-inner-demon-failure-penalty-*`。

> ✅ **2026-06-16 续16(规则层全域摸排 + 修复 · 项目侧合 main `c384a0d3` · opus xhigh · 4 维只读扇出)**:基于本会话幻觉教训,对 memory / 全局 CLAUDE.md / 命令skill / 项目 CLAUDE+GDD **四域只读摸排**(真图景 **2 High + ~13 Medium + ~5 Low**,memory 130 条 0 死链、挂机武侠引用 0 失效)。最危险 = **check-redlines skill 硬编码废弃 v0.1 红线、与 GDD §5.4 直接矛盾**(同「stale 规则产出错误结论」病根)。**全局侧修复**(`~/.claude` 即时生效,未版本化):check-redlines 重写(删硬编码→运行时读 GDD §5.4 + 跑 16 红线测 + 修路径)· flutter-review 补 build_runner 前置 + 强制贴原始输出 · wuxia-content 修路径 + 自检硬核对 · handoff-light 补 sha 禁转抄 · 全局 CLAUDE 补防幻觉阈值7(行号/状态 drift)+ Flutter 预览主次(Isar 默认 macOS)· 删 4 个 Pen/Windows 失效孤儿 memory · life_time_app 瘦身 135→30 行 + 删 4 明文密钥 + 对齐搁置 · 修 codex_backup 死链 + MEMORY.md 索引误述。**项目侧修复**(本 commit 纯文档/注释 0 代码):GDD §6.6 DeepSeek 自相矛盾(v1.17 漏网)· CLAUDE §12.2 三处行号 drift 去钉改符号引用 · GDD 索引 §12 描述 · numbers.yaml Boss 血量注释 50000→60000。**配套**(本会话前期):/handoff 补 0d 交付物实证(禁编造已落盘/已push/sha)+ 全局 CLAUDE 补防幻觉统一守则段。

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

> **2026-05-30 H1 修复批全闭环已压缩归档**(`58c6f29`→`2dd597b` · 1555→1569 测 / 0 analyze):批1 主菜单 7 未解锁系统 §5.7 门控 + 门派名迁 UiStrings · 批2 `EquipmentService.equip/unequip` 装备穿戴入口(修核心循环断裂 · §5.3 守卫 + picker)· 批3 掉落 dialog 品阶仪式感 + 闭关装备名 bug + 凝练常驻态 + 过场调色 + tick→回合术语 · picker「他人装备中」移装标注。详各 commit/closeout。

> **2026-05-29 详条已压缩归档**(全程 commit/closeout/git log 完整可溯,1534→1555 测):① 方向调整(F/G Steam 搁置 · H 段升主聚焦 · balance_simulator PoC)· H1-Q1 主菜单产品名 P0 清零 · H2/H3/H1 三部曲 audit(`h{1,2,3}_*_audit_2026-05-29.md`)② 外部 review 修复批 P1-a 飞升 auto_swap §5.3 守卫 / P2-a 奇遇招式池空 fail-fast / P2-b 敌人属性抽 numbers / P2-c 战斗公式双路径收敛单一真相源 / P3 三文档血量公式 drift 对齐(commit `559455f`/`f719172`/`62b0b7e`/`2686815`/`1afc888`)③ 根因A 挂机循环重平衡 B1+B2+B3 实装(共鸣双管+闭关 EXP+insightPoints sink · `a359dc2`/`d7ee3f9`)+ B2 低 tier EXP 回 ×1.0 修正 + idle_economy 验证 · 红线值统一 numbers.yaml(`7a1d1e7`)· balance_simulator 升真 build + floor/ceiling bracket + on-level 修正 ④ D 段难度修复:stage_01_05 Ch1 Boss +2 阶硬墙(`781c85b`)+ stage_05_05 跨阶过苛缓和(`24cea80`)→ 过难关清零。


---

## 已知偏差 / 挂账事项

- ~~#37-#45 / stage_05_05 跨阶墙 / equipment_detail '(基 $base)' nit~~ 全销账(2026-05-17..06-08):详各 closeout + 末尾归档

> 已销账条目(#1-#45)详见末尾归档。**P1 阶段全销账 ✅** + **Demo §8.4 14/14 全达标 ✅** + **1.0 ~95% release ready ✅**(A+B+C 全 PASS · 剩 D-G 留 M15-16)。

## 关键约束(每次开局必读)

- 数值红线:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000(GDD §5.2)
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
