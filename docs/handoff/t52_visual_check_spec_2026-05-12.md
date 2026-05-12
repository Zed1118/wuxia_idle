# T52 · 闭关 5 张地图视觉验收（Pen Windows 物理机）

- **日期**：2026-05-12 派单 / Pen 执行日期待定（明天物理机）
- **执行方**：Pen + Windows RDP 桌面（不能 SSH，需登 GUI）
- **分支**：feat/phase3-seclusion @ 3431ac4
- **关联**：PROGRESS.md「当前阻塞」/ 挂账 #25/#26/#28；外部审查 P1 #2 + P2 #3
- **截图归档**：`docs/screenshots/phase3_w3_seclusion/`（新建）

通过后即可 merge feat/phase3-seclusion → main → tag `v0.3.0-w3`。

---

## 0. 环境准备（Pen 物理机 RDP 内）

```powershell
cd F:\Projects\wuxia_idle
git fetch
git checkout feat/phase3-seclusion
git pull
git log --oneline -3
# 应看到:
#   3431ac4 docs: PROGRESS 清外部审查（#21 归档 + 新挂账 #26/#27/#28）
#   a7960d7 fix: 闭关导航链多余 pop 误弹 result 屏（清外部审查 P2 #3）
#   b23a1d6 fix: 统一磨剑石/心血结晶 defId 为 item_* 体系（清外部审查 P1 #2）
```

跑基线确认：

```powershell
"F:\Flutter SDK\flutter_windows_3.41.5-stable\flutter\bin\flutter" analyze
"F:\Flutter SDK\flutter_windows_3.41.5-stable\flutter\bin\flutter" test
```

期望：analyze 0 issues / 493 tests pass。任一失败立刻报回，停止验收。

**清开发态存档**（不清的话旧 'mojianshi' 行残留会让场景 C 失真）：

```powershell
# 关闭已开的游戏进程后
del "$env:APPDATA\wuxia_idle\wuxia_save_slot1.isar"
del "$env:APPDATA\wuxia_idle\wuxia_save_slot1.isar.lock"
# 或者更稳：清整个目录
rmdir /s /q "$env:APPDATA\wuxia_idle"
```
（Demo 阶段开发态可接受，不写 migration）

启动：

```powershell
"F:\Flutter SDK\flutter_windows_3.41.5-stable\flutter\bin\flutter" run -d windows
```

---

## 场景 A · 基础走查（闭关入口 + 5 张地图）

**前置**：进游戏直接到主菜单。

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| A1 | 主菜单点「闭关修炼」 | 进入闭关地图列表屏 | `01_main_menu.jpg` |
| A2 | 看 5 张地图卡片 | 山林（可进）/ 古剑冢（locked 三流）/ 藏经阁（locked 二流）/ 悬崖瀑布（locked 一流）/ 断崖绝壁（locked 宗师）；locked 卡片灰底+「需…境界」提示 | `02_map_list.jpg` |
| A3 | 点古剑冢（locked）| **不**导航，底部 SnackBar 提示「需三流境界」 | 不截 |
| A4 | 点山林 | 进入 SeclusionSetupScreen | `03_setup_shanlin.jpg` |
| A5 | setup 屏看产出预览 | 「每小时预估产出（境界加成 ×1.00）」+ 磨剑石/经验数值 + 兵器掉率/心法领悟/内力增长 % bonus 行 | A4 同图 |
| A6 | 3 档时长按钮 | 显示 1h / 4h / 8h（按 numbers.yaml durationHours），默认选中 4h | A4 同图 |
| A7 | 返回主菜单（左上箭头） | 回主菜单 | 不截 |

**A 通过条件**：A2 / A4 / A5 / A6 三截图清晰显示对应内容。

---

## 场景 B · 完整收功流程（P2 #3 导航链清账重点）

**前置**：先到主菜单点「Phase 2 调试场景」→ 跑「P3 散功代价」种子（解决挂账 #25：P1 fixture 无主修不影响闭关，但留个种子让 character 有内力数值）。

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| B1 | 主菜单 → 闭关修炼 → 山林 → 选 1h | 进 setup 屏，时长按钮高亮 1h | `04_setup_1h.jpg` |
| B2 | 点「开始闭关」 | **导航换屏到 ActiveRetreatScreen**（不是回到 list！）| `05_active_in_progress.jpg` |
| B3 | active 屏检查 | 地图名「山林」、开始时间、预计结束时间（开始 +1h）、进度条 0%、「提前收功」按钮 | B2 同图 |
| B4 | **直接点「提前收功」** | 弹 confirm dialog「确认提前收功？」 | `06_active_confirm.jpg` |
| B5 | confirm dialog 点「确认」 | 跑完 completeRetreat → **导航换屏到 RetreatResultScreen** | `07_result.jpg` |
| B6 | result 屏 | 显示磨剑石数量（>0）/ 经验（如有）/ 装备掉落（如有）/「返回」按钮 | B5 同图 |
| B7 | **点「返回」** | **回到闭关地图列表屏**（不是回到主菜单！）| `08_back_to_list.jpg` |
| B8 | list 屏检查 | 顶部 banner 已消失（active session 已收）；山林卡片不再标 active 标签 | B7 同图 |

**B 通过条件（核心）**：
- B2 / B5 / B7 三次换屏**没有屏闪/瞬间回退**
- B7 返回**精确停在 list 屏**（如果停在主菜单，说明 result 用了 popUntil 把 list 也弹了 → 修复未生效）
- B8 list 自动刷新（banner 消失，山林卡片状态归位）

**B 不通过的可能症状**：
1. B5 点确认后 result 一闪而过直接回 list / 主菜单 → setup 末尾 `nav.pop(true)` 修复未生效
2. B7 点返回直接到主菜单 → result 还在用 popUntil
3. B8 list 不刷新（banner 还在 / 卡片还显示 active）→ pushReplacement chain 没把 true 传回 list

任一症状立刻报回，停止继续。

---

## 场景 C · 磨剑石 defId 不分裂（P1 #2 清账重点）

**前置**：场景 B 已完成（闭关一次产出磨剑石写入 InventoryItem）。

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| C1 | 主菜单 → Phase 2 调试场景 → 点「P3 散功代价」再跑一次种子 | 种子写入 `defId='item_mojianshi'` 1500 颗 | 不截 |
| C2 | 主菜单 → 闭关修炼 → 山林 → 4h → 开始 | 进 active 屏 | 不截 |
| C3 | 点提前收功 → 确认 → result | result 显示磨剑石数量（设 N 颗）| `09_result_C.jpg` |
| C4 | 返回 list → 主菜单 → 仓库（character/inventory 入口）→ 点「强化」打开 enhance_dialog | enhance_dialog 顶部「持有磨剑石」数字应为 **1500 + N**（不是 1500 也不是单独 N，**而是 merge 后总和**）| `10_enhance_mojianshi.jpg` |
| C5 | 截图 enhance_dialog 数字 | 确认数字 = 1500 + 收功 N | C4 同图 |

**C 通过条件**：C4 显示数字是 1500 + N。
**C 不通过症状**：显示 1500 或显示 N（其中一个被覆盖/隐藏）→ defId 仍分裂，inventoryItems 表存在多行同 ItemType，`inventoryQuantityByType.findFirst` 只读到其中一行。

如果 C 没通过，请 Pen 在 RDP 里跑：

```powershell
cd F:\Projects\wuxia_idle
"F:\Flutter SDK\flutter_windows_3.41.5-stable\flutter\bin\flutter" test test/services/seclusion_service_test.dart
```

把输出贴回报给我。

---

## 场景 D · 闭关时长 8h（边界 + 子时加成）（可选）

时间够再做，不阻塞 merge。

| 步骤 | 操作 | 期望 |
|---|---|---|
| D1 | 闭关 → 山林 → 选 8h → 开始 | active 屏开始时间记录正确 |
| D2 | 立即提前收功 | result 显示磨剑石按 0 小时算（接近 0）|
| D3 | 重启游戏，看 list banner | 没 active session 时 banner 不显示 |

不通过不阻塞，记录症状即可。

---

## 截图归档

```
docs/screenshots/phase3_w3_seclusion/
├── 01_main_menu.jpg
├── 02_map_list.jpg
├── 03_setup_shanlin.jpg
├── 04_setup_1h.jpg
├── 05_active_in_progress.jpg
├── 06_active_confirm.jpg
├── 07_result.jpg
├── 08_back_to_list.jpg
├── 09_result_C.jpg
└── 10_enhance_mojianshi.jpg
```

Pen 全跑完后 git add docs/screenshots/phase3_w3_seclusion/ 一并 commit：

```
docs: T52 闭关视觉验收 10 截图（P1 #2 + P2 #3 清账验收通过）
```

---

## 通过判定 & 反馈

**全通过**：场景 A + B + C 全打钩，10 张截图归档完成。
→ Pen 在群里回「T52 通过」，Mac 端我会执行 merge feat/phase3-seclusion → main → tag v0.3.0-w3。

**部分通过/不通过**：
- 哪个场景哪一步失败，附 RDP 截图或录屏
- 终端贴 `flutter analyze` / `flutter test` 完整输出
- 别自己 fix，等 Mac 端复现

**反馈格式**：

```
T52 验收结果：
- 环境基线：[OK / 失败原因]
- 场景 A 基础走查：[通过 / 失败 step + 症状]
- 场景 B 收功导航：[通过 / 失败 step + 症状]
- 场景 C defId 不分裂：[通过 / 失败 step + 数字]
- 截图归档：[完成 / 缺哪几张]
```

---

## 已知预设与挂账提示

- **挂账 #25**：场景 B/C 都需要先跑 Phase 2 P3 种子（不种 character 没主修 + 没磨剑石基线，C 场景测不出 merge）
- **挂账 #26**：主菜单闭关入口硬编码 character=1 / xueTu，本次验收范围内不影响（场景全用学徒 + 山林）；后续 Phase 4 fixture 改造时一并处理
- **挂账 #28**：闭关 widget 端到端 test 缺失，这次 T52 是临时的人工兜底，Phase 5 service 注入后补自动化
