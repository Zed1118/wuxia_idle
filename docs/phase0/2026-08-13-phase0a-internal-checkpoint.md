# Phase 0A 内部检查点

> 日期：2026-08-13  
> 分支：`codex/phase0a-gameplay-greybox`  
> 玩法包：`2f1736a5`  
> 裁决：`WIP / MAC_AND_STRATEGY_PASS / HUMAN_AND_WINDOWS_PENDING`

## 已经成立

- 单主角、无 AI 队友的三波实时灰盒可在 macOS Profile 独立运行；
- WASD/鼠标、移动普攻、身法、Q 聚怪、R 清场、精英破招闭环已接通；
- 普通敌人使用 3 个攻击租约，起手至少错开 180ms；
- 160 个常驻反馈实体承载普攻/Q/R 粒子，清场峰值 136 个活跃实体，无溢出；
- 结果、键位卡、匿名记录表和 package-local JSON 已进入可分发 Mac 包；
- 根应用、Isar、正式存档、奖励和 259 招仍不可达。

## 当前 Mac 性能证据

12s 预热 + 60s 采样 + 30s 冷却；每个样本覆盖 8 次实测 20+1 峰值和 8 次清场。

| 视口 | commit | 有效样本 | 最坏 p99 | 最坏帧 | >33.3ms 连帧 | 碰撞/池/RSS |
|---|---|---:|---:|---:|---:|---|
| 1280×720 | `d4d2f20a` | 3/3 | 3.996ms | 8.034ms | 0 | PASS |
| 1440×900 | `d4d2f20a` | 3/3 | 4.051ms | 9.023ms | 0 | PASS |

六个 manifest 均 clean；FrameTiming+GC、居民池、负载覆盖、RSS 和碰撞工作负载均 PASS。详见 `docs/phase0/2026-08-13-phase0a-macos-matrix.md`。

## 当前玩法 Gate

10 个固定 seed 的真实三波验证：

- 弱策略严格失败 `9/10`：PASS；
- 基准策略首版胜利 `7/10`；只改群体威胁与侧向拉扯代理、不改战斗数值后胜利 `10/10`：PASS；
- 综合策略 Gate：`PASS`。

当前仍缺真人主观/可读性 Gate。不得进入 0B/0C，不得并入正式战斗。

## 下一步

1. 以最新 commit 重建试玩包，做 2–3 人内部 smoke；
2. 冻结生产对照片段、6+2 测试者与正式 6 人包；
3. 执行真人爽感、可读性和操作意愿 Gate；
4. Windows i5-8250U/UHD620/8GB 仍是进入正式生产前硬 Gate。
