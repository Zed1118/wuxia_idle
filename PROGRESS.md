# 挂机武侠 · 开发进度

> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。
>
> **当前阶段：1.0 长线打磨期（质量优先 · 不设上线时间压力）** — Demo ✅(2026-05) → 1.0 内容周期 ✅(P1-P5+) → 打磨中。阶段一变只改本行；工作原则见 CLAUDE.md §7。

## 当前阶段

> ⚙️✅ **2026-07-03 测试节奏收口(v1.29)+ clamp 迁 numbers.yaml 合入 main `ef9bedb7`(已 push·ls-remote 核实)**:接用户反馈「测试太频繁费时」。**① 测试节奏(CLAUDE v1.29·`2318a043`)**:全量默认 `-j1`→并发——10 核实测 **2m34s vs `-j1` 9m42s(3.8×·3587 pass 0 fail·零覆盖损失)**;§8.0 定「何时全量」(自包含改动 targeted+analyze / 跨切面或批末才全量 / 交接验绿态只 analyze)。**② clamp 0.95 迁 config(`[schema]`·行为保持)**:`red_lines.combined_rate_cap: 0.95` 单一真相源,兑现 2026-05-29 消 hardcode 意图;**7 处**散落 `clamp(0.0, 0.95)`(Phase 0 grep 实数,handoff 记「3/×4」是 drift)全接 config——stage_battle_setup:343 直读 + light_foot/mass_battle `_bake`/`applyTerrainTo`/`applyFormationTo` 加可选 `rateCap`(默认 0.95 fixture fallback)生产经 runToEnd 传 `n.combat.redLines.combinedRateCap`;值不变零行为改动,+2 配置驱动红绿测 + 3 red_lines parse/drift 断言。**已验证(主 checkout)**:analyze **0**·全量 **3589 pass/1 skip/0 fail**(默认并发 2m42s·基线 3587→+2·零回归)·裸可执行 `clamp(0.0, 0.95)` 归零(余 6 为注释)。清 worktree+分支。**跨项目 memory** `feedback_test_cadence_no_blind_full` 已存。剩余候选:死文档归档(先证伪 content_guide/AGENTS/data_schema)/README 重写(需拍板深度)/批次4 CI(用默认并发 ~2.5min)。

> 🧹✅ **2026-07-03 批次2/3 清理批(batch-123)合入 main `c58e9221`(--no-ff·已 push·ls-remote 核实)**:接「处理123」批量授权,3 只读 Phase 0 代理侦察 + 主会话逐点 grep 证伪后落地无拍板项。**① 删 59 零引用资产 8MB**(17 MJ `*_01` 旧稿=已被 `*_blend` 替代 + 42 敌人立绘=commit `e73979ce`(06-28)删敌人定义连带弃·独立 grep 现算 + 移除史双证;iconPath 静态全路径无动态拼接;backlog 原记 44.9MB/67 是 drift)。**② numbers.yaml `tower`/`synergies` 两死配置段补 unused 头注**(证实 `NumbersConfig.fromYaml`(numbers_config.dart:322+)不解析二者·synergies 真实源=独立 synergies.yaml;附带发现 tower.daily_attempts 每日5次限制未实装)。**③ ExactAssetImage ×5 全迁 WuxiaImage**(seclusion 4 屏+portrait_frame·全仓归零·获 cacheWidth)。**关键证伪(同 tier_* 教训)**:backlog「3 死文件删除」(battle_engine/battle_demo/stage_auto_play_control)**全否决不删**——实为平衡红线模拟引擎 / 7+ 屏测试夹具 / 未接入功能组件,盲删摧毁诊断体系。**已验证(主 checkout 合并后)**:analyze lib/ test/ **0**·全量 `flutter test --no-pub -j1` **3587 passed/1 skip/0 fail**(基线不变·零回归)。清 worktree+分支。**用户拍板已落地(合 `b7cc4733`)**:①66篇孤儿文案(techniques 26+insights 40·NarrativeLoader 不扫+narrativeInsightId 零消费)`git mv`→`data/narratives/_archive/techniques/`+删 pubspec 2 声明+README 迁回指引(路径 _archive 段守卫豁免·knownInsights 硬编码白名单不依赖文件位置·全量 3587 passed 零回归) ②home_feed/stage_auto_play 未接入组件**保留待接入**(不动) ③docs/handoff **证伪无需改**:图片已由现有 .gitignore(L65-67)挡·tracked 全是 395md 小文档·2.7G 是已 ignore 的未跟踪 capture(Agent 报「2.7G tracked」误导)。**剩余下波候选**:clamp 迁 yaml(改解析类)+死文档归档(先证伪 content_guide/AGENTS skill/codex 依赖)+README 重写+setUpAll(11-15h 缓)。

> 🧹✅ **2026-07-02 批次 2 剩余资产收尾(_suno 归档 + tier banner 清理)合入 main `cab6b701`(--no-ff·未 push)**:接批次 2 backlog 两项。**① `_suno_candidates` 75M** 本地候选音频(已 gitignore/未跟踪)`mv` 出项目→`~/Desktop/wuxia_suno_candidates_archive_2026-07-02`(可恢复·零 git/包影响)。**② tier_*.png 7 张**:Phase 0 **证伪 backlog「约定未接线」误记**——实为 2026-06-29(commit `16941355`)**用户目检否决**的卷轴 cover(写实木轴 PNG 抠图白边叠深底突兀),已由 `technique_panel _TechniqueTierHeader` 纯绘制水墨文字头替代;告知真相后用户拍板删。删 7 图+.gitkeep(目录移除)+pubspec `assets/techniques/` 声明+订正 technique_def/phase2_seed/visual_route **3 处 stale 注释**+backlog 正名。纯资产/注释·零碰 numbers/结算/schema。**已验证(worktree 全量+主仓复验)**:analyze **0**·全量 `flutter test --no-pub -j1` **3587 passed/1 skip/0 fail**(基线不变·零回归)。清 worktree+分支。批次 2 剩余(44.9M 其余零引用 ui/mj/enemies·docs/reviews gitignore)仍 backlog。

> 🗜️✅ **2026-07-02 `.git` filter-repo 瘦身合入 main `5bd36fc1`(重写全历史+force push)**:批次 2 剩余项①落地。`.git` **2.5G→658M(减 74%)**,分两杠杆:**① 安全 gc**(`reflog expire --expire=now --all`+`gc --prune=now`·**零重写/零 force push/零风险**)清不可达对象 2.5G→1.1G;**② filter-repo** 剥 `docs/**/*.png|jpg`(500.5M 纯验收废图·853 个 `.md` 记录全保留)+ 删 **121 个 `refs/codex/*`** turn-diff 检查点垃圾 refs(filter-repo 无法重写裸树 refs·把 364 个 docs 图片 blob 钉活是没瘦下去主因)+ gc,1.1G→658M。**双拍板(用户)**:剥 docs 图片+force push(不做额外旧 PNG 资产剥离)/本地 37 张废图直接丢弃。HEAD **caba2422→5bd36fc1**(全 2564 commit 新 hash·3 个纯图片 commit 过滤后变空被 filter-repo 默认剪)。补 `.gitignore` 挡 `docs/reviews/`+`docs/art_ref/` 图片防回流(`docs/handoff/` 早有规则)。**已验证(本会话现跑)**:历史 docs 图片 blob 残留 **0**·692 个 docs `.md` 全保留·工作树干净·**远端 `ls-remote` 核实 main+13 tag 全 = 5bd36fc1**(非 push 回显)。纯 git 维护·零碰 lib/test/data/numbers/结算/schema(analyze/test 不受影响未重跑)。`.git` 全备份留 job tmp 兜底。**GitHub 远端体积**:force push 已顶掉旧历史 ref,旧对象变不可达,GitHub 服务端 gc 择期回收(非即时)。批次 2 剩余(零引用 tier_*/audio candidates)仍待拍板。

> 🎨✅ **2026-07-02 资产瘦身批(六维审查批次 2·webp 转码)合入 main `2fe743ea`**:分发包 210MB PNG 有损转 webp 瘦身。**双拍板(用户)**:① q80 画质档(Claude 目检 4 类样张——背景大图/特效alpha层/立绘/图标——q80 肉眼无压缩痕迹,水墨厚涂对有损极友好)② **方案A**:文件名保留 `.png`、内容换 webp,Flutter `AssetImage` 按内容 magic bytes 嗅探解码(非扩展名),故 lib/data 共 **475 处 `.png` 引用 + pubspec 目录声明零改动**,规避改扩展名的大面积漏改(漏改即运行期资产静默缺失,正是刚修的 P0 类风险)。**门槛策略**:只转有≥10%收益的 **324 张**(省 145.2M),**110 张小图标保持真 PNG**(转 webp 反变大)。**assets PNG 210.2M→64.7M(省 69%)**;按目录 ui 88%/techniques 73%/scenes 72%/enemies 60%/characters 57%/maps 54%/equipment 19%。新增 `test/data/webp_in_png_decode_test.dart` 解码守卫(端到端证 rootBundle 读 webp bytes→skia 解出正确尺寸 896×1344)+ `assets/README.md` 约定 + `tool/convert_assets_webp.py` 幂等复用脚本(Pillow q80 method6)。**已验证(worktree 全量 + 主 checkout 定向)**:analyze lib/ test/ **0**·全量 `flutter test --no-pub -j1` **3587 passed/1 skip/0 fail**(基线 3586→+1 新测·零回归)·主 checkout 合并后解码+pubspec 守卫 4 测复验绿·抽样 file 确认转的=webp/保持的=png。**未 push**(待用户)。批次 2 剩余项(44.9M 零引用清理/docs/reviews gitignore/audio `_suno_candidates`/handoff capture)未动,仍 backlog。
> 🔍✅ **2026-07-02 全项目六维全面审查(报告 `docs/audit/full_project_review_2026-07-02.md`)**:6 并行只读审计代理(架构/红线/测试/数据/性能/文档)+主会话交叉证伪。**总评:核心质量优,短板在工程外围**。**P0×1**:pubspec 漏声明 `data/lore/sect_event/`→10 篇门派事件文案运行期不可达(构建产物双重复核,修复=一行 pubspec+守卫测)。**P1×12**:无 CI/分发包 210MB PNG 未压缩(webp 可 -70%)/44.9MB 零引用资产入包/git 2.4G(docs/reviews 26 张大图漏 ignore)/core 分层违规 1 处(system_clock_provider)/battle_screen 3102 行/battle_engine 等 3 死文件仅测试续命/玩家可见中文散写 ~11 处/66 篇文案无加载管线(narratives/techniques 26+insights 40)/numbers.yaml tower+synergies.effect_values 两段 0 消费/243 测试文件 setUpAll 样板重复/GDD 全文 0 提及桃花岛(反向 drift)。健康面:反主流 0 命中·三系锁死闭环·倍率 max=8000 合规·id 联结双向差集 0·CLAUDE 引用 12/12 成立·cacheWidth 覆盖率高。**已验证(本会话实测)**:analyze **0**·全量 `flutter test --no-pub -j1` **3583 passed/1 skip/0 fail**(墙钟 ~9min42s,首记时长基线)。纯只读审计·零碰代码。修复路线图 5 批见报告(推荐先做速修批:P0+文档订正 ~40min)。**速修批(#1)已完成(合入 main `3fb76a20`·worktree 3 commit --no-ff)**:P0 影响面升级——除 sect_event 10 篇外,新发现同因漏网 `data/narratives/` 根扁平层 14 篇(爬塔 Boss 开场/胜利 ×12 + 收徒叙事 ×2,tower_entry_flow:94,330 / disciple_join_hook:38 真消费)也未入包,共 24 篇文案玩家不可见;pubspec 补两行声明 + 新增 `test/data/pubspec_asset_declaration_test.dart`(结构守卫:data/ 含 yaml 非 _archive 目录必须逐个声明 + rootBundle 冒烟,红绿双验:摘声明 3 测全红)。GDD §12 导语补记桃花岛一二期 + 订正门派事件误列「不启动」(P3.4 已实装);CLAUDE **v1.28** 订正 §5.3 校验点符号(canEquip/canPractice 不存在→isEquippableAtRealm/TechniqueLearningService.learn)与 §8.1 关卡叙事「不抛错走 placeholder」口径;.gitignore CI 幽灵注释清除;批次 2-5+P2 待办登记 `docs/spec/full_review_2026-07-02_followup_backlog.md`。**已验证(主 checkout 实测)**:analyze **0**·全量 `flutter test --no-pub -j1` **3586 passed/1 skip/0 fail**(3583→+3 守卫测·零回归)·debug 构建产物复核 sect_event 10 + narratives 根 14 全入包。
> 🗼✅ **2026-07-02 floor30 护法结界终局战 + 视觉验收路由 已压缩归档**(git log 可溯·3530→3583 测):终局 Boss 软门槛(护法结界血墙·主Boss承伤×0.15 while 左使9000/右使8500 护法存活·on-level 100%胜/欠配 66.7%)合 `42c8b3bd`;护罩 pill/「护法结界·结界破」题字/破界 flash 表现层 + 确定性验收路由 `battle_guardian_ward` 合 `de0b6966`;破界题字抢占清「斩」字叠字修 `8545cb12`+相位题字同款 `cd099478`;Codex 真机目检 + 三环截图 PASS。

> 🗼✅ **2026-07-01 爬塔 3 观察点拍板→② 修 · ①③ 定夺 + PROGRESS 瘦身**:接爬塔复核 3 观察点用户逐项拍板。**② floor20 副掉降阶饰品修复**(towers.yaml:754 `accessory_haojiahuo_yu_pei_lao` 好家伙阶[-1 阶]→`accessory_liqi_fei_yu_pei` 利器阶·对齐一流段·同玉佩题材·dropChance 1.0 不变;补 F4 死重清理漏的 16-20 段;floor15:510 好家伙对二流阶正确·保留不动)。**① 经验深度倒挂=不调**(minor/major 两档有意设计·major 里程碑 Boss > 后续 minor·玩法零影响)。**③ 终局 Boss 100% 胜偏软=另开设计会话**(需换杠杆:机制/多目标/强控相位·设计级非改值·**deferred backlog 待拍板**)。**已验证(主 checkout 现跑)**:定向 drop_table_reference_redline + tower def/progress **42/42**·全量 `flutter test --no-pub -j1` **3530 passed/1 skip/0 fail**(基线不变·零回归)。新 id equipment.yaml:337 利器阶·lore/icon/detail 齐全·已在 stages.yaml:946 掉落 wired。零碰 numbers/saveVer/schema/结算。**PROGRESS 瘦身 161→86 行**(顶 5 支柱条保留·旧详细条压 7 行日期分组归档·sha/测数全溯)。**未 push**。

> 🌱✅ **2026-07-01 新手前 30 分钟体验打磨 S1/S2/S3/S4 合入 main `94b090ab`**：诊断新手 0-30min 路径(2 轮只读子代理现读代码)→brainstorm 定范围→spec→plan→subagent-driven 4 task TDD(每 task spec+quality 双审 + 最终整体审全 Approved)。**S1** 祖师塑形确认区补决策可逆说明(深底 `WuxiaColors.textMuted` 文案)/**S3** 普通关失败弹框补非教学化短诊断(抽公开 `StageRetryDialogBody`·浅纸底 `WuxiaUi.muted`)/**S2** 首胜掉装备后补「回行囊查看/整备」轻提示(复用 `_VictoryMutedLine`·掉装备即显·无按钮无路由守 §5.1)/**S4** 选关页 replay 提示行门控通 stage_01_05 前隐藏(新常量 `kFirstChapterFinalStageId`+照 goalGuidance 同链透传 `replayRewardUnlocked`+门控 `_StageRow` replay 行·翻转现有 `stage_list_screen_test`「Ch1 通过 01」replay 断言)。**写 plan 前现读代码证伪 2 项**：**S5**(材料行取名)**完全证伪删除**——`fromDefId` 已把磨剑石等映射具名枚举·测试 `stage_victory_dialog_test:199` 已断言「磨剑石 ×2」绿；**S4 部分证伪缩范围**——扫荡/周目本就章级门控不过早·仅 replay 提示行(单关 cleared 即显)真过早。**纯表现层/文案/显示条件·零碰 numbers/结算/saveVer/schema/三系锁死/在线=离线**·中文全进 UiStrings·两套色板不混。**已验证(合并后 main 实测)**：`analyze lib/ test/` **0**·全量 `flutter test --no-pub -j1` **3530 passed/1 skip/0 fail**(合并前 main `cd535aeb` 3526→+4 新测)。spec/plan `docs/superpowers/{specs,plans}/2026-07-01-onboarding-first-30min-polish*`。清 worktree+分支。**未 push**(ahead origin 10)。**目检已闭合(合入 main `23a85360`·已 push)**：4 屏 VISUAL_ROUTE 截图验收全 PASS——S1 祖师塑形提示(深底 muted)/S2 胜利卷宗整备行(浅纸 muted)/S3 失败弹框诊断(浅纸 muted)/S4 选关 replay 门控 `stage_list`(隐)vs`stage_list_cycle`(显)前后对比。**顺修 `_ChoiceCard` 真 bug**:Wrap 无界高度下 `Spacer` 崩 debug RenderFlex 断言(release no-op)致祖师塑形屏 debug body 全空,移除(行为中性)+清 S1 测试冗余 FlutterError 抑制(根因已除)+补 `founder_creation`/`stage_retry_dialog` 验收路由。analyze 0·全量 3530 passed/1 skip/0 fail。

> 🔧✅ **2026-07-01 codex Boss 招降/收降 hook 修复评审→合入 main `cd535aeb`**：审查 `codex/fix-boss-recruit-hook-save-key`(用户点名·§8.3 例外直进 §8.2)——修 hook 错把 `IsarSetup.currentSlotId`(默认 1)当 `SaveData.id` 读致默认槽 `get(1)`→null→提前返回·改 `_currentSaveData`=`get(0)` 固定主键(全仓 30+ 处 canonical 一致)·victory/defeat 双路径都修·两处中文 fallback title 收口 UiStrings·补默认槽 hook 真回归测(调真实 `runStageBossRecruitHookAfterVictory`·旧 `get(1)` 下必挂)。测试 seam(`Rng?`/`StageBossRecruitFlow?`/`StageBossNarrativeLoader?` 全 nullable 默认 null)窄不放宽生产·ref nullable 后 assert+守卫生产安全。**已验证(合并后 main)**：analyze 0·targeted 12/12·全量 3526 passed/1 skip/0 fail。--no-ff 合入·删分支。**未 push**。**剩余风险**：defeat hook 同 helper 修但未独立回归测·生产 `runSectRecruitFlow` 真分支未被 seam 测覆盖。

> 🗼✅ **2026-07-01 爬塔 30 层结构复核 + 诊断工具扩至全坡度(合入 main `90769a14`)**:审计 Boss 节奏/间隔/掉落/难度坡度四维,全健康、无需调值。**节奏**:6 Boss 每 5 层·minor(5/15/25)/major(10/20/30)交替·间隔恒 10。**坡度**:total baseHp 阶内单调·每 Boss >前驱普通层(no-regress 硬断言由 2 对[24→25/29→30]扩至全 6 对[4→5/9→10/14→15/19→20/24→25/29→30]常驻守 drift)·敌数 1→2→3 随境界 7 阶锁步。**掉落**:装备阶严格锁步 6 阶(寻常→像样→好家伙→利器→重器→宝物)·神物不进塔。**实测**(`tower_boss_feel_diagnostic` 扩至全 12 采样层·2 profile×20 seed·只读模拟):on-level 队 100% 胜·Boss 层 tick/血耗显著高于普通层(floor10 掉血 75.5%/floor25 掉至 67.4%)·相位在血厚 Boss(10/20/25/30)真触发·早期 minor(5/15)无相位属设计。**纯只读模拟+测加固·零碰 numbers/结算/schema**。**已验证**:`analyze lib/ test/` **0**·全量 `flutter test --no-pub -j1` **3525 passed/1 skip/0 fail**(基线不变)。**观察点(涉数值待拍板·本次未改)**:① 经验深度倒挂(floor15=floor10=2400·floor25 4000<floor20 4800)② floor20 大 Boss 副掉 -1 阶饰品 `accessory_haojiahuo_yu_pei_lao`(F4 死重清理未覆盖 16-20 段)③ 终局 Boss 100% 胜偏软(06-28 已记录复现)。顺清冗余备份分支 `codex/ui-...-blocked-9eef81ae`(battle-density 已重做合入·纯冗余)。清 worktree+branch。**未 push**。

> 🔬✅ **2026-07-01 长线平衡审计(可玩性二期 backlog)全链路诊断 + 补关卡银两占比雷达测**:3 并行只读审计 subagent + 6 测量工具本会话实测 + 逐条 grep 证伪。**三链路**:战斗伤害🟢(极值单击峰值 213015/21.3万·进十万不进百万守软红线·周目逐周目递减·三道校验齐全)·成长曲线🟢(修炼/境界曲线平滑无卡点速通·在线=离线严格)·经济🟢已校准。**防幻觉证伪**:「结晶中期断供」(实为 19+关掉+桃花岛合成)/「后期缺钱致命」(economy test 绿·+30/49 终局巨投入非常态)前提错误。**唯一待办→已校准**:40 关 item_silver「P1 占位」经补 `stage_silver_ratio_redline_test`(反推达 30%占比所需每日打本 K30∈[2,12]·学徒 onboarding 放宽 1.5)证实稳态阶良好校准——三流 K30=3.0/二流 **4.8 精确对齐 spec「关卡补 100-150」锚**/宗师 7.7·仅学徒 1.8 属 onboarding 有意压低闭关产出·**无需调值**。报告 `docs/audit/long_term_balance_audit_2026-07-01.md`。**已验证**:`analyze lib/ test/` **0**·全量 `flutter test --no-pub -j1` **3525 passed/1 skip/0 fail**(3523→+2 雷达测)。纯审计+测加固·零碰 numbers/结算/schema/存档。已 push。

> 🎯✅ **2026-07-01 读秒圆环真机目检闭合 + 破绽用色定夺=暖金(合入 main `e4e779de`)**：清读秒圆环子系统唯一真机挂账。`visual_capture.sh` 驱 `flutter run VISUAL_ROUTE=battle_charge_break` + CGWindowID 截图(不借鼠标)真机目检：**蓄力环绛红(hpLow·青衫剑客·带可破招 ⚡)/破绽环暖金(lingQiao·巷口杀手)/内伤环暗绛(statDecrease·弟子甲)一帧并显、720p 三色三义可辨**。**破绽用色定夺**(spec §3.4 待定项)：`avatar_status_tags.dart` BeatCountdownRing `hpLow→lingQiao` 暖金——绛红已是敌蓄力(危险)色,破绽是破招后进攻窗口(机会),触发它的 ⚡ 图标本就 lingQiao 金色成链。**nuance**(报告已surface)：staggerTicksRemaining 两侧可挂(玩家破招敌=机会 / 敌 defenseBreak 命中己=脆弱),暖金取「破招英雄动作主 flow」语义,己方踉跄靠 hover 释义兜底,用户可否决。顺补 `scenarioChargeBreak` 确定性 seed(弟子甲内伤 + 巷口杀手破绽)使该验收路由名副其实显三环(此前仅 seed 蓄力·无测试引用)。**纯表现层/debug 基建·零碰 numbers/结算/saveVer/schema**。**已验证(worktree+主仓实测)**：`flutter analyze lib/ test/` **0**·全量 `flutter test --no-pub -j1` **3521 passed/1 skip/0 fail**(无回归)·真机三环截图复核 PASS。worktree `stagger-ring-warmgold` 保留(含已 build app)。**未 push**(待本段后)。

> **2026-07-01 读秒圆环实装 + tap 两段点选 + 夜间 UI 视觉打磨 + 纸底文字根治 已压缩归档**(git log 可溯·3466→3530 测·顶支柱详见上方保留条):CD/内伤/破绽/敌蓄力「转圈读秒圆环」实装 push `fb05277f`(countdown_ring 三组件·四层透传 beat·目检收口见上方 `e4e779de` 条);tap 两段点选替代拖招 `3a984e4d`+真机 PASS;夜间 UI visual-gap-sweep 集成合入(60 文件纯表现层)+纸底 textPrimary→WuxiaUi.ink 根治 `e35c9712`+paper-text-audit 门禁;codex 睡觉模式 3 分支 2 合 1 退 `56f282b3`→battle-density 收口 `cfe4717a`。零碰 numbers/结算/saveVer/schema。

> **2026-06-30 night-ui 视觉验收多批 + 维护轮 已压缩归档**(git log 可溯·3466→3508 测):night-ui 4 批次全合 `6f3a39d8` / P1+仪式浮层 `cf168e55` / battle HUD+P3 `f9257906`;维护轮清 worktree + riverpod 3.3.2 试升不可解(analyzer 死锁)+ 祖师 schools 唯一性红线 `5e24d5f9`。

> **2026-06-29 装备/角色 UI 专业化 + 页面性能 + 祖师塑形 + 5/4 梯队视觉批 + 13 任务批次 已压缩归档**(git log 可溯·3331→3466 测):装备对比/角色面板/仓库专业化 3 分支合;页面切换性能优化 `1c926f04`(WuxiaImage cacheWidth·57 处迁移);新档祖师塑形 `fa428eaa`(saveVer 0.33·命盘/出身/流派);浅宣纸文字对比根治 `d6c1eeee`(PaperPanel panelFill 55%→86%);第 5 梯队 9 分支全合 + 第 4 梯队多批 + 主菜单状态摘要 + 下一阶段 13 任务(12 合 1 缓)。

> **2026-06-27/28 弟子终局解锁 + 桃花岛二期 + codex 批量集成 + 战前情报 opt-in 已压缩归档**(git log 可溯·3207→3297 测):弟子加入移终局 06_05;桃花岛二期 + 藏卷阁 Hub PR #17 `7335927e`;睡觉模式 16 任务并行集成(15 合 11 缓)+ codex 挂机 7 分支全合 `d9659815`;战前情报 opt-in 重做 `06e30c22`(复用 ⓘ·去强制弹窗守即拖即放)。

> **2026-06-22..26 装备出售/分解 + 第八阶段 + 桃花岛一期 + 全系统审计 A-E + 材料经济 P4 已压缩归档**(git log/spec 可溯·2815→3172 测):装备出售分解 + 仓库格子化(推翻 §2.1 收藏品红线·CLAUDE v1.23);问鼎九霄 6 Boss 剧情;第八阶段角色 Lv + 推荐境界(saveVer 0.31);桃花岛一期养成支柱(saveVer 0.30);全系统审计 A-E + 掉落 F1-F8 + 招式倍率全局 ≤8000 单线(CLAUDE v1.21);P4 材料经济(银两货币 + 经验丹 3 档 + 秘籍 9 本 + items.yaml)。

> **2026-06-11..20 长线打磨波 A/B + 半手动战斗重做 + 红线两层收口 + 续10-44 + 第五~七阶段 已压缩归档**(git log/spec/closeout 可溯·1888→2815 测):波 A/B 机制深度 + 24 招内容 + 机制 Boss×6;半手动战斗 + seed 重放(废录制回放净 -2050 行·saveVer 0.19);周目进化(Boss HP 50000→60000);红线语义收口分两层(硬=配置表值 schema 拦截 / 软=极值实战不进百万);续19-44 上下文帮助 / 打击感 / 三人协同 / Boss 多阶段 / 材料经济长期档案。

> **2026-06-01..10 可玩性 P1a/P1b 养成内核 + UI kit v1 + P0 战斗可见化 已压缩归档**(git log/closeout 可溯·1661→1883 测):P1a per-skill 熟练度 1.00→1.30 + P1b 藏经阁技能装配(saveVer 0.17);UI kit v1 9 组件 + WuxiaUi token + MJ 图接入;P0 战斗单位可见化(立绘 + 弹道 + 受击闪 + 胜负 vignette)+ 仓库格子化 + 装备/敌人图归位 + VISUAL_ROUTE 验收基建。

---

## 已知偏差 / 挂账事项

- **[开放·低severity·debug-only] Riverpod 3.x `pausedActiveSubscriptionCount` 断言**(2026-06-29 真机 `flutter run` 退出/导航时偶发):根因=`towerProgressProvider`(autoDispose `Future`·第4梯队 tower_progress_summary)被外部 Consumer(`main_menu.dart:151`/leaderboard)+ 依赖 `towerFloorListProvider`(`ref.watch(...future)`)同时 watch,TickerMode 切换 resume 时 flush→依赖自 invalidate→resume 中又 pause→计数错位(element.dart:1086 assert)。**整 stack 零用户帧=Riverpod 框架 bug,用户用法标准**;assert release 剥离·应用未崩·零数据损坏·3456 全量测试不触发。**处置=记录+延后**:不升版不改 provider(flutter_riverpod 当前 3.3.1·latest 3.3.2 但当前约束不可解·且无法确认恰修此条)。下次依赖维护轮试 3.3.2+ 真机验断言是否消失。**2026-06-30 维护轮已试=仍不可解**(analyzer 死锁:isar_community_generator 封 analyzer<11 vs riverpod codegen/lint 需 analyzer^12,互斥;再开条件=isar 支持 analyzer≥12)。详 memory `reference_riverpod_tickermode_pause_assert`。
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
