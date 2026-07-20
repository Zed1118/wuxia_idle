# 测试质量硬化批：弱断言强化 + flaky 锚定 + 边界补齐 + 过 mock 纠偏

> 派单日期：2026-07-20。分支 `kimi/test-hardening`（基点 main@4a61a47e），
> worktree `.worktrees/kimi-harden`。执行协议：CLAUDE.md §8.0/§8.2/§8.3。
> 上一批（provider/service 覆盖 19 测）已合 main，本批不刷覆盖数字，审现有测试
> 套件**质量/健壮性**，揪弱测并加固。

## 目标

按四类审 `test/` 现有测试（先扫定候选，从命中最多的文件起，**序列制**逐文件，
每文件独立 commit）：

1. **弱断言**：只断言 isNotNull/isNotEmpty/长度，不验具体值/语义 → 强化为语义断言。
2. **隐性 flaky**：依赖迭代顺序/时间/全局单例/并发共享 → 加确定性锚
   （排序/固定 seed/隔离 setUp）。
3. **缺边界**：只测 happy path，缺错误/空/越界/并发路径 → 补边界用例。
4. **过度 mock**：mock 到不测真实行为 → 改真实入口驱动。
   （预备注：全仓 grep 无 mocktail/Mockito/Fake 使用，本类预计稀少。）

**每处加固先复现弱点**：强化断言先填错误期望值跑 RED（证原断言宽松、新断言有牙），
改回正确值转绿后再提交，不盲改。

## 禁区（碰=立即 [BLOCKED] 停）

- `lib/features/battle/**`、`test/features/battle/**`、`test/combat/**`（codex 并行占 battle）
- `data/` 全目录、数值/schema/红线测试（`test/data/**`、`test/balance/**` 红线类）、
  `pubspec.yaml`、`lib/shared/strings.dart`、`GDD.md`、`PROGRESS.md`、`BACKLOG.md`、
  `NEXT*`、saveVersion、结算公式层
- 不改 `lib/` 生产逻辑；发现疑似生产 bug → 记「发现项」+ 必要时 `[BLOCKED]` 冻结
- 主 checkout（/Users/a10506/Desktop/Projects/挂机武侠 顶层）只读

## 验收（每文件，§8.2 四证据批末汇总）

- 加固后该文件 targeted 绿 + `flutter analyze --no-pub` 0 issue
- 恢复点记：审了几文件 / 加固几处 / 各属四类哪类 / 发现的生产 bug（若有）
- 批末：一次全量 `flutter test --no-pub`（并发）绿；树净 + tip 前缀
  `[READY] 测试质量硬化批交付`

## 候选清单（弱断言模式命中数降序，扫于 2026-07-20）

| 命中 | 文件 | 初判 |
|---|---|---|
| 25 | test/features/debug/application/phase2_seed_service_test.dart | 多为 null 守卫+具体值，实弱点多在「装备齐只查 id 非空」类 |
| 22 | test/features/equipment/application/equipment_disposal_service_test.dart | 待审 |
| 10 | test/features/mainline/presentation/apply_victory_resolution_test.dart | 待审（上批留偶发观察项） |
| 9 | test/features/taohua_island/island_settle_service_test.dart | 待审 |
| 9 | test/features/sect/stage_boss_recruit_test.dart | 待审 |
| 9 | test/features/seclusion/application/seclusion_service_test.dart | 待审 |

（5-7 命中档：offline_recap_service / sect_providers / equipment_catalog_service /
sweep_unit / onboarding_service / inner_demon_narrative / expedition_config_load /
expedition_combat_runner / gauntlet_providers / gauntlet_enemies —— 视进度续审。）

## 任务切片

- [ ] 切片 1：计划文件 + 候选扫描（本文件）
- [ ] 切片 2+：逐文件审→复现→加固→targeted+analyze→commit（逐文件追加记录）
- [ ] 末片：批末全量绿 + 四证据 + [READY] 冻结

## 逐文件记录

### ① test/features/debug/application/phase2_seed_service_test.dart（commit 44b73aaa）
- 审出：类别1 弱断言 3 处；类别2/3/4 未见实弱（真 Isar 临时目录隔离、
  集合比较用 Set/containsAll、已有 clear/reseed 幂等边界）。
- 加固：
  1. 「师徒装备齐」由 equippedXxxId 非空 → 每件 id 可解析 + slot 匹配 +
     ownerCharacterId 归属本人 + 主修 role=main 归属本人（悬空 id 旧断言抓不到）。
  2. 「buildTeams 不再 fail-fast」敌队 isNotEmpty → right.length ==
     stage.enemyTeam.length（与 def 对齐）+ negative id 约定（characterId<0）。
  3. 「W14_3 reseed」大弟子 equippedEncounterSkillId 非空 → 仍在 unlock 池内。
- RED 证据：3 处填错值（owner+100 / enemyTeam.length+1 + id>0 / bogus skill id）
  → +36 -3，仅目标 3 用例红，改回真值 → **39/39 绿**；analyze 0；format 0。

### ② test/features/equipment/application/equipment_disposal_service_test.dart（commit 5be31f19）
- 审出：类别1 弱断言 6 处（拒绝路径只查「装备仍在」不查「字段未被改写」）；
  类别3 缺边界 2 处（批量处置测全 +0，强化加成在批量路径无覆盖）。
- 加固：
  1. 6 处拒绝测补字段不变量：rejectedEquipped×2（ownerCharacterId 1/42 不被改写）、
     rejectedHeritage×2（isLineageHeritage 仍 true）、rejectedLocked×2（isLocked 仍 true）。
  2. 新测 sellAllOfTier 带强化（liQi+3 ×2 → totalSilver 728=2×280×1.3）。
  3. 新测 disassembleAllOfTier 带强化（liQi+2 ×2 → mj 18=2×(7+2)、xx 2）。
- RED 证据：字段探针填错（999/isFalse）+ 新测填「批量忽略强化加成」错误值
  （560/14）→ +19 -8 精准 8 红（Actual 728/18 证批量逐件计入强化加成），
  改回真值 → **27/27 绿**；analyze 0；format 0。

### ③ test/features/mainline/presentation/apply_victory_resolution_test.dart（commit 84662515）
- 审出：类别1 弱断言 2 处 + 类别3 缺边界 2 处；类别2/4 未见
  （全套真 Isar + 显式 DateTime，既有 11 用例分支覆盖已好）。
- 加固：
  1. 首通秘籍只查非空 → 补 quantity=1 语义。
  2. 心法只查存在 → 补 skillUsageCount 仍空（growable 转换写回不丢数据）。
  3. 新测「activeIds 部分悬空」：per-id skip 语义（既有只测全悬空→null）。
  4. 新测「baseExpReward>0 经验结算」：advancements 记录 + EXP 全额落库未升层
     （既有全 0 EXP，L851-859 路径未覆盖）。
- RED 证据：分两轮——轮一 scroll 999→Actual 1 / 悬空 id+1000→Actual 1 /
  experienceGained 999→Actual 30；轮二 skillUsageCount isNotEmpty→Actual [] /
  layersGained 1→Actual 0 / experience 999→Actual 30。改回真值 → **13/13 绿**；
  analyze 0；format 0。

### ④ test/features/taohua_island/island_settle_service_test.dart（commit 277f9d9d）
- 审出：类别1 弱断言 5 处（greaterThan(0) 不验产出量）+ 类别3 缺边界 3 处
  （回拨/未初始化 settle/零时长 harvest 守卫分支全无覆盖）。
- 加固：
  1. T4 daZaoTai.stored >0 → closeTo(6.12)=1.5×synergy1.02×1×4（RED 顺带证
     旧注释「= 6」未计 synergy 之误）+ 新增 tieJiangChang.stored≈0（24 产 24 耗）。
  2. T2b zhuZaoTai.stored >0 → closeTo(3.264)。
  3. T5 totalQty>0 → 背包总量 == gained 汇总（175）+ 必含 item_mojianshi。
  4. T6 两 >0 → 精确 floor 量（mojianshi 110 / jingyandan 73）。
  5. 新测 T10 时钟回拨 elapsed<0 → stored/lastSettledAt 均不变（守卫早返）。
  6. 新测 T11 settle 未初始化档 → 建 7 建筑但 stored 全 0。
  7. 新测 T12 harvest 零时长 → gained 空 + 不写背包。
- RED 证据：分两轮——轮一 7 首探针全红（9.9→3.264 / 6.0→6.12 / isFalse→true /
  999→110 / tBack→t0 / 1.0→0.0 / isFalse→true）；轮二 5 次探针全红
  （24.0→0.0 / 176→175 / 999→73 / 1.0→0.0 / non-empty→[]）。
  改回真值 → **14/14 绿**；analyze 0；format 0。

### ⑤ test/features/sect/stage_boss_recruit_test.dart（commit e3ecc94b）
- 审出：类别1 名实不符 1 处——「victory/defeat 共用防刷」测只写库再读回
  （测的是 Isar 读写，未驱动任何 hook）；类别2/3/4 未见（rng 固定 _AlwaysHitRng，
  schema 红线/transform/compat 覆盖已好）。
- 加固：改写为真驱动 `runStageBossFailRecoverHookAfterDefeat`——save 预标
  triggered 后调 defeat hook，断言 recruitFlow 调用 0 次（守卫早返）。
- RED 证据：flowCalls 期望 1 → Actual 0（守卫生效）；改回 0 → **12/12 绿**；
  analyze 0；format 0。

### ⑥ test/features/seclusion/application/seclusion_service_test.dart（commit 4f2757d2）
- 审出：类别1 弱断言 2 处；其余命中均为「>0 守卫 + 相对精确」既有强模式
  （如 100+points / before+points / quantity==out.silver），不重复加固；
  类别2/3/4 未见（abandon/clamp/跨槽/空指针边界已全）。
- 加固：
  1. 「收功 actualRewards 有 mojianshi」isNotEmpty → 条目数量 == out.mojianshi
     （session 记录与结算输出一致，沿文件内 kaifeng_fucai 既有模式）。
  2. 「收功 moJianShi 数量增加」quantity>0 → 捕获 out 断言 == out.mojianshi
     （出库入库一致，沿 item_silver 既有模式）。
- RED 证据：两探针 out.mojianshi+1 → Actual 4 双双红；改回 → **55/55 绿**；
  analyze 0；format 0。

### ⑦ test/features/seclusion/application/offline_recap_service_test.dart（commit 5cd7e322）
- 审出：类别3 缺边界 1 处——弹卡阈值 1h 只测了 0.5h 侧，端点语义（`<` 才拦）未锁；
  类别1/2/4 未见（>0 守卫与「与 computeOutputs 直接一致」对比测已覆盖数值语义）。
- 加固：新测「恰好离开阈值（整 1h）→ 弹卡」+ settledHours 全额结算。
- RED 证据：settledHours 999 → Actual 1.0；改回 → **10/10 绿**；analyze 0；format 0。

### ⑧ test/features/sect/sect_providers_test.dart（commit 6b2ac904）
- 审出：类别1 弱断言 1 处 + 类别3 缺边界 1 处。
- 加固：
  1. 月度 tick `lastTickAt isNotNull` → 精确锚 `createdAt + 30d`（elapsedMonths=1
     推进语义，非「= tick 时刻」；RED 31d→Actual 30d 证锚语义）。
  2. 新测「rng 恰等于 missionRecruitProb → 不招徒」（锁 `roll >= prob 即拒` 端点；
     prob 读 numbers 真值不写死；RED isTrue→Actual false）。
- RED 证据：两探针两轮全红；改回 → **19/19 绿**；analyze 0；format 0。

### ⑨ test/features/weapon_codex/equipment_catalog_service_test.dart（commit 384c8096）
- 审出：类别3 缺边界 3 处（既有 4 测语义已好）。
- 加固：新测 空 defIds no-op+未建档查询 null / 同批重复 defId count 按件数（2）/
  reconcile 混合（已入册跳过 + 同 def 重复持有 toSet 去重只回填 1 档）。
- RED 证据：count 999→Actual 2、hasLength(99)→Actual 2；改回 → **7/7 绿**；
  analyze 0；format 0。

### ⑩ test/features/sweep/application/sweep_unit_test.dart（commit 60864d24）
- 审出：类别1 弱断言 2 处（startBattle 左/右队只查 isNotEmpty）。
- 加固：主线+爬塔两起手测 → 左队 characterId 集合 == 库中全部角色
  （P3 无 active ids → 兜底装配唯一角色；首版锚 activeCharacterIds 会误伤
  合法兜底路径，改锚 characters 全集）+ 右队 length == stage/floor enemyTeam length。
- RED 证据：左队 {id+100}→Actual {1} 双红；右队 +1→Actual 1 双红；改回 →
  **6/6 绿**；analyze 0；format 0。（期间补 character.dart/isar_community 两 import。）

### ⑪ test/features/onboarding/application/onboarding_service_test.dart（commit ac5d2da2）
- 审出：类别1 弱断言 2 处。
- 加固：R5.4 主修只查非空 → id 可解析 + role=main + tier 0 入门功；
  R5.5 敌队 `>0` → == stage.enemyTeam.length。
- RED 证据：role assist→Actual main；enemyTeam+1→Actual 1；改回 → **10/10 绿**；
  analyze 0；format 0。

### ⑫ test/features/inner_demon/inner_demon_narrative_test.dart（commit 592ba997）
- 审出：类别1 一致性缺口 2 处——opening 测已断 yaml 内 id 联结，victory/defeat 缺
  （fromYaml 的 id 来自文件内部，联结非平凡）。文件头有「文案不写死」既定方针，
  不违方针加字数/内容断言。
- 加固：victory/defeat 补 `c.id == '${id}_victory/_defeat'` 联结断言。
- RED 证据：_wrong 后缀双红（Actual 真 id）；改回 → **4/4 绿**；analyze 0；format 0。

### ⑬ test/features/expedition/expedition_config_load_test.dart（commit c5349fec）
- 审出：类别3 缺结构不变式 1 处——敌队规模无 3v3 上限守卫
  （buildEnemyTeam 超员静默截断丢怪）。
- 加固：新测「远征敌队规模 ≤3」（normal/elite 全量）。
- RED 证据：≤2 探针 → Actual 3（elite 队 3 人）；改回 ≤3 → **4/4 绿**；
  analyze 0；format 0。

### ⑭ test/features/boss_gauntlet/gauntlet_enemies_test.dart（commit 1218d85d）
- 审出：同 ⑬ 类别3——三关敌队解析只查非空，无规模上限守卫。
- 加固：通用解析测补 team.length ≤3。
- RED 证据：≤2 探针 → Actual 3（苏无咎/石镇岳队 3 人）；改回 → **5/5 绿**；
  analyze 0；format 0。

### ⑮ test/features/boss_gauntlet/gauntlet_providers_test.dart（commit 6ae06332）
- 审出：类别3 缺边界 1 处——头注承诺「占用标注」但 occupied=true 路径无测
  （occupied 由 CharacterOccupancyService 快照派生，含 active 断魂庄会话成员）。
- 加固：新测「active 会话弟子 → occupied=true + selectable=false」（真 enter 入口驱动）。
- RED 证据：occupied isFalse→Actual true、selectable isTrue→Actual false 两轮红；
  改回 → **6/6 绿**；analyze 0；format 0。

### 审计后无需加固（记录在案）
- **test/features/expedition/expedition_combat_runner_test.dart**（4 命中档）：
  caps >0 + currentHp ≤ maxHp 构成区间断言已合理；stagedRewards 按 rewardKey
  合并累加，精确件数脆（节点奖励类型调优即漂移），isNotEmpty 为该层合适语义；
  奖励口径由 expedition_settlement/recall 测族兜底。

## 当前恢复点

- **状态**：候选表 ≥4 命中档 15 文件全部审完并各自独立 commit；低命中档
  （2-3）多为「守卫+字段断言」既有强模式，扫描未见同量级弱点，批收尾。
- **最后完成**：⑮ gauntlet_providers occupied 边界（6/6 绿，6ae06332）+
  expedition_combat_runner 审计记录（不加固）。
- **下一步**：批末全量 `flutter test --no-pub` 绿 → 四证据 → [READY] 冻结。
- **已跑验证**：15 文件 targeted 全绿（39/27/13/14/12/55/10/19/7/6/10/4/4/5/6），
  每文件 `flutter analyze --no-pub` 0 + `dart format --set-exit-if-changed` 0；
  全部 40+ 处加固均有 RED→GREEN 运行记录（见各节）。
- **阻塞项**：无。

## 发现项（疑似生产 bug，只记录不修）

（暂无）
