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

- 状态：已完成实现，待运行验证并提交 READY 封签。
- 最后完成：新增 resolver、五组边界测试与本计划。
- 下一步：运行 targeted test、scoped analyze、diff check；检查 diff 后提交中文动宾 commit 与 `[READY]` 空提交。
- 已跑验证：尚未运行本切片验证。
- 阻塞项：无。
