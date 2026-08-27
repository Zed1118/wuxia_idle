# codex 接管交接单(2026-08-27)· 12 小时工作包

> 写给 codex 的直接交接。Claude 侧用量将尽,后续由用户直接与 codex 沟通。
> **本文所有 `file:line` 都必须重新定位后再用**,理由见 §0.3。

---

## §0 开局(动手前必做,约 20 分钟)

### 0.1 先读这三份

1. 项目 `CLAUDE.md` —— 尤其 **§5 红线**、**§8.2 交付门槛**、**§8.3 就绪信号**、**§9 不要做的事**、**§9.1 执行端操作坑速查**
2. 本文全文
3. `docs/dispatch/G2_playtest_runbook_20260827.md` —— 用户正在做的真人试玩,本包多数任务都是它暴露出来的

### 0.2 当前仓库全景

| 项 | 值 |
|---|---|
| main | `aed517e9 冻结防御特效渲染修复派单包` |
| **在途执行分支** | `codex/p2-defense-vfx-fix-20260827`(worktree `挂机武侠-p2-defvfx`)—— **N16,交接时正在跑,见 §1** |
| **用户试玩用的集成分支** | `integration/p2-g2-candidate-20260827`(worktree `挂机武侠-p2-integration`),tip `870f9832 [BLOCKED]`,树 `fd2a9ed3` |
| 集成分支 Gate | 2026-08-27 已跑全量:`full_test 5623 全过` / `analyze 0` / `format 0 changed` / `worktree_clean`;4 条 FAIL 见 `docs/dispatch/2026-08-26_night_plan.md` |

### 0.3 行号会漂,必须重新定位

本文的 `file:line` 是 Claude 在**集成分支**上读的。`main` 上同一处行号不同——实测例:
防御渲染短路那行在集成分支是 `:1610`,在 main 上是 `:1604`。

**所以:每处动手前用 `grep -n` 重新定位,以符号/代码内容为锚,不要照抄行号。**
发现本文描述与代码实况不符 → **先停下报告偏差,不要顺着错误前提做**。

### 0.4 证据分级(重要)

本文事实分两类,可信度不同:

- **【C 已验】** = Claude 本人在本次会话中直接读代码验证过
- **【S 未复核】** = 来自检索子代理的报告,**Claude 本人没有逐条复核**

**凡标【S 未复核】的,你必须自己先验一遍再动手。**

---

## §1 已派出、正在跑的活:N16 防御特效渲染修复

**派单包**:`docs/dispatch/phase2_wiring/N16_defense_vfx_render_fix.md`(main 上,冻结于 `aed517e9`,sha256 前缀 `161571b4523334c8`)
**分支**:`codex/p2-defense-vfx-fix-20260827`,基线 `aed517e9`
**worktree**:`/Users/a10506/Desktop/Projects/挂机武侠-p2-defvfx`(已预热:pub get + build_runner 128 outputs)

**接管方式**:
- 如果那个会话还在跑 → 让它跑完,你不要在同一 worktree 并行写
- 如果已中断/未完成 → 读派单包,**在同一分支续做**,不要另起分支
- 完成后按派单包 §10 自检,tip 打 `[READY]`

**N16 的核心要求别漏**:必须补一条**渲染层**测试(现有测试只断言控制器产出条目、从不渲染 widget,功能 100% 坏了它照样绿),并做**破坏证红**(必须在 commit 之后做,用带 `trap restore EXIT INT TERM` 的脚本包住)。

---

## §2 硬约束(违反即视为未交付)

### 2.1 禁区文件——一个字都不许动

- `data/numbers.yaml`
- `GDD.md`
- `PROGRESS.md`
- `lib/shared/strings.dart`
- `pubspec.yaml`

需求由协调者/用户收口。**要改这些,停下来问用户。**

### 2.2 git 纪律

- **禁 push / 禁 merge / 禁碰 main / 禁 revert**
- 一个任务一个分支一个 worktree,只写自己的 worktree
- commit message **中文动宾**(英文 conventional 前缀如 `feat(x):` 属违规,CI Gate 会查)
- 分支写完:工作区干净 + **tip commit 消息前缀** 打 `[READY]`(写完待评)或 `[BLOCKED]`(需用户拍板)
- **注意**:后续任何 commit 都会让旧标记失效(这是有意的 fail-closed 设计)。merge 之后必须重跑验证再补新标记,**不要扫描历史标记**

### 2.3 fresh worktree 必做预热

```bash
cp /Users/a10506/Desktop/Projects/挂机武侠/libisar.dylib <新worktree>/
cd <新worktree> && flutter pub get && dart run build_runner build --delete-conflicting-outputs
```
`.g.dart` 被 gitignore,不预热会报一片 `Target of URI hasn't been generated`。
**不要设 `DEVELOPER_DIR`**,它会让 `flutter build macos` 报 xcodebuild 找不到。

### 2.4 测试纪律

- 写完 dart 必跑 `dart format`(CI 门禁)
- 全量用**并发** `flutter test --no-pub`(约 6 分钟);`-j1` 慢 3.8×,只在排查 flaky 时用
- 自包含改动只跑 targeted + `flutter analyze`;跨切面或批末才全量
- **多路径批跑会静默漏跑文件**:验收要逐文件确认「All tests passed」出现次数,不看总数
- `flutter test` 退出码 0 **不代表全绿**,要读 `[E]` 块
- `testWidgets` 体内不要 await 真 IO(dart:io / Isar 会挂 10 分钟),初始化收进 `setUp` 或 `tester.runAsync`

### 2.5 决策分级——🔴 一律停下问用户

| 级 | 范围 | 处置 |
|---|---|---|
| 🟢 | 路径纠正 / 假阳性过滤 / 只读审计 | 自己决定 |
| 🟡 | 新增审计方向 / 范围增减 >30% | 可做可写方案,**不得合并** |
| 🔴 | **玩家可见 UI** / 数值与成长规则 / schema / 删配置字段 | **停在 `[BLOCKED]` 等用户拍板** |

**本包里 B、C、D2 全是 🔴**——你可以出方案、做对比、写原型,但**视觉方向必须用户拍**。

---

## §3 任务清单(约 12 小时)

> 顺序建议:批一先做(不需要拍板,可以边做边等用户回复批二的方案),批二拿到拍板后实装,批三收尾。

### 批一 · 纯 bug 修复(约 3.5h,不需要拍板)

#### 任务 1.1 — 图层排序 key 与渲染 key 不同源(约 1h)

**现象**(用户实测):「人物图标和敌人图标会有重叠,有时候人物在敌人图层下方,有时候会在表层」。

**【S 未复核】已查到的事实**:
- 排序函数 `lib/features/battle/presentation/phase0a/phase0a_stage.dart:73-83` `sortActors()`,按世界 y 升序、y 相同按 id 字典序
- 摆进 Stack:`phase0a_battle_screen.dart:675-685`
- **病根**:排序用的是**领域逻辑 y**,而屏幕位置是 `AnimatedPositioned` 在一个 tick 内线性插值的(`phase0a_battle_screen.dart:712-720`,duration = `controller.fixedDeltaSeconds`)。
  → 图层可能在两个精灵**脚底线视觉上还没交叉**时就提前一个 tick 翻转

**做什么**:让排序 key 与渲染 key 同源(用插值后的实际渲染 y 排序,而不是领域 y)。

**不要做**:不要加阵营偏置、迟滞、「玩家恒在最上层」——那些是 D2,属 🔴,在批二。

**验收**:补测试断言 Stack 里 actor widget 的实际先后顺序。
**注意**:全仓现在**没有任何测试断言实际绘制顺序**(只有纯函数级 `test/features/battle/presentation/phase0a/phase0a_stage_transform_test.dart:96-116`)。所以这条测试是新增的,必须做破坏证红。

#### 任务 1.2 — 「需疗养」横幅口径宽于准入口径(约 45min)

**【S 未复核】**:主菜单横幅 `lib/features/main_menu/application/main_menu_status_summary_provider.dart:131-155` 把
`injuryHoursRemaining > 0 || lightInjuryStacks > 0 || innerBreathDisorderHoursRemaining > 0` 三种都算作「需疗养」;
但战斗准入**只看** `injuryHoursRemaining > 0`(重伤),见 `lib/features/mainline/application/mainline_participant_snapshot_service.dart:141-155`。

→ 横幅数字**高估被封人数**,直接误导玩家(用户实测已被误导)。

**做什么**:统一口径。**注意文案在 `lib/shared/strings.dart`(禁区)**——如果修复需要改文案,**停下问用户**,不要自己改。
优先选**不改文案**的解法(比如横幅只统计真正阻断出战的那一类)。

#### 任务 1.3 — 注释写反(约 10min)

**【S 未复核】**:`phase0a_stage.dart:73` 的 doc comment 写「近处先画、远处后画」,
但代码是 y 小的先画 = 远的先画。**代码对、注释错**。订正注释。

#### 任务 1.4 — 同类短路核查(约 45min)

**【C 已验】**:`phase0a_battle_screen.dart` 里除了防御那处短路,还有一处
`if (source == null || target == null || targetId == null) { ... }`(main 上约 `:1738`,**行号要重新定位**)。

**做什么**:核一遍有没有哪个 vfx kind 也恒不满足条件、因而**恒不渲染**。
判据:对每个走该分支的 kind,回到 `phase0a_vfx_controller.dart` 看它构造时是否设了所需字段。
发现同类问题 → **写进交付说明**,并问用户是否要一并修。

#### 任务 1.5 — N14 弱支点断言(约 30min)

`test/features/mainline/application/phase2_same_core_reward_evidence_test.dart` 第 2 组里有一条**同义反复**断言:
bot 产出 `commands` 列表 → manualController 回放**同一个列表** → 再断言两者的 `commandSummaries` 相等。
**这条断言不可能失败**,没有守卫价值。

**做什么**:改成有守卫价值的断言(比如断言「manual 回放未提前 break」),或直接删掉那一行。
**不要**为了让它「看起来在测东西」而保留。

---

### 批二 · 表现层三项(约 5h,**必须先拿用户拍板**)

> 这三项是当前 G2 真人试玩**卡死的根**。用户实测原话:
> 「技能和护盾没有表现形式,没有特效,察觉不了,但是我看 CD 信息有显示」
> 「破势我没有感知到存在」
>
> **结构性结论**:posture 五值(`capacity: 14` / `vulnerability_ticks: 4` 等)现在**没法通过真人试玩定标**,
> 因为玩家感受不到阈值和窗口在哪。**表现层没到位之前,数值试玩的前提不成立。**
>
> 项目产品原则(memory `feedback_wuxia_combat_satisfaction_principle`):
> **战斗爽感 = 参与感 + 即时打击,走表现层不走数值膨胀。** 这三项正落在这条原则上。

**工作方式**:每项先给用户 **2–3 个方案对比**(一句话大白话 + 代价 + 推荐项),拍板后再实装。
**禁止代拍。** 禁止发明美术资产。

#### 任务 2.1 — B:技能 1-6 完全没有施法特效(约 2h)

**【C 已验】的事实**:
- `Phase0aVfxKind` 枚举里**根本没有技能类特效**。对照:普攻有 `meleeSlash`(双弧墨痕)/ `palmTrail`(掌风),`Q` 有 `gatherVortex` + `gatherPull`,`R` 有 `clearBurst`(径向墨爆),击杀有 `defeatInk`
- `phase0a_vfx_controller.dart` 里 `case Phase0aSkillStarted():` → 直接 `break`,零特效
- `case Phase0aSkillApplied():` → 只推**伤害飘字**(damagePopup)

→ 按 1-6 和普攻在画面上唯一区别就是伤害数字大小。

**要问用户的**:技能特效做成什么样?给方案,例如:
- 方案 A:复用已有墨系语言(按流派刚猛/灵巧/阴柔分三套),成本低、风格统一
- 方案 B:每个技能独立特效,成本高
- 方案 C:先只做「起手 + 命中」两段通用反馈,不区分技能

#### 任务 2.2 — C:破势几乎没有感知通道(约 2h)

**【C 已验】的事实** —— 破势的全部反馈只有两样:
1. 敌人头顶一个 **12px 文字标签**(`_BossStatusTag`,`phase0a_presentation_tokens.dart` 里 `bossStatusFontSize = 12`、`bossStatusGap = 4`),显示 `7/14` 倒数,开窗变「破绽 · 全力」
2. 开窗瞬间一条屏幕横幅,停留 **0.9 秒**(`bossInterruptFeedbackSeconds = 0.9`)

**没有的**:累积过程零视觉反馈(累积时不推任何 vfx,只有开窗那一下)、没有蓄条只有数字、敌人本身没有任何「失衡/踉跄」形态变化。

**还有一处文案撞车**【C 已验】:开窗横幅那句是 `UiStrings.phase0aBossChargeInterrupted = '破！'`——
它**本来是「破招成功」的文案,被复用给破势开窗了**。玩家无法区分刚才那下是打断了蓄力还是打出了破绽。

**要问用户的**:破势该怎么表现?给方案,例如:
- 方案 A:敌人本体状态化(描边/变色/姿态倾斜)+ 独立文案,最直观
- 方案 B:头顶换成蓄条(替代数字)
- 方案 C:A+B 都做

**注意**:改文案要动 `lib/shared/strings.dart`(禁区)——拿到用户拍板后,**让用户改或明确授权你改**。

#### 任务 2.3 — D2:图层无 z 稳定机制(约 1h)

**【S 未复核】**:玩家和敌人在 2D 场上互相穿插,y 一交叉图层就整个互换。
- 玩家出生在 `y=0`(`phase0a_stage_content_mapper.dart:109`)
- 敌人按 slot 铺满整个纵深(`:790-800`)→ **2 只敌人时必然一只在你上层、一只在你下层**
- 敌人 AI 有绕侧策略 `lateralFlank`(`phase0a_enemy_ai_adapter.dart:140-147`),反复横穿玩家 y → 每穿一次翻一次

**要问用户的**:要不要加 z 稳定?方案例如:
- 方案 A:交叉迟滞(hysteresis)——y 差超过阈值才翻转,消除抖动
- 方案 B:玩家恒定在最上层(牺牲纵深真实感,换稳定)
- 方案 C:阵营偏置(同 y 时玩家优先在上)
- 方案 D:不改,y-sort 本来就该这样

---

### 批三 · 测试反模式清账(约 2.5h)

> **这是本包价值最高的一项。** 起因:防御特效功能 **100% 坏了**(零像素输出),
> 而它的测试 `test/features/battle/presentation/phase0a/phase0a_defense_presentation_test.dart` 一直是绿的——
> 因为它只断言**控制器产出了条目**和音效映射,**从不渲染任何 widget**。
>
> 这不是孤例,是一类系统性假绿。项目 memory 里有专门条目
> (`feedback_test_bypasses_production_path`:测试绕开生产路径是假绿最高发入口)。

**做什么**:

1. 扫 `test/features/**/presentation/**`,找出所有「只调 controller/service 拿返回值断言,从不 `pumpWidget`」的表现层测试
2. 对每一条,回答一个问题:**「把它声称在测的那个功能彻底破坏掉(比如让渲染函数直接 return SizedBox.shrink()),这条测试会红吗?」**
3. 会红 → 合格,跳过。不会红 → **记入清单**,写明:测试 `file:line`、它声称测什么、实际断言到哪一层、破坏什么它不会红
4. 产出审计报告 `docs/audit/test_antipattern_presentation_layer_<日期>.md`
5. **本批只出报告不批量改**(改动面可能很大,要用户决定优先级)

**已知的两条实例**(可作为样例):
- 【C 已验】`phase0a_defense_presentation_test.dart` —— 断言停在 `Phase0aVfxController().consume()`,从不渲染
- 【C 已验】键盘防御绑定 `E`/`F`/`Z` **零测试覆盖**(`grep -rn "LogicalKeyboardKey.key[EFZ]" test/` 零命中,对照 W/A/D/J/Q 都有测)

---

### 批四 · 收口(约 1h)

1. 每个分支跑 `flutter analyze`(0 issue)+ targeted 测试 + `dart format`
2. 批末跑一次全量 `flutter test --no-pub`
3. 每个分支工作区干净、tip 打好 `[READY]` / `[BLOCKED]`
4. 写 handoff:`docs/handoff/<日期>_codex_closeout.md`,**≤80 行**
5. **不要合并任何分支到 main,不要 push**——合并由用户或协调者做

---

## §4 挂着等用户拍板的事(不在工作量内,但你可以帮用户推进)

| # | 事项 | 卡在哪 |
|---|---|---|
| 1 | `forbidden_files: data/numbers.yaml` 豁免与否 | 集成分支 Gate 的 4 条 FAIL 之一。posture 五值是协调者自己写的(不是执行端越界),且正是试玩要验的靶子。选项:A 豁免并重跑 Gate / B 摘出走单独数值流程 / C 先试玩再定。Claude 倾向 C |
| 2 | 攻击令牌 T2 候选 `2/1/1/0` | 用户已裁决:**保留为独立候选,不并入当前 G2,也不永久否决**。分支 `codex/p2-token-candidate-rerun-20260826`,`[BLOCKED]`。日后需要时做真人 A/B |
| 3 | registry 语义错位 | `docs/dispatch/phase0a_overhaul/decision_registry.yaml` 里 `selected_candidate: A` 仍顶着 B 的 `chosen_because: 群敌参与率 +9.75...`。**建议并到试玩结束后那一笔改**(单独改会让集成分支已跑的 Gate 失效) |
| 4 | 掌门重伤 → 主线首通链整条锁死 | 【S 未复核】主线首通/扫荡**硬绑定当前掌门**且合同明写「不回退掌门」。这是**冻结决议的后果不是 bug**,要改属于改决议 |
| 5 | N8 CLAUDE.md 文档漂移 | 分支 `codex/p2-claudemd-drift-20260826` `[BLOCKED]` |
| 6 | N15 两项发现 | 生产路径没有特效密度设置;群战 24 是波次总量而非同屏活跃数 |

---

## §5 用户正在做的事

用户在 `挂机武侠-p2-integration` worktree 上跑真人试玩(app 已构建好,`open build/macos/Build/Products/Debug/wuxia_idle.app`)。
八项验收表在 `docs/audit/phase2_g2_human_ready_candidate_20260827.md:11-22`(**只在集成分支上有**),当前 8 项全 `BLOCKED`。

**已经出结论的**:第 4 项(护盾/化解/闪避各有真实用途)= **REWORK**,原因是渲染缺陷不是手感问题。

**第 5 项要去 `stage_01_05` 风雨渡口打**(`test/support/phase2_g2_acceptance_harness.dart` 明写 `stage_01_03` 是非 Boss 伏击关、不承担该项)。

试玩键位:移动 `WASD` / 普攻 `J`(或鼠标左键按住)/ 护盾 `E` / 招架 `F` / 闪避 `Z` / 聚怪 `Q` / 破招 `R` / 技能 `1-6` / 暂停 `Esc`。
**`docs/phase0/phase0a-playtest-keycard.md` 已过期别用**(那份写 `Space`=身法,当前代码没有 Space)。
