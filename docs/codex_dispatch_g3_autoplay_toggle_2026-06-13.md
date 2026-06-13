# Codex 视觉验收派单:选关屏 per-stage 自动/手动开关(步骤5-G3)

验收点:已通关关卡可逐关切「自动/手动」战斗,三态(跟随全局 / 自动 / 手动)。
分支 `worktree-g3-autoplay-toggle-ui`(未合 main)。验收包 = `tool/build_acceptance.sh` 产出(hub 总入口)。

## 验收包

```
open "/Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/g3-autoplay-toggle-ui/build/macos/Build/Products/Debug/wuxia_idle.app"
```

窗口拉 **1280×720**(沿 R2 教训,默认窗太小易溢出/误判)。开屏是「验收总入口」hub,点路由按钮进屏,左上返回切下一个。

## 路由 1:`stage_list_autoplay`(主屏验收)

hub 里点 **`stage_list_autoplay`**(说明含「per-stage 自动/手动开关」)。这是主线章一选关屏,seed:01_01..04 已通关。

逐项截图 + 结论:

1. **已通关 tile 显开关**:01_01..04 四个已通关关卡,每个副标题(敌数)下方有一行小开关(图标 + 文字 + 下拉箭头)。未通关/锁定关**无**此行。
2. **01_01 = 跟随态**:显示「🤖 自动」+ 灰色小字「随设置」(override=null,跟随全局默认 true)。
3. **01_02 = pin 手动态**:显示「✋ 手动」**无**「随设置」(已 pin override=false)。
4. **01_03 / 01_04 = 灰显锁定**:这俩已通关但无重放记录(迁移豁免态),开关灰显、无下拉箭头;hover 出 tooltip「重打一次记录后可切换」。
5. **点开三选项菜单**:点 01_01 的开关,弹出菜单含三项「跟随设置 / 自动战斗 / 手动战斗」,水墨/原生菜单在 1280×720 下不溢出、可读。
6. **选项切换生效**:菜单选「手动战斗」→ 01_01 行变「✋ 手动」(落库 + 重渲染)。再点选「跟随设置」→ 回「🤖 自动 随设置」。

## 路由 2:`tower_floor_list`(爬塔 dialog 验收)

hub 点 **`tower_floor_list`**。爬塔 plaque 固定高,开关走**已通关层重打确认 dialog**:

7. 点一个**已通关**(✓ 绿勾)楼层 → 弹「重打」确认 dialog,dialog 内除正文外有一行「战斗方式」+ 开关。开关交互同上(三选项菜单)。dialog 不溢出、层级正常。

## 关注质量点

- 开关那行在 720p 下是否与 tile 其他元素挤/溢出(尤其 Boss 关名长 + 「精英」标 同行时)。
- 「随设置」弱标记是否够弱(不喧宾夺主)又可辨。
- 图标(smart_toy 自动 / touch_app 手动)语义是否直观,或建议换更武侠的表达。

## 已知非 bug(别记 FAIL)

- 01_03/01_04 灰显 = 设计(无 record 无从写 override,迁移豁免关本就走 autoFallback)。
- 群战屏 toggle 选「自动」实际走 autoFallback 非确定性 replay(formation 未入 seed),属已知降级,本验收不涉及。

结论回填本 doc「逐项结论」段(沿 R2 体例:每项 PASS/FAIL + 截图名)。

## 逐项结论

1. **PASS** — `stage_list_autoplay_01_initial_tiles.png` / `stage_list_autoplay_02_tiles_04_locked.png`  
   01_01..04 已通关 tile 均在敌数副标题下显示开关行；01_05 未通关只显示「可挑战」，无开关行。

2. **PASS** — `stage_list_autoplay_01_initial_tiles.png`  
   01_01 显示自动图标 +「自动」+ 弱灰「随设置」+ 下拉箭头，跟随全局默认态清楚。

3. **PASS** — `stage_list_autoplay_01_initial_tiles.png`  
   01_02 显示手动图标 +「手动」+ 下拉箭头，未显示「随设置」。

4. **PASS** — `stage_list_autoplay_02_tiles_04_locked.png` / `stage_list_autoplay_05_hover_tooltip_mousemove_retry.png`  
   01_03/01_04 开关灰显且无下拉箭头；用真实 mouseMoved hover 后出现 tooltip「重打一次记录后可切换」。

5. **PASS** — `stage_list_autoplay_06_menu_01_01.png`  
   点击 01_01 开关弹出三选项菜单，含「跟随设置 / 自动战斗 / 手动战斗」，1280×720 下不溢出且可读。

6. **PASS** — `stage_list_autoplay_07_01_01_manual_selected.png` / `stage_list_autoplay_08_01_01_follow_restored.png`  
   选择「手动战斗」后 01_01 变为「手动」；再选「跟随设置」后恢复「自动」+「随设置」。

7. **FAIL** — `tower_floor_list_03_replay_dialog.png` / `tower_floor_list_06_dialog_menu_final_retry.png`  
   点击已通关 17 层可弹「已通关」重打 dialog，dialog 居中不溢出，且有「战斗方式」+「自动」行；但多次点击该行/图标/文字均未弹出「跟随设置 / 自动战斗 / 手动战斗」三选项菜单。

## 额外视觉判断

- smart_toy / touch_app 图标语义直观，但偏现代工具感；更武侠的替代表达可考虑「书册/令牌」表示自动规则，「手印/指令」表示手动接管，或直接用小篆化「自 / 手」印章图标。
- 「随设置」弱标记处理合适：灰度足够低，不抢主状态「自动」，但在 720p 下仍可辨。
- 720p 下开关行未挤压 tile 内容；01_04 Boss 长名 + Boss 标记 + 开关行同屏可读，未见溢出。

---

## R1 #7 FAIL 定责(Claude · 非代码 bug)

第 7 项 FAIL 根因 = **验收 route 种子缺口,不是代码 bug**。证据:
- `tower_floor_list` route 只种 founding masters,**未种任何 tower 重放记录** → 已通关层 dialog 内 toggle 命中 `hasRecord=false` 的**迁移豁免禁用态**(渲染为 Tooltip 包裹的灰显「自动」,**不是 PopupMenuButton**,故点击无反应)。
- 复看 `tower_floor_list_03_replay_dialog.png`:「战斗方式 自动」**无下拉箭头、无「随设置」、灰显** = 正是禁用态(与主线 01_03/01_04 灰显态同源,你已 PASS 那两项)。
- 新增单测「enabled toggle 嵌 AlertDialog 内 → 点击照常弹三选项菜单」**通过**,证 PopupMenuButton 在 dialog 上下文工作正常。

**修复**:新增验收 route `tower_floor_list_autoplay`(种 1/2 层通关 + 重放记录)。提交 `c55d98cd`。

## R2 复验(只重验第 7 项 · 用新 route)

hub 里点 **`tower_floor_list_autoplay`**(说明含「per-floor 自动/手动开关」)。窗口 1280×720。

**注意**:塔列表自动滚到当前层(第 3 层置顶),已通关的 **1/2 层在视图上方,需向上滚**才能点到。

7'. 向上滚到 **第 1 层**(✓ 已通关)→ 点它 → 弹「已通关」重打 dialog,dialog 内「战斗方式」行应是 **enabled** 态:「自动」+ 灰字「随设置」+ **下拉箭头**。点该开关 → 弹「跟随设置 / 自动战斗 / 手动战斗」三选项菜单。
8'. 向上滚到 **第 2 层**(✓ 已通关)→ 点它 → dialog 内开关为「手动」(pin 态,无「随设置」)+ 下拉箭头,点击同样弹三选项菜单。

回填 PASS/FAIL + 截图名。其余 1-6 项已 PASS 不必重验。
