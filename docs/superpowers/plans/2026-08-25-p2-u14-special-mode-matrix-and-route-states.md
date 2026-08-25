# Phase 2 U14 特殊模式允许矩阵与地点入口全状态路由结果合同

- 单一目标：六类特殊模式的允许矩阵由真实生产 admission 消费，并以地点/角色入口全状态路由测试证明 fail closed。
- 固定验收门：`0/1 → 1/1`；只有六模式允许矩阵与对应生产入口全状态路由同时成立才关闭，不按测试文件数拆分冒充进度。
- 实时基线：断魂庄、百草岭、心魔与九霄塔已有 typed production consumer；九霄塔已关闭首通后 headless admission 子门。轻功、守城仍缺固定门要求的 bot/headless/差遣完整生产 admission。
- 当前关键阻塞：轻功/守城即时 headless 可复用既有 runner，但差遣没有 durable run/session、共享占用、离线推进和返程报告 owner；守城还缺阵型持久快照。纯声明矩阵或只接即时 headless 不能证明完整生产接线。
- 90 分钟停止线：若不能在不新增 reducer/session/headless 内核/provider/settlement 真相源的前提下把六模式接到真实 owner，则停止并证据化 BLOCKED，不扩展成跨 M5/M6 大爆炸施工。
- 主成本读数：墙钟；审计只运行参与请求、断魂庄 admission、百草岭 typed dispatch 与江湖地点展示相关定向回归。
- 非目标：schema/saveVersion、YAML、TUNING、奖励、经济、解锁阈值、叙事、战斗规则、统一报告或 main。

## 审计结果

- 固定验收门保持 `0/1`，状态 `BLOCKED`。
- 心魔 manual-only 子门已由 `0/1 → 1/1`，但 U14 整体固定门仍 `0/1 BLOCKED`。
- 九霄塔子门已由 `0/1 → 1/1`；轻功和守城仍各 `0/1 BLOCKED`，因此 U14 整体保持 `0/1 BLOCKED`。
- 既有合同与路由证据继续有效，但不能补出两个缺失的 typed production admission。
- 后续解阻必须先获授权建立轻功/守城 durable dispatch owner（或明确移除差遣分母），再由 U14 将六模式真实消费者与全状态路由合并复核；不得先写无人消费的“真值表”。
