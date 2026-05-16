# W15 G 任务 · Pen-only T64 fail-fast 不抛 StateError 修救 closeout

> 2026-05-16 / Mac · opus 4.7 / 单会话顺手 30min / 2 commit(test fix + docs)/ 零回退
> 起源:P2(W15 #30 第 2 期消费层接入)收尾后下波 3 候选 G 任务

## 1. 起点与背景

W14 起 PROGRESS.md §已知偏差 #34 周边有一条遗留:Pen Codex 桌面跑 `flutter test` 时,`test/data/game_repository_test.dart` "T64 心法每本 3 招 type 分布:ult 被改成 normalAttack → 抛 StateError" fail-fast 用例**没抛预期 StateError**,Mac 端不重现。

历史记录最早见 `docs/handoff/codex_desktop_visual_check_method_report_2026-05-14.md:54` Codex 报告,旧推测 `.dart_tool/build` cache stale,后续多个 closeout(W14/W15 共 14 条)都把这条挂着,sonnet 30min 短平快预算一直没起手。

本会话 P2 闭环后用户拍板 G 起手 + F 派单同发,本批闭环 G。

## 2. 根因诊断(Mac 端 grep + 推理)

**问题链**:

1. **Pen Windows git 默认 `core.autocrlf=true`**,checkout 时把 `data/*.yaml` 转 CRLF(Windows 标准 line ending)
2. **`fileLoader` 用 `File.readAsString` raw 读**保留 CRLF(`test/data/game_repository_test.dart:15-19`)
3. **brokenLoader 内 `replaceFirst` 的 needle 是 Dart 多行字面量**(`'''...'''` 默认 LF):
   ```dart
   return original.replaceFirst(
     '''
     - id: skill_gangmeng_jichu_ult
       name: 怒涛拳
       description: TODO_NARRATIVE
       type: ultimate''',
     '''
     - id: skill_gangmeng_jichu_ult
       name: 怒涛拳
       description: TODO_NARRATIVE
       type: normalAttack''',
   );
   ```
4. **LF needle match 不到 CRLF 文件内容** → `replaceFirst` 返回原字符串
5. **broken loader 返原 yaml** → `loadAllDefs` 正常加载不抛 → test fail

Mac 端验证:`grep -c $'\r' data/skills.yaml` = 0 / `file data/skills.yaml` 报 "UTF-8 text" 不是 "with CRLF",证实 Mac 端 LF,Pen 端 CRLF。

**Tower test 同款风险 4 处未爆**(`test/features/tower/domain/tower_floor_def_test.dart:218/235/266` + `:284` 读 towers.yaml):needle 是单行字面量(`'requiredRealm: xueTu'` / `'baseHp: 15000'`),不含换行,CRLF 文件内单行 needle 仍能 match,所以 Pen 端没爆。但同款风险仍在(将来如有人改成多行 needle 立刻撞)。

## 3. 代码改动

3 处 `fileLoader` / raw read normalize CRLF → LF:

| 文件 | 改动 |
|---|---|
| `test/data/game_repository_test.dart:18` | `return (await f.readAsString()).replaceAll('\r\n', '\n');` + 3 行注释解释根因 |
| `test/features/tower/domain/tower_floor_def_test.dart:23` | 同上(无注释,沿用 game_repository_test 注释) |
| `test/features/tower/domain/tower_floor_def_test.dart:284` | `_buildBrokenTowersYaml` 内 `readAsStringSync().replaceAll('\r\n', '\n')` |

Mac 端 LF 下 normalize 是 no-op,旧行为完全不变。

## 4. 测试与验证

| 阶段 | 命令 | 结果 |
|---|---|---|
| 1. 单文件 | `flutter test test/data/game_repository_test.dart test/features/tower/domain/tower_floor_def_test.dart` | 45/45 全过 |
| 2. 全仓回归 | `flutter test` | **661/661** + analyze 1 info(P2 遗留 `prefer_const_constructors`,与本批无关,未顺手清) |

## 5. Pen 端验证预期

Pen 端 git pull 拉到本 commit + `flutter test test/data/game_repository_test.dart` 后,T64 心法每本 3 招 type 分布 fail-fast 用例**应抛预期 StateError**(包含 `'应精确为'` 字符串)。

如果 Pen 端跑了仍 fail,说明 CRLF 不是真根因,需要 Mac 端重新诊断(可能性低,但 closeout 留这条防御性条款)。

F 派单(`codex_dispatch_w15_stage_drop_visual_2026-05-16.md`)§3.1 已写明 Codex 顺手 `flutter test test/data/game_repository_test.dart` 验本 fix,作为入场检查之一。

## 6. 下次开局必读

### 6.1 状态快照

- HEAD 待 push(本会话 2 commit:`c17af84` test fix + `bb7ab0d` PROGRESS + F 派单)
- 661/661 + analyze 1 info(P2 遗留 `prefer_const_constructors`,不阻塞)
- T64 fail-fast Mac 端原本就过,本批是 Pen 端预修(Pen 端跑过才算闭环)
- Codex F #34 stage drop 视觉验收派单已在 Pen 端跑(本会话同期产出)
- P2 当前阶段:Character.insightPoints + internalForce 消费层接入完成,#30 第 2 期闭环

### 6.2 开局动作

1. 读 PROGRESS.md「当前阶段」+「下一步」+「挂账事项」
2. 读 本 closeout §6 下次开局必读 + 本 closeout §7 A 任务设计要点
3. 读 `docs/handoff/week15_30_phase2_consumption_layer_2026-05-16.md` §4.2 / §6.4(P2 wallet 累加纪律,A 沿用)
4. `git pull --rebase --autostash`
5. 选读 memory:`feedback_avoid_over_engineer_abstraction`(A 同款 wallet 设计点决策依据) + `feedback_isar_pitfalls` §3(schema 改动 saveVersion bump 纪律,A 若加字段必须遵循)

### 6.3 下波候选

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| **A** ⭐ | experiencePoints 消费层接入(#30 第 3 期同体例) | **opus xhigh** | 2-3h | cross-system 升层链路,本 closeout §7 已写设计要点;F 在 Pen 跑期间 Mac 端首推 |
| B | §12.1 #7 三流派 extra_effect 数值拍板 + 正午阳刚 +20% 接入 SeclusionService | sonnet | 30-60min(讨论+实装) | 讨论型,落 numbers.yaml 后接 SeclusionService |
| C | §12.1 #10 师承遗物规则拍板 | sonnet | 30-60min(讨论) | 讨论型,Phase 4-5 师徒系统阻塞,可以现在拍板规则攒着 |
| D | 顺手清:analyze 1 info(P2 遗留 prefer_const_constructors)+ PROGRESS 101→<100 行归档 | sonnet | 10min | 顺手收尾 |

**推荐 A 起手**:与 P2 同子系统延续(seclusion 产 wallet + Character 消费),context 复用 P2 决策(角色级 wallet + 无 cap + writeTxn 一次性写);但跨主线/塔/闭关三贡献源 cross-system,先讨论 + 拍板设计点再实装。

## 7. A 任务(experiencePoints 消费层接入)设计要点

**为什么是 cross-system**:

- `RetreatOutputs.experiencePoints` 只是闭关产生的一支
- **主线 stage victory** 也产 EXP(`stage.baseExpReward * difficultyMultiplier` 已存在,见 `stages.yaml`)
- **爬塔 floor cleared** 也产 EXP(预设但需 grep 确认)

A 任务核心 = 把 EXP 写回 Character + 触发升层(layer)/ 升阶(tier)链路。

**待讨论设计点**:

1. **Q1 wallet 位置**:`Character.experiencePoints: int = 0`(沿 P2 体例,角色级)?还是直接消费完不存(无 wallet)?
   - 倾向:存 wallet,因为升层公式可能不是「攒到 N 立刻升」,而是「点击升层按钮花费 X EXP」(GDD §10 武学领悟 UI 类比)
   - 待用户拍板

2. **Q2 升层触发时机**:闭关 / 主线 / 塔 produce EXP 后立刻 auto-升?还是攒着等用户点「升层」按钮?
   - 倾向:auto-升(挂机游戏不应手动点)— **但需查 GDD §4.3 修炼度 9 层升级机制**
   - 待用户拍板

3. **Q3 三贡献源是否区分**:闭关 EXP / 主线 EXP / 塔 EXP 是否分开记录?还是统一加到 `Character.experiencePoints`?
   - 倾向:统一加(Demo 不需要区分来源做统计/buff),分开记录是 over-engineering(同 P2 wallet 决策)
   - 待用户拍板

4. **Q4 升层公式**:`experienceToNextLayer` 怎么算?7 阶 × 9 层 = 63 节点,每节点的 EXP 阈值递增曲线?
   - 查 `numbers.yaml realms.layers` / `realms.tiers` 现有锚点
   - 可能已经定好(W14-1 / W6 实装时落过),只需读不需新设
   - 实装前必须 grep + 读 yaml 确认

5. **Q5 升层后副作用**:Character 各属性是否需要 recompute?(internalForce / internalForceMax / 各 stat caps)
   - 倾向:升层时按 `realms.layers[N]` / `realms.tiers[T]` 内的曲线 + Character.attributes 重算
   - 实装前必须读 yaml + grep `cultivationLayer` / `RealmStratum` 现有 caller 路径

**实装预设步骤**:

1. **Phase 0** 设计讨论(30min):拍 Q1-Q5 5 个设计点
2. **Phase 1** schema(30min):`Character.experiencePoints` 字段(若 Q1 倾向落)+ Isar saveVersion bump 0.8.0 → 0.9.0 + `IsarSetup._currentSaveVersion` 同步(沿 P2 saveVersion 修救教训)
3. **Phase 2** service(60min):新建 / 改 service 写 EXP 回 Character + 触发升层 + 升层后 stat recompute;3 caller path 同步(SeclusionService.completeRetreat / 主线 victory 链路 / 塔 floor cleared 链路)
4. **Phase 3** UI(30min):RetreatResultScreen 加 EXP 维度展示(沿 P2 4 维体例)/ 主线 victory 屏加 EXP gained 显示
5. **Phase 4** test(60min):service 测 3 路径写回 + 升层触发 + cap clamp(若有)+ widget 测 EXP 展示
6. **Phase 5** verify(15min):analyze + 全仓 test + commit + push

**风险预估**:

- 主线 victory 链路若已有 EXP 写回(W11 销账 #32 victory 接 resolveBattle)— 需先 grep 确认,可能不是 0→1 是 1→2 扩
- 升层 stat recompute 若不在 Character 域内的现有代码路径(在某 service 里散写)需识别 + 内聚
- saveVersion bump 必须同步 `isar_setup_test` 期待值改 + build_runner regen(P2 修救血泪经验)

## 8. 硬约束沿用(本批 + A 都用)

延续 P2 closeout §6.4 全部硬约束。本批新经验:

- **Mac/Linux 写 Dart test 用多行字面量做 yaml `replaceFirst` 时,Pen Windows 端 CRLF 工作树会让 needle miss,test 静默不抛预期 error**:fix 在 loader 端 normalize 而非改字面量(loader 端 normalize 一处生效全 test;改字面量分散且新增 test 易忘);防御纵深:tower test 同款 4 处 needle 是单行未爆但仍 normalize。
- **多个 closeout 持续挂账同一条不动手的代价**:T64 fail 14 个 closeout 挂了 14 天,sonnet 30min 顺手就能动诊断 + 修;教训是老挂账"30min 短平快"如果连续 3 个 closeout 都没起手,优先级要提到下波必做。
