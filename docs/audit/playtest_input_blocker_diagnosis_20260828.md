# 试玩阻塞输入诊断（2026-08-28）

## 结论

- 状态：`[BLOCKED]`。唯一基线 `1ba913a633beb0fd8f9b47764161f47c54260707` 的真实第 8 章战斗无法复现“不能移动、不能放技能”；本单没有可修的确定性代码 bug。
- D1 实测证伪“移动链失效”：`phase0a_battle_screen.dart:587-625` 实际收到 CGEvent `W` 的 `KeyDownEvent`，`_heldMovementKeys` 从 `[]` 变为 `[W]`，KeyUp 后回到 `[]`。
- `phase0a_battle_screen.dart:511-550` 每个 `0.1s` fixed tick 实际采样 `[W]`；`phase0a_player_input_adapter.dart:113-126` 每拍实际产出 `1` 个 `Phase0aMoveIntent`。
- `phase0a_combat_reducer.dart:543-580` 实测每拍 `defenseConsumed=false`、`suppressed=false`、`suppressedActorIds={}`，player 位置 `(-320,0)→(-320,-21)→…→(-320,-147)`，共 7 拍连续移动。
- `phase0a_combat_reducer.dart:262-278` 的 suppressed 集合只在 enemy 循环加入 enemy id；本次实测 player 不在其中，而且 `:550-557` 显式允许 defense 同拍的 move intent。
- D2 实测部分证伪“数字槽全空”：`phase0a_stage_content_mapper.dart:1087-1119` 从 slot1 生产 snapshot 读到 `numericSkillBindings.equipped.length=1`。

## 第 8 章角色六槽实测

| 热键 | loadout slot | 原始绑定 | 数字栏结果 |
|---|---|---|---|
| 1 | `main1` | `skill_gangmeng_jichu_basic` / `normalAttack` | 被 `phase0a_stage_content_mapper.dart:1094-1097` 按拍板规则排除 |
| 2 | `main2` | `skill_gangmeng_jichu_skill` / `powerSkill` | 唯一 equipped binding |
| 3 | `assist` | `null` | 未绑定 |
| 4 | `resonance` | `null` | 未绑定 |
| 5 | `ultimate` | `null` | 未绑定 |
| 6 | `encounter` | `null` | 未绑定 |

- `phase0a_battle_screen.dart:735-753` 的封印区实际渲染：画面显示 `1/3/4/5/6 未装备`、`2 重击 可用`；不是整区缺失。
- CGEvent `2` 经 `phase0a_battle_screen.dart:646-662` 实际进入输入链；`phase0a_player_input_adapter.dart:222-232` 产出 `Phase0aSkillIntent`。
- `phase0a_combat_reducer.dart:1166-1194` 实际产出 `Phase0aSkillStarted` / `Phase0aSkillApplied` / `Phase0aEnemyDefeated`，释放后 `qiAfter=37`；可用的 2 号技能并未失效。
- 1/3/4/5/6 零反馈的确定原因是 `bindingFor()` 为 null 时 `phase0a_player_input_adapter.dart:222-226` 不产生 skill intent；其中 1 是规则排除，3–6 是存档未装备。

## 自动驱动与范围判定

- 发键和鼠标均由 CGEvent 发送；每次动作前用 `CGWindowListCopyWindowInfo` 重读 bounds。两轮实测窗口从 `(320,139,1920×1080, scale=2)` 移到 `(2880,195,1920×1080, scale=1)`，驱动使用当轮实值。
- 现有行为下，只有“未绑定数字键零反馈”存在；补可见提示属于本单 §6 禁修的玩家可见 UI，因此不修。
- 仍为假设：原真人现象可能与当时焦点、具体键位或所启动的 app 实例有关；`phase0a_battle_screen.dart:668-674` 只证明失焦会清 held input，本次无实测能把任一项升格为原真人根因。

## 存档保护

- 权威冷备：`/Users/a10506/Desktop/wuxia_save_cold_backup_20260828_d1_input_diag.NIP1tY`。
- app 启动/战斗期间 slot1、slot2、slot3 均曾发生 SHA 变化；每轮停进程后均从冷备精确恢复并 `cmp=0`。
- 收工 SHA：slot1 `9a79f3e1075a83b769978d869960d9ba9f69991f6eb928ff471f7640d9d8c0ed`；slot2 `4624f51775953f23ea7b2acabe8d1a1e51f6b95348966964f679f60406349199`；slot3 `85003feb66802cf10e7a2b4f6c868d50b1eacab3822f311350c498269da06819`。

## 交付边界

- 未改 `lib/`；所有 print 探针已精确还原，四个探针文件均与 HEAD byte diff 为 0。
- 未动数值、schema/saveVersion、设计、玩家可见 UI、任一禁区文件或 main。
- targeted 末行与 `[E]`：移动屏 `00:03 +28: All tests passed!` / 0；数字技 `00:00 +4: All tests passed!` / 0；主线 Host `00:00 +18: All tests passed!` / 0。
- analyze 末行：`No issues found! (ran in 14.0s)`；format 末行：`Formatted 1626 files (0 changed) in 3.00 seconds.`
- 加锁全量末行：`04:54 +5643: All tests passed!`，`[E]=0`；本任务创建的 `wuxia_full_test.lock` 已删除。
