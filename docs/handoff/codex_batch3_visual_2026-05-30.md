# H1 批3 UI 视觉验收（Pen Windows）

结论：5 项均可判 PASS。② 实机只观察到寻常货分支，未观察到神物金色分支；但装备与道具的视觉区分、勋章图标、品阶标签均已实机确认。

## 环境

| 项 | 记录 |
|---|---|
| 路径 | `F:\Projects\wuxia_idle` |
| Git HEAD | `a39e1d2b4039c75f9272960a035d300db365e569` |
| 窗口 | 约 1280×900 |
| 构建 | 复用白屏复现任务已完成的 debug build |
| 写入范围 | 仅 `docs/handoff/codex_batch3_visual_2026-05-30.md` 与 `docs/handoff/batch3_visual_2026-05-30/` 截图 |

## 逐项判读

| # | 结果 | 实机观察 |
|---|---|---|
| ① 过场水墨色 | PASS | 章节翻篇过场底部「翻过此页 · 入关」按钮为暗红/绛红系，不是 Material 默认蓝紫。 |
| ② 掉落品阶仪式感 | PASS | 主线首关胜利弹窗中，装备掉落「粗布衣」「铜铃」有勋章图标、品阶文字「寻常货」和偏灰品阶色；道具「磨剑石 ×1」仍是朴素列表。 |
| ③ 回合术语 | PASS | 战斗日志行首显示「第 N 回合」，右上角显示「回合 23」，结算弹窗显示「用时 23 回合」；未见英文 `tick`。 |
| ④ 凝练入口常驻态 | PASS | 通过 Phase 2 `P3 · 散功代价` seed 进入心法面板，主修心法按钮常驻显示「凝练领悟 · 暂无领悟点」。本轮没有正点数 seed，但 0 点态已实机确认。 |
| ⑤ picker 关闭按钮 | PASS | 武器 picker 顶部 header 有明确 X 关闭按钮；P1 seed 的护甲空态也有 X 且实测可关闭；P5 seed 中其他角色装备显示「他人装备中」。 |

## 截图清单

| 文件 | 对应验收 |
|---|---|
| `docs/handoff/batch3_visual_2026-05-30/batch3_01_transition_button.png` | ① 过场按钮红系 |
| `docs/handoff/batch3_visual_2026-05-30/batch3_02_drop_tier.png` | ② 装备掉落分色/图标/标签，道具朴素 |
| `docs/handoff/batch3_visual_2026-05-30/batch3_03a_battlelog.png` | ③ 战斗日志「第 N 回合」 |
| `docs/handoff/batch3_visual_2026-05-30/batch3_03b_summary.png` | ③ 结算「用时 N 回合」 |
| `docs/handoff/batch3_visual_2026-05-30/batch3_04_refine_button.png` | ④ 「凝练领悟 · 暂无领悟点」 |
| `docs/handoff/batch3_visual_2026-05-30/batch3_05a_picker_close.png` | ⑤ 非空 picker header X |
| `docs/handoff/batch3_visual_2026-05-30/batch3_05b_picker_empty.png` | ⑤ 空态 picker header X |
| `docs/handoff/batch3_visual_2026-05-30/batch3_05c_picker_empty_closed.png` | ⑤ 空态 picker 关闭后回到角色面板 |
| `docs/handoff/batch3_visual_2026-05-30/batch3_05d_picker_worn_by_other.png` | ⑤ 「他人装备中」标注 |

## 路径记录

| 验收 | 实际路径 |
|---|---|
| ① | 主菜单 -> 主线 -> 章节列表第一章卡右侧「卷」入口 |
| ②/③ | 过场页「入关」 -> 主线第一关「山门之外」 -> opening 剧情继续 -> 战斗 -> 结算 -> 主线胜利掉落弹窗 |
| ④ | 主菜单 -> Phase 2 调试场景 -> `P3 · 散功代价` -> 心法面板 |
| ⑤A/B | 主菜单 -> Phase 2 调试场景 -> `P1 · 强化曲线` -> 返回主菜单 -> 角色面板 -> 武器/护甲槽 picker |
| ⑤C | 主菜单 -> Phase 2 调试场景 -> `P5 · 师徒种子` -> 角色面板 -> 武器 picker |

