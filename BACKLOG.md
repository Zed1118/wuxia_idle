# 任务储备总账(唯一正向储备)

> 反向储备(拍死不做·防重提)见 `docs/spec/rejected_task_registry.md`,规划新任务前两份都读。
> **准入三态**:待拍板 / 已解锁未做 / 依赖锁死——「本次没空做」不准进(CLAUDE §7 打磨期原则)。
> **维护**:每批收账随 PROGRESS 同步更新;销账即删行(git 留历史);总行数 ≤80。
> 2026-07-19 建账:散落储备(PROGRESS 挂账段 / playability_phase2_backlog / 两份 audit followup)已归纳至此,旧文件原地归档留指针。

## 一 · 待拍板(拍一个解锁一个)

| # | 项 | 域/性质 | 拍板点 |
|---|---|---|---|
| 1 | 敌立绘 16 空 iconPath + 断魂庄 3 装备图 + 撑伞源图代际差 | 美术批(MJ 出图·夜批 codex 产提示词中) | 提示词就绪后人工 MJ 出图 |
| 3 | P2③ Boss 协同窗口 | 设计讨论 | 「敌方协同」新概念,先定范围再动(master spec §四) |
| 4 | 丹房强度 2B | 数值复核 | 已定「不动」,待真人试玩数据复核(2026-07-19 1A 批决议) |
| 5 | 残页集齐数量(真解1/残页5 默认) | 数值微调 | 实玩后可调(P1a §16#4 默认值) |
| 6 | 高熟练度难度微调候选 | 数值微调 | 波B 全表 sweep 读数在案,待真玩拍板 |
| 7 | CLAUDE §12.2 #5 归档行闭关单倍率表述 | no-touch 文档订正 | 1A 经验倍率拆分批后 stale,待版本订正窗口 |

## 二 · 已解锁可派

| # | 项 | 域 | 预估 | 依据 |
|---|---|---|---|---|
| 1 | 4A `dispersionInternalForcePenalty` 字段清理(砍/注释) | numbers_config(数值敏感留 Claude) | 20-30min | C2 目标1 实测零结算消费方,防撞已解除 |
| 2 | battle-ui-v2 阶段 5(Windows 100%/125%/150% 缩放) | battle 表现层(codex 在途分支自然续) | 随批 | plan `2026-07-19-battle-ui-v2-85-fidelity-implementation.md` 既定末段 |

## 三 · 依赖锁死(附再开条件)

| # | 项 | 依赖/再开条件 |
|---|---|---|
| 1 | Riverpod `pausedActiveSubscriptionCount` debug 断言(低severity·框架bug·release 无感) | isar_community 支持 analyzer≥12 → 升 riverpod 3.3.2+ 真机验;详 memory `reference_riverpod_tickermode_pause_assert` |
| 2 | isar fork 供应链 / analyzer 三角(analyzer 钉 9.0.0 止血中) | 同上游条件,解锁后做一轮依赖维护批 |

## 四 · 方向级候选(大活·需专注会话+xhigh)

- **Ch9 主线章 spec**(承 Ch8「碛北那一位」hook)——内容主线自然续
- **爬塔二流段 spec**——塔内容扩展另一轴
