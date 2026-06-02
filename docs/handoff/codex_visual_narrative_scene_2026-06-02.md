# narrative_scene 视觉验收 closeout（2026-06-02）

窗口/截图尺寸：01 为 3840x1948 px；02-06 为 2880x1622 px（macOS Retina 截图，窗口已尽量最大化）。

| 验收门 | 结论 | 备注 |
|---|---|---|
| 1 pngquant 无明显 banding | PASS | 6 张天空/雾/沙/水渐变未见肉眼可见色带 |
| 2 墨色层次保留 | PASS | 水墨浓淡、纸纹、雾化层次保留 |
| 3 辨识近无损 | PASS | 未见压缩导致的脏块/糊化/细节丢失 |
| 4 题材对位 | PASS | 02 为授权铸剑炉选片；其余与关卡题材吻合 |
| 5 scrim 深浅 | PASS | 50% 暗遮罩压暗适度，背景仍可辨 |
| 6 正文浮层可读 | PASS | 01 暗场与 04 浅沙场文字均清晰 |
| 7 水墨观感统一 | PASS | 低饱和克制，05 绛红未跳脱 |
| 8 布局/日志 | WARN | 无 overflow/RenderFlex/VISUAL_ROUTE_ERROR；首张 q 退出触发 Flutter HardwareKeyboard caught assertion，02 曾有“终端意外退出”系统弹窗并已重截 |

截图：docs/handoff/codex_visual_narrative_scene_2026-06-02/01_stage_01_05.png；02_stage_02_03.png；03_stage_03_01.png；04_stage_04_03.png；05_stage_04_05.png；06_stage_05_02.png。

逐张 banding：01 雨夜水雾平滑；02 暖炉暗部无脏块；03 浅天空无断层；04 沙海素天/沙面无可见色带；05 暮色红雾过渡自然；06 冷调山雾无色带。

scrim/浮层建议：当前 50% scrim 与墨底浮层组合成立，不建议为浅背景额外加深；正文长句在 04/05 仍可读。

构建/导航/存档异常：6 次均 `VISUAL_ROUTE_READY: narrative_scene`，未见 `VISUAL_ROUTE_ERROR`；退出用 `pkill -f wuxia_idle`，未触碰 git。

总判：视觉主闸门达标，可提交压缩背景；运行环境 WARN 建议另行跟踪但不阻断本轮美术验收。
