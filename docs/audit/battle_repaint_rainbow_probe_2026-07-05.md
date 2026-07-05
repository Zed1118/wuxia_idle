# battle 重绘局部化实测(repaint rainbow · 2026-07-05 夜间批 E)

> P2 零散挂账「battle 144Hz repaint rainbow 实测一次」落地。
> 方法:临时 `debugRepaintRainbowEnabled = true`(main.dart 探针,测完已还原不提交),
> `VISUAL_ROUTE=battle_scene`(ScenarioLauncher 默认 autoStart,真战斗自动播,1280×720),
> CGWindowID 截图连拍 10 帧(间隔 1s,不借鼠标),PIL 逐对帧差(阈值 12/通道)+ 8×6 网格热图。
> rainbow 每次重绘轮转色相 → 帧间像素变化 = 「该区域重绘过」的超集(含内容动画),静止区字节不变。

## 结论:重绘高度局部化,无全屏重绘 ✅

- **逐对帧全屏变化率:均值 9.9%,峰值 24.6%**(9 对;全屏重绘会接近 100%)。
  安静拍仅 1.2-1.8%,爆发拍(弹道/飘字/掉血)也只到 ~25%。
- 热区分布与预期一致:**左右两列战斗单位区**(头像/血内条/高亮,峰值 65-82%)、
  顶部 header/banner 行(20-47%)、底部技能栏行(25-57%);**中央背景大片 0-2% 静止**
  (6/48 格子从未变化 >1%,另有约 10 格 <3%)。
- 判定:RepaintBoundary 隔离面(cacheWidth 批 + C 批次 `_playback` 注入 setState 重绘粒度)
  在真机自动战斗下真实生效,基本盘无「一格动全屏画」问题。**无需进一步优化动作,挂账可销。**

## 网格热图(max changed % per cell · 8 列 × 6 行)

```
 41.1 28.1 28.2 21.0 18.8 20.2 21.3 47.3   ← header/敌我名牌
 65.9  9.8 29.6  0.7  0.6  0.1 21.8 81.8   ← 上排单位
 77.4  8.5  0.8 37.7 36.5  0.0 30.2 80.9   ← 中排单位(中央两格=飘字/弹道走廊)
 68.2 12.5  2.2  0.7  1.5  2.9 26.4 69.3   ← 下排单位
 47.8 11.2  3.3  6.3  8.1 15.3 13.0 32.9   ← 战报区边缘
 39.4 57.3 26.7 26.7 26.7 26.7 26.7 24.8   ← 底部技能栏(读秒环/CD 常态低频重绘)
```

## 方法局限(如实标注)

- 1s 采样测的是「区域是否重绘过」,**不是 144Hz 帧率成本**:同一区域 1Hz 或 144Hz 重绘
  在此读数下相同。144Hz 光栅耗时若要量化需 DevTools timeline/profile 真机(交互式,归用户
  或后续专项);本读数已回答挂账的核心问题(重绘是否被 RepaintBoundary 局部化)。
- 帧差是重绘的超集(含精灵位移等真实内容变化),不会漏报、可能高估——高估下仍只有 9.9% 均值,
  结论更稳。
- battle_scene 是 demo 队伍非满编终局特效密度;爆发密度更高的场景峰值会更高,但热区结构
  (单位区+底栏局部)不变。

## 探针复现

`lib/main.dart` ensureInitialized 后加 `debugRepaintRainbowEnabled = true;`(import
`package:flutter/rendering.dart`)→ `VISUAL_WINDOW_W=1280 VISUAL_WINDOW_H=720 flutter run
-d macos --dart-define=VISUAL_ROUTE=battle_scene` → `window_id.swift` 取 CGWindowID →
`screencapture -x -o -l<id>` 连拍 → PIL ImageChops 帧差(脚本一次性,未入库)。
