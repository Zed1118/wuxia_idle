# 任务储备总账(唯一正向储备)

> 反向储备(拍死不做·防重提)见 `docs/spec/rejected_task_registry.md`,规划新任务前两份都读。
> **准入三态**:待拍板 / 已解锁未做 / 依赖锁死——「本次没空做」不准进(CLAUDE §7 打磨期原则)。
> **维护**:每批收账随 PROGRESS 同步更新;销账即删行(git 留历史);总行数 ≤80。
> 2026-07-19 建账:散落储备(PROGRESS 挂账段 / playability_phase2_backlog / 两份 audit followup)已归纳至此,旧文件原地归档留指针。

## 一 · 待拍板(拍一个解锁一个)

| # | 项 | 域/性质 | 拍板点 |
|---|---|---|---|
| 3 | P2③ Boss 协同窗口 | 设计讨论 | 「敌方协同」新概念,先定范围再动(master spec §四) |
| 4 | 丹房强度 2B | 数值复核 | 已定「不动」,待真人试玩数据复核(2026-07-19 1A 批决议) |
| 5 | 残页集齐数量(真解1/残页5 默认) | 数值微调 | 实玩后可调(P1a §16#4 默认值) |
| 6 | 高熟练度难度微调候选 | 数值微调 | 波B 全表 sweep 读数在案,待真玩拍板 |
| 7 | CLAUDE §12.2 #5 归档行闭关单倍率表述 | no-touch 文档订正 | 1A 经验倍率拆分批后 stale,待版本订正窗口 |
| 8 | 生产 DefaultRng 无种子统一走 rngProvider(#57 遗留) | 生产接线 | 2026-07-22 拍板留议(非阻塞·stage_entry_flow.dart:826 直 new) |

## 二 · 已解锁可派

| # | 项 | 域 | 预估 | 依据 |
|---|---|---|---|---|
| 1 | battle-ui-v2 阶段 5(Windows 100%/125%/150% 缩放) | battle 表现层(codex 在途分支自然续) | 随批 | plan `2026-07-19-battle-ui-v2-85-fidelity-implementation.md` 既定末段 |
| 2 | P1-5.2 战败持久化:ExpeditionRun 加 defeated schema 字段 | [schema] 实装批 | 半批 | 2026-07-22 用户拍定(#58 BLOCKED 项解锁·须 build_runner+全量) |
| 3 | 散功 dispel_service 接占用契约(+顺手修 recall 并发冲突 UI 假 recap) | P2 审查批 | 小批 | #58 Gate 新发现(中/低·2026-07-22 收账挂账) |
| 4 | Ch13 美术 11 图 codex image_gen 派单(5 敌+cover+5 背景) | 美术 | 随批 | known_missing_assets +11 已登记(#55 带入) |
| 5 | Ch14 spec 起草(承 Ch13 卷尾 hook·shi_dang 收编位) | 设计 | 专会话 | 2026-07-22 收账下批建议 |

## 三 · 依赖锁死(附再开条件)

| # | 项 | 依赖/再开条件 |
|---|---|---|
| 1 | Riverpod `pausedActiveSubscriptionCount` debug 断言(低severity·框架bug·release 无感) | isar_community 支持 analyzer≥12 → 升 riverpod 3.3.2+ 真机验;详 memory `reference_riverpod_tickermode_pause_assert` |
| 2 | isar fork 供应链 / analyzer 三角(analyzer 钉 9.0.0 止血中) | 同上游条件,解锁后做一轮依赖维护批 |

## 四 · 方向级候选(大活·需专注会话+xhigh)

- **Ch10+ 一流拐点主线章**(承 Ch9 末「符的那头是又一个开始」hook·B 案存档备参)——抬发布上限 reconcile 面大(memory `feedback_wuxia_release_cap_raise_reconcile` 4 站点),宜专章专议
- **爬塔二流段 spec**——塔内容扩展另一轴
