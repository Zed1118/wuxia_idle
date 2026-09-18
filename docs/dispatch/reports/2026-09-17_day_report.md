# 2026-09-17 日批收账报告（21:39 → 22:26 · Claude 调度审核 · Codex 执行 B2）

> 时间戳取自 git / dispatch.log / gate.log。交付状态事实源 = git；**B2 分支与协调者分支均未入链、未推 main**，是否入链由下方菜单拍板。

## 当前完成

| 项 | 交付 | 验证（协调者独立实测） | 状态 |
|---|---|---|---|
| #1 ③ 代码类 6 worktree 处置 | 6 个 `archive/codex/<分支名>` 标签（tip 与 09-16 台账逐一相符）推 origin；6 个 worktree 干净移除、本地分支删除 | `ls-remote --tags` 6/6；`worktree remove` 未加 `--force` 6/6 成功 = 无脏树；worktree 14→9、本地分支 14→9 | **完成** |
| #2 B2 零引用 key 逐条复核 | `codex/b2-unused-keys-review-20260917` @ `964c5be02`（审计提交 `411e200f4`，5 commit，已推 origin 备份）：`numbers_key_usage.py` 加 `--baseline`；新 `numbers_unused_keys_review.py`（四层复核 530 条命令、`--check` 逐字节回放）；报告 `docs/audit/numbers_yaml_unused_keys_review_2026-09-17.md`；恢复点；收据 | gate：forbidden/scope/test_deletions/commit_msg/worktree_clean PASS，analyze `No issues found! (ran in 50.9s)`、format `Formatted 1857 files (0 changed)`；receipt_crosscheck 仅 analyze/format 两项授权 `NOT_RUN`；detached `411e200f4` 复跑 `--check`「四层复跑与报告逐字节一致」、报告 SHA `3f309166…` 同；抽 8 条零引用 lib 字面量 8/8 为 0；抽 3 条合同 `GDD.md:174` / `data_schema.md:182` / `CLAUDE.md:564` 真实 | **REVIEWED，未入链** |

B2 实测结论（链 tip 重锚后）：标量叶子 1796 / 归一路径 847；零引用 **202 叶 / 87 路径 / 51 末段**（与 B-2 原表集合一致，新增 0 移出 0）；生产消费 234、待人判 1360。

| 四类建议 | 归一路径 | 叶子 | 主要段 |
|---|---:|---:|---|
| 删除候选 | **0** | 0 | — |
| 头注 UNUSED | 42 | 53 | validation_examples 20、skills 参考倍率 8、combat 公式开关 6、inheritance 3、retreat 时段锚 2、character 2、meta 1 |
| 保留（有合同） | 22 | 106 | equipment.tiers 16/94（`data/equipment.yaml:7` 明文要求对齐）、character.attributes 5（CLAUDE.md §12.2 #2）、techniques.tiers.tier_name 1/7 |
| 待拍板 | 23 | 43 | tower 旧段 9/29（与 towers.yaml 合同冲突）、synergies 旧段 10/10（与 synergies.yaml 格式分叉）、character 收徒门槛 2、inheritance 2 |

「误判：实际消费」0；对 B-2 原表的更正 = 原「删除候选」57 路径全部改列合同保留/文档锚/待拍板。**没有一个 key 满足「无合同、无设计锚、无待决冲突」的删除条件**。

## 代拍清单

| # | 时间 | 事项 | 级 | 依据 |
|---|---|---|---|---|
| 1 | 21:40 | 本会话 cwd 落在与链分叉的协调者 worktree；改从链 tip 开集成 worktree `dispatch-20260917` 工作，原 worktree 只读 | 🟢 | NEXT.md 明文「不再作集成基线」 |
| 2 | 21:44 | 6 个 ③ 代码类分支对链 `cherry` 各含 ≥1 `+`，统一「归档标签后删」而非直删 | 🟢 | 与 09-17 7A 口径一致，零内容丢失 |
| 3 | 22:13 | B2 收据 head_sha 自引用形式冲突：接受收据绑定最后审计提交、收据单独封装提交 | 🟢 | 与夜批 B 单 00:25 已接受口径一致 |
| 4 | 22:22 | gate 白名单漏传收据路径（派单包 §0 已列）→ 补传复跑 | 🟢 | 调用侧笔误 |

无 🔴 代拍；未改任何 yaml / lib / test。

## 决策菜单

| # | 问题 | 选项 | 推荐 |
|---|---|---|---|
| 1 | B2 分支入链？ | **1A** `--no-ff` 合入 `codex/p2-player-flow-20260910`（纯 docs/audit + tools/audit，gate 实质通过） · 1B 不合只留 origin | **1A** |
| 2 | 协调者分支 `claude/dispatch-20260917`（派单包、盘面、本报告、PROGRESS 一行）入链？ | **2A** 与 1A 同次合入 · 2B 不合 | **2A** |
| 3 | 头注 UNUSED 42 路径 | **3A** 派 codex 一单只在 `numbers.yaml` 对应段头加 `# UNUSED` 注释（白名单仅注释行，附 YAML 解析结果 sha 不变守卫；`numbers.yaml` 属「改前 ask」文件，故仍需你点头） · 3B 不动 | **3A** |
| 4 | 保留（有合同）22 路径 | **4A** 合同转守卫测试：equipment.yaml 每件数值落在 `numbers.equipment.tiers` 区间、`tier_name` 与 `EnumL10n` 七阶名一致、角色属性生成落在 `[1,10]/[16,24]`——让「合同」变成被测试消费的事实，零引用自然消失 · 4B 维持文档合同 | **4A**（行为守卫，不改数值） |
| 5 | 待拍板 23 路径 | 5A 我按四段（tower / synergies / character 收徒 / inheritance）各出一句话方案对照，下轮逐段拍 · 5B 统一挂到 M7 塔 8–14 层迁移后再议 | **5A**（synergies/character/inheritance 各有明确替代源，可较快定；tower 段可单独 5B） |
| 6 | 下一单 | **6A** NEXT #4：`tools/phase0minus_probe` 子包 analyze 1892 条噪声（pub get 或排除，派 codex ~20min） · 6B NEXT #3 真人试玩（用户主导） | **6A** |

## 晚续（22:2x → 23:xx · 用户「全部按推荐执行，由你直接工作，不派 codex」）

| 项 | 交付（commit） | 验证（本会话实测） | 状态 |
|---|---|---|---|
| 1A B2 入链 | `239c0540f` `--no-ff` 合入 `claude/dispatch-20260917` | 分支线性含 B2 5 commit | 完成（随 2A 推链） |
| 3A 头注 UNUSED | `8d6a00299` `numbers.yaml` +14 注释行 | YAML 解析 sha 不变 `6d8cafb5…`；53/53 叶 `unused_marked`；verdict 不变 | 完成 |
| 4A 合同转守卫 | `5335f8300` + `00ca60825`；`NumbersConfig.attributeBounds`；校验器 4 处硬编码改读配置；新守卫 `test/data/numbers_tier_contract_guard_test.dart`（5）、`test/data/validation/attribute_bounds_from_numbers_test.dart`（14）；required_keys +4 | analyze 0；定向 5/14/32/120 + chinese_literal_audit 2 全绿；commit 后破坏证红 2/2（装备越界、tier_name 改字）还原复绿；重扫 guard passed 零引用 202/87/51 → **99/68/41**，合同保留 106 叶全部脱离零引用 | 完成 |
| 5A 待拍板对照 | `2626cf002` `docs/audit/numbers_unused_keys_pending_decision_2026-09-17.md` | 事实行号为 3A 后现值；含 4A 发现的装备命名奖励越阶 E 段 | 完成（🔴 待你按段回 `T-A S-A C-A I-A E-A`） |
| 6A probe 噪声 | `07aaa05a2` 根 `analysis_options.yaml` 排除子包 | 根裸 analyze 1943 → 0；子包独立 analyze 0；CI 只扫 lib test tool 不受影响 | 完成 |
| 批末全量 | `flutter test --no-pub`（`00ca60825`，冷 worktree） | `00ca60825` 冷 worktree 并发全量 **6971 PASS / 0 FAIL / 0 跳过**，`All tests passed!` exit 0，墙钟 23:06:57→23:15:37（8m40s）；format 1766 files 0 changed；analyze lib test 0 issue | **完成** |
| 2A 入链 | 推 `claude/dispatch-20260917` → `origin/codex/p2-player-flow-20260910`（快进，origin 链 `29ddf974a` 为祖先） | 推送结果见本报告末行「入链」 | 见末行 |

晚续代拍：① 4A 白名单形状——「命名奖励落在下一阶区间内」实测不成立（武器 490 跨阶间隙），改为包络断言（🟢 守卫口径，不动数值）；② 4A 首版 helper 触 `chinese_literal_audit`，改回 throw 内拼报文（🟢）；③ 全量首跑在 10 分钟后台上限前中止、改脱离会话重跑（🟢）。仍无 🔴 代拍：未改任何数值，`numbers.yaml` 只加注释。

`numbers_unused_keys_review.py --check` 在 3A/4A 后按设计抛「审计源相对派单基线变化」——冻结报告 `3f309166…` 保留为 `c64b16593` 时点证据，不改写；下次 B 类审计以 `--baseline <新链 tip>` 重锚。

## 本批指标

- 派单 1 / 完成 1 / gate 实质通过 1 / 合并 0 / 返修 0 / resume 0。Codex 单耗 190,593 tokens、墙钟 31m24s（21:49:31→22:20:55）。
- 协调者代码改动 0；写入仅 `docs/dispatch/`、PROGRESS 一行（协调者分支）。
- 锚表更新：codex gpt-6-astra 审计单（87 路径 × 4 层 + 脚本）≈ 31 min / 190k tokens。

## 末问

值得封装：① 收据自引用口径（收据绑定最后审计提交 + 单独封装提交）已第二次出现，应写进 `receipt.schema.md`「生成顺序」与派单包模板，免得执行端每次停 BLOCKED；② gate `--whitelist` 必须含派单包白名单全部精确文件（含收据/恢复点），可让 gate 直接读派单包 §0 生成白名单，减少调用侧笔误。

**已封装（2026-09-18，用户「继续推进」，NEXT #4）**：改在 `~/.claude/skills/afk/`（skill 层，不进本仓）：
- `scripts/receipt.schema.md`「生成顺序」新增第 6 步 + `head_sha` 字段释义：收据绑最后实质 commit S（带就绪标记），收据放独立包装 commit R（`R^ == S`，只含收据/恢复点，带就绪标记）；写完收据再改实质文件即产生新 S′ 必须重出收据。
- `SKILL.md` 派单包必含清单加 ⑨（收据自引用口径抄进派单包正文）并把 ⑦ 的白名单写法钉死为 §0 逐行反引号精确路径、禁 glob / 禁目录授权。
- `scripts/gate.sh` 新增 `--whitelist-from <派单包>`（解析 §0「可写范围（白名单」块：子项首反引号路径；绝对路径跳过并 INFO；glob / 目录 / 空列表 `FAIL: input` 直接中止；与 `--whitelist` 取并集）与 `--wrap-tip <R>`（`R^ == S` 否则 `FAIL: input`；新增检查项 `wrap_commit`：`S..R` 不得含 `lib/ test/ data/` 及禁区文件、须在白名单内、R 消息带 `[READY]/[BLOCKED]`；`--receipt` 省略时自动从 R 内取 `docs/dispatch/reports/*receipt*.yaml`）。
- 验证（B2 真实夹具，`--skip-full`）：正例 `gate.sh <wt> c64b16593 411e200f4 --whitelist-from <B2 派单包> --wrap-tip 964c5be02` → 解析 5 路径、跳过 1 仓库外路径、`scope_whitelist` PASS、`wrap_commit` PASS、收据自动取自 R；与原版脚本手抄 `--whitelist` + `--receipt` 的结果逐项一致（唯一 FAIL 同为 `receipt_crosscheck: analyze_last_line,format_last_line`——B2 收据两字段写的是 `"NOT_RUN"`，见下）。负例三条各按设计拒收：night_B 派单包行内 glob → `FAIL: input`；`--wrap-tip dd8293368`（父非 S）→ `FAIL: input`；S=`0200bff0e` R=`bc6cb8b8b`（R 夹带 lib/test/data）→ `wrap_commit` 列出全部 8 个实质文件 + 缺就绪标记。
- **顺带发现（未改，登记）**：B2 派单包写「不跑 `flutter`」而 `receipt.schema.md` 要求 analyze/format 真实末行，B2 收据从生成起就注定 crosscheck FAIL。审计单「禁 flutter」与收据 schema 需二选一：要么审计单允许跑 analyze/format（只读命令），要么 schema 给审计单开 `NOT_RUN` 口径并让 Gate 自跑替代对撞。**拍板（2026-09-18 用户「按推荐执行」，取 B 收窄版）**：仅当审计单 `changed_files` 不含 Flutter 相关文件（`lib/ test/ data/ assets/ integration_test/`、`.dart`、`pubspec.yaml|lock`、`analysis_options.yaml`）时，收据三条 last_line 可写 `"NOT_RUN"`（`error_block_count` 须 0），Gate 自跑 analyze/format/full test 裁定、不对撞执行端的行；范围碰到 Flutter 相关文件则 `NOT_RUN` 直接 FAIL 并标明原因。落地 `gate.sh` crosscheck + `receipt.schema.md` 字段约束 + `SKILL.md` ⑧ 补句（禁 flutter 的审计单白名单必须限于文档/脚本）。验证：B2 夹具整单 `PASS (full_test SKIPPED)`，crosscheck 输出 `doc-only audit: NOT_RUN accepted for analyze_last_line,format_last_line`；负例 `49cf33494..a27a7ed04`（只改 `data/numbers.yaml` 的审计范围）配 `NOT_RUN` 收据 → 三条均 `NOT_RUN rejected: range touches Flutter-relevant files`。

**入链（23:1x）**：`claude/dispatch-20260917` @ `5c05da57d` 快进推入 `origin/codex/p2-player-flow-20260910`（`29ddf974a..5c05da57d`，`ls-remote` 核实同 tip）；同 tip 备份到 `origin/claude/dispatch-20260917`。主 checkout 本地链仍在 `c64b16593`，需 `git pull --ff-only`。main 未动。
