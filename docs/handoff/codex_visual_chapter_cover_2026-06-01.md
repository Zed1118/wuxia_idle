# 章节封面视觉验收 closeout

日期：2026-06-01
对象：章节列表 6 章封面（Mac 本地，1280x720）

## 截图

- PASS `docs/handoff/codex_visual_chapter_cover_2026-06-01/01_chapter_list_top.png`：落地顶部截图，Ch1-3 可见。
- PASS `docs/handoff/codex_visual_chapter_cover_2026-06-01/02_chapter_list_scroll.png`：下滚到底截图，Ch4-6 可见。

## 验收门

1. PASS 每章卡顶部均有约 96px 水墨封面条，横幅裁切正常。
2. FAIL 6 章封面互不相同；Ch1 桃花春、Ch2 客栈街、Ch3 木擂台、Ch4 边关城楼、Ch6 道观石碑基本对应；Ch5 实际横幅更像城墙/山水远景，未明确呈现“戈壁路”。
3. PASS 锁章封面已调暗；Ch1 解锁全亮，Ch2-6 灰暗并显示锁状态。
4. PASS 封面整体低饱和墨调，无油画/卡通/高饱和问题。
5. PASS 1280x720 布局未见 overflow/RenderFlex，标题与状态显示正常。

## 日志

- PASS 已等到 `VISUAL_ROUTE_READY: chapter_list`。
- PASS 日志未见 `exception` / `overflow` / `RenderFlex`。

总判：FAIL（仅因 Ch5 题材对应不达标；其余门通过）。
