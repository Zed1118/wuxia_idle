# P1.1 候选 5 CLAUDE.md §12 表述对齐 closeout(2026-05-21)

> Mac+Opus xhigh ~20min(audit 10min + Edit 6 处 5min + closeout/commit 5min)
> **HEAD**:`d98d972` → 收尾 `<本 commit>`,与 origin 同步
> **测试基线**:1172 pass(不动,纯 markdown)/ analyze n/a / saveVersion 0.12.0
> P1.1 加权 4/4 ✅ + 文档对齐 ✅ → **P1.1 全收口完成**

## §1 一句话总结

候选 2/3 实装后 CLAUDE.md §12 待决清单状态对齐 — `enabled_when_alive` flip 反转 #11 表述 + #9 补 battle 实装注 + 顺手扫掉 2 处过时文件路径,顶部 v1.9 摘要 1 行。**0 代码改 / 0 yaml 改 / 0 test 改**。

## §2 6 处 Edit 清单

| # | 位置 | 改动 | 触发 |
|---|---|---|---|
| 1 | 顶部 v1.8 上 | 加 v1.9 变更摘要 | 状态对齐元说明 |
| 2 | §12.1 末尾备注行 | 删 #11 项目,只留 #12 | 候选 2 激活,#11 不再 Demo 不实装 |
| 3 | §12.2 #11 | 反转表述「Demo 不实装」→「P1.1 候选 2 已激活,方案 E.5.A,玩家=祖师自享 sect_wide_buff」+ 数值 + Phase 5+ 切换语义 + 实装文件指路 | 候选 2 commit `a0eae82` |
| 4 | §12.2 #9 | 末尾追加「v1.9 补:候选 3-b commit `15ff8aa` 已实装 battle 释放路径 + battle_ai 优先级 + 红线 27,421」 | 候选 3-b commit `15ff8aa` |
| 5 | §12.2 #1 | 文件路径 `lib/data/enum_localizations.dart:39,78` → `lib/features/battle/domain/enum_localizations.dart`(行号 `RealmLayer.qiMeng:42 / dengFeng:48` + `CultivationLayer.wuXia:96 / jiJing:97`) | grep 验文件已迁,旧路径失效 |
| 6 | §12.2 #6 | 文件路径 `encounter_hook.dart:50` → `encounter_service.dart:216`(公式实装) + `encounter_def.dart:162`(schema 注释) | grep 验公式实际在 service,hook 只有注释 |

## §3 余 §12.2 9 条无 drift

#2 / #3 / #4 / #5 / #7 / #8 / #10 / #12 / #13 抽查表述与 yaml/代码一致(其中 #10 师承遗物 4 子项 `transfer_trigger=ascend_to_wusheng` 仍是 Phase 5+ 飞升触发,候选 1 收徒不涉飞升,表述准确)。

## §4 红线点检

- 顶部 v1.1-v1.8 历史摘要全保留(v1.9 prepend),不删历史
- §12.1「未决项 → 无」结论保持(v1.5 全收口仍成立)
- 规则层(三系锁死 / 数值红线 / 不硬编码)0 改动
- 文件 GDD 索引 / §5-§11 任何章节未动

## §5 P1.1 全收口里程碑

| 候选 | 内容 | commit | 日期 |
|---|---|---|---|
| 1 | A1 E.1 收徒弹窗 | `86618f1` | 2026-05-21 早 |
| 2 | A1 E.5 祖师爷 buff | `a0eae82` | 2026-05-21 早 |
| 3 | A3 共鸣度满级体验(4 子) | `3cb9918`/`15ff8aa`/`9e54cf9`/`225ee8e` | 2026-05-21 午 |
| 4 | A4 开锋 build 内容扩 | `d98d972` | 2026-05-21 晚 |
| **5** | **CLAUDE.md §12 表述对齐** | **本 commit** | **2026-05-21 晚** |

P1.1 系统纵深加权 4/4 ✅ + 文档对齐 ✅ → P1.1 阶段正式 close。

## §6 下一步候选(下次会话)

| # | 任务 | 模型 | 备注 |
|---|---|---|---|
| **6** ⭐ | Demo §8.4 stage_audit 复跑 | opus | 25min,P1.1 全完成后审 1.0 路线图位置 + 与 2026-05-20 版对照变化 |
| 7 | M4 #46 Stage 3 美术量产决策 | opus 拍板 + 用户产 MJ | Stage 2 W1-W6 收官 74 张,Stage 3 是否继续 / 切哪个题材 |
| 8 | 切下一个 1.0 路线图模块 | TBD | 主线 / 师徒升级 / 武学领悟内容扩 / 闭关地图扩,候选 6 stage_audit 后拍板 |

**推荐**:候选 6 起手(纯 audit doc,opus 25min 短任务),拍板下一阶段重点。

## §7 教训 sink

| # | 教训 | memory 落点 |
|---|---|---|
| 1 | 候选间 yaml flip + 字段实装后,CLAUDE.md §12 表述要顺手同步更新,不要堆到「下波统一对齐」(会忘 + drift 越积越多) | 未独立 sink(本 + memory `feedback_phase0_grep_two_axes` A.5 子格已锚) |
| 2 | §12.2 引用代码文件行号是 stale 高发区(W1-W18 重构过多次),周期 audit(每 P0.x / P1.x 收口时)抽查一遍 | 未独立 sink(可考虑总结) |

---

**closeout 完结**。P1.1 阶段 4 候选 + 1 文档对齐全收口 ✅。
