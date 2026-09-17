# 夜批 B 治理与配置审计恢复点

基线：`c307b3ffcb155af58d4efb9179e36453297b1360`。分支：`codex/night-b-governance-20260916`。

## 当前恢复点

- 状态：B-1～B-4 审计本体完成，协调者已确认三个交付路径为白名单例外；此前授权冲突已解除。本次补交遇到沙箱文件权限阻塞，尚未形成最终 `[READY]` 提交，工作区非干净。
- 最后完成：逐项登记簿分类、配置引用清点、21 条孤立文档分支评估及十个 M 门文本漂移核对；相关脚本与报告均已独立复跑和抽查。
- 收据约定：采用提交收据之前的最后一个 commit 为 `head_sha`；`changed_files` 与 `patch_sha256` 仅覆盖 `base_sha..head_sha`。最后新增收据提交不改写历史，并使用 `[READY]` 前缀。
- 三项 Flutter/Dart 检查：未运行；按协调者本次明确要求，收据字段均填 `NOT_RUN`，不宣称 analyze、format、full test 或协调者 Gate 已通过。
- 收口顺序：本恢复点和生成器补正先提交为 H；在 H 干净时先于内存生成收据，再写入指定路径；最后仅新增收据提交 F，保持 F 的父提交等于 H，F 前缀为 `[READY]`。仓库外摘要记录 F 和实际检查结果。
- 下一步：先恢复共享 Git 元数据与仓外摘要目录的可写权限，按上述 H/F 顺序提交并重新生成收据；完成后交协调者独立验收。无需重做审计或实施处置建议。
- 剩余审计阻塞：审计本体无；交付存在下述实际权限阻塞。主线、真人体验及 Windows 正式验收仍独立。

## 续令补交实况（2026-09-17 00:25 后）

- 已写本计划、收据，并更新生成器的两个仓内路径例外、`--head` 复现参数与三个 `NOT_RUN` 字段；审计恢复点已标记原授权冲突解除。
- 当前 receipt.head_sha 为仍在 HEAD 的 `c04ca7dbb25384dc4a638323a9acabad20b33c16`，changed_files 精确覆盖该提交相对派单基线的 8 项，patch_sha256 为 `0dc4a26f1c4acdf83c182955ebc9b16bef8ba28e3aa23df5dae7cd6e034f7035`。收据真实覆盖旧审计提交，尚未覆盖本轮未提交补交文件；恢复提交能力后须按 H 重新生成。
- `git add` 首次成功暂存三项；后续更新暂存及 commit 创建 `/Users/a10506/Desktop/Projects/挂机武侠/.git/worktrees/wt2/index.lock` 均报 `Operation not permitted`。未改写历史，HEAD 仍为原 `[BLOCKED]`。
- 写 `/Users/a10506/Documents/Codex/2026-09-16/night-B/summary.md` 报 `PermissionError: [Errno 1] Operation not permitted`，该外部摘要未生成。本轮沙箱只开放 worktree，没有共享 `.git` 与 night-B 父目录写权限，用户业务授权已经确认，不能将此再描述为等待白名单批准。
- 当前本地材料保留待提交，不清除暂存或未提交工作。需要开放的路径为 `/Users/a10506/Desktop/Projects/挂机武侠/.git` 与 `/Users/a10506/Documents/Codex/2026-09-16/night-B`（后者仅用于已获授权的 summary.md）。

## 结果与已跑验证

| 目标 | 结果 | 已执行验证 |
|---|---|---|
| B-1 | 202 登记任务中 167 个 ready_reviewed；167 已集成、其他三类均 0 | 两条统计命令与 167 表行一致；10/10 随机 ancestry；补验 9 任务的 12 条修正证据；7 个补丁等价分支无独有 merge 遗漏 |
| B-2 | 1796 标量叶子；233 生产消费、0 仅测试消费、202 零引用、1361 待人判 | 完整 JSON 重跑一致；报告同源生成逐字相同；零引用 8/8、生产双端 3/3；14 组动态读取排除证据；固定 lib 基线与 Git 跟踪文件范围 |
| B-3 | 21 分支；逐分支独有提交合计 42、去重 40；建议归档 20、直接删 1、原样 cherry-pick 0 | 固定 SHA 元数据重复一致；主代理抽 5 条静态证据 5/5；工具仅语法/help/map/list/dry-run，没有 mutation 或 GUI |
| B-4 | 十门原文与实况对照已追加 B-1 | 12 个 ancestry 全为 0；重算 105 主线配置、chain/tolerance 6/12 行、M4 34/32/17/17/0；外部 JSON 哈希已记录 |

详细历史恢复点：`docs/audit/night_b_governance_recovery_2026-09-17.md`。

## 授权与验收边界

原白名单为本单新建的 `docs/audit/*.md` 与 `tools/audit/*.py`。协调者 2026-09-17 续令明确追加本计划、`docs/dispatch/reports/2026-09-16_night_B_receipt.yaml` 和 `/Users/a10506/Documents/Codex/2026-09-16/night-B/summary.md`。保留原审计文件、登记簿、lib/test/data，不 push、不改 main，不启动 GUI、不访问真实存档。

收据生成器运行时实测 `git diff --check` 及 schema 固定 patch SHA-256 管道；最终提交后可用 `python3 tools/audit/night_b_receipt.py --head <receipt.head_sha>` 复现收据。`error_block_count: 0` 是未运行 full test 时的固定数值占位，不构成零失败测试证据。
