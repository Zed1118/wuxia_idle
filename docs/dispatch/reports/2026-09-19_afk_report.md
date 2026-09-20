# 2026-09-19 挂机批早报（qoder × codex 双端 · 协调者 Gate）

授权:17:15 起 3h 自主(实际用户 21:52 回来续令「codex 可用、继续」,23:5x 收口);allow-merge/push 仅链 `codex/p2-player-flow-20260910`。时间线均取 git 时间戳。

## 当前完成

| 单 | 执行端 | 产出 | Gate | 合入 |
|---|---|---|---|---|
| A 链→main 合并预检 | qoder | `docs/audit/chain_merge_precheck_2026-09-19.md`:CI 7 步本地全绿(6976 测 / 覆盖 87.00%),结论「可合并但需知悉 6 条」 | 首跑 `-3`(与 C1/C2 开跑争抢,28min)→ 单独复跑 PASS(11:30 全绿) | `34b03b918` 23:32 |
| B 满 build 真实路径极值探针 | qoder | `test/tools/phase0a_full_build_extreme_probe_test.dart` + 画像夹具:3 流派 × 154 内容 × 周目 {1,max} = 924 轮,**max 382,584 < 1e6**,败 2(lingQiao 19_05/20_05 周目 3) | PASS | `d04f04ca3` 22:51 |
| C 零引用 key 二轮对照单 | 协调者自审(preflight BLOCKED 未派) | `docs/audit/numbers_unused_keys_round2_2026-09-19.md`:59 叶 → 删 26 / 接线 18 / 留 15;新发现 reference_multipliers 8 区间与 skills.yaml 实值脱节(50 个带 tier 的 powerSkill 38 越界) | — | `36781fbbf` 17:38 |
| C1 删 26 叶(用户拍板) | qoder | numbers.yaml 只减不增(+1 墓碑注释)、审计脚本登记同步;守恒 59→33 / 已标 32 | 9/10 PASS;`forbidden_files: numbers.yaml` 按拍板豁免 | `1592c5d67` 23:46 |
| C2 四项接线(用户拍板) | codex(372.8k tokens) | `high_level_success` 4 字段替代写死公式 / 奇遇 `attributeDelta` 加载期红线 / `time_range` 真读取 / 五战例测试改读 yaml;lib 写死残留 0,重扫 40 | 8/10 PASS;`forbidden_files` 同上豁免,`test_deletions` 41 行 = 手写字面值改 yaml 读(test 51→53、expect 143→147) | `92de16ae3` 23:56 |

**批末合并 tip 验证**:`flutter analyze` 0 issue、全量 `09:46 +7027` 全绿、重扫零引用 14 叶(全为 validation_examples 文案叶,已标)。协调者独立复跑:B 探针 924/382584 一致;A 缺的两项 macOS 原生测试本地 sfx 10/10、窗口 5/5;C2 复做 `floor_rate` 0.40 证红 -2、还原 29/29。

## 代拍决策清单(全 🟢/🟡,无红级代拍)

- 🟢 C 单不派 qoder 改自审:preflight `wip_running` 7/2 结构性 BLOCKED(见下),不绕门禁。
- 🟢 qoder C1 被自身 harness 600s 后台等待上限掐断 → 发续跑小包(`docs/dispatch/2026-09-19_qoder_C1_续跑收口.md`,`QODERCLI_PRINT_BG_WAIT_CEILING_MS=0`)收口。
- 🟡 Gate `forbidden_files` 对用户已拍板的 numbers.yaml 改动仍 FAIL → 本批按拍板豁免合入;建议 gate.sh 加 `--allow-forbidden <path>`。
- 🟡 gate.sh FAIL 时清掉全量日志 → 已改(`~/.claude` `02a0cbb`):退出前留档 `~/.claude/gate_logs/`。
- 🟡 preflight `afk_lib.branch_states` 把所有本地分支(链/协调/锁定 worktree/m4)算 RUNNING → 建议只数执行端前缀分支。

## 需你知悉/拍板

1. **A 知悉项 ①**:链合 main 后 saveVersion 0.49→0.50,不可回退;⑤ main 既有 12 个 `test/tools/output/*` 被跟踪,是否清出。其余 4 条只登记(见 A 报告 §结论)。
2. C 对照单 §2 C 段附带 🟡:`enhancement_service._enhanceLevelCap` 的 49 硬编码(与 realms 绝对层数上限同值)——是否立微修单。
3. `numbers_key_usage.py` 里对已删段 `combat.final_damage_formula.` 仍有 3 处空登记(无害),🟢 下次顺手清。
4. `~/Documents/Codex/2026-09-13/p2-ci-recovery/m4-54aed-worktree`(24 个未提交 lib 改动 + 未跟踪测试)🔴 仍留给你。
5. B 报告登记的 2 处周目 3 败局(lingQiao 19_05 / 20_05)只登记不调值。

## 决策菜单(用户 2026-09-20 回复 `1A 2A 3A`,已执行)

| # | 项 | 拍板 | 执行结果 |
|---|---|---|---|
| 1 | 12 个 `test/tools/output/*` 跟踪产物 | A 清出跟踪 | codex D 单 `cddf20b4a`+`6cb1622b4`:首轮 Gate 在干净 checkout 全量 `-3`,查明 **6 个是黄金文件**(`phase0a_idle_island_parity`/`full_content_balance`/`ch1_real_skill_profile` 三条 diagnostic 测试读它们比对)→ 恢复跟踪;实际清出 5 个产物,`phase2_g2_stage_01_03_acceptance_record.md` 是手写 G2 记录、`git mv` 到 `docs/audit/` 并改 4 处引用。🟡 若想连黄金文件也搬出 `test/tools/output/`,需改 3 条测试路径,另立单 |
| 2 | `_enhanceLevelCap` 49 硬编码 | A 读 realms 上限 | `bcfa2fef2`:新增 `RealmUtils.maxAbsoluteLevel`(realms 表最大 `absolute_level`,非 release_cap),`enhancement_service` 与 `enhance_dialog._capHardLimit` 改读;新测 `enhancement_cap_realms_test` 注入表降 48 的 numbers 夹具,两向 mutation 各红 1/2 条,协调者复做 ① 红 1;`numbers.yaml:727` 注释同步(唯一 forbidden 命中,`--allow-forbidden` 明示豁免);Gate 全量 `08:29 +7030` 全绿 |
| 3 | gate.sh `--allow-forbidden` + preflight 只数执行端分支 | A 两项都改 | `~/.claude` `4544d39`:executors.json 每端加 `branch_prefix`;`branch_states(prefixes, ignore)` 把非执行端前缀与主 checkout 检出链归 `other`;实仓 dry-run 7/2→1/2;test_preflight 新增 4 条(既有 `codebuddy` bin 缺失那条红与本改无关) |

链 tip `ca92ec412`(合并 `--no-ff`),已推 `codex/p2-player-flow-20260910`;`origin/main` 仍 `342d19275`。

## 第二轮拍板(用户 2026-09-20 回复 `1合 2做 5做 6做`,已执行)

| # | 项 | 结果 |
|---|---|---|
| 1 | 链 → main | `origin/main` 342d19275 → `b99cfa72d`(纯 ff,136 commit),CI run 35493047229 **success**;随后 E 单入链再 ff 到 `795114c37`,CI run 35494420672 见 PROGRESS |
| 2+6 | 黄金文件搬家 + 审计脚本空登记 | codex E 单 `f56ea20d4`:6 个黄金文件 100% rename 到 `test/tools/golden/`(不再被 ignore),3 条 diagnostic 测试只改路径常量;`numbers_key_usage.py` 删 3 处 `combat.final_damage_formula` 登记,扫描 14/14 不变;Gate 全量 `08:32 +7030` 全绿。执行端打 `[BLOCKED]` 是派单包验收项「tools 零命中」与冻结的 `numbers_unused_keys_review.py:49` 互斥(派单包写错,🟢 放行);`test_deletions` 6 行 = 6 个路径常量,逐行核实豁免;`receipt_crosscheck` 因 gate 审计单口径要求 `break_red` 为空而派单包要求一组,以派单包为准 |
| 5 | 注册表 | `~/.claude` `5a02399`:codebuddy `enabled=false` + caveat;冒烟测只查已启用端 bin,38/38 |

🟡 gate.sh 待改:审计单(零 `lib/` 改动)若派单包要求证红,应接受非空 `break_red` 而非 schema 报错;rename 型 test 改动的 `-` 行需能按「路径常量替换」豁免。

仍待你:③ `~/Documents/Codex/2026-09-13/p2-ci-recovery/m4-54aed-worktree` 24 个未提交 lib 改动;④ P13 死链口径拍板。
