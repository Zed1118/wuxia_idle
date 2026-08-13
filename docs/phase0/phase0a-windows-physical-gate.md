# Phase 0A Windows 最低档物理机 Gate 手册

> 当前状态：`WINDOWS_PENDING`。本手册和脚本只完成复跑准备，不代表 Windows 已通过。

## 1. 可签字设备

首轮目标下界为：

- Windows 10 22H2 或 Windows 11 64-bit；
- Intel Core i5-8250U 级或性能不高于该档的支持 CPU；
- Intel UHD Graphics 620 级 DirectX 11 核显；
- 8GB RAM、SSD；
- 插电并使用最佳性能电源模式；
- 60Hz、100% Windows 缩放；本地桌面能完整容纳 1280×720 与 1440×900 两个逻辑视口。

以下结果只能用于构建/脚本 smoke，不能签最低档性能 Gate：

- GitHub Actions、云主机、虚拟机或云桌面；
- Remote Desktop/RDP 会话；
- GTX/RTX 等独显或明显强于目标档的 CPU；
- 1366×768 且没有 1440×900/60Hz 外接显示器的机器；
- 窗口被最小化、完全遮挡、锁屏或进入节能状态的运行。

SSH 可以用于传包和取回结果，但采样必须由物理机本地登录用户在可见交互桌面启动。SSH service session 中启动的不可见 GUI 进程不能签字。

## 2. 冻结版本

Windows 与 Mac 正式矩阵必须使用同一 git commit 和同一 `probe_scenarios.yaml` checksum。开始前记录：

```powershell
git rev-parse HEAD
git status --porcelain
Get-FileHash -Algorithm SHA256 .\tools\phase0minus_probe\assets\probe_scenarios.yaml
```

工作树必须为空。若为补 Windows runner 产生了新 commit，则必须在这个最终 commit 上重新生成 Mac 正式矩阵，不能以“运行时代码看起来没变”替代同 commit 规则。

## 3. 采集并人工确认主机信息

在仓库根目录执行：

```powershell
cd .\tools\phase0minus_probe
.\scripts\collect_phase0a_windows_host_manifest.ps1 `
  -OutputPath .\config\windows_minimum_spec_manifest.captured.json
```

采集脚本故意输出 `CAPTURED_NOT_ATTESTED`，并把以下项目保持为失败值，防止机器仅“能运行”就被误签：

- `runtime.renderer`；
- `device.gpu_is_integrated`；
- `attestation.*`。

操作者须在本地核对任务管理器、`dxdiag`、Windows 显示设置和 Flutter GPU/DevTools 信息，再将捕获文件改为：

- `status: RECORDED`；
- 填入实际 renderer，不能保留 `FILL_*` / `UNKNOWN`；
- 确认实际使用核显后设 `gpu_is_integrated: true`；
- 确认没有 RDP/VM、为本地 Console 会话；
- 只有机器确实不强于目标下界时，才把三项性能档 attestation 与 `valid_for_minimum_spec_gate` 改为 `true`；
- 在 `validation_notes` 写明核对依据，不写空泛的“已确认”。

模板位于 `config/windows_minimum_spec_manifest.template.json`。不得把模板原样当结果。

## 4. 执行正式矩阵

关闭浏览器、IDE、录屏、系统更新和其他高负载程序；保持电源、60Hz、100% 缩放和屏幕常亮。不要操作采样窗口。

```powershell
cd .\tools\phase0minus_probe
$Commit = git -C ..\.. rev-parse HEAD
$Checksum = (Get-FileHash -Algorithm SHA256 .\assets\probe_scenarios.yaml).Hash.ToLowerInvariant()
.\scripts\run_phase0a_windows_matrix.ps1 `
  -HostManifest .\config\windows_minimum_spec_manifest.captured.json `
  -ExpectedCommit $Commit `
  -ExpectedScenarioChecksum $Checksum
```

脚本只构建一次 Profile binary，然后自动执行：

- 1280×720 × 3 次；
- 1440×900 × 3 次；
- 每次固定 `PROBE_MODE=phase0a_replay`、DPR 1、60Hz、完整 12s warmup + 60s sample + 30s cooldown；
- 每个 run 生成 `frames.jsonl`、`memory_gc.jsonl`、`summary.json`、`manifest.json`、`run.log`；
- 最后严格验证并生成 `windows_gate_validation.{json,md}`、`SHA256SUMS.txt` 和 zip。

任一 run 失败、窗口落错显示器、GC 缺失、checksum/commit 不一致、五项复合 Gate 非 PASS、结果少于 6 次，矩阵脚本必须非零退出。失败后保留原始目录供诊断，不挑最好成绩重签。

## 5. 回传与裁决

回传整个 `<timestamp>.zip`，不要只截图或只抄 p99。主窗口须复核：

- host manifest 的物理机资格与人工依据；
- 6 个唯一 run、两视口各 3 次；
- 同 commit、同 scenario checksum、同 binary checksum；
- 原始文件 SHA-256；
- `timing_gc`、`resident_pool`、`workload_coverage`、`rss`、`collision_workload` 全 PASS；
- renderer、driver、DPR、刷新率和本地会话均有证据。

脚本输出 `PHASE0A_WINDOWS_MATRIX_PASS` 只表示 Windows 性能矩阵机械 Gate 通过。它不能代签 6 人爽感/可读性 Gate，也不自动批准进入 0B；最终仍由项目主人裁决。

## 6. CI 边界

CI 可以做：Windows Profile 编译、Dart/Flutter 测试、PowerShell 语法 smoke、validator fixture、结果包结构与 checksum 校验。

CI 绝不能代签：最低档物理硬件、实际核显/driver/renderer、60Hz 本地显示、前台窗口调度、真实帧时/GC/RSS/对象池/碰撞性能以及人工画面与手感。
