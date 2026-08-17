# Phase 0A 玩法灰盒 · macOS 初步性能基线

> **日期**：2026-08-13  
> **分支**：`codex/phase0a-gameplay-greybox`  
> **回放 commit**：`8955e126`  
> **场景 SHA-256**：`4e5fe7e906d05eb5b56525f4232e30ddab0d52fc8a6d1c598a65068f09b47ad9`  
> **裁决**：`PRELIMINARY_PASS / POOL_AND_FEEDBACK_PENDING`；不是 Phase 0A 正式性能 Gate，不解除 Windows 硬阻塞。

## 1. 本轮回答的问题

本轮只验证确定性玩法逻辑、21 个常驻敌人、Flutter HUD 与首轮白盒反馈在当前 Mac 上是否存在明显帧时风险，并验证 Phase 0A 能复用 Phase 0− 的 FrameTiming、RSS、GC、结果 checksum 和显示环境采集链。

它不签完整清场粒子/残影/伤害标签/hit-stop/镜震负载、正式对象池与碰撞 Gate、6 人玩法 Gate、最低档 Windows 性能。因此每个结果都显式写入 `preliminary_gate = POOL_AND_FEEDBACK_PENDING`，即使底层帧时 Gate 为 `PASS`，也不得改称 Phase 0A 正式通过。

## 2. 环境与负载

- MacBook Air `Mac17,3`，Apple M5，32GB RAM；
- Flutter 3.41.5 / Dart 3.11.3 / Flame 1.38.0；
- macOS Profile，60Hz、DPR 2.0；
- `12s` 预热 + `60s` 采样 + `30s` 冷却；
- 12 秒压缩循环：10 怪 → 20 怪 → 20+1，每个 20+1 峰值执行 Q→R；
- 21 个敌人组件在加载期一次创建，循环只激活/复位，不在预热后新增居民；
- raw 结果位于 `tools/phase0minus_probe/build/results/phase0a-replays/`，按仓库规则忽略。

## 3. 有效结果

| 视口 | 有效帧 | p99 | 最坏帧 | 连续 >33.3ms | 20+1 峰值 | 清场 | GC 事件 | 预热后居民分配 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1280×720 | 3,595 | 3.183ms | 6.881ms | 0 | 8 | 8 | 174 | 0 |
| 1440×900 | 3,597 | 2.794ms | 15.746ms | 0 | 8 | 8 | 174 | 0 |

两次 run 同时满足：

- `p99(totalSpan) < 16.6ms`，无单帧超过 16.6ms；
- 无连续两帧 `totalSpan > 33.3ms`；
- GC telemetry、内容视口、60Hz 与 DPR2 均有效；
- manifest 为已提交的 `8955e126` 且 `git_dirty=false`；
- 居民敌人数恒为 21，`invariant_holds=true`、`allocation_after_warmup=0`；
- 60 秒样本覆盖的 20+1 峰值次数高于最低 5 次要求。

| 视口 | 预热末 RSS | 峰值 | 冷却末 | 冷却末相对预热末 |
|---|---:|---:|---:|---:|
| 1280×720 | 133.06MiB | 136.34MiB | 136.00MiB | +2.94MiB |
| 1440×900 | 133.62MiB | 137.28MiB | 137.02MiB | +3.40MiB |

均低于 Phase 0− 的 `预热末 + max(10%, 64MiB)` 人工审计线。

## 4. 无效运行与环境事故

两次 1.0 正式时长运行因窗口完全被 Codex 主窗口遮挡，macOS 停止为 Flame 窗口持续产帧，最终只有约 2 秒游戏时钟、正式样本 0 帧。它们标记为 `INVALID_INSUFFICIENT_FRAMES`，不进入上表，也不删除原始证据。

随后用 0.2× smoke 对比确认：将窗口显式放到 `(2800, 200)` 后，20 秒墙钟完整推进 `20.42s` 游戏时钟、采到 719 帧并覆盖 2 次 20+1。正式运行因此固定使用该离屏坐标，并仍由 manifest 复核真实显示环境为 60Hz / DPR2。坐标只是防遮挡条件，不是显示环境证据。

## 5. 下一步 Gate

1. 补完整反馈实体和安全对象池，重新执行两视口各 3 个有效 run；
2. 增加碰撞广相/窄相、反馈实体峰值、池 invariant、RSS 自动 Gate；
3. 单独运行 10 seeds 的弱策略/基准策略，不用性能 fixture 代签玩法难度；
4. 完成 6 人测试与当前生产战斗对照；
5. 在 i5-8250U / UHD 620 / 8GB 级 Windows 实机以同 commit/checksum 复跑。

