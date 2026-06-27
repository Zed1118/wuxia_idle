# AGENTS.md

> **本文件已瘦身为 stub(2026-06-13)。操作层单一真相源 = [`CLAUDE.md`](./CLAUDE.md);设计层真相源 = [`GDD.md`](./GDD.md)。**
> 历史完整版(v1.1 / 2026-05-29 快照)随 git 历史可溯。瘦身原因:双份大文档持续漂移(AGENTS.md 一度停在 Demo 阶段口径,与已进入 1.0 长线打磨期的 CLAUDE/GDD/PROGRESS 冲突),根治 = 只维护一份。

## 一句话

买断制、写实武侠挂机游戏(发布目标 Windows,开发/验收在 macOS)。Flutter Desktop,3v3 自动战斗 + 离线挂机。当前阶段:**1.0 长线打磨期**(质量优先,不设上线时间压力 · 详 CLAUDE.md §7 / GDD §1)。

## 当前协作模式(2026-06-27 起)

- **Mac 单端**:Claude Code(Opus)写 `lib/` / `data/`(数值 yaml + narratives/lore/events 文案)/ `test/` / `GDD.md`。读 **CLAUDE.md**。
- **Codex(Mac 本地)**:可作为主窗口调度/规划/视觉验收入口;长任务按 **CLAUDE.md §8.0 可恢复任务协议** 执行(主窗口调度 + 独立分支/worktree + 小切片 commit + 恢复点)。
- Windows DeepSeek 端 + `WINDOWS_DEEPSEEK_GUIDE.md` 已退役(归档 `docs/_archive/`)。

## 核心红线(完整版见 CLAUDE.md §5 / GDD §2.1 §5)

- **反主流不做**:体力 / 每日任务 / 登录奖励 / 战令 / 抽卡 / VIP / 装备分解 / 留存焦虑通知。
- **数值红线**:普伤 ≤8,000 / 大招暴击 <十万 / 玩家血 ≤20,000 / Boss 血 <1M / 内力 ≤15,000 / 装备攻击 ≤2,000。
- **三系锁死**:境界 ↔ 装备阶 ↔ 心法阶 一一对应,低境界不可用高阶装备/心法(师承遗物不例外)。
- **不硬编码**:Dart 代码不写中文文案(走 data/narratives,lore,events)、不写数值常量(走 data/*.yaml)。
- **在线 = 离线**:不做挂机加速/快进券/在线 buff。
- **水墨克制基调**:不用 Material 默认饱和色;不写教程弹窗(用剧情/气泡/百科)。

## 拿不准时

查 GDD(§1 快速索引定位)→ 查 CLAUDE.md §12 / GDD §12 待决清单 → 查既有 yaml/同类 feature 模式 → **仍不清楚停下来问人类**。不自作主张是这个项目最重要的纪律。
