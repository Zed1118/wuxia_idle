# Codex 视觉验收派单 · 章节页封面

**项目**：挂机武侠（Mac 本地 · 非 Pen）
**验收对象**：章节列表 6 章封面接线 + MJ 水墨封面（commit `06df1a1`）
**日期**：2026-06-01

## 已编译 app（直接跑，勿 checkout/build）

```
/Users/a10506/Desktop/Projects/挂机武侠/build/macos/Build/Products/Debug/wuxia_idle.app
```

`VISUAL_ROUTE=chapter_list` 已编译入。启动即 seed + 直落**章节列表**，无需导航。
就绪信号：`VISUAL_ROUTE_READY: chapter_list`（debug build；首启 seed ~10-20s，等 READY 再截图）。
本地已自验 READY 正常、0 exception。

## 截图清单（2 张）

存 `docs/handoff/codex_visual_chapter_cover_2026-06-01/`（PNG 不入库）：
1. `01_chapter_list_top.png` — 落地即截（Ch1-3 卡顶部封面条）
2. `02_chapter_list_scroll.png` — 下滚到底（Ch4-6 卡封面条）

## 验收门（逐条 PASS/FAIL）

1. **每章卡顶部有水墨封面条**（约 96px 高横幅 · BoxFit.cover）。
2. **6 章封面各不同 + 题材对应**：Ch1 桃花春 / Ch2 客栈街 / Ch3 木擂台 / Ch4 边关城楼 / Ch5 戈壁路 / Ch6 道观石碑。
3. **锁章封面调暗**（未解锁章 opacity 0.35 灰暗 · 解锁章全亮）。
4. **封面水墨克制**（低饱和墨调，无高饱和/油画/卡通；与游戏水墨基调一致）。
5. **布局不破**：1280×720 无 overflow / RenderFlex；卡片标题+状态正常；日志 0 exception。

任一 FAIL 记现象 + 截图。

## closeout

写 `docs/handoff/codex_visual_chapter_cover_2026-06-01.md`（≤30 行）：2 截图 PASS/FAIL + 5 验收门逐条 + 日志异常 + 总判。
