# 派单包 C · numbers.yaml 零引用 key 二轮对照单（只读审计单）

- 执行端：qoderclicn（Qwen3.8-Max）
- worktree：`/Users/a10506/Qoder/2026-09-19/c-unused-keys-round2/wt`（分支 `qoder/c-unused-keys-round2-20260919`，基线 `5d9bbdeaf`；纯脚本单，未预热，**不跑 flutter**）
- 派单基线（Gate 用）：`base_sha = 5d9bbdeaf`

## 0. 总则（硬约束）

- **语言**：commit message、文档一律简体中文；commit message 中文动宾（如「产出零引用 key 二轮对照单」）。
- **可写范围（白名单，精确路径）**：
  - `docs/audit/numbers_unused_keys_round2_2026-09-19.md`（新建，本单主产出）
  - `tools/audit/numbers_unused_keys_review.py`（既有，允许改：`--check` 冻结基线由 `c64b16593` 重锚到 `5d9bbdeaf`、冻结报告 sha 同步；**不得放宽判零口径、不得改 `numbers_key_usage.py`**）
  - `docs/superpowers/plans/2026-09-19-qoder-c-unused-keys-round2.md`（新建，恢复点）
  - `docs/dispatch/reports/2026-09-19_qoder_C_receipt.yaml`（新建，收据）
  - **其余一律禁改**，特别是 `data/numbers.yaml`（一个 key、一行注释都不动）、`data/**`、`lib/**`、`test/**`、`tools/audit/numbers_key_usage.py`、`docs/audit/numbers_yaml_unused_keys_review_2026-09-17.md`（B2 原表，只读）、`docs/audit/numbers_unused_keys_pending_decision_2026-09-17.md`（5A 对照单，只读）、`PROGRESS.md`、`BACKLOG.md`、`GDD.md`、`CLAUDE.md`、`AGENTS.md`、`data_schema.md`、`pubspec.yaml`。协调者以 `git diff --name-only` 机器判定：出现白名单外路径整单 FAIL。
- **git 边界**：只在自己的 worktree 提交；禁 push / merge / rebase / revert；禁碰 `main` 与 `codex/p2-player-flow-20260910`。
- **环境边界**：禁安装任何软件；只用系统 python3 与 git。
- **不碰真实存档**，不启动游戏 GUI，**不跑 `flutter`**（收据三条 last_line 写 `NOT_RUN`，见 §4）。
- **就绪标记**：最后实质 commit S 带 `[READY]`/`[BLOCKED]`；收据放独立包装 commit R（`R^ == S`），R 消息带同样标记。
- **审计纪律**：每条结论带可机器复核的证据（命令原文 + 命中数 + file:line）；禁止转抄 B2 原表 / 5A 对照单的数字，一律本次实测；不确定就写「未能判定」+ 原因。**删除配置字段是 🔴 用户拍板项，本单只产建议清单，一个 key 也不删、不接线。**

## 1. 背景（一句话）

B2 审计（`docs/audit/numbers_yaml_unused_keys_review_2026-09-17.md`）后，5A 对照单已由用户拍板处理了 tower 29 叶 + synergies 10 叶（删）、C 段 2 叶（头注）、E 段（转字段）、I 段（`can_take_disciple_at` 接线）；最近重扫（`numbers_key_usage.py --baseline HEAD`，C-A 后）零引用 **60 叶**，其中已标 UNUSED 57、未标 3（`equipment.enhancement.max_level_formula` / `equipment.enhancement.success_curve[].success_formula` / `equipment.resonance.new_owner_retention`）。本单对剩余 60 叶做二轮「留 / 删 / 接线」对照单，交用户按段拍板；同时把 `--check` 冻结基线重锚到当前 tip。

## 2. 目标清单（每目标收口 commit 一次）

### 目标 1：重扫 + 守恒

- `python3 tools/audit/numbers_key_usage.py --baseline 5d9bbdeaf --format json > /Users/a10506/Qoder/2026-09-19/c-unused-keys-round2/usage.json`，记录：总叶数、`verdict` 为零引用的叶数、其中 `unused_marked=true/false` 各多少、退出码。
- 与 5A 对照单末节登记的「99 → 60」做守恒核对（本次实测 60 ± 你能解释的差；差异逐叶列出并给 `git log -S'<key>' --oneline 5d9bbdeaf` 证据）。
- 未标 3 叶：逐叶给「为何 B2 标了保留理由却没标注」的判断（读 B2 原表 `:93-95` 与 `:976+` 节），提出头注文案建议（不写入 yaml）。

### 目标 2：60 叶三分类对照单

对每一叶（按 yaml 行号升序），一行一叶，列：`key` / 行号 / 当前值 / 已标 UNUSED? / B2 原判 / **本次分类** / 证据 / 代价：

- **分类只允许三种**：`留（设计指引，头注即可）` / `删（配置死叶，🔴 用户拍板）` / `接线（有真消费点却读了别的值或写死 Dart 常量）`。
- **「接线」判定必须做 5A I 段那种复核**：把 key 的**值**当领域词再搜一遍（如 `yiLiu`、`0.30`、公式片段 `0.50 - 0.02`），`git grep -n -F '<值>' -- lib test`；命中即列 file:line 并判定是否为同一门槛写死在 Dart（参考 5A I 段发现 `RealmTier.yiLiu` 写死在 `tutorial_service.dart` 的先例）。**只搜 key 名搜不到不算证据**（memory `feedback_negative_grep_not_proof_of_absence`）。
- 「删」类必须再给：`git log -S'<key>' --format='%h %ad %s' --date=short` 的加入 commit 与最近一次改动；GDD/`data_schema.md` 是否引用（`grep -n`）；若 GDD 引用则删除需 `[GDD]` 同步，标出章节。
- 按 numbers.yaml 段落分组（equipment / retreat / combat / …），每段给「推荐拍板 + 一句话理由」，推荐不得为省事偏向「留」——若证据支持删或接线就推荐删或接线（memory `feedback_no_effort_saving_in_recommendations`）。

### 目标 3：`--check` 重锚

- 读 `tools/audit/numbers_unused_keys_review.py`，把冻结基线 `c64b16593` 与冻结报告 sha 改为 `5d9bbdeaf` 与本次 `usage.json`/报告的对应 sha（按脚本既有机制，不改判零口径、不删任何检查）。
- 重锚后 `python3 tools/audit/numbers_unused_keys_review.py --check` 必须退出 0；重锚前的失败原文与重锚后的通过原文都记进报告。
- 若脚本的冻结机制不适合重锚（例如它锁的是 B2 报告全文 sha），写明原因并给替代方案，不硬改。

### 目标 4：对照单 + 结论

`docs/audit/numbers_unused_keys_round2_2026-09-19.md`（≤ 200 行，逐叶表可长）：基线与计数 / 守恒 / 分段对照表 / 段级推荐 / **回复格式**（如「E-留 R-删 …」）供用户拍板 / 未能判定项。

## 3. 禁止的修法

- 禁止改 `data/numbers.yaml`（含加注释）、禁止改 `numbers_key_usage.py`、禁止在 `numbers_unused_keys_review.py` 里放宽或删除检查。
- 禁止把「搜 key 名零命中」当成「无消费」的充分证据；禁止转抄 B2/5A 的计数。
- 禁止跑 `flutter`。

## 4. 收据与恢复点

- 按 `~/.claude/skills/afk/scripts/receipt.schema.md` 产 `docs/dispatch/reports/2026-09-19_qoder_C_receipt.yaml`：本单 `changed_files` 只含 docs + `tools/audit/*.py`（无 Flutter 相关文件），按 schema「NOT_RUN 口径」三条 last_line 写 `"NOT_RUN"`、`error_block_count: 0`；`audit_verification` 按固定命令计算 `diff_check_exit` 与 `patch_sha256`。
- 收据自引用口径：`head_sha` = 最后实质 commit S；收据单独提交为 R（`R^ == S`）。
- 恢复点 `docs/superpowers/plans/2026-09-19-qoder-c-unused-keys-round2.md`。

## 5. [BLOCKED] 出口条件

- 重扫零引用叶数与 60 的差异无法用 git 证据解释 → 记录、打 `[BLOCKED]`。
- `--check` 重锚后仍失败且原因不在白名单可改范围 → 记录、打 `[BLOCKED]`。

## 6. 验收方式（协调者怎么查）

- `gate.sh <worktree> 5d9bbdeaf <S> --whitelist-from <本派单包> --wrap-tip <R>`（Gate 自跑 analyze/format，收据 NOT_RUN 按纯脚本审计单接受）；协调者复跑 `numbers_key_usage.py --baseline 5d9bbdeaf` 对撞叶数，复跑 `--check` 退出码。
- 抽检 5 叶：3 个「接线」/「删」类 + 2 个「留」类，复算其值搜索与 `git log -S` 证据。
