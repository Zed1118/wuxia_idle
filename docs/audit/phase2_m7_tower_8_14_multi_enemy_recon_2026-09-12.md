# 九霄塔 8–14 层多敌结构侦察与迁层前缺口

日期：2026-09-12。范围：只侦察；保留诊断测试和证据，不迁层、不修改生产代码。

## 结论与基线

**8–14 层都是一波、全员初始在场；typed 都是一个 `tower_N_defeat_all` clause，内部集合覆盖该层全部敌人。** 多敌增加的是同波 actor 数、部分击杀中间态和并发出招，不增加 legacy 波数，也不启用 typed 后备补兵/入场预警。当前固定样本的 60 组两路对照全部完成，逐拍状态、战斗事件和结算一致；本次未检出 8–14 层由路由切换引起的行为漂移。这不等于下一批已获迁层授权。

| 核对项 | 实际状态 |
|---|---|
| 源分支 | `codex/p2-player-flow-20260910` |
| 侦察基线 | `0ec23aa0fefcab5f37109216552edcd48b552350` |
| 与提示中的 a48 差异 | `a48aab668d5fbf631c94a06e1a00baa41244de8b` 在开局尚未并入；交付核对时源分支已由其他执行链前进到 a48。两者只差现有平价测试，生产源码相同。本侦察固定在 0ec，并独立重放 a48 测试；本任务未执行任何合并。 |
| 独立分支 | `codex/tower-multi-recon-20260912` |
| 独立 worktree | `/Users/a10506/.codex/worktrees/tower-multi-recon-20260912/挂机武侠` |
| main | `342d1927529b8306582431be597ef1975bd69deb`，保持不变 |
| 生产迁层集合 | `{1,2,3,4,5,6,7}`，保持不变；`lib/features/tower/application/phase0a_tower_encounter_host.dart:39` |
| 闸门 | `review_gaps_block_floor_migration: false`，保持原值；同处还有 `next_batch_floor_migration_requires_user_signoff: true`，不能把 false 解释为本批获准。`docs/dispatch/phase0a_overhaul/task_registry.yaml:8136`、`:8139` |
| 主 checkout 用户内容 | `AGENTS.md`、`CLAUDE.md`、`.qoder/settings.json`、冻结归档的前后 SHA-256 一致；校验记录见 verification.txt。 |
| 保留项 | locked `.claude/worktrees/review-followup-20260912` 及其分支保持原样；未合并、push、force-push、启动真实应用或访问真实存档。 |

CodeGraph 查询返回项目未初始化，未创建索引；采用源码定位和公开运行时 getter。已读当前项目规则及已否任务清单；本报告的建议仅覆盖已指定的塔层侦察范围。

## 方法、产物与复跑

- [诊断探针](../../test/diagnostics/phase0a_tower_multi_enemy_recon_test.dart)：只经真实 `createFreshPhase0aTowerCombatSession` 构造两条路线；typed 使用测试注入 `{floorIndex}`，legacy 使用空集合。双方同 seed、同一逐拍输入。每拍比较完整 actor/state、除波次生命周期外的全部战斗事件 payload，终局比较结算；只归一化波次造成的 seq 偏移与 guardian 源 ID/运行时 ID 表示差异。
- [a48 clause 断言负对照](../../test/diagnostics/phase0a_tower_a48_clause_guard_recon_test.dart)：保留 a48 helper 的断言逻辑，以测试定义注入改名/拆条变体，量它是否会拦截结构变化。变体不是生产塔数据。
- [原始输出 JSONL](evidence/tower_8_14_recon_2026-09-12/probe.jsonl)：逐行对应 stdout 的 `TOWER_RECON` 记录，仅去掉该固定前缀，字段和值不变。下文 `probe.jsonl:L24` 表示该文件第 24 行。
- [完整测量摘要](evidence/tower_8_14_recon_2026-09-12/summary.txt)、[命令、结果与完整性校验](evidence/tower_8_14_recon_2026-09-12/verification.txt)。两个诊断测试保留用于复跑；a48 整份平价测试的临时复制件执行后已丢弃。

`test/diagnostics/phase0a_tower_multi_enemy_recon_test.dart:64` 定义样本矩阵；`:99` 定义 seed/玩家 fixture；`:111` 调用真实工厂。固定步长 `0.1s`，最多 `3000 ticks`，来自实际 numbers 加载输出（JSONL 第 1 行）。这是一致性测量，不是适级难度或真人体验测量。

| profile | 范围 × 周目 1/2 | 输入与目的 |
|---|---|---|
| bot | 1、8–14、32、42、49，共 22 对 | 高耐久固定玩家与生产 bot；记录真实胜负，不把高层胜利写成所有样本的前提。 |
| singleTarget | 8–14，共 14 对 | 普攻瞄准当前第一名存活敌人，不发聚怪/清场技能；量部分击杀中间态。 |
| pressure | 8–14，共 14 对 | 前 600 tick 停手，随后生产 bot 收场；量多敌真实出招与 11/C2 蓄力。 |
| defeat | 8、11、14，共 6 对 | 玩家 fixture HP=1，停手至败；量目标未完成、legacy 尚未清波。 |
| bossMechanics | 11、14，共 4 对 | 三流玩家、装备攻击 130，普攻且蓄力期间停攻；量 14 两个相位和两次蓄力开始。 |

实际验证输出：

```text
基线 entrypoint parity: 00:20 +29: All tests passed!
a48 临时重放 parity: 00:16 +29: All tests passed!
固定样本诊断: 00:01 +61: All tests passed!
a48 clause 负对照: 00:00 +2: All tests passed!
dart analyze 两个保留诊断文件: No issues found!
```

61 项是 1 项库存核对 + 60 组路线对照，包含 52 组胜利和 8 组战败。初轮的 49/C1、49/C2 因探针强制胜利而失败，实际均是两路一致的战败；修正了诊断前提，没有调整玩家/敌人来刷绿。最终仍记录它们分别在 tick 311、292 战败（JSONL 第 22–23 行）。全部结果属于本 worktree 的定向验证；未跑全量 CI、Windows 或真人验收。

复跑保留的诊断：

```bash
cd "/Users/a10506/.codex/worktrees/tower-multi-recon-20260912/挂机武侠"
flutter test --no-pub --reporter expanded test/diagnostics/phase0a_tower_multi_enemy_recon_test.dart
flutter test --no-pub --reporter expanded test/diagnostics/phase0a_tower_a48_clause_guard_recon_test.dart
```

新 worktree 的环境准备为 `flutter pub get --offline`、`dart run build_runner build`；只生成被忽略的构建前置文件，受版本控制的 `lib/` 内容无变化。运行时为 Flutter 3.41.5 / Dart 3.11.3。

## 问题 1：legacy 如何切波次

**第 8 层两敌和第 14 层三敌均只产生 1 个 WaveStarted；胜利时均只产生 1 个 WaveCleared。** 战败样本只 started、不 cleared。第 1 层单敌的成功样本也是 1/1。

源码因果链：

1. `lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart:569` 的 `mapTower` 将整个 `floor.enemyTeam` 传入 `_mapContent`，没有传多波 override。
2. 同文件 `:643` 将 `assembleAll(enemyTeam)` 包成只有一个元素的 `enemySnapshotWaves`。`phase0a_tower_encounter_host.dart:369` 经该 mapper 创建 legacy session。
3. `lib/features/battle/application/phase0a/phase0a_wave_battle_flow.dart:137` 首次 advance 发 `WaveStarted(waveIndex=1,waveTotal=1)`；`:150` 先处理玩家死亡；`:161` 仅在所有敌人移除后发 clear，再在 `:172` 发 victory。

以下采用 singleTarget profile，1 层为 bot 对照；表内时点是实测 tick，不能跨 profile 混用：

| 层 | 敌人数 | C1/C2 WaveStarted 数 | C1/C2 WaveCleared 数 | C1/C2 最后一敌死亡 = clear = victory tick | 证据 |
|---|---:|---|---|---|---|
| 1 | 1 | 1 / 1 | 1 / 1 | 1 / 1 | JSONL L2–3 |
| 8 | 2 | 1 / 1 | 1 / 1 | 13 / 19 | L24–25 |
| 9 | 2 | 1 / 1 | 1 / 1 | 13 / 13 | L26–27 |
| 10 | 2 | 1 / 1 | 1 / 1 | 13 / 13 | L28–29 |
| 11 | 1 | 1 / 1 | 1 / 1 | 7 / 13 | L30–31 |
| 12 | 2 | 1 / 1 | 1 / 1 | 13 / 19 | L32–33 |
| 13 | 2 | 1 / 1 | 1 / 1 | 19 / 19 | L34–35 |
| 14 | 3 | 1 / 1 | 1 / 1 | 25 / 31 | L36–37 |

全部 start tick 均为 1，waveIndex/waveTotal 均为 1。8、11、14 的六组战败测得 `started=1, cleared=0`（L52–57）。探针固定了最后击杀 → clear → victory 的同拍顺序及 seq 先后，见诊断测试 `:323`、`:339`。

结构差异在 actor 身份和同波 roster：legacy 的单敌 ID 直接使用源 ID，多敌 ID 为 `${enemyDefId}_w0s${slot}`，见 mapper `:689`；typed 同规则见 tower host `:445`。例如第 8 层为 `enemy_tower_08a_w0s0`、`enemy_tower_08b_w0s1`。多敌不会触发波间回复、下一波生成或 waveTotal 增大。

## 问题 2：typed objectiveProgress 与完成时点

**8–14 的默认派生定义仍是一条 clause；每层只有一个 defeat-all，目标集合含该层全部 entry ID。**

- clause：`tower_${floorIndex}_defeat_all`，楼层数字不补零。
- entry：`tower_${floorIndex}_entry_${slot.padLeft(3,'0')}`，slot 从 `000` 开始。
- primitive：`CombatDefeatTargetsRef(entryIds)`；composition：`all`。
- 直接定义证据：`lib/features/tower/application/phase0a_tower_encounter_host.dart:83`、`:113`。
- 公开进度见 `lib/features/battle/application/phase0a/phase0a_encounter_flow.dart:128`；无需新增生产接口。

实际进度的字段投影如下，数据来自 JSONL L24 / L36，完整记录见文末原始输出：

```text
8/C1 singleTarget:
 tick  0: clause=tower_8_defeat_all,  satisfied=[],                     completed=false, active=2, legacy=0/0
 tick  1: clause=tower_8_defeat_all,  satisfied=[],                     completed=false, active=2, legacy=1/0
 tick  7: clause=tower_8_defeat_all,  satisfied=[tower_8_entry_000],    completed=false, active=1, legacy=1/0
 tick 13: clause=tower_8_defeat_all,  satisfied=[entry_000,entry_001],  completed=true,  active=0, legacy=1/1

14/C1 singleTarget（下列 entry 前缀均为 tower_14_）:
 tick  0: clause=tower_14_defeat_all, satisfied=[],                    completed=false, active=3, legacy=0/0
 tick 13: clause=tower_14_defeat_all, satisfied=[entry_000],           completed=false, active=2, legacy=1/0
 tick 19: clause=tower_14_defeat_all, satisfied=[entry_000,entry_001], completed=false, active=1, legacy=1/0
 tick 25: clause=tower_14_defeat_all, satisfied=[entry_000,entry_001,entry_002], completed=true, active=0, legacy=1/1
```

14/C1 的首个死亡是主 Boss（tick 13），但两护卫存活时目标不完成；bot/pressure 样本也测到先杀护卫、最后杀 Boss 的相反顺序（L16、L50–51）。目标不依赖 Boss 身份，不是 defeat-commander。

`progress.clauses.single.progress.satisfied` 存的是 **entry ID**，不是 actor ID；同对象还包含 `processedEventIds` 和 `elapsed`。L24 终局 `elapsedUs=0`，processed event 记录包括 `targetDefeated:phase0a:defeat:7:4:0` 等。这是击败型目标，非计时目标。

生产路径由实际 `Phase0aEnemyDefeated` 投影为 `TargetDefeated`（`lib/features/battle/application/phase0a/phase0a_explicit_objective_event_source.dart:76`），逐个累积 satisfied，全目标数量到齐才完成（`lib/features/battle/domain/phase0a/encounter_objective.dart:227`）。同拍先 markExited，再准备目标进度、生成 victory、提交进度/director/outcome（encounter flow `:314`、`:343`、`:405`）。

**本次全部测量中，首次 advance 后 `completed ⇔ started>0 && cleared==started`，成功样本的末敌死亡、目标完成、legacy clear、双方 victory 同拍。** 初始化 tick 0 例外：started=cleared=0，而 completed=false；直接拿 `0==0` 当清场结论错误。诊断测试 `:174` 单独处理此边界，`:190` 每拍核对 satisfied 与已移除 entry 集，并强制多敌 singleTarget 存在未完成的部分击杀帧。

玩家死亡优先于目标提交（encounter flow `:331`），六组定向败局 completed=false。**双方同拍全灭的边界未量到**：本次败局均未同时杀光敌人，不能以这些样本替代该边界验证。

`checkpointObjectiveObservation` 为 null 的实际原因仍是 `checkpoints.isEmpty`（encounter flow `:145`），并非没有 tracker/director。四种专用 observation 在 8–14 两路对照中的 typed 侧都为 null；`objectiveProgress` 与 `spawnState` 同时非空且被每拍读取，见诊断测试 `:146`、`:168`。

## 问题 3：SpawnDirector 与 AttackToken 是否真正参与

### SpawnDirector

直接读取的是 `Phase0aEncounterFlow.spawnState`，getter 在 `phase0a_encounter_flow.dart:239`。

| 楼层 | pending 最大值 | warning 最大值 | active 初始/最大值 | 成功终局 active / removed | grace 最大值 |
|---|---:|---:|---:|---|---:|
| 1、11 | 0 | 0 | 1 | 0 / 1 | 0 |
| 8、9、10、12、13 | 0 | 0 | 2 | 0 / 2 | 0 |
| 14 | 0 | 0 | 3 | 0 / 3 | 0 |

所有 profile、两周目结果一致；详见 JSONL L2–61 的 maxima/transitions。单敌阶段 director 的 active 本来也非零；多敌扩大了实际活动集合。多敌中间态的 active 2→1→0、3→2→1→0 和 removed 累增均已实测。

原因：tower host `:89` 设置 activeLimit 为敌人数、warning/grace/threshold 为零；`:597` 指定 `startWithAllEntriesActive:true`。`lib/data/validation/combat_encounter_runtime_contract_mapper.dart:53` 选用 `SpawnDirector.allActive`；`lib/features/battle/domain/phase0a/spawn_director.dart:300` 将所有 entry 初始化为 active、enteredTick=0、grace=0。每拍 director 仍执行、死亡仍更新 roster，见 encounter flow `:272`、`:314`。

**后备补兵、预警排队、延迟入场未量到；本次真实塔配置根本不走这些分支。** 不能用多敌计数充当动态 spawn 覆盖率，也没有证据要求在等价迁层中新增这些行为。

### AttackToken

- typed 组装了 stateless `AttackTokenEnforcingBatchGate`（`lib/features/battle/application/phase0a/phase0a_production_flow_assembler.dart:247`）。tower host `:621` 的 mapper 始终返回 null。
- null 的精确语义是“不加入 token request，原 intent 保序放行”，见 `lib/features/battle/application/phase0a/attack_token_enforcing_batch_gate.dart:43`、`:58`。配置里的 melee budget 与 `tokensByActor` 元数据不会自行把 intent 变为请求。
- legacy 组装普通 session，未加该 token gate（production flow assembler `:88`）。两路都消费逐个遍历存活敌人的既有 AI（`lib/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart:49`）。

实测 pressure profile 的同拍敌方出招人数最大值：五个双敌普通层均为 **2**；14 层两周目均测到 **2**。11 单敌为 1。统计对象是敌方 `AttackStarted / EnemySkillStarted / BossChargeStarted` 的同 tick 去重 actor 集，源码在诊断测试 `:378`；它不是“同时命中的伤害数”。

```text
8/C1 pressure:  firstSimultaneousEnemyAttack={tick:37, actors:[enemy_tower_08a_w0s0,enemy_tower_08b_w0s1]}
14/C2 pressure: firstSimultaneousEnemyAttack={tick:37, actors:[enemy_tower_14_guard_b_w0s2,enemy_tower_boss_14_w0s0]}
8–14 全部 pressure 对照: statesAndCombatAndSettlementEqual=true
```

原值见 JSONL L38、L51；每拍全部事件与状态都与 legacy 比较，不是只比较出招总数。**null mapper 在已测多敌样本中没有造成行为漂移；它保留了既有并发攻击。** 将它改成非 null 节流会改变现有合同，不能作为这次迁层的默认“修复”。

`lastAttackTokenLeaseBatchReceipt` 每帧为 null（`leaseReceiptFrames=0`）。tower 用的是 stateless gate，本次未注入 lease runtime；因此 JSONL 中 `leaseActive/leaseMutations=null`，不是把不可采样值冒充零。内部 `allocate()` 调用次数、请求/拒绝计数**未量到**：没有对这些内部调用埋点；“输入请求集合为空”的判断来自上述 mapper/gate 源码。三个敌人同拍出招也**未量到**，本次 14 层样本峰值为 2。

## 问题 4：11、14 与纯多敌层的差异及首个目标

| 维度 | 8/9/10/12/13 | 11 | 14 |
|---|---|---|---|
| enemyTeam / bossKind | 双普通敌 / null | 单 Boss / minor | Boss + 两普通护卫 / major |
| actor ID 结构 | `_w0s0/_w0s1` | 源 ID，不加 slot 后缀 | `_w0s0/_w0s1/_w0s2` |
| 波数 / clause 数 | 1 / 1 | 1 / 1 | 1 / 1 |
| 第一周目阶段机制 | 无配置 | 无 authored phase/charge | phase 阈值 1.0/.65/.35；两次 chargeCounter |
| 第二周目 | 按每名普通敌取 tower_normal 词条 | Boss 词条注入识破蓄力 `skill_qingshan_qingfeng` | 阈值改为 1.0/.80/.45；Boss 取 tower_boss，护卫取 tower_normal |
| Boss 专属承伤表 | 无 | 无 | 灵巧 1.25、阴柔 .75 |
| 机制护法 | 无 | 无 | 两护卫都无 ward/interception 配置，不等于 42 层机制护法 |

配置证据：`data/towers.yaml:268`、`:303`、`:336`、`:373`、`:408`、`:441`、`:478`；14 承伤/phase/cycle phase/护卫分别在 `:501`、`:504`、`:518`、`:533`。词条分配在 `data/numbers.yaml:2190`；按 **enemy.isBoss** 选表在 `lib/data/numbers_config.dart:3677`；注入 shipo charge 在 `lib/shared/battle_shared/enemy_combatant_snapshot_assembler.dart:164`。

实测补充（JSONL L44–45、L60–61）：

| 样本 | phase 事件 | charge-start 事件 | 可下的结论 |
|---|---:|---:|---|
| 11/C1 pressure | 0 | 0 | 该样本未产生蓄力 |
| 11/C2 pressure | 0 | 13 | C2 注入的 Boss 蓄力实际进入运行路径 |
| 14/C1 bossMechanics | 2 | 2 | phase 1/2 分别在 tick 7/13；对应两种方系 skill/ult 蓄力都开始 |
| 14/C2 bossMechanics | 2 | 2 | 同样进入 phase 1/2 和两种蓄力；snapshot 阈值实测 .80/.45 |

14 的这两个 bossMechanics 样本 `bossHits=[]`，但不能把该空结果外推到所有样本。**14/C2 的 phase 2 已测到真实命中**：bot 在 tick 7 开始 `skill_gangmeng_changlian_fang_ult` 蓄力，tick 10 发出相同 skillId 的 `EnemySkillStarted` 并造成 heavy 伤害 22（L17）；pressure 在 tick 607→610 重现相同 skillId 和伤害 22（L51）。原始 `bossSkillStarts`、`bossHits` 给出精确技能/actor/tick 关联；蓄力倒计时归零、按当前 cast 释放并落 heavy 伤害的源码分别为 `lib/features/battle/domain/phase0a/phase0a_combat_reducer.dart:324`、`:1816`、`:1866`。

**14/C1 各相位及 C2 phase 1 的相位蓄力命中未量到**：这些样本有开始事件，但没有对应技能释放/命中输出。本次只能记为部分消费证据，不能写成完整机制验收。快速 bot 的 14/C1 只出现 1 次 phase/charge（L16），说明只看快速平价终局会漏掉第二次机制。

```text
14/C2 bot: phase2 charge tick=7 skill=skill_gangmeng_changlian_fang_ult chargeTicks=3
           EnemySkillStarted tick=10 same skill; HitLanded tick=10 heavy damage=22
14/C2 pressure: phase2 charge tick=607; EnemySkillStarted + HitLanded tick=610 heavy damage=22
```

外围 bossKind 还关联 Boss 战绩、hard-fight 伤势处理、major 首胜镜头，分别见 `lib/features/tower/presentation/tower_entry_flow.dart:324`、`:788`、`:1009`。本次未跑 8–14 完整首通 UI/奖励持久化，不把 factory 的结算 snapshot 一致性扩展成这些外围已验收。

**下一批首个目标推荐第 8 层。** 它是首次从单敌进入双敌 slot ID、部分击杀、并发 AI 的实际内容；三项在本次都量到。11 单独开局仍是单敌，不能解决本次多敌证据需求。14 同时叠加三敌、Boss 身份、两个 phase 与周目差异，安排在批末集成验证。

## 问题 5：现有平价断言的失效与空操作

先纠正路由前提：`test/features/tower/application/phase0a_tower_entrypoint_parity_test.dart:109` 的列表确实含 14/32/42/49；但 `_FactoryTrace :710` 对 >7 显式注入该层 typed，并在 `:135` 另建 legacy。它们已有测试内 typed↔legacy 对照。**生产默认路由保持 legacy，不等于这些测试只跑 legacy。** 本次基线和 a48 临时重放均为 29/29 通过。

| 断言/覆盖点 | 实际问题与影响 | 证据 |
|---|---|---|
| 基线目标 helper | 0ec 仍留“目标不可观察、没有 director”的错误说明，未直接读 objectiveProgress。a48 已修正读取，交付核对时已进入源分支；本 worktree 仍固定为开局 0ec。 | 现有 parity `:920`；公开 getter `phase0a_encounter_flow.dart:128`、`:239` |
| a48 clause ID/条数 | 只断言 clauses 非空、每个 ID 非空；改名和拆成两条都会通过。注释宣称“钉住”与实际断言不符。 | a48 原文件 `:957`；保留负对照测试 `:151`；JSONL L62–63 |
| 目标完成映射 | a48 在片段结束才比较 completed 与 starts/clears；未量部分击杀的 satisfied 集及每拍完成时点。单敌没有非空的部分集合。 | a48 `:967`；本次 8/C1 的 6 个部分击杀帧、14/C1 的 12 帧见 L24/L36 |
| 启动边界 | 把该映射照搬到 tick 0，`0==0` 会错误表示清场；原 helper 的 starts 非空断言则会先失败。 | 本次全部样本 `tickZeroZeroEqualsZeroButObjectiveFalse=true`；诊断测试 `:174` |
| 波次归一化 | `_combatEvents` 丢弃波次、nextSeq 清零本身仍有效；旧 helper 只约束有事件和 last clear ≤ victory，没固定唯一波/编号/末敌同拍顺序。 | 现有 parity `:906`、`:959`；本次加强诊断 `:323` |
| 快杀覆盖 | 同样绿色可来自两路都没让敌人出招。8/C1 bot tick 1 胜利，敌出招人数 0、部分帧 0；pressure 才真实出现两个敌人同拍出招。 | JSONL L4/L38；这两个 profile 是本次 fixture，不冒称为现有 entrypoint fixture 的计数。 |
| Spawn/Token 空结果 | pending/warning 始终 0，lease receipt 始终 null；相关空事件相等无法证明补兵、预警或 token 竞争。 | 全部 maxima；Q3 生产链 |
| 14 Boss 机制覆盖 | 现有专门要求机制出现的定向例针对 32/42；14 的入口对照没有必须出现两次 phase/charge 的守卫。 | 现有 parity `:291`、`:395`；本次 L16 与 L60 对比 |
| guardian 翻译 | 8–14 的 guardian ID 集为空，在这些层循环空列表不能证明护法映射；42 的既有机制对照另有实质覆盖。 | tower host `:453`；14 snapshots L60–61；现有 parity `:395` |
| 新层入口/持久化矩阵 | 8–13 没进入现有三入口矩阵；首批 receipt/关库重开守卫只覆盖 1–7。 | 现有 parity `:109`；`test/features/tower/application/phase0a_tower_first_batch_settlement_test.dart:73`、`:124`、`:154` |

以下两行是负对照的实际 stdout。它们证明 a48 helper 不识别形状变化，不表示这些变体已经进入生产：

```text
TOWER_RECON {"kind":"a48WeakGuard","variant":"renamed","floor":8,"clauseIds":["diagnostic_renamed"],"completed":true,"ticks":1,"a48HelperPassed":true}
TOWER_RECON {"kind":"a48WeakGuard","variant":"split","floor":8,"clauseIds":["diagnostic_split_0","diagnostic_split_1"],"completed":true,"ticks":1,"a48HelperPassed":true}
```

塔 host 对注入定义验证的是 defeat-target **并集**覆盖全 entry（`:347`–`:364`），并未禁止多个 clause。当前默认派生定义仍确定为单条；本次两个变体用于证明测试断言的检测能力，不能据此把通用合法 composition 定义成生产 bug。

## 迁 8–14 前的可执行缺口清单

“本次已有诊断证据”与“迁层候选已完成回归/外围验收”分开记。下表都是下一批同一 8–14 迁层候选中的工作，不拆成独立迁层批次。

| 编号 | 缺口 / 影响 | 必须补的动作与验收结果 | 判断依据 / 本次状态 |
|---|---|---|---|
| G1 | a48 已进入源分支，但形状守卫过弱，仍可能静默接受目标定义变化。 | 下一批候选保留 a48 的公开 getter 修正，并将默认派生定义的 clause 精确固定为一条 `tower_N_defeat_all`、全量 `tower_N_entry_000..`；负对照改名/拆条触发精确形状断言。 | Q5 两条 false-green 实测；本次保留诊断已固定默认 ID/条数，未修改原测试。 |
| G2 | 只看终局会漏部分击杀/错误提前完成；波次归一化隐藏生命周期错误。 | 将本次 8–14 两周目的逐拍诊断纳入迁层回归：对多敌 singleTarget 样本强制存在非空部分击杀帧；satisfied 与实际死亡对应 entry 集一致；玩家存活且全敌清除才完成；tick0 未完成；唯一 start/clear、waveIndex=waveTotal=1、最后死亡→clear→victory 同拍；败局无 clear/完成，终局后幂等。 | L24–37/L52–57 已量到；诊断 `:168`、`:323` 已作断言；仍需接入统一迁层候选。双方同拍全灭未量到，若对该边界宣称保全，另加直接运行证据。 |
| G3 | 新增多敌测试可能再次快速清场，根本未覆盖并发 AI；全 active 语义缺少明确常驻守卫。 | 保留双敌及三敌有至少两名敌人同 tick 实际出招的非空条件与完整两路轨迹比较；固定 tick0 active=N、pending/warning/grace=0、死亡后 active/removed 变化。保持 null mapper 的既有不节流行为。 | pressure 已测，诊断 `:393` 强制非空；不要求凭空新增 token 竞争或补兵。 |
| G4 | 11/C2、14 两周目的实际 Boss 机制未被原迁层断言完整覆盖；本次只补齐部分相位命中证据。 | 11/C2 保留识破蓄力实际触发；14/C1/C2 强制 phase 1/2、相应解锁技能与蓄力各出现，为 14/C1 的两个相位与 C2 phase 1 补真实命中；将已测 C2 phase 2 的 skillId/actor/tick/伤害关联改成强制断言，核对两路一致。不得仅以开始事件替代消费证据。 | L45 蓄力13次；L17/L51 已有 C2 phase 2 同技能命中22，L60–61 开始事件不伴命中。缺口限定为其余相位消费及全相位关联守卫。 |
| G5 | 8–13 三入口遗漏；直接 factory 一致性不能证明真实可见/即时挂机/关库重开入口遵守 authority、种子和归属。 | 将 8–14×两周目补入现有三入口矩阵，保留 1–7 和 32/42/49 回归；迁层后 factory 不再对 ≤14 暗中强制 typed，而是校验传入的生产 authority；legacy 对照继续显式空集合。 | parity `:109`、`:710`。14 已有 opt-in 三入口对照，不能写成它全无覆盖。 |
| G6 | 8–14 完整首通奖励/记录/receipt、重打幂等与 durable 重开未量到；Boss 外围和战斗 snapshot 不是同一验收范围。 | 扩展首批 settlement 测试到完整 8–14×两周目，核对首通、重打不重复授奖、参与者/层/周目归属、收据、关库重开；11/14 覆盖 bossKind 对应的生产外围，保留记录/奖励所有者。 | first_batch_settlement `:73`、`:124`、`:154` 只到7；tower_entry_flow `:324`、`:788`、`:1009`。本次未写此外围测试。 |
| G7 | 当前闸门值不能充当下一批用户授权。 | 向用户提交本报告、完整 8–14 候选范围和前述证据；只有用户决定下一批迁层及闸门状态，执行端保持原值直到收到该决定。 | task_registry `:8136`–`:8139`；本次没有翻转、迁层或改计数。 |

没有实测支持把“动态补兵、预警、新 AttackToken 节流、14 机制护法接线”列成 8–14 等价迁层的生产修复前置；这些在当前塔合同中不参与。也没有实测支持声称本批需要先改 `lib/` 才能跑通多敌两路对照。

## 下一批推荐范围与顺序

**推荐一个完整 8–14 批次，内部顺序：8 → 9、10、12、13 → 11 → 14。**

1. **8 先行建立多敌守卫**：实际两敌、slot ID、部分集合、同拍双敌出招均有证据，且不叠加 Boss 配置。
2. **收齐 9、10、12、13**：都是双敌，但流派、技能配对和速度不同；不能只测 8 再将剩余普通层排除。本次四层两周目均已取得逐拍/pressure 对照（Q1/Q3）。
3. **11 作为 Boss 对照**：单敌方便分离 Boss C2 识破与多敌变量；它仍包含在本批，不能把迁移范围缩成只迁 11。
4. **14 批末汇合**：三敌、Boss 先死/护卫先死、两相位及周目阈值变化都有本次证据；补 G4 命中消费和 G6 外围验证后，与 8–13 一同作为统一候选接受审核。

范围选择依据是实际结构差异，未以节省工作量缩减为一层。完成这个批次仍不能外推到 15–49、动态增援、攻击 token 竞争或正式 M7 关闭；本次仅提供证据与推荐顺序，不执行迁层决定。

## 原始探针输出摘录

以下两行直接取自 stdout 的 JSON 内容并还原固定前缀，未删字段；第 14 层更多 profile 与两周目完整记录见同目录 JSONL。

```text
TOWER_RECON {"kind":"probe","profile":"singleTarget","floor":8,"cycle":1,"seed":20260993,"enemies":2,"bossKind":null,"routes":["migrated","legacy"],"ticks":13,"outcome":"victory","statesAndCombatAndSettlementEqual":true,"tickZeroZeroEqualsZeroButObjectiveFalse":true,"legacyWaves":[{"event":"started","tick":1,"waveIndex":1,"waveTotal":1},{"event":"cleared","tick":13,"waveIndex":1}],"maxima":{"pending":0,"warning":0,"active":2,"grace":0,"leaseActive":null,"leaseMutations":null},"leaseReceiptFrames":0,"partialFrames":6,"maxSimultaneousEnemyAttackActors":0,"firstSimultaneousEnemyAttack":null,"eventCounts":{"Phase0aAttackStarted":3,"Phase0aHitLanded":2,"Phase0aEnemyDefeated":2,"Phase0aBattleVictory":1},"bossSnapshots":[],"bossSkillStarts":[],"bossHits":[],"bossEvents":[],"enemyDefeated":[{"tick":7,"target":"enemy_tower_08a_w0s0"},{"tick":13,"target":"enemy_tower_08b_w0s1"}],"transitions":[{"tick":0,"completed":false,"clauses":[{"id":"tower_8_defeat_all","completed":false,"satisfied":[],"processedEventIds":[],"elapsedUs":0}],"spawn":{"pending":0,"warning":0,"active":2,"removed":0},"legacyWaveStarted":0,"legacyWaveCleared":0,"outcome":"ongoing"},{"tick":1,"completed":false,"clauses":[{"id":"tower_8_defeat_all","completed":false,"satisfied":[],"processedEventIds":[],"elapsedUs":0}],"spawn":{"pending":0,"warning":0,"active":2,"removed":0},"legacyWaveStarted":1,"legacyWaveCleared":0,"outcome":"ongoing"},{"tick":7,"completed":false,"clauses":[{"id":"tower_8_defeat_all","completed":false,"satisfied":["tower_8_entry_000"],"processedEventIds":["targetDefeated:phase0a:defeat:7:4:0"],"elapsedUs":0}],"spawn":{"pending":0,"warning":0,"active":1,"removed":1},"legacyWaveStarted":1,"legacyWaveCleared":0,"outcome":"ongoing"},{"tick":13,"completed":true,"clauses":[{"id":"tower_8_defeat_all","completed":true,"satisfied":["tower_8_entry_000","tower_8_entry_001"],"processedEventIds":["targetDefeated:phase0a:defeat:13:7:0","targetDefeated:phase0a:defeat:7:4:0"],"elapsedUs":0}],"spawn":{"pending":0,"warning":0,"active":0,"removed":2},"legacyWaveStarted":1,"legacyWaveCleared":1,"outcome":"victory"}]}
TOWER_RECON {"kind":"probe","profile":"singleTarget","floor":14,"cycle":1,"seed":20261053,"enemies":3,"bossKind":"major","routes":["migrated","legacy"],"ticks":25,"outcome":"victory","statesAndCombatAndSettlementEqual":true,"tickZeroZeroEqualsZeroButObjectiveFalse":true,"legacyWaves":[{"event":"started","tick":1,"waveIndex":1,"waveTotal":1},{"event":"cleared","tick":25,"waveIndex":1}],"maxima":{"pending":0,"warning":0,"active":3,"grace":0,"leaseActive":null,"leaseMutations":null},"leaseReceiptFrames":0,"partialFrames":12,"maxSimultaneousEnemyAttackActors":1,"firstSimultaneousEnemyAttack":null,"eventCounts":{"Phase0aAttackStarted":5,"Phase0aHitLanded":4,"Phase0aPostureChanged":1,"Phase0aBossPhaseChanged":1,"Phase0aBossChargeStarted":1,"Phase0aEnemyDefeated":3,"Phase0aBattleVictory":1},"bossSnapshots":[{"actor":"enemy_tower_boss_14_w0s0","chargeSkillId":null,"guardianDefIds":[],"guardianWardMult":null,"guardInterceptsInterrupt":false,"phaseThresholds":[1.0,0.65,0.35],"schoolDamageTakenMult":{"lingQiao":1.25,"yinRou":0.75}}],"bossSkillStarts":[],"bossHits":[],"bossEvents":[{"kind":"phase","tick":7,"actor":"enemy_tower_boss_14_w0s0","phaseIndex":1,"unlocked":["skill_gangmeng_changlian_fang_skill"]},{"kind":"charge","tick":7,"actor":"enemy_tower_boss_14_w0s0","skillId":"skill_gangmeng_changlian_fang_skill","chargeTicks":3}],"enemyDefeated":[{"tick":13,"target":"enemy_tower_boss_14_w0s0"},{"tick":19,"target":"enemy_tower_14_guard_a_w0s1"},{"tick":25,"target":"enemy_tower_14_guard_b_w0s2"}],"transitions":[{"tick":0,"completed":false,"clauses":[{"id":"tower_14_defeat_all","completed":false,"satisfied":[],"processedEventIds":[],"elapsedUs":0}],"spawn":{"pending":0,"warning":0,"active":3,"removed":0},"legacyWaveStarted":0,"legacyWaveCleared":0,"outcome":"ongoing"},{"tick":1,"completed":false,"clauses":[{"id":"tower_14_defeat_all","completed":false,"satisfied":[],"processedEventIds":[],"elapsedUs":0}],"spawn":{"pending":0,"warning":0,"active":3,"removed":0},"legacyWaveStarted":1,"legacyWaveCleared":0,"outcome":"ongoing"},{"tick":13,"completed":false,"clauses":[{"id":"tower_14_defeat_all","completed":false,"satisfied":["tower_14_entry_000"],"processedEventIds":["targetDefeated:phase0a:defeat:13:9:0"],"elapsedUs":0}],"spawn":{"pending":0,"warning":0,"active":2,"removed":1},"legacyWaveStarted":1,"legacyWaveCleared":0,"outcome":"ongoing"},{"tick":19,"completed":false,"clauses":[{"id":"tower_14_defeat_all","completed":false,"satisfied":["tower_14_entry_000","tower_14_entry_001"],"processedEventIds":["targetDefeated:phase0a:defeat:13:9:0","targetDefeated:phase0a:defeat:19:12:0"],"elapsedUs":0}],"spawn":{"pending":0,"warning":0,"active":1,"removed":2},"legacyWaveStarted":1,"legacyWaveCleared":0,"outcome":"ongoing"},{"tick":25,"completed":true,"clauses":[{"id":"tower_14_defeat_all","completed":true,"satisfied":["tower_14_entry_000","tower_14_entry_001","tower_14_entry_002"],"processedEventIds":["targetDefeated:phase0a:defeat:13:9:0","targetDefeated:phase0a:defeat:19:12:0","targetDefeated:phase0a:defeat:25:15:0"],"elapsedUs":0}],"spawn":{"pending":0,"warning":0,"active":0,"removed":3},"legacyWaveStarted":1,"legacyWaveCleared":1,"outcome":"victory"}]}
```
