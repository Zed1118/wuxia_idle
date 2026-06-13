# 半手动战斗 · 确定性 seed 重放 · 周目进化 · Master Spec

> 日期:2026-06-13 · 阶段:1.0 长线打磨期 · 模型:opus xhigh
> 来源:用户 2026-06-13 拍板。整合「桌面文档1 半手动战斗(类B)」+「文档2 玩法创新 江湖记招/问鼎轮回(类C)」为统一机制。
> 状态:方案定稿 + P0 首批可执行。实装前 GDD §5.5 调整需单独 ask。
> 上游核查:本会话两份 Phase 0(战斗确定性 + 进度/周目/UI 现状),行号锚点见 §三。

## TL;DR

默认真单步回合制手动打;手动通关时记录 `{seed + 操作序列}`,解锁该关该周目的「自动战斗」开关(同 seed 确定性重演,确保打过);周目递进——一周目手动过可自动刷,挑战二周目敌人进化(江湖记招)→ 新战斗 → 重新手动。把「手动=推进新内容」「自动=刷已通关内容」分开,挂机便利与手动参与各得其所。

## 一 · 用户拍板核心决策(2026-06-13)

1. **自动战斗实现 = A 确定性 seed 重放**(非策略托管/非快速结算):记 `{seed+操作}`,同 seed 重演 100% 复刻通关,有逐回合真实表现 + 确保打过。
2. **调挂机定义**(改 GDD §5.5,见 §四):接受「离线只自动刷已手动通关内容,推进新关/新周目需在线手动」。
3. 默认战斗模式 = 真单步回合制 + 手动选目标。

## 二 · 核心机制

### 2.1 三态战斗模式
- **手动单步(默认 · 新关/新周目)**:战斗不自动推进,玩家点「行动」走一步,每步选技能 + 选目标。
- **自动重放(已手动通关该关该周目后解锁)**:用记录的 `{seed+操作}` 重演,确保复刻通关。可挂机/离线刷。
- 离线托管:仅对已解锁自动的关生效(见 §四)。

### 2.2 手动→解锁→自动 闭环
1. 新关首次 = 手动单步打。
2. 通关瞬间记录 `{seed, 操作序列}`(操作=每个 requestUltimate 的 推进锚点+角色+技能+目标)。
3. 该关该周目标记「已手动通关」+ 存重放记录 → 解锁「自动战斗」开关。
4. 开自动 = 同 seed 重演操作序列 → 确定性复刻通关。

### 2.3 周目进化(江湖记招 / 问鼎轮回)
- 一周目手动过 → 可自动刷一周目(攒资源/掉落/熟练)。
- 挑战二周目:敌人进化(数值 scale + 反制词条,江湖记招),是**新战斗** → 原 seed 失效 → 重新手动。
- 周目选择 UI:继续刷一周目(自动) vs 挑战 N+1 周目(手动)。
- 主线 = 江湖记招(绑关卡,叙事宿敌);爬塔 = 问鼎轮回(绑全塔规则)。第一期主线 3 层 / 爬塔 2 周目(架构预留 5)。

## 三 · Phase 0 现状结论(行号锚点)

### 3.1 战斗确定性(地基)— 内核已确定性,缺 seed 注入
- 内核确定性 ✅:纯函数同步推进 / `_actorOrder` 全序排序(`default_ground_strategy.dart:152`)/ AI 无随机(`battle_ai.dart`)/ rng 消费顺序锁死(`damage_calculator.dart:120,149`)/ 无时间·无序集合·外部状态依赖。测试已用 seeded Random 复现战斗(`rng.dart:28` 约定)。
- ❌ 唯一阻断:`advance()` 不传 rng(`battle_providers.dart:108`),strategy 循环内 `rng ?? Random()` 每次 new 无种子(`default_ground_strategy.dart:77`)。
- 改造(小,3 点):startBattle 接 seed → BattleNotifier 持单 `Random(seed)` → advance 一路传进 tick → strategy 不再 new。**全场复用同一实例**。

### 3.2 进度 / schema 现状
- 主线:`MainlineProgress(clearedStageIds List + clearedAt)`(`mainline_progress.dart:28`)— 无周目/seed/操作维度。
- 爬塔:`TowerProgress(highestClearedFloor int)`(`tower_progress.dart:27`)— 标量。
- saveVersion 0.18.0(`isar_setup.dart:88`),迁移手写单段(`:137`)。Isar List 不能嵌变长 List → 操作序列需独立 @collection 或序列化 String。

### 3.3 周目机制
- 100% 全新,零残留。敌人来自 StageDef/EnemyDef 静态,进化需新「按周目 scale」层。

### 3.4 单步 UI / 选目标 / 操作记录
- battle_screen `Timer.periodic→advance`(`battle_screen.dart:246`)。已有 `autoStart` flag(`:116`,false 冻结不播)可复用做单步:autoStart=false + 「下一步」按钮调 advance。纯 UI。
- 速度档现只 2 档(fast toggle `:252`);多档纯加配置。
- 手动选目标:现 `_pickTargetId` 全自动(`battle_ai.dart:99`)。改手动要动 domain:requestUltimate 扩 targetId + AI 消费优先。
- 操作记录挂点:`requestUltimate`(`battle_providers.dart:84`),记 `{锚点, charId, skillId, targetId}`。

## 四 · 挂机定义调整(GDD §5.5 草案 · 实装前需 ask)

现 GDD §5.5「在线=离线,挂机就是挂机」。调整草案:
- **自动(在线挂着/离线)**:刷**已手动通关**的关卡/周目,产出资源·掉落·熟练度。此产出「在线=离线」不变(不引入在线 buff/加速)。
- **手动(在线)**:推进**新关卡/新周目/新进化层**。新增「在线专属:一次性手动门槛」。
- 反留存初衷不破:非在线 buff,是一次性手动操作门槛,过后即可自动。不做日课/登录奖励/体力。
- ⚠️ 改 GDD §5.5 措辞需用户单独确认。

## 五 · 分阶段实施(依赖顺序 · P0 首批详细)

依赖链(前三步无 schema 低风险,schema 迁移最后收口):

### P0 · 单关 手动→seed重放→解锁 最小闭环(不含周目)
目标:单关证明「手动单步过 → 记 seed+操作 → 自动重演确保过」核心闭环。
1. **确定性链改造**(§3.1,无 schema):startBattle 接 seed + BattleNotifier 持单 `Random(seed)` + advance 传 rng + strategy 去掉 `?? Random()`。**红线测:同 seed+操作两次跑结果全等**。
2. **操作序列 in-memory 记录**(§3.4,无 schema):`BattleNotifier.requestUltimate` 记 `{锚点,charId,skillId,targetId}` 到 in-memory 列表。
3. **单步 UI + 手动选目标**(§3.4):复用 autoStart=false + 「下一步」按钮;requestUltimate 扩 targetId,AI 消费优先玩家目标。
4. **重放执行**:自动模式用 `{seed+操作}` 重演(同 seed 构造 Random + 在相同锚点回放 requestUltimate)。
5. **解锁 + 落盘**(§3.2,🔴 schema):新 Isar collection `BattleReplayRecord`(battleKey+seed+ops 序列化)+ 进度模型加 cycleIndex + 「已手动通关」判定;升 saveVersion 0.19.0 + 迁移分支(旧档 cycle=1/replay 空)。
6. **GDD §5.5 调整**(§四,ask 后改)。

验收:单关手动单步可打过;通关后该关出现「自动战斗」开关;开自动确定性复刻通关;红线测 seed 复现;§5.4 数值红线不破;全量测不退。

### P1 · 周目进化(江湖记招 / 问鼎轮回)
- 主线江湖记招 3 层:复战进化(敌人数值 scale + 反制词条)+ 周目选择 UI + 「敌人已识得你某路数」提示。
- 爬塔问鼎轮回 2 周目:通关 30 层开二周目 + Boss 反制词条 + 周目选择。
- 敌人进化层(按 cycleIndex 对 EnemyDef scale + 词条),数值守红线(每周目 +5-8%,主要靠词条非堆数值)。
- 战败诊断帖(文档2 创新点四,5 类诊断 + 可跳转)——失败侧战后体验补齐。

### P2+ · 全貌(预留,后续独立波,不在本 spec)
文档2 其余创新点(本命兵器编年史/江湖传闻/败中有悟/闭关梦境/门派气质/师徒临阵传招/心法相斥/无名小敌成宿敌/传承代价)各需独立 spec,按文档2 §12 优先级排。

## 六 · 数据结构草案(实装以代码现状为准)

```text
# 新 Isar @collection: BattleReplayRecord(一行=一关一周目重放记录)
BattleReplayRecord:
  id        Isar Id
  battleKey String   # 索引: "stage#${stageId}#${cycle}" / "tower#${floor}#${cycle}"
  seed      int      # 战斗随机种子
  ops       String   # 操作序列 JSON: [{anchor,charId,skillId,targetId},...]
  clearedAt DateTime
# 进度模型新增(标量,纯加字段):
  MainlineProgress / TowerProgress: 每关/层当前可挑战周目 cycleIndex
# saveVersion 0.18.0 → 0.19.0;迁移: 旧档 cycle 默认 1 + replay 空(旧通关关卡的自动解锁策略见 §八#2)
```

## 七 · 硬约束(红线)

- §5.4 数值红线不破(普伤8000/血20000/内力15000/装攻2000);周目进化靠词条/反制非堆数值(每周目 +5-8% 上限)。
- 确定性重放是地基:战斗内任何随机必须走注入的 seeded rng,禁无种子 `Random()`/`DateTime.now`/无序集合驱动结果。
- 不硬编码中文文案(UiStrings)/ 数值(yaml)。不绕过现有 service 校验。
- schema 迁移单一收口点(P0 步骤5),一次升 0.19.0;旧档兼容。
- 离线托管只对已解锁自动的关;不引入在线 buff/加速/快进券。
- TDD:确定性链 + 重放必有红线复现测;每步 analyze 0 + 全量 test 不退。

## 八 · 待确认问题(P0 不阻塞,实装中需拍)

1. GDD §5.5 措辞最终定稿(§四草案)。
2. 旧档迁移:0.18 已通关关卡开 0.19 后,自动战斗是否需「补打一次手动」才解锁?还是迁移期豁免(无 seed 记录则降级:豁免关用保守自动托管跑,新关才严格 seed 重放)?
3. 单步「行动」粒度:一步=一个 actor 行动,还是一步=一个完整 round(全员行动)?
4. 手动选目标范围:所有技能可选目标,还是只单体技能可选(群体自动)?
5. 周目进化敌人 scale 公式 + 反制词条数据落点(EnemyDef 扩 or 新配置)。
6. 操作序列锚点用 tick 还是 actionLog 长度(重放对齐精度)。
