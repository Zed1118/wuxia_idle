# P2 M5 R02：心魔战败摘要对齐

## 目标与合同

- 外部设计复核：Qoder CLI，精确模型 `Qwen3.8-Max`，`high`。
- 写入者：受控 Codex 子 agent；Qoder 只读复核，不直接改仓库。
- 仅修改任务登记列出的 R02 文件。
- 心魔摘要不得声称内力或修炼度发生回退；普通 Boss 摘要不得改变。
- 不增加新弹窗、新玩法或新字符串体系。
- 不改领域结算、AI、调参、存档 schema 或 R01 文件。
- 心魔行仅显示受影响角色名与 `UiStrings.innerDemonResidueNote`；旧结果中
  内力/修炼度字段保留为证据，不在摘要呈现。
- 不扩展 `DefeatLossEntry` 公共构造签名；在已有 `residueApplied` 分支早返回，
  普通 Boss 的内力、层数/修炼度与伤势逻辑保持原样。

## Qoder 实现前只读设计复核

- CLI/version：`qoderclicn 1.1.28`；model catalog 精确包含
  `Qwen3.8-Max`；实际 selector：`-m Qwen3.8-Max --reasoning-effort high`。
- catalog 命令：`qoderclicn --list-models`；复核命令：
  `qoderclicn -p --no-session-persistence -m Qwen3.8-Max --reasoning-effort high
  --permission-mode dont_ask --max-output-tokens 4000 --tools Read Grep Glob --
  "<R02 read-only design prompt>"`。
- 权限：`--permission-mode dont_ask --tools Read Grep Glob --no-session-persistence
  -p`；无 Bash/Edit/Write，未运行测试。
- 首轮完整 prompt 在 5 分 10 秒内始终 0 输出，有界 Ctrl-C 后
  `Operation aborted` / exit 1；不冒充有效结论。
- 同配置精简 prompt 重试正常 exit 0，结论 `DESIGN PASS (conditional)`，
  P0=0、P1=2、P2=3。P1 要求心魔在 `_entryLine` 顶部早返回，非心魔
  旧路径 byte-for-byte 保持，并锁定 Boss 内力相等和零回退层边界。
- P2 triage：心魔结果的 before/after 字段保留且不清零；只订正
  `innerDemonResidueNote` 过时注释；`defeatTechniqueProgressSegment` 仍被普通
  Boss 零层回退真实消费，不删除任何字符串。R01 依赖签名由集成层合并时处理。

## 验证清单

- [x] 外部设计复核有命令、版本、精确模型和结论证据。
- [ ] 心魔摘要只陈述真实发生的内息紊乱。
- [ ] 普通 Boss 摘要行为锁定。
- [ ] 定向测试通过。
- [ ] scoped analyze 为零。
- [ ] 外部最终复核无 P0/P1/P2。

## 任务切片

1. 复读规约、登记、现有生产与测试，完成 Qoder 只读设计复核。
2. 先把心魔专用行与普通 Boss 边界写成失败测试，再以最小早返回转绿。
3. 运行三个 owned targeted 及心魔/mainline presentation 相关回归、scoped analyze、
   format/diff/path/status。
4. 尝试既有 `defeat_inner_demon_residue` VISUAL_ROUTE 在 1280×720 与
   1440×900 smoke；不可达时记录未目检风险。
5. 使用同一 Qoder selector/权限做最终 actual diff 只读复核，更新证据并
   冻结 READY tip。

## 当前恢复点（CLAUDE §8.0）

- 状态：规约/登记/生产/测试已读；Qoder 设计复核有效 PASS，待 TDD 红测。
- 最后完成：冻结不扩公共构造、仅 `residueApplied` 早返回的最小设计；
  普通 Boss 内力相等/零层回退继续显示。
- 下一步：修改 owned tests 跑出有效红灯，再改生产渲染。
- 已跑验证：Qoder model catalog 与两轮只读调用；尚未跑测试/analyze。
- 阻塞项：无；R01 在另一 source task，R02 不修改其文件。

## CLAUDE §8.2 交付证据（待收口）

- 生产入口：待记录 `runStageFlow` 战败分支 → `_applyBossDefeatPenalty` →
  `buildDefeatLossEntries` → `_DefeatLossBanner` 真实消费链。
- targeted pass 数：待跑。
- 红线影响：待复核；预期零数值/三系/在线离线/反主流影响，玩家文案仅消费
  已有 `UiStrings`。
- 残留风险：待记录目检、R01 集成与未跑 full 风险。
