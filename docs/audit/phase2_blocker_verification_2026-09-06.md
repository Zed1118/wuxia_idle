# 二阶段全阻塞验证 · 2026-09-06

本轮按用户“自行制定测试并验证所有阻塞”执行。开局 `e07a6a9f0` clean，修复代码 `4ed04ae42d1233f080ffde81bed148ea369be96d`；正式 M0–M9 仍 **1/10，仅 M1 关闭**。本报告覆盖全部开放门的可测部分与剩余条件，不把自动化、补充密度 fixture 或 AI 操作记作自然人验收。合入范围仅是首胜续关修复、Windows 启动验证与收口记录；新发现的战斗/音频/性能缺陷未在本批修复，不能据此发布。

## 核心结果

- **已修复**：首次胜利 invalidate 进度会卸载 StageList 的 LayoutBuilder 子树，续关 closure 的 context 因而失效。改为捕获页面根 context；真实创建角色、输入战斗、首胜、Next 的新增回归有效 RED→GREEN。没有改动数值、敌人、奖励、解锁、schema、存档格式或攻击规则。
- **已验证**：合法学徒冷副本通过真实 widget 输入连续赢五关（含黑风岭 40 杀），经真实叙事/章末返回后重开 Isar，五关 cleared、五条结算 journal 均 closed、参与者与 runId 一致、loadout version 1–5。无伪造胜利/抬血/预写通关；这属于生产输入与持久化工程证据，仍不是原生鼠标长按或真人 G2 签字。
- **回归与平台**：相邻 4 文件 13 项、持锁全量 **6067/6067**、analyze 0 issue、修改文件 format 0 changed。当前代码 macOS Profile 构建成功，独立签名包已从正常菜单/冷存档启动并完成轻功进入→败局→返回。Windows unsigned release 在 CI 实际打开窗口，进程观察 17.06 秒；未代签实体 Windows 的键鼠、音频或 GPU。
- **前三缺陷/风险**：① 自动战斗近身折返与瞄准配合造成暗器停滞；② 密集战斗性能未达标，带声十分钟内存增长至约 2.42 GiB 且原生音频告警反复出现；③ 减少闪光开关没有被受击表现消费。后两种窗口的静音对照有改善但仍红，不能把音频当作唯一性能根因。

## 固定阻塞矩阵

| 门 | 本轮实际执行与结果 | 尚缺／下一步 |
| --- | --- | --- |
| M0 | 查真实生产引用：ActionTimeline/QiResourceLedger 仍无消费路径 | 接线、测量、七心魔逐身份确认；不能测试尚未实现的路径 |
| M1 | 当前完整回归通过；原已关闭门保持关闭 | 不重复申请签字 |
| M2 | 首胜续关 RED→GREEN；合法五连关和重开存档通过；鼠标两秒开/点按关、Q/R、失焦/暂停取消及 Boss 主动接敌守卫随全量通过 | 暗器 Bot 停滞修复；原生长按手势、完整 Boss 学习性及真人 G2 |
| M3 | 正常存档 EquipmentService 合法装备剑/重兵/软兵/双兵/暗器 5/5，身份进入真实快照；45 格生产矩阵回归通过 | 45 格使用强测试角色，不证明平衡；合法实装的五种手感仍需真人 |
| M4 | 30 MP3 全文件解码；1280×720/1440×900 原生密度与静音对照；持续运行见附录 | 帧门失败、音频异步告警、2 个借用音效；真人听感/可读性与物理 Windows |
| M5 | 真实塔战/结算、轻功/守城 durable、断魂扣帖/恢复、远征节点等定向守卫；当前包原生轻功败局返回 | 六模式当前包的所有胜负/恢复 UI 路径未穷举；不搬用旧版本实机 PASS |
| M6 | 真实五关导航、章末叙事、返回、receipt 闭合；真实 Isar 七入口准入与武学/行囊导航守卫 | 全部一级 Hub 可理解性与跨页面完整人工验收 |
| M7 | 主线 catalog 实数 105/105，塔 0/49；候选塔 42 接受错误目标并早胜的反例已复现 | 先补目标类型/全目标约束、三入口行为及完整 parity，再迁 49 层、退役 5 处接缝；反例尚未进入当前 legacy 生产塔 |
| M8 | 10 项旧档/版本/幂等守卫；真实 Boss 命中下减少闪光两组完全相同（alpha 0.76） | 无效设置修复；效果/震屏与领域状态一致性；72 小时、长离线及平台矩阵 |
| M9 | 当前修复源码打包、Windows 原生启动；远端 CI 见收口记录 | 上游门、实体平台、最终发布冻结仍开放 |

辅助定向 **64/64（15 文件）** 与全量存在重叠，不相加；外部探针“执行成功”可能意味着复现缺陷，不能算修复通过。原生轻功败局只证明可判定终局与返回，操作间隔包含自动化工具延迟，不用于难度评价。

## 关键反例及再验标准

| 项目 | 复现／对照 | 修复后必须证明 |
| --- | --- | --- |
| 暗器自动停滞 | 同一合法冷档和 seed：原 Bot 300 秒/5 杀仍 ongoing；只改瞄准 300 秒/1 杀仍 ongoing；进入射程停止折返且精确瞄准的测试指令 30.8 秒/40 杀 victory，余血 529 | 生产 Bot 在五类武器、近身/边缘/不同战术继续输出，无新增射程/伤害/移动规则，不影响手动输入 |
| 减少闪光 | 同一 Boss tick 47 命中 1154；开关两组 alpha 0.76、100ms 有、600ms 无，设置已保存 | 真实战斗表现消费开关，命中/伤害/战斗结果不变 |
| 音频与性能 | 带声音两轮 native continuation 告警；四轮帧门红；静音改善但未消除超标 | 对真实 AudioPlayersBackend 的并发复用做复现与修复，再双视口 3×60 秒、长时、原生音频复验；不可仅跑假后端或素材解码 |
| 塔目标约束 | typed 塔 42 survive 1 拍→3 拍 victory、3/3 敌人仍存活；1/3 目标也被接受 | 错误目标 fail closed；完整目标集合和生产三入口/actor parity 通过后才能迁层 |

另：`BACKLOG.md` 的旧 CI 首次失败根因、isar/analyzer 与 Flutter SDK 升级依赖，本轮没有获得新的解锁证据，继续保留。首胜 Next 的 context 缺陷不等于历史 run 33950577057 的超时根因，不能串换销账。

## 可复验命令

```sh
flutter test --no-pub test/diagnostics/mainline_real_first_victory_navigation_test.dart test/features/mainline/presentation/mainline_ch1_continuous_run_test.dart test/features/mainline/presentation/mainline_durable_settlement_recovery_test.dart test/tools/ci_workflow_contract_test.dart
flutter analyze --no-pub lib test tool
# 全量仅经 /Users/a10506/.claude/locks/wuxia_full_test.lock 互斥执行
flutter test --no-pub --reporter expanded
```

以上依次为 13 项通过、0 issue、6067 项通过。native/武器/旧档探针及参数见原始证据目录，不要求把几十个定向日志重新跑成全量。

## 证据与限制

全部原始日志、输入探针、重开存档结果、原生截图、帧/GC/RSS 数据与 Windows 启动 artifact 存于：`/Users/a10506/Documents/Codex/2026-09-06/wuxia-blocker-tests/`。

- 主链：`legal-chain-complete.json`、`legal-chain-final-pass.log`、`legal-chain-probe.dart.txt`；新增回归 `navigation-red.log`、`navigation-final-targeted.jsonl`、`aux/navigation-review.md`。
- 全量：`full.log`、`full-result.json`（844.72 秒）；静态：`analyze-final.log`。本轮仅一次完整全量，未因诊断失败反复全跑。
- 武器：`real-inventory-survey.json`、`real-weapons-summary.json`、`hidden-stall-diagnosis.json`；三个暗器对照均保留源探针与完整结果。
- 辅助：`aux/REPORT.md`、`aux/blocker_matrix.json`、测试清单、音频解码、减少闪光及塔目标反例。辅助基线 e07，4ed 仅变 StageList context；最终 6067 全量覆盖统一候选。
- 平台：`package.json`、`profile-package.json`、`native-saves.png`、`native-lightfoot-defeat.png`、`profile/`；AOT `6946fca4748e5718a15a7dec95ac3b7d281cf3e836b53020d5f1e55c73262f5c`。
- 数据：生产原档三文件前后 SHA-256 完全一致，见 `original-saves-after.json`；未动用户 humanfix 试玩档。所有新原生包使用独立 bundle/container，所有 headless/widget 写入临时冷副本。

## 原生密度与持续运行结果

| 视口/声音 | 采样秒数 | 帧数 | p99 total ms | 严重连续帧 | RSS 起→终 MiB | 原生音频告警 | 帧/RSS 门 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1280x720 / 静音 | 60 | 7050 | 26.532 | 1 | 264.2→287.4 | 0 | FAIL / PASS |
| 1280x720 / 带声 | 60 | 4120 | 69.644 | 4 | 286.6→346.8 | 168 | FAIL / PASS |
| 1440x900 / 静音 | 60 | 6880 | 28.708 | 1 | 261.0→285.4 | 0 | FAIL / PASS |
| 1440x900 / 带声 | 60 | 4129 | 78.956 | 4 | 273.6→339.2 | 124 | FAIL / PASS |
| 1280x720 / 静音 | 600 | 65746 | 29.385 | 3 | 254.2→333.9 | 0 | FAIL / PASS |
| 1280x720 / 带声 | 600 | 36690 | 106.215 | 18 | 283.2→2476.8 | 2874 | FAIL / FAIL |

全部 run 正常退出、GC 遥测完整。带声 600 秒样本最终 RSS 约 **2.42 GiB**，原生 continuation 告警 **2874** 条；9 分 21 秒时 Dart 堆约 40.3 MiB、外部堆约 16 KiB、进程约 1.70 GiB。增长主体不在 Dart 堆，提示原生音频/图形资源问题；目前未用分配追踪闭合具体泄漏根因。静音长期样本 RSS 门通过但帧门仍红，因此不能把所有卡顿归因于声音。两组都不是 72h 测试。

## 性能采样方法与有效性

同一 AOT、同一 `phase0a_m4_density_profile`（24 active）、DPR 2、12 秒预热 + 60/600 秒采样 + 30 秒冷却；用真实 macOS 窗口、FrameTiming、GC 与逐秒 RSS。两种逻辑内容尺寸均由原生窗口参数设置并在 summary 中回读。全量/构建结束后才启动采样；窗口以未绑定 F15 激活，保留首轮截图及宿主进程负载，不宣称无系统/观察工具开销。

60 秒轮次要求至少 3000 帧、p99 total <16.6ms、严重连续帧 ≤1、build/raster 连续超预算 <3、GC 完整、RSS end ≤ start×1.1 +64MiB。两种尺寸首轮均红，因此转做静音因果对照，不机械重复成三轮“全绿”；正式 3×2 性能门仍开放。600 秒样本只证明短期持续运行，不代表 72 小时或真人长时间操作。

测试夹具异常单独保留：直接改隔离包 plist 未刷新 macOS 已缓存偏好，首个原计划带声的 600 秒 run 实际 `muted=true`。已通过只读 VM `getObject` 读取真实 SoundManager `_settings` 核实，标记为静音样本；第二个全新 bundle/container 的 600 秒 run 在采样开始即核对 `muted=false`、真实 AudioPlayersBackend 与 80/70/90 音量。没有用磁盘配置冒充运行时状态，也未修改 VM 对象。

## 当前代码远端验证

- [CI 34005471171](https://github.com/Zed1118/wuxia_idle/actions/runs/34005471171)：精确代码 SHA `4ed04ae42`，测试、覆盖率门槛、macOS build 全部 success。
- [Windows 34004669034](https://github.com/Zed1118/wuxia_idle/actions/runs/34004669034)：同 SHA build + native startup success；运行时 stdout/stderr 均为空，startup JSON 留有 exe 哈希、窗口观察及进程存活时长。unsigned 发布 artifact 约 130 MB，不能当作正式签名分发。
- 独立复核对 context 修复无阻断发现；指出测试早期异常未清理资源，已在创建 temp 后注册 `addTearDown`，最终定向与全量均包含修正。

## 执行成本与收口

09:24:10 CST 起，主成本为墙钟，首轮 90 分钟上限；47 分钟检查点已报告五连关证据增量，正式 Gate 增量 0。本轮主动测试与取证约 72 分钟完成；正式 Gate 增量 0，生产导航缺陷修复 1 项，合法五关闭环及重开存档证据闭合。一次独立复核带来测试资源清理修正；集成尚未发生返工。最终文档之外的 lib/data/test/workflow/tool 与 4ed 完全一致，后续只做受控集成和既有 CI 等待，不扩展施工。集成 SHA 与 CI 见外部 integration-final.json / main-ci-final.json（收口生成）；无需新的产品决策。
