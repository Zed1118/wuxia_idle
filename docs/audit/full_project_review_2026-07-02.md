# 挂机武侠 · 全项目全面审查报告

**日期**:2026-07-02 · **基线**:main `33857613`(=origin/main·工作树干净)
**方法**:6 个并行只读审计代理(架构/红线合规/测试体系/数据内容/性能资源/文档工程)+ 主会话实测硬数据 + 关键结论逐条交叉证伪(pubspec/构建产物/grep 复核)。全部数字本会话实测,无转抄。

## 总评

**核心质量为优,短板集中在工程外围。** 代码架构、数值红线、测试体系、数据一致性四大内核经六维扫描仅 1 个 P0(且为一行修复);发现的问题几乎全部落在资产管理、发布链路(无 CI/包体虚胖)、死代码/死文案、文档边角——与「1.0 长线打磨期」定位吻合:玩法内核已可信,该还的是工程债。

## 实测基线(2026-07-02 本会话)

| 项 | 实测值 |
|---|---|
| `flutter analyze lib/ test/` | **0 issues**(15.3s) |
| 全量 `flutter test --no-pub -j1` | **3583 passed / 1 skip / 0 fail**(墙钟 ~9min42s,首次记录时长基线) |
| 代码规模 | lib 415 文件 / 94,779 行;test 517 文件 / 95,155 行(≈1:1);47 features |
| 配置 | data/ 451 yaml / 2.3M;numbers.yaml 36 顶层段 32 段有消费 |
| 资产 | assets/ 301M(实际入包 ≈226M);.git 2.40 GiB;docs/ 本地 3.1G(2.7G 为未跟踪 capture) |
| 红线守卫 | 37 个守卫测试文件(balance 9 + data 14 + features 9 + debug 路由守卫);23 个 `_enforce*` 校验 |

## P0(1 项)

**P0-1 `data/lore/sect_event/` 未声明进 pubspec → 10 个门派事件文案运行期不可达**
pubspec.yaml:54-55 声明 `data/lore/` 与 `_templates/`,Flutter asset 目录声明不递归,`sect_event/`(tournament_01-05/crisis_01-02/mission_01-03 共 10 文件)漏网。构建产物 flutter_assets/data/lore/ 下确认无 sect_event(本会话双重复核)。运行期 `sect_event_dialog.dart:56` rootBundle 读取失败被 `catch (_)` 整体吞掉,回退通用兜底文案——玩家永远看不到这 10 篇文案,numbers.yaml:1764 `narrative_ids` 引用池形同虚设。**修复一行 pubspec + 一条守卫测试。**

## P1(应排期)

### 发布链路
- **P1-1 无 CI**:`.github/` 本地与远端均不存在,`gh run list` 空;质量门(analyze+3583 测)完全依赖本地手跑纪律。`.gitignore:12`「CI 必须先跑 build_runner」为幽灵注释。→ 拍板要不要最小 CI(analyze + build_runner + 全量 test)。
- **P1-2 分发包虚胖 ~3 倍**:210MB PNG 未做格式压缩,实测探针 `menu_splash_pier_01.png` 2564KB→jpeg q85 396KB(-85%);全量 webp 化后总包可从 ~230MB 降至 ~60-80MB。最大源图 1456×816(MJ 原生,无超规格),纯格式问题。
- **P1-3 零引用资产 44.9MB 正在入包**:434 张 png 逐一 grep,剔除 36 张动态拼接约定名后确认 67 个 0 引用,最大簇 `ui/mj/*_01.png` 旧稿 15 张 ~19MB(代码全用 `*_blend` 版);`techniques/tier_*.png` 7 张 3.7MB 约定路径从未接线。
- **P1-4 git 历史包袱 2.40 GiB**:top 大对象全是 `docs/reviews/l1_acceptance/*.png`(最大单张 25.8MB,26 张已跟踪);`docs/reviews/` 漏出 .gitignore。另:本地 `docs/handoff/` 2.7G 未跟踪 capture 目录(944M+629M+335M…)纯磁盘垃圾;`assets/audio/_suno_candidates/` 75M 不入包但占仓库 25%。

### 代码与架构
- **P1-5 core 分层违规 1 处**:`lib/core/application/system_clock_provider.dart:1` import flutter_riverpod,是 core 36 文件唯一 Flutter 依赖(同目录其余均用纯 Dart riverpod_annotation),改 codegen 即归队。
- **P1-6 battle_screen.dart 3102 行 god file**:`_BattleScreenState` ~1200 行 + 20+ 彼此独立的私有 widget(可低风险拆分);战斗是改动最频繁子系统,该文件是 merge 冲突高发区。同级 watch list:strings.dart 3285(纯字符串目录,合理)/numbers_config 2867(纯 config,合理)/character_panel_screen 2266(下一个接近阈值的 UI 文件)。
- **P1-7 死代码仅测试续命**:`battle_engine.dart`(旧引擎,生产 0 引用,11 方法已整体搬迁 default_ground_strategy)/`battle_demo.dart`/`stage_auto_play_control.dart` 三件,均仅 2-3 个测试 import——测试在验证已死代码给假信心。`home_feed_screen.dart` Screen 本体死(providers/UiStrings 仍被 baike 活用);`technique_learning.dart` 属已文档化 deferred,删否待拍板。
- **P1-8 玩家可见中文散写 ~11 处**(§5.6 违规):synergy_def.dart:60-68 buff 描述拼串 / master_builder.dart:69-75 默认角色名 / item_slot.dart:24 `'未达境界'` / asset_fallback.dart:34 `'缺图'` 等,半天量级收进 UiStrings/EnumL10n。

### 数据与内容
- **P1-9 66 篇文案写了玩家看不到**:`data/narratives/techniques/` 26 篇(拼音命名,与 techniques.yaml id 体系不联结,0 引用真孤儿)+ `insights/` 40 篇(encounter_skills.yaml 填了 22 条 `narrativeInsightId` 映射且测试守合法性,但 lib 无任何代码读 `insights/<id>.yaml`,管线缺失)。→ 拍板:接 UI 或移 _archive。
- **P1-10 numbers.yaml 两段 0 消费死配置**:`tower` 段(:1258 起,真值在 towers.yaml)与 `synergies.effect_values`(:1380 起,真值在 synergies.yaml),均无 unused 头注,双源 drift 风险,违反「配置而不消费必须标注或砍」约定。
- **P1-11 测试样板重复**:`GameRepository.loadAllDefs` setUpAll 样板在 243/517 个测试文件重复,建议抽 `test/support/def_loading.dart`,新测试统一走,存量防扩散即可。

### 文档
- **P1-12 GDD 反向 drift**:桃花岛一二期已实装合 main(saveVer 0.30 养成支柱,lib/features/taohua_island/ 12 文件),GDD.md 全文 **0 提及**;§12 已实装导语独漏此项。一行修复。

## P2(建议/拍板项,压缩列)

1. CLAUDE §5.3 引用 `TechniqueRepository.canPractice()` 符号不存在(实际闸门 `TechniqueLearningService.learn`,且 0 生产 caller,学心法 UI 属 Phase 5+ scoped);§8.1「narratives 缺失抛错」与实际 placeholder 兜底不符——两处文档订正。
2. §5.6 拍板 dev-facing 异常串豁免:非 debug 中文串 383 行的主体是 `throw StateError('…红线…')` 类 fail-fast 诊断文本,按字面执行需迁 300+ 行,建议明文豁免。
3. `0.95` 战斗三率 clamp 上限字面量 ×4 处与 numbers.yaml `max_rate` 双源;`fortuneSensitivity=20.0` 构造默认值与 config 双源(兜底可掩盖缺失)。
4. factions.yaml / territories.yaml 无 `_enforce*` pass 裸解析(缺文件静默 fallback 空 map)。
5. 恒真断言留存:ch6_r5_crosstier_redline_test:216-227 `greaterThanOrEqualTo(0)`(有注释溯源,建议删断言留指路)。
6. `ExactAssetImage` 绕过 cacheWidth 5 处(seclusion 4 屏 + portrait_frame.dart:44);shop_screen.dart:606 引用不存在的 `assets/images/items/` 目录(永走 errorBuilder)。
7. battle 144Hz repaint 待实测:常驻 `_pulse.repeat` + 逐拍动画,battle/presentation 仅 1 处 RepaintBoundary,建议 DevTools repaint rainbow 过一次。
8. 工程卫生:README 仍是 Flutter 脚手架模板;根目录 10 个退役 md(phase1/2/3_tasks 等 DeepSeek/Windows 时代遗产)未归档 docs/_archive/;docs/superpowers/plans 100 + specs 38 已完成未归档;CHANGELOG 停更 2026-05-17(已被 PROGRESS 取代,属死文档);version 0.1.0+1 从未 bump。
9. insights 测试白名单 drift(knownInsights 36 vs 磁盘 40,含 1 个无文件项);`_templates/` 7 个退役模板仍打包。
10. 零测试 feature 仅 pvp(76 行旧档兼容)与 splash(196 行),风险低;Riverpod 双风格并存(67 codegen vs 21 手写,纯一致性债);跨 feature 245 条 import 边无 barrier(battle 102 条入边,单人项目可接受,重构 battle 时全仓 analyze)。

## 健康面(实测确认,六维)

- **红线合规**:反主流关键词(体力/每日/登录/抽卡/VIP/战令)0 命中;在线=离线(时间戳差值结算,公式天然等价);三系锁死装备侧全链路闭环(equip 唯一路径守卫+入场再校验+飞升 auto-swap+种子 yaml 层兜底)无绕过;招式倍率实测 max=8000 恰在线内;八类主配置 schema 校验全覆盖。
- **架构**:战斗公式集中度优(presentation/application 全扫仅 4 处良性命中);Riverpod 反模式 0 命中(无 StateProvider/闭包持 ref);shared 组件复用好(PaperDialog 24 文件复用,无重复造轮);无孤儿文件;PVP 切除干净(仅 2 个旧档兼容 model+3 处带注释引用)。
- **测试**:test:lib≈1:1;红线/雷达/守卫三层齐备;唯一 skip 有规范的 forward-placeholder 注释;质量抽样符合「约束语义优于瞬时事实」(stage_silver_ratio 反推区间为范本级)。
- **数据**:encounters 68↔events 68、equipment 80↔lore 80 双向差集 0;154 条 narrative 引用 0 缺失;7 阶 ×3 slot 主属性 0 倒挂;概率字段 0 越界;内容量全面超出 Demo 锚(主线 30 关/装备 80/心法 49/lore 180 段/主线叙事 2.3 万字)。
- **文档**:CLAUDE.md 引用点抽查 12/12 成立 0 drift(damage_calculator/`_enforceEncounterSkillRedLines`/UiStrings/shop_service 头注/numbers 系数全对);PROGRESS 92 行守约、6 sha 抽验全存在;docs/audit/ 已积累 15 份专项报告。
- **性能**:cacheWidth 覆盖率约 100%(仅 ExactAssetImage 5 处例外);启动同步加载仅 11 核心 yaml+一致性校验(<50ms 自测注释可信,data 全量才 2.3M,narratives/lore 全懒加载);音频走原生播放器无堆解码;lib 全部 25 处 debugPrint 均为错误路径,build() 内 0 噪声。

## 修复路线图(候选表·附推荐)

| # | 批次 | 内容 | 模型 | 预估 | 备注 |
|---|---|---|---|---|---|
| 1 | **速修批(推荐先做)** | P0-1 pubspec 一行+守卫测 · P1-12 GDD 桃花岛补记 · P2-1 两处文档订正 · gitignore 幽灵注释 | opus high | ~40min | 全部一行级,P0 即刻止血 |
| 2 | 资产瘦身批 | P1-2 webp 转码(需美术目检抽验)· P1-3 45MB 死重清理 · P1-4 docs/reviews ignore+suno 归档 | opus | 半天 | 分发包 -70%;webp 质量需用户拍板抽验 |
| 3 | 死代码/死文案批 | P1-7 三件套删除+测试迁移 · P1-9 66 篇文案接线或归档 · P1-10 死配置段处置 | opus | 半天 | 文案接线 vs 归档需拍板 |
| 4 | CI 搭建 | GitHub Actions:build_runner+analyze+全量 test | opus | ~1h | 要不要 CI 本身先拍板;做则注意 flutter-version 钉死+镜像源(memory 五坑) |
| 5 | battle_screen 拆分 | 3102 行拆私有 widget | opus xhigh | 单独一波 | 改动面大,冲突高发区,建议闲置窗口做 |

推荐顺序 1→2→3(1 无依赖立即可做;2/3 各含一个拍板点)。5 建议等战斗子系统无在途需求时做。

---
*生成:2026-07-02 全面审查会话(6 并行只读审计代理+主会话交叉证伪);上一份全局体检为 docs/audit/project_health_review_2026-06-25.md,本报告为其后续,覆盖面扩至性能资源与工程卫生。*
