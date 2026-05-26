# P4.1 1.1 三项链路视觉验收

验证日期：2026-05-26  
验证人：Pen Codex  
范围：Q6A 奇遇招募 NPC、Q6B Boss 战胜招降、character_panel 门派成员 polish、sect_recruit 文案深度  
约束：仅做视觉验收与截图；未修改代码、数值或文案源文件。

## Step 0：进入主界面

状态：PASS

截图：
- `docs/handoff/p4_1_1_screenshots/step0_game_onboarding_window.png`
- `docs/handoff/p4_1_1_screenshots/step0_main_loaded.png`

结果：
- 已从「直入江湖」onboarding 界面点击进入。
- 主界面加载完成，停在「挂机武侠 · 调试主菜单」。

发现的问题：无。

## Step 1：Q6A — 奇遇招募 NPC

状态：FAIL

截图：
- `docs/handoff/p4_1_1_screenshots/step1_q6a_bamboo_opening_options.png`
- `docs/handoff/p4_1_1_screenshots/step1_q6a_bamboo_confirm_dialog.png`
- `docs/handoff/p4_1_1_screenshots/step1_q6a_bamboo_after_outcome_no_confirm.png`

结果：
- PASS：`sect_recruit_bamboo` 可从 encounter debug picker 触发。
- PASS：奇遇开篇与选项正常显示，包含招募选项「你若愿意，可入我门派。」。
- FAIL：选择「接纳」方向后，未弹出二次确认对话框 `sect_recruit_confirm_dialog`。界面直接进入普通 outcome body。
- FAIL：点击「行路」结束后未显示招募成功 SnackBar，仅显示通用提示「心中默念, 继续前行」。

发现的问题：
- debug picker 路径没有走完整 sect recruit 确认与招募链路，导致 Q6A 的确认框和成功提示无法通过该路径验收。

## Step 2：Q6B — Boss 战胜招降

状态：FAIL

截图：
- `docs/handoff/p4_1_1_screenshots/step2_chapter1_stage_list.png`
- `docs/handoff/p4_1_1_screenshots/step2_stage_01_05_battle_or_result.png`
- `docs/handoff/p4_1_1_screenshots/step2_stage_01_05_after_wait.png`

结果：
- 已用调试入口推进到第一章 Boss 关 `stage_01_05`「风雨渡口」。
- 进入战斗后玩家侧未获胜，结果为「右队胜」。
- 因未达成 Boss 战胜条件，未观察到 0.40 概率招降提示，也未能继续验收招降确认流程。

发现的问题：
- 当前调试推进路径不足以稳定完成 `stage_01_05` Boss 胜利，Q6B 视觉链路未跑通。
- 本次未使用代码修复或数据调整。

## Step 3：polish — character_panel 门派成员

状态：PASS（非空成员列表未验证）

截图：
- `docs/handoff/p4_1_1_screenshots/step3_character_panel_lineage_sect_membership.png`

结果：
- PASS：角色面板可打开并滚动到「师承」区域。
- PASS：门派成员行已显示，当前 UI label 为「门派同道」。
- PASS：在无其他 NPC 成员时，空状态显示为「门派人少」。
- NOT VERIFIED：由于 Q6A/Q6B 招募链路未成功，本次没有形成 NPC 成员，无法视觉确认「排除玩家自己和祖师后列出 NPC 成员」的非空状态。

发现的问题：
- 验收描述中称「门派同门」行，当前实机显示为「门派同道」。如这是预期命名则无问题；如需严格一致，需要后续确认。

## Step 4：文案深度

状态：PASS

截图：
- `docs/handoff/p4_1_1_screenshots/step1_q6a_bamboo_confirm_dialog.png`
- `docs/handoff/p4_1_1_screenshots/step4_desert_opening_options.png`
- `docs/handoff/p4_1_1_screenshots/step4_desert_outcome_body.png`
- `docs/handoff/p4_1_1_screenshots/step4_mountain_outcome_or_phase2.png`

结果：
- PASS：`sect_recruit_bamboo`、`sect_recruit_desert`、`sect_recruit_mountain` 均可通过 encounter debug picker 触发查看。
- PASS：已查看 3 个 sect_recruit encounter。视觉上 bamboo / desert outcome body 有 7 行左右深度，含 NPC 背景动机段；mountain outcome 也可正常展示。
- PASS：只读检查确认 3 个接纳 outcome body 行数为：bamboo 7 行、desert 7 行、mountain 8 行。
- PASS：只读检查确认 `sect_candidates` 5 个 NPC lore 行数为：bamboo_swordsman 6 行、desert_wanderer 6 行、mountain_hermit 6 行、river_drifter 6 行、blacksmith_son 7 行。

发现的问题：
- `sect_candidates` lore 未在本次实机流程中找到独立 UI 展示入口，因此该项以只读数据核对为准，未形成单独候选人 lore UI 截图。

最后总结：有 FAIL：Step 1 Q6A、Step 2 Q6B；Step 3 非空成员列表未验证。
