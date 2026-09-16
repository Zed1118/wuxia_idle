# 夜批 B 审计恢复点（2026-09-17）

## 范围与交付路径冲突

基线 `c307b3ffcb155af58d4efb9179e36453297b1360`，分支 `codex/night-b-governance-20260916`。仅新建本单 `docs/audit/*.md`、`tools/audit/*.py`；不改代码、登记簿及已有审计文件，不 push/merge/rebase/revert，不启动 GUI 或读取真实存档。

任务单 §0 白名单与 §6 指定的 `docs/superpowers/plans/2026-09-16-night-b-governance.md`、`docs/dispatch/reports/2026-09-16_night_B_receipt.yaml`、worktree 外 `summary.md` 冲突。已向用户请求确认这三个路径是否为例外，未得到答复前不写入。此文件在允许目录内保留恢复点；不冒充指定路径已交付。冲突来自当前任务单，不是额外审批规则。

## B-1 已完成

- 最后完成：重新解析登记簿 202 项，核对其中 167 项 `ready_reviewed`，167 已集成、0 已过时、0 待合、0 未能判定。此分类表示历史交付进入冻结链，不表示功能正式验收。
- 产物：`task_registry_ready_reviewed_triage_2026-09-17.md`、`tools/audit/task_registry_triage.py`。
- 验证：YAML 计数与 `rg -c '^    status: ready_reviewed$'` 均 167；表 167 行；脚本复跑计数相同。以 `random.Random(20260917).sample(rows, 10)` 独立重验下列十项 ancestry，10/10 成立。
- 样本：`P2-M6-ENGINEERING-INTEGRATION-GATE`、`P2-G2-D04-TOKEN-OBSERVE-SEAM`、`P2-M2-R15-MENTOR-INSIGHT-STAGE-OCCUPANCY-RUNTIME`、`P2-M2-R06-OBJECTIVE-RUNTIME-TRACKER`、`P2-M6-TOWER-PARTICIPANT-SETTLEMENT-REPORT`、`P2-M2-R03-OBJECTIVE-CONTROLLER`、`P2-M0-QODER-BASELINE`、`P2-G2-D05-SESSION-ENCOUNTER-SEAMS`、`P2-M2-R26-MIGRATED-ENCOUNTER-EXPLICIT-LEASE-ASSEMBLER`、`P2-M6-LIGHT-FOOT-PARTICIPANT-SETTLEMENT-REPORT`。
- 特别发现：`P2-M5-INNER-DEMON-PERSONAL-PROGRESS` 的两字段复用一个不可解析 SHA；报告引用真实链上 `fe2a287f29285ab9988b0c3387765fc6f04a5b3f`，未修改登记簿。
- 下一步：完成 B-2/B-3 的独立复核，追加 B-4 门文本附录。
- 阻塞：审计本体无；§6 交付路径例外待确认。

## 检查边界

本单不运行 Flutter/Dart analyze、format、full test，不安装依赖；只执行 Python 静态扫描、Git 只读审计和本分支提交。未执行的检查不得写 PASS。最终仍需协调者按任务单独立抽检。

## B-4 已完成

- B-1 收口提交：`0fbb5910f`；提交后 `date` 为 `2026-09-17 00:08:00 CST`，在时间围栏内继续。
- 最后完成：在 B-1 文档追加 M0–M9 共十门原文/证据/漂移/建议；M2 blocker 已更新，旧 evidence 仍漂移；M0/M3 接线 evidence 陈旧；M4 保留正式阻塞并补生产矩阵口径。
- 验证：主代理独立复跑 12 个 commit ancestry（12/12 exit 0）、105 条主线配置、chain/tolerance 6/12 行和 M4 34/32/17/17/0 统计，并记录外部 JSON 哈希。未触碰真实存档。
- 下一步：收 B-2/B-3、复核最终白名单与补丁散列。
- 阻塞：仅 §6 指定路径例外待确认。

## B-1 独立复核补证

- B-4 收口提交：`23107f786`；提交后 `date` 为 `2026-09-17 00:10:23 CST`。
- 独立审阅发现应补登记的后续修正，现已对 9 个任务追加 12 条 correction 证据：9 条祖先、3 条全补丁等价；7 项原全补丁等价另验独有 merge 数均 0。
- 10 个主题命中都指向实际交付/收口；59 项集成提交类另抽核源文件与计划，未见基础提交冒充整任务的反例。
- 重生成报告后计数保持 167 已集成、其余 0；原不可解析 SHA 未被静默修写。B-1 本体复核完成，下一步收 B-2/B-3。

## B-2 已完成

- B-1 补证提交：`5c90dd64c`；提交后 `date` 为 `2026-09-17 00:18:43 CST`。
- 最后完成：`numbers_yaml_unused_keys_2026-09-17.md` 与 `tools/audit/numbers_key_usage.py`。1796 标量叶子＝233 生产消费＋0 仅测试消费＋202 零引用＋1361 待人判；847 归一路径、497 末段名；零引用对应 87 路径/51 末段名。
- 已跑验证：代理两次完整 JSON 对象一致；主代理再次运行 JSON 并验证 Markdown 与同源生成结果逐字一致。只扫描 Git 跟踪源文件，固定 lib 基线保护通过；14 组动态消费排除证据在报告中。
- 主代理独立零引用抽样：用 `random.Random(20260917).sample(zero_rows, 8)` 抽取 tower.difficulty_curve[5].recommended_realm、equipment.tiers[2].tier_name、inheritance.unlock_rules.can_take_disciple_at、validation_examples.example_c.attacker.realm_diff_modifier、equipment.tiers[5].armor.speed_min、equipment.tiers[4].armor.speed_min、tower.difficulty_curve[0].recommended_realm、equipment.tiers[4].weapon.attack_min，逐条 `git grep -n -F -- <末段> lib` 均 0 行/exit 1。
- 主代理另验 opening_qi、equipment_attack_factor、constitution_factor 三条解析/消费双端，3/3 成立。Python 语法检查通过。未删除任何配置。
- 下一步：提交 B-3、最终白名单/补丁收据验证。
- 阻塞：审计本体无；§6 指定路径仍未获例外确认。

## B-3 已完成

- B-2 收口提交：`40ae26eac`；提交后 `date` 为 `2026-09-17 00:19:19 CST`。
- 最后完成：`orphan_doc_branches_triage_2026-09-17.md` 与 `tools/audit/orphan_doc_branches_triage.py`。21 条分支、逐分支独有提交合计 42（去重 40）；0 cherry-pick、20 归档后删、1 直接删建议。未做分支处置。
- 已跑验证：固定 SHA 两轮元数据 JSON 相同，主代理独立复跑分支/提交数；21 个章节无占位符，完整 tip、merge-base、提交与文件列表在文档中。
- 主代理以 `random.Random(20260917).sample(rows, 5)` 抽到编号 20、5、10、9、8：复核 E2 精确 shell blob 的 `bash -n` exit 0，capture/scenario 精确路径在链缺失；N4 自反断言仍在 test:219；durable policy 存在轻功/守城；gatherPull 存在坐标生产接线；黑风岭令牌现值四项各 1、合计 4。5/5 静态证据成立。
- 额外核对唯一“直接删”候选 `f16c09efc` 完整 diff，仅 import 顺序改变。E2 目录另有无关 `decision_session.sh`，不存在的是本批 capture 工具与场景，不是整个 tools/playtest 目录。
- 下一步：检查最终仅八个新增白名单文件、生成 stdout 收据并冻结。
- 阻塞：§6 指定路径例外仍未确认；未运行 Flutter/Dart 三项门禁，不能声明协调者 Gate PASS。
