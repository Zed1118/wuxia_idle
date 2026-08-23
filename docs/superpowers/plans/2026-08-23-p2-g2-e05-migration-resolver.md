# P2 G2 E05：遭遇迁移路由合同

## 目标

建立纯 typed `legacy | migrated` encounter migration resolver；不读取文件、不切换 production host、不猜真实 stage/encounter 语义。

## 验收标准

- caller 必须显式声明 `migrationState`；legacy 仅接受声明为 legacy、显式 allowlist membership、`encounterCount == 0`、`hasLegacyContent == true`；migrated 对应声明为 migrated、非 allowlist、`encounterCount == 1`、`hasLegacyContent == false`。
- 声明 state 与实际结构不一致时 fail closed，不由 resolver 推断 state。
- both/neither、空白 ID、负数或非法组合均 fail closed；allowlist 防御性不可变且不含重复项。
- 仅改 resolver、对应测试与本计划；无依赖、无 loader/host/data/tuning/objective/token/UI/reward/save。
- targeted test、scoped analyze、`git diff --check` 通过，工作区 clean，tip 以 `[READY]` 开头。

## 当前恢复点

- 状态：已完成并冻结，等待主控评审/合并。
- 最后完成：新增显式 state resolver、五组边界测试与本计划；实现 `316f7b20` / 恢复点 `ecc6544b`，READY 封签为 `0c340af8`。
- 下一步：主控复审 diff 后合并；本分支不再修改。
- 已跑验证：分支 `flutter analyze` / `dart analyze` 0 issues、`git diff --check` 通过；主控集成态 targeted 5/5 通过。
- 阻塞项：无。
