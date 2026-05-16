# W15 victory dialog round2 visual check closeout

## 1. 结论

本轮 hotfix 后视觉验收 **6 PASS / 1 WARN / 0 FAIL**。

#34 第 2 UI 缺口本批闭环:主线 A1/B1 与塔 C1 都拿到 3 行升层 banner,drop banner 已显示中文「磨剑石 ×N」,未再出现 `item_mojianshi ×N`。物料 Tab D2 累积态也收齐,起步 100 磨剑石累积到 104。

唯一 WARN:第一次增量 `flutter build windows --debug` 后 GUI 仍像旧产物,VC15-fresh 主修显示「未修主修」。执行 `flutter clean` + 重新 debug build 后 fixture 正常,祖师主修显示「入门功」并可进入战斗。

## 2. 环境与启动记录

- 工作目录: `F:\Projects\wuxia_idle`
- `git pull --rebase --autostash`: fast-forward `0ea4311..d6509ec`
- HEAD: `d6509ec`
- `dart run build_runner build --delete-conflicting-outputs`: 通过；当前 build_runner 提示该参数已移除并忽略
- `flutter build windows --debug`: 通过
- 增量 build 后发现旧 GUI 行为,执行 `flutter clean` + `flutter build windows --debug`: 通过
- 启动前清档: `$env:APPDATA\wuxia_idle`
- GUI: 成功启动；本机窗口实际约 `1280 x 720`,用滚动访问第 11 按钮
- VC15-fresh seed: clean rebuild 后生效,祖师主修「入门功」,不再报「未修主修」
- Flutter build 产生的 generated plugin 副产物已 `git restore`

## 3. 截图清单与评级

| 编号 | 文件 | 评级 | 说明 |
|---|---|---:|---|
| seed | `docs/screenshots/w15_victory_dialog_round2/seed_precheck_vc15_fresh_main_technique_r2.png` | PASS | 祖师 `学徒·启蒙`,内力 `500/500`,主修「入门功」,经验 `0/100`。 |
| A1 | `docs/screenshots/w15_victory_dialog_round2/A1_mainline_01_01_dialog_localized.png` | PASS | 「山门之外 · 战斗胜利」;掉落含「粗布衣」「磨剑石 ×1」;3 角色突破至「学徒入门」;继续按钮可见。 |
| A2 | `docs/screenshots/w15_victory_dialog_round2/A2_mainline_01_01_narrative_after_dialog.png` | PASS | 关闭 dialog 后进入 `山门之外 · 终` narrative,链路不破。 |
| B1 | `docs/screenshots/w15_victory_dialog_round2/B1_mainline_01_02_dialog_advancement.png` | PASS | 「荒山野店 · 战斗胜利」;掉落「磨剑石 ×2」;3 角色突破至「学徒熟练」。 |
| C1 | `docs/screenshots/w15_victory_dialog_round2/C1_tower_floor1_firstclear_advancement.png` | PASS | 塔第 1 层首通;奖励「磨剑石 ×1」;3 角色突破至「学徒精通」;确定按钮可见。 |
| D1 | `docs/screenshots/w15_victory_dialog_round2/D1_inventory_material_tab_fresh.png` | PASS | 沿第 1 跑截图:起步态 2 组,`磨剑石 ×100` / `心血结晶 ×10`,reserved enum 不显示。 |
| D2 | `docs/screenshots/w15_victory_dialog_round2/D2_inventory_material_tab_accumulated.png` | PASS | 累积态 `磨剑石 ×104`,`心血结晶 ×10`,排序仍为磨剑石 -> 心血结晶,无 reserved enum 空组。 |
| E | 未收 | 未验 | 部分角色升层边界不是本轮强制项。 |

## 4. 视觉层反馈

- A1/B1/C1 drop banner 均为中文物料名:「磨剑石 ×1 / ×2 / ×1」,没有 `item_mojianshi ×N`。
- A1/B1/C1 升层 banner 均为 3 行,每行带 auto-awesome 图标与角色名。
- 升层结果随经验推进为:学徒入门 -> 学徒熟练 -> 学徒精通。
- D1/D2 物料 Tab 分组排序稳定,只显示磨剑石和心血结晶两组。
- D1/D2 行右侧仍显示 `item_mojianshi` / `item_xinxuejiejing` defId,但主行文本和本轮明确验收点均通过；建议后续如要更克制可隐藏右侧调试 id。

## 5. 节奏层反馈

- VC15-fresh -> 角色面板 -> 主线 stage_01_01 战斗链路已通。
- A1 dialog 点击「继续」后进入胜利 narrative,A2 验证通过。
- A2 后触发一次奇遇 `渡客问道`,说明 dialog -> narrative -> encounter hook 链路可运行；点掉后不影响继续 stage_01_02。
- B1 后可返回主菜单进入问鼎九霄。
- 塔第 1 层首通后弹 C1 dialog,点击「确定」回到塔列表。
- 装备仓库 TabBar 切到「物料」正常,D2 累积数量可见。

## 6. 工程教训

- 本轮 hotfix 源码已包含 `seedVisualCheckW15Fresh()` 给 3 角色各学 1 个 tier 0 主修心法,但第一次增量 debug build 启动后 GUI 仍呈旧行为。`flutter clean` 后重建解决。
- Windows 视觉验收若遇到“源码已改但 GUI 仍旧”的情况,优先清理 Flutter build 产物再重建,比继续点 UI 更省时间。
- 本机窗口高度无法达到派单建议的 1400,实际约 720；第 11 按钮可通过滚动可靠定位。
- PowerShell profile/Clixml 噪声在本机会污染命令输出,但不影响 Flutter build 成功与截图产出。
- `flutter build windows --debug` / `flutter clean` 会改 generated plugin 文件,本轮 closeout 前已恢复。

## 7. 下次推荐

- #34 victory dialog round2 可由 Mac 端按本 closeout 与 6 张截图验收闭环。
- 物料 Tab 若未来要完全避免 `item_*` 出现在用户界面,建议隐藏每行右侧 defId 或改为仅 debug 模式显示；本轮不阻断。
- 后续 Windows 端复验建议直接 `flutter clean` 后 build,避免命中旧 debug 产物。
