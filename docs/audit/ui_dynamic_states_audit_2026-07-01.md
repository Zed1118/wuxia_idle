# UI 动态态夜审 D · 2026-07-01

范围：动态弹窗、确认态、snackbar、focus/hover/pressed 可验收性。只改 debug route / presentation / tests / audit 文档；未触碰数值、schema、saveVer、结算、数据规则。

## 结论

- `shop_buy_confirm`：已有 dedicated route，背景为真 `ShopScreen`，弹窗复刻购买确认。已补 route seed 测试，锁住银两 80 与 preview 接线。
- `item_use_confirm_dialog`：已有 dedicated route，背景为真 `InventoryScreen(initialTab: 1)`，弹窗复刻使用确认。已补 route seed 测试，锁住经验丹/秘籍物品。
- `skill_codex_locked_snackbar`：已有 dedicated route，post-frame 触发 `UiStrings.skillCodexNotMet`。本次强化全局 SnackBar 主题为浮动墨底、金边、加粗白字，避免深底列表上提示过弱。
- `encounter_outcome_skill_banner`：重验资料已判定 RESOLVED，当前居中仪式浮层成立；本次未改。
- `battle_tap_preview`：当前代码只有 `battle_drag_preview`。本次新增 `battle_tap_preview` 兼容 route，复用同一冻结预置态，保证点按/干预验收口径能稳定截图。
- focus/pressed：`PlaqueButton` 已有 `FocusableActionDetector`、focus 金边、pressed 暗层、键盘 Enter/Space 测试。
- hover：共享按钮底层当前没有独立 hover 视觉态。按本 worker 边界不改共享按钮底层；建议由共享控件 owner 统一设计 hover token 后补全。

## 风险

- `battle_tap_preview` 是兼容别名，不改变战斗交互语义；真实拖动/点按手感仍需人工真机或可信桌面事件工具复验。
- snackbar 主题是全局 presentation 变更，会影响所有 `SnackBar` 外观，但不改变文案、触发条件或业务流程。
