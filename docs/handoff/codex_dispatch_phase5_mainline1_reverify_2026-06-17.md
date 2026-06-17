# Codex 派单：主线一战斗 UI 交互复验(单步路由)· 2026-06-17

**项目：** 挂机武侠 · `/Users/a10506/Desktop/Projects/挂机武侠`
**分支：** `feat/phase5-battle-experience` · HEAD `01de03b9`(已与 origin 同步,含本次单步验收路由)
**角色：** Codex = Mac 本地真机交互视觉验收。本轮复验上轮没验上的 C/D/E/F。

---

## 背景

上轮验收(报告 `codex_phase5_mainline1_visual_2026-06-17.md`):A 单击弹简介 / B 不裸下发 / G 内力条标签 / H 布局 已 PASS;但 **C 长按拖招、D aoe 单击弹简介、E「内力不足」文案、F debuff hover 释义** 因验收路由自动战斗数秒就结算、没有操作窗口,未能验收。

本次已补:`battle_drag_live` 路由**起手暂停**(冻结 seed 初态),顶栏新增「单步」按钮——可逐步推进、从容操作。上轮 stale 提示「点大招群体直发」已改:**实装语义 = aoe 群体技单击弹简介、长按拖下发、松手即对全体触发**(无需指定落点),与单体技唯一差异在拖招松手目标解析。

## 启动(关键:禁加 DEVELOPER_DIR)

```
flutter run -d macos --dart-define=VISUAL_ROUTE=battle_drag_live
```

⚠️ **flutter 构建/run 禁加 `DEVELOPER_DIR=/Library/Developer/CommandLineTools`** —— 会 xcodebuild exit 72、app 进程早退、伪装成路由 flake(上轮误判即此)。首帧打印 `VISUAL_ROUTE_READY: battle_drag_live` 即就绪。进入后画面已暂停,顶栏可见 暂停/继续 + 「单步」按钮。

## 复验项(逐条 CGEvent 操作 + 截图判定)

1. **D — aoe 单击弹简介(上轮没截到)**:单击技能「万钧裂空」(aoe 大招)→ 应弹宣纸水墨简介浮层(可见 类型=群体 / 倍率 / 耗内 / 冷却),**不直接出手**。单击「裂石指」(single 大招)同样弹简介。各截一图。
2. **C — 长按拖招下发**:长按「裂石指」拖到敌头像 → 应见引导线 + 敌头像高亮,松手=单体指定目标命中。长按「万钧裂空」拖动松手 → 应对全体触发(不需落特定头像)。截引导线/高亮/命中。
3. **E —「内力不足」文案**:主控内力 1500、大招耗内 250。反复拖放大招(配合点「单步」推进让 AP/CD 转)耗内力,降到 <250 后,技能按钮状态行应显「内力不足」。截图。
4. **F — debuff + hover 释义**:点「单步」推进若干步,让阴柔敌人攻击我方触发「内伤」debuff 贴头像 → 暂停态 hover debuff 标签 → 应显薄释义浮层。截图。踉跄/剑鸣若本场景不触发请注明(非缺陷)。
5. **单步按钮自身**:确认「单步」按钮存在、点一下推进一个 actor/tick(画面/日志增一步)。

复确认上轮已 PASS 的 G 内力条「内 X/Y」标签 / H 布局不溢出 仍正常(顺手即可)。

## 硬规矩(不可破)

1. **本轮纯复验,不改代码**:发现问题写进报告交 Claude 修,你不动 lib/、不 commit、不 push、不合 main。
2. 截图按政策归 `docs/handoff/<报告同名目录>/`(.gitignore 已挡 png 不入库),结论写进报告。
3. 判定逐项给 通过 / 不通过 / 无法确认 + 现象 + 截图名。

## 产物

- **验收报告**:`docs/handoff/codex_phase5_mainline1_reverify_2026-06-17.md`(逐项判定表 + 总结 + 给 Claude 的待修项,若有)
- **截图目录**:`docs/handoff/codex_phase5_mainline1_reverify_2026-06-17/`
- 完成后确认无 Flutter/wuxia_idle 进程残留。

## 基建速查

- 路由 host:`lib/features/debug/presentation/visual_route_host.dart` → `case VisualRoute.battleDragLive`(startPaused:true)
- 场景:`battle_test_menu.dart` → `scenarioDragLive`(主控带 普攻+裂石指 single+万钧裂空 aoe;敌 3×40000 血阴柔)
- 单步:顶栏「单步」按钮(仅 startPaused 渲染)→ `BattleNotifier.step()`
- 简介浮层:单击技能方块 → `_showSkillInfo`(读 SkillDef 活数据)
