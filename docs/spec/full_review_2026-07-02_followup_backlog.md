# 全面审查后续批次 backlog(2026-07-02)

> 源:`docs/audit/full_project_review_2026-07-02.md`(六维审查,P0×1+P1×12+P2×10)。
> 速修批(#1)已完成:P0 pubspec 资产声明 ×2 + 守卫测 / GDD 桃花岛+门派事件订正 / CLAUDE §5.3·§8.1 订正(v1.28)/ .gitignore 幽灵注释。
> 本文件只承载**待拍板/待排期**项(守打磨期 backlog 原则);做完一批划掉一批。

## 批次 2 · 资产瘦身(拍板点:webp 转码质量抽验)

- [ ] 210MB PNG → webp/jpeg 转码(实测探针 -85%,总分发包 ~230MB→60-80MB);**需用户目检抽验画质后全量执行**
- [ ] 44.9MB 零引用资产清理(67 文件:`ui/mj/*_01` 旧稿 15 张 ~19MB / `techniques/tier_*.png` 7 张 3.7MB 约定未接线——tier_* 需拍板「接线 or 删」/ enemies 零引用若干)
- [ ] `docs/reviews/` 加 .gitignore + `git rm --cached`(26 张大 PNG,最大 25.8MB);2.4G 历史要不要 `git filter-repo` 清洗需拍板(单人仓 force push 成本低)
- [ ] `assets/audio/_suno_candidates/` 75MB 定稿归档或删除(拍板)
- [ ] 本地 `docs/handoff/` 2.7G 未跟踪 capture 目录清理(纯磁盘,零风险)

## 批次 3 · 死代码/死文案(拍板点:66 篇文案接线 vs 归档)

- [ ] `battle_engine.dart`/`battle_demo.dart`/`stage_auto_play_control.dart` 三死文件删除 + 对应测试迁移到 strategy/真实入口
- [ ] 66 篇不可达文案处置:`narratives/techniques/` 26 篇(拼音命名,与 techniques.yaml id 不联结,真孤儿)+ `insights/` 40 篇(`narrativeInsightId` 映射已填但无加载管线)——**接 UI or 移 _archive 需拍板**
- [ ] numbers.yaml `tower` 段 + `synergies.effect_values` 段:0 消费死配置,砍掉或补 unused 头注
- [ ] `home_feed_screen.dart` Screen 本体(providers/UiStrings 仍被 baike 活用,只删壳)/ `technique_learning.dart`(已文档化 deferred,Phase 5+ 用,建议留)

## 批次 4 · CI 搭建(拍板点:要不要 CI 本身)

- [ ] GitHub Actions:build_runner → analyze → 全量 test(-j1 锚点 ~10min);注意 memory `feedback_flutter_ci_local_green_red_divergence` 五坑(钉 flutter-version / PUB_HOSTED_URL 对齐镜像 / golden exclude 等)

## 批次 5 · battle_screen 拆分(拍板点:排期时机)

- [ ] 3102 行 → 拆 20+ 彼此独立私有 widget(低风险但改动面大,冲突高发区,等战斗子系统无在途需求时单独一波,建议 xhigh)

## P2 零散(顺手做/低优)

- [ ] §5.6 拍板 dev-facing 异常串豁免条款(383 行 fail-fast 中文串的字面违规悬置)
- [ ] 玩家可见中文散写 ~11 处收敛 UiStrings/EnumL10n(半天,可并入任一批)
- [ ] `0.95` 战斗三率 clamp ×4 进 numbers.yaml;factions/territories.yaml 补 `_enforce*`
- [ ] `ExactAssetImage` ×5 迁 WuxiaImage;shop_screen.dart:606 死路径;恒真断言 ch6_r5:216 删除
- [ ] battle 144Hz repaint rainbow 实测一次;243 测试文件 setUpAll 样板抽 `test/support/def_loading.dart`(防扩散)
- [ ] README 重写;根目录 10 个退役 md 归档 docs/_archive/;CHANGELOG 处置(死文档);insights 测试白名单对齐(36 vs 40)
