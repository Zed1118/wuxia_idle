# Phase 2 M5 九霄塔文案与证据收口计划

日期：2026-09-01

分支：`codex/p2-m5-tower-copy-evidence-fix-20260901`

基线：`62d6df2aea62d54bb1abf8f730fe8e6cb100f572`

## 目标

修复九霄塔持久差遣已接入后仍显示“不可派遣”、且差遣按钮复用百草岭入口文案的生产 UI 回退；用真实生产 Widget 契约测试守住文案和动作身份；校正 2026-09-01 M5/外部审查中的最终 Gate 与审查深度口径。

## 非目标

- 不改变九霄塔首通、重打、差遣、占用、结算或奖励语义。
- 不改 schemaVersion/saveVersion、Isar collection、YAML、数值、技能、经济、解锁或战斗规则。
- 不关闭 M5 剩余 `4/42`，不进入 M3/M4，不用工程验证替代真人目检。
- 不把外部审查深度不足的 U11/U12 写成已独立接受。

## 验收标准

1. 生产接线：`TowerLocationDetailScreen` 明确显示“首次亲自挑战；已通层可差遣历练”和差遣占用；`TowerFloorCard` 使用九霄塔专用“差遣历练”动作，不复用百草岭“前往派遣”。
2. Targeted：地点详情和塔层列表生产 Widget 测试均通过；测试必须在当前回退实现上先 RED。
3. 破坏证红：分别回退地点说明、把按钮换回 `expeditionLocationEnter`，相关用例必须真实失败并精确反向还原。
4. UI/UX：1280×720 与 1440×900 地点详情无布局异常；既有 `PlaqueButton` 桌面语义不改变。
5. 证据口径：M5 审计记录 final-tip `5840/5840`、原始 Gate 与组合门禁结论的边界；外部审查校正将 U11/U12 标为 `UNPROVEN`。
6. 红线：零 schema/saveVersion、YAML、数值、技能、奖励、经济、解锁、战斗规则改动；中文 UI 文案只进入 `UiStrings`。
7. 收口：定向测试、analyze、整仓 format、锁保护全量均 PASS；原始 Gate 的 `test_deletions` 由唯一合法测试契约迁移门 PASS 覆盖，`strings.dart` 由用户仅对本单明确一次性豁免，其他 Gate 项必须 PASS；最终 diff 符合范围且工作树 clean。

## 任务切片

1. 补生产 Widget 失败测试并记录 RED。
2. 恢复专用 UiStrings 与生产消费方。
3. 做两向 mutation，记录失败数并还原。
4. 更新 M5 审计与外部审查校正附录。
5. 执行定向、桌面尺寸、analyze、format、全量与 Gate，冻结 READY。

## 当前恢复点

- 状态：READY 收口中。工程修复与风险匹配验证完成；实现检查点 `3b616d84bc2a85647b0b560da8e21f87ad0002bb` 已冻结；用户于 2026-09-01 明确授权本单对 `lib/shared/strings.dart` 做一次性 Gate 豁免。
- 最后完成：当前错误实现取得地点详情 `1` 条、塔层列表 `2` 条有效 RED；恢复专用文案/按钮后定向 `8/8 + 14/14 PASS`；两向 mutation 分别精确 `1`、`2` 条失败并反向还原；M5 final Gate 和 U11/U12 审查深度口径已校正。
- 下一步：冻结新的 `[READY]` final tip，更新 receipt，复跑测试契约迁移门和 exact-tip 正式 Gate；原始 Gate FAIL 必须保留并与组合门禁结论同时报告。
- 已跑验证：地点详情 `8/8 PASS`（含 1280×720、1440×900）；塔层列表 `14/14 PASS`；analyze `No issues found!`；整仓 format `1700 files / 0 changed`；锁保护全量 `5840/5840 PASS`、`[E]=0`；两向 mutation RED 已确认。
- 阻塞项：无。一次性豁免严格限于本单的 `lib/shared/strings.dart`，不修改通用 Gate，不适用于其他文件、任务或未来批次；`test_deletions` 仍只按专用迁移门处理。
