# 1.0 整体进度全谱审查 · 2026-05-24

> 阶段性 milestone 级审查(非日常 stage_audit · 体量放宽 ≤120 行)
> 基线:main HEAD `0ac60a8` · 1340 pass / 0 analyze · GDD v1.15 · ROADMAP_1_0.md v1.2
> 起点锚:2026-05-17 1.0 路线图 launched(8 天 / 249 commit)

## TL;DR

1.0 实际进度 **~65%**(原计划 16 个月,实际 8 天压缩)· P0+P1.1+P1.3+P2 全 + P3.1+P3.2 全 + P3.3/P3.4 ~50% · **P4-P5 是上线流程性工作未启**(社交/翻译/教程/音乐/Steam 集成,有固定 lead time)· **核心可玩内容深度 ~85%** 早超 Demo §8.4 量级。下波最大 ROI:P1.2 实装(解 P1 100%)、P3.3 Phase 4-5、P3.4 Batch 2.3-2.5。

## 1. P0-P5 全谱状态

| Phase | 计划 | 实际 | 完成度 |
|---|---|---|---|
| **P0** strategy 重构 + #38 maxHp | M1-M2 | ✅ 2026-05-17 4 项销账 | 100% |
| **P1.1** A 类(收徒/共鸣/开锋/祖师 buff)| M2-M4 | ✅ 2026-05-21 5 候选全收口 | 100% |
| **P1.2** §12 江湖恩怨 + 声望 | M2-M4 | 🟡 Phase 0 ✅ + spec PR #6 OPEN · Phase 2-5 未开 | 15% |
| **P1.3** 美术 PoC + LoRA Stage 0-3 | M2-M4 | ✅ 89+74+22 张 ship | 100% |
| **P1.4** DeepSeek 产能压测 | M2-M4 | 🔴 v1.8 退役(Mac+Opus 单端接管)| N/A |
| **P2.1** §12.4 第二条主线 Ch4-Ch6 | M5-M10 | ✅ 三章弧 ~18,318 字 · 师父三句遗言 + 物理遗物全闭环 | 100% |
| **P2.2** §12.1 心魔系统 | M5-M10 | ✅ Batch 2.1-2.5 + 镜像 cap 维度纠正 | 100% |
| **P2.3** §7.1 飞升 + 遗物 transfer | M5-M10 | ✅ Batch 3.1-3.3 + **P5+ 多代+真传位提前 ship** | 100%+ |
| **P3.1** §12.3 轻功对决 | M10-M12 | ✅ Batch 2.1-2.4 + P3.1.B damage_multiplier | 100% |
| **P3.2** §12.3 群战守城 | M10-M12 | ✅ Batch 2.1-2.5 + 残血/sentinel 双修 | 100% |
| **P3.3** §12.3 PVP 异步 | M10-M12 | 🟡 Phase 1 spec + Phase 2 schema(T11)+ Phase 3 logic(T13)· Phase 4-5 待 | ~50% |
| **P3.4** §12.1 门派事件 | M10-M12 | 🟡 Phase 1 spec + Batch 2.1 schema(T12)+ 2.2 service(T14)· 2.3-2.5 待 | ~50% |
| **P4.1** §12.2 帮派门派 | M12-M14 | 🔴 无 spec | 0% |
| **P4.2** §12.4 翻译(可选英文)| M12-M14 | 🔴 未启 | 0% |
| **P5.1-3** 教程审计 / 难度曲线 / 音乐音效 | M15-M16 | 🔴 未启 | 0% |
| **P5.4-6** Steam 集成 / 时长校准 / 上线 | M15-M16 | 🔴 未启 | 0% |

**§12 决议表 12 项全纳入 1.0**(0 留 2.0)· GDD §12.1 真硬阻塞已清零。

## 2. 1.0 整体完成度估算

| 维度 | 权重 | 状态 | 加权 |
|---|---|---|---|
| P0 | 5% | 100% | 5% |
| P1(P1.1 ✅ / P1.2 15% / P1.3 ✅ / P1.4 N/A)| 15% | 75% | 11% |
| P2(P2.1+P2.2+P2.3+P5+ 全 ✅)| 30% | 100%+ | 30% |
| P3(P3.1+P3.2 ✅ / P3.3+P3.4 ~50%)| 25% | 75% | 19% |
| P4 | 10% | 0% | 0% |
| P5 | 15% | 0% | 0% |
| **1.0 整体** | 100% | | **~65%** |

**核心可玩深度 ~85%**(P0-P3 主流程全跑通 + 主线 3 章弧 + 心魔 + 飞升 + 轻功/群战 + PVP/Sect 半闭环)· **P4-P5 上线流程性工作有固定 lead time**(Steam 审核 / closed beta / 音乐外包),非简单百分比可压缩。

## 3. 速度数据(8 天)

| 项 | 数据 |
|---|---|
| 总 commit | 249(平均 31/天 · 高峰今日 43)|
| spec doc | 6 · handoff/closeout | 212 · feature dir | 30 · narrative | 334 |
| GDD 版本 | v1.0 → v1.15(15 次升版)|
| baseline | 1340 test / 0 analyze 持续守住 |

**spec vs 实测精度**(spec 估时系统性高估 1.5-10x):

| 模式 | ratio 范围 | 子系统锚点 |
|---|---|---|
| opus 主对话 xhigh | **0.30-0.67x** | P2.2 0.50 / P2.3 0.63 / P3.1.B 0.67 / P3.2 0.30 / P5+ 0.42 |
| opus nightshift --print | **0.07-0.18x** | T11+T12 schema 0.09 / T13+T14 logic+service 0.07 |

## 4. 工作流体系成熟度

| 工作流 | 实战次数 | 状态 |
|---|---|---|
| 主对话 opus high/xhigh 单线 | 主力,日常 | ✅ P2 全段 / P3.1/P3.2 全用 |
| 8h overnight v2(ABCDE 多批)| 2 次 | ✅ 单会话 15 批违反清理颗粒度,改 v3 修正 |
| 8h overnight v3(5 worktree 并行)| 1 次 | ✅ 4/5 PR squash + 5 reviewer agent 均分 8.9/10 |
| nightshift v2 dispatcher | 3 次 | ✅ 首跑 P0 修补 / T11-T14 真生产 / C1 §6 失败但有产出真触发 |
| Pen + Codex Windows 视觉验收 | 多次 | ✅ Mac/Windows 异步配合 |

## 5. 关键挂账 / 技术债

| # | 项 | 严重度 | 建议 |
|---|---|---|---|
| 1 | PR #6 P1.2 spec OPEN 待 merge(reviewer 4 项 fix 已落)| 中 | 用户决策 merge → 解 P1.2 Phase 2-5 |
| 2 | numbers_config 无 PvpDef/SectEventDef 强类型(raw map)| 低 | Phase 4 UI 时统一升,~30min |
| 3 | 6 旧 worktree 残留(非 PR #6 关联)| 低 | git worktree remove 5min |
| 4 | inner_demon 战斗机制层调优(R5.1 数值层 buff 单维度无效)| 中 | 1.0 P3+ 挂账,真改 mirror crit/余毒/max_ticks |
| 5 | inner_demon 7 主题 enemy 立绘异步 MJ | 中 | T03 prompt 已起,异步出图 8-12 张 + 落地 |
| 6 | P4.1 §12.2 帮派门派 0% + 无 spec | 高 | 最大未启 1.0 模块,~15-20h xhigh |
| 7 | A6 verify 反向声明 blind spot | ✅ 已 sink | memory `feedback_nightshift_v2_first_run_lessons` A6 |

## 6. 风险点

- **R1 时间线压缩超预期** — 原计划 16 个月,实际 8 天 65%。若维持速度,**Steam 上线可提前到 2026-08(M3)而非 2027-09(M16)**,但 P5 上线流程有固定 lead time(Steam 审核/closed beta/音乐外包 ≥ 3 个月)— 真上线日期受 P5 制约,**早交付 P0-P4 后空窗期可补内容/打磨**。
- **R2 跨系统数值红线未做整合 audit** — 单 feature R5 都过,但 P2.2 镜像 + P3.1 terrain + P3.2 阵型 + P3.3 ELO + P3.4 sect_level 跨系统交互未压测。**建议 1 次跨系统数值压测 ~2-3h**。
- **R3 nightshift verify 假阳性率高** — T13 fail_verify 假阳性 + v2 首跑 5/5 fail 然后 P0 修补救回。verify 严苛度 vs 产出质量是两件事(A3/A6 教训 sink)。
- **R4 PROGRESS 99 行卡上限** — 每加顶段必砍同等。可考虑 PROGRESS 自动归档脚本(P2 工具挂账)。

## 7. 下波推荐(按 ROI)

| 优先 | 任务 | 估时 | 解锁 |
|---|---|---|---|
| ★★★ | **PR #6 merge → P1.2 Phase 2-5 实装** | nightshift ~45min | P1 100% |
| ★★★ | **P3.3 Phase 4 UI + Phase 5 narrative + closeout** | nightshift ~30min | P3.3 100% |
| ★★★ | **P3.4 Batch 2.3 战斗联动 + 2.4 UI + 2.5 R5** | nightshift ~30min | P3.4 100% |
| ★★ | numbers_config 升 PvpDef/SectEventDef 强类型 | 主对话 ~30min | clean code |
| ★★ | 跨系统数值红线压测 audit(R2)| ~2-3h | 整体 sanity |
| ★ | P4.1 §12.2 帮派门派 spec 起草 | ~1h spec + ~15-20h 实装 | P4 启动 |
| ★ | 6 旧 worktree 清理 | ~5min | 磁盘/git 噪声 |

3 个 ★★★ 合并跑 ~2h nightshift 一波,可在下一个 1-2h 窗内 cover 完 → **1.0 整体跃升 65% → ~80%**。

---

**审查结论**:1.0 实际推进速度远超原计划 16 个月时间表,P0-P3 主体 + P5+ 提前部分已 ship。**下半场重点**:P1.2 收口 + P3.3/P3.4 收口 + 启动 P4.1 / P5 上线流程性工作并行准备。

详 PROGRESS.md 顶段 + git log --since="2026-05-17" + ROADMAP_1_0.md。
