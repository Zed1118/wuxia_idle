# Phase 0A 移动平滑 + 普攻手感独立切片

## 目标

修复实机目检中主角移动的离散跳步与键盘漏拍，并让普攻在持续按键下稳定触发、保留生产配置的范围/扇区/伤害规则。在线实时屏与 headless/bot 共用同一固定步 reducer，不改变领域规则或数值红线。

## 分支与范围

- 分支：当前独立 fork（不触碰其他 worktree）
- 允许文件：`phase0a_battle_controller.dart`、`phase0a_battle_screen.dart`、`phase0a_player_input_adapter.dart`、Phase 0A domain reducer/model（确有必要时）、`data/numbers.yaml` 中普攻直接配置、对应测试、本计划文件
- 明确不改：`data/stages.yaml`、VFX 文件、旧 3v3、敌群内容与关卡编排

## 根因假设与验收标准

1. 固定逻辑步长为配置注入的 0.1 秒；表现层继续使用既有 `AnimatedPositioned(duration=fixedDelta, linear)`，本切片不叠加第二层 previous/current 插值。
2. 键盘移动不依赖操作系统 key repeat；KeyDown/KeyUp 维护按键集合，连续按住每个固定 tick 产生同一确定性输入，失焦/暂停时清理。
3. 普攻按住 J 或鼠标主键时，在冷却允许的 tick 继续请求；单次按键仍只产生一次请求；键盘攻击沿用朝向，鼠标攻击沿用瞄准方向。
4. 普攻射程、扇区、冷却、真气与伤害继续从生产配置/SkillDef 注入，Dart 不新增数值；本批仅将生产射程由 360 调为 420，扇区保持不变；不改变 headless 规则。
5. 位置插值仅存在 presentation；controller/domain state、事件 tick/seq、命中目标与结算结果保持固定步确定性。
6. targeted tests 覆盖：held WASD、KeyUp/失焦、held J、controller previous/current render state、领域移动确定性与普攻范围合同；`flutter analyze` 0 issue。

## 切片与恢复点

- Slice 1：计划文件与输入状态契约测试。恢复点：已完成/下一步实现 held input。
- Slice 2：screen held input 驱动；保留既有 `AnimatedPositioned` 表现动画。恢复点：待 targeted tests。
- Slice 3：回归普攻配置合同、targeted tests、`flutter analyze`；确认不改 stages/VFX。恢复点：待最终验收。
- Slice 4：检查 diff 与红线，工作区 clean，tip 提交 `[READY]` 中文交付摘要。

## 当前恢复点

- 状态：合并 Gate 返修已完成，待新 READY
- 最后完成：已读 `CLAUDE.md`、GDD §5、`docs/spec/rejected_task_registry.md`；已定位 10Hz 离散绘制与 keydown repeat 根因
- 下一步：提交 Gate 修正 commit 与新 `[READY]` tip，保持 worktree clean
- 已跑验证：初次核心 targeted 52/52 PASS；焦点/production mapper/headless/session 53/53 PASS；Gate 返修后 screen/retry/focus 41/41 PASS（含 retry 独立复跑 6/6）；返修文件范围 `flutter analyze` 0 issue；全树 analyze 被仓库内独立 phase0minus_probe 缺失依赖阻塞
- Gate 返修：补 held J 跨冷却连续请求与 KeyUp 停止、失焦清移动、Esc 清理、终局后同 controller 直接 restart 不继承、retry 等待期间 held 不继承测试；`_retry()` 成功 restart 后显式清 held。
- 红线/残留：只改普攻配置射程 360→420，扇区 0.72 弧度、伤害/冷却/真气公式不变；未覆盖实机帧率画像与 VFX 扩容（本切片明确不改 VFX）
- 阻塞项：无
