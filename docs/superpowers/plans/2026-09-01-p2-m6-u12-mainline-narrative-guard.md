# P2 M6 U12：主线叙事去阻塞与搬迁守卫收口

## 结果合同

- 唯一主 WIP：`P2-M6-U12-MAINLINE-NARRATIVE-GUARD`。
- 基线：`4dc54697df9a26d26abceb58577a67368e9b63cb`，U02/U03 已有生产实现，但 U12 没有独立权威工程门，现按 `0/1` 处理。
- 目标：关闭 `1/1` U12 工程门；真人视觉验收继续挂账，不晋升 M6 或 Phase 2。
- 固定分母：21 章 × 5 关 = 105 个精确主线 ID；105 opening + 105 victory + 42 defeat = 252 个唯一旧叙事 ID。

## 必须保持

1. 全部 `StageType.mainline` 关卡不自动展示 opening、victory、defeat 阅读器。
2. 特殊模式沿用既有自动叙事行为；主线 Boss 失败仍先结算并展示事实损失。
3. 252 个旧 ID 各有且仅有一个 manifest 去向，当前全部为 `migrate`；目标和解锁证据与关卡定义一致。
4. `NarrativeLoader` 三个物理目录内，252 个 source 资产 0 orphan、0 shadow，文件 stem 与 YAML ID 一致。
5. 章节卷轴仍为可选阅读入口；manifest loading/error 不阻断选关或开战。

## 本轮真实缺口

既有守卫锁定了数量与集合，但没有锁死 `stage_01_01` 至 `stage_21_05` 的精确 21×5 拓扑。误删正式关卡并补入同数量伪关卡时，计数、manifest 与物理集合可能一起漂移而保持绿色。本轮只加固该红线，并同时锁定每关 opening/victory ID 与 `isBossStage` 对应的 defeat ID。

## 验证顺序

1. 复用既有生产路径与 43 项核心基线。
2. 三向破坏证红：主线自动阅读判据、manifest 目标漂移、物理孤儿资产。
3. 恢复后跑 U02/U03 原 12 文件保护网及新增拓扑断言。
4. `flutter analyze`、`dart format .`、锁定全量、Gate。
5. 合并 main、push，并核对精确 merge SHA 的 GitHub CI。

## 禁止范围

- 不改叙事正文或资产内容，不删旧 narrative。
- 不改解锁、奖励、经济、玩家数值、技能、战斗规则、Isar schema 或 saveVersion。
- 不进入 M3/M7，不用自动化证据代替真人视觉验收。
