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

- 状态：A-1 READY；A-2 READY；A-3 BLOCKED（已实测）；A-4 按遇阻即停未启动。
- 最后完成：主线与塔结算各一份提交；presentation 薄包装与 application 消费者接线完成。主线掉落写入移除触发 10 项失败、塔推进归零触发 2 项失败，均已逐字节还原。
- 下一步：完成收据与摘要后收工。若后续明确允许事件服务增加时钟注入口，再从 A-3 继续；当前不修改范围外服务。
- 已跑验证：A-1 新守卫 `00:00 +114: All tests passed!`；A-2 定向共 51 项通过，全量 `08:01 +6917: All tests passed!`，退出 0；分析 `No issues found! (ran in 4.4s)`；格式 `Formatted 1851 files (0 changed) in 4.56 seconds.`。
- 环境：原 SDK 缓存只读；使用外置可写 `../flutter-sdk` 同版本副本，`CI=true` 禁用遥测写入，不修改系统 SDK 或全局设置。
- 阻塞：A-1、A-2 无。A-3 的 GameEventService 会在返回装备上写入不可注入的真实时间，需要范围外服务注入才能保证含装备履历的完整结果确定性。已向用户异步澄清，未收到回复，不视为扩大授权。最终收据 SHA 自引用按内置代码收据与外置最终 tip 收据分别记录。



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

- 主线迁层已提交 `a8af2a73e`；塔定向 `00:01 +5: All tests passed!`，活动 4、扫荡 4、四份源码契约 12 项分别单跑绿，总定向 51 项。全仓分析 `No issues found! (ran in 4.4s)`。
- 两个目标 entry-flow 在所有 application 的反向依赖为 0。当前无关反向依赖保留如下：

| 文件位置 | 依赖内容 | 处理 |
|---|---|---|
| `main_menu/application/main_menu_status_summary_provider.dart:14` | `seclusion/presentation/seclusion_gate.dart` | 无关，本单不迁移 |
| `debug/application/phase0a_debug_battle_fixture.dart:23` | `phase0a_visual_roster.dart` | 调试表现装配，保留 |
| `debug/application/production_profile_keyboard_driver.dart:7` | `phase0a_battle_controller.dart` | 调试键盘驱动，保留 |
| `debug/application/phase0a_production_profile.dart:7` | `phase0a_battle_controller.dart` | 调试生产画像，保留 |
| `debug/application/phase0a_production_profile.dart:8` | `phase0a_battle_screen.dart` | 调试生产画像，保留 |

- 塔搬迁归一核验：两函数及掉落持久化正文相同，依赖取值和回调命名作明确适配；两行迁入的英文注释已译为简体中文。审计脚本/输出保留 `../logs/A-2_tower_move_audit.*`。
### A-2 收口验证

- 主线掉落写入移除：`00:06 +16 -10: Some tests failed.`，退出 1；塔推进归零：`00:01 +3 -2: Some tests failed.`，退出 1。原始日志 `../logs/A-2_break_remove_implementation.log`、`A-2_break_force_degenerate_value.log`，结构化结果 `A-2_break_red.json`；两次均 SHA-256 验证恢复。
- 全量 `flutter --suppress-analytics test --no-pub`：`08:01 +6917: All tests passed!`，退出 0、无失败或跳过；`../logs/A-2_full_test.log`、`A-2_full_test.exit`。
- 全仓分析 `No issues found! (ran in 4.4s)`，整仓格式 `Formatted 1851 files (0 changed) in 4.56 seconds.`，均退出 0；各原始日志存于 `../logs/`。
- application 对两份 entry-flow 的反向 import 为 0；主线、塔业务搬迁审计复跑均一致。723 个受保护文件再次比对零字节变化。
- 本次只修订自己的最后塔提交为 READY，保留主线、塔两份可独立评审提交。

### A-3 阻塞与收工恢复点

- A-2 READY：`1565f31fa0419588f0b0b023d0a7d3c9c0665275`；收口时间 `Thu Sep 17 00:40:39 CST 2026`，未到时间围栏。
- A-2 实际体积：两份 presentation 净减 1410 行，两份 settlement 新增 1659 行；差 249 行来自显式惰性依赖及转发适配，不宣称只有几十行包装差。
- A-3 没有实施生产代码改动。真实主线固定输入阻塞探针 `00:00 +0 -1: Some tests failed.`（退出 1），证明返回装备履历时间不能通过当前允许的注入口固定。
- 阻塞原因及 154 个时钟或随机点已登记 `docs/audit/clock_rng_residue_2026-09-17.md`；4 个范围内裸时钟仍保留，不能报告 A-3 验收通过。该探针不是既有全量套件回归，不加入生产测试套件。
- 按派单“遇到即停，不硬做”，A-4 未启动；未制造没有机制事件的 golden 或补齐假完成数字。
- 代拍：是否允许 GameEventService 增可选 SystemClock 入口并由两结算透传；NumbersConfig 的生产 null/缺失兜底是否在后续数值单显式补配置。当前生产 YAML 一个字节不改。
- 收据 SHA 不能包含自身提交的 SHA。仓库内收据归档最后代码 READY 提交及已执行验证；外置 `../receipt.yaml` 指向最终含收据 tip，协调者用 `--receipt` 读取；不冒称仓库内收据自引用最终 tip。该可逆交付方式已提前异步说明。
- 收工提交之后在最终 tip 再执行 full test、analyze、format、两向破坏证红并还原；原始输出存 `../logs/final_*`，最终实测末行写入外置收据及 `../summary.md`，避免为记录自身 SHA 反复改提交。
