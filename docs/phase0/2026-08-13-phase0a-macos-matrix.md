# Phase 0A macOS 正式性能矩阵

> 日期：2026-08-13  
> 运行时代码 commit：`d4d2f20a1034c5380f5b571c4a588f3112cf04a2`  
> 场景：`20+1` resident + 160 feedback residents + 22 CircleHitbox  
> 裁决：`MAC_PERFORMANCE_AND_COLLISION_PASS / HUMAN_AND_WINDOWS_PENDING`

## 环境与协议

- MacBook Air `Mac17,3`，Apple M5，32GB RAM；
- Flutter 3.41.5 / Dart 3.11.3 / Flame 1.38.0；
- macOS Profile，60Hz，DPR 2；
- 每次 `12s` 预热 + `60s` 样本 + `30s` 冷却；
- 两视口各 3 个有效 run；所有 manifest 均 `git_dirty=false`；
- 12 秒循环覆盖 10 → 20 → 20+1，60 秒样本至少观察 7 次 20+1 峰值和 7 次清场；
- 回放窗口置于左侧内建屏并在 START 后执行一次系统 `Raise`。不 Raise 时 macOS 会暂停被遮挡的 Flame 窗口；所有 0 帧结果均标 INVALID 并排除。

## 六个有效样本

| 视口 | run 时间戳 | 有效帧 | p99 | 最坏帧 | >33.3ms 连帧 | GC | RSS 冷却增量 | 反馈峰值/溢出 | 20+1 / 清场 | 接触起始 |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1280×720 | `040414Z` | 3,600 | 3.911ms | 7.762ms | 0 | 573 | +19.22MiB | 136 / 0 | 8 / 8 | 3,644 |
| 1280×720 | `040610Z` | 3,600 | 3.980ms | 8.034ms | 0 | 592 | +18.80MiB | 136 / 0 | 8 / 8 | 3,826 |
| 1280×720 | `040800Z` | 3,602 | 3.996ms | 7.555ms | 0 | 576 | +18.83MiB | 136 / 0 | 8 / 7 | 3,380 |
| 1440×900 | `040954Z` | 3,603 | 3.983ms | 8.491ms | 0 | 571 | +5.27MiB | 136 / 0 | 7 / 7 | 3,350 |
| 1440×900 | `041143Z` | 3,604 | 4.051ms | 8.091ms | 0 | 590 | +4.77MiB | 128 / 0 | 8 / 7 | 3,780 |
| 1440×900 | `041330Z` | 3,600 | 3.921ms | 9.023ms | 0 | 579 | +6.28MiB | 128 / 0 | 7 / 7 | 3,676 |

每个样本同时满足：

- `timing_gc_gate=PASS`；
- `resident_pool_gate=PASS`；
- `workload_coverage_gate=PASS`；
- `rss_gate=PASS`；
- `collision_workload_gate=PASS`；
- 22 个常驻 Hitbox、至少 3,350 次接触起始、16 次技能范围查询；
- 160 个 feedback resident，预热后居民分配 0，overflow 0。

## 结论边界

本矩阵签署 Mac 上的确定性性能 fixture、反馈池和碰撞工作负载。另行执行的 10-seed 策略 Gate 为 PASS（弱策略严格失败 9/10、基准策略胜利 10/10）。

仍未签署：

- 6 人爽感、可读性与操作意愿；
- 与生产版“点招立即出手”对照；
- 最低档 Windows 实机矩阵。

因此不得把本报告单独解释为 Phase 0A 总体 PASS，也不得据此接入根应用。

