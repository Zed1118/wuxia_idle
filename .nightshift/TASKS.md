# Nightshift Plan - 2026-05-19 P1 #42 收口后挂账冲刺 + 新屏 widget test 加固
Window: 用户睡眠 8h 内(实际预期 4-6h 串行完成)
Total tasks: 10
Dispatcher interval: 30s buffer(task timeout 50m + 30s 间隔)
HEAD baseline: 3d24af1 (main, 0 issues + 1086 pass + 1 skip)

> **本批主题**:P1 #42 Phase 1+2 §10 三方式 + P2 扩段 100% 全闭环里程碑后,清挂账 + 加固新屏 widget test。
>
> **task pool 设计原则**:① 10 task 全独立无 file 冲突(各自改 PROGRESS / docs/handoff/<unique>.md / test/features/<unique>);② 全 sonnet --print 跑;③ test task 不动 lib/(只 add test);④ audit task 不动 yaml/lib(只输出 md);⑤ #37 钉死「不挂回 yaml」/ #43 钉死「只 audit 不改」/ #08 死代码钉死「dry-run 不删」;⑥ 每 task spec Phase 0 reality check 必跑(memory `feedback_workflow_speed_levers` Lever 2)。
>
> **吸取昨天教训**:① dispatcher auto-create worktree(`-B` 覆盖);② verify 加 `dart run build_runner build --delete-conflicting-outputs`(.g.dart gitignored);③ analyze `--fatal-errors` 不 `--fatal-infos`(memory `feedback_nightshift_verify_lint_severity`);④ test task 仅跑 feature-local(memory `feedback_workflow_speed_levers` Lever 1);⑤ 数字必 grep 实测不写死(memory `feedback_closeout_numbers_grep`)。
>
> **文件冲突排雷表**:T01→PROGRESS.md(独占)/ T02-T03/T07-T09→docs/handoff/<unique-date-slug>.md(无冲突)/ T04→codex_entry_detail_test.dart / T05→codex_tab_test.dart / T06→tutorial_banner_card_test.dart / T10→.nightshift/SUMMARY.md(独占)。**0 file overlap,cherry-pick 全干净**。

## T01: PROGRESS.md 96 行清理 → < 80
- status: pending
- worktree: ../wuxia-idle-T01 (auto-created by dispatcher)
- skippable: true
- timeout_min: 30
- risk: low
- type: doc
- goal: |
    PROGRESS.md 96 行已近 100 cap。顶段「当前阶段」5 段(P1.z / P1.y / P1.x / Phase 1 / W18-A1.2)详条迁出归档段「W14-W15 详条迁出」体例,顶段保留近 2 项(P1.z + P1.y),其余压缩到「W17-W18 详条迁出 2026-05-19」段。目标 < 80 行。**不丢内容只压缩**。
    完整 prompt:`.nightshift/prompts/T01.md`。
- verify: bash .nightshift/prompts/T01.verify.sh
- rollback: git reset --hard HEAD && git clean -fd

## T02: #43 高阶占位 audit
- status: pending
- worktree: ../wuxia-idle-T02
- skippable: true
- timeout_min: 40
- risk: low
- type: audit
- goal: |
    equipment.yaml line 11 `drop_source_tags:` 占位 + towers.yaml 21-30 层敌人 skillIds(暂用 mingjia 阶)+ dropTable(暂用 liqi 阶)占位。grep 实测各占位实际位置 / 数量 / 期望值,输出 `docs/handoff/p1_43_higher_tier_placeholders_audit_2026-05-19.md`(≤ 80 行)含:① 占位现状表 ② 期望状态 ③ 推荐补齐方案(Phase 1.1 vs P2 起手时机)④ 风险评估(Demo 是否可接受)。**不改 yaml,只输出 md**。
    完整 prompt:`.nightshift/prompts/T02.md`。
- verify: bash .nightshift/prompts/T02.verify.sh

## T03: #37 6 orphan 主题逐条复审(决议归档)
- status: pending
- worktree: ../wuxia-idle-T03
- skippable: true
- timeout_min: 45
- risk: mid
- type: audit
- goal: |
    `data/events/_archive/` 6 条 orphan(duan_qiao_can_yue / gu_chuan_deng_ying / huang_cun_yao_ren / qing_lou_can_meng / lao_jing_hui_xiang / yu_zhong_qiao_men)逐条读全文 + 主题归类 + 是否有匹配的现有 technique/encounter slot。**钉死:不动 encounters.yaml + events/_archive/**,只输出 `docs/handoff/p1_37_orphan_decree_2026-05-19.md`(≤ 100 行)含:① 6 条主题表(标题/biome/weather/调子)② 每条「挂回 vs 永封档」推荐 + 理由 ③ 若挂回,目标 encounter id + 数值红线核查(不在本批落地)。
    完整 prompt:`.nightshift/prompts/T03.md`。
- verify: bash .nightshift/prompts/T03.verify.sh

## T04: CodexEntryDetail widget test 加固 37→80+
- status: pending
- worktree: ../wuxia-idle-T04
- skippable: true
- timeout_min: 50
- risk: low-mid
- type: test
- goal: |
    `test/features/codex/presentation/codex_entry_detail_test.dart` 当前 37 行覆盖最薄。补 8-10 个边界 case:① NarrativeReader 多段 page navigation ② 短文(1 段)/ 中文(3-5 段)/ 长文(8+ 段)/ AppBar 返回 / 跳过按钮(P1.z codex 默认 mandatory=false 跳过可见)/ scroll / 空 entry fallback(空字符串)/ 标题渲染。**不动 lib/,只 add test**。预期 testWidgets +8-10。
    完整 prompt:`.nightshift/prompts/T04.md`。
- verify: bash .nightshift/prompts/T04.verify.sh

## T05: CodexTab widget test 加固 115→160+
- status: pending
- worktree: ../wuxia-idle-T05
- skippable: true
- timeout_min: 50
- risk: low-mid
- type: test
- goal: |
    `test/features/codex/presentation/codex_tab_test.dart` 当前 115 行,P2 扩段后 19 条 entry(12 机制 + 7 lore)+ unlockedCount「档数」语义新。补 10-15 case 覆盖:① 19 条全 locked 状态 ② 部分 unlock(2/4/8 档)③ Codex 9 分类 渲染顺序 ④ ListView viewport `setSurfaceSize(800, 3000)`(memory `feedback_listview_widget_test_viewport`)⑤ InkWell push to detail ⑥ 灰显 lock_outline 图标 ⑦ 「已解锁 N / 8」计数边界(0/1/8 = 满)⑧ 「待解锁」文案 ⑨ lore 段 sublist 顺序 ⑩ tabs (机制 / 江湖背景) 切换。**不动 lib/,只 add test**。预期 testWidgets +10-15。
    完整 prompt:`.nightshift/prompts/T05.md`。
- verify: bash .nightshift/prompts/T05.verify.sh

## T06: TutorialBannerCard widget test 边界 +5
- status: pending
- worktree: ../wuxia-idle-T06
- skippable: true
- timeout_min: 35
- risk: low
- type: test
- goal: |
    `test/features/tutorial/presentation/tutorial_banner_card_test.dart` 已有基础覆盖。补 5 个边界 case:① hintsRead 含 [6] step 6 不显 ② [6,7] step 8 仍显 ③ multi-banner 顺序(step 6/7/8 同时未读取最早 unread,_firstUnreadHint 派生)④ null/空 hintsRead 默认全显 ⑤ InkWell tap onTap call。**不动 lib/,只 add test**。预期 testWidgets +5。
    完整 prompt:`.nightshift/prompts/T06.md`。
- verify: bash .nightshift/prompts/T06.verify.sh

## T07: typedef/extension 死字段周期审计(B 推荐)
- status: pending
- worktree: ../wuxia-idle-T07
- skippable: true
- timeout_min: 40
- risk: low
- type: audit
- goal: |
    memory `feedback_extension_hardcode_audit` 周期清账。① Isar entity extension(`*Extension on <Entity>` 体例)扫描 lib/ 全仓 + 每 method 字段使用率 grep ② lib/data/defs/ 各 `*_def.dart` 字段使用率(grep field name 在 lib/ 出现次数,0 引用 = 候选死字段)③ 输出 `docs/handoff/typedef_extension_audit_2026-05-19.md`(≤ 100 行)含:① extension method 总数 + 0 引用 candidates ② def 字段 0 引用 candidates ③ 推荐处置(删/留/扩 caller)。**只列不删**。
    完整 prompt:`.nightshift/prompts/T07.md`。
- verify: bash .nightshift/prompts/T07.verify.sh

## T08: 死代码 dry-run scan(B 推荐)
- status: pending
- worktree: ../wuxia-idle-T08
- skippable: true
- timeout_min: 40
- risk: low
- type: audit
- goal: |
    ① `dart fix --dry-run` 全仓跑 ② manual scan: grep `@riverpod` provider 名 + service class 名 + widget class 名,统计每个引用次数(0 引用 = orphan candidate)③ 输出 `docs/handoff/deadcode_scan_2026-05-19.md`(≤ 100 行)含:① dart fix dry-run 摘要 ② orphan provider/service/widget candidates 表 ③ 推荐处置(删/留)。**钉死 dry-run 不删,不动 lib/**。
    完整 prompt:`.nightshift/prompts/T08.md`。
- verify: bash .nightshift/prompts/T08.verify.sh

## T09: lib/ 目录结构审计(B 推荐)
- status: pending
- worktree: ../wuxia-idle-T09
- skippable: true
- timeout_min: 35
- risk: low
- type: audit
- goal: |
    本会话新增 feature(tutorial / codex)+ W16 festival + W17 lineage 是否符合 CLAUDE.md §3 lib/features/<feature>/{domain,application,presentation} 三层。grep features/ 树结构 + 命名规范 + 跨 feature 依赖,输出 `docs/handoff/lib_structure_audit_2026-05-19.md`(≤ 80 行)含:① 当前 feature 列表(分层完整度)② 偏差(若有)③ 跨 feature import 依赖图(是否有 import 倒挂)④ 推荐处置。**只审,不动 lib/**。
    完整 prompt:`.nightshift/prompts/T09.md`。
- verify: bash .nightshift/prompts/T09.verify.sh

## T10: SUMMARY 生成(收尾)
- status: pending
- worktree: ../wuxia-idle-T10
- skippable: true
- timeout_min: 25
- risk: low
- type: summary
- goal: |
    读 T01-T09 `.nightshift/status/T0X.status` + commit 信息 + verify exit code,产出唯一新文件 `.nightshift/SUMMARY.md`(覆盖前次)含:① 任务执行表(10 行) ② 各 task commits + 文件改动统计 ③ 测试状态(全量 + 各 task 局部)④ 早上 review 三 phase 清单(① 阅 SUMMARY → ② 各 task git diff → ③ cherry-pick 合 main)⑤ 已知偏差 + 失败原因 ⑥ 下波候选 3-6 表(续 PROGRESS 下波候选)。
    完整 prompt:`.nightshift/prompts/T10.md`。
- verify: bash .nightshift/prompts/T10.verify.sh

---

## 启动

```bash
bash /Users/a10506/Desktop/挂机武侠/.nightshift/launch.sh
```

`launch.sh` 内含 `caffeinate -dimsu nohup ... &` + disown,关闭 Terminal 不影响 dispatcher。

## Dry-run(睡前必跑一次)

```bash
bash /Users/a10506/Desktop/挂机武侠/.nightshift/dispatcher.sh --dry-run
```

打印「会调度哪些 task / 用哪些 prompt」不真启 claude,< 5s 完成。看到「DRY RUN: would auto-create worktree ... + claude --print ...」就说明 dispatcher 健康。

## 早上检查入口

```bash
cat /Users/a10506/Desktop/挂机武侠/.nightshift/SUMMARY.md            # T10 产出
ls /Users/a10506/Desktop/挂机武侠/.nightshift/status/                # 10 task 终态
tail -100 /Users/a10506/Desktop/挂机武侠/.nightshift/logs/dispatcher.log
git log --all --oneline | grep nightshift                            # 全 task commit
git branch -a | grep nightshift                                      # 10 task 分支
```

## 合并产出(早上 review 后)

```bash
cd /Users/a10506/Desktop/挂机武侠
git checkout main

# 单 task 合并(--no-ff 保留 nightshift 痕迹)
git merge nightshift/T01 --no-ff -m "merge(nightshift T01): PROGRESS 行数清理"

# 或批量 cherry-pick(适合 doc/audit 一行 commit)
git cherry-pick nightshift/T01 nightshift/T02 nightshift/T03 nightshift/T07 nightshift/T08 nightshift/T09  # audit/doc
git cherry-pick nightshift/T04 nightshift/T05 nightshift/T06                                                # test
# T10 SUMMARY 不合 main(.nightshift/ 是 workspace 目录)
```

## 清理 worktree(合并后)

```bash
for t in T01 T02 T03 T04 T05 T06 T07 T08 T09 T10; do
  git worktree remove "../wuxia-idle-$t" 2>/dev/null
done

# 删 nightshift 分支
for t in T01 T02 T03 T04 T05 T06 T07 T08 T09 T10; do
  git branch -D "nightshift/$t" 2>/dev/null
done
```

## 风险与已知偏差

1. **Claude --print 网络依赖**:Anthropic API 调用,代理 hook 不在 claude 命令清单。半夜代理断 → 全 task SKIPPED。
2. **flutter pub get 网络依赖**:verify 时跑 pub get 拉缓存外依赖。pub cache 已预热则 30s 内,否则 fail。
3. **Mac sleep**:`caffeinate -dimsu` 兜底防 sleep,但 macOS 强制更新 / 蓝牙断连等可能仍中断。
4. **API budget**:每 task `--max-budget-usd 5`,10 task 共预算 $50。实际不会用完(sonnet 50min ~$1-2)。
5. **worktree 内首次 build_runner 缺失**:.g.dart gitignored 不在 worktree。verify 已加 `dart run build_runner build --delete-conflicting-outputs` 兜底。

## 容错保证

- 全 task `skippable: true`,1 个失败不阻塞下一个
- 每个 task 内 claude 也有 max-budget 兜底
- dispatcher 用 perl alarm 强制 50min/task timeout
- 所有 task 产出在独立 worktree + 独立分支,**main 不会被任何 task 污染**
- T01-T10 全 task 文件 0 重叠(冲突排雷表已验)
