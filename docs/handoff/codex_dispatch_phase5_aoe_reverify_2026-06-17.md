# Codex 派单：aoe 全体伤害 + F debuff 复验 · 2026-06-17

**项目：** 挂机武侠 · `/Users/a10506/Desktop/Projects/挂机武侠`
**分支：** `feat/phase5-battle-experience` · HEAD `5d1be323`(含 aoe 全体伤害实装 6 commit + F debuff 场景修)
**先读：** PROGRESS 续21 + GDD §5.8(招式目标类型) + CLAUDE §5 红线
**角色：** Codex = Mac 本地真机交互视觉验收。本轮复验 aoe 全体伤害 + F debuff,并复确认上轮已过项。

---

## 背景

上轮复验(报告 `codex_phase5_mainline1_reverify_2026-06-17.md`):**C-aoe 拖招不通过**(万钧裂空只命中单个敌人,未对全体扣血)、**F debuff 无法确认**(场景我方全 gangMeng,触发不了内伤)。本次已:① 实装 **aoe 全体伤害**(各目标完整伤害·无衰减·GDD §5.8),② **F 场景修**(scenarioDragLive 弟子甲改 lingQiao,敌 yinRou 攻击触发内伤)。

## 启动(关键:禁加 DEVELOPER_DIR)

```
flutter run -d macos --dart-define=VISUAL_ROUTE=battle_drag_live
```

⚠️ **flutter 构建/run 禁加 `DEVELOPER_DIR=/Library/Developer/CommandLineTools`** —— 会 xcodebuild exit 72、app 进程早退、伪装成路由 flake(上轮误判即此)。进入后画面已起手暂停,顶栏可见 单步 按钮;首帧打印 `VISUAL_ROUTE_READY: battle_drag_live` 即就绪。

## 复验项(逐条 CGEvent 操作 + 截图,各给 通过/不通过/无法确认 + 现象 + 截图名)

1. **C-aoe 拖招打全体(本次重点)**:长按「万钧裂空」(aoe 大招)拖动松手 → 应见 **3 个敌人同时扣血**(对比上轮只单个扣血),配合点「单步」推进逐帧观察 3 条血条同步下降。截全体扣血图。
2. **F debuff hover**:点「单步」推进让敌方 yinRou 攻击我方灵巧弟子甲 → 弟子甲头像下应贴「内伤」标签 → 暂停态 hover 标签 → 显释义浮层。截标签 + 浮层。
3. **复确认上轮已过**:C-single 拖招(裂石指拖敌头像指定单体)/ D aoe+single 单击弹简介 / E「内力不足」文案 / 单步按钮 / G 内力标签 / H 布局不溢出 仍正常(顺手即可)。

## 硬规矩(不可破)

1. 纯复验不改代码、不 commit、不 push、不合 main;发现问题写进报告交 Claude 修。
2. 截图归 `docs/handoff/<报告同名目录>/`(.gitignore 已挡 png 不入库);判定逐项给 通过/不通过/无法确认 + 现象 + 截图名。
3. 完成后确认无 Flutter/wuxia_idle 进程残留。

## 产物

- **验收报告**:`docs/handoff/codex_phase5_aoe_reverify_2026-06-17.md`(逐项判定表 + 总结 + 给 Claude 的待修项,若有)
- **截图目录**:`docs/handoff/codex_phase5_aoe_reverify_2026-06-17/`

## 基建速查

- aoe 结算:`default_ground_strategy.dart` → `_resolveAction` 对 targetIds loop(各目标 `_resolveOneTarget` 完整伤害独立结算)
- 场景:`battle_test_menu.dart` → `scenarioDragLive`(弟子甲 lingQiao;敌 3×40000 血 yinRou,攻击触发内伤)
- 单步:顶栏「单步」按钮(仅 startPaused 渲染)→ `BattleNotifier.step()`
