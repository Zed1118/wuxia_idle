# Phase 0A macOS 正式性能矩阵

> 日期：2026-08-13  
> 最终运行时代码 commit：`37f81c4242b3e81792337ef18fca57a1ab21331e`
> 场景：`20+1` resident + 160 feedback residents + 22 CircleHitbox  
> 裁决：`MAC_PERFORMANCE_AND_COLLISION_PASS / HUMAN_AND_WINDOWS_PENDING`

## 环境与协议

- MacBook Air `Mac17,3`，Apple M5，32GB RAM；
- Flutter 3.41.5 / Dart 3.11.3 / Flame 1.38.0；
- macOS Profile，60Hz，DPR 2；
- 每次 `12s` 预热 + `60s` 样本 + `30s` 冷却；
- 两视口各 3 个有效 run；所有 manifest 均 `git_dirty=false`；
- 12 秒循环覆盖 10 → 20 → 20+1，60 秒样本至少观察 7 次 20+1 峰值和 7 次清场；
- app 自己请求前台焦点，运行器以 `caffeinate` 防止空闲休眠，不再额外启动第二实例；
- 逻辑视口最多校准 20 次，连续 3 次精确一致才开始计时；校准失败则采样前关窗；
- 每轮结束后运行器强制校验 summary/manifest，任一 Gate、commit、dirty、DPR、60Hz 或 Profile 口径不符即非零退出。

## 六个有效样本

| 视口 | run 时间戳 | 有效帧 | p99 | 最坏帧 | >33.3ms 连帧 | GC | RSS 冷却增量 | 反馈峰值/溢出 | 20+1 / 清场 | 接触起始 |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1280×720 | `062600Z` | 3,595 | 3.878ms | 7.810ms | 0 | 570 | -26.53MiB | 136 / 0 | 8 / 8 | 3,800 |
| 1280×720 | `062744Z` | 3,599 | 3.737ms | 7.376ms | 0 | 572 | +1.72MiB | 136 / 0 | 8 / 8 | 3,770 |
| 1280×720 | `062927Z` | 3,596 | 2.319ms | 5.255ms | 0 | 572 | +3.13MiB | 136 / 0 | 8 / 8 | 3,760 |
| 1440×900 | `063110Z` | 3,597 | 2.331ms | 4.936ms | 0 | 570 | +3.20MiB | 136 / 0 | 8 / 8 | 3,760 |
| 1440×900 | `063253Z` | 3,599 | 2.039ms | 4.635ms | 0 | 571 | +3.53MiB | 136 / 0 | 8 / 8 | 3,792 |
| 1440×900 | `063436Z` | 3,596 | 2.268ms | 5.066ms | 0 | 570 | -9.50MiB | 136 / 0 | 8 / 8 | 3,740 |

每个样本同时满足：

- `timing_gc_gate=PASS`；
- `resident_pool_gate=PASS`；
- `workload_coverage_gate=PASS`；
- `rss_gate=PASS`；
- `collision_workload_gate=PASS`；
- 22 个常驻 Hitbox、至少 3,740 次接触起始、16 次技能范围查询；
- 160 个 feedback resident，预热后居民分配 0，overflow 0。

## 证据归档

- 六份最终 `manifest.json` 和 `summary.json`：`docs/phase0/evidence/phase0a-macos-37f81c42/`；
- 归档校验：在该目录执行 `shasum -a 256 -c SHA256SUMS.txt`；
- 六份 manifest 均为同一 commit、`git_dirty=false`、60Hz、DPR 2；
- 最终 Mac 正式验收包以 `37f81c42` 为唯一有效版本；旧归档只作历史追溯。

## 结论边界

本矩阵签署 Mac 上的确定性性能 fixture、反馈池和碰撞工作负载。另行执行的 10-seed 策略 Gate 为 PASS（弱策略严格失败 9/10、基准策略胜利 10/10）。

仍未签署：

- 6 人爽感、可读性与操作意愿；
- 与生产版“点招立即出手”对照；
- 最低档 Windows 实机矩阵。

因此不得把本报告单独解释为 Phase 0A 总体 PASS，也不得据此接入根应用。
