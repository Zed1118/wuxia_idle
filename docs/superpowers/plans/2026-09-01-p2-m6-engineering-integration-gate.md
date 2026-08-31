# P2 M6 工程集成 Gate 结果合同

## 唯一目标

- task：`P2-M6-ENGINEERING-INTEGRATION-GATE`。
- 基线：`a6a76917a1731fe96ed3ba650b741961eba05788`。
- 固定工程分母：M6 四条正式 Gate 合为一个 `0/1 → 1/1` 集成门；U01–U14 的历史 `READY` 只作为候选输入，不能单独晋升 M6。
- 正式边界：本门只给出工程候选；真人桌面交互、视觉可读性和 Windows 实机继续挂账，不能据此签署正式 M6 或 Phase 2。

## 四条 Gate

1. 全部生产战斗入口从同一 canonical occupancy 判定角色占用，冲突时 fail closed 且零建活动。
2. 当前掌门闭关时不可战；同一掌门恢复空闲后，主线、塔、轻功、守城、心魔、断魂庄和百草岭均能使用本人 exact snapshot。
3. 生产拓扑保持“主菜单 → 四个一级入口 → 地点/调度选人 → 亲战或差遣 → 共享结算 → 事实报告”，不回退旧三席、fixture runner 或第二结算 owner。
4. 精确 105 个主线关卡不自动弹 opening/victory/defeat 文本；特殊模式叙事行为保持。

## 实施与验证

1. 新增跨模式 Isar 集成守卫，以同一个角色验证七类 admission 的 idle/retreat 对称行为。
2. 对 occupancy 聚合、空闲判定、主菜单地图路由、返程参与者报告、主线叙事判据分别做可编译破坏证红，并用精确反向补丁还原。
3. 运行 M6 生产链组合 targeted、`flutter analyze --no-pub lib test`、`dart format .`、锁保护全量和项目 Gate。
4. 只在上述证据全部通过后登记 `ready_reviewed`，合并 push，并核对精确 main SHA 的 GitHub CI。

## 禁止范围

- 不修改 schema/saveVersion、玩家数值、技能、奖励金额/概率、经济、解锁、YAML TUNING 或战斗规则。
- 不新增 reducer、headless 内核、结算真相源或兼容回退。
- 不启动 M3/M7，不用 widget/自动化数量替代真人目检。
