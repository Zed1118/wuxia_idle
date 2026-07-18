# battle 批视觉 smoke（Kimi K3 · 2026-07-18）

- 环境：be432668 · analyze 0（No issues found, 17.5s）· build_runner 已重生（124 outputs）· 屏幕录制权限 OK（window_id 截屏成功，画面非黑）
- 说明：因终端无「辅助功能」权限（-25211），脚本 osascript 窗口 resize 失败，全部走 window_id 兜底截整窗；实测产物尺寸与目标分辨率一致（720p=2560×1440@2x、1440x900=2880×1800@2x），判定有效。

| 路由 | 720p | 1440x900 | 现象记录（WARN/FAIL 必填，写具体位置） |
|---|---|---|---|
| battle_scene | PASS | PASS | 全要素齐：双方立绘、血/气条、底部招式轮转谱、战报行。720p 抓到「暴击 3900」飘字+朱砂「斩」题字，排版清晰不糊；水墨基调正常，无 Material 饱和色 |
| battle_tap_live | PASS | PASS | 3v3 点选案台：7 张技能签状态标签（回气中）清晰可辨；武学案台角色列表/气值正常。截帧在节拍 0（点选态待输入，符合路由语义），未抓到推进中飘字 |
| battle_tap_preview | PASS | PASS | 预览态：敌方 3 个「可选」目标标记（右上/右侧）、技能签「待发」朱红角标、主控下方头像焦点环均清晰可辨 |
| battle_charge_break | PASS | PASS | 顶部「蓄势」横幅（青衫剑客 正在蓄力：青锋绝·还有 2 拍发动）；3 个单位头顶读秒环（3/2/2）可见；底部中央「⚡破绽·该爆发了」提示明显；技能签气耗/息数标注完整 |
| battle_interrupt_caption | PASS | PASS | 干预题字「破！」黄（上）/绛红（下）双款：字号大、米白描边、墨溅底，独立预览路由无遮挡问题 |
| battle_ultimate_caption | PASS | PASS | 大招题字「天问归一」（黄）/「血煞噬魂」（绛红）：字体描边清晰，位置上下分区不叠 |
| battle_mass_battle_stage | WARN | WARN | 标题「战斗 3 v 7」但首屏仅 3 敌可见（疑为波次设计，待 Claude 终判确认）；截帧停在节拍 0，无伤害飘字，**本批改动点「同槽飘字散开」未能目检**，建议补一条带 --wait 更久或推进中的截帧复核 |
| battle_defeat | PASS | PASS | 败北结算完整：败字题头、短板诊断、致命一击/内力余量、总伤害/暴击/用时、查看技能装配+继续按钮；背景压暗，无残留危险提示/特效叠在结算层上 |

共同必查：16/16 无 RenderFlex overflow 黄黑条纹、无红色 error widget、无空白/黑屏；文字无叠字、无不可读截断；720p 底部操作区完整。

## 踩坑 / 异常日志

1. **首次 battle_scene 720p 截图失败一次**：终端报 `could not create image from rect`（resize 失败后走 region 兜底失败）。未改任何东西直接重试同命令即成功（window_id 兜底），判定为一次性抖动，记录在案。
2. **osascript 辅助功能权限缺失（全 16 条均有，非阻塞）**：
   `287:314: execution error: “System Events”遇到一个错误：“osascript”不允许辅助访问。 (-25211)` → `VISUAL_CAPTURE_WARN: resize_failed` → 自动降级 window_id 截整窗成功。建议在系统设置→隐私与安全性→辅助功能中给终端授权，可消除该 WARN。
3. 构建有 2 条 audioplayers_darwin Swift main-actor warning（上游包 6.4.0 既有问题，与本次 battle 批无关）。

## 截图清单

```
build/visual_acceptance/kimi_battle_smoke_20260718/battle_charge_break/1280x720/battle_charge_break.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_charge_break/1280x720/battle_charge_break.png
build/visual_acceptance/kimi_battle_smoke_20260718/battle_charge_break/1440x900/battle_charge_break.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_charge_break/1440x900/battle_charge_break.png
build/visual_acceptance/kimi_battle_smoke_20260718/battle_defeat/1280x720/battle_defeat.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_defeat/1280x720/battle_defeat.png
build/visual_acceptance/kimi_battle_smoke_20260718/battle_defeat/1440x900/battle_defeat.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_defeat/1440x900/battle_defeat.png
build/visual_acceptance/kimi_battle_smoke_20260718/battle_interrupt_caption/1280x720/battle_interrupt_caption.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_interrupt_caption/1280x720/battle_interrupt_caption.png
build/visual_acceptance/kimi_battle_smoke_20260718/battle_interrupt_caption/1440x900/battle_interrupt_caption.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_interrupt_caption/1440x900/battle_interrupt_caption.png
build/visual_acceptance/kimi_battle_smoke_20260718/battle_mass_battle_stage/1280x720/battle_mass_battle_stage.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_mass_battle_stage/1280x720/battle_mass_battle_stage.png
build/visual_acceptance/kimi_battle_smoke_20260718/battle_mass_battle_stage/1440x900/battle_mass_battle_stage.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_mass_battle_stage/1440x900/battle_mass_battle_stage.png
build/visual_acceptance/kimi_battle_smoke_20260718/battle_scene/1280x720/battle_scene.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_scene/1280x720/battle_scene.png
build/visual_acceptance/kimi_battle_smoke_20260718/battle_scene/1440x900/battle_scene.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_scene/1440x900/battle_scene.png
build/visual_acceptance/kimi_battle_smoke_20260718/battle_tap_live/1280x720/battle_tap_live.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_tap_live/1280x720/battle_tap_live.png
build/visual_acceptance/kimi_battle_smoke_20260718/battle_tap_live/1440x900/battle_tap_live.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_tap_live/1440x900/battle_tap_live.png
build/visual_acceptance/kimi_battle_smoke_20260718/battle_tap_preview/1280x720/battle_tap_preview.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_tap_preview/1280x720/battle_tap_preview.png
build/visual_acceptance/kimi_battle_smoke_20260718/battle_tap_preview/1440x900/battle_tap_preview.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_tap_preview/1440x900/battle_tap_preview.png
build/visual_acceptance/kimi_battle_smoke_20260718/battle_ultimate_caption/1280x720/battle_ultimate_caption.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_ultimate_caption/1280x720/battle_ultimate_caption.png
build/visual_acceptance/kimi_battle_smoke_20260718/battle_ultimate_caption/1440x900/battle_ultimate_caption.log
build/visual_acceptance/kimi_battle_smoke_20260718/battle_ultimate_caption/1440x900/battle_ultimate_caption.png
```
