# Phase 2 U14 特殊模式允许矩阵与地点入口全状态路由结果合同

- 单一目标：六类特殊模式的允许矩阵由真实生产 admission 消费，并以地点/角色入口全状态路由测试证明 fail closed。
- 固定验收门：`0/1 → 1/1`；只有六模式允许矩阵与对应生产入口全状态路由同时成立才关闭，不按测试文件数拆分冒充进度。
- 实时基线：六模式中只有断魂庄拥有 typed automation policy，百草岭拥有 typed dispatch request；塔、轻功、守城、心魔没有 `ActivityParticipationRequest` 生产消费者。
- 当前关键阻塞：冻结矩阵允许的塔/轻功/守城首通后自动/差遣路径尚无生产 admission/runner 入口，心魔也没有 typed manual-only admission；纯新增声明表和单元测试不会证明生产接线。
- 90 分钟停止线：若不能在不新增 reducer/session/headless 内核/provider/settlement 真相源的前提下把六模式接到真实 owner，则停止并证据化 BLOCKED，不扩展成跨 M5/M6 大爆炸施工。
- 主成本读数：墙钟；审计只运行参与请求、断魂庄 admission、百草岭 typed dispatch 与江湖地点展示相关定向回归。
- 非目标：schema/saveVersion、YAML、TUNING、奖励、经济、解锁阈值、叙事、战斗规则、统一报告或 main。

## 审计结果

- 固定验收门保持 `0/1`，状态 `BLOCKED`。
- 现有定向合同与地点展示回归 `90/90 PASS`，只能证明已存在路径没有回归，不能补出四个缺失的 typed production admission。
- 后续解阻必须先按塔、轻功、守城、心魔分别建立真实 production admission/runner 纵切，再由 U14 做一张穷举允许矩阵和入口全状态复核；不得先写一张无人消费的“真值表”。
