# Phase 0A 战斗爽感竖切片计划

## 目标

把 Phase 0B 已有的水墨长卷、祖师、山贼与精英素材接入 Phase 0A 真实可操作战斗，集中验证基础攻击、Q 聚怪、R 清场约 15 秒核心循环的可读性与释放感。

## 分支

`codex/phase0a-combat-feel-slice`

## 验收标准

- 生产接线证据：`PROBE_MODE=playtest` 的真实 `GameplayGame` 使用水墨场景、角色图集和动作反馈，不新增孤立演示模式。
- 基础攻击、聚怪、清场各有不同且克制的动作姿态、墨迹反馈与群体受击反应；主角和精英不被特效遮挡。
- 角色按脚底纵深排序，常规桌面视口 1280×720 与 1440×900 可操作、HUD 可读。
- 保持 Phase 0 探针隔离，不接根应用、不改生产数值/存档/奖励，不触及三系锁死、在线=离线及反主流红线。
- 增加直接相关 widget/渲染契约测试，并运行 probe targeted tests、`flutter analyze` 和双视口 visual smoke。
- 保留键盘焦点、鼠标攻击与现有确定性战斗结算；不把正式美术品质或 Phase 0A 跨平台 Gate 宣称为完成。

## 任务切片

1. 接入长卷背景、角色图集与脚底纵深排序。
2. 强化基础攻击、聚怪、清场的水墨反馈与群体形变。
3. 收敛 HUD 和屏幕氛围，补渲染契约测试。
4. 跑 targeted/analyze，完成 1280×720、1440×900 真机目检并记录风险。

## 当前恢复点

- 状态：完成，待用户继续真机体验与上游评审。
- 最后完成：Phase 0A `playtest` 已接入长卷、祖师/山贼/精英图集、脚底纵深、墨迹反馈与等宽技能 HUD；根据用户反馈补入同一左键的 150～420 像素窄幅掌风，并修正 1440×900 留白和胜利态 `Wave 4/3`。
- 下一步：用户体验掌风命中感与 Q→R 爽感；若通过，由上游按 §8.2 决定合并，不在本分支扩展批量美术。
- 已跑验证：`flutter analyze`（0 issue）；`flutter test test/gameplay/gameplay_visual_slice_test.dart test/gameplay/gameplay_game_test.dart test/gameplay/combat_rules_test.dart`（25/25 pass）；1280×720 与 1440×900 macOS 真机 visual smoke，键鼠/焦点/HUD 均可见，1440×900 背景已满屏。
- 阻塞项：无代码阻塞。残留风险为暂未接正式音效，动作仍是六姿势图集切换而非骨骼动画；本切片不代表 Phase 0A 跨平台 Gate 或根应用生产接线完成。
