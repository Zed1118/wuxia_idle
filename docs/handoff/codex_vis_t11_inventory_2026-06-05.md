# Codex 视觉自验派单：T11 仓库段头 SectionHeader 落地

日期：2026-06-05
HEAD：`a7d8697`
验收包（已编译，零编译切路由）：`build/macos/Build/Products/Debug/wuxia_idle.app`
截图目录（请新建）：`docs/handoff/codex_vis_t11_inventory_2026-06-05/`

## 背景（一句话）

UI 包装改造 v1「序 0 地基」落地后，仓库分组头由旧「竖条+label+计数(N)」试点替换为 kit 组件 `SectionHeader`（墨笔标题 + 底部 `ink_divider.png` 枯笔分隔线，**去掉计数 (N)**，对齐 demo §2 `.shead`）。本次只验这一处段头观感是否到位 + 无回归。

## 操作步骤（不要 checkout / 不要重 build，直接用已编译包）

1. 打开验收包：
   ```
   open "/Users/a10506/Desktop/Projects/挂机武侠/build/macos/Build/Products/Debug/wuxia_idle.app"
   ```
2. 窗口显示「验收总入口」(hub) → 点 **inventory** 路由按钮进屏。
3. 截全屏：`01_inventory_full.png`；再把「武器/护甲/饰品」三段头区域各截一张近景：`02_shead_weapon.png` / `03_shead_armor.png` / `04_shead_accessory.png`。
4. 左上返回 hub（如需）。

## demo ② 对照（比对基准）

```
cd "/Users/a10506/Desktop/Projects/挂机武侠/docs/handoff/ui_mockup_v1" && python3 -m http.server 8765
```
浏览器开 `http://localhost:8765/` → 滚到「② 装备仓库」。段头基准 = `.shead`：**墨笔粗体标题 + 字距加宽(letter-spacing 2) + 底部一道枯笔墨分隔线**，标题后**无计数数字**。

## 验收门（逐条判 PASS/WARN/FAIL）

| # | 门 | 判据 |
|---|---|---|
| 1 | 段头样式对齐 demo ② | 武器/护甲/饰品三段头 = 墨笔粗体标题 + 底部枯笔墨分隔线；字距宽 |
| 2 | 计数已去除 | 段头标题后**无** `(N)` 之类数字后缀 |
| 3 | 枯笔分隔线真实加载 | 分隔线是 `ink_divider.png` 枯笔质感，**非**退化的一条细直墨线（细直线=资产没加载到，需标 WARN） |
| 4 | 无回归 | 1280×720 无 RenderFlex overflow 黄黑条；格子 detail 图正常 contain；强化朱印/境界封条灰化/师承标仍在；无缺图占位 |

## closeout 要求

验收完在本文件追加「## 结论」段：总判（PASS/WARN/FAIL）+ 逐门对照表 + 截图清单。截图存上面截图目录。如有 WARN/FAIL 附一句根因猜测。

## 结论

总判：**FAIL**。计数去除与无回归通过，但仓库段头未达到 demo ② `.shead` 的视觉目标：标题在深色底上接近不可读，分隔线呈规则双直线，不是 `ink_divider.png` 的枯笔墨迹观感。

| # | 门 | 判定 | 备注 |
|---|---|---|---|
| 1 | 段头样式对齐 demo ② | FAIL | 武器/护甲/饰品三段标题均存在，但标题过暗；底部分隔线为规则双浅色直线，未呈现 demo 的枯笔墨分隔线。 |
| 2 | 计数已去除 | PASS | 三段头标题后未见 `(N)` 或数字后缀。 |
| 3 | 枯笔分隔线真实加载 | WARN | 画面表现更像退化直线而非 `ink_divider.png` 枯笔质感；根因猜测：资产未接入/未命中，或被拉伸/着色后退化成直线。 |
| 4 | 无回归 | PASS | 1280×720 未见 RenderFlex overflow 黄黑条；格子 detail 图正常 contain；强化朱印、境界锁灰化、师承星标仍在；未见缺图占位。 |

截图清单：

- `docs/handoff/codex_vis_t11_inventory_2026-06-05/01_inventory_full.png`
- `docs/handoff/codex_vis_t11_inventory_2026-06-05/02_shead_weapon.png`
- `docs/handoff/codex_vis_t11_inventory_2026-06-05/03_shead_armor.png`
- `docs/handoff/codex_vis_t11_inventory_2026-06-05/04_shead_accessory.png`
