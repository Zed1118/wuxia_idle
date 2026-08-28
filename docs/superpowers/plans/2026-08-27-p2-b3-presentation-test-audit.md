# 批三表现层测试反模式清账计划

## 目标

在当前批二统一候选链上，完整审计 `test/features/**/presentation/**`，找出声称守卫玩家可见表现、但破坏生产渲染后仍不会变红的假绿测试；只提交审计报告，不批量修改测试或生产代码。

## 分支与基线

- 分支：`codex/p2-b3-presentation-test-audit-20260827`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-p2-b3-test-audit`
- 基线：`51aa958c [READY] 完成图层稳定验收`
- 冻结分母：130 个 presentation 测试文件，939 个显式注册用例（780 `testWidgets` + 159 `test`）。AST 本文件 helper 可达分析确认：779 条可达 `pumpWidget`，160 条不可达 widget pump/painter；后者分布在 28 个文件，进入人工复核。
- 最高风险：文件位于 presentation 目录或测试名含“renders”，但断言只停在 controller/service/mapper 的返回值。

## 固定验收标准

1. 枚举全部 `test/features/**/presentation/**` 文件及用例，不只查已知防御样例。
2. 对每个用例建立生产渲染可达性分类：真实 widget pump、直接 painter 像素、非视觉纯合同、疑似绕过、已证假绿。
3. 对疑似/已证假绿逐条记录 `file:line`、声称行为、实际断言层、不会被哪种渲染破坏击中、建议补强方式与优先级。
4. 单列键盘 `E/F/Z` 等玩家可见入口的零覆盖或弱覆盖，不把 grep 缺口冒充已复现缺陷。
5. 至少对最高优先级代表项做受控破坏证红/证不红；临时改动必须恢复且不得进入提交。
6. 产出 `docs/audit/test_antipattern_presentation_layer_2026-08-27.md`，核心结论约一页，完整证据放附录。
7. 报告中的路径与行号在当前分支按符号重新定位；发现交接描述偏差立即记录，不顺着错误前提。
8. 工作区最终只含计划与审计报告，禁区文件零 diff，tip 为 `[READY]` 或有明确 blocker 时 `[BLOCKED]`。

## §8.2 交付检查

- 生产接线证据：报告必须把每条测试追到实际 renderer/widget/painter 消费方；纯检索不算。
- targeted 验证：运行审计中用到的代表测试，并保存破坏实验的红/绿差异与退出状态。
- 红线影响：只读测试审计，不触及数值、三系、在线离线、玩家规则或文案数值硬编码。
- 残留风险：明确静态可达分析的边界、未执行的破坏矩阵与需要后续修复的测试。
- UI 加码：本批不改 UI；不以截图或直接 VisualRoute 代替生产渲染可达性判断。

## 任务切片

1. AST 复核并冻结分母，建立可达性初筛。
2. 人工复核所有无 widget/painter 可达路径与高风险命名用例。
3. 对最高优先级样例做受控破坏实验并恢复。
4. 写报告、复核证据、提交并打就绪标记。

## 当前恢复点

- 状态：审计与三组 mutation 已完成，报告已写；等待 Git 收口与就绪标记，不计 Phase 2 顶层 Gate 进度。
- 最后完成：160 条人工复核得到 154C/6F；临时破坏均恢复，当前只剩计划与审计报告两份文档改动。
- 下一步：复核禁区/main/integration 状态，提交报告并打 `[READY]` tip。
- 已跑验证：恢复后相关测试逐文件 3/28/3/5 全绿；`flutter analyze --no-pub lib test` 0 issue。无路径 analyze 因既有 `tools/phase0minus_probe` 独立包配置债返回 1943 issue，已在报告列为残留风险。
- 阻塞项：无。
