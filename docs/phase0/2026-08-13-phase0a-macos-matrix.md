# Phase 0A macOS 正式性能矩阵

> 日期：2026-08-13  
> 最终运行时代码 commit：`3340b7086c3819f578d1b747672d758645b2a585`
> 场景：`20+1` resident + 160 feedback residents + 22 CircleHitbox  
> 裁决：`MAC_PERFORMANCE_AND_COLLISION_PASS / HUMAN_AND_WINDOWS_PENDING`

## 环境与协议

- MacBook Air `Mac17,3`，Apple M5，32GB RAM；
- Flutter 3.41.5 / Dart 3.11.3 / Flame 1.38.0；
- macOS Profile，60Hz，DPR 2；
- 每次 `12s` 预热 + `60s` 样本 + `30s` 冷却；
- 两视口各 3 个有效 run；所有 manifest 均 `git_dirty=false`；
- 12 秒循环覆盖 10 → 20 → 20+1，60 秒样本至少观察 7 次 20+1 峰值和 7 次清场；
- `run_phase0a_macos_profile.sh` 每轮都以精确 `.app` 路径自动激活窗口，不再依赖人工点击；修复后连续 2 轮缩时烟测和下表 6 轮完整矩阵均自动按时结束。

## 六个有效样本

| 视口 | run 时间戳 | 有效帧 | p99 | 最坏帧 | >33.3ms 连帧 | GC | RSS 冷却增量 | 反馈峰值/溢出 | 20+1 / 清场 | 接触起始 |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1280×720 | `055206Z` | 3,600 | 3.519ms | 23.654ms | 0 | 572 | -11.50MiB | 136 / 0 | 8 / 8 | 3,814 |
| 1280×720 | `055350Z` | 3,589 | 3.641ms | 24.483ms | 0 | 571 | -27.64MiB | 136 / 0 | 8 / 8 | 3,754 |
| 1280×720 | `055532Z` | 3,597 | 3.587ms | 6.338ms | 0 | 572 | +3.09MiB | 136 / 0 | 8 / 8 | 3,754 |
| 1440×900 | `055715Z` | 3,596 | 3.336ms | 7.360ms | 0 | 573 | -32.77MiB | 136 / 0 | 8 / 8 | 3,754 |
| 1440×900 | `055858Z` | 3,597 | 3.211ms | 7.143ms | 0 | 571 | +1.83MiB | 136 / 0 | 8 / 8 | 3,754 |
| 1440×900 | `060041Z` | 3,592 | 3.435ms | 7.950ms | 0 | 572 | -14.11MiB | 136 / 0 | 8 / 8 | 3,754 |

每个样本同时满足：

- `timing_gc_gate=PASS`；
- `resident_pool_gate=PASS`；
- `workload_coverage_gate=PASS`；
- `rss_gate=PASS`；
- `collision_workload_gate=PASS`；
- 22 个常驻 Hitbox、至少 3,754 次接触起始、16 次技能范围查询；
- 160 个 feedback resident，预热后居民分配 0，overflow 0。

## 证据归档

- 六份 `manifest.json` 和 `summary.json`：`docs/phase0/evidence/phase0a-macos-3340b708/`；
- 归档校验：在该目录执行 `shasum -a 256 -c SHA256SUMS.txt`；
- 六份 manifest 均为同一 commit、`git_dirty=false`、60Hz、DPR 2；
- 最终 Mac 正式验收包：桌面 `挂机武侠_Phase0A_正式验收包_3340b708`。

## 结论边界

本矩阵签署 Mac 上的确定性性能 fixture、反馈池和碰撞工作负载。另行执行的 10-seed 策略 Gate 为 PASS（弱策略严格失败 9/10、基准策略胜利 10/10）。

仍未签署：

- 6 人爽感、可读性与操作意愿；
- 与生产版“点招立即出手”对照；
- 最低档 Windows 实机矩阵。

因此不得把本报告单独解释为 Phase 0A 总体 PASS，也不得据此接入根应用。
