# 路线 C 完全拆除 3v3 · 第一前置批

## 目标

在不删除旧引擎的前提下，先消除原子切换前的生产覆盖缺口：全量主线/扫荡接入 Phase 0A，并为心魔、轻功、群战冻结新引擎语义与接线边界。

## 分工

- DeepSeek：只改主线/扫荡灰度门及对应测试，把普通主线从 Ch1 一周目扩到全部主线与合法周目。
- 主 agent：审计并实现心魔、轻功、群战的 Phase 0A 语义；复核 DeepSeek diff 后整合。

## 红线

1. 灰度门仍默认关闭；本批不删除 legacy fallback。
2. 不改 YAML 数值、伤害公式、存档 schema/saveVersion。
3. 特殊玩法奖励、伤势、阵型、解锁与事务语义不得静默降级。
4. DeepSeek 不改 `stage_entry_flow.dart`、Phase 0A mapper/reducer 或特殊玩法文件。

## 验收

1. 105 个 mainline StageDef、合法 cycle 均可进入 Phase 0A；非法 cycle 与三类特殊 stage fail closed。
2. 主线扫荡覆盖同一 mainline 范围，塔范围不回退。
3. 心魔 7、轻功 5、群战 5 均有明确新引擎契约和 production wiring 测试。
4. targeted、相关族、analyze、全量测试及 macOS 五灰度 build 全绿。

## 恢复点

- 状态：进行中。
- 基线：`b530dc66`，全量 5403/5403，analyze 0，Mac 动态目检通过。
- 当前：工作分支与 DeepSeek 隔离分支已创建，尚未修改业务代码。
- 阻塞：特殊玩法语义需先从旧 strategy/结算钩子逐项提取，禁止按普通主线静默映射。
