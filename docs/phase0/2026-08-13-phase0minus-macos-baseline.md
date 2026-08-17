# Phase 0− 怪海性能探针 · macOS 基线报告

> **日期**：2026-08-13
> **分支**：`codex/phase0minus-performance-probe`
> **探针 commit**：`c8b759fb`
> **场景 SHA-256**：`6ec997a0cc7e2f54bc8f5f863dc6f390c93b79b2fad11545cf99ccbd72f44cdd`
> **裁决**：Mac Gate `PASS`；Phase 0− Overall `BLOCKED`（缺目标最低档 Windows 实机）

## 1. 环境

- MacBook Air `Mac17,3`，Apple M5（10 核 CPU / 10 核 GPU），32GB RAM；
- macOS 26.4；Flutter 3.41.5 stable；Dart 3.11.3；Flame 1.38.0；
- Profile 构建，Flutter VM service GC stream 自动采集；不主动触发 GC；
- 当前可用显示器：60Hz、DPR 2.0；两个内容视口均在运行前自动校准并由报告复核；
- 每个组合 3 次有效 run：12 秒预热、60 秒采样、30 秒冷却；固定 seed `20260812`；
- 碰撞后端：Flame 默认 Sweep；清场每 10 秒触发；HUD 为真实 Flutter overlay。

本机外接 60Hz/DPR1 显示器在首轮运行中离线，因此最终矩阵统一使用内屏 60Hz/DPR2。它是更高物理像素负载的 Mac 基线，但不能替代 Windows 最低档，也不能直接与未来 DPR1 报告混为同一设备口径。

## 2. 结果汇总

下表的 p99 区间、最大帧和 GC 数来自最终采集器的 18 个有效 Profile run。时间单位为微秒。

| 视口 | 档位 | 有效/通过 | p99 区间 | 三次最坏单帧 | GC 事件/次 | 连续 `>33.3ms` |
|---|---|---:|---:|---:|---:|---:|
| 1280×720 | 10 怪 | 3/3 | 482–724 | 10,244 | 283–284 | 0 |
| 1280×720 | 20 怪 + 1 精英 | 3/3 | 889–1,077 | 11,238 | 545 | 0 |
| 1280×720 | 30 怪 | 3/3 | 1,404–2,259 | 14,420 | 756–757 | 0 |
| 1440×900 | 10 怪 | 3/3 | 845–856 | 17,050 | 283 | 0 |
| 1440×900 | 20 怪 + 1 精英 | 3/3 | 939–2,229 | 17,784 | 544 | 0 |
| 1440×900 | 30 怪 | 3/3 | 1,046–2,440 | 13,018 | 756–760 | 0 |

18/18 个 run 同时满足：

- 有效采样帧数 ≥3000；
- `p99(totalSpan) < 16.6ms`；
- 不存在连续 2 帧 `totalSpan > 33.3ms`；
- GC stream 已连接并实际收到事件；
- 四类对象池在预热后新增分配均为 0；
- 实际内容视口、60Hz 和 DPR 2.0 均与本轮预期一致；
- 冷却末 RSS 未超过 `预热末 + max(10%, 64MiB)`：最坏增量 4.00MiB。

跨全部 run 的 RSS 最大值：预热末 130.53MiB、运行峰值 152.27MiB、冷却末 133.97MiB。峰值会受 VM service GC 观察器与系统状态影响，仅用于本探针版本的回归对照。

## 3. 证据位置与可复现命令

原始 `frames.jsonl`、`memory_gc.jsonl`、`summary.json`、`manifest.json` 位于本 worktree 的：

`tools/phase0minus_probe/build/results/`

这些大体积原始结果按仓库门禁被 `.gitignore` 排除；每个 manifest 记录 commit、场景 checksum、视口、显示器、GC 状态和三份产物的 SHA-256。本报告只提交聚合结论。

Mac 复跑：

```bash
cd tools/phase0minus_probe
PROBE_GATE_DPR=2 scripts/run_macos_matrix.sh 3 1.0
```

如果 60Hz/DPR1 外接屏可用，应传入其窗口坐标并移除 `PROBE_GATE_DPR=2`；脚本发现窗口落到错误显示器会立即停止。

Windows 复跑：

```powershell
cd tools/phase0minus_probe
.\scripts\run_windows_profile.ps1 -Viewport desktop_1280x720 `
  -Tier target_20_plus_1 -Repeat 3 -DurationScale 1.0
```

随后对两个视口和三个档位完整执行，并填写 `config/windows_minimum_spec_manifest.template.json`。只有 i5-8250U / UHD 620 / 8GB 级目标实机（或更弱但仍属支持范围的设备）可以签最低档 Gate；CI、远程桌面或独显机器不能代签。

## 4. 裁决与下一步

- **Mac Gate：PASS。** 当前代理负载在 M5 Mac 上有充足帧时间余量，30 怪压力档也未接近临时红线。
- **Phase 0− Overall：BLOCKED。** 当前没有目标最低档 Windows 实机报告，不能批准进入 Phase 0A。
- **不得外推**：本结果不证明正式骨骼动画、正式纹理、音频、完整场景或正式技能在最低档 Windows 上也能通过；也不证明玩法已经达到暗黑或鬼谷手感。
- **恢复动作**：准备并人工分发同 commit Windows Profile 包；目标机回传完整 raw results 与硬件/驱动 manifest 后，再作 PASS / LOWER DENSITY / FAIL 裁决。
