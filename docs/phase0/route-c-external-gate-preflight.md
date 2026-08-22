# Route C 外部 Gate 预检

> 状态：`HUMAN_PENDING / WINDOWS_PENDING`。预检只防串包、缺样本和旧 probe 冒签，
> 不代替真人操作或 Windows 最低档物理机采样。

## 对象纠偏

历史 `phase0a-playtest-protocol.md` 的“旧战斗→新灰盒” AB 对照，以及
`tools/phase0minus_probe` 的 Windows 性能矩阵，均属早期隔离 probe 证据。它们可供
历史追溯，但不能签 Route C 生产根应用删除 Gate。

新证据必须同时绑定：

- 待删候选 commit；
- 根应用 `wuxia_idle` 的 Profile binary SHA-256；
- 六人使用生产可玩路由 `phase0a_battle_playable`，Windows 使用同核循环负载
  `phase0a_battle_profile`；
- 六人全部同包，Windows 六次全部同 binary。

## 六人原始样本

每人一个 `human-session.json`，schema 为 `route-c-human-session-v1`，只用
`P01`–`P06` 匿名编号。除既有爽感、可读性、再战意愿外，必须原始记录：

- Boss 蓄力预警是否被看到；
- 可打断反馈是否被理解；
- 破招后硬直是否被看到；
- vulnerability window 是否被理解；
- 键鼠是否由测试者本人完成；
- 是否无溢出、卡死、实现者代打或外部污染。

在待删候选的干净 Mac 工作树上一次性构建并复制冻结包；脚本只准备包，不启动 GUI：

```bash
tools/route_c_gate/prepare_route_c_human_package.sh HEAD \
  build/route_c_human_gate
```

六个会话必须使用包内同一 `wuxia_idle.app`，按生成的 P01–P06 模板填写。排期固定为
两种视口各 3 人、`idle/arpg/mixed` 各 2 人。任何姓名、邮箱、账号、电话等 PII 字段
都会令证据 `INCONCLUSIVE`；实现者代打、外部事件污染或问卷未完成的样本不得标记
`valid=true`。

六轮完成后，重新散列回传包内的实际 executable 与 fixture，再执行机械聚合：

```bash
dart run tool/route_c_human_gate.dart aggregate \
  --candidate HEAD \
  --sessions build/route_c_human_gate/sessions \
  --manifest build/route_c_human_gate/package-manifest.json \
  --app build/route_c_human_gate/package/wuxia_idle.app/Contents/MacOS/wuxia_idle \
  --fixture build/route_c_human_gate/package/phase0a_debug_battle.yaml \
  --output build/route_c_human_gate/human-gate-summary.json
```

机械阈值为：三项评分中位数均不低于 4；至少 4/6 愿意再战；蓄力预警、打断反馈、
硬直和 vulnerability window 各至少 5/6 被识别；键鼠本人完成与无溢出/卡死均须
6/6；至少 5/6 无协助完成三轮；任一直接否决项为 true 都是 `LOCAL_FAIL`。
不足六个有效样本、串包、混 fixture、PII 或完整性矛盾均为 `INCONCLUSIVE`，不会冒充
体验失败或通过。

## Windows 物理机样本

保留 `phase0a-windows-physical-gate.md` 的最低档硬件、本地 Console、60Hz、100% 缩放与
两视口各三次要求，但采样对象改为根应用 Profile binary。每次结果目录必须有
`manifest.json`，schema 为 `route-c-windows-production-run-v1`，路由为
`phase0a_battle_profile`，且组合性能 Gate 已由
生产版采样器判为 `PASS`。旧 `phase0minus_probe.exe` 结果会被预检直接拒绝。

在候选 commit 的干净 Windows 工作树上执行：
主机信息从 `tools/route_c_gate/windows_minimum_spec_manifest.template.json` 复制填写，
不得原样使用模板。

```powershell
$Commit = git rev-parse HEAD
$Fixture = (Get-FileHash -Algorithm SHA256 .\data\phase0a_debug_battle.yaml).Hash.ToLowerInvariant()
.\tools\route_c_gate\run_route_c_windows_matrix.ps1 `
  -HostManifest .\windows_minimum_spec_manifest.captured.json `
  -ExpectedCommit $Commit `
  -ExpectedFixtureChecksum $Fixture
```

根应用只构建一次，每次执行 12s 预热 + 60s 采样 + 30s 冷却。组合 Gate
严格要求有效帧数、p99 总帧时、严重慢帧连续峰值、GC telemetry 与 RSS 回落；
任一项失败即中止并保留原始目录。

最终预检不直接信任每轮 `manifest.json` 自报的 `composite_gate=PASS`：它会重新读取
`frames.jsonl` 与 `memory_gc.jsonl`，独立计算样本数、p99、build/raster/严重慢帧连续峰值、
GC 状态和 RSS 首尾值，再与 `summary.json` 逐项对照；同时重新散列并校验
`host_manifest.json`，拒绝独显、RDP、虚拟机、非 60Hz/100% 缩放或未填 renderer。
矩阵包同时冻结 `wuxia_idle.exe` 与 `phase0a_debug_battle.yaml`，最终预检会重新散列
二者并与六轮 manifest 对照，不能只填写一个看似合法的 64 位哈希冒签。

## 执行

```bash
dart run tool/route_c_gate_preflight.dart \
  --candidate <candidate-ref> \
  --human-dir <six-human-results> \
  --windows-dir <windows-matrix-results> \
  --output <preflight-report.json>
```

退出码：`0=PASS`、`2=PENDING`、`1=INVALID`。只有三项 Gate 都通过后，才能将候选
删除提交原子整合到主线并重跑全量验证。
