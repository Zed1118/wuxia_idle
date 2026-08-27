# 批二 2.2：破势三通道反馈实施合同

## 单一目标

让玩家能从敌人本体、持续蓄条和开窗瞬间三个通道感知权威 posture 状态，并明确区分“破势开窗”和“破招打断”。

## 固定验收门

- 累积过程以头顶蓄势条替代纯数字；条值直接来自 `PostureState.accumulated/capacity`，不维护第二份状态。
- `isVulnerable` 期间敌人本体出现可辨认的倾斜和暖金洗色，窗口结束后随状态恢复。
- `vulnerabilityEntered` 生成独立 `postureBroken` VFX，在目标锚点显示程序化墨裂与“破势！”；不再复用破招 VFX。
- `lib/shared/strings.dart` 仅在用户已授权的窄范围内新增破势文案并把原打断文案明确为“破招！”。
- 真实 Boss 生产流测试覆盖：姿态条累积、开窗本体状态、开窗非零尺寸/非透明像素、破势/破招文案分离。
- 临时短路开窗渲染时新增测试必须变红，恢复后相关回归和 `flutter analyze --no-pub lib test` 通过。
- 除获准的 `lib/shared/strings.dart` 外，其余禁区零改动；工作区 clean，tip 为 `[READY]`；不 merge、不 push、不碰 main。

## 实施切片

1. 拆分 VFX kind 与文案语义，补事件映射测试。
2. 用权威 posture 状态替换头顶数字为蓄势条，并接入本体失衡状态。
3. 绘制锚定式破势墨裂，补真实 Boss 屏幕像素测试与破坏证红。
4. 运行姿态/Boss/战斗屏回归、静态检查和禁区审计，提交 clean READY。

## 基线与计数

- 基线：`4747e7ba [READY] 完成三系技能特效验收`。
- 本门关闭前批二为 `1/3`；仅代码完成或控制器绿测不计门关闭。
