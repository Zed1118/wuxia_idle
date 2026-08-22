# Phase 0A Windows 本地物理机生产兼容性 Gate 手册

> 当前状态：`PASS @ 597a243b2506610b5cbb74e2919be79bbf99e283`。2026-08-23 起，本 Gate 不再用于证明
> i5-8250U/UHD 620/8GB 等产品最低配置，只验证被记录的 Windows 实体机生产兼容性；后续 commit 或新 AOT 必须重新取证。
> 当前 Route C 生产证据结构与独立裁决见
> [`route-c-external-gate-preflight.md`](./route-c-external-gate-preflight.md)，本轮结果见
> [`route_c_gate_closeout_2026-08-23.md`](../audit/route_c_gate_closeout_2026-08-23.md)。

## 1. 可签字设备

签字主机必须满足：

- Windows 10 22H2 或 Windows 11 64-bit 实体机；
- 本地已登录 Console，可见交互桌面，非 RDP、非 VM、非云机；
- 插电并使用最佳性能电源模式；
- 100% Windows 缩放，桌面可完整容纳 1280×720 与 1440×900 两个逻辑视口；
- OS、CPU、GPU、driver、RAM、SSD、电源、renderer、刷新率和会话事实全部据实记录。

独显、更强 CPU、16GB+ RAM 和高刷新率不再否决。当前 Ryzen 7 5800X、RTX 4070 SUPER、
16GB、143Hz 主机可以签本 Gate，但所得结果只能证明这台物理基线兼容，不能据此定义或
宣传产品最低配置。

以下情况不能签字：GitHub Actions、虚拟机、云桌面、RDP、锁屏、最小化或完全遮挡的窗口、
SSH service session 中不可见的 GUI，以及任何占位或不实 attestation。SSH 只用于传包、
启动本地交互计划任务和取回结果；采样应用必须运行在物理机本地用户的可见 Console。

## 2. 冻结版本

Windows 与 Mac 正式矩阵必须绑定同一干净 git commit。Windows 六轮还必须使用同一个
Profile `app.so`、同一份 `data/phase0a_debug_battle.yaml` 和同一份冻结主机 manifest。
任何 runner、文档合同或验收标准改动产生新 commit 后，旧 commit 的 Mac/Windows 成绩
都不能代签。

## 3. 主机信息

在候选仓库根目录复制模板：

```powershell
Copy-Item .\tools\route_c_gate\windows_physical_gate_manifest.template.json `
  .\windows_physical_gate_manifest.captured.json
```

本地核对 Windows 设置、任务管理器、`dxdiag` 和 Flutter 运行日志后填写：

- `status: RECORDED`，清除所有 `FILL_*` / `UNKNOWN`；
- 记录实际 renderer、driver、显示刷新率、缩放、电源和硬件事实；
- 仅在实体机、本地 Console、非 RDP、非 VM、插电最佳性能均真实成立时，将对应
  `attestation` 项设为 `true`；
- `validation_notes` 写清核对依据，不得只写空泛的“已确认”。

捕获文件位于仓库根并被 gitignore，不能把模板原样当结果，也不能提交个人主机证据。

## 4. 执行正式矩阵

关闭浏览器视频、录屏、系统更新和其他高负载程序；保持屏幕常亮、窗口可见，不操作采样窗口：

```powershell
$Commit = git rev-parse HEAD
if (git status --porcelain) { throw "worktree must be clean" }
$Fixture = (Get-FileHash -Algorithm SHA256 .\data\phase0a_debug_battle.yaml).Hash.ToLowerInvariant()
.\tools\route_c_gate\run_route_c_windows_matrix.ps1 `
  -HostManifest .\windows_physical_gate_manifest.captured.json `
  -ExpectedCommit $Commit `
  -ExpectedFixtureChecksum $Fixture
```

脚本构建一次 Profile 根应用，然后运行 1280×720 ×3 与 1440×900 ×3。每轮固定 DPR 1、
12 秒预热、60 秒采样、30 秒冷却；任一轮失败即中止并保留原始目录，不允许挑最好成绩重签。
刷新率按主机实际值记录，不要求伪装为 60Hz。

## 5. 回传与裁决

回传完整 zip，主端独立验证：

- 六个唯一 run、两视口各三次；
- 同 commit、fixture、host manifest 和 `app.so` checksum；
- 原始帧、GC/RSS、对象池、碰撞负载与复合 Gate 全 PASS；
- renderer、driver、DPR、刷新率、100% 缩放和本地 Console 证据完整。

机械输出 PASS 只证明当前记录的 Windows 实体机生产兼容。它不证明更弱硬件可运行，
不制定产品最低配置，也不代签玩法手感或未来正式素材负载。

## 6. CI 边界

CI 可以验证 Windows Profile 编译、Dart/Flutter 测试、PowerShell 合同和证据包 checksum。
CI 不能代签物理显示、前台窗口调度、真实 renderer/driver、实体机帧时或主机 attestation。
