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
