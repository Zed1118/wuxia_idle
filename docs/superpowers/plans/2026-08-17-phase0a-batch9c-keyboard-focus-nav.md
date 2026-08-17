# Phase 0A Batch 9C：键盘焦点/导航

**日期**：2026-08-17
**基线**：`main@a2190971`
**分支**：`feat/phase0a-batch9c-keyboard-focus-nav`
**来源**：BACKLOG 二#13 ③（9A 音效 / 9B 终局重试合入后唯一剩项；本批完成后二#13 整条销账）

## 目标

Phase 0A 战斗屏键盘焦点**可见、可环游、可战斗**：
Tab 到达的每个交互点都有可见焦点环；整屏 Tab 环游顺序确定；
焦点停在技能印上时战斗键（WASD/J/Q/R）仍然有效。只补焦点表现与
导航测试，不改任何战斗规则与数值。

## 现状审计（冻结前实测）

已具备（本批不重做）：
- 技能印 Tab 遍历 gather→clear、Enter/Space 激活、禁用态跳过、
  Semantics button/enabled、鼠标光标（`phase0a_skill_seals_test` 覆盖）
- 再战按钮 `FocusableActionDetector` 四义项 + 屏幕级 Enter 同效（9B）
- 屏幕级 `Focus` autofocus + WASD/J/Q/R/Enter 快捷键
- phase0a 在 `desktop_semantics_allowlist.txt` 零豁免

真实缺口：
- **G1 技能印焦点环不可见**：裸 `Focus` 无 `onShowFocusHighlight`，
  Tab 到达零像素变化（同 2026-07-30 真机走查实录的 PlaqueButton 旧病）
- **G2 再战按钮未接金边环**：9B 只接激活/光标，没接焦点高亮回调
- **G3 无整屏集成测**：Tab 完整环（含终局再战按钮）、焦点在印上时
  战斗键冒泡到屏幕 handler、再战按钮焦点态 ActivateIntent
- **G4 技能印 Semantics 无 label**：读屏只听到「按钮」

## 冻结范围

1. `_SkillSeal` 改 StatefulWidget，裸 `Focus`+`MouseRegion` 换
   `FocusableActionDetector`（对齐 `PlaqueButton` 体例）：
   `onShowFocusHighlight → _focused` + `if (_focused)` 金边环
   （`WuxiaUi.gold`，环宽入 tokens）；Enter/Space 走 ActivateIntent。
2. `_RetryButton` 补同款金边环（`onShowFocusHighlight` + 金边）。
3. `Phase0aPresentationTokens` 新增焦点环 token（环宽）。
4. Semantics label 补全：技能印 label = 印字 + 键位 + 状态行。
5. 新增整屏集成测（新文件 `phase0a_focus_nav_test.dart`）：
   - 战斗中 Tab 环游：screen → gather → clear
   - 终局 Tab 跳过禁用印到达再战按钮，Enter（ActivateIntent）触发再战
   - 焦点在技能印上按 J/Q/R/WASD 仍冒泡发 command
   - 焦点环出现/消失断言（技能印 + 再战按钮）
   - 技能印 Semantics label 含状态行

## 禁止项

- 不加新交互点（暂停 / Esc 退出 / 返回入口均不做）
- domain/reducer/flow/numbers 零改动
- 屏幕快捷键映射语义不变（WASD/J/Q/R/Enter 现有行为保持）
- HUD/立绘/封签不加焦点（纯展示）
- 不碰 9A sfx 与 9B retry 接线语义
- 焦点环视觉不做新语言：沿用项目金边环体例（`WuxiaUi.gold`，用户已确认）

## 实现契约

- 焦点高亮策略依赖 `applyDesktopFocusHighlightStrategy`（main 已接线
  `alwaysTraditional`）；widget 测内用
  `tester.binding.focusManager.highlightStrategy = alwaysTraditional`
  复现桌面行为（体例见 `plaque_button_focus_ring_test`）。
- 金边环结构对齐 `plaque_button.dart` L185-196：
  `Positioned.fill + IgnorePointer + DecoratedBox(border: gold)`。
- 新数值（环宽）只进 `Phase0aPresentationTokens`，不散写。

## 验收

- 红测先行：新集成测在实装前跑红。
- 实装后 targeted 全绿：`phase0a_skill_seals_test` /
  `phase0a_focus_nav_test` / `phase0a_retry_test` /
  `phase0a_battle_screen_test` / `desktop_semantics_audit_test` /
  `phase0a_source_contract_test`。
- 破坏证红（commit 后做，反向补丁还原，不用 `git checkout --`）：
  删技能印 `if (_focused)` 金边 → 焦点环测红；
  删再战按钮 ActivateIntent → 焦点态 Enter 测红。
- `flutter analyze --no-pub` 0 issue；`dart format` 门禁净。
- 全量四段 **5152 + 新增数逐值吻合**。
- 视觉验收说明：焦点环是键盘态视觉，静态验收路由拍不到；验证以
  widget 测断言「焦点态金边存在、失焦消失」为主，复用三条 J/Q/R
  路由确认非焦点态画面零回归（不新增视觉路由，不调 20s 保持窗口）。

## 恢复点

- RP0：计划冻结（本 commit）。
- RP1：红测落盘跑红 → 实装复绿 → targeted + analyze + format 净。
- RP2：破坏证红完成并还原复绿。
- GATE：全量四段逐值吻合 → `git merge --no-ff` 合 main → 收账
  （PROGRESS 登记 + BACKLOG 二#13 整条销项）→ push 盯 CI。
