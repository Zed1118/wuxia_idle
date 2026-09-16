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

- 状态：A-1、A-2、A-3 READY；A-4 正在实施，仅新增测试与 fixture。
- 最后完成：A-3 直接结算调用链注入与 15 个新增守卫；完整返回和全部持久字段确定性通过，主线时钟破坏证红 2 失败且已精确还原。
- 下一步：完成三场景生产装配事件流 golden，默认两次通过并做 reducer 破坏证红；随后完成本目标全量及最终收据。
- 已跑验证：A-3 完整套件 `07:33 +6932: All tests passed!`，退出 0；分析 `No issues found! (ran in 5.4s)`；格式 `Formatted 1854 files (0 changed) in 4.17 seconds.`；主线注入退回真实时钟 `00:02 +3 -2: Some tests failed.`，退出 1并还原。
- 环境：原 SDK 缓存只读；使用外置可写 `../flutter-sdk` 同版本副本，`CI=true` 禁用遥测写入，不修改系统 SDK 或全局设置。
- 阻塞：原 A-3 范围冲突已由本轮协调者明确授权解除。允许事件服务、首次塔与奇遇进度、公共事件直接调用链增加可选注入口，默认未传参行为保持；其余残留不扩大修改。仓库内代码收据与外置最终 tip 收据方案亦已明确获准。



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

### A-3 首轮阻塞与收工记录（已获继续授权）

- A-2 READY：`1565f31fa0419588f0b0b023d0a7d3c9c0665275`；收口时间 `Thu Sep 17 00:40:39 CST 2026`，未到时间围栏。
- A-2 实际体积：两份 presentation 净减 1410 行，两份 settlement 新增 1659 行；差 249 行来自显式惰性依赖及转发适配，不宣称只有几十行包装差。
- A-3 没有实施生产代码改动。真实主线固定输入阻塞探针 `00:00 +0 -1: Some tests failed.`（退出 1），证明返回装备履历时间不能通过当前允许的注入口固定。
- 阻塞原因及 154 个时钟或随机点已登记 `docs/audit/clock_rng_residue_2026-09-17.md`；4 个范围内裸时钟仍保留，不能报告 A-3 验收通过。该探针不是既有全量套件回归，不加入生产测试套件。
- 按派单“遇到即停，不硬做”，A-4 未启动；未制造没有机制事件的 golden 或补齐假完成数字。
- 代拍：是否允许 GameEventService 增可选 SystemClock 入口并由两结算透传；NumbersConfig 的生产 null/缺失兜底是否在后续数值单显式补配置。当前生产 YAML 一个字节不改。
- 收据 SHA 不能包含自身提交的 SHA。仓库内收据归档最后代码 READY 提交及已执行验证；外置 `../receipt.yaml` 指向最终含收据 tip，协调者用 `--receipt` 读取；不冒称仓库内收据自引用最终 tip。该可逆交付方式已提前异步说明。
- 收工提交之后在最终 tip 再执行 full test、analyze、format、两向破坏证红并还原；原始输出存 `../logs/final_*`，最终实测末行写入外置收据及 `../summary.md`，避免为记录自身 SHA 反复改提交。

### A-3 授权恢复后的实现与验证

- 复工核对：`7478f273d`、工作区干净，`Thu Sep 17 00:56:12 CST 2026`。协调者已明确授权直接结算链的可选时钟与随机源注入、继续 A-4、内外两份收据分工；其余禁区及 06:00 围栏不变。
- 沿既有 `SystemClock` 增加 `fixed` 命名构造，无第二时钟抽象；四函数在原取时位置消费依赖，事件、首次进度、里程碑写入统一接收该次结算时刻。被动积分 provider 和闭关真正收功入口已接线，显示用计时器保持原样。
- 事件文案、里程碑属性独立可选注入随机源；未传仍走原服务的独立随机源，不额外消耗掉落 Rng 或技能残页 math.Random。主线 DropService 仍通过其现有 now 入口注入；生产 dropServiceProvider 已接同一 systemClockProvider。
- 新完整结算守卫五场景覆盖四函数与群战里程碑；使用生产 dropServiceProvider，比较完整返回和全部 26 张持久表原始 JSON，不归一化时间。`00:04 +5: All tests passed!`（`A-3_settlement_determinism_test_4.log`）。
- 新被动/闭关守卫 `00:02 +4: All tests passed!`，原 presence 15、闭关掉落 4 项单跑通过。被动 provider 临时退回真实时钟触发 1 失败，已精确还原并复绿。
- 下游时钟新 4 项与旧事件 18 项合跑：`00:04 +22: All tests passed!`。增补里程碑新 2 项后，与旧里程碑 10 项合跑：`00:02 +16: All tests passed!`；旧断言未改。
- 主线、塔、活动、扫荡原回归：`00:07 +39: All tests passed!`（`A-3_existing_settlement_targeted_recheck.log`）。首次命令误写活动测试路径，35 项通过与 1 项路径加载失败另存，不算代码回归。
- 新测试开发中的枚举/const 编译问题、时区显示与生产 Boss 层/掉落 fixture 假设已修正；旧断言未删除或放宽，原始尝试日志保留。最终比较仍保留时间瞬间与全部持久字段。
- 全仓分析 `No issues found! (ran in 5.4s)`；格式 `Formatted 1854 files (0 changed) in 4.17 seconds.`，均退出 0。723 个受保护文件仍零字节变化。
- 下一步：在本代码提交上将主线注入时钟临时换回 DateTime.now 做破坏证红，精确还原后运行本目标完整套件；通过才标 READY 并检查时间围栏。


### A-3 收口

- 代码提交：`10466e12422170e6831ad001ba66db077dd43ddc`。提交后主线时钟破坏证红：`00:02 +3 -2: Some tests failed.`，退出 1、2 失败，SHA-256 验证原字节恢复；原始输出 `../logs/A-3_clock_break_red.log`，结构化记录 `A-3_clock_break_red.json`。
- 完整套件：`07:33 +6932: All tests passed!`，退出 0，无失败或跳过；原始输出 `../logs/A-3_full_test.log`、退出码 `A-3_full_test.exit`。比 A-2 增加 15 个测试，不删除旧断言。
- 分析/格式原始输出为 `A-3_analyze.log`、`A-3_format.log`；上述 reporter 均已实测，不复用 A-2 数字。
- 完成版残留：138 点；六个核心文件裸调用 0，两个 `_readMathRandom()` 文本误命中与闭关两个展示时钟例外均登记。旧 154 点阻塞快照保留。
- 独立审查未发现其余直接链漏传；确定性承诺针对完整显式注入依赖，不宣称范围外全部活动、任意默认随机调用或全局存储路径均已确定。

### A-4 施工恢复点

- A-3 READY：`496a1fd12`；收口执行 `date`：`Thu Sep 17 01:19:12 CST 2026`，未到 06:00，开始本目标。
- 只新增 `reducer_event_stream_golden_test.dart` 与 `test/fixtures/golden/phase0a_reducer/*.json`，不改生产 reducer。临时 mutation 由主线程串行执行并按原字节还原。
- 场景：生产 catalog 主线首关、塔第 1 层、塔第 32 层脆弱机制；均走既有生产 headless 装配入口。机制必须实际进入窗口、窗口内造成伤害并恢复，不能只检查存在配置。
- 事件原始次序、seq/tick 和关键字段均保留；再生开关默认关闭，再生时同样执行机制断言。

- 生成一次、默认两次均 `00:00 +3: All tests passed!`，退出 0。主线首关为生产真实败北终局（第 82 拍，176 事件）；塔 1 胜利（第 11 拍，22 事件）；塔 32 败北（第 671 拍，588 事件）。固定采样分别 400、400、1200 拍，包含终局空拍，不假设所有输入都能获胜。
- 塔 32 真实脆弱事件：第 85 拍开启（seq 98），第 86 拍清场命中造成 2169 伤害（seq 103），第 89 拍恢复（seq 108）；生产路由为 legacy_tower，仍经过生产映射和统一装配入口。
- 30 类事件及 131 个自有字段全覆盖；嵌套技能结果 7 字段、普攻段 4 字段、坐标原值及全部事件顺序保留。三份基准共 651383 字节。
- reducer 普通命中伤害临时加 1：`00:00 +0 -3: Some tests failed.`，退出 1，3 失败；原字节及 fixture SHA 验证恢复，恢复后 `00:00 +3: All tests passed!`。日志 `A-4_break_red.log/.json`、`A-4_golden_restored.log`。
- 初次分析仅有新增测试的 avoid_print，已改为 debugPrint，未使用 ignore；复跑 `No issues found! (ran in 3.0s)`，格式 `Formatted 1855 files (0 changed) in 5.25 seconds.`，均退出 0。原始尝试日志保留；完整套件正在执行。
