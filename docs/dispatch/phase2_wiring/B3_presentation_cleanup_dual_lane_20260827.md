# 派单包 · 二阶段 B3 表现层清账双道批(2026-08-27)

## §0 身份与总纪律

你是本批**总控**:建 worktree、按顺序推进两道任务、每件收工产 receipt。不要一边总控一边在多个 worktree 交叉写代码。

- **唯一基线**:`6d59c895dd5922adde1b64c50b3895c52d7926e9`(分支 `codex/p2-b3-presentation-test-audit-20260827` 的 tip)
- **禁 push / 禁 merge / 禁碰 main / 禁 revert**
- **禁区文件,一个字都不许动**:`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`
  - 链里已有一处 `lib/shared/strings.dart` 改动(`c6fc287e`),**授权状态待用户确认**。你不得再动它一个字,也不得为本批新增任何 UI 文案。
- **不得修改 `~/.claude/skills/` 下任何文件**(含 `gate.sh`)。执行端不修改自己的判据。
- commit message **中文动宾**;每件任务收工 tip 前缀 `[READY]` 或真实 `[BLOCKED]`。
- 真人试玩已由用户推迟到明天。**本批不依赖试玩,也不要等它。**
- 本批全部任务**只改 `test/` 与 `.github/`,零 `lib/` 改动**。需要动 `lib/` 才能完成 → 停下报告,不要自己动。

## §1 本批要换到的两个可验收结果

1. F2 五类墨效像素守卫落地,并经双向破坏证红。
2. 其余表现层假绿(F3/F4/F5)与 CI Analyze 红各自关闭或产出明确阻塞结论。

不为消耗额度重复跑全量或制造无价值文档。

## §2 环境预热(每个新 worktree 必做,不做必挂)

```bash
cp /Users/a10506/Desktop/Projects/挂机武侠/libisar.dylib <worktree>/
cd <worktree>
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

**不要设置 `DEVELOPER_DIR`**(设了会让 flutter 构建报 xcodebuild 找不到)。`.g.dart` 被 gitignore,不预热会一片 `Target of URI hasn't been generated`,那是环境前置未满足,不是代码回归。

## §3 两道队列(并行,域不相交)

### A 道 — 表现层 painter 域

worktree `/Users/a10506/Desktop/Projects/挂机武侠-p2-f2-ink`,任务串行、分支逐级堆叠。

| 序 | 分支 | 任务 | 估时 |
|---|---|---|---|
| A1 | `codex/p2-b3-f2-ink-pixel-tests-20260827`(基线 `6d59c895`) | F2 五类墨效像素守卫 | 2h |
| A2 | `codex/p2-b3-painter-mutation-sweep-20260827`(基线 A1 tip) | 其余六类 painter 逐类 mutation + 按结果补守卫 | 1.5h |

**A1 固定范围**
- 通过真实 `Phase0aBattleScreen` 定位生产 `CustomPaint`,**不直接实例化私有 `_InkEffectPainter`**;经 `CustomPaint.painter` 公共属性取到 painter 再绘制。
- 覆盖 melee / palm / gather / clear / defeat 五类,每类至少取一帧。
- `PictureRecorder` → `toImage` → `rawRgba`,断言存在非透明像素。
- 保留现有 key / 尺寸 / 坐标测试作为布局合同,不删。
- 需要暴露生产 API 才测得到 → **立即停下报告**,不自行改生产结构。

**A2 固定范围**
逐类做 mutation 实验并按实测结果处置,六类锚点(行号会漂,必须用符号重新定位):
`_GatherPullPainter`、`_GuardianWardRingPainter`、`_GuardianMechanicPainter`、`_StageWashPainter`、`_PaperBannerPainter`、`_OutcomeSealPainter`。
- 实验证明假绿的 → 按 F2 同法补像素守卫。
- 实验证明现有守卫已足够的 → **不补测试**,在 plan 文件里写明实验命令与结论。
- 不允许「因为在清单里所以都补一遍」。

### B 道 — 主线/百科/CI 域

worktree `/Users/a10506/Desktop/Projects/挂机武侠-p2-f45-mainline`,任务串行、分支逐级堆叠。

| 序 | 分支 | 任务 | 估时 |
|---|---|---|---|
| B1 | `codex/p2-b3-f45-mainline-entry-tests-20260827`(基线 `6d59c895`) | F4/F5 主线入口真实接线测试 | 2.5h |
| B2 | `codex/p2-b3-f3-baike-reachability-20260827`(基线 B1 tip) | F3 Baike 可达性判定 + 落地 | 1h |
| B3 | `codex/p2-ci-analyze-scope-fix-20260827`(基线 B2 tip) | CI Analyze 口径修复 | 20min |

**B1**:把 `mainline_all_mode_consistency_test.dart` 与 `mainline_ch1_continuous_run_test.dart` 里的 `contains('symbol')` 源码字符串断言换成真实驱动——从 `StageListScreen` 生产入口点击进入,以 provider override 选 bot/headless,断言真实 host / controller / clock 被消费;`continueFirstClearRun` 与同一 participant snapshot 确实进入宿主。**同一次调研同一会话内落地,不产中间报告再等下一轮派单。**

**B2**:先判「Repository 未加载」分支在真实启动流程里是否可达,再按结论二选一落地——可达则补真实 widget 测试(pump `BaikeScreen`、切典故 tab、断言 `baikeLoreEmpty` 上屏);不可达则删除错误声称并建立启动不可达合同。**不得自行改生产加载语义**;若落地必须让 loaded 状态可注入(即改 `lib/`)→ 停下报告。

**B3**:`.github/workflows/windows-release.yml:49` 的裸 `flutter analyze --no-pub` 改成与 `ci.yml:51` 同口径 `flutter analyze --no-pub lib test tool`。事实依据:裸跑实测 1943 issues / exit 1,1943 行全部来自 `tools/phase0minus_probe`;`gh run` 显示 2026-08-24 那次 windows-release 失败步骤即 `Analyze`。**只改口径,不动 `tools/` 里的代码,不加 exclude,不动 `analysis_options.yaml`。**

## §4 每件任务的固定收工流程

1. 实现并 commit(中文动宾)。
2. **commit 之后**做双向破坏证红(顺序固定):
   - `remove_implementation`:删掉新增实现/断言的支点,复跑该任务的 targeted 测试。
   - `force_degenerate_value`:把关键条件强制成退化值,复跑同一组。
   - 两向都必须变红并记录**实测失败数**;随后**精确反向补丁还原**。禁 `git reset --hard` / `git checkout --` / `git revert`,还原后必须 `git diff --quiet` 为 0 且 `git status --short` 为空。
3. 跑 targeted 测试(该任务直接相关文件)。
4. 跑 `flutter analyze --no-pub lib test`。
5. 跑 `dart format --output=none --set-exit-if-changed .`(**整仓 `.`,不是单文件**)。
6. 跑一次全量 `flutter test --no-pub`。**跑之前先建锁 `~/.claude/locks/wuxia_full_test.lock`,跑完删除;发现锁存在就等,两道不得同时跑全量。**
7. `git diff --check <base>..<head>`。
8. 写 `receipt.yaml` 并 commit,tip 打 `[READY]` / `[BLOCKED]`,worktree clean。

**退出码 0 不算成功**:必须逐条读 reporter 最后一行原文和 `[E]` 块计数;多路径批跑会静默漏跑文件,逐文件确认「All tests passed」出现次数。

## §5 receipt.yaml —— 本批全部是「审计单」,别写成代码单

Gate 按 `git diff --name-only base..head` 里**有没有 `lib/` 路径**自判单类型。本批五件活零 `lib/` → **一律判为审计单**。审计单的 receipt:

- `break_red` **必须留空**;写成代码单的两向数组会 schema FAIL。
- 必须且只能有一个 `audit_verification` 块。
- 破坏证红照做不误(那是我要的证据质量),但**记进 plan 文件与 commit body,不写进 receipt**。

```yaml
schema_version: 1
base_sha: "6d59c895dd5922adde1b64c50b3895c52d7926e9"
head_sha: "<你的收工 tip 全 40 位小写 sha>"
changed_files:
  - "test/....dart"
full_test_last_line: "08:12 +5633: All tests passed!"
error_block_count: 0
analyze_last_line: "No issues found! (ran in 4.0s)"
format_last_line: "Formatted 1620 files (0 changed) in 2.34 seconds."
break_red:
audit_verification:
  kind: "git_diff_check_and_patch_sha256"
  diff_check_exit: 0
  patch_sha256: "<下面命令输出的 64 位小写 sha256>"
```

```bash
LC_ALL=C git -c core.quotePath=false --no-pager diff --no-ext-diff --no-textconv \
  --no-renames --binary --full-index --no-color <base_sha>..<head_sha> | shasum -a 256
```

字段全部 JSON 双引号(`mutation` 也一样);`changed_files` 必须按字节序升序且去重;三行 last_line 抄**原文**,不要只抄 `All tests passed!` 后缀。上一单 N16 就是因为缺 receipt 被 Gate 判 FAIL。

## §6 两个已知会撞 Gate 的点(照做,别绕)

1. **`test_deletions` 是零删除策略**:`test/` 下出现任何 `^-` 即判失败。B1/B2 要替换错误断言,必然产生删除行——**该删就删,不要为了讨好判据把 import 挪位或拆成纯追加**。在 plan 文件里逐条列出:删了哪些行、每条为什么删。我会按「明示例外表」口径人工处理。
2. **广域 Gate 口径已裁定为 A**:组件任务 Gate + 聚合集成全量回归 + 明示例外表。不要提议扩展 Gate 支持 waiver,也不要改 `gate.sh`。

## §7 `[BLOCKED]` 出口条件(命中任一,立刻停,不硬做)

- 必须暴露生产私有 API 或改生产结构才测得到。
- F3 落地需要改生产加载语义 / 让单例可注入(即动 `lib/`)。
- F4/F5 需要改生产入口结构才能驱动。
- 触及玩家可见 UI 表现、数值、schema、存档语义。
- 需要动任何禁区文件。
- 破坏证红两向中任一向**没变红**(说明新增断言本身是假绿,必须报告不得掩盖)。

## §8 并发限制

- 同时最多 2 个写会话,且文件域不相交(A 道 = `test/features/battle/presentation/phase0a`,B 道 = `test/features/mainline` / `test/features/baike` / `.github`)。
- 同一 worktree 永远只有一个写者。
- 同时最多 1 个全量 `flutter test`(用 §4 的锁)。
- targeted 测试最多同时 2 组;`build_runner`、全量测试、macOS build 三者不并行。
- subagent 只用于只读检索,并发不超过 2,**根 agent 是唯一写文件的人**。
- 剩余时间进入最后约 20% 时不再开新任务,只做收尾、还原确认与 receipt。

## §9 我(Claude)会怎么验收

不采信执行端自报数字。每件 `[READY]` 我会:

1. 独立复跑 targeted + analyze + format + `git diff --check`,逐条读 reporter 尾行与 `[E]` 块。
2. **自己再做一次破坏证红**,不看你的记录。
3. 核 worktree clean、tip 前缀、commit message 中文动宾、禁区零 diff、文件域不交叉。
4. 核 receipt 与实测对撞。
5. A2 若出现「补了但 mutation 证明原本就不假绿」的测试,会被打回删除。

不合格直接打回,不替你修。

## §10 收尾(等两道都停写后,由协调者做,你不要自己做)

批一两条唯一净增分支(`codex/p2-b1-healing-banner-admission-20260827` 缺陷 F 修复、`codex/p2-b1-n14-replay-guard-20260827` 792 行守卫)rebase 进链 —— 这会移动链 tip,**必须在 A/B 两道全部停写之后**,不得并行。
