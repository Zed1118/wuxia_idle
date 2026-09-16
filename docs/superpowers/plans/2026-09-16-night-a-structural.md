# 夜批 A 结构整改恢复计划

- 分支：`codex/night-a-structural-20260916`
- 基线：`c307b3ffcb155af58d4efb9179e36453297b1360`
- 目标顺序：A-1 配置缺项拒绝加载 → A-2 结算迁层 → A-3 时钟随机源 → A-4 事件流守卫。
- 边界：严格遵守派单禁区；不推送、不合并、不读真实存档、不启动 GUI。生产 YAML、数值、UI、schema/saveVersion、战斗规则保持不变。
- 验收：每项定向、全仓分析、格式检查、并发全量测试，保留原始日志；执行指定破坏证红并精确还原；每项收口检查 06:00 CST 时间围栏。
- 生产接线：A-1 从 `NumbersConfig.fromYaml` 加载生产配置；后续按对应目标记录真实消费者。
- 红线影响：只取消生产已有 key 的静默兜底，生产缺项保留并登记；不调整配置值。
- 残留风险：Windows、GUI、真人验收不在本单范围；具体未完成项见恢复点。

## 恢复点

- 状态：A-1 已完成并验证；A-2 正在实施。
- 最后完成：红线段已独立提交 `4b18c4c67`；其余 94 个 numbers 兜底和关卡首领开关已收紧，旧测试显式 fixture 已迁移且原断言保留。数值残留 2 处、布尔残留 2 处已登记。
- 下一步：分别形成主线、塔两份可评审提交，迁移 application 消费者和源码守卫，再做双向破坏证红及全量验证。
- 已跑验证：新增守卫 `00:00 +9: All tests passed!`；恢复字面量 mutation 为 `00:00 +8 -1: Some tests failed.`，1 失败且已精确还原。旧红线测试 4 项通过（原始日志见 `../logs/A-1_red_lines_existing.log`）。
- 环境：原 SDK 缓存只读；使用外置可写 `../flutter-sdk` 同版本副本，`CI=true` 禁用遥测写入，不修改系统 SDK 或全局设置。
- 阻塞：A-1 无。A-3 下游服务注入范围与最终收据自引用 SHA 两项已向用户异步澄清，不阻塞 A-1/A-2。旧红线测试的缺段 fixture 改为显式完整 fixture，原有 8 项数值断言全部保留；新增逐 key 删除拒绝加载守卫覆盖新契约。


### A-1 当前验证记录

- 新必填字段守卫：`00:00 +114: All tests passed!`（`A-1_required_keys_targeted.log`）。
- 旧 fixture 相关 10 个文件逐个单跑：112 项通过；首次动画 fixture 尚未显式给旧断言值而失败，补显式输入后原断言通过；首轮失败日志保留。
- 全仓分析：`No issues found! (ran in 2.8s)`（`A-1_analyze.log`）。
- 整仓格式：`Formatted 1846 files (0 changed) in 4.89 seconds.`（`A-1_format.log`，退出 0）。
- 全量：`flutter --suppress-analytics test --no-pub` → `08:22 +6917: All tests passed!`，退出 0、无失败/跳过；原始输出 `../logs/A-1_full_test.log`、退出码 `A-1_full_test.exit`。
- 验证统一环境：`PATH=/Users/a10506/Documents/Codex/2026-09-16/night-A/flutter-sdk/bin:$PATH`、`CI=true`；命令均在本 worktree 运行。遥测关闭只处理沙盒外配置不可写，不更换 SDK 版本。
- 已为 723 个受保护文件建立 SHA-256 指纹，当前复核零字节变化；最终收工再次复核。

- A-1 收口审计：全部 218 条旧断言原样保留；将新增缺项异常替换归一后，其余 numbers 配置代码与基线完全一致。原始审计 `../logs/A-1_diff_audit.log`。


### A-2 施工边界

- 开始前围栏：`Thu Sep 17 00:18:06 CST 2026`，A-1 READY `384417960`，工作区干净。
- 主线和塔各一个代码写者；主线程独占 activity/sweep 消费者、既有测试路径迁移与集成。
- 新应用入口：`mainline/application/mainline_settlement.dart`、`tower/application/tower_settlement.dart`；依赖对象延迟读取，保留旧前置检查及 provider 读取时序。
- 没有发现 BuildContext 业务判断。共享纯 helper 随同迁移，presentation 保留薄包装/导出；不改时钟或随机序列（留 A-3）。
- 源码测试映射：共享成长调用、经验来源策略两文件的主线位置移到新 application；单一经验账户与旧等级禁用两文件保留 presentation 扫描并增加 application，原断言不删除。

- 主线切片：定向 `00:06 +26: All tests passed!`，退出 0（`A-2_mainline_targeted.log`）；依赖/回调适配归一后 9 个函数体、2 份共享 hook、镜头推导均等价（`A-2_mainline_move_audit.log`）。
- 集成前分析：`No issues found! (ran in 5.4s)`（`A-2_analyze_precommit.log`）。塔消费者与源码路径将在下一提交接入；当前主线提交快照仍保留原塔文件。
