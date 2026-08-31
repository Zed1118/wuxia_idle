# P2 M5 六模式工程集成审计结果合同

## 唯一目标

- task：`P2-M5-ENGINEERING-INTEGRATION-AUDIT`。
- 基线：`22afa6d3831b4dfb0d20df7d6694f6f7c13ff968`。
- 固定分母：二阶段方案 M5 的六个模式乘七项合同，共 `6 × 7 = 42` 格；顶层 M5 工程 Gate 只有 `42/42` 才能从 `0/1` 关闭为 `1/1`。
- 本轮上限：先对 main 上已经汇合的纵切作 production owner 重资格化；发现缺口时如实保留 `0/1 BLOCKED`，不以历史 READY 数量、测试总数或 M6 接线替代 M5。

## 七项合同

每个模式分别核对：

1. production entry；
2. 首次手动/首通门槛；
3. 门槛后的自动化解锁；
4. 奖励及 durable 防重；
5. 伤势或模式专属失败后果；
6. 模式要求的记录作用域；
7. 前台 bot、快速 headless、差遣、离线与扫荡的允许矩阵。

## 判定规则

- `PASS` 必须能指向生产 owner 和会因 owner 漂移而失败的行为测试。
- `BLOCKED` 包括缺 owner、只有存档级记录而合同要求个人记录、或只实现允许矩阵中的部分通道。
- 显式禁止自动化的心魔，其拒绝矩阵可作为 PASS；不能把“不存在入口”当作其他模式的自动化 PASS。
- 真人桌面手感、视觉与 Windows 实机继续挂账，不进入 42 格工程分母，也不因挂账阻止本轮识别代码缺口。

## 验证与停止线

1. 运行六模式生产域与共享 stage settlement 的组合 targeted，建立当前 main 基线。
2. 输出逐格 owner、测试与缺口，不新增伪装成 production policy 的常量表。
3. 若不是 `42/42`，本轮只提交阻塞证据；不创建假绿集成测试，不晋升 M5。
4. 后续必须按依赖逐项授权 schema/运行时/UI 施工，并在所有缺口进入同一 main 后重新执行本分母。

## 禁止范围

- 本审计不修改 schema/saveVersion、玩家数值、技能、奖励金额/概率、经济、解锁阈值、YAML TUNING 或战斗规则。
- 不启动 M3/M7，不重写 reducer、headless 内核或 settlement owner。
- 不把 M6 工程候选、U09/U10/U14 或任一模式纵切冒充 M5 顶层 Gate。
