# P2 M6 U02/U03：主线叙事去阻塞与章节卷轴搬迁

## 目标

一次原子关闭 U02 与其必要的 U03/U12 最小承载：105 个 `StageType.mainline` 关卡（含第 4/5 关 Boss）不再自动 push opening、victory、defeat 阅读器；所有旧 ID 保留并逐项登记 manifest；玩家从现有章节 timeline 主动阅读已解锁内容。

## 实现边界

- 不改变特殊模式 opening/victory/defeat 行为，不删除或改写 narrative YAML，不增加主菜单一级入口。
- Boss 失败照常原子结算惩罚；损失通过事实性、非叙事 UI 显示，不给配装或打法建议。
- manifest 每个现有主线 opening/victory/defeat ID 恰好一行，字段为 `targetType/targetId/unlockTrigger/disposition`。本批 252 条全部使用 `migrate`；`merge/archive` 保留为未来 schema 能力，但没有内容 owner 明确复核不得在本批使用。
- 解锁只能使用现有进度证据；若 defeat 缺少可持久化证据，采用保守可解释规则并通过测试固定，不引入 saveVersion 或已读状态迁移。
- 本任务不实现 U01 连续下一关、U04 待处理事件、U05 四入口，也不改变结算、招募、奇遇领域语义。

## 外部模型与验收

- 开工前和 actual diff 后分别调用 Qoder CLI `Qwen3.8-Max` 高强度只读审查，记录命令、版本、精确模型、退出码与 P0/P1/P2。
- actual diff 终审证据必须绑定被审查的最终 code tree/commit；终审后如再改 code/test，必须重跑终审。
- 定向测试覆盖 105 关完整性、三类自动 reader 归零、Boss 事实性损失展示、可选阅读解锁、特殊模式不回归。
- 允许同步改写现有 `mainline_narrative_completeness_test.dart` 与两个 `stage_list_screen*_test.dart` 中已被新冻结合同取代的“点关卡自动进 opening reader”断言；不得删除原有资产真实性、章节内容和 cycle 回归覆盖。
- 章节 timeline 新入口需覆盖 1280×720 与 1440×900 无 overflow、语义标签和键盘可达性；不能只验字符串存在。
- `dart format --output=none --set-exit-if-changed`、changed/scoped `flutter analyze --no-pub`、`git diff --check` 和 clean worktree 全部通过后提交唯一 READY 恢复点。

## 恢复点

- 产品语义基线：`693ed157071e8242dc44ef81b9bae7d289809e58`；source patch diff 基线：`a6a373e137f72a69040199eb9431052f8095d1e1`。
- 执行端不得改 registry、`CLAUDE.md`、`GDD.md`、`PROGRESS.md`；由主控集成后统一收口。
