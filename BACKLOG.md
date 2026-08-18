# 任务储备总账(唯一正向储备)

> 反向储备(拍死不做·防重提)见 `docs/spec/rejected_task_registry.md`,规划新任务前两份都读。
> **准入三态**:待拍板 / 已解锁未做 / 依赖锁死——「本次没空做」不准进(CLAUDE §7 打磨期原则)。
> **维护**:每批收账随 PROGRESS 同步更新;销账即删行(git 留历史);总行数 ≤80。
> 2026-07-19 建账:散落储备(PROGRESS 挂账段 / playability_phase2_backlog / 两份 audit followup)已归纳至此,旧文件原地归档留指针。

## 一 · 待拍板(拍一个解锁一个)

| # | 项 | 域/性质 | 拍板点 |
|---|---|---|---|
| 19 | **资质视觉档位化**(2026-08-08 defer;2026-08-11 随 #15/#16 实装销账时**单独立行**——此前只寄生在 #16 正文里,两条一销就会连带丢掉这个还没拍的点) | 玩家可见 UI · 观感 | 现状:档案页资质 chip 沿用 `_AttrChip` 同款样式,六档共用一个灰底标签、档位差异只靠档名文字(`lineage_character_detail_screen.dart:303` 自注「视觉表现为临时版」)。可选表达:色阶 / 印章 / 边框 / 底纹。**用户 2026-08-11 已拍板并入试玩局再定**——好不好看只有真机看过才算数,量测只能排硬伤。与本区 #4/#5/#6 同属「卡在没人真玩过」的一批,建议同一局解决 |
| 4 | 丹房强度 2B | 数值复核 | 已定「不动」,待真人试玩数据复核(2026-07-19 1A 批决议) |
| 5 | 残页集齐数量(真解1/残页5 默认) | 数值微调 | 实玩后可调(P1a §16#4 默认值) |
| 6 | 高熟练度难度微调候选 | 数值微调 | 波B 全表 sweep 读数在案,待真玩拍板 |

## 二 · 已解锁可派

| # | 项 | 域 | 预估 | 依据 |
|---|---|---|---|---|
| 7 | B3 立绘融合观感真人拍方向 **2026-08-18 挂起:战斗已转横版 ARPG 方向(0A/0B),旧 3v3 屏去留待裁决,本项随旧屏去留再定** | battle 表现层数值 | 挂起 | 需先看真机实拍图;要调只动 `battleStandeeFusionOpacityAtFull`/明度下沿/上沿三常量,门禁测守边界。登记值精度 ±9。**附带项(cliffwaterfall boss 取样带侵入)已证伪销 2026-08-05**:夜班 N5 真机差分实测 boss 尺寸下立绘右缘 ~0.71,距带起点 0.74 约 38 逻辑 px 未侵入;新发现=登记口径贴纯背景资产、实拍合成带 118.3(+14.6 超 ±9),均 <floor 125 零行为差,**未来若把 floor 下调至 ≤118 须先统一全表口径**,详 `docs/audit/cliffwaterfall_fusion_band_probe_2026-08-05.md` |

## 三 · 依赖锁死(附再开条件)

| # | 项 | 依赖/再开条件 |
|---|---|---|
| 1 | Riverpod `pausedActiveSubscriptionCount` debug 断言(低severity·框架bug·release 无感) | isar_community 支持 analyzer≥12 → 升 riverpod 3.3.2+ 真机验;详 memory `reference_riverpod_tickermode_pause_assert` |
| 2 | isar fork 供应链 / analyzer 三角(analyzer 钉 9.0.0 止血中) | 同上游条件,解锁后做一轮依赖维护批 |
| 3 | Flutter SDK 3.41.5→≥3.44 升级(解锁 audioplayers 6.8.x / 松 windows-2022 钉) | 2026-08-05 拍板暂缓(无需求驱动+isar fork 兼容风险与上行 #2 统一处理);再开条件=windows-2022 退役公告 / audioplayers 出本项目需要的修复 / #2 解锁开依赖维护批时**合并做**。要点存档(2026-08-01 实测):真闸门=audioplayers ≥6.8.0 要 Flutter ≥3.44(非 pubspec 约束);动作序列=升 SDK→pub upgrade→CMake 3.14→3.15 三处(`windows/CMakeLists.txt:2,11`+`windows/runner/CMakeLists.txt:1`)→CI 三处 flutter-version 钉(`ci.yml:36,78`/`windows-release.yml:35`)→`windows-release.yml:26` 放回 windows-latest→Windows release CI 实跑(唯一真证明);isar_community 对新 Dart 兼容须复核 |

## 四 · 方向级候选(大活·需专注会话+xhigh)

- (归档:「第八阶段 · 敌方协同」已于 2026-08-06 全五切片收官进 main(merge `714e68a0`+`9e4dc275`,塔 42 首实例三态校准 100%/15%/0%),详 spec `docs/spec/2026-08-05-phase8-boss-coop-guard-charge-design.md` 与 PROGRESS 顶段;真机观感目检待用户,一验后关账。)
- (归档:「爬塔与支线终局适配」已于 2026-08-04 三批(PR #115/#117/#118)全收口进 main,详 `docs/spec/2026-08-01-tower-extension-design.md`。)
