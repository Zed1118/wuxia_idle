# 全面审查后续批次 backlog(2026-07-02)

> 源:`docs/audit/full_project_review_2026-07-02.md`(六维审查,P0×1+P1×12+P2×10)。
> 速修批(#1)已完成:P0 pubspec 资产声明 ×2 + 守卫测 / GDD 桃花岛+门派事件订正 / CLAUDE §5.3·§8.1 订正(v1.28)/ .gitignore 幽灵注释。
> 本文件只承载**待拍板/待排期**项(守打磨期 backlog 原则);做完一批划掉一批。

## 批次 2 · 资产瘦身(拍板点:webp 转码质量抽验)

- [ ] 210MB PNG → webp/jpeg 转码(实测探针 -85%,总分发包 ~230MB→60-80MB);**需用户目检抽验画质后全量执行**
- [x] 零引用资产清理 **✅已删(2026-07-03·batch-123)**——**订正**:backlog 原记「44.9MB/67 文件」是 drift(webp 转码 + tier_* 已删后体积变小)。本波独立 grep 现算实为 **59 文件 8.0MB**:`ui/mj/*_01` 旧稿 **17 张**(fx_×10 + overlay_×4 + ui_frame_×2 + ceremony_red_seal_01·全 0 引用,已被 `*_blend` 版替代;entry_/menu_/其余 ceremony 的 *_01 均 1 引用=活,未动)+ `enemies/*.png` **42 张**(129 中 42 张 0 引用,移除史抽验 guard_c/shidi_a 均 commit `e73979ce`(06-28)删敌人定义时连带删 iconPath=废弃品)。iconPath 为静态全路径字面量(`assets/enemies/x.png`)无动态拼接,grep 验证可靠。~~`tier_*.png` 7 张~~ 早于 2026-07-02 删。
- [x] `docs/reviews/` **✅已治理(上批 .git 瘦身)**——本波复核:仅 4KB tracked,.gitignore 已含 `docs/reviews/`(挡 PNG)。2.4G→658M 历史已 filter-repo 洗过(见 PROGRESS `5bd36fc1`),无需再洗。
- [x] `assets/audio/_suno_candidates/` 75MB **✅已归档(2026-07-02·用户拍板)**:mv 出项目 → `~/Desktop/wuxia_suno_candidates_archive_2026-07-02`(已 gitignore·不进仓/不进包·可恢复)
- [ ] **⚠️需拍板** `docs/handoff/` 2.7G(**订正**:本波复核为 **tracked 416 文件**,非「未跟踪」;backlog drift)。选项:①只加 .gitignore 挡未来 ②`git rm --cached`+gitignore 移出跟踪(仍在历史) ③filter-repo 洗历史+force push(彻底但成本高)。涉历史/force push,拍板后做。

## 批次 3 · 死代码/死文案(拍板点:66 篇文案接线 vs 归档)

- [x] ~~三死文件删除~~ **❌证伪·全部不删(2026-07-03·batch-123 Phase 0)**——同 tier_* 教训,backlog 误记为「死」。独立 grep 现查:① **`battle_engine.dart`** 被 `test/tools/*`(balance_simulator/tower_boss_feel/floor30_soft_gate 诊断)+ `test/balance/*_crosstier_redline`(跨阶红线)+ 战斗测试共 18 文件引用,是**平衡诊断/红线模拟引擎**,删=摧毁整个红线体系;② **`battle_demo.dart`** `BattleDemo.mockTeams()` 是 7+ 个 **BattleScreen 生产屏 widget 测试的核心夹具**(log/pause/cycle_hint/break_window/coop_burst/command_console),虽 `BattleDemoLauncher` 生产入口已被 battle_test_menu 取代,mockTeams 静态夹具活跃;③ **`stage_auto_play_control.dart`** 是「功能完成未接入入口」组件(接真实 auto-play provider·5 类选关屏挂机开关),`stage_list_screen_test:131` 断言其存在——**与 home_feed 同类,死活模糊需拍板不自主删**(见下条)。**结论:三者皆非死文件,不删。**
- [ ] **⚠️需拍板** 66 篇不可达文案处置(2026-07-03 Phase 0 复核确认真孤儿):`data/narratives/techniques/` **26 篇**(拼音命名)+ `data/narratives/techniques/insights/` **40 篇**。证据:`NarrativeLoader._scanPaths` 仅含 `narratives/ + stages/ + ascension/ + chapters/`,**不含 techniques/**;`narrativeInsightId` 字段仅在 `skill_def.dart:44/128` 定义+解析,**lib/ 零消费**(无 loader 读)。pubspec 已声明(L61-62)故运行期可达,但无加载管线。选项:①移 `_archive/`(保留内容移出 asset,最保守) ②保持现状(Phase 5 武学领悟 UI 时接线) ③删除。**Phase 5 前接线属提前造轮子(违 §5.7),倾向 ①/②。**
- [x] numbers.yaml `tower` 段 + `synergies` 段 **✅已补 unused 头注(2026-07-03·batch-123)**——证实 0 消费:`NumbersConfig.fromYaml`(numbers_config.dart:322+)不解析 `y['tower']`/`y['synergies']`(头注 L18-19「保留 raw」),lib/ 无 raw 访问。synergies 真实源=独立 `data/synergies.yaml`(12 条·multipliers 格式·game_repository:341)。两段各加醒目 UNUSED 头注(保留 tower 段作 GDD §8.2 设计锚·标注 daily_attempts 每日 5 次限制**未实装**)。删除仍需拍板,故留注不删。
- [ ] **⚠️需拍板** `home_feed_screen.dart`(壳死·无路由引用·但 providers/`UiStrings.homeFeedRelativeTime` 被 baike 活用)+ `stage_auto_play_control.dart`(接真实 auto-play provider·未接入选关屏入口)两个「功能完成未接入」组件:删壳(迁复用逻辑)vs 保留待接入(Phase 5+)。`technique_learning.dart`=活 service(非 dead),留。

## 批次 4 · CI 搭建(拍板点:要不要 CI 本身)

- [ ] GitHub Actions:build_runner → analyze → 全量 test(-j1 锚点 ~10min);注意 memory `feedback_flutter_ci_local_green_red_divergence` 五坑(钉 flutter-version / PUB_HOSTED_URL 对齐镜像 / golden exclude 等)

## 批次 5 · battle_screen 拆分(拍板点:排期时机)

- [ ] 3102 行 → 拆 20+ 彼此独立私有 widget(低风险但改动面大,冲突高发区,等战斗子系统无在途需求时单独一波,建议 xhigh)

## P2 零散(顺手做/低优)

- [x] ~~玩家可见中文散写 ~11 处~~ **✅证伪已达标(2026-07-03 复核)**:presentation/domain 层实为 0-2 处硬编码,~340 处中文均为 dev-facing 异常串(§5.6 已豁免)。无需做。
- [x] ~~`0.95` 战斗三率 clamp ×4 进 numbers.yaml~~ **✅已实装(2026-07-03·本条 2026-07-05 夜间批核实为 stale)**:`data/numbers.yaml:130 combined_rate_cap: 0.95` + `RedLinesConfig.combinedRateCap` 解析 + 3 消费点全接线(`stage_battle_setup.dart:354`/`light_foot_strategy.dart:71`/`mass_battle_strategy.dart:96`),测试覆盖 `numbers_config_red_lines_test` + 两 strategy test。lib/ 剩余 `0.95` 字面量全为 UI alpha 无关项。**仍开放(需拍板)**:factions/territories.yaml 补 `_enforce*` 校验(范围/fail-fast 策略)——grep 证实 game_repository 57 处 `_enforce` 无 faction/territory 条目。
- [x] `ExactAssetImage` ×5 迁 WuxiaImage **✅已迁(2026-07-03·batch-123)**(seclusion 4 屏 + portrait_frame·全仓 ExactAssetImage 归零·获 cacheWidth 收益);~~shop_screen.dart:606 死路径~~ **证伪已迁出**(现为 WuxiaImage);~~ch6_r5:216 恒真断言删除~~ **证伪=有意软红线下界放宽**(注释明「>=0 恒真·清线由 solo_mainline 覆盖」),不删。
- [ ] battle 144Hz repaint rainbow 实测一次;252 测试文件 setUpAll 样板抽 `test/support/def_loading.dart`(**11-15h 大改动·缓做**,建议后续专项重构批·收益<成本本波不压)
- [x] **README 重写 ✅完整深度已重写(2026-07-03·用户拍板完整)**:替换默认 Flutter 模板→183 行完整 README(玩法/技术栈/结构/构建/测试/红线/文档索引);所有事实现查 repo(pubspec 版本·.g.dart gitignore build_runner 步骤·516 测试文件·451 data yaml·46 feature)。~~insights 白名单 36 vs 40~~ **证伪已自洽**(`encounter_skills_yaml_test` knownInsights 36=已映射 insight 数,非文件数)
- [x] 根目录退役 md 归档 docs/_archive/ **✅已归档 12 个(2026-07-03·Phase 0 逐个证伪)**:根 .md 20→8。归档=DeepSeek/Windows 协作期 4(DEEPSEEK_OUTPUT/T32_WINDOWS_HANDOFF/WINDOWS_REVIEW_T16/CHANGELOG·0 活引用)+ Phase1-3 期 7(phase{1,2,3}_{summary,tasks}/PHASE3_KICKOFF)+ ui_structure。phaseN_tasks 被 30+ 源码「出处 citation」(如 `phase2_tasks T26 §324-356`)引用·无路径·find 可达·零 break。**证伪保留**:content_guide.md=wuxia-content skill 硬编码从根读(归档即断·check-redlines 实不引它=backlog drift)/data_schema.md=字段 SoT·源码 §链实引/AGENTS.md=codex stub。git mv 纯 rename·analyze 0。
