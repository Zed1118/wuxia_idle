# Codex R3 合并视觉验收派单 · P5+/P3.1/P3.2/P3.x/心魔/Ch4-6/声望

派单日期：2026-05-28
派单方：Mac Opus
范围：05-22~05-28 实装的全部新 UI,合并一次验收
HEAD：`c6b386a`（Mac = Pen 已同步）

## 背景

C.1 基础 8 项 ✅（05-26）+ C.2 sect recruit R2 ✅（05-27 刚确认）。
但 05-22~05-28 实装了 6 个新 UI 子系统从未在 Pen 端验过。本次合并跑完。

## 环境准备

```powershell
cd F:\Projects\wuxia_idle
git log --oneline -1        # 确认 HEAD = c6b386a
dart run build_runner build --delete-conflicting-outputs
flutter build windows --debug 2>&1 | Select-Object -Last 5
```

build 完后启动:
```powershell
Start-Process .\build\windows\x64\runner\Debug\wuxia_idle.exe
```

## 验收清单（4 Round · 16 验收点）

### Round 1 · P5+ 多代飞升（需 debug seed）

**准备**：主菜单 →「Phase 2 测试场景」→ 点「VC-P5+」按钮 seed → 返回主菜单 →「传承面板」

| # | 验收点 | 操作 | 必收截图 |
|---|---|---|---|
| 1.1 | 飞升按钮 enable | 传承面板 → 滚到底 →「步入飞升」按钮亮起 | `r3_01_ascension_button_enable.png` |
| 1.2 | AscensionScreen 装备选择 | 点「步入飞升」→ 装备多选(勾 1-2 件) | `r3_02_ascension_equip_pick.png` |
| 1.3 | 接任弟子下拉 | AscensionScreen → 下拉选弟子(应 ≥1 选项) | `r3_03_ascension_disciple_dropdown.png` |
| 1.4 | 确认 dialog | 点确认 →「门派衣钵:{弟子名}」dialog | `r3_04_ascension_confirm_dialog.png` |
| 1.5 | 飞升完成 snackbar | 确认后 snackbar 显传位信息 | `r3_05_ascension_snackbar.png` |

### Round 2 · 心魔 + 轻功 + 群战（主菜单直达）

**准备**：回主菜单（clean seed 即可,不需 P5+ seed）

| # | 验收点 | 操作 | 必收截图 |
|---|---|---|---|
| 2.1 | 心魔入口 | 主菜单 →「心魔试炼」→ 7 关列表(三态:cleared/available/locked) | `r3_06_inner_demon_screen.png` |
| 2.2 | 轻功入口 | 主菜单 →「轻功对决」→ 5 关列表(三态) | `r3_07_light_foot_screen.png` |
| 2.3 | 群战入口 | 主菜单 →「群战守城」→ 5 关列表(显 N 波/M 敌/阵型/难度) | `r3_08_mass_battle_screen.png` |
| 2.4 | 群战阵型选择 | 点群战任一关 → 弹出阵型选择 dialog(雁行/八卦/锋矢 3 选) | `r3_09_formation_picker_dialog.png` |
| 2.5 | 群战战斗 | 选阵型后进入战斗 → 战斗结算(左队 vs 右队 · wave 信息) | `r3_10_mass_battle_result.png`（能给则给） |

### Round 3 · Ch4-6 主线 narrative

**准备**：主菜单 →「主线章节」

| # | 验收点 | 操作 | 必收截图 |
|---|---|---|---|
| 3.1 | Ch4-6 章节入口 | 章节列表 → Ch4「西出阳关」/ Ch5 / Ch6 可见 | `r3_11_chapter_list_ch4_6.png` |
| 3.2 | Ch4 首关叙事 | 进 Ch4 第 1 关 → narrative opening 加载(非 placeholder) | `r3_12_ch4_narrative_opening.png` |
| 3.3 | Ch5 首关叙事 | 进 Ch5 第 1 关 → narrative opening 加载 | `r3_13_ch5_narrative_opening.png`（能给则给） |
| 3.4 | Ch6 首关叙事 | 进 Ch6 第 1 关 → narrative opening 加载 | `r3_14_ch6_narrative_opening.png`（能给则给） |

### Round 4 · 声望 + 门派持久

| # | 验收点 | 操作 | 必收截图 |
|---|---|---|---|
| 4.1 | 声望面板 | 主菜单 →「江湖见闻录」→ 声望/恩怨 tab 有内容(非空白) | `r3_15_reputation_panel.png` |
| 4.2 | 门派同道持久 | 角色面板 → 师承区 →「门派同道:」行(验 R2 招募后持久) | `r3_16_sect_members_persistent.png`（能给则给） |

## 截图命名

统一存 `docs\handoff\r3_visual_check_screenshots\`，文件名见各行。

## 必收 vs 能给

| 优先级 | 验收点 |
|---|---|
| **必收**（10 项） | 1.1-1.5（P5+ 飞升全流程）· 2.1-2.4（三子系统入口 + 阵型 dialog）· 3.1（章节列表） |
| **能给则给**（6 项） | 2.5（群战战斗结算）· 3.2-3.4（Ch4-6 叙事）· 4.1-4.2（声望/门派持久） |

## 硬约束

- 不动 `lib/` `test/` `data/` `GDD.md` `CLAUDE.md` `numbers.yaml`
- 不 push
- 不装新包
- 跑不通的场景保留反证截图 + closeout 标 FAIL，不伪造
- Isar 数据路径：`C:\Users\Administrator\Documents\wuxia_save_slot1.isar`
- 清库重启：删上述 `.isar` 文件 + 重启 exe

## 注意事项

1. **P5+ Round 1 必须先 seed**：用「Phase 2 测试场景」→「VC-P5+」按钮。不 seed 飞升按钮不会 enable（founder 未达 wuSheng·dengFeng）
2. **心魔/轻功/群战默认 locked**：clean seed 角色境界低,关卡全锁是预期。只需验 Screen 加载正常 + 三态 UI 不 crash
3. **群战阵型 dialog 是 05-28 新加**：之前群战走 fallback 3v3,现在应弹阵型选择
4. **Ch4-6 章节可能 locked**：clean seed 无法进关打。如果 locked 截章节列表即可,不需要打进去
5. **build 前必跑 build_runner**：`.g.dart` 文件 gitignored,fresh checkout 必须先生成

## closeout 必交

交付 `docs\handoff\pen_visual_verify_r3_consolidated_2026-05-28.md`：
- 每验收点状态（PASS / FAIL / LOCKED_EXPECTED）
- 截图路径
- 发现的问题
- 最后总结
