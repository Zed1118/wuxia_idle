# Nightshift · 挂机武侠 6 小时无人值守

## 启动

```bash
caffeinate -dimsu nohup bash /Users/a10506/Desktop/挂机武侠/.nightshift/dispatcher.sh > /dev/null 2>&1 &
```

`caffeinate -dimsu` 防止 macOS sleep + display dim,`nohup` + `&` 让进程脱离 shell。**关闭 Terminal 不会 kill dispatcher**。

## Dry-run(可选,推荐睡前跑一次)

```bash
bash /Users/a10506/Desktop/挂机武侠/.nightshift/dispatcher.sh --dry-run
```

只打印「会调度哪些 task / 用哪些 prompt / worktree 路径」,不真启 claude。耗时 < 5s。
看到「DRY RUN: would claude --print ...」就说明 dispatcher 健康。

## 中途取消

```bash
pkill -f "nightshift/dispatcher.sh"
# 或者根据 ps 找 PID:
ps aux | grep dispatcher.sh
kill <PID>
```

## 早上检查

```bash
# 主报告(T06 产出)
cat /Users/a10506/Desktop/挂机武侠/.nightshift/SUMMARY.md

# 各 task 状态
ls /Users/a10506/Desktop/挂机武侠/.nightshift/status/
cat /Users/a10506/Desktop/挂机武侠/.nightshift/status/T01.status

# 各 task 详细日志
ls /Users/a10506/Desktop/挂机武侠/.nightshift/logs/
less /Users/a10506/Desktop/挂机武侠/.nightshift/logs/T01.log

# 所有 nightshift commits
git log --all --oneline | grep nightshift

# 各 nightshift 分支
git branch -a | grep nightshift
```

## 合并产出到 main(早上 review 通过后)

每个 task 在自己分支(`nightshift/T0X`)有 1 commit(若 task 成功)。手动合并:

```bash
cd /Users/a10506/Desktop/挂机武侠
git checkout main

# 单 task 合并(快进或 squash)
git merge nightshift/T01 --no-ff -m "merge(nightshift T01): #37 永封档"

# 或批量 cherry-pick
git cherry-pick nightshift/T01 nightshift/T02 nightshift/T03 nightshift/T05  # doc 类
git cherry-pick nightshift/T04                                                 # test 类
# T06 SUMMARY 通常不合 main(.nightshift/ 是临时目录)
```

## 清理 worktree

完成后(或决定放弃)清理:

```bash
git worktree remove ../wuxia-idle-T01
# ... 重复其余 5 个
# 或一波删:
for t in T01 T02 T03 T04 T05 T06; do
  git worktree remove "../wuxia-idle-$t" 2>/dev/null
done

# 删 nightshift 分支(可选,留着也行)
for t in T01 T02 T03 T04 T05 T06; do
  git branch -D "nightshift/$t" 2>/dev/null
done
```

## 风险与已知偏差

1. **Claude --print 网络依赖**:Anthropic API 调用,代理 hook 不在 claude 命令清单。如果半夜代理断 → 所有 task 全 SKIPPED。
2. **flutter pub get 网络依赖**:verify 时跑 pub get 拉缓存外依赖。pub cache 已预热则 30s 内,否则 fail。
3. **Mac sleep**:`caffeinate -dimsu` 兜底防 sleep,但若 macOS 强制更新 / 蓝牙断连等可能仍中断。
4. **API budget**:每 task `--max-budget-usd 8`(opus 短 task < $2 实测),8 task 共预算 $64。实际不会用完。
5. **worktree 内首次 build_runner 缺失**:.g.dart gitignored 不在 worktree。verify 模板已含 fail-fast build_runner(memory `feedback_nightshift_build_runner_silent_fail`)。

## ⚠️ verify.sh 必须套 VERIFY_TEMPLATE.sh(2026-05-20 起)

`.nightshift/VERIFY_TEMPLATE.sh` 是 verify.sh 的 helper 函数库,**修补 4 个 nightshift 历史 bug**:
1. count 写死期望(memory `feedback_nightshift_verify_count_baseline`)→ `verify_count_delta` baseline+delta 算式
2. `git show --name-only` 中文 commit msg body 误抓(memory `feedback_nightshift_verify_changedoutside_bug`)→ `verify_changed_files_only` 用 `git diff-tree`
3. build_runner 静默失败(memory `feedback_nightshift_build_runner_silent_fail`)→ `verify_build_runner_strict` fail-fast + tee log
4. `--fatal-errors` 非法 flag(memory `feedback_flutter_analyze_fatal_errors_invalid`)→ `verify_analyze_clean` 用 `--fatal-warnings`

**新 verify.sh 体例**(每个 T0X.verify.sh 顶部):
```bash
#!/bin/bash
source "$(dirname "$0")/../VERIFY_TEMPLATE.sh"
verify_init "T01"
verify_file_exists "data/synergies.yaml"
verify_count_delta "data/synergies.yaml" "^  - id: synergy_" 3 "synergies"
verify_blacklist_words "data/synergies.yaml"
verify_build_runner_strict
verify_analyze_clean
verify_local_tests "test/balance/synergy_hot_loop_upgrade_test.dart"
verify_commit_message "nightshift T01"
verify_changed_files_only "data/synergies\.yaml|test/balance/synergy_hot_loop_upgrade_test\.dart"
verify_done
```

## 容错保证

- 全 task `skippable: true`,1 个失败不阻塞下一个
- 每个 task 内 claude 也有 max-budget 兜底
- dispatcher 用 perl alarm 强制 50min/task timeout
- 所有 task 产出在独立 worktree + 独立分支,**main 不会被任何 task 污染**
- T01-T05 都不动 lib/ 主代码(T04 只 +新 test 文件)

## 文件结构

```
.nightshift/
├── README.md               (本文件)
├── TASKS.md                (任务清单,模板格式)
├── dispatcher.sh           (主调度脚本)
├── SUMMARY.md              (T06 早上自动产出)
├── prompts/
│   ├── T0X.md              (各 task 自完备 prompt)
│   └── T0X.verify.sh       (各 task verify 脚本)
├── logs/
│   ├── dispatcher.log      (调度器主日志)
│   └── T0X.log             (各 task claude + verify 完整输出)
└── status/
    └── T0X.status          (各 task 终态:completed/skipped/started/finished/exit codes)
```
