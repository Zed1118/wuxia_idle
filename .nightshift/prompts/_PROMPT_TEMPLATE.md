# Nightshift T?? · <一句话任务描述>

> 体例参考 wuxia_idle/.nightshift/prompts/T01.md(深度耦合体例)
> 通用版仅给最小骨架,真实 task 按项目特化扩。

你是 Claude(model 见 nightshift.conf),被 nightshift dispatcher 调起,在 git worktree `<WORKTREE_BASE>/<PREFIX>-T??`(branch `nightshift/T??`,从 `<MAIN>` HEAD 起)内独立完成本任务。

---

## 背景

<2-3 句话:为什么做、上下文、相关 GDD/PRD 章节锚点>

## 目标

<具体可验证的产出。引用文件路径、id、行号尽量精确>

- 产出 1: ...
- 产出 2: ...

## 允许修改(diff guard opt-in,verify_path_guard 用)

> 体例:bash extended regex,匹配 git diff-tree 输出文件路径
> 列了本段就启 path guard 白名单;不列就只走全局禁区

- `data/.*\.yaml`
- `test/.*\.dart`

## 禁止修改

- `pubspec\.yaml`     # 不准动依赖
- `\.env.*`           # 全局禁区已盖,这里冗余强调
- `lib/main\.dart`    # 入口稳定

## Phase 0 · reality check(必跑,3-5 min)

```bash
cd <worktree>
git log -1 --oneline                  # 确认 base
ls <相关文件 / 目录>
grep -c "<相关 pattern>" <file>       # baseline 实测,后面 verify_count_delta 用
```

## 操作

### Step 1: ...
### Step 2: ...
### Step 3: ...

## 完成后

请 git commit,commit message 必须含 `nightshift T??` 子串(verify_commit_message 检查)。

## 不要做

- **🚨 严禁 cd / git -C 到 dispatcher 创建的 worktree 之外的任何路径**(v2 红线,memory feedback_nightshift_v2_first_run_lessons A1)
  - 即使 prompt 引述了别的 worktree(如 `wuxia_idle-p12-spec`)只能作为参考阅读
  - 所有 git/edit/cd 必须在当前 cwd(即 dispatcher 的 `--add-dir <worktree>`)内
  - 需要切分支用 `git checkout <branch>` 不用 `git -C <other-path>`
- 不要顺手重构无关代码(memory feedback_layered_bugs)
- 不要为让 verify 过而删 test / 降断言
- 不要改 .env/密钥/.mcp.json/.claude.json
- 不要 git push / git reset --hard / git rebase
- 遇到歧义在 worktree 根建 `QUESTION-T??.md` 写阻塞点,然后停

## 参考

- 类似实现: ...
- memory 锚点: ...
