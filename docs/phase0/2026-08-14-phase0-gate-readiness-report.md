# Phase 0 外部门禁工程就绪报告

> 状态：`ENGINEERING_READY / EXECUTION_PENDING`
> 审计基线 commit：`06ab4162`（phase0b 分支起点，外部门禁工程尚未开始）
> 初次工程 READY 标记：`78a281a3`（后续文档修正已超越此 commit；最终 tip 请以 `git log -1` 为准）
> Worktree：`feat/phase0b-qoder-gate-readiness`（隔离分支，未合入 main）
> 审计日期：2026-08-14
> 审计范围：`tools/phase0minus_probe/`、`docs/phase0/`、相关 spec；不触碰根应用或正式游戏规则。
> **重要说明**：本报告审计的是**工程就绪状态**（工具链、测试、文档），**不是外部门禁的执行结果**。Windows 物理机 Gate 和真人 Gate 均尚未执行（见 §2），需操作者在实际环境中执行后方可获得 PASS/FAIL 结论。
>
> **测试计数修正说明**：早期文档草稿中曾出现"27 tests"和"29/29"的计数，均为人工估算错误。本文档 §4.1 所列完整命令 `flutter test --no-pub test/gate/ test/human_gate/ test/isolation_contract_test.dart test/viewport_calibration_contract_test.dart` 的实际新鲜输出为 **33/33 通过**（见 commit `d2bef804` 及后续验证）。测试文件本身在 phase0b 分支期间未改动，计数差异纯属文档错误。

---

## 1. 已就绪

### 1.1 Windows 最低档物理机 Gate 工具链

| 环节 | 文件 | 状态 |
|---|---|---|
| 主机信息采集 | `scripts/collect_phase0a_windows_host_manifest.ps1` | 故意输出 `CAPTURED_NOT_ATTESTED`，attestation 全 false，renderer 为 `FILL_*`；须人工核对后改 `RECORDED` |
| 主机信息模板 | `config/windows_minimum_spec_manifest.template.json` | 占位完整 |
| 单次 Profile 运行 | `scripts/run_phase0a_windows_profile.ps1` | 锁定 `phase0a_replay`、DPR 1、60Hz、DurationScale 1.0；校验 git dirty、scenario checksum、host attestation、RDP/VM 拦截 |
| 完整矩阵 | `scripts/run_phase0a_windows_matrix.ps1` | 构建一次 → 1280x720 x3 + 1440x900 x3 → validator → SHA256SUMS → zip |
| 结果校验器 | `tool/validate_phase0a_windows_results.dart` | 读 results-root + host manifest → `validatePhase0aWindowsGate()` → JSON + Markdown 报告 |
| 核心校验逻辑 | `lib/gate/windows_gate_validator.dart` | 21 项逐 run 检查 + 14 项 host 检查；独显/RDP/VM/混 binary/缺 evidence/placeholder 全 fail-closed |
| 破坏性证伪测试 | `test/gate/windows_gate_validator_test.dart` (5 tests) | 合法矩阵 PASS；benchmark 伪装 FAIL；远程+未签字+混 binary+缺 evidence FAIL；**独显代签 FAIL**；**混 commit FAIL** |
| 脚本契约测试 | `test/gate/windows_gate_scripts_test.dart` (4 tests) | Profile runner 锁定 replay；Matrix 覆盖两视口 x3；采集脚本不能自签；macOS runner 防休眠 |

### 1.2 真人试玩 Gate 工具链

| 环节 | 文件 | 状态 |
|---|---|---|
| 匿名身份 | `lib/human_gate/playtest_identity.dart` | P01-P06、AB/BA、slot 1-6；环境变量注入 |
| 冻结排期 | `config/phase0a_human_gate_schedule.json` | 6 人：2 idle + 2 arpg + 2 mixed；3 AB + 3 BA；无 PII |
| 原始报告 schema | `lib/human_gate/playtest_report.dart` (v2) | 14 必填 key + 6 禁填 PII key；原子写入 |
| 问卷 schema | `lib/human_gate/human_session.dart` (v1) | 17 必填分组；5 帧冻结 stimulus ID + SHA-256；有效性-完整性交叉校验 |
| 执行证据 | `lib/human_gate/human_execution_evidence.dart` | session.state + execution.events；AB/BA 序分别校验 |
| 机械聚合 | `lib/human_gate/playtest_aggregator.dart` | 6 人排期完整性、AB/BA 计数、build_commit 一致性 |
| 爽感裁决 | `lib/human_gate/human_gate_aggregator.dart` | 13 项 pass check（3 中位数 >= 4、4/6 重玩、5/6 主角、24/30 危险、无否决…）；exit code 0/1/2/70 |
| 破坏性证伪测试 | `test/human_gate/human_gate_aggregator_test.dart` (10 tests) | 边界通过；不足 6 人 INCONCLUSIVE；否决 FAIL；3/6 失败；PII/评分/有效性矛盾 FAIL；败局重试不算；**重复测试者 INCONCLUSIVE**；**缺失原始报告 INCONCLUSIVE**；混包+违反排期 INCONCLUSIVE；**进程退出码不可信** |
| 身份与排期测试 | `test/human_gate/playtest_human_gate_test.dart` (7 tests) | 边界合法；PII/越界 FAIL；原子写入无残留；排期匿名平衡；**越界元数据 FAIL**；**AB/BA 序交换 FAIL**；**混 build FAIL** |
| 执行证据测试 | `test/human_gate/human_execution_evidence_test.dart` | 完整 AB PASS；中断 FAIL |
| macOS 主持脚本测试 | `test/host_human_session_macos_test.dart` | 排期平衡；AB/BA 串行；重复参与者 exit 68；篡改冻结文件 exit 66 |

### 1.3 隔离与视口契约

| 测试 | 守护 |
|---|---|
| `test/isolation_contract_test.dart` (5 tests) | probe 源码无 `package:wuxia_idle/`、`isar`、`path_provider` 等生产导入；嵌套 pubspec 无持久化依赖；根 pubspec 无 Flame；Windows Gate 工具留在 probe 内 |
| `test/viewport_calibration_contract_test.dart` | main.dart 实现 20 次重试 + 3 次连续匹配 + 校准失败关窗 |

### 1.4 Mac 性能基线（已通过）

- Phase 0-minus：18/18 runs PASS（commit `c8b759fb`）
- Phase 0A：6/6 runs PASS（commit `965e948e`，p99 < 3.7ms）
- 10-seed 策略门：weak 9/10 fail、baseline 10/10 pass

---

## 2. 仍需人类/设备

| 项 | 为何不能在本任务内完成 |
|---|---|
| Windows 最低档物理机 | 须 i5-8250U / UHD 620 / 8GB 实体机；CI、云桌面、RDP、VM 均不可签字 |
| 6 名真人测试者 | 须非实现者、匿名、按冻结排期执行；Agent/作者不可充当 |
| 主观评分与可读性判断 | 1-5 评分、五帧可读性、直接否决项均须真人填写 |
| 人工 attestation | host manifest 的 `valid_for_minimum_spec_gate` 等字段须操作者核对 dxdiag/任务管理器后手改 |

---

## 3. 回传目录结构

### 3.1 Windows Gate 回传

```
build/windows_gate_matrix/<timestamp>/
├── host_manifest.json                     # RECORDED + 人工 attestation
├── phase0a-replays/
│   ├── phase0a-replay-windows-desktop_1280x720-r1-*/
│   │   ├── manifest.json
│   │   ├── summary.json
│   │   ├── frames.jsonl
│   │   ├── memory_gc.jsonl
│   │   └── run.log
│   ├── ... (共 6 个 run 目录)
├── validation/
│   ├── windows_gate_validation.json
│   └── windows_gate_validation.md
├── SHA256SUMS.txt
└── (打包为 <timestamp>.zip 回传)
```

### 3.2 真人 Gate 回传

```
results/sessions/
├── P01/
│   ├── session.state                      # status=COMPLETE
│   ├── execution.events                   # comparison_complete\ngameplay_complete\nreadability_complete
│   ├── human-session.json                 # schema=phase0a-human-session-v1
│   └── raw-report.json                    # schema_version=2
├── P02/ ... P06/
└── human-gate-summary.json               # 聚合器输出
```

---

## 4. 验证命令

### 4.1 工程验证（Mac 端，CI 可跑）

```zsh
cd tools/phase0minus_probe

# 静态分析
flutter analyze --no-pub

# 全部门禁契约测试（33 tests）
flutter test --no-pub test/gate/ test/human_gate/ test/isolation_contract_test.dart test/viewport_calibration_contract_test.dart

# Phase 0B 合约测试
flutter test --no-pub test/phase0b/

# 配置与度量测试
flutter test --no-pub test/config/ test/metrics/
```

### 4.2 Windows Gate 验证（物理机端）

```powershell
cd .\tools\phase0minus_probe

# 1. 采集主机信息（故意不签字）
.\scripts\collect_phase0a_windows_host_manifest.ps1

# 2. 人工核对后编辑 config\windows_minimum_spec_manifest.captured.json
#    改 status → RECORDED，填 renderer，确认 gpu_is_integrated，改 attestation

# 3. 跑完整矩阵
$Commit = git -C ..\.. rev-parse HEAD
$Checksum = (Get-FileHash -Algorithm SHA256 .\assets\probe_scenarios.yaml).Hash.ToLowerInvariant()
.\scripts\run_phase0a_windows_matrix.ps1 `
  -HostManifest .\config\windows_minimum_spec_manifest.captured.json `
  -ExpectedCommit $Commit `
  -ExpectedScenarioChecksum $Checksum

# 4. 输出 PHASE0A_WINDOWS_MATRIX_PASS 表示机械通过
# 5. 回传 <timestamp>.zip
```

### 4.3 真人 Gate 验证（Mac 端主持）

```zsh
cd tools/phase0minus_probe

# 主持单人会话
./scripts/host_phase0a_human_session_macos.sh \
  --participant P01 --order AB --slot 1 \
  --package-id <commit-short> --results-root results/sessions

# 六人完成后聚合
dart run bin/phase0a_human_gate.dart human results/sessions results/human-gate-summary.json

# 输出 HUMAN_GATE_PASS / LOCAL_FAIL / INCONCLUSIVE
```

---

## 5. 失败处置

| 失败场景 | 检测方式 | 处置 |
|---|---|---|
| 独显代签 | `gpu_is_integrated` 校验 | validator FAIL；不签字 |
| RDP/VM 会话 | `remote_desktop`/`virtual_machine` 校验 | validator FAIL + runner throw |
| 混 commit / 混 binary | 逐 run `git_commit` + `binary_sha256` 一致性 | validator FAIL |
| 视口不足 6 run | `viewportRunCounts` 每视口须 == 3 | validator FAIL |
| 结果 checksum 漂移 | `files_sha256` vs 实际文件 | validator FAIL |
| 不足 6 人 | `valid.length == 6` | INCONCLUSIVE |
| 重复测试者 | `seenParticipants` | INCONCLUSIVE + schema error |
| 混包 / 违反排期 | `package_id` 一致性 + frozen schedule | INCONCLUSIVE |
| 缺失原始报告 | `rawByRunId` 查找失败 | INCONCLUSIVE + schema error |
| 直接否决项 | `direct_veto.*` | LOCAL_FAIL |
| 冻结文件篡改 | SHA-256 校验 | host exit 66 HASH_MISMATCH |
| 样本不足 / 有效性矛盾 | 中位数/阈值 + integrity 交叉 | LOCAL_FAIL 或 INCONCLUSIVE |

---

## 6. 红线影响与残留风险

### 红线影响

- 本任务 **零改生产数值**、**零改生产中文文案**、**零触碰根应用 `lib/`**。
- 所有改动限于 `tools/phase0minus_probe/test/`（新增 4 个破坏性测试）和 `docs/phase0/`（本文件）。
- 不影响 §5.2 七阶节奏、§5.3 三系锁死、§5.4 数值红线、§5.5 在线=离线。

### 残留风险

| 风险 | 级别 | 说明 |
|---|---|---|
| Windows 物理机不可用 | 阻塞 | 本任务无法执行真实 Windows Gate；只能准备工具链 |
| 6 名真人不可用 | 阻塞 | 本任务无法执行真人 Gate；只能准备工具链和验证 fail-closed |
| `libisar.dylib` 截断 | 低 | fresh worktree 需从主仓拷完整 dylib 才能跑测试 |
| Phase 0B 美术资产 | 低 | 手工骨骼绑定尚未完成；art review 工具链已就绪 |
