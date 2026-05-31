# Codex 视觉验收派单 · 角色页档案头

**项目**：挂机武侠（Mac 本地 · 非 Pen）
**验收对象**：角色页档案化（半身像档案头）· commit `549010c`
**日期**：2026-06-01

## 已编译 app（直接跑，勿 checkout/build）

```
/Users/a10506/Desktop/Projects/挂机武侠/build/macos/Build/Products/Debug/wuxia_idle.app
```

`VISUAL_ROUTE=character_panel` 已编译入此 build。**启动即自动**：`seedMasterDisciple()`（清存档 + 建祖师 id=1 + 大/二弟子，全带立绘 + 装备 + 心法）→ 直落**角色页祖师档案**，无需任何导航。

启动：`open <上面路径>` 或双击。
就绪信号：`VISUAL_ROUTE_READY: character_panel`（debug build 故有）。**首次启动会先跑 seed（清存档+建 3 角色+装备+心法），约 20-30s 才落地打 READY——等 READY 再截图,勿截早**。我已本地自验该 build:READY 正常打印,0 exception/RenderFlex。

## 截图清单（3 张）

| # | 文件名 | 操作 | 看点 |
|---|--------|------|------|
| 1 | `01_founder_profile.png` | 启动落地即截（祖师档案头） | 立绘(左 110 方墨框) + 姓名题字 + 境界·层 + **流派名文字**(刚猛/灵巧/阴柔,带流派色) + 墨色分隔 + 4 属性(根骨/悟性/身法/机缘)横排,**聚成一张档案卡** |
| 2 | `02_disciple_profile.png` | 顶部点「大弟子」Tab | 立绘**随角色变**为大弟子图 + 档案信息切换(姓名/境界/流派/属性同步) |
| 3 | `03_full_panel_scroll.png` | 档案头下方往下滚一屏 | 档案头 + 派生数值 + 装备槽(阶位色边框)整体版式连贯,无 overflow / 空框破布局 |

截图存：`docs/handoff/codex_visual_char_panel_profile_2026-06-01/`（PNG 按惯例不入库，仅 closeout.md 入库）。

## 验收门（PASS/FAIL 判据）

1. **档案卡观感**：立绘 + 姓名 + 境界 + 流派 + 4 属性视觉上是「一张人物档案」，不是表格堆叠（§5.4）。
2. **立绘存在感**：祖师/弟子立绘 110×110 清晰，流派色边框，不空框、不拉伸变形。
3. **立绘随角色变**：切 Tab 立绘 + 档案信息同步切换（截图 1 vs 2 立绘不同）。
4. **流派名补齐**：境界旁有流派文字 + 流派色点（非仅旧的纯色条无字）。
5. **布局不破**：1280×720 默认窗口无 overflow / RenderFlex；日志 0 exception/assertion。

任一 FAIL 记具体现象 + 截图，我据此修。

## closeout 模板

验收完写 `docs/handoff/codex_visual_char_panel_profile_2026-06-01.md`（≤40 行）：每张截图 PASS/FAIL + 一句观察 + 日志异常摘要 + 总判。
