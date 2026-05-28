# M15-16 D 段:性能稳定 spec

> 起草:2026-05-29 · 目标 M15-16 · 对应 RELEASE_CHECKLIST §D · ROADMAP P5.2
> 关联 Q1-Q5 拍板:海外 only / Demo 上 Steam(P5.4b 时 D 段须先过基线)

## 1. 目标

CHECKLIST D 6 子项 0/6 → 6/6。1.0 ship 前 8h 长跑无 crash、FPS ≥60、Isar IO 无 ANR、30-35 关数值再平衡完成、closed beta ~10 人反馈收齐。

## 2. 拆 Batch(并行可行性 + Claude 推占比)

| Batch | 内容 | Claude 推 | 用户办 | 估时 |
|---|---|---|---|---|
| **D1 FPS 基线** | flutter DevTools profile + 主菜单/战斗/闭关 3 场景 FPS 录基线 + Pen Windows 实机测 | 90% | Pen 跑 profile 截数据 | ~3h |
| **D2 Memory leak 锚点** | DevTools memory tab + ImageCache 监控 + Isar 长跑写入观察 + leak 候选清单 | 80% | Pen 8h 长跑挂着观察 | ~2h |
| **D3 Isar IO ANR** | 大背包(80 件)/ 多 character(20+)/ 战斗 tick 写入压测 + 慢操作锚点 + writeTxn 体积评估 | 100% | — | ~2h |
| **D4 数值再平衡 P5.2** | 30-35 关全玩家路径模拟 + 难度曲线 + 卡点/秒杀点诊断 + numbers.yaml tune | 100% | — | ~4-5h xhigh |
| **D5 8h 长跑** | 自动化挂机脚本(战斗 + 闭关 + 奇遇 cycle)+ leak/FPS 录制 + crash 报告 | 70% | 用户机器跑 8h | ~2h spec + 8h 跑 |
| **D6 closed beta 表单** | Google Forms 结构化(难度评分 / 数值 bug / 流程卡点 / 通关时长 / 体验综合)+ 反馈收集分析模板 | 100% | 10 人组织 + 派表单 | ~1h |

**总 Claude 推:~14-15h · 用户操作:Pen profile 跑 + 8h 长跑机器 + closed beta 10 人**

## 3. 决策点(Phase 0 拍)

| # | 问题 | 推荐默认 | 影响 |
|---|------|---------|------|
| D-Q1 | FPS 目标:Steam 最低配几代 GPU? | **GTX 1060 / Iris Xe(2017+ 集显)** | profile 机器选型 |
| D-Q2 | Isar 大背包压测阈值:60 / 100 / 200 件? | **100 件**(Demo 80 件 + 1.0 buffer) | D3 测试 fixture seed |
| D-Q3 | 数值再平衡范围:30 关全 / 章末 6 关 / 全玩家路径模拟器? | **全玩家路径模拟器**(P5.2 spec 锚) | D4 工作量 ×3 |
| D-Q4 | closed beta 渠道:Discord 私邀 / itch.io 内测 / Steam Demo? | **Steam Demo Playtest**(F 段同步)| 与 F 段绑定 lead time |
| D-Q5 | 8h 长跑断点续测?fixed 8h 单次 / 4h+4h / 24h pass | **fixed 8h 单次**(crash 概率最高场景) | D5 自动化复杂度 |

## 4. 子任务粒度(可立即派单)

- **D1.1**:`tools/perf_profile.dart` 起 + DevTools 接入指南(Pen)→ 1 commit
- **D1.2**:3 场景 FPS 录(主菜单 / 战斗 stage_03_03 / 闭关 retreat_zhongnan)→ baseline.json
- **D2.1**:ImageCache 监控 widget(debug only)+ 80 件装备 icon 加载锚点
- **D2.2**:Pen 8h 挂机后 memory snapshot 对比 → leak 候选清单 doc
- **D3.1**:`isar_io_stress_test.dart` 80 件背包 + 20 character + 100 tick 写入压测
- **D3.2**:writeTxn 体积红线测试(Phase 0 grep `writeTxn` 大块)
- **D4.1**:`tools/balance_simulator.dart` 全 30 关玩家路径(rng × 50 seed)→ 难度曲线 csv
- **D4.2**:卡点 / 秒杀点诊断 + numbers.yaml 微调 + R5 红线测族不破
- **D5.1**:`tools/idle_long_run.dart` 8h 自动化脚本(战斗 / 闭关 / 奇遇 cycle)
- **D6.1**:Google Forms 模板 + 反馈分析 spreadsheet 结构 + 10 人邀请文案

## 5. 红线 / 风险

- **不破现有 1519 测族**(每 Batch 收尾 verify · feedback_verification_before_completion)
- **8h 长跑测试机器选型**:Pen Windows(用户主力)vs Mac Opus 端(只有 Flutter Mac build,不发布)→ **Pen 优先**
- **数值再平衡红线**:GDD §5.4(普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000)不破
- **closed beta 反馈**主观性强,建议结构化打分 + 自由文本双轨,避免回收数据失锚
- **D4 数值再平衡是 1.0 release 最大不确定性**:全玩家路径模拟器若发现章末 Boss 概率秒杀玩家,需 stages.yaml 大改 → 预留 xhigh 2 batch buffer

## 6. 验收

- [ ] D1 FPS 平均 ≥60 @ GTX 1060 / Iris Xe(主菜单 / 战斗 / 闭关 3 场景)
- [ ] D2 8h 长跑 memory 增长 < 100MB(无 leak 锚点)
- [ ] D3 Isar IO 100 件背包 + 20 character + 100 tick 无 ANR(主线程 < 16ms / frame)
- [ ] D4 全 30-35 关玩家路径模拟 通关率 [60%, 85%](难度曲线合理)
- [ ] D5 8h 长跑 0 crash + crash 报告自动化收集
- [ ] D6 closed beta ~10 人反馈回收 ≥7 份(70%+)+ 高优 bug 闭环

## 7. 依赖 / 阻塞关系

- D6 closed beta 依赖 F 段 Steam Demo Playtest 上架(F-D 串行,F 优先)
- D4 数值再平衡 独立于其他段(并行 OK)
- D5 8h 长跑依赖 D2 leak 锚点先清(防止已知 leak 影响 crash 诊断)
- E 音频 / G 法律 不阻塞 D 段(完全并行)

## 8. closeout / 验收 doc

- 每 Batch 完成后:`docs/handoff/m15_d_<batch>_closeout_<date>.md` ≤80 行
- 最终段:`docs/handoff/m15_d_full_closeout_<date>.md` ≤80 行 + CHECKLIST §D 6/6 全勾 + PROGRESS 顶段对齐
