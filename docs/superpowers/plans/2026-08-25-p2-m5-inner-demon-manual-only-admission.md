# Phase 2 M5 心魔本人手动准入结果合同

- 单一目标：角色面板当前目标本人以 typed `direct + human + realtime + firstClear|replay` 请求进入既有心魔 live stage flow；其他 tuple、错人和资格漂移全部 fail closed。
- 固定验收门：`0/1 → 1/1`；必须同时证明角色面板身份传递、typed policy、exact participant snapshot、真实 `runStageFlow` 消费与共享结算归属。
- 实时基线：角色面板构造 `InnerDemonScreen()` 时丢失目标角色 ID；screen 直接调用 `runStageFlow`，默认参与者可与“本人”不一致；没有 typed admission。
- 最高杠杆阻塞：`runStageFlow.directParticipantSnapshot` 目前只允许轻功/守城，需要在不扩其他模式的前提下允许 innerDemon exact snapshot。
- 预期增量：心魔子门 `0/1 → 1/1`；顶层 M0–M9 仍 `1/10`，M5/M6/U14/Phase 2 不晋升。
- 成本上限：90 分钟无门变化停线；主成本读数为墙钟，验证定向、心魔域、相邻 stage flow 与 scoped analyze。
- 非目标：心魔 AI、失败数值、奖励、自动化、差遣、headless、扫荡、schema/saveVersion、YAML、TUNING、叙事、战斗规则、provider 或 main。

## 验收证据

- RED：typed policy、production resolver、角色目标传递与 direct innerDemon stage seam 在实现前失败。
- Green：穷举 request tuple、错人/悬空/死亡/疗养/占用/无主修/错装配 fail closed。
- Production：`CharacterPanelScreen` 传目标 ID，`InnerDemonScreen` 只把 admission 返回的 exact snapshot 交给既有 `runStageFlow`。
- Completion：定向与相邻域、analyze、diff check、双向白名单、registry/文档与 clean READY。
