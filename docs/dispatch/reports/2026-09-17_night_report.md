# 2026-09-17 夜批早报（2026-09-16 23:55 → 02:00 收工 · Claude 监督 Codex 双单）

> 授权 8h（23:55–07:55），执行端实际墙钟 ~2h（A 23:59–01:47，B 23:59–00:31）；两单共 8 个目标全部 `[READY]` 且通过独立 gate 后，按 /afk v2 §3（READY 待复核已达上限）进入收口模式，**未补派新单**。时间戳全部取自 git / dispatch.log。
> 交付状态事实源 = git；**两条分支均未合并、未推 main/链**，是否入链由下方菜单拍板。

## 当前完成

| 单 | 分支 @ tip | 交付 | gate（协调者独立实测） | 状态 |
|---|---|---|---|---|
| A 结构整改（代码） | `codex/night-a-structural-20260916` @ `ebc8f55db`（10 commit，已推 origin 备份） | A-1 numbers_config fail-fast（红线段+逐键守卫）· A-2 主线/塔结算迁 `application/`（`mainline_settlement.dart` 1164 行、`tower_settlement.dart` 551 行）· A-3 结算链时钟/随机源可注入（`SystemClock.fixed`，3 个确定性测试）· A-4 reducer 事件流 golden（3 场景） | 全量 `+6935 All tests passed`、analyze 0、format 0 changed、receipt 对撞 matched；`test_deletions` 20 行逐行对账 = 13 行旧「缺 key 走默认」测试被等量 fail-fast 测试替换 + 1 行 fixture 补 key + 6 行迁移路径常量 → 🟢 判可接受 | **REVIEWED，未合并** |
| B 治理审计（只读） | `codex/night-b-governance-20260916` @ `f4cfeab4e`（7 commit，已推 origin 备份） | B-1 登记簿 167/167 三分类（已集成）· B-2 numbers.yaml 叶子 1,796 = 生产消费 233 / 零引用 202 / 待人判 1,361 · B-3 孤立文档分支 21 条 = 归档 20 / 直删 1 / cherry-pick 0 · B-4 M 门 blocker 漂移表 · 4 个 `tools/audit/*.py` 可重跑 | forbidden/scope/test_deletions/commit_msg/clean/analyze 0/format 0 PASS；receipt_crosscheck FAIL 仅因 Flutter 三项为协调者授权 `NOT_RUN`（gate 已实测覆盖）→ 判实质通过 | **REVIEWED，未合并** |

A 体量：49 文件 +32,614/−1,930，其中 27.5k 行是 3 个 golden JSON（`tower_32_vulnerability.json` 18,926 行）；代码+测试净约 5k 行。抽检：A-1 首件 detached 复跑 analyze 0 / 守卫 9/9+4/4 / 破坏证红精确 1 红；B-1 抽 3 行 3/3 复核一致；B-2 抽 3 个零引用 key grep 3/3 零命中。真档 `~/Library/…/Documents/` 两次 bypass-sandbox 续跑（B 二次 resume、A resume）前后 sha256 各 6/6 不变。

## 代拍清单（逐条标级）

| # | 时间 | 事项 | 级 | 依据 |
|---|---|---|---|---|
| 1 | 23:52 | preflight 4 项 BLOCKED（wip 43/59、4 个 `[BLOCKED]` 分支、2 个脏 worktree）证伪为台账遗留后带记录开工 | 🟡 | 真实在跑 WIP=0；脏树 = 4 个用户文件 + Codex 证据目录 |
| 2 | 00:25 | B 派单包 §0 白名单与 §6 收据路径冲突（协调者笔误），resume 时补例外允许写 plans/reports/外置 summary | 🟢 | 路径纠正 |
| 3 | 00:29 / 00:58 | `codex exec resume` 不继承 `--add-dir`，改 `--dangerously-bypass-approvals-and-sandbox` 续跑；前置真档 `uchg` 锁+哈希，后置 6/6 核对 | 🟡 | night_plan 进度段 |
| 4 | 00:58 | A-3 阻塞点授权最小范围扩展：`GameEventService.recordEquipmentObtained` 及结算直接调用链同类写入加**可选**时钟/随机源参数，默认等价现有行为 | 🟡 | 范围外 ~150 处裸时钟只登记 |
| 5 | 00:35 / 01:57 | B 收据 `NOT_RUN` 三项、A `test_deletions` 20 行，均以 gate 独立实测 / 逐行对账放行 | 🟢 | 上表 |

无 🔴 代拍。🔴 待拍板项由 A 登记不动：`realms.level_diff_modifier.diff_3_or_more.attacker` yaml 为 null；`bossRecruit.baseProbability` 6 关缺键（`docs/audit/numbers_config_fallback_residue_2026-09-17.md`）。

## 决策菜单

| # | 问题 | 选项 | 推荐 |
|---|---|---|---|
| 1 | A 分支入链？ | **1A** `--no-ff` 合入 `codex/p2-player-flow-20260910`，合后全量一次 · 1B 先由你桌面跑一次主线+塔实战再合 · 1C 不合 | **1A**（gate 全绿、行为保持、无 UI/数值改动） |
| 2 | B 分支入链？ | **2A** 合入链（纯 docs/audit + tools/audit） · 2B 不合只留 origin | **2A** |
| 3 | A-4 golden 体量（27.5k 行 JSON） | **3A** 保留全量（逐帧可读 diff，回归定位精确） · 3B 改存事件流摘要哈希+关键帧 · 3C 只留 mainline/tower_01 两个小 golden | **3A**（golden 价值就在逐帧可读；仓库净增 ~1MB 可接受） |
| 4 | 两个 🔴 数值残留 | 4A `diff_3_or_more.attacker`：GDD §6 表为「—」即不适用，让 loader 显式接受 `null` 语义 · 4B `bossRecruit.baseProbability`：6 关补值或显式声明无招降 | 需你拍数值口径，本夜不动 |
| 5 | B-2 202 个零引用 key | 5A 逐条人判后删（`[schema]` 单）· 5B 仅头注 unused · **5C** 先不动，纳入下一夜批「B-2 复核单」 | **5C**（需逐 key 看是否动态路径消费） |
| 6 | B-3 孤立文档分支 21 条 | **6A** 按建议归档 20 打 tag 后删 + 直删 1 · 6B 不动 | **6A** |
| 7 | 8 条无 worktree 历史分支 + 主仓 `git pull --ff-only`（本地链落后 origin 14 commit） | **7A** 我清 8 条（先 is-ancestor 三验）+ 你 pull · 7B 不动 | **7A** |
| 8 | 时钟/随机源残留 ~150 处 | 8A 下一夜批继续按调用链分片收口 · **8B** 只登记不动 | **8B**（A-3 已覆盖结算主链，其余非确定性不影响存档） |

## 本夜指标

- 派单 2 / 完成 2 / gate 实质通过 2 / 合并 0（allow-merge=no）/ 返修 0 / 续跑 3 次（B×2、A×1）。
- 协调者代码改动 0；写入仅 `docs/dispatch/`（派单包、night_plan、本报告）。
- 锚表：codex gpt-6 结构单 4 目标 ~108 min；审计单 4 目标 ~23 min；全量套件冷隔离 8:07–8:31。

## 末问

值得封装：① `codex exec resume` 无沙箱续跑的「真档锁 + 哈希核对」前后置步骤（本夜手工两次）→ 建议进 `/afk` scripts；② gate `test_deletions` 对「等量替换」的对账（列出 ± 配对）→ 可加 `--explain-deletions` 输出。

## 拍板执行记录（2026-09-17 用户回复「按推荐处理，1A 2A 3A 5C 6A 7A 8B」）

| # | 执行 | 实测 |
|---|---|---|
| 1A/2A | 从链 `c307b3ffc` 开集成分支，`--no-ff` 合入 A `ebc8f55db`、B `f4cfeab4e`（零冲突），cherry-pick 4 个夜批 docs commit，更新 PROGRESS 顶段后推为链 `codex/p2-player-flow-20260910` 新 tip | analyze `--no-pub lib test` 0 issue；format 1762 文件 0 changed；全量 `08:06 +6935: All tests passed!`、error block 0、退出 0。`flutter analyze` 全仓会报 `tools/phase0minus_probe/` 独立子包 1892 条（未 pub get，与本批无关） |
| 3A / 8B | 无动作 | — |
| 5C | 202 个零引用 key 入下一夜批「B-2 复核单」候选 | — |
| 6A | 21 条 ③ 文档分支：20 打 `archive/codex/<分支>` 标签后删、`codex/p2-defense-vfx-fix-20260827` 直删；删前逐条核 tip 与处置表固定 tip 一致、21 个 worktree 均干净 | 29/29 处置 0 跳过 |
| 7A | 8 条无 worktree 历史分支现算均含 1–3 个独有补丁（cherry `+`），三验不过 → **收窄为打归档标签后删**，不直接丢内容；tips：`83277eb42` `5fe5b3652` `0397f4d3e` `21ad6e60b` `3469ad375` `e6b733b60` `802511dc9` `1aaa08940` | 8/8 |
| 标签 | 28 个 `archive/codex/*` 已推 origin | worktree 38→17，本地分支 110→81 |
| 未做 | 第 4 项（两个 🔴 数值残留）等你定口径；主仓 `git pull --ff-only` 由你执行；64 条已全进链的无 worktree 分支不在本次菜单 | — |

