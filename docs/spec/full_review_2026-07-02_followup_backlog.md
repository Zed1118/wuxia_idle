# 全面审查后续批次 backlog(2026-07-02)

> 源:`docs/audit/full_project_review_2026-07-02.md`(六维审查,P0×1+P1×12+P2×10)。
> 速修批(#1)已完成:P0 pubspec 资产声明 ×2 + 守卫测 / GDD 桃花岛+门派事件订正 / CLAUDE §5.3·§8.1 订正(v1.28)/ .gitignore 幽灵注释。
> 本文件只承载**待拍板/待排期**项(守打磨期 backlog 原则);做完一批划掉一批。

## 批次 2 · 资产瘦身(拍板点:webp 转码质量抽验)

- [x] ~~210MB PNG → webp/jpeg 全量转码~~ **❌口径证伪,不执行全量替换(2026-07-10)**:试点时 383 个 `.png` 路径仅 58.0MB,其中 **272 个/44.7MB 实际 magic 已是 WebP**,仅扩展名沿用 `.png`;真 PNG 仅 111 个/13.3MB(110 个 alpha 装备图 + 桃花岛)。透明装备有损 WebP 出现明显边缘色块,lossless 全 110 张也只省 0.85MB。结论:关闭全量替换;唯一显著受益的桃花岛已获人工确认并以 q82 落地(832KB→202KB,-75.8%),当前剩 382 个 `.png` 路径/110 个真 PNG。详 `docs/audit/asset_webp_pilot_2026-07-10.md`。
- [x] 零引用资产清理 **✅已删(2026-07-03·batch-123)**——**订正**:backlog 原记「44.9MB/67 文件」是 drift(webp 转码 + tier_* 已删后体积变小)。本波独立 grep 现算实为 **59 文件 8.0MB**:`ui/mj/*_01` 旧稿 **17 张**(fx_×10 + overlay_×4 + ui_frame_×2 + ceremony_red_seal_01·全 0 引用,已被 `*_blend` 版替代;entry_/menu_/其余 ceremony 的 *_01 均 1 引用=活,未动)+ `enemies/*.png` **42 张**(129 中 42 张 0 引用,移除史抽验 guard_c/shidi_a 均 commit `e73979ce`(06-28)删敌人定义时连带删 iconPath=废弃品)。iconPath 为静态全路径字面量(`assets/enemies/x.png`)无动态拼接,grep 验证可靠。~~`tier_*.png` 7 张~~ 早于 2026-07-02 删。
- [x] `docs/reviews/` **✅已治理(上批 .git 瘦身)**——本波复核:仅 4KB tracked,.gitignore 已含 `docs/reviews/`(挡 PNG)。2.4G→658M 历史已 filter-repo 洗过(见 PROGRESS `5bd36fc1`),无需再洗。
- [x] `assets/audio/_suno_candidates/` 75MB **✅已归档(2026-07-02·用户拍板)**:mv 出项目 → `~/Desktop/wuxia_suno_candidates_archive_2026-07-02`(已 gitignore·不进仓/不进包·可恢复)
- [ ] **⚠️需拍板** `docs/handoff/` 2.7G(**订正**:本波复核为 **tracked 416 文件**,非「未跟踪」;backlog drift)。选项:①只加 .gitignore 挡未来 ②`git rm --cached`+gitignore 移出跟踪(仍在历史) ③filter-repo 洗历史+force push(彻底但成本高)。涉历史/force push,拍板后做。

## 批次 3 · 死代码/死文案(拍板点:66 篇文案接线 vs 归档)

- [x] ~~三死文件删除~~ **❌部分证伪(2026-07-03·batch-123 Phase 0)**——① **`battle_engine.dart`** 被平衡诊断/红线测试活用;② **`battle_demo.dart`** 的 `BattleDemo.mockTeams()` 是 BattleScreen widget 测试夹具,二者保留。③ `stage_auto_play_control.dart` 当时判为「功能完成未接入」并留待拍板;其最终决策见下条。
- [x] 66 篇不可达文案 **✅已归档(2026-07-03·`b2098f29`)**:`data/narratives/techniques/` 26 篇 + `insights/` 40 篇迁至 `data/narratives/_archive/techniques/`,保留内容并移出 asset 打包；恢复步骤见归档目录 README。
- [x] numbers.yaml `tower` 段 + `synergies` 段 **✅已补 unused 头注(2026-07-03·batch-123)**——证实 0 消费:`NumbersConfig.fromYaml`(numbers_config.dart:322+)不解析 `y['tower']`/`y['synergies']`(头注 L18-19「保留 raw」),lib/ 无 raw 访问。synergies 真实源=独立 `data/synergies.yaml`(12 条·multipliers 格式·game_repository:341)。两段各加醒目 UNUSED 头注(保留 tower 段作 GDD §8.2 设计锚·标注 daily_attempts 每日 5 次限制**未实装**)。删除仍需拍板,故留注不删。
- [x] `home_feed` / `stage_auto_play` **✅已拍板并清理(2026-07-10)**:`home_feed_screen.dart` 删除,事件流查询迁入 `features/event`,离线归来与门派月度 tick 启动钩子迁到 `MainMenuStartupGate`;`stage_auto_play` 逐关偏好/控件/视觉路由删除,战斗入口只读全局 `GameplaySettings.autoPlayDefault`,主线首通强制 interactive 规则保留。`technique_learning.dart`=活 service,继续保留。

## 批次 4 · CI 搭建

- [x] GitHub Actions **✅已落地(2026-07-03·PR #18·`5a1e13b1`)**:钉 Flutter 3.41.5 + PUB_HOSTED_URL,执行 build_runner → analyze → 默认并发全量 test；2026-07-10 push run 绿。**运行时维护(2026-07-10)**:`actions/checkout@v4`(Node 20 弃用注记)升级到官方最新 `v7`(Node 24),并移除 build_runner 已废弃的 `--delete-conflicting-outputs` 参数。

## 批次 5 · battle_screen 拆分(拍板点:排期时机)

- [x] `battle_screen.dart` 3102 行拆分 **✅旧任务已完成并销账(2026-07-10 复核)**:2026-07-05 `BattlePlaybackController` 等拆分后当前主文件为 896 行,旧 3102 行口径已失效;后续仅按真实热点继续拆,不再排一次 20+ widget 的机械重构。

## P2 零散(顺手做/低优)

- [x] ~~玩家可见中文散写 ~11 处~~ **✅证伪已达标(2026-07-03 复核)**:presentation/domain 层实为 0-2 处硬编码,~340 处中文均为 dev-facing 异常串(§5.6 已豁免)。无需做。
- [x] ~~`0.95` 战斗三率 clamp ×4 进 numbers.yaml~~ **✅已实装(2026-07-03·本条 2026-07-05 夜间批核实为 stale)**:`data/numbers.yaml:130 combined_rate_cap: 0.95` + `RedLinesConfig.combinedRateCap` 解析 + 3 消费点全接线(`stage_battle_setup.dart:354`/`light_foot_strategy.dart:71`/`mass_battle_strategy.dart:96`),测试覆盖 `numbers_config_red_lines_test` + 两 strategy test。lib/ 剩余 `0.95` 字面量全为 UI alpha 无关项。**✅ factions/territories.yaml 校验也已补(2026-07-10 复核)**:`GameRepository._validateFactionTerritoryReferences` 在 `loadAllDefs` 末尾校 faction alignment 枚举、stage/encounter factionId 引用、territory baseDefenseLevel ∈ [1,7];`test/features/sect/faction_territory_validation_test.dart` 覆盖 3 个坏例 + 真实数据回归。
- [x] `ExactAssetImage` ×5 迁 WuxiaImage **✅已迁(2026-07-03·batch-123)**(seclusion 4 屏 + portrait_frame·全仓 ExactAssetImage 归零·获 cacheWidth 收益);~~shop_screen.dart:606 死路径~~ **证伪已迁出**(现为 WuxiaImage);~~ch6_r5:216 恒真断言删除~~ **证伪=有意软红线下界放宽**(注释明「>=0 恒真·清线由 solo_mainline 覆盖」),不删。
- [x] ~~battle 144Hz repaint rainbow 实测一次~~ **✅已实测销账(2026-07-05 夜间批E)**:真机自动战斗 10 帧 rainbow 帧差,重绘局部化实证(逐对均值 9.9%/峰值 24.6%,中央大片静止,热区=单位区+底栏),无需优化动作。详 `docs/audit/battle_repaint_rainbow_probe_2026-07-05.md`(含 144Hz 帧率成本非本读数的口径局限)。
- [x] 测试 `setUpAll` 样板专项重构 **✅完成(2026-07-10)**:共享 `test_data.dart` 与 `isar_test_support.dart` 已落地;GameRepository 生产数据样板累计迁 247 个测试文件(helper/自测另 2),直接 `loadAllDefs` 文件在最终批 230→25,余下均为 custom/fresh/fault loader;Isar 直接 Core 初始化累计 95→0。各批定向测试与 `flutter analyze test` 全绿。
- [x] **README 重写 ✅完整深度已重写(2026-07-03·用户拍板完整)**:替换默认 Flutter 模板→183 行完整 README(玩法/技术栈/结构/构建/测试/红线/文档索引);所有事实现查 repo(pubspec 版本·.g.dart gitignore build_runner 步骤·516 测试文件·451 data yaml·46 feature)。~~insights 白名单 36 vs 40~~ **证伪已自洽**(`encounter_skills_yaml_test` knownInsights 36=已映射 insight 数,非文件数)
- [x] 根目录退役 md 归档 docs/_archive/ **✅已归档 12 个(2026-07-03·Phase 0 逐个证伪)**:根 .md 20→8。归档=DeepSeek/Windows 协作期 4(DEEPSEEK_OUTPUT/T32_WINDOWS_HANDOFF/WINDOWS_REVIEW_T16/CHANGELOG·0 活引用)+ Phase1-3 期 7(phase{1,2,3}_{summary,tasks}/PHASE3_KICKOFF)+ ui_structure。phaseN_tasks 被 30+ 源码「出处 citation」(如 `phase2_tasks T26 §324-356`)引用·无路径·find 可达·零 break。**证伪保留**:content_guide.md=wuxia-content skill 硬编码从根读(归档即断·check-redlines 实不引它=backlog drift)/data_schema.md=字段 SoT·源码 §链实引/AGENTS.md=codex stub。git mv 纯 rename·analyze 0。
