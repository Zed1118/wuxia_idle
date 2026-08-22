# Route C 外部 Gate 预检

> 状态：`PASS @ 597a243b2506610b5cbb74e2919be79bbf99e283`。2026-08-23 用户取消六人真人 Gate；同 commit 的 Mac 与 Windows 本地物理机生产兼容性矩阵均 6/6 PASS，独立预检 PASS，Route C 已快进合入 `main`。证据索引见 `docs/audit/route_c_gate_closeout_2026-08-23.md`。

## 对象纠偏

历史 `phase0a-playtest-protocol.md` 的 AB 对照、六人问卷工具以及
`tools/phase0minus_probe` 的旧性能矩阵只保留作历史资料，均不参与当前 Route C 裁决。

Windows 证据必须同时绑定：

- 待删候选 commit；
- 根应用 `wuxia_idle` 的 Profile AOT 载荷 `data/app.so` SHA-256；
- 生产循环负载路由 `phase0a_battle_profile`；
- 1280×720 与 1440×900 各三次，六次使用同一 AOT、fixture 与主机 manifest。

## Windows 物理机资格（2026-08-23 新标准）

用户已将 Route C 外部标准从“i5-8250U/UHD 620/8 GB 最低档性能 Gate”改为
“Windows 本地物理机生产兼容性 Gate”。当前联网主机 Ryzen 7 5800X + RTX 4070 SUPER +
16 GB + 143 Hz 可以签本 Gate；该结果只证明此物理基线兼容，不得外推或宣传为产品最低配置。

签字仍要求 Windows 10 22H2 或 Windows 11 64-bit、实体机、本地 Console、非 RDP、非 VM、
插电最佳性能、100% 缩放、实际刷新率/CPU/GPU/driver/RAM/SSD/renderer 全部据实记录，且
桌面可完整容纳 1280×720 与 1440×900。独显和高刷新率不再否决；隐藏 SSH service session、
云机、虚拟机、RDP、占位字段或不实 attestation 仍直接否决。

## Windows 执行

在候选 commit 的干净 Windows 工作树上：

```powershell
git fetch origin codex/deepseek-route-c-delete-rehearsal
git switch --detach origin/codex/deepseek-route-c-delete-rehearsal
$Commit = git rev-parse HEAD
if (git status --porcelain) { throw "worktree must be clean" }

Copy-Item .\tools\route_c_gate\windows_physical_gate_manifest.template.json `
  .\windows_physical_gate_manifest.captured.json
```

据实填写捕获文件，不能原样使用模板：

- `status: RECORDED`；
- 清除全部 `FILL_*` / `UNKNOWN`；
- 填入实际 OS、CPU、GPU、driver、RAM、存储、电源、renderer、刷新率和缩放；
- 本地 Console、非 RDP、非 VM、实体机、插电和最佳性能均须有真实依据；
- 将 `valid_for_windows_physical_gate`、`physical_machine_confirmed`、
  `local_console_confirmed` 和电源 attestation 据实设为 `true`。

关闭浏览器、IDE、录屏、更新和其他高负载程序，保持窗口可见且不要操作采样窗口：

```powershell
$Fixture = (Get-FileHash -Algorithm SHA256 .\data\phase0a_debug_battle.yaml).Hash.ToLowerInvariant()
.\tools\route_c_gate\run_route_c_windows_matrix.ps1 `
  -HostManifest .\windows_physical_gate_manifest.captured.json `
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
重新散列主机 manifest、`app.so` 和 fixture，并拒绝旧 probe、串 commit、混二进制、
RDP、VM、非 100% 缩放、隐藏服务会话或未完整记录的主机。

退出码：`0=PASS`、`2=PENDING`、`1=INVALID`。本轮候选树、生产消费者、Mac Gate 与 Windows
本地物理兼容性 Gate 已在 `597a243b2506610b5cbb74e2919be79bbf99e283` 全部通过并完成原子整合；后续改动不得借用该证据冒签新的二进制。
