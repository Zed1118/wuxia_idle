# P2 M5 R02：心魔战败摘要对齐

## 合同

- 外部设计复核：Qoder CLI，精确模型 `Qwen3.8-Max`，`high`。
- 写入者：受控 Codex 子 agent；Qoder 只读复核，不直接改仓库。
- 仅修改任务登记列出的 R02 文件。
- 心魔摘要应沿既有 `residueApplied` 语义隐藏内力与心法回退段，不扩 `DefeatLossEntry` 公共构造合同；普通 Boss 摘要及其修炼度字符串不得改变。
- 不增加新弹窗、新玩法或新字符串体系。

## 验证清单

- [x] 外部设计复核有命令、版本、精确模型和结论证据。
- [x] 心魔摘要只陈述真实发生的内息紊乱。
- [x] 普通 Boss 摘要行为锁定。
- [x] 定向测试 40/40 通过。
- [x] scoped analyze 5 items 为零。
- [x] 外部最终复核无 P0/P1/P2。

## 任务切片

1. 复读规约、登记、现有生产与测试，完成 Qoder 只读设计复核。
2. 先把心魔专用行与普通 Boss 边界写成失败测试，再以最小早返回转绿。
3. 运行三个 owned targeted 及心魔/mainline presentation 相关回归、scoped analyze、
   format/diff/path/status。
4. 尝试既有 `defeat_inner_demon_residue` VISUAL_ROUTE 在 1280×720 与
   1440×900 smoke；不可达时记录未目检风险。
5. 使用同一 Qoder selector/权限做最终 actual diff 只读复核，更新证据并
   冻结 READY tip。

## Qoder 实现后只读终审

- 命令/权限：`qoderclicn -p --no-session-persistence -m Qwen3.8-Max
  --reasoning-effort high --permission-mode dont_ask --max-output-tokens 4000
  --tools Read Grep Glob -- "<R02 read-only final review prompt>"`；CLI 仍为
  `qoderclicn 1.1.28`，无 Bash/Edit/Write。
- 首轮约 3 分钟返回：核心合同 P0=0、P1=0，列出 4 个 P2：
  不存在的 VISUAL_ROUTE 声称、测试头行号漂移、本计划恢复点未回写、
  banner 类注释未描述心魔行。
- triage：4 项均是 owned files 内可关闭的文档准确性问题，已删除
  VISUAL_ROUTE 误声称和漂移行号，更新 banner 注释及本恢复点。待同模型
  精简复核确认 P0/P1/P2=0/0/0。
- 后续在 owned widget test 将心魔摘要 smoke 扩为 1280×720 与
  1440×900 两档，均断言无 Flutter 异常/溢出且事实文本精确，3/3 通过。
  因此再用同一 selector 做一次最小增量终审，不将上述早于改动的
  PASS 充当最终证据。
- 最小增量终审命令继续使用 `qoderclicn 1.1.28` / `Qwen3.8-Max` /
  `high` / `Read Grep Glob`，正常 exit 0；确认两档 surface 设置与恢复、
  `tester.takeException()` 无异常/溢出、事实与负断言、无真实路由截图声称均正确；
  最终结论 `PASS`，P0=0、P1=0、P2=0。

## 当前恢复点（CLAUDE §8.0）

- 状态：实现与 40/40 targeted、5-item analyze=0 已完成；Qoder 首轮
  终审 4 个文档性 P2 已关闭，两轮后续复核均 P0/P1/P2=0/0/0。
- 最后完成：心魔 `residueApplied` 行仅呈现角色名与内息紊乱；
  普通 Boss 内力、层数/修炼度、伤势路径不变。
- 下一步：跑 format/diff/path/status，提交证据并追加 READY 标记。
- 已跑验证：有效红测 1 项失败；5 个定向测试文件 40/40 绿；
  `flutter analyze` 指定 5 个 owned Dart 文件，0 issue。
- 阻塞项：无功能阻塞。当前基线无 `defeat_inner_demon_residue`
  VISUAL_ROUTE，因此两档视口不可达；见§8.2 残留风险。

## CLAUDE §8.2 交付证据

- 生产入口：`runStageFlow` 战败分支 → `_applyBossDefeatPenalty` →
  `buildDefeatLossEntries` → `_DefeatLossBanner` 真实消费链；公开测试薄入口
  `buildDefeatLossBanner` 不参与生产调度。
- targeted pass 数：40/40。逐文件独立运行
  `defeat_loss_banner_residue_test.dart` 3/3、`stage_entry_flow_pure_test.dart`
  20/20、`inner_demon_defeat_summary_test.dart` 6/6、
  `stage_entry_flow_branches_test.dart` 4/4、`stage_entry_flow_test.dart` 7/7。
- 红线影响：零数值/三系/在线离线/反主流影响；不改结算数据、
  AI、调参、存档 schema 或玩法，仅收窄已有 `UiStrings` 的 UI 摘要呈现。
- 残留风险：当前 `VisualRoute` 枚举与
  `tool/visual_acceptance.dart routes --format ids` 均无
  `defeat_inner_demon_residue`，无可达 fixture 执行 1280×720/1440×900
  截图 smoke；本次以 widget surface 完成 1280×720 与 1440×900
  无异常/无溢出自动回归，但未真机截图目检仍是诚实残留风险。
  R01 仍由集成层合并，本 source task 不改其文件；按登记未跑 full。
