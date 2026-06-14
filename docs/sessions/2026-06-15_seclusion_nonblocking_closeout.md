# Closeout — L3 闭关非阻塞 + 出战锁 + 题字过场 + 快捷键

**日期:** 2026-06-15
**worktree/分支:** `seclusion-nonblocking` / `worktree-seclusion-nonblocking`(**未合并**,morning review 后合)
**方式:** brainstorm → spec → plan → subagent-driven(7 task,每 task implementer + 审查)

## 起因
用户反馈「闭关了不能退出游戏吗?必须保持界面吗?想闭关后能做装备/清仓库,只是不能战斗」。

## 调研结论(关键反转)
闭关**技术上已非阻塞**:数据实时落盘、后台计时、装备/背包/角色面板与闭关状态零耦合。真缺口:
1. 闭关进行屏 `automaticallyImplyLeading: false` → 桌面端无硬件返回 = 被困。
2. 闭关期间战斗**未被锁**(与用户预期相反)。

## 实装(0 改 numbers.yaml / schema / 红线 · 纯表现层+状态读)
| # | 内容 | 文件 |
|---|---|---|
| 1 | UiStrings 7 文案 | `lib/shared/strings.dart` |
| 2 | `activeRetreatSessionProvider` + `guardBattleEntry` | 新 `seclusion_gate.dart` |
| 3 | 主线/爬塔/群战/轻功 4 入口包守卫 | `main_menu.dart` |
| 4 | 常驻闭关横幅 `MainMenuRetreatBanner` | 新文件 + `main_menu.dart` |
| 5 | 闭关屏返回按钮 + Esc/Enter + 收功 invalidate | `active_retreat_screen.dart` |
| 6 | 开始闭关题字过场 `showSeclusionEnterCaption` | 新文件 + `seclusion_setup_screen.dart` |

## 设计决策(自主拍板,记录备查)
- 横幅形态:主菜单常驻横幅(非小浮标/仅入口显示)— 用户选。
- 出战拦截:弹提示 + 「提前出关」选项(非灰按钮)— 用户选。「提前出关」走 `completeRetreat`(按已挂时长发奖,符 §5.5),非 `abandonRetreat`(清零)。
- 题字过场只做「开始闭关」(收功侧已有 RetreatResultScreen + jingle)。
- 快捷键限闭关相关屏(不做全局 ESC,避免冲突)。

## 闸门
- 全仓 `flutter analyze`:**No issues found**
- 全量 `flutter test`:**2190 passed + 1 skipped**(基线 2183 + 7 新:gate2/banner2/exit2/caption1)零回归。

## 待办 / 风险
- **心魔(inner demon)入口未锁**:用户确认的范围是主线/爬塔/群战/轻功 4 个,心魔也是战斗但范围外,需拍板是否一并锁(Task 3 同模式多包一个 onTap 即可)。
- 题字过场 / 横幅 / 弹窗配色未真机验收:纯表现层低风险,可重编 macos 包或派 Codex 确认。
- commit 链:`5f697efa`(T1)→`a63e1439`(T2)→`bc1759d3`(T3)→`083aa7bb`(T4)→`0c436378`(T5)→`3a8bc878`(T6)+ 本 closeout/PROGRESS 续9。
