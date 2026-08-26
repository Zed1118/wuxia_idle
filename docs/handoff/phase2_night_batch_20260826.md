# 二阶段候选夜批交接（2026-08-26 02:00–05:00）

调度=Claude / 执行=codex 单端串行 / 基线 `c799b964`（main `e292d3a0` 的严格后代，676:0，merge-tree 干净 = 纯 FF）

## 当前完成

| 单 | commit | 产出 | 执行端自报 | 协调者复核后 |
|---|---|---|---|---|
| B 仅测试引用文件分档 | `e2a0ba7c` | 13 行表 | WIRED0/VALID2/PARKED11/EXCL0 | **全过**：13 文件 lib 引用方均 0（模式已自校验）、9 个决策 ID 全命中、消费方行号精确 |
| A0 视觉路由映射 | `2363af37` | 35 行映射 | EXISTING11/NAV-ONLY24/MISSING0 | **全过**：11 枚举名全命中、analyze 0 issue、仅动 1 doc |
| A1 四条真实导航链 | `0008fc3b` | 22 行 + 18 图 | PASS18/FAIL0/SKIP4 | **改判 PASS16/FAIL2**：抓出徽章截断漏判 |
| A2 T2+T3 直达矩阵 | `017f3936` | 48 行 + 46 图 | PASS0/FAIL46/SKIP2 | **部分采信**，见下 |

尺寸/存在性机械核对：64 张图全部 2560×1440 / 2880×1800，无空文件、无尺寸不符。

## A2 复核分歧（不采信其全 FAIL 结论）

- **溢出列（46 行 PASS）可信**：抽验 tower_floor_list 等，无 RenderFlex 黄黑条、无文字裁切。
- **鼠标列（46/46 FAIL）不可证伪**：macOS 截图不含 cursor，证据包无任何 cursor 证据；静态查得 `SystemMouseCursors` 19 处分布在 `wuxia_ink_button`/`plaque_button`/`wuxia_icon_button` 等共享组件，另有 64 处 InkWell（默认 clickable）。按判据应记「无法验证」而非 FAIL。
- **战斗屏 4 行 fixture 声明与像素不符**：出处表称「黑风岭生产 roster 40 敌 / 同屏 12」，`phase0a_battle_screen_1280x720.png` 实际只有 1 个「测试角色」（20000/15000 整数）、**零敌人**。以像素为真相源，该负载声明不成立。
- 键盘 / semantics 两列未独立复核（需 AX Inspector + 逐屏 Tab，时间不足）。

## 登记未修的缺陷（🔴 玩家可见 UI，等拍板）

1. **徽章文案截断**：`wuxia_ink_button.dart:417` 硬钉 `maxWidth:116` + `:427 maxLines:1`，扣 16px padding 余 100px @ fontSize10 粗体 ≈ 7–8 汉字。`strings.dart:541` 的 `主线第六章通关后开放`（10 字）渲染成「主线第六章通关…」，**两档视口都截**。调用点 `jianghu_map_screen.dart:86,:125`。该组件全仓 43 处使用；另 2 个 8 字文案卡临界，约 10 个动态 status 长度未量化。
2. **结算守卫抛异常（最高优先级，待定性）**：真打完主线 `stage_01_05` 后，`stage_entry_flow.dart:1799 _requireExactSettlementParticipant` 抛 `StateError: Combat settlement participant does not match the selected character`，胜利弹窗不出；换 sweep 路径撞同族守卫 `sweep_settlement.dart:97`。同类 fail-closed 守卫全仓 5 处。**5605 个绿测未拦住**。待定：真生产 bug，还是 seeded 存档造成的参与者不一致。
3. 战斗态无返回控件、部分列表键盘焦点环 / semantics 缺失（A2 报，我未独立复核）。

## §8.2 / §8.4 重判

① 生产路径已连接 **PARTIAL**（107/120 WIRED；11 个 PARKED 等解冻 `TUNE-POSTURE-01` / `MENTOR-INSIGHT-CORE-01` 等决策）· ② 风险匹配：test 5605 绿 + analyze 0，**视觉新增 2 个确证缺陷** · ③ 统一候选态 PASS · ④ 工作树 clean PASS（含本批 3 个新 worktree）
§8.2 ⓐⓑ PASS · ⓒ 我先前误判已撤 · ⓓ 70/676 英文 commit 沿用一次性豁免。

## 我的代拍决策（逐条备查）

- 🟡 preflight 三项阻塞豁免——实测 0 个活执行端，22/163 是 185 分支历史残留的名字启发式；执行上更严：全程单执行端、零并发
- 🟢 A1 时限 70→50 分钟、A2 按剩余自动算 111 分钟（时间账收紧）
- 🟢 A2 commit 把 `[BLOCKED]` 标在句尾而非前缀，不打回
- 🟡 A1 漏判由我复检直接修正而非返修 A1——当时 A2 已独占 GUI 且无并发额度

## 接下来（决策菜单）

| # | 决策 | 选项 | 推荐 |
|---|---|---|---|
| 1 | 候选合 main | A 现在合（纯 FF 零冲突）/ B 先修缺陷再合 / C 先定性结算异常再决定 | **C**：结算异常若是生产 bug，合进去等于把「打赢看不到胜利」带上主干 |
| 2 | 徽章截断 | A 放宽 maxWidth / B 缩短文案 / C 允许 2 行 | **A**：文案已在 strings.dart 统一，改组件一处收全部 43 个使用点 |
| 3 | 结算异常定性 | A 派只读复现单 / B 下轮我亲自查 / C 挂 BACKLOG | **A**：给 codex 一张最小复现单，比读代码猜快 |
| 4 | 鼠标 / 键盘 / semantics | A 重验（需 AX Inspector 手动）/ B 按「无法验证」记账 | **B**：截图承载不了 cursor，重验要换手段，不值当补 |

## 环境快照

main `e292d3a0` 未动 · 候选 `c799b964` · 本批分支 `codex/p2-b-testonly-classification-20260826`、`codex/p2-a-visual-acceptance-20260826`、`coordinator/p2-night-handoff-20260826` · 未 push（`--allow-push no`）· 证据图 `~/Desktop/挂机武侠视觉验收-20260826/`（64 张，不进 git）· 派单包在 job tmp `dispatch/`
