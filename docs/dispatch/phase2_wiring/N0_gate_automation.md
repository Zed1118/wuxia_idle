# 批 N0:复核自动化(gate.sh + receipt + runner)(2026-08-26)

**工作目录**:`/Users/a10506/.claude/skills/afk/scripts/`(**不是项目仓库**)。
产物落在该目录,**禁止把任何文件写进 `/Users/a10506/Desktop/Projects/挂机武侠` 及其任何 worktree**。

规格来源:`/Users/a10506/.claude/skills/afk/SKILL.md` §5「复核自动化」(现读,不要凭印象)。

## 背景

协调者复核目前全靠人工复跑,成本正比于任务数,是整条夜批流水线的瓶颈。
本单把「禁采信执行端自报」从**人工复跑**升级为**脚本对撞**:自报不再是协调者要读的东西,
而是脚本要验的对象。

## 交付物

### N0-1 `receipt.schema.md`
定义执行端收工时产出的 `receipt.yaml` 固定格式,字段至少含:
`base_sha` / `head_sha` / `changed_files[]` / `full_test_last_line`(reporter 末行**原文**) /
`error_block_count`(`grep -c '^\[E\]'` 的值) / `analyze_last_line` / `format_last_line` /
`break_red`(双向,各含 `direction` / `mutation` / `failed_count` / `conclusion`)。

### N0-2 `gate.sh <worktree> <base_sha> <head_sha> [--whitelist f1,f2,...]`
输出**单行** `PASS` 或 `FAIL: <失败项1>[,<失败项2>...]`,详情写 stderr。退出码 0=PASS,1=FAIL。
检查项(逐项独立实测,**不读 receipt 就能得出结论**):

| 项 | 判据 |
|---|---|
| forbidden_files | `git diff --name-only base..head` 命中 `data/numbers.yaml`/`GDD.md`/`PROGRESS.md`/`lib/shared/strings.dart`/`pubspec.yaml` → FAIL |
| scope_whitelist | 给了 `--whitelist` 时,改动文件集 ⊄ 白名单 → FAIL(未给则跳过并在 stderr 标注) |
| test_deletions | `git diff base..head -- test/` 出现 `^-[^-]` 行 → FAIL |
| commit_msg | 范围内任一 commit message 不含中文字符,或首个 commit 无 `[READY]`/`[BLOCKED]` tip → FAIL |
| worktree_clean | `git status --porcelain` 非空 → FAIL |
| full_test | 在 worktree 跑 `flutter test --no-pub`;`grep -c '^\[E\]'` ≠ 0 或末行非 `All tests passed!` → FAIL |
| analyze | `flutter analyze --no-pub lib test` 非 `No issues found!` → FAIL |
| format | `dart format --output=none --set-exit-if-changed .` 报 changed → FAIL |
| receipt_crosscheck | 有 `receipt.yaml` 时,其 `full_test_last_line`/`error_block_count`/`analyze_last_line`/`format_last_line`/`changed_files` **与脚本实测不一致** → FAIL(无 receipt 则跳过并标注) |

**性能要求**:全量约 5–6 分钟(锚表见 SKILL.md §5),`gate.sh` 必须支持 `--skip-full` 跳过全量用于快速预检,
但**默认必须跑全量**,`--skip-full` 时输出里要显式标 `(full_test SKIPPED)`。

### N0-3 `runner.sh <queue_file>`
`queue_file` 每行一条:`<派单包绝对路径>\t<worktree 绝对路径>\t<base_sha>`。
逐条:`codex exec --cd <worktree> --sandbox danger-full-access "$(cat <派单包>)" < /dev/null` →
跑 `gate.sh` → PASS 取下一条 / FAIL **立即停止整个队列**并把失败项写进 `runner.status`。
发单命令模板**必须从 `~/.claude/automation-playbook/executors.json` 的 `dispatch_template` 字段读取**,
**禁止把命令硬编码进 runner.sh**(SKILL.md §1:注册表是唯一事实源)。
每条的日志落 `$CLAUDE_JOB_DIR/tmp/` 下,文件名含派单包 basename。全程 `caffeinate -i` 包裹。

## 固定样例验收(不过不许上线,这是本单的核心判据)

`gate.sh` 必须在下面两个**真实 commit** 上给出正确判定,把两次运行的完整输出贴进收工报告:

| 样例 | worktree | base..head | 期望 |
|---|---|---|---|
| 已知红 | `/Users/a10506/Desktop/Projects/挂机武侠-p2-posture` | `b98b363c..2c8015d9` | **FAIL**(该 commit 全量为 `5612 +/ 4 -`) |
| 已知绿 | 同上 | `aa9d8105..1db64d0d` | **PASS** |

注意:已知红那次,**工作树当前 HEAD 不在 `2c8015d9`**。你需要让 gate.sh 支持在**不破坏该 worktree 当前状态**
的前提下对历史 commit 求值(建议:另建临时 worktree 求值后删除,或用 `git worktree add --detach`)。
**严禁 `git checkout` 改变 `挂机武侠-p2-posture` 的 HEAD** —— 那上面有未合并的交付物。
若你判断无法在不动该 worktree 的前提下完成,`[BLOCKED]` 报上来,**不要硬做**。

## 硬约束

- **禁止写入项目仓库及任何 worktree**(唯一例外:为求值而临时创建、用完即删的 detached worktree)。
- 禁 push / 禁 merge / 禁碰任何分支 / 禁 revert。
- 不改 `SKILL.md`、不改 `executors.json`(只读它)。
- 脚本用 bash;不引入需要额外安装的依赖(不许 `pip install`);`yq`/`jq` 若不可用须自带回退解析。
- 数字实测禁估算;引用文件现读带 `file:line`。

## [BLOCKED] 出口条件

- 无法在不改动 `挂机武侠-p2-posture` HEAD 的前提下对历史 commit 求值;
- 两个固定样例中任一判定与期望不符,且你找不到脚本侧原因(可能是我给的期望错了 —— 停下报告,别改期望迁就脚本);
- `executors.json` 的 `dispatch_template` 字段结构与 SKILL.md 描述对不上。

## 协调者怎么验收

我会自己拿这两个固定样例复跑 `gate.sh`,输出对不上即打回。
脚本里出现硬编码的发单命令 = 直接打回。往项目仓库写文件 = 直接打回。
`gate.sh` 在「receipt 与实测不一致」时不 FAIL = 直接打回(那是本单存在的理由)。
