# Codex 视觉验收派单:周目进化(P1 E3)

验收点:主线选关周目选择控件 + 爬塔「挑战下一轮回」入口。
分支 `p1-cycle-evolution`(未合 main)。验收包 = `tool/build_acceptance.sh` 产出(hub 总入口)。

## 验收包

```
open "/Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/p1-cycle-evolution/build/macos/Build/Products/Debug/wuxia_idle.app"
```

窗口拉 **1280×720**。开屏是「验收总入口」hub,点路由按钮进屏,左上返回切下一个。

---

## 路由 1:`stage_list_cycle`(主线选关·周目选择验收)

hub 里点 **`stage_list_cycle`**(说明含「周目选择验收」)。进入主线章一选关屏,seed:01_01..04 均已 cycle1 通关。

逐项截图 + 结论:

1. **周目选择控件出现**:01_01..04 四个已通关关卡,除原有内容外,每个 tile 在原「重打」入口区域显示「周目选择控件」(CycleSelectControl)。未通关/锁定关**无**此控件。截 `stage_list_cycle_01_initial_tiles.png`。
2. **「第1周目(自动)」选项可见**:周目选择控件内含「第1周目」条目,副标记为「(自动)」或「自动」。点击触发 cycle=1 战斗(自动跑)。截 `stage_list_cycle_02_cycle1_auto_label.png`。
3. **「挑战第2周目(手动)」选项可见**:控件内含「挑战第2周目」条目,副标记为「(手动)」或「手动」。此项为 cycle+1 挑战入口。截 `stage_list_cycle_03_cycle2_manual_label.png`。
4. **点「挑战第2周目」进入战斗**:点击该选项跳转战斗屏,战斗以 cycle=2 半手动/手动模式启动。截进入战斗后 `stage_list_cycle_04_battle_entered.png`。
5. **江湖记招提示 banner 出现**:战斗屏顶部或中央出现提示 banner,文字包含「此敌已识得你的路数」或类似「江湖记招」提示文案。截 `stage_list_cycle_05_jianghu_hint_banner.png`。
6. **720p 布局不溢出**:tile 内同时有「自动战斗」开关行(StageAutoPlayControl)和「周目选择」控件(CycleSelectControl)两行,在 1280×720 下未见内容溢出/叠压/截断。截 `stage_list_cycle_06_720p_layout_no_overflow.png`。

---

## 路由 2:`tower_cycle`(爬塔·问鼎轮回验收)

hub 里点 **`tower_cycle`**(说明含「问鼎轮回验收」)。进入爬塔列表屏,seed:30 层 cycle1 全部通关(maxClearedCycle=1)。

逐项截图 + 结论:

7. **当前轮回标记可见**:爬塔列表顶部或标题区显示当前处于「第1轮回」或类似标记,明确当前周目编号。截 `tower_cycle_01_current_cycle_label.png`。
8. **30 层全显「已通关」**:列表中 1..30 层均显示 ✓ 绿勾或「已通关」态,无「可挑战」或「锁定」层。截 `tower_cycle_02_all_floors_cleared.png`。
9. **「挑战下一轮回」入口出现**:列表底部或固定区域出现「挑战下一轮回」按钮/入口(因 maxClearedCycle>=currentCycleIndex=1 且 currentCycleIndex<maxCycleTower)。截 `tower_cycle_03_next_cycle_entry.png`。
10. **点击「挑战下一轮回」生效**:点击该入口触发 advanceCycle,currentCycleIndex 变为 2,列表标记更新为「第2轮回」并重置 30 层进度(1..30 层回到未通关态)。截点击后 `tower_cycle_04_after_advance.png`。

---

## 关注质量点

- **720p 双控件布局**:stage_list_cycle 的 tile 同时放 StageAutoPlayControl + CycleSelectControl,注意是否竖向挤压或字号过小。
- **周目选项文案清晰度**:「第1周目(自动)」/「挑战第2周目(手动)」两项语义上要可区分(1=重打已有记录自动 / 2=新挑战手动)。
- **江湖记招 banner 位置**:banner 是否遮挡战斗主区域或过于显眼(首次出现强调即可,持续遮盖是问题)。
- **轮回入口 tap 区域**:1280×720 下「挑战下一轮回」按钮是否够大、不被列表 scrim 盖住。

---

## 已知非 bug(别记 FAIL)

- **cycle scale 差异细微**:cycle 2 敌人强度仅比 cycle 1 高约 +6%/cycle,视觉上未必一眼看出「更难」——难度体现主要来自词条(御体防御↑/反震内伤/识破蓄力技/凝甲暴击减半/真气多放招),这些是战斗内部属性,不会在选关屏或爬塔列表 UI 上以 badge 形式显示。Codex 只验控件出现即可,不验伤害数值。
- **30 层 seed 跑 30 次 recordClear**:towerCycle route 顺序调用 recordClear 30 次(通过 TowerProgressService),启动时有约 1-2 秒 seed 延迟,属正常——看到 loading spinner 后等待即可。
- **stage_list_cycle 自动战斗开关灰显**:若 01_03/01_04 无重放记录(seed 未种),开关仍会灰显——本路由 seed 走 seedVisualCheckW7W11,未额外种重放记录,此灰显属正常(与 stage_list_autoplay route 的设计一致)。验收重点是「周目选择控件」出现,非自动开关状态。

---

## 验收流程说明

本 doc 仅覆盖视觉/交互验收(Codex 闭环)。Claude 闸门工作(flutter analyze / 红线压测 F1 / 合 main)单独进行,不在本派单范围内。

结论回填本 doc「逐项结论」段(沿 R2 体例:每项 PASS/FAIL + 截图名)。

---

## 逐项结论

Codex 视觉/交互验收回填(2026-06-14, macOS app,窗口 1280×720):

1. PASS — `stage_list_cycle_01_initial_tiles.png`。01_01/01_02 首屏可见周目选择控件;补充滚动检查 `stage_list_cycle_01_initial_tiles_lower_check.png` 确认 01_03/01_04 也有同控件,未通关 01_05 仅显示「可挑战」且无周目控件。
2. PASS — `stage_list_cycle_02_cycle1_auto_label.png`。控件内「第1周目」可见,右侧副标记「(自动)」清晰。
3. PASS — `stage_list_cycle_03_cycle2_manual_label.png`。控件内「挑战第2周目」可见,右侧副标记「(手动)」清晰,与第1周目语义可区分。
4. PASS — `stage_list_cycle_04_battle_entered.png`。点击「挑战第2周目」后经剧情过场进入 3v3 战斗屏,底部为半手动操作区。
5. PASS — `stage_list_cycle_05_jianghu_hint_banner.png`。战斗屏顶部出现「此敌已识得你的路数,见招拆招。」提示,为窄条展示,未遮挡主战斗区或底部操作区。
6. PASS — `stage_list_cycle_06_720p_layout_no_overflow.png`。1280×720 下 tile 同时放「自动战斗」行与两行周目选择控件,未见溢出、叠压、截断或字号过小。
7. PASS — `tower_cycle_01_current_cycle_label.png`。爬塔顶部显示「当前:第1轮回」。
8. PASS — `tower_cycle_02_all_floors_cleared.png`。顶部概览 1..30 层均为绿色已通关态,统计为「已通 30 / 30 层」,可见列表卡片也为勾选已通关态。
9. PASS — `tower_cycle_03_next_cycle_entry.png`。顶部固定提示区出现「已通 30 层,可挑战下一轮回」与右侧「挑战下一轮回」入口,tap 区域未被遮挡。
10. PASS — `tower_cycle_04_after_advance.png`。点击后标记更新为「当前:第2轮回」,统计变为「已通 0 / 30 层」,列表重置为第1层可挑战、后续层锁定/未通关态。
