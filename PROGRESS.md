# 挂机武侠 · 开发进度

> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。
>
> **当前阶段：1.0 长线打磨期（质量优先 · 不设上线时间压力）** — Demo ✅(2026-05) → 1.0 内容周期 ✅(P1-P5+) → 打磨中。阶段一变只改本行；工作原则见 CLAUDE.md §7。

## 当前阶段

> 🐞 **2026-06-26 一键扫荡黑屏 hang bug 修复(用户实玩抓·TDD·合 main·HEAD 5b10a40b)**:进入一键扫荡卡「连播中 1/N」黑屏无限转圈、停止无效(交接 `2026-06-26_1115` 已记症状但未动手·疑 `battle_resolution.resolve` 改动)。**证伪疑点 + 定真根因**(sweep 自实装起从未真机玩):`battleProvider` 是 **autoDispose**(生成码 `isAutoDispose:true` 实证),SweepScreen `_preparing` spinner 期间不挂 BattleScreen → 无 watcher → `startBattle` 注入的队伍被回收重置回空团 → 后续挂出的 BattleScreen 拿空团黑屏 placeholder;且迟挂载错过 `startBattle` 的 `empty→非空` listen 边沿 → timer 永不起。对照 `_StageBattleHost`(stage_entry_flow)是「先挂屏空团、后 postFrame startBattle」靠边沿起 timer,扫荡反序故坏。**修(两处互补·均 opt-in 零回归)**:① SweepScreen.initState `ref.listenManual(battleProvider)` 跨本屏生命周期保活 provider 不被回收;② BattleScreen 加 `autoStartOnMount`(默认 false 保现有冻结契约·SweepScreen 传 true)挂载到已就绪活跃战斗时兜底自启,补迟挂载错过的边沿。停止现于关边界生效(原「无效」是冻结所致)。TDD `sweep_battle_plays_test`(注入真 leftWin 战斗·修前 RED 永不到 recap·单关+2 关连播双锚)。analyze**0**/全量**3102+1skip**(基线 3100·**+2**·0 回归)。**仍未真机目检**:连播手感/掉落入账/recap/停止反馈待 `flutter run -d macos`。**同会话续·前会话交接 2 个 UX 项(用户拍板做)**:① **主菜单按钮统一高度**——根因 `WuxiaInkButton` 高度由 hint 行数驱动(1 行~76/2 行~84·与缩略图无关),修为 hint 恒占 2 行高度(SizedBox 30)→ 所有按钮等高(`wuxia_ink_button_height_test` 锁短/长描述 + 带图/纯图标各等高);② **启动直达主菜单**——`splash_screen._go()` pushReplacement `HomeFeedScreen`→`MainMenu`,跳过「江湖见闻」过场 feed(离线收益由 OfflinePassiveService 照常应用·HomeFeedScreen 现开局不可达留底)。全量**3104+1skip**(基线 3102·**+2**·0 回归)·analyze 0。

> ⚡ **2026-06-26 第八阶段:角色等级 Lv + 关卡推荐境界 + 掉落悬停预览 + 战斗反馈(用户拍板 A+B+C+D 全做·brainstorm→TDD·合 main 未实玩)**:用户提新点子(非旧「形与势」框架——旧清单仓库/git/memory 全查无、只剩简写 `#1/2/4/11/12/16` 进过 spec,内容从未存盘故不可考,已废弃)。**A 角色等级**:新成长轴 `Character +level/levelExp`(saveVer 0.30→0.31)·全局连续涨(跨境界不重置)·`LevelService` 升级纯逻辑 + `LevelConfig`(numbers.yaml `level` 段)·`derived_stats` maxHp/内力/速度注入 `(level-1)×per_level` **平直有界加成**(clamp 硬守 §5.4·extremum 测扩满 build+L100)·**5 EXP 源并行喂**(主线/塔/闭关/离线/经验丹·与境界 EXP 同源)·角色面板 Lv chip+经验条·**不解锁高阶装备心法**(§5.3 锁死不动)。**B 推荐境界难度**:`StageDifficultyAssessor` 纯函数(境界差档→碾压/适中/偏高/送死·对齐 §5.5)·复用现成 `StageDef/TowerFloorDef.requiredRealm` 无新字段。**C 掉落悬停预览**:`StagePreviewHoverCard`(OverlayPortal 悬停·**出流不占列表高度**守 viewport)+`StagePreviewContent`(推荐境界+难度徽章+复用既有「掉落传闻」桶·守 §2.1 不显%)·铺**主线选关屏+爬塔层**(原只有 info 图标点击 dialog→新增 hover·保留点击 fallback·=用户「之前好像做过没找到」的真相:做过一半且是点击式)。**D 战斗反馈**:victory 显「晋 Lv N」(`LevelUpSummary` banner)。红线全守(Lv 经 clamp 不破 §5.4/不破 §5.3·掉落不显%·表现层不写 BattleState)。analyze**0**/全量**3092+1skip**(基线 3051·**+41**·0 回归)。**真机目检抓 1 真 bug 并修**:Isar **不应用 Dart 字段默认值**,旧档 Character 无 level 字段读回 int64 哨兵(-9.2e18)→ 污染 Lv 显示+速度派生(纯 bump 无迁移对新增非空 int 假设错)→ `IsarSetup.repairCharacterLevels` 启动期幂等回填 level<1/levelExp<0→1/0(兼修已升版但漏回填的破档)+ derived_stats/chip 读层钳制双保险(`character_level_repair_test` +2)。spec `docs/spec/2026-06-26-level-difficulty-lootpreview-design.md`·handoff `docs/sessions/2026-06-26_第八阶段_等级难度掉落预览.md`。**未实玩**(headless 无渲染):悬停手感/难度配色/Lv chip/「晋」banner 待 `flutter run -d macos` 副屏目检。**自主拍 balance 初值待真机校**(Lv max100/曲线120+40L/hp15·if8·speed1 每级·保守)。**D 余 2 候选**(题字命中分级/掉落金光分桶)留 backlog。**同会话实玩反馈续轮**:① 掉落预览浮层字体放大加深(推荐境界 15/墨·桶标签/物品 14)+ 底部翻向上弹+限高滚动(防裁切);② **E 稀有彩头**(用户拍板:低等级副本也爆高阶·低概率不为零):全局机制 `selectRareBonusTier`(跨 1-2 阶·各档独立 roll 取最高·封顶神物·阶梯递减)+ `rare_bonus_drop` 配置(+1阶 5%/+2阶 1.5%·初值待校)+ `DropService.rollRareBonus` 并入主线/副本 victory dropResult(自动持久+金光仪式)+ 塔首通(同 first-clear 守 §5.1)+ 预览金色提示·守 §5.3 高阶可拿不可装(境界锁兜底)。全量**3100+1skip**(基线 3051·**+49**·0 回归)。

> ⚡ **2026-06-26 一键挂机扫荡实装(主线整章 + 爬塔30层·用户拍板·TDD·合 main 未实玩)**:新增 `lib/features/sweep/`——门槛(本周目全关已首通才解锁·`SweepEligibility` 章/塔纯逻辑)/recap 战果聚合(`SweepRecap`+残页计数)/驱动状态机(`SweepController` 连播·中途停·战败 halt)/逐关托管真战斗(`SweepScreen` 强制 auto+`startFastForward` 快进连播·关间过场 `sweep_inter_battle_gap_ms`)/醒目入口(选关屏章 header + 塔屏顶金框主按钮·未解锁隐藏守 §5.7)。**结算复用既有 victory 数据路径**(`applyVictoryResolution`/`applyTowerVictoryResolution` 提公开·跳全 UI 仪式);扫荡恒重打 → 走既有重打掉落规则。**红线全守**:§5.5 真跑每场非黑箱秒结(不压缩离线/无券)·§5.1 爬塔重打仅掉残页(防刷·用户拍板「按现规则」·主线重打照常掉)·§5.6 关间走 numbers.yaml/文案全 UiStrings。BattleScreen 加 `startFastForward`(默认 false 零影响)。门槛/recap/控制器纯逻辑 TDD + SweepScreen 战败 recap widget 测 **+20**。analyze**0**/全量**3051+1skip**(基线 3031·0 回归)。spec `docs/spec/2026-06-25-one-key-sweep-{design,plan}.md`。**未实玩**(headless 跑不了真实战斗渲染):连播手感/掉落真入账/recap 总账/按钮视觉醒目度待用户 `flutter run -d macos` 副屏目检。**形与势 16 项战斗轴**(原第六阶段·⭐#1/2/4/11/12/16 框架已确认)仍未动工,后续轨。

> 🏝️ **2026-06-25 桃花岛升级成本「节奏 B」实装(用户拍板前低后高+境界分阶·xhigh·TDD)**:Phase 0.5 诊断(子代理摸排银两经济:闭关被动 8-60 银/h·战斗主动 30-280 银/关层·四座建筑全满旧值 22,400 银)→ AskUserQuestion 拍板**节奏 B**。① 升级银两从线性公式 `base+(L-1)×perLevel` 改 **per-level 显式数组** `upgrade_silver_levels`(线性做不到前低后高):source `[500,1200,2800,6000]`/座10,500、processor `[800,1800,4000,9000]`/座15,600,**四座全满 52,200 银**(后段陡 L4→5 占~50%);② 新增**按等级分阶境界 gate** `upgrade_realm_levels:[0,1,2,3]`(升 L_n→L_n+1 需祖师达对应 realm,**L4→5 需一流 realm3**·与高阶配方心血/培元同步解锁·单调非减校验)。配方比率/材料成本(base×level)/产速**不动**。config schema 改(2 标量→2 数组)+解析+`upgradeRealmFor`+validate 长度/单调强校验(GameRepository 加载期 fail-fast)+action_service realmLocked 改按等级查+UI hint 参数化显所需境界名(`taohuaIslandRealmLockedFor`)。**对抗审查抓 1 真回归**(B1:满级建筑 `upgradeSilverFor(maxLevel)` 数组越界 RangeError·旧线性公式不崩·widget 测仅 level2 漏网)→ UI atMax 守卫+补满级渲染回归测。analyze**0**/全量**3031+1skip**(基线 3017·**+14** 测:11 curve_b+T5b/c+满级渲染·0 回归)。红线全守(银两 sink 非战斗数值·中文全注释/UiStrings·数值全 numbers.yaml)。spec 见 design `docs/spec/2026-06-25-taohua-island-phase1-design.md`。

> 🎯 **2026-06-25 爬塔/战斗/结算 UI 5 修(用户实玩反馈·副屏目检确认·xhigh)**:① 爬塔 Boss 卡片「BOTTOM OVERFLOWED 36px」黄黑条纹——timeline 固定 `SizedBox(100)` 容不下已通关 Boss 的弱点行,改 `IntrinsicHeight` 自适应(`tower_floor_card.dart`);② 剧情短段落上下大片空白——`narrative_reader_screen` 文字 `Center`→`Align(topCenter)` 靠上对齐;③ 战斗 1 怪居中/2 怪上下对称——`_TeamColumn` 只渲染 team.length 槽 + `_slotFrac` 弹道坐标分母 3→实际人数 n(抽纯函数 `slotVerticalFraction` +4 测·1→0.5/2→0.25,0.75/3→不变);④ 通关后列表复位到第1层、要往下滑——`skipLoadingOnReload` 防 ListView 重建复位 + available 层变化时重滚(Boss-aware 偏移估算·`tower_floor_list_screen`);⑤ 结算屏装饰——大字上方孤立小「武」印章移除(胜利另有 VictorySealFlash)+ 弱 inkDivider 换两端淡出渐变细线(`victory_overlay`)。`victory_overlay_test` 同步印章断言→findsNothing。analyze**0**/全量**3017+1skip**(基线 3013·+4·0 回归)。

> 🏝️ **2026-06-25 桃花岛一期 = 新养成经营支柱(brainstorm→spec→plan→subagent-driven 14 task 全实装合入 main·用户出门期间自主推进)**：用户提「桃花岛」隐世经营基地——浪迹江湖回岛种养产料→转化战斗力。**生产模型**:原料(铁匠厂→精铁/草药园→药草)持续滴落+仓储 cap；加工(打造台→磨剑石/心血结晶·丹房→凝神/培元丹)连续速率自动加工(源料够即转化·零看护·用户拍板替代离散队列);**单一 settle 纯函数**进屏与离线共用→ offline=online 构造性成立；回岛「桃花岛纪事」多条目收获 recap(数字跳动)。状态嵌入 SaveData(`saveVer 0.30`·IslandBuildingState @embedded)。升级反哺(银两+自产材料·境界锁高阶配方 realm3)。main_menu 入口·第二章 cleared 解锁。**红线全守**(offline=online 无加速/无体力每日登录/cap 非 FOMO/复用 P4 经济精铁药草=miscMaterial 银两=item_silver/数值全 numbers.yaml/中文全 UiStrings+EnumL10n)。**每 task spec+质量双 review + final 整体 READY_TO_MERGE**;查实并修一处 Task13 回归(MainMenu 新读 config 崩 home_feed 轻量测→GameRepository.instanceOrNull 防御)。analyze**0**/全量**3001+1skip**(~120 桃花岛测·0 回归)。spec/plan `docs/spec/2026-06-25-taohua-island-phase1-{design,plan}.md`。**一期边界(留二期)**:木工坊/矿洞/灵泉·闭关离线迁移归口·疗伤药&战斗消耗(撞伤势红线)·行商·装饰·多品类原料。**pending**:~~配方比率/升级成本占位待后续 balance~~ 已销账(配方比率诊断为自洽不动·升级成本节奏 B 2026-06-25 实装,见顶段) + GUI 手感/中文渲染本地目检(本环境无完整 Xcode headless 无法验)。第六阶段战斗轴(流派形与势 #1/2/4/11/12/16)挂账待回。

> 🏝️ **2026-06-25 桃花岛 balance 第一刀:cap 对齐 72h(用户拍板·确定性探针校,非实玩)**:Phase 0 诊断发现 `cap_hours=72` 与各仓实际 cap 不自洽——旧 cap(源料 200@33h 饱和 / 打造台 80@53h / 丹房 60@60h)在 72h 前就封顶,离开 33-72h 一次性 settle 被源料 cap 提前截断(磨剑石仅 50 vs 应得 80),长挂玩家拿不满 cap_hours 承诺的量(非违 §5.5——settle 按真实 elapsed 结算,游戏开/关严格相等;偏差仅出在「单次离开>33h」)。**用户拍板①对齐 72h**:各 cap 改线性式 cap(L)=base×L 且 base ≥ 满速×72(源料 200/100→450/450、打造台 80/40→120/120、丹房 60/30→80/80),使一次性 72h ≈ 持续累积。**②产速保持温和补充**(不动 base_rate/recipe rate,L1 磨剑石 1.5/hr·凝神丹 1.0/hr·定位叠加战斗掉落的零看护补充线)。新增红线测 `island_offline_online_invariant_test`(基于真实 numbers.yaml·全 level×全 recipe 锁「一次性 settle==分块 settle」+防回退断言成品满产未被 cap 截断·+12 测)。screen_test cap 断言同步(50/300→50/900)。analyze**0**/全量**3013+1skip**(基线 3001·+12·0 回归)。

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
- **2026-05-28 过夜清理+P3 三项+P2.1 4 批+drop 全覆盖+CHECKLIST v1.5+R4 派单**(1505→1519 测 · 详 `overnight_1_1_cleanup_handoff_2026-05-28.md` / `session_closeout_2026-05-28_p3_p1_triple.md` / `codex_dispatch_r4_p2_1_content_drop_2026-05-28.md`)
