# 二阶段 M1 候选整合审计

## 结果

本批把 M0 证据与 C02–C10 九个互不重叠的纯领域候选整合到独立分支。联合验证通过，`main` 与生产路径未改。当前交付是 G1 契约评审底座，不是生产接线完成态。

| 切片 | 领域结果 | 主审补强 |
|---|---|---|
| C02 几何 | 扇形、双圆、胶囊、位移轨迹、自身状态 | 稳定距离/ID 排序、非有限锚点 fail closed、lint 清零 |
| C03 时间线 | windup/active/recovery/终态、首效、取消/失败冷却标记 | 事件值语义、取消窗边界、零前摇/零收招和 off-by-one |
| C04 防御 | 五正交 flags、闪避/化解/重定向/格挡/减伤/反击 | 移除 flags 错误耦合、非有限伤害钳制、nonRecursive 安全合同 |
| C05 姿态 | 单一累计、破势窗口、恢复策略、Boss 控制折算 | 结构相等性与确定性 |
| C06 状态 | slow/root/内伤/毒、刷新/叠层、固定拍 | 新 spec 刷新、快照隔离、绝对逻辑 tick、批量与逐拍一致 |
| C07 真气 | 预留/提交/取消、单动作产气、击杀窗口 cap | 调低 cap 时负额度不得反向扣气 |
| C08 普攻链 | 五武器 identity、段/引用/连段重置 | 模板引用可复用、opaque ID 规范、相等/hash 一致 |
| C09 特性 | 刚猛/灵巧/阴柔正交 modifier | 复用 `TechniqueSchool`、正因子、溢出 fail closed、完整 bounds copy |
| C10 事件 | 九阶段顺序、稳定 tie-break、只读表现 feed | 未排序/重复输入 fail closed、feed 字段非空、输入快照固化 |

## 验证证据

- `flutter test --no-pub` 九个定向测试文件：`77/77`。
- `flutter analyze --no-pub` 九实现 + 九测试：`No issues found`。
- 新 worktree 初次全仓分析因忽略的 `.g.dart` 与归档 `tools/phase0minus_probe/.dart_tool` 未生成而产生环境型连锁错误；执行根包 build runner 和该子包 `flutter pub get` 后，全仓 `flutter analyze --no-pub` 为 `No issues found`。
- 所有生成/依赖产物均位于隔离 worktree 且被忽略；未改 `pubspec.lock`，未升级依赖。

## 未接生产的原因

公共 reducer/model、数据 schema、存档与生产 route 必须由 G1 单一 owner 冻结后再接线，否则并行候选会把未决产品语义固化进长寿 API。当前九模块刻意保持纯领域和调用方注入，不写最终平衡值。

## 下一批入口

1. 先由用户处理 G0 的 `PROPOSED` 与 `proposed_reopen` 条目。
2. G1 单 owner 审核 C02–C10 的 ID、enum、事件与序列化边界。
3. 以黑风岭生产纵切接入 C02–C10，再进入 C11–C17 和 E01–E04；每个接线任务必须先证红、后实现、再跑同核 targeted。

