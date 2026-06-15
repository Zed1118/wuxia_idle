# 过夜自主工作交接 — 2026-06-15 晨检

> 用户睡前指令:升 xhigh · 自主规划任务/优化 · **全部工作在 worktree** · **不合并** · 晨起检查。
> 本 doc = morning review 索引(主 checkout 未追踪文件)。main 仍 = origin/main(`58ed0005`,无任何功能代码合入)。

## 交付总览(3 项,均未合并)

| # | 内容 | 位置 | 状态 | 类型 |
|---|---|---|---|---|
| 1 | **L3 闭关非阻塞 + 出战锁 + 题字过场 + 快捷键** | worktree `seclusion-nonblocking`(分支 `worktree-seclusion-nonblocking`,7 commit) | analyze 0 / 全量 **2190 测**+1skip / 零回归 | 功能实装 |
| 2 | **M2 离线收益汇总 设计 spec** | `docs/spec/2026-06-15-m2-offline-recap-design-DRAFT.md`(未追踪) | 待你拍板范围 | 规划(未实装) |
| 3 | **2 项安全清理** | worktree `polish-cleanups`(分支 `worktree-polish-cleanups`,1 commit) | analyze 0 / 全量 **2183 测**+1skip / 零回归 | 优化 |

## 1. seclusion-nonblocking(L3,可合并单元)
brainstorm→spec→plan→subagent-driven(7 task,每 task 实装+审查通过)。**用户原诉求**「闭关被困界面/想做装备不想战斗」。调研发现闭关技术上已非阻塞,真缺口=无返回出口+未锁战斗。实装:闭关屏返回按钮 + 主菜单常驻横幅 + 4 战斗入口(主线/爬塔/群战/轻功)出战锁(弹窗+提前出关按已挂时长发奖)+ 开始题字过场 + Esc/Enter 快捷键。0 改 numbers.yaml/schema/红线。closeout 在该 worktree `docs/sessions/2026-06-15_seclusion_nonblocking_closeout.md`。
- **待拍板**:心魔(inner demon)入口也是战斗但未锁(用户确认范围是 4 个,心魔范围外)——要不要一并锁?
- **合并方式**:review 后 `git merge worktree-seclusion-nonblocking`(已含 PROGRESS 续9 + UX 表 L3)。注:seclusion 的 spec/plan 文档已先 push 到 main(58ed0005)。

## 2. M2 设计 spec(需你决策)
Phase 0 诊断关键:**离线产出机制根本不存在**(lastOnlineAt 死字段)、唯一挂机路径=闭关(按时长结算)、无金币概念。spec 框定两范围:
- **范围 A(推荐,安全,不碰红线)**:重开时若闭关有进展/已满,弹欢迎回来卡 + 引导收功。用现有 RetreatSession,无 schema 改,无 §5.5 风险。
- **范围 B(红线相邻)**:真·通用被动离线挂机 + 累计总额字段——4 个待拍板(是否真发放/未闭关算不算/用哪地图/累计字段用途),需单独立项 + 数值平衡审。
- **晨起 3 问**:M2 选 A 还是 B?A 的话 lastOnlineAt 要不要补写入点?B 要的话确认单独立项。

## 3. polish-cleanups(低风险优化)
代码质量审计(只读)结论:代码库整体很干净(无死码/无 extension 硬编码/无确凿 bug)。仅 2 项 🟢 安全清理已实装:① 爆品「轻触继续」迁 UiStrings(§5.6 合规)② lineage 合并逐字重复的 `_absLabel`→`_pctLabel`(输出不变)。审计另记 1 项 🟡(item_slot.dart:24 lockText 默认值)留你定。

## 备注
- 未做 M2 实装/L1 全屏:M2 触红线需拍范围;L1 依赖 window_manager 需拍板(均守「不自作主张」纪律)。
- 全部 worktree 用 ExitWorktree keep 保留;合并/丢弃由你定。无孤儿分支外的临时产物。
