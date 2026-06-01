# Codex 视觉复验派单 · 章节页封面(Ch5 重做 + 0.5 调亮)

**项目**：挂机武侠（Mac 本地 · 非 Pen）
**复验对象**：Ch5 封面重做(黄河义渡栈桥,替换原水乡误图) + 锁章封面 0.35→0.5 调亮
**日期**：2026-06-01（接首轮 `codex_visual_chapter_cover_2026-06-01.md` 软 FAIL 复验）

## 背景(为何复验)

首轮 Codex 判 FAIL,唯一失分项是验收门 #2「Ch5 题材」。**根因:原派单门标准写错**——
拿「戈壁路」对照 Ch5,但 Ch5「第五章·征东」实际地理是 **潼关→嵩山道观→黄河义渡→
中州论剑场→嵩山论剑顶**(中原东归/论剑,非西域戈壁)。已重做 Ch5 封面为**黄河义渡栈桥**
(长木桥+雄浑远山+开阔水面,贴东归主题,与 Ch1 桃花柔美水乡拉开区分度)。本次门 #2 用正确标准复验。

## 已编译 app（直接跑,勿 checkout/build）

```
/Users/a10506/Desktop/Projects/挂机武侠/build/macos/Build/Products/Debug/wuxia_idle.app
```

`VISUAL_ROUTE=chapter_list` 已编译入。启动即 seed + 直落**章节列表**,无需导航。
就绪信号:`VISUAL_ROUTE_READY: chapter_list`(debug build;首启 seed ~10-20s,等 READY 再截图)。

## 截图清单（2 张）

存 `docs/handoff/codex_visual_chapter_cover_recheck_2026-06-01/`(PNG 不入库):
1. `01_chapter_list_top.png` — 落地即截(Ch1-3 卡顶部封面条)
2. `02_chapter_list_scroll.png` — 下滚到底(Ch4-6 卡封面条,**重点看 Ch5**)

## 验收门（逐条 PASS/FAIL）

1. **每章卡顶部有水墨封面条**(约 96px 高横幅 · BoxFit.cover)。
2. **Ch5 封面 = 黄河义渡/中州东归山水**(长桥渡口/水面/雄浑远山,水墨克制;**不是戈壁、不是西域**)。
   *(余 5 章首轮已 PASS:Ch1 桃花春/Ch2 客栈街/Ch3 木擂台/Ch4 边关城楼/Ch6 道观石碑)*
3. **Ch5 与 Ch1/Ch2 不撞型**(开阔山水渡 ≠ 桃花柔美近景 ≠ 客栈街市;区分度足够)。
4. **锁章封面调暗到 0.5**(未解锁章变暗但**仍可辨认题材**,不是糊成一团黑;解锁章全亮)。
5. **封面水墨克制**(低饱和墨调,无高饱和/油画/卡通)。
6. **布局不破**:1280×720 无 overflow/RenderFlex;卡片标题+状态正常;日志 0 exception。

任一 FAIL 记现象 + 截图。

## closeout

写 `docs/handoff/codex_visual_chapter_cover_recheck_2026-06-01.md`(≤30 行):
2 截图 PASS/FAIL + 6 验收门逐条 + 日志异常 + 总判。
