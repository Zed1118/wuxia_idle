# W15 #30 第 2 期 内力 + 心法领悟点消费层接入 closeout

> 2026-05-16 / Mac · opus xhigh / 单会话 / 单 commit / 零回退

## 1. 起点与背景

#30 第 1 期(2026-05-15)`SeclusionService.computeOutputs` 已落 4 维度 + 4 加成,但 `RetreatOutputs` 中 `techniqueLearnPoints` / `internalForcePoints` 仅「只算不发奖」(沿 experiencePoints 体例)。第 2 期任务:把这 2 维度从纯计算落到 `Character` 实际消费。

H 任务 brief(详 E+K closeout §6.3):

> **H(opus 2-3h)**:techniqueLearnPoints / internalForcePoints 消费层接入,#30 新维度落 Character/Technique,Phase 5 重构告段后第一个新业务功能。

## 2. 用户拍板 2 设计点

**Q1**:`techniqueLearnPoints` wallet 落哪? → **A1 角色级 `Character.insightPoints`**(非 SaveData 全局 / 非喂主修修炼度 / 非纯占位)。
- 理由:Demo 单角色场景多,跨角色 wallet 提前抽象 = over-engineering(复证 `feedback_avoid_over_engineer_abstraction`,与 D 任务跳过同款)
- 语义最清楚:与 `mainTechniqueId` / `learnedSkillIds` 同体例,角色绑定 wallet
- TechniqueLearningService 已有 `currentInsightPoints` 入参,等学心法 UI 落地时生产路径直接读这个字段

**Q2**:experiencePoints 是否顺手接? → **只做 2 维**。
- 理由:experience 升层涉及 `experienceToNextLayer` → RealmLayer → RealmTier 跨阶链路,牵主线/塔/闭关三贡献源,值得独立任务收口
- H scope 严守 brief 不漂移

## 3. 代码改动

5 文件 modified + 1 文件 new = 6 文件:

| 文件 | 改动 |
|---|---|
| `lib/core/domain/character.dart` | +8 行:`int insightPoints=0` 字段 + factory 参数 + factory 赋值 + 字段注释 |
| `lib/core/domain/character.g.dart` | (gitignored)build_runner regen `r'insightPoints'` PropertySchema |
| `lib/features/seclusion/application/seclusion_service.dart` | +11 行:`completeRetreat` writeTxn 内 `ch.internalForce` clamp(0, internalForceMax)+ `ch.insightPoints` 累加 |
| `lib/features/seclusion/presentation/retreat_result_screen.dart` | +17 行:`hasReward` 2→4 维 + 2 新 `_RewardRow`(`Icons.bolt` 内力 + `Icons.auto_stories` 心法领悟点)+ 局部 var 加 internalForce/insightPoints |
| `lib/ui/strings.dart` | +2 行:`seclusionInternalForce(int n)` / `seclusionInsightPoints(int n)` |
| `test/features/seclusion/application/seclusion_service_test.dart` | +102 行:`completeRetreat` group +3 test(internalForce 写回 / insightPoints 写回 / cap clamp) |
| `test/features/seclusion/presentation/retreat_result_screen_test.dart` | **新建** 5 widget test:4 维全 / 仅内力 / 仅领悟点 / 空收获 / 3 维混合 |

`.g.dart` 全 gitignored(`feedback_wuxia_pen_build_runner` 体例),不入 commit。

## 4. 关键决策细节

### 4.1 internalForce clamp 体例

`Character.internalForce` 与 `internalForceMax`(默认 500)已存在 + grep 全仓发现 max 字段**永不被代码动态修改**(永远是 500 默认 + 测试 setUp 显式覆盖),纯静态上限。clamp 公式:

```dart
final next = ch.internalForce + outputs.internalForcePoints;
ch.internalForce = next > ch.internalForceMax ? ch.internalForceMax : next;
```

### 4.2 insightPoints 累加纯加(无 cap)

未给 `insightPoints` 设上限。理由:
- numbers.yaml 没相关锚点
- GDD §7.2 武学领悟未实装,Demo 阶段不知 wallet 上限语义
- TechniqueLearningService 消费成本 `assist:100 / main:500` 是确定的,累加无 cap 也不会出现「攒太多用不掉」问题
- 真出现攒爆需求时再加 cap,不预先抽象(over-engineering 雷)

### 4.3 写回放 writeTxn 内不分 2 个 txn

`completeRetreat` writeTxn 内一次性写 InventoryItem + RetreatSession + Character(internalForce + insightPoints + currentRetreatSessionId)。**不分多 txn**,因为不涉及奇遇 `recordIdleMinutes` 那种 nested txn 抛 IsarError 的情境(idle tick 已在 writeTxn 外单独跑,见 line 281-289 现有注释)。

### 4.4 Schema bump 0 迁移成本

Isar 字段加新 int 默认 0,旧 save 加载自动兜底为 0,**不需要写迁移代码**(memory `feedback_supabase_migration` 与 Isar 不同:Isar 自带字段默认值,不像 Supabase NOT NULL 需要 backfill)。这是本批新经验,值得沉淀。

## 5. 测试与验证

| 阶段 | 命令 | 结果 |
|---|---|---|
| 1. Character 改完 | `flutter analyze` | 0 issues |
| 2. service 改完 | `flutter analyze lib/features/seclusion/` | 0 issues |
| 3. UI 改完 | `flutter analyze` | 0 issues |
| 4. test 改完 | `flutter test test/features/seclusion/` | 1 fail(cangJingGe 境界不足),fix 后 61/61 全过 |
| 5. 全仓回归 | `flutter test` | **661/661** + analyze 0 issues |

测试 661 = 原 653 + 8 新增(3 service + 5 widget)。

### 5.1 测试漏踩

`insightPoints 累加 techniqueLearnPoints` test 第一版用 cangJingGe + xueTu 境界,触发 `StateError: 境界不足`(cangJingGe 要求 sanLiu)。fix:test 内先 writeTxn 把 character 境界升 sanLiu,然后 startRetreat / completeRetreat 都传 sanLiu。**新经验**:测 闭关产出 wallet 写回时,如果走非山林地图(sanLin 是 xueTu 起点 + 唯一 base 1.0/1.0 地图),fixture 必须先升境界 — 沿用 `seclusion_setup_screen` 体例。

### 5.2 cap clamp test 复用 fixture

`internalForce cap clamp` test 直接复用 fixture 默认(internalForce=500 / max=500),收功后 assert `ch.internalForce == max == 500`,优雅。

## 6. 下次开局必读

### 6.1 状态快照

- HEAD `<H1>`(单 commit 已 push origin/main)
- 661/661 + analyze 0 issues
- `Character` schema +`insightPoints: int = 0`(`character.g.dart` regen)
- `SeclusionService.completeRetreat` 写 Character internalForce(clamp)+ insightPoints
- `RetreatResultScreen` 4 维度展示(mojianshi + internalForce + insightPoints + equipDrops)
- #30 第 2 期闭环 2/3 维度(internalForce + techniqueLearn);experiencePoints 留独立任务

### 6.2 开局动作

1. 读 PROGRESS.md「当前阶段」+「下一步」+「挂账事项」
2. 读 本 closeout §6 下次开局必读
3. `git pull --rebase --autostash` 看 drift(本会话已 push,正常无)
4. 选读 memory:本批未新增,沿用 `feedback_avoid_over_engineer_abstraction`(Q1 决策依据)

### 6.3 下波 3 候选

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| **G** ⭐ | Pen-only T64 test fail 排查 | sonnet | 30min | 老挂账,短平快首推 |
| F | #34 stage drop 视觉验收 Pen 环境改善 | Codex 派单 | 1h | 老挂账,需借鼠标 |
| **新** | experiencePoints 消费层接入(#30 第 3 期同体例) | opus xhigh | 2-3h | 升层链路 cross-system 跨主线/塔/闭关三贡献源,Demo §10 锚点 |

**推荐 G 起手**(sonnet 30min):老挂账短平快收口。F 需借鼠标 + Codex 派单,排第 2。experience 升层链路是 cross-system 新业务,值得独立 task,排第 3 留作下一个 opus 任务。

### 6.4 硬约束沿用

延续 E+K closeout §6.4 + J closeout §6.4 全部硬约束。本批新经验:

- **Isar 字段加新 int 默认 0,0 迁移成本**:旧 save 加载自动兜底为默认值,不像 Supabase NOT NULL 需要 backfill;本批 `Character.insightPoints` 新字段无迁移代码,加 build_runner regen 即可。
- **wallet 是否设 cap 看消费成本**:`insightPoints` 累加无 cap,因为消费成本(`assist:100 / main:500`)远小于产出累加速度的 hours × cap=72 极值,不存在「攒太多用不掉」问题。真出现需求再加 cap,不预先抽象。
- **写 wallet wager 在 writeTxn 内一次性写**:`completeRetreat` 已有 writeTxn 写 InventoryItem + RetreatSession + Character,直接复用同一 txn 写 Character.insightPoints / internalForce,不分 2 个 txn(无 nested txn 风险,因为 idle tick 已在 writeTxn 外另起)。
- **测产出 wallet 写回非默认地图时,fixture 必须先升境界**:山林是唯一 xueTu 起步 + 基础 1.0/1.0 地图,要测 cangJingGe / xuanYaPuBu 等高 rate 地图,fixture setUp 默认 xueTu 不够,必须先 writeTxn 改 character.realmTier。
