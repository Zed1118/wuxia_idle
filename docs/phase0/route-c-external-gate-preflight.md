# Route C 外部 Gate 预检

> 状态：`WINDOWS_PENDING`。2026-08-23 用户取消六人真人 Gate；Route C 外部硬锁只剩
> Windows 物理机矩阵。预检防串包、缺样本、虚假主机声明和旧 probe 冒签。

## 对象纠偏

历史 `phase0a-playtest-protocol.md` 的 AB 对照、六人问卷工具以及
`tools/phase0minus_probe` 的旧性能矩阵只保留作历史资料，均不参与当前 Route C 裁决。

Windows 证据必须同时绑定：

- 待删候选 commit；
- 根应用 `wuxia_idle` 的 Profile AOT 载荷 `data/app.so` SHA-256；
- 生产循环负载路由 `phase0a_battle_profile`；
- 1280×720 与 1440×900 各三次，六次使用同一 AOT、fixture 与主机 manifest。

## Windows 物理机资格

最低档签字设备必须满足 `phase0a-windows-physical-gate.md`：Windows 10 22H2 或
Windows 11 64-bit、CPU 不高于 i5-8250U 目标档、UHD 620 级核显、8 GB RAM、SSD、
插电最佳性能、60 Hz、100% 缩放、本地 Console，且可完整容纳两个目标逻辑视口。

RDP、虚拟机、云机、独显、明显更强 CPU、非 60 Hz 或不实 attestation 只能用于构建和
兼容性 smoke，不能签最低档性能 Gate。不得通过限核、降频或伪填 manifest 冒充目标硬件。

## Windows 执行

在候选 commit 的干净 Windows 工作树上：

```powershell
git fetch origin codex/deepseek-route-c-delete-rehearsal
git switch --detach origin/codex/deepseek-route-c-delete-rehearsal
$Commit = git rev-parse HEAD
if (git status --porcelain) { throw "worktree must be clean" }

Copy-Item .\tools\route_c_gate\windows_minimum_spec_manifest.template.json `
  .\windows_minimum_spec_manifest.captured.json
```

据实填写捕获文件，不能原样使用模板：

- `status: RECORDED`；
- 清除全部 `FILL_*` / `UNKNOWN`；
- 填入实际 OS、CPU、GPU、driver、RAM、存储、电源、renderer、刷新率和缩放；
- 本地 Console、非 RDP、非 VM、核显、插电和最佳性能均须有真实依据；
- 只有机器确实不高于目标档时，才可将 attestation 项设为 `true`。

关闭浏览器、IDE、录屏、更新和其他高负载程序，保持窗口可见且不要操作采样窗口：

```powershell
$Fixture = (Get-FileHash -Algorithm SHA256 .\data\phase0a_debug_battle.yaml).Hash.ToLowerInvariant()
.\tools\route_c_gate\run_route_c_windows_matrix.ps1 `
  -HostManifest .\windows_minimum_spec_manifest.captured.json `
  -ExpectedCommit $Commit `
  -ExpectedFixtureChecksum $Fixture
```

根应用只构建一次。每轮执行 12 秒预热、60 秒采样、30 秒冷却；任一轮失败即中止并保留
原始目录。输出目录必须包含六个 run 的 `frames.jsonl`、`memory_gc.jsonl`、
`summary.json`、`manifest.json`、`run.log`，以及冻结的 `host_manifest.json`、`app.so`、
fixture、preflight、`SHA256SUMS.txt` 和 zip。

## 主端独立裁决

回传完整 `build\route_c_windows_matrix\<timestamp>.zip`，不能只发截图或抄指标。主端执行：

```bash
dart run tool/route_c_gate_preflight.dart \
  --candidate <candidate-ref> \
  --windows-dir <解压后的矩阵目录> \
  --output <preflight-report.json>
```

preflight 会重新读取原始帧和内存/GC 数据，独立计算样本数、p99、连续慢帧、GC 与 RSS，
重新散列主机 manifest、`app.so` 和 fixture，并拒绝旧 probe、串 commit、混二进制、独显、
RDP、VM、非 60 Hz/100% 或不合格主机。

退出码：`0=PASS`、`2=PENDING`、`1=INVALID`。候选树、生产消费者、Mac Gate 与最低档
Windows 物理 Gate 均通过后，才允许原子整合到主线并重跑全量验证。
