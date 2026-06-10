# B3/B5 破招题字 + 败北页视觉复验派单 · 2026-06-10

项目：挂机武侠
HEAD：`main @ 98f95ede`（开工前 `git pull --rebase --autostash`）
范围：只做视觉验收，不改代码。承 `codex_p0_break_ui_visual_2026-06-09.md` B3/B5 缺口返修。

## 背景

上轮 B3/B5 FAIL 是因运行态无法静态截图（破招交互/败北页需实玩触发）。本轮已补两条
**静态 seed 路由**，免实玩，直接截图验收。

## 截图命令

```
tools/visual_capture/visual_capture.sh battle_interrupt_caption battle_defeat
```

（默认出 1280x720 + 1920x1080；ALL_ROUTES 已收录，跑全量也含这两条。）

## 逐项验收

| 项 | 路由 | PASS 判据 |
|---|---|---|
| B3 破招题字 | `battle_interrupt_caption` | 上下两态同屏：上方**暖金**「破！」大字（破招方），下方**绛红**「破！」（敌方），均墨团衬底 + 描边，字清晰不糊。 |
| B5 败北页 | `battle_defeat` | 战场背景 + 径向暗角上叠：绛红巨「敗」题字 + 朱印符 + 「败北」副标 + **「蓄力大招难挡——保留内力,看准蓄力时机破招」破招提示** + 战报（伤害/暴击/回合）+ 继续按钮。720p 不溢出不挤叠。 |

## 总判 / 回填

- 两项均 PASS → B3/B5 验收环闭合，回填本文件「结果」段 + 截图路径。
- 任一 FAIL → 标具体视觉问题（题字色/字号/溢出/提示缺失），Mac 端返修。

## 备注

- 「破！」题字复用 `UltimateCaptionContent`（与大招题字同体例），故色彩/描边规格应与
  `battle_ultimate_caption` 一致，可横向对照。
- 败北页即生产战斗败北时弹的 `VictoryOverlay` 战败态，所见即所得。
