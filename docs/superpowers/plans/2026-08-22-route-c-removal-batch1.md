# 路线 C 完全拆除 3v3 · 第一前置批

## 目标

在不删除旧引擎的前提下，先消除原子切换前的生产覆盖缺口：全量主线/扫荡接入 Phase 0A，并为心魔、轻功、群战冻结新引擎语义与接线边界。

## 分工

- DeepSeek：只改主线/扫荡灰度门及对应测试，把普通主线从 Ch1 一周目扩到全部主线与合法周目。
- 主 agent：审计并实现心魔、轻功、群战的 Phase 0A 语义；复核 DeepSeek diff 后整合。

## 红线

1. Phase 0A 生产门已于 `eb73f4e5` 改为默认开启；Windows 实机
   Gate 通过前仅保留 `dart-define=false` 紧急回退保险。
2. 不改 YAML 数值、伤害公式、存档 schema/saveVersion。
3. 特殊玩法奖励、伤势、阵型、解锁与事务语义不得静默降级。
4. DeepSeek 不改 `stage_entry_flow.dart`、Phase 0A mapper/reducer 或特殊玩法文件。

## 验收

1. 105 个 mainline StageDef、合法 cycle 均可进入 Phase 0A；非法 cycle 与三类特殊 stage fail closed。
2. 主线扫荡覆盖同一 mainline 范围，塔范围不回退。
3. 心魔 7、轻功 5、群战 5 均有明确新引擎契约和 production wiring 测试。
4. targeted、相关族、analyze、全量测试及 macOS 默认路径 build 全绿。

## 恢复点

- 状态：第一前置批已完成；进入共享依赖拆分与原子删除准备。
- 当前：`eb73f4e5`，主线/塔/扫荡/远征/断魂庄默认 Phase 0A；
  149/149 production preflight 与历史多人会话退役事务已落地。
- 当前施工：将快照装配、真气周期与结算等中立能力从旧 3v3
  闭包抽离，再冻结删除 manifest 与负向源码守卫。
- 外部硬条件：Windows 发布目标机 2 视口 × 3 物理运行证据仍缺，
  Mac 证据不替代 Windows Gate；未通过前不执行最终旧引擎删除。
