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

## 结果

FAIL。

- B3 `battle_interrupt_caption`：1280x720 与 1920x1080 均未通过。上下两态同屏、上方暖金「破！」与下方绛红「破！」存在且清晰，但衬底表现为规则圆角矩形边框容器，不是判据要求的墨团衬底；文字未见明确描边效果。
- B5 `battle_defeat`：无法完成视觉验收。仓库内未找到 `battle_defeat_1280x720.png` 与 `battle_defeat_1920x1080.png`，因此无法判断败北页题字、破招提示、战报、继续按钮及 720p/1080p 溢出情况。

已查看截图：

- `docs/handoff/visual_capture_38964c01_20260610_111903/battle_interrupt_caption_1280x720.png`
- `docs/handoff/visual_capture_38964c01_20260610_111903/battle_interrupt_caption_1920x1080.png`

缺失截图：

- `docs/handoff/visual_capture_38964c01_20260610_111903/battle_defeat_1280x720.png`
- `docs/handoff/visual_capture_38964c01_20260610_111903/battle_defeat_1920x1080.png`
