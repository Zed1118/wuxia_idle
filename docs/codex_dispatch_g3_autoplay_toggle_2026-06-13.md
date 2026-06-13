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
