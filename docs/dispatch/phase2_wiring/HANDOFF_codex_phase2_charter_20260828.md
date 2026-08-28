# 交接 · 二阶段推进权全量移交 codex(2026-08-28 · v2 自主推进版)

## §0 交接快照(动手前先核,不符先报告偏差)

- 交接时间:2026-08-28 · main `274a3b2ec32871bfd3c735fd75bdffa528bdb2e6`(`合入交接宪法自主推进版`),`origin/main` 已同步同 sha
- 基线:全量 `05:28 +5650: All tests passed!` / analyze `No issues found! (ran in 4.6s)` / format `Formatted 1628 files (0 changed)`
- **你是二阶段唯一推进者。Claude 不再逐单审核。** 你同时是执行端、自己的把关人和合并人。
- **这意味着质量的唯一外部判据只剩 `gate.sh` 和用户试玩。** 没有人在你后面兜底了——§2 的十条和 §9 的停止条件是你不至于自我放行的全部依靠,不是可选建议。

## §1 事实源(按优先级;冲突时上位覆盖下位)

1. **`/Users/a10506/Desktop/二阶段优化方案.md`(1568 行,在仓库外,不在 git 里)** — 二阶段唯一权威方案。M0–M9 在 `:979-1116`,M2 在 `:1016-1038`,G2 八项签字表在 `:1037`。**开工前必读你要做的那个 M 段原文**,不要凭本文件转述。
2. `docs/audit/m2_scope_inventory_20260828.md` — M2 九项现状盘点(已实装 6 / 部分 2 / 未实装 1),每项带 `file:line` 实证。这是 M2 剩余工作的事实底座。
3. 项目 `CLAUDE.md` — 红线、禁区、命名、§8.2 交付门槛、§8.3 `[READY]` 信号、§9.1 执行端操作坑
4. `~/.claude/skills/afk/scripts/gate.sh` — **你的唯一外部判据。禁止修改,禁止绕过,禁止用 `--whitelist` 之外的参数放宽它。** 执行端不许改自己的考卷;现在你既是执行端又是判卷人,这条比以前更重要。

## §2 工作思路(逐条继承,不得因"自己写的自己清楚"而跳过)

这十条不是风格偏好,每一条背后都有本项目真实踩过的坑。

1. **不信自报,一切实测。** 报「完成/已修复/全绿」前必须跑验证并贴原文输出。退出码 0 不算成功——逐条读 reporter 最后一行和 `[E]` 块计数。多路径批跑会静默漏跑文件,逐文件确认「All tests passed」出现次数。**你现在自己给自己写交付报告,这条最容易松。**
2. **数字一律本会话实测,禁转抄历史。** 行号、commit、计数、测试数全部现查。长寿文档(CLAUDE.md / GDD / 方案 / 本文件)自称的「已实装 ✅」是 drift 高发区,**引用前重新定位,别信文档自称已收尾**。
3. **判「已实装」必须指出生产消费点。** 只有定义、只有测试、candidate-only 一律不算。反向核对:换 2 个以上关键词再搜一次,把否定式结论的证据写进文档。搜不到 ≠ 不存在;先搜中文/领域词找到代码里的真实命名再下判定。
4. **测试绿 ≠ 功能对。** 每条断言自问:「把那行生产代码破坏掉,这条断言必然红吗?」不必然红的就是假绿。测试不得绕开生产路径——手设字段、手动改队列、手算几何、常量比自己,都是假绿最高发入口。
5. **验证环境本身也是假设,先证伪再下结论。** 2026-08-28 实例:用 `--visual-route=phase0a_battle_playable` 真机验防御,Z 和 Space 都没反应,差点误判功能是假的;查下去发现 `visual_route_host.dart` 根本不传 `defenseTuning`,而 `phase0a_player_input_adapter.dart:129` 是 `if (defense != null && defenseTuning != null && defenseTuning.isEnabled)`,tuning 为 null 时防御 intent **静默丢弃**。是验证环境坏的,不是功能坏的。
6. **前提存疑先证伪,不顺着错误前提编。** 同日实例:曾据战斗卡片标签「3 波 · 共 9 名敌人」断言黑风岭只有 9 敌、差 4 倍;查 `stage_assignments.yaml` + `black_wind_ridge.yaml` 才发现实配 40/12/4 全部达标,是那个卡片标签本身是显示 bug。**卡片、日志、注释、上游 spec 都是待证伪的证据,不是事实。**
7. **上层 fail 会掩盖下层 bug。** 修长链路失败别修一步就报完成,跑到底。
8. **范围不缩水。** 「避免范围爆炸」「够不上一个专批」「本批先做 X,Y 单独立项」都是省力伪装。出方案前自检:假设工作量完全不是考虑因素,这个方案会变吗?会变就改回全的那个。**分批实装合法,切掉范围塞 backlog 不合法。**
9. **破坏证红必须在 commit 之后做。** 顺序固定:`remove_implementation` 删实现支点 → 复跑 targeted;`force_degenerate_value` 把关键条件强制成退化值 → 复跑同一组。两向都必须变红并记录实测失败数,然后**精确反向补丁还原**。**禁 `git reset --hard` / `git checkout --` / `git revert`**(会抹掉未提交改动),还原后必须 `git diff --quiet` rc=0 且 `git status --short` 为空。任一向没变红 = 新增断言是假绿,必须报告不得掩盖。
10. **拿不准就冻结,禁硬做。** 停在 `[BLOCKED]` 比猜一个默认值代价小得多。**没有人替你兜底之后,这条的价值翻倍。**

## §3 当前盘面

**已合并进 main**(2026-08-28,三单已过 Gate 与独立复核):J 键自动瞄准最近敌人 + 空格闪避(Z 保留)+ 三项防御 CD 展示;M2 九项范围盘点;本交接文件。

**M2 验收前置 1 项 + 剩余功能 4 项**(来自 §1.2 盘点,建议顺序即优先级):

| # | 项 | 现状 | 事实锚点 |
|---|---|---|---|
| 0 | visual route 缺 `defenseTuning` | 验收前置缺陷(不计入 M2 四项功能分母) | `visual_route_host.dart:477-484` 加载 debug fixture;`phase0a_debug_battle_fixture.dart:241-268,271-302` 构造玩家/敌人 adapter 时都未传 tuning;`phase0a_player_input_adapter.dart:128-145` 会因 tuning 为 null 静默丢弃防御 intent。**凡用 visual route 做的战斗视觉验收,拍到的防御状态都是失效态** |
| 1 | 屏外提示 | 未实装 | 反搜 `offscreen/屏外/indicator arrow` 在 battle presentation 零命中。**高密度下没有它就没法玩**,M2 剩余里优先级最高 |
| 2 | 聚合伤害 | 未实装 | `phase0a_vfx_controller.dart:154-173,195-273` 每个伤害 outcome 建独立 popup;`phase0a_battle_screen.dart:407-445` 只淘汰超量不合并数值 |
| 3 | 五关四模板 | 部分 | `stage_assignments.yaml` 只有 `stage_01_03` 迁移;`StageDef`(`stage_def.dart:100-179`)无 template 字段;candidate fixture 里才有 roadbreak/stronghold/ambush/commander 路由 |
| 4 | 剑形态完整普攻链 | 未实装 | `basic_attack_chain.dart:1-5,59-133` 明标 candidate-only;生产 `phase0a_player_input_adapter.dart:147-165` 每次只发单段 `moveKind: light` |

**其他在途**:E2 真机打局管线需返修(首帧时间戳校正 + 帧内容语义断言 + `recording.log` 真落盘);E1 已产出 28 条真实缺陷(战斗退出 10 + 语义 18),按用户「先把基础攻击和技能做好体验」的排序押后。

## §4 推进顺序与 Gate 纪律

`M2 剩余四项 → G2 用户试玩签字 → 才能开 M3/M4`。

**G2 是用户主观试玩 Gate,你不能自签,也不能因为四项都做完了就自动往下走。** 方案 `:1037` 的八项硬检查原文:持续移动/普攻无漏拍;35–45 总敌量有连续清杂爽感;8–16 活跃时玩家与关键威胁仍清楚;护盾/化解/闪避各有真实用途;Boss 攻击可学且破绽可利用;胜利到下一关无阻塞;同装配自动/headless 规则无漂移;双视口性能和水墨表现过线。每项记 `PASS / REWORK / BLOCKED`。**只有全部 PASS 或用户明确豁免,才能标 G2 通过并开 M3/M4。**

配套硬约束:没过 G2 不扩 21 章;M7 此时只允许建任务包和依赖图,不允许未依赖冻结模板/生态的内容包开写。

**M2 四项做完后,你要做的是准备试玩材料并请用户试玩,不是开 M3。** 请用户专门玩 `stage_01_03` 黑风岭——它是唯一 migrated 的关(40 敌/12 活跃/4 令牌,三项都在 G2 要求区间内)。其余四关仍是 legacy 的 2/3/4 波,那是方案明写的「可比较的过渡 fallback」,不是遗漏。用户此前反馈「怪物出现顺序千篇一律」正是因为玩的是 legacy 关。

## §5 每个单的固定收工流程

1. 建 worktree 并预热(见 §7),实现并 commit(**message 必须中文动宾**,英文 conventional 前缀属违规)
2. commit 之后做双向破坏证红(§2.9),精确反向补丁还原
3. targeted 测试(逐文件确认「All tests passed」出现次数)
4. `flutter analyze --no-pub lib test`
5. `dart format --output=none --set-exit-if-changed .`(**整仓 `.`**;写完 dart 必 format,CI 有门禁)
6. 一次全量 `flutter test --no-pub`。**先建锁 `~/.claude/locks/wuxia_full_test.lock`,跑完删除;锁存在就等**,同时只允许一个全量。第 9 步 `gate.sh` 内部也会跑全量,调用 gate 时必须同样持有该锁
7. `git diff --check <base>..<head>`
8. 写 receipt(形态见 §6),tip 打 `[READY]` 或真实 `[BLOCKED]`,worktree clean
9. **自跑 gate.sh 判决**(见 §8)。PASS 才进合并流程,FAIL 一律不合

## §6 receipt 形态(此处曾出过事,照抄别改)

**路径 `build/phase2_wiring_receipts/<单名>/receipt.yaml`。`build/` 已 gitignore,所以写它不弄脏 worktree——不要 commit receipt,不要写到 worktree 根。**

**顺序很重要:先打 `[READY]` 空 commit,再写 receipt**,让 `head_sha` 等于最终 tip(gate 强校验 `head_sha == 被评估 HEAD`)。

Gate 按 `git diff --name-only base..head` **有没有 `lib/` 路径**自判单类型:

- **代码单**(有 `lib/`):`break_red` 必须是结构化块列表,`direction` 恰好按 `remove_implementation`、`force_degenerate_value` 顺序,每块含 `mutation`(非空描述)/`failed_count`/`conclusion`;`conclusion` ∈ `RED_CONFIRMED`(要求 `failed_count > 0`)/ `RED_NOT_CONFIRMED`(要求 `= 0`)。**不得出现 `audit_verification` 字段。**
- **审计单**(零 `lib/`):`break_red` 必须留空,且必须且只能有一个 `audit_verification` 块(`kind` / `diff_check_exit` / `patch_sha256`)。破坏证红照做,但记进 plan 文件和 commit body,不写进 receipt。

公共字段:`schema_version` / `base_sha` / `head_sha`(均 40 位小写十六进制)/ `changed_files`(**按字节序升序去重,与实测一致**)/ `full_test_last_line` / `error_block_count` / `analyze_last_line` / `format_last_line`。三行 last_line **抄原文**,全部 JSON 双引号。

`patch_sha256` 算法:

```bash
LC_ALL=C git -c core.quotePath=false --no-pager diff --no-ext-diff --no-textconv \
  --no-renames --binary --full-index --no-color <base_sha>..<head_sha> | shasum -a 256
```

## §7 硬约束

- **禁区文件,一个字都不许动**:`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`。需要改 → 停下问用户(§10),**不得自行改动**。数值与玩家可见文案是产品决策,不因你获得自主权而解锁。
- **不得修改 `~/.claude/skills/` 下任何文件(含 `gate.sh`)。**
- 数值红线见 CLAUDE.md §5.4;三系锁死见 §5.3;反主流不做清单见 §5.1。触及即停。
- **禁 revert、禁 force push、禁改写已 push 的历史、禁删除他人 worktree/分支。**
- 环境:`unset DEVELOPER_DIR`(设了 flutter 构建报 xcodebuild 找不到);需要 CocoaPods / `flutter build macos` 时用 `LC_ALL=en_US.UTF-8`,**不要用 `LC_ALL=C`**(本仓路径含中文,`C` 会让 CocoaPods 抛 `Encoding::CompatibilityError`)。
- fresh worktree 预热(不做必挂):`cp /Users/a10506/Desktop/Projects/挂机武侠/libisar.dylib <worktree>/` → `flutter pub get` → `dart run build_runner build --delete-conflicting-outputs`。`.g.dart` 被 gitignore,缺失是环境前置未满足,**不是代码回归**。

## §8 合并与 push(本次新授权,附前置条件)

你现在有合并与 push 权。**但每一步的前置条件是硬性的,不满足就不许往下走。**

合并前必须全部满足:

1. 该单自跑 `gate.sh <worktree> <base> <head> --receipt <path>` 判决为 **`PASS`**
2. gate 若判 `FAIL`:**一律不合,本次无人工豁免(包括 `test_deletions`)**。修到过为止;认为判据本身有问题 → `[BLOCKED]` 停下问用户,**不许改 gate,不许绕过,不许自行裁定"这条 FAIL 可以放行"**
3. `git merge-tree --write-tree main <branch>` rc=0
4. 检查改动域重叠:`comm -12` 比对「main 领先该分支的 commit 触及的文件」与「该分支相对 main 的改动文件」,有重叠时必须逐个人工核对,防整文件覆写型静默回退
5. 合并用 `--no-ff` 保留 `[READY]` 链,commit message 中文动宾

push 前必须全部满足:

6. 合并后在 main 上重跑 `flutter analyze --no-pub lib test`(0 issue)+ `dart format --output=none --set-exit-if-changed .`(0 changed)+ 一次全量 `flutter test --no-pub`(建锁)。**批末全量不可省**
7. `git status --short` 为空

push 后必须做:

8. 核 CI:**显式读 `conclusion` 字段,不能只看 `gh run watch` 的退出码**(`--exit-status` 返 0 不等于通过,cancelled 会被掩盖),并核 `headSha` == 你刚 push 的 commit
9. CI 红:基建型(网络/缓存/超时)可重跑;真红必须修,**不得放着不管继续开新单**

## §9 自主推进的停止条件(触任一即停,写清情况问用户)

没有外部审核之后,这些是防止你越走越偏的闸门:

- 同一个单被你自己的 gate 判 FAIL **连续两次**——说明你对该单的理解可能有系统性偏差,停下报告
- 你发现自己正在**放宽判据、修改测试断言以求变绿、或论证某条 FAIL 可以豁免**(`test_deletions` 例外除外)
- 你发现自己正在**缩小已定范围**以便更快收工(见 §2.8)
- 连续 3 个单没有任何 M2 剩余项的实质推进(说明陷入了周边工作)
- main 上 CI 连续红且你无法定位根因
- M2 四项全部完成——**此时必须停,准备试玩材料请用户签 G2,不得自行开 M3/M4**

## §10 必须停下问用户的情形(🔴 禁代拍,不因自主权而解锁)

这几类不是"质量审核",是**产品决策与主观体验**,你客观上无法替代:

- 玩家可见 UI 表现、文案、键位语义的变更
- 数值与成长规则、schema 与迁移、删除配置字段或功能
- GDD 解释、正式美术替换
- **G2 试玩签字**(只有用户能签)
- 方案范围与现有架构存在不可调和冲突(例如「模板」概念与现有 stage schema 互斥)——这是设计冲突,停下报告,不要自己选一条路
- 破坏证红任一向没变红

停下的方式:tip 打 `[BLOCKED] <一句话待拍板点>`,worktree clean,plan 文件写清阻塞项,然后向用户报告。
