# Codex R4 视觉验收派单 · P2.1 内容扩充 + 装备 drop 全覆盖

派单日期：2026-05-28
派单方：Mac Opus
范围：P2.1 4 批内容扩充(装备 80 / 心法 49 / 技能 166 / lore 80 / 相生 12)+ 装备 drop 全覆盖(56 条 dropTable · 77 件主线装备)
HEAD：`e5bb9ba`（Mac = Pen 已同步 · debug exe 已 build）

## 背景

C.1-C.3 前三轮验收全 PASS。本轮验 P2.1 内容扩充后的数据量能否正常加载 + 装备掉落 UI 显示。

## 环境准备

exe 已 build，直接启动：
```powershell
cd F:\Projects\wuxia_idle
git log --oneline -1        # 确认 HEAD = e5bb9ba
Start-Process .\build\windows\x64\runner\Debug\wuxia_idle.exe
```

如果 HEAD 不对：
```powershell
git fetch origin
git reset --hard origin/main
dart run build_runner build --delete-conflicting-outputs
flutter build windows --debug 2>&1 | Select-Object -Last 5
Start-Process .\build\windows\x64\runner\Debug\wuxia_idle.exe
```

## 验收清单（3 Round · 12 验收点）

### Round 1 · 数据加载 + 装备/心法总量（需 VC18-A1 seed）

**准备**：主菜单 →「Phase 2 调试场景」→ 点「VC18-A1 · 心法相生 5 组合视觉验收预设」按钮 seed → 返回主菜单

| # | 验收点 | 操作 | 预期 | 必收截图 |
|---|---|---|---|---|
| 1.1 | 启动无 crash | 主菜单加载完成 | 主菜单标题「挂机武侠 · 调试主菜单」可见 | `r4_01_main_menu_loaded.png` |
| 1.2 | 装备仓库 80 件加载 | 主菜单 →「装备仓库」| 列表可滚动 · 无 crash · 装备名为中文(非 defId) | `r4_02_equipment_inventory.png` |
| 1.3 | 心法面板加载 | 主菜单 →「心法面板」| 心法列表可见 · 含「主修」/「辅修」标签 | `r4_03_technique_panel.png` |
| 1.4 | 角色面板相生 chip | 主菜单 →「角色面板」→ 任一角色 | 角色卡片含「相生」chip(蓝绿色) | `r4_04_synergy_chip.png` |

### Round 2 · 装备掉落验收（需 clean Isar + fresh seed）

**准备**：
1. 关闭 exe
2. 删除 Isar 文件清档：`Remove-Item "C:\Users\Administrator\Documents\wuxia_save_slot1.isar" -Force -ErrorAction SilentlyContinue; Remove-Item "C:\Users\Administrator\Documents\wuxia_save_slot1.isar.lock" -Force -ErrorAction SilentlyContinue`
3. 重启 exe：`Start-Process .\build\windows\x64\runner\Debug\wuxia_idle.exe`
4. 进入后点「直入江湖」跳过引导
5. 主菜单 →「Phase 2 调试场景」→「VC · W7-W11 视觉验收预设」seed
6. 返回主菜单 →「主线章节」→ Ch1「学武出山」→ stage_01_01「山门之外」

| # | 验收点 | 操作 | 预期 | 必收截图 |
|---|---|---|---|---|
| 2.1 | 战斗发起 | 点 stage_01_01 开战 | 3v3 战斗画面正常 | `r4_05_battle_stage_01_01.png`（能给则给） |
| 2.2 | 掉落显示 | 战斗胜利 → 结算弹窗 | 显示「掉落：」+ 至少 1 件装备名(stage_01_01 掉率 1.0 = 必掉「粗布衣」+「铜铃」) | `r4_06_victory_drop_display.png` |
| 2.3 | 掉落入库 | 结算后 → 主菜单 →「装备仓库」 | 仓库内可见刚掉落的装备 | `r4_07_drop_in_inventory.png` |

### Round 3 · 典故 + 招式描述（沿 Round 1 seed 继续）

**准备**：回主菜单（可沿 Round 2 seed 继续，或重新用 VC18-A1 seed）

| # | 验收点 | 操作 | 预期 | 必收截图 |
|---|---|---|---|---|
| 3.1 | 百科典故 Tab | 主菜单 →「江湖见闻录」→「典故」Tab | 有 ≥1 条典故条目(非空状态) · 若空显示「装备尚浅,典故未集。」也 PASS(clean seed 未集典故属正常) | `r4_08_baike_lore_tab.png` |
| 3.2 | 装备详情典故 | 「装备仓库」→ 点任一装备展开详情 | 详情页有典故段落(非 placeholder / 非空白) | `r4_09_equipment_lore_detail.png` |
| 3.3 | 招式描述 | 「角色面板」→ 点角色 → 技能/招式列表 | 招式有中文描述(非 TODO_NARRATIVE / 非空白) | `r4_10_skill_description.png`（能给则给） |
| 3.4 | 装备仓库滚动 | 「装备仓库」→ 滚到底部 | 列表含多件不同 Tier 装备 · 滚动流畅不卡顿 | `r4_11_inventory_scroll_bottom.png`（能给则给） |
| 3.5 | 相生 12 组合不 crash | 回主菜单 → 角色面板 → 逐个查看角色 | 无 crash · 相生 chip 正常渲染 | `r4_12_synergy_no_crash.png`（能给则给） |

## 截图命名

统一存 `docs\handoff\r4_visual_check_screenshots\`，文件名见各行。

## 必收 vs 能给

| 优先级 | 验收点 |
|---|---|
| **必收**（7 项） | 1.1-1.4（数据加载 4 项）· 2.2-2.3（掉落显示+入库）· 3.1（百科 Tab） |
| **能给则给**（5 项） | 2.1（战斗画面）· 3.2-3.5（典故详情/招式描述/滚动/相生遍历） |

## 硬约束

- 不动 `lib/` `test/` `data/` `GDD.md` `CLAUDE.md` `numbers.yaml`
- 不 push
- 不装新包
- 跑不通的场景保留反证截图 + closeout 标 FAIL，不伪造
- Isar 数据路径：`C:\Users\Administrator\Documents\wuxia_save_slot1.isar`
- 清库重启：删上述 `.isar` + `.isar.lock` 文件后重启 exe

## 注意事项

1. **Round 2 必须 clean Isar**：确保 drop 从零开始验,否则旧存档可能已有装备干扰判断
2. **stage_01_01 掉率 1.0**：第一关必定掉「粗布衣」(armor_xunchang_bu_yi) +「铜铃」(accessory_xunchang_tong_ling)，结算弹窗应显示「掉落：」后列出这两件
3. **百科典故可能空**：clean seed / VC seed 角色不一定触发过典故收集,「装备尚浅,典故未集。」是合法空态,不算 FAIL
4. **装备详情典故**：需要装备 ExpansionTile 展开看,round2 实测 row click 用鼠标直接点
5. **build 前必跑 build_runner**：`.g.dart` 文件 gitignored(已 build 则跳过)
6. **VC18-A1 seed 给 7 角色一流·启蒙**：打 Ch1 绰绰有余,不需要额外升级

## closeout 必交

交付 `docs\handoff\pen_visual_verify_r4_p2_1_content_drop_2026-05-28.md`：
- 每验收点状态（PASS / FAIL / EXPECTED_EMPTY）
- 截图路径
- 发现的问题
- 最后总结
