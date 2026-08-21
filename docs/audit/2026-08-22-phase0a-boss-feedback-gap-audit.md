# Phase 0A Boss 机制反馈缺口审计

> 日期：2026-08-22
> 范围：蓄力、破招、踉跄、脆弱窗口的玩家可见面
> 结论：领域/结算链已成立，Phase 0A 专属表现尚未接线；09:00 先确认表现方案，再开独立表现批。

## 事实矩阵

| 机制事实 | 当前生产事件/状态 | Phase 0A 表现消费 | 结论 |
|---|---|---|---|
| Boss 开始蓄力 | `Phase0aBossChargeStarted` | `Phase0aVfxController` switch 明确忽略 | 缺 telegraph |
| Boss 被破招 | `Phase0aBossChargeInterrupted` | switch 明确忽略 | 缺中断确认 |
| Boss 踉跄 | `Phase0aActor.staggerTicksRemaining` | Phase 0A screen 零读取 | 缺持续窗口提示 |
| 脆弱机制存在 | `Phase0aActor.vulnerabilityMult` | Phase 0A screen 零读取 | 缺机制身份提示 |
| 脆弱窗口开启 | `chargingCast != null || staggerTicksRemaining > 0` | Phase 0A screen 零读取 | 缺开/关窗提示 |
| Boss 相位变化 | `Phase0aBossPhaseChanged` | VFX switch 明确忽略 | 缺相位过渡反馈 |

代码证据：

- 事件被忽略：`lib/features/battle/presentation/phase0a/phase0a_vfx_controller.dart`
- 运行态事实：`lib/features/battle/domain/phase0a/phase0a_combat_model.dart`
- 旧 3v3 可参考但不可直接复用的组件：
  - `lib/features/battle/presentation/battle_charge_seal.dart`
  - `lib/features/battle/presentation/widgets/battle_banners.dart`
  - `lib/features/battle/presentation/avatar_status_tags.dart`
  - `lib/features/battle/presentation/widgets/battle_field.dart`

## 推荐独立表现批

只做信息表达，不改 reducer、AI、YAML、真气/CD、伤害公式或窗口时长。

1. `BossChargeStarted`：Boss 脚下蓄力墨环 + 近身题签/倒计时，锚点来自事件坐标；若事件还缺坐标，先扩可选 event snapshot，保持旧构造兼容。
2. `BossChargeInterrupted`：短促断墨/题字确认，必须与自然蓄力释放区分。
3. `staggerTicksRemaining > 0`：Boss 身侧持续踉跄标识或脚下破绽环，不用弹窗教学。
4. `vulnerabilityMult != null`：窗口外与窗口内需有可辨差异，但色彩保持克制；避免让“减伤”看成命中失效。
5. 相位变化只在同批确有视觉依赖时顺势接，不为降行数做无关重构。

## 自动验收

1. 事件到 VFX entry 的纯映射测试：charge start / interrupted 各一条，重复 seq 不重复。
2. 有 vulnerability 的 Boss：蓄力、踉跄两种窗口均显示；窗口关闭后移除。
3. 无 vulnerability 的普通 Boss：可有蓄力提示，但不得误显脆弱标识。
4. 终局后新事件不再生成表现；entry 容量满时终局封签仍保留。
5. 1280×720 与 1440×900 widget smoke 无 overflow；最终视觉仍留人类目检。

## 09:00 人类判断点

- 倒计时应表达“剩余模拟拍”还是只用无数字收束动画；当前 `chargeTicksRemaining` 是 reducer 拍，不应直接称秒。
- 脆弱窗口用脚下环、角色侧题签还是两者组合；推荐脚下环持续、题签只在开窗瞬间短显。
- 破招成功是否需要独立音效；现有素材可复用性需实听，不能仅凭文件名拍板。
- 相位变化是否与蓄力提示同屏冲突；优先保证可打断信息不被大标题遮住。

