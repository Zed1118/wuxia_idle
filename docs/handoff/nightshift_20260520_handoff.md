# Nightshift 2026-05-20 启动 handoff(睡前 5 分钟看)

> 8 worktree × 串行 dispatcher,**opus --print**(全 task,用户钉死),预计 4.5-6h 实跑,8h 窗有 2-3.5h buffer。
> infra 沿用 2026-05-19 dispatcher.sh + launch.sh,**已修 3 个 bug**(opus model / output cap env / verify diff-tree)。
> 主题:**Demo §8.4 polish 丰满化**——心法相生触 §4.5 上限 / 武学领悟+5 / 基础奇遇+4 / 心法 description 占位填实 / 3 类 narrative +9 / Phase 5+ 师徒 spec 起草 / closeout 收尾。

## 启动(一行命令)

```bash
bash /Users/a10506/Desktop/挂机武侠/.nightshift/launch.sh
```

`launch.sh` 内含 `nohup + caffeinate -dimsu + disown`,关闭 Terminal 不影响,Mac 也不会 sleep。终端会输出 PID + log 路径 + cancel 命令,**记下 PID** 后可直接关 Terminal 睡觉。

## 任务 8 个一览

| Task | 主题 | 类型 | 输出 | 估时(opus) |
|---|---|---|---|---|
| T01 | 心法相生 +3(5→8 触 §4.5 上限)+ 红线 test | code+yaml+test | `data/synergies.yaml` + `test/balance/synergy_hot_loop_upgrade_test.dart` | 25-40 min |
| T02 | encounters.yaml +9(领悟 +5 + 奇遇 +4)+ skills +5 | yaml+test | `data/encounters.yaml` + `data/encounter_skills.yaml` + test | 35-50 min |
| T03 | techniques.yaml 21 本 description 占位 → 真文案 | yaml content | `data/techniques.yaml`(只改 description) | 35-50 min |
| T04 | 武学领悟招式 narrative +5(insights/) | yaml content | `data/narratives/techniques/insights/` ×5 | 25-40 min |
| T05 | 基础奇遇 events narrative +4 | yaml content | `data/events/` ×4 | 30-45 min |
| T06 | 心法 narrative +4(冰魄/赤阳/流云/太一) | yaml content | `data/narratives/techniques/` ×4 | 35-50 min |
| T07 | Phase 5+ 师徒升级 spec 起草 | doc | `docs/handoff/phase5_master_disciple_spec_2026-05-20.md` | 35-45 min |
| T08 | Demo §8.4 验收 + closeout | doc | `docs/handoff/p1_45_demo_polish_closeout_2026-05-20.md` | 30-45 min |

**总估时**(opus): 4.6-6.1 h 串行,**8h 窗有 1.9-3.4 h buffer**。

## 风险与缓解

| 风险 | 缓解 |
|---|---|
| opus 比 sonnet 慢 1.5-2x | TASK_TIMEOUT_MIN=75 / TASK_BUDGET_USD=8(原 50/$5) |
| opus output token 32K 默认 cap | `CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000` env(memory `feedback_nightshift_max_output_token`) |
| verify "改动越界" grep bug | 改 `git diff-tree --no-commit-id --name-only -r HEAD`(memory `feedback_nightshift_verify_changedoutside_bug`) |
| analyze 误报阻塞 | `--fatal-warnings` 不 `--fatal-infos`(memory `feedback_flutter_analyze_fatal_errors_invalid`) |
| .g.dart 缺失 | verify 含 `dart run build_runner build --delete-conflicting-outputs` 兜底 |
| 文案黑名单词出现 | verify.sh 各文件 grep `legendary/epic/史诗/神器/...` 12 词拦 |
| 跨 worktree id 不一致 | T02/T04/T05 spec 钉死 14 id(5 insight + 5 skill + 4 fortune),hard-code 不可变 |
| Claude --print 网络断 | API 走原始网络,半夜代理断 → SKIPPED;dispatcher 不阻塞,凌晨网络恢复重 launch 可幂等续跑 |
| Mac 强制更新 / 蓝牙断 | caffeinate -dimsu 兜底 |
| API budget 超 | 每 task --max-budget-usd 8,8 task 总 $64 上限,opus 实测 < $5/task |
| Isar testWidgets 死锁 | 本批无 widget test(只 T01/T02 改 test,都是数据 fixture 验证不渲染 widget) |
| 任务间文件冲突 | TASKS.md 冲突排雷表已验,**0 file overlap** |

## 早上检查 3 phase 清单

### Phase A · 阅状态(5 min)

```bash
ls /Users/a10506/Desktop/挂机武侠/.nightshift/status/       # 8 task 终态
tail -100 /Users/a10506/Desktop/挂机武侠/.nightshift/logs/dispatcher.log
git log --all --oneline | grep nightshift                   # 8 task commits
git branch -a | grep nightshift                             # 8 task 分支
```

### Phase B · 各 task git diff review(各 1-2 min)

```bash
for t in T01 T02 T03 T04 T05 T06 T07 T08; do
  echo "=== $t ==="
  cd "/Users/a10506/Desktop/wuxia-idle-$t" 2>/dev/null && git diff main..HEAD --stat
done
```

### Phase C · cherry-pick 合 main(各 10-30 s)

```bash
cd /Users/a10506/Desktop/挂机武侠
git checkout main

# 7 个产出 task cherry-pick(T01 数值 / T02 数值+skill / T03-T06 文案 / T07 doc)
git cherry-pick nightshift/T01 nightshift/T02 nightshift/T03 \
                nightshift/T04 nightshift/T05 nightshift/T06 \
                nightshift/T07
# T08 closeout 不合 main(closeout doc 仅供 review,PROGRESS 顶段更新由主对话做)

# 全合后验证:
flutter test                  # 预期 ≥ 1124 pass + 1 skip(原 1119 + T01 +3 case + T02 +2 case)
flutter analyze --fatal-warnings  # 预期 0 issues
git push origin main
```

### Phase D · PROGRESS 更新(主对话做,5-10 min)

主对话 cherry-pick 后:
- PROGRESS.md 顶段插入 P1 #45 完工段(沿 #44 体例,2-3 行)
- 老顶段(#43/#44)迁出到归档段「W17-W18 详条迁出」末尾
- 总行数控制 < 80
- commit "docs: P1 #45 Demo polish nightshift 销账 + PROGRESS 同步"

### Phase E · 清理(可选,5 min)

```bash
for t in T01 T02 T03 T04 T05 T06 T07 T08; do
  git worktree remove "../wuxia-idle-$t" 2>/dev/null
  git branch -D "nightshift/$t" 2>/dev/null
done
```

## 关键差异 vs 2026-05-19 nightshift

| 项 | 2026-05-19 | 2026-05-20(本批) |
|---|---|---|
| Model | sonnet | **opus**(全 task) |
| Task 数 | 10 | 8 |
| Task timeout | 50 min | 75 min |
| Task budget | $5 | $8 |
| Output token cap env | 未配(T01 失败) | **64000** ✅ |
| verify changedoutside | `git show --name-only`(误抓) | **`git diff-tree`** ✅ |
| analyze flag | `--fatal-errors`(非法 flag) | **`--fatal-warnings`** ✅ |
| 主题 | 挂账冲刺 + widget test 加固 | Demo §8.4 polish 丰满化 |
| 期望 commit 数 | 10 task → 10 commit | 8 task → 8 commit |

## 完成后下波候选(沿 PROGRESS 顶段)

| # | 任务 | 模型 | 时长 |
|---|---|---|---|
| 1 | 美术 PoC + 水墨 LoRA 调研 | opus xhigh + 用户主导 | 6-10 h |
| 2 | Phase 5+ 师徒系统升级实装(本批 T07 已起草 spec)| opus xhigh | 8-15 h |
| 3 | 章节扩展 / 心法相生新 type 设计 | sonnet/opus | TBD |

---

**Good night!** 起床后先 `tail -100 .nightshift/logs/dispatcher.log` 看终态,再走 Phase A → B → C → D。
