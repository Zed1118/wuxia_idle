# Phase 0A 鼠标普攻与六技能控制迁移计划

> 日期：2026-08-20
> 分支：`codex/phase0a-real-skill-bindings-0820`
> 状态：WIP
> 用户拍板：正式入口改为鼠标左键普攻；J 仅兼容；数字 1–6 触发真实技能；固定 Q/R 战术技长期并入真实技能效果。

## 目标

把 Phase 0A 的灰盒 J/Q/R 输入迁为桌面正式控制：鼠标左键按点击方向普攻，数字 1–6 对应真实装配技能，所有成功释放与结算均携带真实 `SkillDef.id`，内部 slot/kind 不进入熟练度账本。

## 架构事实

- 当前输入 Module 只有 attack/gather/clear 三种语义，`Phase0aDamageKind` 也只有 basic/gather/clear；直接把 1–6 伪装成这三类会污染伤害、Qi/CD、事件和熟练度。
- Character 实际有 7 个槽：main1/main2/assist/resonance/ultimate/key/encounter。数字栏按稳定六槽 main1/main2/assist/resonance/ultimate/encounter；key 是破招专槽，后续走上下文破招动作，不挤占数字键。
- `SkillDef` 有 targetType/qiDelta/cooldownTurns/power，但没有 realtime range/effectRadius/pull/stagger；generic skill Adapter 必须显式解析这些运行参数，不能让 reducer 回查仓库或猜默认值。
- 鼠标坐标必须经 presentation `screenToWorld` 逆变换后进入 command aim；屏幕像素方向不能直接当世界方向。

## 迁移切片

### Slice 1 · 鼠标左键普攻

1. [x] `Phase0aStage.screenToWorld` 与两视口可逆测试。
2. [x] `Phase0aPlayerCommand.attackAimDirection`；input Adapter 有 aim 用 aim，无 aim（J）用 facing。
3. [x] stage layer primary pointer down 发起一次 attack；按住跨冷却持续请求；HUD/技能印/暂停/终局不冒泡；J 保留兼容。
4. [x] targeted + analyze，提交恢复点。

### Slice 2 · 六槽身份与 fail-closed 输入

1. [x] neutral snapshot 显式保存 7 槽身份，不靠压缩 `availableSkills` 猜槽位。
2. [x] 数字 1–6 → stable slot request；空槽/未装备严格拒绝，零 event/伤害/Qi/CD/RNG/熟练度。
3. [x] 六槽技能印可点击、键盘/鼠标同路；第七破招槽不占数字栏。

### Slice 3 · generic 真实技能结算

1. [x] `Phase0aSkillBinding` 深 Module：SkillDef + resolved geometry/Qi/CD/behavior。
2. [x] generic intent/reducer/event；真实 id/power/proficiency/targetType 贯穿。
3. [ ] Q pull/R stagger 从固定按键语义迁到显式 behavior binding；旧 gather/clear 作为迁移 Adapter 后删除。
4. [x] settlement 直接消费事件真实 skillId；live/headless skill casts 同 seed 一致。

## 红线

- 不把数字 4–6 静默降级为 basic/gather/clear。
- 不硬编码伤害、Qi、CD、范围；不直接把 cooldownTurns 当秒。
- 不改 SkillDef 数学、三系锁死或 YAML，除非后续 behavior schema 另行拍板。
- 鼠标左键只攻击，不点击移动；J 兼容使用当前 facing。
- 本计划各 Slice 独立绿、独立恢复点；第一切片不假装六技能已完成。

## 当前恢复点

- 最后完成：数字 1–6 generic 主链：真实 basic/六槽 binding、SkillDef Qi/CD/targetType、single/aoe reducer、真实事件/伤害/结算、bot、六技能印与键鼠同路；空槽/unsupported mechanics fail-closed；真 Isar e2e 与 Phase 0A 三层 **296/296**、analyze 0。
- 下一步：提交 generic 技能恢复点；Q pull/R stagger 因 SkillDef 缺 behavior/geometry 仍保留迁移 Adapter，先跑全量与 Ch1 画像，再决定 schema 切片。
- 阻塞：Slice 1 无；Slice 3 的 cooldownTurns→seconds 与 pull/stagger 数据归属需在进入该切片前冻结。
