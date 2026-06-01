# Codex 视觉验收派单 · 战斗屏出版美术 B1(scrim + 背景 + 胜负仪式)

**项目**：挂机武侠 · Mac 本地 · 非 Pen
**验收对象**：战斗屏背景层(BattleSceneBackground:背景图+scrim 0.4)+ 胜负仪式 overlay(金「胜」)
**分支**：worktree-battle-screen-b1(7 commit,base 0f7e5d2)· 全量 1642 测绿 + 0 analyze

## 已编译 app(直接跑,勿 checkout/build)

```
/Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/battle-screen-b1/build/macos/Build/Products/Debug/wuxia_idle.app
```

`VISUAL_ROUTE=battle_scene` 已编入。启动即落战斗屏(scenarioB:左队克制右队稳胜),
**战斗自动播放**到 leftWin → 弹金「胜」仪式 overlay。
就绪信号:`flutter: VISUAL_ROUTE_READY: battle_scene`(首启 seed ~10-20s)。
本地已自验:READY 正常 + 自动播放 45s 零 Unhandled Exception。

## 截图清单(2 张)

存 `docs/handoff/codex_visual_battle_b1_2026-06-01/`(PNG 不入库):
1. `01_battle_scene.png` — READY 后立即截(战斗进行中:背景+scrim+战斗 UI 同屏)
2. `02_victory_ceremony.png` — **等 ~40s 战斗自动播放结束**后截(金「胜」仪式 overlay)

## 验收门(逐条 PASS/FAIL)

1. **背景到位**:战斗屏底层有水墨城墙背景(battle_citywall:对称双城楼+石板广场),BoxFit.cover 铺满。
2. **scrim 压暗得当**:背景被压暗(scrim 40%),但**仍可辨认背景题材**;关键是**战斗 UI 清晰可读**(顶栏存活数/回合、左侧日志、角色头像+姓名+境界、血条/内力条、底栏大招按钮)不被背景抢。
3. **战斗 UI 完整**:3v3 双队角色、血条/内力条、日志滚动、大招按钮、快进按钮均正常显示在背景之上。
4. **胜负仪式 overlay(金「胜」)**:战斗结束弹全屏暗幕(70%)+ 居中:红印章符(武)+ 超大金色「胜」题字 + 「旗开得胜」副标题 + 统计行(总伤/暴击/回合)+ 金框「继续」按钮。
5. **水墨克制一致**:背景 + 仪式整体低饱和墨调,金「胜」醒目但不刺眼;无高饱和/油画/卡通。
6. **布局不破**:1280×720 无 overflow/RenderFlex;日志 0 exception(尤其无 `_pickSkill`/`Bad state`)。

任一 FAIL 记现象 + 截图。**重点主观判断**:scrim 0.4 深浅是否合适(太暗=背景没意义/太亮=抢 UI),需要调可建议 0.35 或 0.45。

## closeout

写 `docs/handoff/codex_visual_battle_b1_2026-06-01.md`(≤30 行):
2 截图 PASS/FAIL + 6 验收门逐条 + scrim 深浅主观建议 + 日志异常 + 总判。
