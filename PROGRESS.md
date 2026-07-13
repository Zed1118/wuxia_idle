# 挂机武侠 · 开发进度
> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。
>
> **当前阶段：1.0 长线打磨期（质量优先 · 不设上线时间压力）** — Demo ✅(2026-05) → 1.0 内容周期 ✅(P1-P5+) → 打磨中。阶段一变只改本行；工作原则见 CLAUDE.md §7。

## 当前阶段

> **2026-07-14 审查问题修复批(`fix/audit-batch-20260714`·Claude)**:按 07-14 全量审查逐项收口——① Windows Release workflow pin `windows-2022`(VS2026 STL1011 止血,audioplayers 升级项进 backlog §八,分支上 workflow_dispatch 实证运行);② settlement 共鸣事件 `??0` 幽灵兜底改「无可归属角色跳过记录、notice 保留」(TDD 红→绿,settlement 测 5/5);③ pubspec analyzer 依赖注释(版本敏感轴);④ CLAUDE v1.37(§4 skills.yaml camelCase 历史例外注记+§8.2 Gate 补 ⓓ commit 中文);⑤ 本文件瘦身归档回 ≤100 行;⑥ backlog 新增 §十三(07-14 玩法评估 5 项:心法获取/战斗爽感二期/Windows 实机验收/出战编成拍板/真人试玩,含 playtest P2 候选并入)。门禁见分支 CI 与批内记录。**下一任务(用户拍板)**:§十三 #1 心法获取玩法,先 spec 拍板再实装。

> **2026-07-14 Claude 全量审查(Codex 07-10~07-13 批次质量·纯只读·详报 `~/Desktop/挂机武侠全量审查报告_2026-07-14.md`)**:**已验证(本会话实测)**:analyze 0;format 1121/0 changed;全量 **3933 pass / 0 fail**(4m37s);main=origin/main@`30fc862d` 树干净、worktree/分支零残留;CI 主链全绿(含 coverage ratchet + macOS build job)。九批深审(闭关幂等/qi 迁移防御/六批 gate/速修边界/四属性配置化/二周目门控/490 级派生/结算事务边界/playtest 证据学)全部通过,PROGRESS 自报数字与实测一致。**发现 P1×1**:Windows Release Evidence 首次定时运行失败(run 29227340821·`audioplayers_windows` 6.7.1 在 windows-latest=VS2026/MSVC14.51 下 STL1011 硬错·每周一 cron 将持续失败·本页 07-12 条旧口径已过时);P2×2:本文件超 100 行、playtest P2 候选未挂 backlog;P3×4 见详报。修复批见上条。

> **2026-07-13 Codex 成长路径与四属性体检收口(`codex/progression-attribute-playtest-implementation`)**：**已完成**：建立 49 层/Lv1～Lv490、7 类经验入口、心魔留账/终境封顶与四属性职责的硬契约，完成主线 30 关×3 配置×20 seed=1800 场固定种子体检及审查报告；P0/P1 均无，本批零生产代码修改。**已验证**：format 1118/0 changed；analyze 0；定向 JSON reporter **43 success / 0 fail**；全量 JSON reporter 非隐藏测试 **3933 success / 0 fail**（另有 1144 hidden testDone records：597 loading + 547 setUpAll/tearDownAll，未计入 pass）；macOS debug build 成功；前期/心魔溢出/战后反馈/Lv490 四画面 @1280×720、1440×900 共 8 张真窗口截图通过。**已知风险**：readable-first-clear 三档样本均 100% 胜、`stage_02_05` 相邻关节拍/Qi 存在断崖候选，当前只是 P2；固定 seed/profile 不等于玩家分布。**下批建议**：先补真实首通存档/战报分布与 02_04～03_01 连续体感证据，再判断是扩充低投入 profile 还是调整数值；暂不动 `numbers.yaml`、schema、save version。

> **2026-07-13 Codex 成长与结算单一真相源收敛(`codex/progression-settlement-convergence`)**：门派声望面板正式显示 `factions.yaml` 中文名称，并保留既有阵营映射兼容；角色升境、面板、心魔、主菜单和商店统一从 `RealmDef` 读取经验阈值，`Character.experienceToNextLayer` 仅保留为 Isar 兼容镜像；主线与通天塔复用公共经验/突破/共鸣/Boss 事件结算，仍分别保留“主线重打给经验、通天塔仅首通给经验”及各自掉落策略。公共服务不开事务，调用方继续保证持久化原子性；同名角色按 `characterId` 关联。**无 schema/saveVersion/数值调整**。**实跑门禁**：format 1109/0 changed；analyze 0；本批定向 **151 pass / 0 fail**；全量 JSON reporter 非隐藏测试 **3897 success / 0 fail**；macOS debug build 成功（仅第三方 Swift 与 Xcode 脚本告警）。

> **2026-07-13 Codex 境界派生 Lv1～Lv490 实装(`codex/realm-derived-490-level`)**：独立 Lv 经验账已退役，`Character.experience` 成为唯一角色经验账；49 个真实境界层各派生 10 个纯展示段。主线、爬塔、闭关、普通离线、经验丹统一走 `CharacterAdvancementService`；战后经验/等级/突破合并为一个反馈区。删除 `LevelService`、`LevelConfig`、`numbers.yaml level` 及旧等级血量/内力/速度加成；旧 `Character.level/levelExp` 仅保留 Isar schema 兼容、生产零读写。角色档案统一显示真实经验、心魔溢出和 Lv490 修为巅峰；终境 1,250,000 只作显示刻度，不产生第 50 层。**实跑门禁**：build_runner 增量 66 outputs；format 1103/0 changed；analyze 0；跨模块专项 **593 pass / 0 fail**；全量 **3878 pass / 0 fail**；macOS debug build 成功；角色面板 31 条测试含 Lv490 @1280×720/1440×900，无异常。

> **2026-07-13 Codex 外部审查复核与分支收敛(`main`)**：已修复提前出关异常/并发重入、`qiDelta` 加载期红线；退役心魔余毒两个无消费倍率及误导注释；主菜单闭关横幅复用唯一时长切分函数；订正 07-12 测试数、心魔观察值属性与推送状态。已审核并合入角色四属性职责统一、二周目快速开局和「境界派生 490 级」设计规格；已清理 5 个已合并 worktree 及 6 个已合并本地分支。**合并态实跑门禁**：`flutter analyze --no-pub` 0 issue；跨分支专项 183 绿；`flutter test --no-pub` **3877 pass / 0 fail**。
> 🎯✅ **2026-07-11 Codex 二周目快速开局(`codex/mainline-player-loop`)**:先核查原推荐的主线列表/扫荡预估/重打收益/战后装备处理,确认均已于 06-29 既有批次实装,避免重复开工;改做 GDD §10.4 唯一明确未落的玩家功能。任一现存档完成首周目 `stage_06_05` 后,空槽显示「已解锁老江湖开局」,祖师创建页可在「循序入门/老江湖开局」间选择;快速模式复用 `SaveData.isOnboardingCompleted`,只解除心法/闭关前期门槛,主线、首通奖励、塑形、初始资源均从头开始,无 schema/saveVer。兼容旧档 `clearedStageIds`,正常通关 01_05 同步闭环完成态。同步订正 GDD、playability backlog 与 rejected registry 中 19 项已完成却仍可派发的 drift。**TDD**:新增 6 条契约测,定向 43 绿;**分支门禁**:`flutter analyze lib test` 0 issue;全量 **3800/3800**、0 fail(373.8s);`flutter build macos --debug` 成功。macOS 原生 `founder_creation` @1280×720/1440×900 无 overflow/exception/遮挡。

> **2026-07-13 Codex 角色四项属性职责统一(`codex/character-attribute-roles`)**：**已完成**：根骨缩短新生成重伤时长；悟性统一影响心法修炼、招式熟练度与武学领悟；身法移除暴击贡献并将基础暴击平移至 7.5%；机缘负责普通奇遇概率与 4 个显式门槛选项；角色面板新增实战装备攻击/基础防御并采用响应式 3+4 布局。旧角色属性值、schema、saveVersion 均未迁移。**已验证**：analyze 0；targeted 427 绿；红线/平衡/迁移守门 17 绿；全量与 coverage 全量均 3867/3867；覆盖率 81.62% ≥ 81.25%；macOS debug 实窗角色面板无裁切/overflow。**已知风险**：机缘选项真运行触发依赖随机与存档进度，交互已由 parser/widget/事件引用测试覆盖；Windows 真机表现仍待既有发布验收流程。**下批建议**：评审合并后推送观察 CI，再做一轮属性数值体感试玩，不宜继续扩大属性职责。

> **2026-07-12 最终优化方案首轮六批合并 Gate(`main` @ `4808fffd`)**：**已完成**：首通体验渐进门禁、Splash 生命周期测试、宗门配置读面收窄、存档槽 feature 维护编排、战斗结算胜负单一真相源、战斗播放资源封装、覆盖率 ratchet（81.25%）及手动/每周 Windows release workflow 已逐分支审核后无冲突合入；审核阶段修正 6 份设计文档的 `diff --check` 卫生并重新冻结。**已验证**：build_runner 114 outputs；format 1098/0 changed；analyze 0；合并态 targeted 198 绿；并发全量 `success:true`（345073ms）；macOS `battle_charge_break` @1280×720/1440×900 实窗均无 overflow、空层或遮挡。**2026-07-13 状态复核**：`main` 已到 `b44a8942` 且与 `origin/main` 同步，Ubuntu/macOS CI 已成功；Windows workflow 仍无实际运行记录。**已知风险**：MSIX/签名/升级安装、Windows 音频/8h 长稳性能和 closed beta 仍需外部环境；静态视觉路由不等于完整动态手感/帧率验收。

> **2026-07-12 Codex 内力/真气循环实装(`codex/inner-force-qi-cycle`)**:永久内力改为闭关成长且战斗不消耗、实际值决定伤害；战斗资源拆为有界真气气海，招式显式产耗气，心法提供开场/气海/产气/减耗差异，连续战斗保留并有限恢复。散功、Boss/心魔失败不再扣永久内力，统一改为可由有效战斗和闭关/离线调息恢复的「内息紊乱」；0.35→0.36 旧档保护性补满内力并迁移旧余毒。**固定种子诊断快照（非长期断言；引用必须附 commit，战斗改动后需重跑）**：`main@dd303f70` 实测普通敌人/主线Boss/塔Boss 开场真气20/40/60；心魔05/06高爆发17/20、心魔07高爆发13/20、floor30满配30/30低配0/30、单人闭关整备主线Ch1-6全通。**2026-07-13 独立复核门禁**:`dart format --output=none --set-exit-if-changed .` 1099 文件无改、`flutter analyze --no-pub` 0 issue、全仓 **3849 pass / 0 fail**。

> **2026-07-12 Codex 开放式闭关实装(`codex/open-ended-retreat-settlement`)**:取消1/4/12h预选,改为玩家主动收功;前72h地图完整收益+溢出无上限普通挂机在同一事务中结算,幂等防重。每12h一次稳定装备判定(最多6次、无保底),后段高阶权重提升,越境界装备仍受三系锁。存档升至0.35并迁移 active 会话境界快照;设置/进行中/返场/主菜单/结果页已统一两段口径。**最终门禁**:`dart format` 1081/0 changed;`flutter analyze --no-pub` 0 issue;闭关/迁移/主菜单专项全绿;全仓 **3807/3807**;macOS debug build 成功;79h 进行中 + 90h 结算在 1280×720/1440×900 实窗截图通过。**仅剩**:推送后远端 CI 复验。

> **2026-07-11 Codex 项目健康治理(`codex/project-health-hardening`)**:按 07-10 全量审查建议完成 7 批收口。① `lib/test/docs` 115 个历史格式文件统一,CI 加 formatter 门禁;② 新增扫荡结算/单位 4 测,CI 全量测试产 `lcov.info` artifact;③ 新增独立 macOS debug build job;④ README/CLAUDE/历史计划与 `.git` 体积误诊订正(`docs/handoff` tracked 仅 2.76MiB,本地 ignored 2.7G 不擅删);⑤ 存档恢复抽 `SaveRestoreDatabaseOps`,掉落引用校验移出 GameRepository,招募属性去 `dynamic`;⑥ 六个 BattleScreen 播放 bool 收进 `BattleScreenPlaybackConfig`,25 个测试/诊断调用迁 `defaultGroundStrategy` 后删除旧 `battle_engine.dart`;⑦ 锁文件兼容升级 21 项并删未使用 `intl`。**最终门禁**:build_runner 114 outputs;format 1080/0 changed;analyze 0;coverage 全量 **3794/3794**(约10m16s),已记录行覆盖 **80.84%**;macOS debug build 成功;diff/status 边界通过。**剩余非阻塞**:`stage_entry_flow` 21.51% 且仍混合多 hook;GameRepository/IsarSetup 全局单例继续分批降耦;`js 0.7.2` 为 `isar_community 3.3.2` 上游传递依赖;远端 CI 待分支推送后运行。

> **2026-07-10 Codex CI 运行时维护(`codex/ci-runtime-refresh`)**:GitHub Actions `checkout@v4` 在 PR #23-25 持续产生 Node 20 弃用注记;核对官方 action.yml 后升级到最新 `actions/checkout@v7`(Node 24),并清除 CI 中 build_runner 已移除/忽略的 `--delete-conflicting-outputs` 参数。PR #26 首轮 CI 全链路绿且 annotations 为空,弃用注记已消失。

> **2026-07-10 Codex 质量批(`codex/save-restore-design`)**:完成安全存档恢复闭环(候选校验、恢复前安全备份、原子替换、失败回滚、启动中断自愈与设置页交互);测试基础设施收口至直接 Isar Core 初始化 95→0、production repository 样板累计迁移 247 文件;标题栏返回/主页统一 44px 语义按钮;六类关键图片 fallback 契约落地;招式池 206+40=246 由 YAML/GDD/repository 三层机器守卫。**本地门禁**:`flutter analyze lib/ test/` 0 问题;`flutter test --no-pub` 3790/3790;`flutter build macos --debug` 成功;`git diff --check` 通过。macOS 真窗口 `main_menu`/`chapter_list`/`equipment_detail_screen` @1280x720、1440x900 共 6 张截图均 READY、无 overflow/exception。**PR #33 首轮 CI**:test job 通过,annotations 0,mergeable/CLEAN。
> **2026-07-10 Codex 资产 WebP 试点 + 桃花岛落地**:magic audit 订正旧 210MB 口径:383 个 `.png` 路径 58.0MB,其中 272 个/44.7MB 已是 WebP 内容;真 PNG 仅 111 个/13.3MB。8 样本三档转码 + 四联目检证实只有桃花岛 q82 显著受益,alpha 装备有损边缘破坏、全 lossless 仅省 0.85MB,故关闭全量转码任务。后续获人工确认后桃花岛已改显式 `.webp`(832KB→202KB,-75.8%)并补 bundle 解码/尺寸守卫;同步销账已完成的 battle_screen 3102 行旧任务。
> **2026-07-10 Codex 审查债务收口批(`codex/review-debt-cleanup` + 测试基础设施批)**:确认 CI 与 66 篇文案归档已完成;删除不可达 `home_feed` 并迁移事件流/启动钩子;删除隐藏逐关 `stage_auto_play`;新增并全面采用测试数据/Isar helper。GameRepository 生产数据样板累计迁 247 个测试文件(helper/自测另 2),本批直接 `loadAllDefs` 文件 230→25,余下均为自定义/fresh/fault loader;Isar 直接 Core 初始化累计 95→0。**验证**:各迁移分批定向回归全绿,`flutter analyze test` 0 问题;批末全量门禁见本分支后续记录。
> **2026-07-10 Codex 挂机批 A-O 已归档**:文档 drift/UI 规范、fallback 诊断、存档备份核验、在线生命周期、战场重绘隔离、core 分层、数据校验、测试占位/TODO 清理与 README 命令订正均已完成;逐项文件、测试数和提交见当日 git log(`ef9eaf65`..`528c0d40`)及 PR #23 前历史。
> **2026-07-10 Codex macOS 生命周期 + 新手前 30 分钟复验**:新手/主线/在线生命周期/离线 gate 定向 27 绿;macOS 原生窗口冷启动验 `founder_creation`/`main_menu`/首通真战斗/被动离线回顾 4 路由 @1440x900,均 READY + window-id 截图,无异常/overflow;Finder 失焦 3 秒再聚焦后进程存活且无生命周期写档错误。详 `docs/audit/runtime_onboarding_acceptance_2026-07-10.md`。
> 🩺✅ **2026-07-10 Codex 全量审查 + 质量补强(`main`)**:按用户要求先做全量审查再推进下一阶段。审查结论:当前刷新链路无阻断问题;`main` 已含 18 个本地 commit、无 tracked 脏改,仅 `Builds/`/`审查报告/`/`设计文档/` 为未跟踪目录。复核体检批资源刷新链路:战斗/扫荡统一走 `invalidateAfterCombatSettlement`,商店/道具/装备/桃花岛各自有成功后 invalidate helper,调用点与测试覆盖对齐。**验证**:`flutter analyze` 0 issue;`flutter test --no-pub -j1 --reporter expanded` **3789 pass / 1 skip / 0 fail**;`flutter build macos --debug` 成功;`git diff --check` 通过。**下一阶段已启动**:补审查报告高优先级测试缺口,新增 `monthly_tick_test` 锁注册/顺序/异常不阻塞日志,新增 `rng_test` 锁 DefaultRng 确定性/边界/pick/provider override。targeted `flutter test --no-pub test/core/game_loop/monthly_tick_test.dart test/shared/utils/rng_test.dart` **7 绿**。**后续销账(2026-07-10)**:招式计数误报已证伪并加 206+40=246 机器守卫;标题栏动作已统一;六类关键图片 fallback 已审计并补强。
> **2026-07-05..08 十六批已压缩归档**(git log + docs/sessions/docs/audit 可溯·3682→3753 测):07-07 全面体检(6 并行代理·P0×5 全数修复:离线结算闭环 OnlinePresenceController/invalidate 速修 helper/群战烘焙/拖招插队/门控解锁)· 通宵字体审查(色板混用清零+醒目金压暗)· codex 六任务批(仓库筛选分组/开局三件套/水墨弹道)· 技能目标快捷选择栏 · UX对比度+技能成长门控 · 夜批视觉收口(29 屏实拍)· Tier1/Tier2 配色结构根治(DarkParchment/LightPaper 重命名+PanelSurface 自带文字色)· 夜间挂机批 A-M(docs+4 候选分支全合)· BattleScreen C BattlePlaybackController 抽离(1433→836 行)· 07-08 三批遗留修复+风险收口续+桃花岛首屏一屏地图。详各日 handoff/closeout 与 git log。
> **2026-07-03/04 终局机制型 Boss 批次2/3/4 已压缩归档**:批次2 爬塔应用(floor25/30 vulnerability+ward·`934df290` PR#20) · 批次3 心魔机制型(05/06/07 镜像脆弱窗口 0.12/0.10/0.08+07 限时生存·`ead9c395` PR#22·CLAUDE v1.31) · 批次4 周目脆弱窗口收窄(`0bd1ed2d` PR#21)。详各 PR squash commit。
> **2026-07-03 五批已压缩归档**:CI 搭建(`.github/workflows/ci.yml`·PR #18 `5a1e13b1`·ubuntu 纯Dart测+isar core download) · E1 战斗节奏真机校值(popup speed clamp) · 祖师/门派命名(subagent TDD 7 task·saveVer 0.32) · 根目录退役 md 归档 ×12(根 20→8) · 批次2/3清理(59 零引用资产 8MB+死分支)。详 git log 2026-07-03 各 commit。
> 🗜️✅ **2026-07-02 `.git` filter-repo 瘦身合入 main `5bd36fc1`(重写全历史+force push)**:批次 2 剩余项①落地。`.git` **2.5G→658M(减 74%)**,分两杠杆:**① 安全 gc**(`reflog expire --expire=now --all`+`gc --prune=now`·**零重写/零 force push/零风险**)清不可达对象 2.5G→1.1G;**② filter-repo** 剥 `docs/**/*.png|jpg`(500.5M 纯验收废图·853 个 `.md` 记录全保留)+ 删 **121 个 `refs/codex/*`** turn-diff 检查点垃圾 refs(filter-repo 无法重写裸树 refs·把 364 个 docs 图片 blob 钉活是没瘦下去主因)+ gc,1.1G→658M。**双拍板(用户)**:剥 docs 图片+force push(不做额外旧 PNG 资产剥离)/本地 37 张废图直接丢弃。HEAD **caba2422→5bd36fc1**(全 2564 commit 新 hash·3 个纯图片 commit 过滤后变空被 filter-repo 默认剪)。补 `.gitignore` 挡 `docs/reviews/`+`docs/art_ref/` 图片防回流(`docs/handoff/` 早有规则)。**已验证(本会话现跑)**:历史 docs 图片 blob 残留 **0**·692 个 docs `.md` 全保留·工作树干净·**远端 `ls-remote` 核实 main+13 tag 全 = 5bd36fc1**(非 push 回显)。纯 git 维护·零碰 lib/test/data/numbers/结算/schema(analyze/test 不受影响未重跑)。`.git` 全备份留 job tmp 兜底。**GitHub 远端体积**:force push 已顶掉旧历史 ref,旧对象变不可达,GitHub 服务端 gc 择期回收(非即时)。批次 2 剩余(零引用 tier_*/audio candidates)仍待拍板。
> 🎨✅ **2026-07-02 资产瘦身批(六维审查批次 2·webp 转码)合入 main `2fe743ea`**:分发包 210MB PNG 有损转 webp 瘦身。**双拍板(用户)**:① q80 画质档(Claude 目检 4 类样张——背景大图/特效alpha层/立绘/图标——q80 肉眼无压缩痕迹,水墨厚涂对有损极友好)② **方案A**:文件名保留 `.png`、内容换 webp,Flutter `AssetImage` 按内容 magic bytes 嗅探解码(非扩展名),故 lib/data 共 **475 处 `.png` 引用 + pubspec 目录声明零改动**,规避改扩展名的大面积漏改(漏改即运行期资产静默缺失,正是刚修的 P0 类风险)。**门槛策略**:只转有≥10%收益的 **324 张**(省 145.2M),**110 张小图标保持真 PNG**(转 webp 反变大)。**assets PNG 210.2M→64.7M(省 69%)**;按目录 ui 88%/techniques 73%/scenes 72%/enemies 60%/characters 57%/maps 54%/equipment 19%。新增 `test/data/webp_in_png_decode_test.dart` 解码守卫(端到端证 rootBundle 读 webp bytes→skia 解出正确尺寸 896×1344)+ `assets/README.md` 约定 + `tool/convert_assets_webp.py` 幂等复用脚本(Pillow q80 method6)。**已验证(worktree 全量 + 主 checkout 定向)**:analyze lib/ test/ **0**·全量 `flutter test --no-pub -j1` **3587 passed/1 skip/0 fail**(基线 3586→+1 新测·零回归)·主 checkout 合并后解码+pubspec 守卫 4 测复验绿·抽样 file 确认转的=webp/保持的=png。**未 push**(待用户)。批次 2 剩余项(44.9M 零引用清理/docs/reviews gitignore/audio `_suno_candidates`/handoff capture)未动,仍 backlog。
> 🔍✅ **2026-07-02 全项目六维全面审查(报告 `docs/audit/full_project_review_2026-07-02.md`)**:6 并行只读审计代理(架构/红线/测试/数据/性能/文档)+主会话交叉证伪。**总评:核心质量优,短板在工程外围**。**P0×1**:pubspec 漏声明 `data/lore/sect_event/`→10 篇门派事件文案运行期不可达(构建产物双重复核,修复=一行 pubspec+守卫测)。**P1×12**:无 CI/分发包 210MB PNG 未压缩(webp 可 -70%)/44.9MB 零引用资产入包/git 2.4G(docs/reviews 26 张大图漏 ignore)/core 分层违规 1 处(system_clock_provider)/battle_screen 3102 行/battle_engine 等 3 死文件仅测试续命/玩家可见中文散写 ~11 处/66 篇文案无加载管线(narratives/techniques 26+insights 40)/numbers.yaml tower+synergies.effect_values 两段 0 消费/243 测试文件 setUpAll 样板重复/GDD 全文 0 提及桃花岛(反向 drift)。健康面:反主流 0 命中·三系锁死闭环·倍率 max=8000 合规·id 联结双向差集 0·CLAUDE 引用 12/12 成立·cacheWidth 覆盖率高。**已验证(本会话实测)**:analyze **0**·全量 `flutter test --no-pub -j1` **3583 passed/1 skip/0 fail**(墙钟 ~9min42s,首记时长基线)。纯只读审计·零碰代码。修复路线图 5 批见报告(推荐先做速修批:P0+文档订正 ~40min)。**速修批(#1)已完成(合入 main `3fb76a20`·worktree 3 commit --no-ff)**:P0 影响面升级——除 sect_event 10 篇外,新发现同因漏网 `data/narratives/` 根扁平层 14 篇(爬塔 Boss 开场/胜利 ×12 + 收徒叙事 ×2,tower_entry_flow:94,330 / disciple_join_hook:38 真消费)也未入包,共 24 篇文案玩家不可见;pubspec 补两行声明 + 新增 `test/data/pubspec_asset_declaration_test.dart`(结构守卫:data/ 含 yaml 非 _archive 目录必须逐个声明 + rootBundle 冒烟,红绿双验:摘声明 3 测全红)。GDD §12 导语补记桃花岛一二期 + 订正门派事件误列「不启动」(P3.4 已实装);CLAUDE **v1.28** 订正 §5.3 校验点符号(canEquip/canPractice 不存在→isEquippableAtRealm/TechniqueLearningService.learn)与 §8.1 关卡叙事「不抛错走 placeholder」口径;.gitignore CI 幽灵注释清除;批次 2-5+P2 待办登记 `docs/spec/full_review_2026-07-02_followup_backlog.md`。**已验证(主 checkout 实测)**:analyze **0**·全量 `flutter test --no-pub -j1` **3586 passed/1 skip/0 fail**(3583→+3 守卫测·零回归)·debug 构建产物复核 sect_event 10 + narratives 根 14 全入包。
> 🗼✅ **2026-07-02 floor30 护法结界终局战 + 视觉验收路由 已压缩归档**(git log 可溯·3530→3583 测):终局 Boss 软门槛(护法结界血墙·主Boss承伤×0.15 while 左使9000/右使8500 护法存活·on-level 100%胜/欠配 66.7%)合 `42c8b3bd`;护罩 pill/「护法结界·结界破」题字/破界 flash 表现层 + 确定性验收路由 `battle_guardian_ward` 合 `de0b6966`;破界题字抢占清「斩」字叠字修 `8545cb12`+相位题字同款 `cd099478`;Codex 真机目检 + 三环截图 PASS。
> **2026-07-01 四批已压缩归档(观察点拍板②修+PROGRESS瘦身 / 新手前30min S1-S4 / codex招降hook修 / 读秒圆环目检+破绽暖金定夺)**(git log 可溯·合入 sha:观察点批见 git log·S1-S4 `94b090ab`+目检 `23a85360`·hook `cd535aeb`·塔复核 `90769a14`·圆环目检 `e4e779de`·3521→3530 测):观察点=②floor20副掉升利器阶/①经验倒挂不调/③终局Boss偏软→已由 07-03 起机制型 Boss 五批收口;S1-S4=祖师塑形可逆说明/失败弹框诊断/首胜整备提示/replay 门控+顺修 `_ChoiceCard` Spacer debug 崩;hook 修=get(1)→get(0) canonical(defeat hook 无独立回归测风险仍开放);圆环=三环三色真机 PASS+破绽暖金(`avatar_status_tags.dart` hpLow→lingQiao)+`scenarioChargeBreak` 确定性 seed。全部零碰 numbers/结算/saveVer/schema。
> **2026-07-01 读秒圆环实装 + tap 两段点选 + 夜间 UI 视觉打磨 + 纸底文字根治 已压缩归档**(git log 可溯·3466→3530 测·顶支柱详见上方保留条):CD/内伤/破绽/敌蓄力「转圈读秒圆环」实装 push `fb05277f`(countdown_ring 三组件·四层透传 beat·目检收口见上方 `e4e779de` 条);tap 两段点选替代拖招 `3a984e4d`+真机 PASS;夜间 UI visual-gap-sweep 集成合入(60 文件纯表现层)+纸底 textPrimary→WuxiaUi.ink 根治 `e35c9712`+paper-text-audit 门禁;codex 睡觉模式 3 分支 2 合 1 退 `56f282b3`→battle-density 收口 `cfe4717a`。零碰 numbers/结算/saveVer/schema。
> **2026-06-29 装备/角色 UI 专业化 + 页面性能 + 祖师塑形 + 5/4 梯队视觉批 + 13 任务批次 已压缩归档**(git log 可溯·3331→3466 测):装备对比/角色面板/仓库专业化 3 分支合;页面切换性能优化 `1c926f04`(WuxiaImage cacheWidth·57 处迁移);新档祖师塑形 `fa428eaa`(saveVer 0.33·命盘/出身/流派);浅宣纸文字对比根治 `d6c1eeee`(PaperPanel panelFill 55%→86%);第 5 梯队 9 分支全合 + 第 4 梯队多批 + 主菜单状态摘要 + 下一阶段 13 任务(12 合 1 缓)。
> **2026-06-01..28 可玩性内核 + UI kit + P0 战斗可见化 + 装备出售/分解 + 桃花岛一二期 + 全系统审计 A-E + 材料经济 P4 + 弟子终局解锁 + 战前情报 opt-in 已压缩归档**(git log/spec/closeout 可溯·1661→3297 测,历史四条明细见更早 commit 中 PROGRESS.md)。
---

## 已知偏差 / 挂账事项

- **[开放·低severity·debug-only] Riverpod 3.x `pausedActiveSubscriptionCount` 断言**(2026-06-29 真机 `flutter run` 退出/导航时偶发):根因=`towerProgressProvider`(autoDispose `Future`·第4梯队 tower_progress_summary)被外部 Consumer(`main_menu.dart:151`/leaderboard)+ 依赖 `towerFloorListProvider`(`ref.watch(...future)`)同时 watch,TickerMode 切换 resume 时 flush→依赖自 invalidate→resume 中又 pause→计数错位(element.dart:1086 assert)。**整 stack 零用户帧=Riverpod 框架 bug,用户用法标准**;assert release 剥离·应用未崩·零数据损坏·3456 全量测试不触发。**处置=记录+延后**:不升版不改 provider(flutter_riverpod 当前 3.3.1·latest 3.3.2 但当前约束不可解·且无法确认恰修此条)。下次依赖维护轮试 3.3.2+ 真机验断言是否消失。**2026-06-30 维护轮已试=仍不可解**(analyzer 死锁:isar_community_generator 封 analyzer<11 vs riverpod codegen/lint 需 analyzer^12,互斥;再开条件=isar 支持 analyzer≥12)。详 memory `reference_riverpod_tickermode_pause_assert`。
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
- **2026-05-25..28 v2.1 工具 + P1.2 江湖恩怨 + P3 三项 + P2.1 内容批 + drop 全覆盖**(1458→1519 测 · git log + `session_closeout_2026-05-{25,28}_*` / `p1_2_jianghu_full.md` / `codex_dispatch_r4_*` 可溯)
