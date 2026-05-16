# Codex W15 victory dialog 视觉验收 closeout

## 1. 一句话结论

5 张正式截图已收，真实 GUI 链路跑通；评级为 **2 PASS / 3 WARN / 0 FAIL**。#34 的 victory drop banner 缺口已部分闭环：主线 / 塔 victory dialog 均能显示掉落，但当前 P5 种子与派单前置不一致，未能验到 3 active 学徒升层多行 banner；材料掉落仍显示 `item_mojianshi` defId，未本地化成「磨剑石」。

## 2. 环境与启动记录

- HEAD: `1092537`
- 入场：`git pull --rebase --autostash` 成功快进到 `1092537`。
- 生成：`dart run build_runner build --delete-conflicting-outputs` 成功；当前 build_runner 提示该参数已移除并忽略，仍写出 16 个输出。
- 构建：`flutter build windows --debug` 成功，产物 `build\windows\x64\runner\Debug\wuxia_idle.exe`。
- 启动：清理 `$env:APPDATA\wuxia_idle` 后启动 Debug exe。
- 窗口：1280 x 900。
- 约束：未改 `lib/`、`test/`、`data/`、`GDD/CLAUDE/numbers`，未 push。`flutter build` 自动改动的 generated plugin 文件已恢复，仅保留截图与本 closeout。

## 3. 截图清单与评级

| # | 场景 | 截图路径 | 评级 | 备注 |
|---|---|---|---|---|
| A1 | stage_01_01 victory dialog | `docs/screenshots/w15_victory_dialog/A1_mainline_01_01_dialog.png` | WARN | dialog 出现，title 为「山门之外 · 战斗胜利」，drop 显示「粗布衣」+ `item_mojianshi ×1`；无升层 banner。 |
| A2 | stage_01_01 dialog 后叙事屏 | `docs/screenshots/w15_victory_dialog/A2_mainline_01_01_narrative_after_dialog.png` | PASS | 点「继续」后进入「山门之外 · 终」叙事屏，dialog 未破坏 narrative 链路。 |
| B1 | stage_01_02 victory dialog | `docs/screenshots/w15_victory_dialog/B1_mainline_01_02_dialog.png` | WARN | dialog 出现，title 为「荒山野店 · 战斗胜利」，drop 显示 `item_mojianshi ×3`；无升层 banner。 |
| C1 | 塔首通实际补证 | `docs/screenshots/w15_victory_dialog/C1_tower_floor2_firstclear_actual.png` | WARN | P5 后塔已通 1/30，无法拍第 1 层首通；改拍第 2 层首通，title / 首通奖励 / 确定按钮正常，无升层 banner。 |
| C2 | 塔重打实际补证 | `docs/screenshots/w15_victory_dialog/C2_tower_floor2_replay_actual.png` | PASS | 第 2 层重打显示「已重打通关，重打不发奖」，无升层 banner，符合 replay 行为。 |

## 4. 视觉层反馈

- 主线新 victory dialog 已落地，drop 信息能在战后第一屏出现。
- `AdvancementSummary` 多行 banner 本轮未验到：当前 P5 种子角色为祖师一流 / 大弟子二流 / 二弟子三流，stage_01_01 / stage_01_02 / 塔低层 EXP 不足以升层。
- 掉落材料显示为 `item_mojianshi ×N`，不是中文「磨剑石 ×N」。装备「粗布衣」能正常本地化。
- 主线 dialog 视觉尺寸稳定，1280 x 900 下标题、掉落、按钮均不截断。
- 塔 dialog 保持原体例，首通和重打文案均可读。

## 5. 节奏层反馈

- P5 种子后自动进入角色面板，Back 两次回主菜单正常。
- 主线 stage_01_01 / stage_01_02 流程为 opening narrative → battle → battle result → 新 victory dialog → victory narrative，链路顺畅。
- 塔流程为 battle → battle result → tower victory dialog，首通后进度从已通 1/30 到已通 2/30；重打不发奖成立。
- 派单前置与当前仓库不一致：`UiStrings.hintP5` 与测试均写明 P5 是「祖师一流 + 大弟子二流 + 二弟子三流」，且 P5 后主线 01-01 至 01-04、塔第 1 层已处于已通状态。故无法按派单自然取得「3 active 全员学徒启蒙」和「塔第 1 层首通」。

## 6. 工程教训

- `build_runner --delete-conflicting-outputs` 在当前版本只报警告不阻塞，仍可作为本轮生成步骤使用，但 closeout 里应记明参数已被忽略。
- `flutter build windows --debug` 会碰平台 generated plugin 文件；视觉验收结束后需恢复这些构建副产物，避免越过 docs/screenshots-only 约束。
- CopyFromScreen 截图稳定；本轮清理了 `_probe_*.png`，只保留正式 5 张。
- P5 派单前置最好由派单方在接单前复核一次当前 UI 文案 / test / seed 数据，避免视觉验收目标与现有 debug seed 语义漂移。

## 7. 下次推荐

- 若要验升层 banner，多半需要 Mac 端新增一个专用 debug seed：3 active 全员 `xueTu.qiMeng`、experience=0、internalForce=500/500、主线和塔进度清零。
- 修 `ItemDropResult` 在 victory dialog 中的显示名解析，让 `item_mojianshi` 显示为「磨剑石」。
- #34 UI 缺口 1/2 可按「victory dialog 已有 drop 展示，但材料本地化 + 升层 banner 真机未验」记 WARN 闭环；InventoryScreen 物料 Tab 仍留下一波。
