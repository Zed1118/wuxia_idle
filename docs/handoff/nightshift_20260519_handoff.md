# Nightshift 2026-05-19 启动 handoff(睡前 5 分钟看)

> 10 worktree × 串行 dispatcher,sonnet --print,预计 4-6h 实跑,8h 窗充裕。
> infra 已 ready(.nightshift/ 100% 复用 W17 nightshift 修过的 dispatcher.sh + launch.sh),dry-run 10/10 PASS。

## 启动(一行命令)

```bash
bash /Users/a10506/Desktop/挂机武侠/.nightshift/launch.sh
```

`launch.sh` 内含 `nohup + caffeinate -dimsu + disown`,关闭 Terminal 不影响,Mac 也不会 sleep。终端会输出 PID + log 路径 + cancel 命令,**记下 PID** 后可直接关 Terminal 睡觉。

## 任务 10 个一览

| Task | 主题 | 类型 | 输出 | 估时 |
|---|---|---|---|---|
| T01 | PROGRESS.md 96 → <80 行清理 | doc | PROGRESS.md | 15-20min |
| T02 | #43 高阶占位 audit | audit | docs/handoff/p1_43_..._2026-05-19.md | 25-35min |
| T03 | #37 6 orphan 决议(钉死不动 yaml) | audit | docs/handoff/p1_37_..._2026-05-19.md | 30-40min |
| T04 | CodexEntryDetail widget test 37→80+ | test | test/features/codex/.../codex_entry_detail_test.dart | 30-40min |
| T05 | CodexTab widget test 115→160+(viewport) | test | test/features/codex/.../codex_tab_test.dart | 35-45min |
| T06 | TutorialBannerCard widget test +5 | test | test/features/tutorial/.../tutorial_banner_card_test.dart | 25-35min |
| T07 | typedef/extension 死字段周期审计 | audit | docs/handoff/typedef_extension_audit_2026-05-19.md | 30-40min |
| T08 | 死代码 dry-run scan(钉死只列不删) | audit | docs/handoff/deadcode_scan_2026-05-19.md | 25-35min |
| T09 | lib/ 目录结构审计 | audit | docs/handoff/lib_structure_audit_2026-05-19.md | 20-30min |
| T10 | SUMMARY 生成(收尾) | summary | .nightshift/SUMMARY.md | 10-20min |

**总估时**:4.3-6.0h 串行,**8h 窗有 2-3.7h buffer**。

## 风险与缓解

| 风险 | 缓解 |
|---|---|
| Claude --print 网络断 | API 调用走原始网络,半夜代理断 → 全 SKIPPED;dispatcher 不阻塞,凌晨网络恢复重 launch 可幂等续跑 |
| Mac 强制更新 / 蓝牙断 | caffeinate -dimsu 兜底 |
| API budget 超 | 每 task --max-budget-usd 5,10 task 总 $50 上限,sonnet 实测 < $2/task |
| .g.dart 缺失 | verify.sh 全部含 `dart run build_runner build --delete-conflicting-outputs` 兜底 |
| analyze 误报阻塞 | verify.sh 用 `--fatal-errors` 不 `--fatal-infos`(memory `feedback_nightshift_verify_lint_severity` 教训) |
| Isar testWidgets 死锁 | T06 spec 明文禁止 writeTxn 端到端 case(memory `feedback_isar_widget_test_deadlock`) |
| ListView lazy build 漏 | T05 spec 强制 `setSurfaceSize(800, 3000) + addTearDown`(memory `feedback_listview_widget_test_viewport`) |
| 任务间文件冲突 | TASKS.md 冲突排雷表已验,**0 file overlap**,cherry-pick 全干净 |
| audit task 误改 yaml/lib | T03/T08 verify.sh 钉死改动越界 → exit 1 |

## ⚠️ 紧急 addendum(2026-05-19 01:21 实跑发现)

**发现 2 个 bug,夜班继续跑但**:

1. **T01 真失败(API max output token 32K cap)**:PROGRESS.md 整文件重写超 sonnet output cap,**status=skipped,产出 0**。早上需主对话 opus 5min 单独跑 PROGRESS 清理。
2. **T02-T10 verify "改动越界" 检测有 grep bug**(`git show --name-only HEAD` 含 commit msg body 中文行被误抓),**会导致 status 全 skipped 但 commit 实际生成**:
   - T02 `a3ec749 docs(nightshift T02): #43 高阶占位 audit` 实际 ✓ 50 行 md
   - T03 `8ca6d3d docs(nightshift T03): #37 6 orphan event 决议归档` 实际 ✓ 47 行 md

**早上 review 核心动作改**:**不依赖 `status=completed`,直接 git log --all --oneline | grep nightshift 看 commit + cherry-pick 各分支 HEAD**(即使 status=skipped,commit 实际生成 + 文件实际可用)。

**T04-T10 预测**:test 加固 + audit task 同 bug 多半会 skipped 但 commit 仍生成,cherry-pick 仍可救。T10 SUMMARY 自动产出会显得"全失败",**忽略 SUMMARY 直接看 git log**。

**memory 沉淀**:`feedback_nightshift_max_output_token` + `feedback_nightshift_verify_changedoutside_bug`,下次夜班 dispatcher.sh + verify.sh 模板必修。

---

## 早上检查 3 phase 清单

### Phase A · 阅 SUMMARY + 状态(5min)

```bash
cat /Users/a10506/Desktop/挂机武侠/.nightshift/SUMMARY.md       # T10 自动产
ls /Users/a10506/Desktop/挂机武侠/.nightshift/status/            # 10 task 终态
tail -100 /Users/a10506/Desktop/挂机武侠/.nightshift/logs/dispatcher.log
git log --all --oneline | grep nightshift                       # 10 task commits
```

### Phase B · 各 task review(各 1-2min)

```bash
for t in T01 T02 T03 T04 T05 T06 T07 T08 T09; do
  echo "=== $t ==="
  cd "/Users/a10506/Desktop/wuxia-idle-$t" 2>/dev/null && git diff main..HEAD --stat
done
```

### Phase C · cherry-pick 合 main(各 10-30s)

```bash
cd /Users/a10506/Desktop/挂机武侠
git checkout main

# Audit/Doc 类(6 个):T01 + T02/T03 + T07/T08/T09
git cherry-pick nightshift/T01 nightshift/T02 nightshift/T03 nightshift/T07 nightshift/T08 nightshift/T09

# Test 类(3 个):T04/T05/T06
git cherry-pick nightshift/T04 nightshift/T05 nightshift/T06

# T10 SUMMARY 不合 main(.nightshift/ 是 workspace)

# 全合后:
flutter test                                # 预期 ~1109/1109 + 1 skip(原 1086 + ~23)
flutter analyze                              # 预期 0 issues
git push origin main
```

### 清理 worktree(合并后)

```bash
for t in T01 T02 T03 T04 T05 T06 T07 T08 T09 T10; do
  git worktree remove "/Users/a10506/Desktop/wuxia-idle-$t" 2>/dev/null
done
for t in T01 T02 T03 T04 T05 T06 T07 T08 T09 T10; do
  git branch -D "nightshift/$t" 2>/dev/null
done
```

## 中途取消(若想 abort)

```bash
pkill -f "nightshift/dispatcher.sh"
# 或:
ps aux | grep dispatcher.sh
kill <PID>
```

## 容错保证

- 全 task `skippable: true`:任 1 个失败不阻塞下一个
- 每个 task 内 claude `--max-budget-usd 5` 兜底
- dispatcher 用 perl alarm 强制 50min/task timeout
- 所有 task 产出在独立 worktree + 独立分支,**main 不会被任何 task 污染**
- T01-T10 全 task 文件 0 重叠(冲突排雷表已验)
- verify.sh 每个 task 钉死改动范围(audit 不动 lib/yaml,test 不动 lib/)

## 启动前最后 sanity check

```bash
# 1. dry-run(< 5s,已跑过 PASS)
bash /Users/a10506/Desktop/挂机武侠/.nightshift/dispatcher.sh --dry-run

# 2. 主仓干净
cd /Users/a10506/Desktop/挂机武侠 && git status

# 3. 没有其他 dispatcher 在跑
pgrep -fl "nightshift/dispatcher.sh"   # 应该 0 output

# 4. 启动
bash /Users/a10506/Desktop/挂机武侠/.nightshift/launch.sh
```

启动后约 30s 内会有 T01 START 日志,可监控:

```bash
tail -f /Users/a10506/Desktop/挂机武侠/.nightshift/logs/dispatcher.log
```
