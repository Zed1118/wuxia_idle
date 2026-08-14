# Phase 0B art-load 交叉审查恢复计划

> **日期**：2026-08-14
> **基线**：Kimi commit `3db99c2b`（Phase 0B 固定镜头 20+1 观察矩阵已固化）
> **审查者**：QoderCN（独立 worktree `fix/phase0b-qoder-cross-review`）
> **状态**：执行中

## 0. 一句话

修复 Phase 0B art-load 工程收口的三个结构性缺陷，使 fresh checkout 可跑日常测试、证据不随 HEAD 漂移、runner 契约 fail-closed 而非隐式硬编码本机参数。

## 1. 发现的问题

### 1.1 测试依赖 gitignored 产物（fresh checkout 不可运行）

`test/phase0b/phase0b_art_load_evidence_test.dart` 直接读取 `tools/phase0minus_probe/build/results/phase0b-art-load/` 下的矩阵 JSON。该路径被根 `.gitignore` 的 `build/` 规则忽略，fresh checkout 无此目录，测试直接失败。

**修复**：将 Kimi 最后一轮矩阵报告（唯一真实证据）冻结到 `docs/phase0/evidence/`，测试改读该处。

### 1.2 `build_commit` 等同 HEAD（后续提交即失效）

测试断言 `buildCommit == headCommit`。任何后续 commit（包括本修复本身）都会让测试失败，即使证据完全有效。

**修复**：改为断言 `build_commit` 是当前 HEAD 的历史祖先（`git merge-base --is-ancestor`），保证证据绑定的是已提交状态而非瞬时 HEAD。

### 1.3 art-load runner 把本机 144Hz 硬编码为通用默认

| 脚本 | `PROBE_EXPECTED_REFRESH_RATE` 默认 | 实际来源 |
|---|---|---|
| `run_phase0b_art_load_macos.sh` | **144** | Kimi 本机外接屏 |
| `run_phase0b_scroll_macos.sh` | 60 | spec §3.1 目标 |
| spec §3.1 | 60Hz（Windows 目标）/ 记录实际 | — |

art-load runner 把 Kimi 本机 144Hz 写成了默认值，如果另一台 60Hz 机器跑这个脚本且不设环境变量，jq 验证会因 `refresh_rate_hz == 144` 失败。这是把本机参数误当通用契约。

**修复**：两个 runner 统一改为 fail-closed——不设环境变量就报错退出，不允许静默假设。DPR 同理。

### 1.4 不伪造/不重跑 6 轮矩阵

已有矩阵报告是 Kimi 在 commit `3db99c2b` 上真实运行的 6 轮结果（2 视口 × 3 重复）。不得重跑、不得修改数值。只冻结既有 JSON 并调整测试契约。

## 2. 执行步骤

### Step 1：冻结证据（observation-only）

1. 从 Kimi worktree 复制 `phase0b-art-load-matrix-20260814T124851Z.json` 到 `docs/phase0/evidence/phase0b-art-load-matrix-frozen.json`
2. 生成 `docs/phase0/evidence/phase0b-art-load-matrix-frozen.json.sha256` 校验和
3. 提交信息：`[phase0b] 冻结 art-load 矩阵证据到 docs/phase0/evidence (observation-only)`

### Step 2：修复证据测试

重写 `test/phase0b/phase0b_art_load_evidence_test.dart`：
- 读 `docs/phase0/evidence/phase0b-art-load-matrix-frozen.json`
- `build_commit` 改为 `git merge-base --is-ancestor <build_commit> HEAD`
- 素材 SHA-256 仍校验（文件在 `tools/phase0minus_probe/assets/phase0b/runtime/`，未被 gitignore）
- 保留 schema/claim/observation 结构断言
- 提交信息：`[phase0b] 证据测试改为读冻结 JSON + 祖先校验`

### Step 3：修复 runner DPR/refresh 契约

修改 `run_phase0b_art_load_macos.sh` 和 `run_phase0b_scroll_macos.sh`：
- 删除 `:-144` / `:-60` / `:-2` 默认值
- 若 `PROBE_EXPECTED_REFRESH_RATE` 或 `PROBE_EXPECTED_DPR` 未设置，打印错误并 `exit 2`
- 提交信息：`[phase0b] runner DPR/refresh 改 fail-closed，删除本机硬编码默认`

### Step 4：更新嵌套契约测试

在 `tools/phase0minus_probe/test/phase0b/phase0b_art_load_runner_contract_test.dart` 增加断言：
- runner 不含 `:-144` 或 `:-60` 默认
- runner 包含 fail-closed 错误退出逻辑
- 提交信息：`[phase0b] 嵌套契约测试验证 runner fail-closed`

### Step 5：根级 analyze + targeted tests

- `flutter analyze` 根项目
- `flutter test test/phase0b/` 根项目
- `cd tools/phase0minus_probe && flutter test test/phase0b/`
- 提交信息：`[READY] Phase 0B art-load 交叉审查完成`

## 3. 不做什么

- 不碰 `lib/`、`data/` 生产代码
- 不重跑矩阵
- 不修改已有 observation 数值
- 不删除 Kimi 已提交的 commit
- 不引入新依赖

## 4. 验收标准

1. Fresh checkout（无 `build/results/`）跑 `flutter test test/phase0b/` 全绿
2. 新 commit 不会让证据测试失效（祖先校验）
3. 另一台 60Hz Mac 跑 art-load runner 不设环境变量 → 立即报错，不静默通过
4. `flutter analyze` 无新增 warning
5. 工作区干净，tip 为 `[READY]`
