# 任务储备总账(唯一正向储备)

> 反向储备(拍死不做·防重提)见 `docs/spec/rejected_task_registry.md`,规划新任务前两份都读。
> **准入三态**:待拍板 / 已解锁未做 / 依赖锁死——「本次没空做」不准进(CLAUDE §7 打磨期原则)。
> **维护**:每批收账随 PROGRESS 同步更新;销账即删行(git 留历史);总行数 ≤80。
> 2026-07-19 建账:散落储备(PROGRESS 挂账段 / playability_phase2_backlog / 两份 audit followup)已归纳至此,旧文件原地归档留指针。
> 2026-08-23 最新收口事实：主线、塔、扫荡、远征、断魂庄五个生产消费面已永久切至 Phase 0A 单角色 ARPG，live/headless 共用 reducer；历史多人会话安全兑现、释放或保留奖励选择态，不再启动旧 runner。旧 3v3 已在 Gate commit `597a243b` 原子删除并合入 `main`，同 commit 的 Mac/Windows 本地物理机矩阵均 6/6 PASS；六人真人 Gate 已取消。Windows 结果不定义产品最低配置，详 `docs/audit/route_c_gate_closeout_2026-08-23.md`。

## 一 · 待拍板(拍一个解锁一个)

| # | 项 | 域/性质 | 拍板点 |
|---|---|---|---|
| 21 | **断魂庄 RNG seed 作用域** | 会话随机性 · 规则 | `GauntletRun.seed=SaveData.id`，而单例 SaveData 的 id 恒为 0，故所有存档/每次进入的第 N 关实际 seed 恒为 N。选 A=按 `slotId` 稳定（推荐：同存档重打不重抽、异存档不同流），B=确认全存档固定副本并订正文档，C=引入 run serial 让每次进入变化。2026-08-23 夜班只读审计发现，因属随机性口径未擅改。 |
| 20 | **Phase 0A 普攻真气来源口径** | 战斗资源循环 · 规则/数值 | 当前 production snapshot 的真实入门普攻 `SkillDef.qiDelta=20`，但 Phase 0A input adapter 明确消费 `numbers.phase0a_arena.moves.basic_qi_delta=0`；因此身份/伤害来自真实 basic，普攻却不回真气，画像表现为 Q 每场约一次、R 零次。选 A=改由真实 `SkillDef.qiDelta` 驱动（会改变 Q/R 循环，须重跑画像与实机），或 B=保持 0 并把它正式定义为 Phase 0A 规则。2026-08-23 夜班仅发现并挂账，未改任何值。 |
| 19 | **资质视觉档位化**(2026-08-08 defer;2026-08-11 随 #15/#16 实装销账时**单独立行**) | 玩家可见 UI · 观感 | 现状:档案页资质 chip 六档共用一个灰底标签、档位差异只靠档名文字(`lineage_character_detail_screen.dart:303` 自注「视觉表现为临时版」)。可选表达:色阶/印章/边框/底纹。用户 2026-08-11 已拍板并入未来试玩局再定；2026-08-23 取消的是 Route C 六人 Gate，不代表本观感项自动拍板。 |
| 4 | 丹房强度 2B | 数值复核 | 已定「不动」,待真人试玩数据复核(2026-07-19 1A 批决议) |
| 5 | 残页集齐数量(真解1/残页5 默认) | 数值微调 | 实玩后可调(P1a §16#4 默认值) |
| 6 | 高熟练度难度微调候选 | 数值微调 | 波B 全表 sweep 读数在案,待真玩拍板 |

## 二 · 已解锁可派

（空——Phase 0A 护法近身标签错列打磨已于 2026-08-22 销账；git 历史可溯）

## 三 · 依赖锁死(附再开条件)

| # | 项 | 依赖/再开条件 |
|---|---|---|
| 1 | Riverpod `pausedActiveSubscriptionCount` debug 断言(低severity·框架bug·release 无感) | isar_community 支持 analyzer≥12 → 升 riverpod 3.3.2+ 真机验;详 memory `reference_riverpod_tickermode_pause_assert` |
| 2 | isar fork 供应链 / analyzer 三角(analyzer 钉 9.0.0 止血中) | 同上游条件,解锁后做一轮依赖维护批 |
| 3 | Flutter SDK 3.41.5→≥3.44 升级(解锁 audioplayers 6.8.x / 松 windows-2022 钉) | 2026-08-05 拍板暂缓(无需求驱动+isar fork 兼容风险与上行 #2 统一处理);再开条件=windows-2022 退役公告 / audioplayers 出本项目需要的修复 / #2 解锁开依赖维护批时**合并做**。要点存档(2026-08-01 实测):真闸门=audioplayers ≥6.8.0 要 Flutter ≥3.44(非 pubspec 约束);动作序列=升 SDK→pub upgrade→CMake 3.14→3.15 三处(`windows/CMakeLists.txt:2,11`+`windows/runner/CMakeLists.txt:1`)→CI 三处 flutter-version 钉(`ci.yml:36,78`/`windows-release.yml:35`)→`windows-release.yml:26` 放回 windows-latest→Windows release CI 实跑(唯一真证明);isar_community 对新 Dart 兼容须复核 |

## 四 · 方向级候选(大活·需专注会话+xhigh)

（空——Route C 已于 2026-08-23 完成双平台 Gate 并原子合入 `main`。）
