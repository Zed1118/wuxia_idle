# T58 · 师徒系统视觉验收（Pen Windows 物理机）

- **日期**：2026-05-13 派单 / Pen 执行日期待定
- **执行方**：Pen + Windows RDP 桌面（不能 SSH，需登 GUI）
- **分支 / commit**：main @ `ea13704`
- **关联**：PROGRESS.md「当前阶段」/ phase3_summary.md Week 4 段 / Week 4 T53-T57 已落地
- **截图归档**：`docs/screenshots/phase3_w4/`（已建空目录）

通过后 Mac 端 commit summary T58 行打勾 + tag `v0.3.0-w4` push origin。

---

## 0. 环境准备（Pen 物理机 RDP 内）

```powershell
cd F:\Projects\wuxia_idle
git fetch
git checkout main
git pull
git log --oneline -3
# 应看到:
#   ea13704 docs(summary): phase3_summary Week 4 段（T53-T58）+ T55 教训复盘
#   88014eb feat(combat): [T57] 3v3 师徒集成测试 + T55 战斗路径 lineage buff 补齐
#   e698190 feat(ui): [T56] 角色面板「师承」段 + Tab 三角色切换 + 销账 #26
```

跑基线确认：

```powershell
"F:\Flutter SDK\flutter_windows_3.41.5-stable\flutter\bin\flutter" analyze
"F:\Flutter SDK\flutter_windows_3.41.5-stable\flutter\bin\flutter" test
```

期望：analyze 0 issues / 529 tests pass。任一失败立刻报回，停止验收。

**清开发态存档**（activeCharacterIds 从 1 个变 3 个可能触发字段长度差异，保险清）：

```powershell
# 关闭已开的游戏进程后
rmdir /s /q "$env:APPDATA\wuxia_idle"
# 或者只删 slot 文件
del "$env:APPDATA\wuxia_idle\wuxia_save_slot1.isar"
del "$env:APPDATA\wuxia_idle\wuxia_save_slot1.isar.lock"
```

启动：

```powershell
"F:\Flutter SDK\flutter_windows_3.41.5-stable\flutter\bin\flutter" run -d windows
```

---

## 场景 A · P5 师徒种子 + 主菜单入口

**前置**：进游戏直接到主菜单（首次启动后 SaveData 空）。

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| A1 | 主菜单点「Phase 2 调试场景」| 进入 Phase2TestMenu，5 场景按钮 P1/P2/P3/P4/**P5** 全可见 | `01_phase2_menu_with_p5.jpg` |
| A2 | 点「P5 师徒系统」 | SnackBar「P5 种子写入完成」+ 自动跳转 CharacterPanelScreen（祖师视角默认）| 不截 |
| A3 | 返回主菜单 | 主菜单 8 按钮全部可见，闭关按钮**不灰**（说明 SaveData 已 ready）| `02_main_menu_after_p5.jpg` |

**A 通过条件**：A1 / A3 两截图清晰显示对应内容。

---

## 场景 B · 角色面板 Tab 三角色切换 + 师承段（T56 核心）

**前置**：场景 A 已完成（P5 种子已 seed，3 师徒入阵）。

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| B1 | 主菜单点「角色面板」| 进入 CharacterPanelScreen，**顶部 3 个 Tab**：[祖师*] [大弟子] [二弟子]，祖师高亮 | `03_panel_founder.jpg` |
| B2 | 祖师 Tab 内容检查 | 姓名（祖师名）/ 境界（一流·启蒙）/ 流派色条 / 4 属性 / 派生数值「内力 X / Y（Y 应含 +10% lineage buff）」/ 武器+护甲槽显示 +N 强化 / 主修高亮 | B1 同图 |
| B3 | 师承段（页面底部）| **师父**：— 或 无 / **徒弟**：大弟子名 / 二弟子名 / **传记**：[传记待补] / **遗物**：龙泉剑 / 锦袍 | B1 同图（如不在一屏，单独截 `04_panel_lineage_section.jpg`）|
| B4 | 点「大弟子」Tab | **切到大弟子内容**：姓名变更、境界二流、装备数值不同、师承段「师父」变成祖师名、「徒弟」变成 — 或 无、遗物 — 或 无 | `05_panel_first_disciple.jpg` |
| B5 | 点「二弟子」Tab | 切到二弟子（三流），师父=祖师名 | `06_panel_second_disciple.jpg` |
| B6 | 返回主菜单 | 回主菜单 | 不截 |

**B 通过条件**：B1 / B4 / B5 三次切换 Tab 后**姓名/境界/装备数值都跟着变**，祖师内力上限**>** 大/二弟子相对 base 比（含 +10% buff）。

**B 不通过的可能症状**：
1. Tab 点击没反应 → state 切换有 bug
2. 切换后内容不变（仍显示祖师）→ _selectedCharacterId state 没 setState
3. 师承段全显示「无」/「—」→ masterId/discipleIds 未正确读

---

## 场景 C · 主线 stage_01_01 3 师徒同阵 victory（T57 核心）

**前置**：场景 A 已完成（SaveData.activeCharacterIds=[1,2,3]）。

| 步骤 | 操作 | 期望 | 截图 |
|---|---|---|---|
| C1 | 主菜单点「主线」→ 第 1 章「学武出山」→ 关卡列表 | stage_01_01「山道试剑」可挑战 | 不截 |
| C2 | 点 stage_01_01 → 看 opening 剧情 → 点「完成」 | 进战斗屏 | 不截 |
| C3 | 战斗屏顶部 | **左队 3 个角色头像**（祖师 + 大弟子 + 二弟子）/ 右队 3 个流民 | `07_battle_3v3_open.jpg` |
| C4 | 等待战斗自动结束（境界压制必胜，5-15 秒）| Victory log + 右队 3 个流民全死 + 左队至少 1 个存活 | `08_battle_3v3_victory.jpg` |
| C5 | 点「完成」→ victory narrative → 关卡列表 | stage_01_01 显示已通关 ✓ | 不截 |

**C 通过条件**：C3 / C4 两截图清晰显示 3v3 同阵 + victory 状态。

**C 不通过的可能症状**：
1. 左队只有 1 个或 2 个角色 → buildTeams 装配链 bug（应 3 个）
2. 战斗一开始就 defeat → 主修招式没装配（StateError）
3. 战斗 maxTicks 兜底 draw → BattleEngine 不收敛（不应发生）

---

## 截图归档

```
docs/screenshots/phase3_w4/
├── 01_phase2_menu_with_p5.jpg
├── 02_main_menu_after_p5.jpg
├── 03_panel_founder.jpg
├── 04_panel_lineage_section.jpg  (可选，B3 一屏放不下时)
├── 05_panel_first_disciple.jpg
├── 06_panel_second_disciple.jpg
├── 07_battle_3v3_open.jpg
└── 08_battle_3v3_victory.jpg
```

Pen 全跑完后 git add docs/screenshots/phase3_w4/ 一并 commit：

```
docs: T58 师徒系统视觉验收 ≥7 截图（Week 4 收尾）
```

---

## 通过判定 & 反馈

**全通过**：场景 A + B + C 全打钩，≥ 7 张截图归档完成。
→ Pen 在群里回「T58 通过」，Mac 端我会 update summary T58 行 ✅ + tag `v0.3.0-w4` push origin。

**部分通过/不通过**：
- 哪个场景哪一步失败，附 RDP 截图或录屏
- 终端贴 `flutter analyze` / `flutter test` 完整输出
- 别自己 fix，等 Mac 端复现

**反馈格式**：

```
T58 验收结果：
- 环境基线：[OK / 失败原因]
- 场景 A P5 种子：[通过 / 失败 step + 症状]
- 场景 B 角色面板 Tab：[通过 / 失败 step + 症状]
- 场景 C 3v3 同阵 victory：[通过 / 失败 step + 症状]
- 截图归档：[完成 / 缺哪几张]
```

---

## 已知预设与挂账提示

- **#25 / #26 已销账**：T54/T56 销账，场景 A/C 走 P5 路径正好验证销账后行为
- **挂账 #28**：闭关 widget 端到端 test 缺失，本次不验闭关 → 与 T58 无关
- **挂账 #30**：闭关 3 维度扩展未接 service（technique_learn_rate / internal_force_growth / 节气日 / 子时阳刚），本次不验 → 与 T58 无关
- **schema 不升版**：saveVersion 仍 0.4.0，理论上不必清存档；保险起见清 SaveData 防字段长度差异
