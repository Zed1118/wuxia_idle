# Phase 5 W6 升级 + service 实例化 + nullable provider 架构全交付收尾（2026-05-14）

> 写给下一会话开局后接 Week 7 的 Mac Opus 自己看。
> Phase 5 W6 4 commits 单日落地,tag `v0.3.0-w6` push origin。
> PROGRESS.md「当前阶段」段是单一信源；本文档补充「为什么这么做」与「下次开局必读」。

---

## 1. 一句话结论

Phase 5 W6 **升级路 c1-c7 单日交付**：isar→isar_community 3.3.2 + flutter_riverpod 3.x + riverpod_annotation 4.x + riverpod_generator 4.x + analyzer 5.x→9.x；8 个有 Isar 依赖的 service 全部实例化 + 9 个 service provider 走 nullable propagation 架构；widget 端 4 处 `Isar.getInstance` guard 全删；**架构层面销账 #23**（widget test 不接真 Isar 旁路问题）。`main` HEAD `50fb2df`，tag `v0.3.0-w6` push origin。**530/530** 测试，analyze 0 issues。60 文件 +604/-445 行。

---

## 2. commit 时间线（本会话）

| # | hash | 类型 | 简述 |
|---|---|---|---|
| 1 | `1e937df` | chore | 升 isar_community 3.3.2 + riverpod 3.x + 基础 provider（c1-c4，54 文件 +237/-161）|
| 2 | `4bee3c4` | docs | PROGRESS 同步 c1-c4 进度 |
| 3 | `f305bde` | feat | service 实例化 + nullable provider 架构（c5-c7，销账 #23，32 文件 +374/-287）|
| 4 | `50fb2df` | docs | W6 全交付收尾 + 销账 #23 + 重评估 #3 #18 |
| — | tag `v0.3.0-w6` | tag | Phase 5 W6 全交付 |

---

## 3. 关键决策链 + 反思（本会话新增）

### 3.1 起手 reality check 链（3 轮 pubspec 实测）

原计划 **S1（Riverpod 3.x）/ S2（Isar 4.x）分两 tag**，pub solver 实测后摸出 3 层硬约束:

1. **第 1 轮**：`isar 3.1.0` 锁 `analyzer <6`,挡住 riverpod_generator 4.x 的 `analyzer ^9` —— S1 单独跑不动
2. **第 2 轮**：发现 `isar 4.x` 在 pub.dev **只有 dev 预览**,真路是 fork `isar_community 3.3.2`（drop-in 兼容,API 仅 import 路径换名）
3. **第 3 轮**：`isar_community_generator 3.3.x` 依赖 `build ^4.0.0`,与 `riverpod_generator <3.0.0-dev.17` 的 `build ^2.0.0` 互斥 —— S2 单独也跑不动；3.2.x 用 `analyzer ^6.9` 又绑 `_macros 0.3.3` SDK 已砍

**结论**：**S1/S2 在 pub solver 层强绑**，原"独立小 tag"被 solver 驳回。走方案 B'（合并升级,单 tag `v0.3.0-w6` 含 4 commits）。

教训：**pubspec.yaml 升级路径必须 `dart pub outdated` + 抓 transitive 依赖约束**才能预判可行性。这次 reality check 3 轮成本（≈ 30 分钟），换了完整准确的方案 B，远低于"硬上 S1 撞墙再回滚"的代价。

### 3.2 nullable propagation 架构（c5 核心创新）

原计划 widget test 旁路 #23 用 `ProviderScope.overrides` 注入测试 Isar/mock service —— 但 FakeAsync 与真 Isar 不兼容、mock service 要 implement 所有方法,工作量大。

**实际架构**：让 `IsarSetup.instanceOrNull` 探测式 getter + `isarProvider` 返回 `Isar?` + service provider 走 `isar == null → service == null`。链路:

```
IsarSetup.instanceOrNull (未 init → null)
  ↓
isarProvider: Isar?  
  ↓
enhancementServiceProvider: EnhancementService?
  ↓
widget _persist:
  final service = ref.read(enhancementServiceProvider);
  if (service == null) return;  // 替代旧 Isar.getInstance guard
  await service.persistResult(...);
```

**收益**：
- widget test 不 init Isar 时**自动**短路 —— 不需要任何 override
- widget 端 4 处散点 `Isar.getInstance(_isarInstanceName)` guard 全删（enhance_dialog/forging_panel/technique_panel/tower_entry_flow）
- 散点的 `_isarInstanceName = 'wuxia_save_slot1'` 常量全删
- 测试旁路从 widget 端集中到 provider 层,生产代码不再含"测试相关"逻辑

**c6 被架构吃掉**：原计划"49 test 改 `ProviderScope.overrides` 注入 Isar"实际不需要 —— service-level test 直接 `XxxService(isar: IsarSetup.instance).method(...)` 构造,widget test 自动短路。原预估 600-900 行 diff 实际只用 660 行就把 c5+c6 同时做完。

### 3.3 service 哪些去 static 的判断

11 个 service 类（lib/services/）按 Isar 依赖分两类:

**实例化（8 个）**：persist / 写 Isar collection 的 service
- EnhancementService.persistResult
- ForgingService.persistResult
- DispelService.persistResult
- Phase2SeedService.seedP1-P5（全 writeTxn）
- MainlineProgressService.getOrCreate / recordVictory
- TowerProgressService.getOrCreate / recordClear / recordDefeat
- SeclusionService.getActiveSession / startRetreat / completeRetreat / abandonRetreat
- StageBattleSetup.buildTeams / buildTeamsForTower

**保持 static（3 个）**：纯函数无 Isar 依赖（结果回 caller 再写）
- CultivationService.recordSkillUsage
- TechniqueLearningService.learn
- BattleResolutionService.resolve

**混合策略**：同一 class 内的纯函数方法保留 static（如 EnhancementService.tryEnhance / useCrystalToGuarantee / DispelService.dispel / SeclusionService.canEnterMap / computeOutputs / StageBattleSetup.buildEnemyTeam），只有写 Isar 的方法改实例。Dart 允许 class 同时含 static + instance 方法,Lint 通过。

### 3.4 method tear-off 坑（Phase2SeedService）

`Phase2SeedService.seedP1` 改实例方法后,原 caller `onTap: () => _seedAndPush(Phase2SeedService.seedP1, ...)`（tear-off 引用 static 方法）失效。要么改成 closure `onTap: () => _seedAndPush(() => Phase2SeedService(isar: IsarSetup.instance).seedP1(), ...)`,要么用 method tear-off 实例 `Phase2SeedService(isar: ...).seedP1`。本次走 closure。

### 3.5 widget initState 同步 throw 坑

`SeclusionMapListScreen.initState` 内 `SeclusionService(isar: IsarSetup.instance).getActiveSession(...)` 直接构造时立刻 throw（未 init Isar 时）—— **不**被 FutureBuilder.snap.error 捕获（因为 throw 发生在 future 外）。修法：抽个 `_fetchActive()` helper,用 `IsarSetup.instanceOrNull` 短路,返回 `Future.value(null)`。

---

## 4. 销账 + 挂账重评估

| 挂账 | W6 后状态 | 备注 |
|---|---|---|
| **#23 widget test 不接真 Isar 旁路** | **✅ 架构销账** | nullable propagation 替代散点 guard,详见 §3.2 |
| **#3 riverpod_lint + analyzer 上限** | 🔍 部分解 + 新阻塞 | analyzer 升到 ^9 解开 isar 链路;但 custom_lint 0.8.x 锁 ^7.5/^8 与 riverpod_generator 4.x ^9 互斥,等 custom_lint 升级 |
| **#18 flutter build web 被 Isar 阻塞** | **🔍 验证为伪挂账** | 项目 `flutter build web` 直接报 "This project is not configured for the web"。GDD §2 锁 Windows 单平台,无 web target,isar_community native-only 与项目设计一致 |
| #28 闭关 widget e2e | 仍挂账 | service 实例化后理论可走 ProviderScope.overrides 注入真 tempDir Isar,但 FakeAsync 兼容仍是问题。留 W7+ |
| #2 DDD 目录整理 | 仍挂账 | Phase 5 收尾子项 |
| #12 LevelDiff 语义统一 | 仍挂账 | Phase 5 收尾子项 |

---

## 5. Week 7+ 起手指引

### 5.1 候选方向

| 优先级 | 候选 | 阻塞 | 备注 |
|---|---|---|---|
| 高 | **B 装备扩 30-50** | 无 | 当前 10 件,缺 20-40 件。fixture 写作 + numbers.yaml 数值梯度。无新系统,纯内容扩 |
| 高 | **D 心法扩 20-30** | 无 | 当前 6 件,缺 14-24 件。同 B 性质 |
| 高 | **A 爬塔 UI 路径** | 无 | schema + Service + fixture 已 W2 ready,缺 UI 串联（floor list / battle entry / drop）|
| 中 | **Phase 4 战斗结算扩展** | 无 | 掉装备 / 掉境界 / 散功代价等。从 GDD §5/§6 推具体设计 |
| 中 | **Phase 5 剩余条目**：#2 DDD / #12 LevelDiff / #28 闭关 e2e | 无 | 小颗粒清理 |
| 低 | **#30 闭关 3 维度扩展** | §12 #7 节气清单 + 农历库选型 | 需用户先决 |
| 低 | **C 奇遇 / E 武学领悟** | §12 #6 机缘值规则 | 需用户先决 |

### 5.2 推荐顺序

1. **W7**: A 爬塔 UI 路径（schema 已 ready,直接装配 UI 验收闭环）+ Pen Windows 视觉验收
2. **W8**: B 装备扩 30-50 + D 心法扩 20-30（双轨内容扩,可并行）
3. **W9**: Phase 4 战斗结算扩展（需要先讨论具体范围）
4. 之后看用户决策 §12 #6 / #7 拍板后接 C/E/#30

### 5.3 模型建议

- **W7 A 爬塔 UI**：sonnet 默认起手（UI 装配偏机械）,遇到复杂状态/动画再升 opus
- **W8 B+D 内容扩**：sonnet 全程（fixture + 数值审计）
- **W9 Phase 4**：起手前讨论先升 opus 拍板设计

---

## 6. 数据快照

- main HEAD: `50fb2df`
- tag: `v0.3.0-w6` push origin
- 测试: **530/530** 全过,analyze 0 issues
- 累计 commit（项目至今）：~70+ commits
- 累计 tag：v0.1.0-phase1 / v0.2.0-phase2 / v0.3.0-w1..w6
- Demo 内容量（GDD §7 对照）：主线 15/15 ✅ / 章节 3/3 ✅ / 爬塔 schema 30/30 ✅（UI 缺）/ 闭关 5/5 ✅ / 师徒 3/3 ✅ / 装备 10/30-50 / 心法 6/20-30 / 奇遇 0/20-30（阻塞）/ 武学领悟 0/30-50（阻塞）
- 关键架构: Riverpod 3.x + Isar community 3.3.2 + nullable propagation 测试旁路架构

---

## 7. 下次开局必读

1. PROGRESS.md「当前阶段」段 + 「下一步」段（已同步为 W7+ 候选）
2. 本文档 §5 候选 + §3 反思（特别 §3.2 nullable propagation 是 W6 留下的新约定）
3. **新建 service / provider 时遵循 §3.3 判断**：纯函数 static / 写 Isar 实例化
4. **新建 widget _persist 时遵循 §3.2 模板**：`ref.read(xxxServiceProvider)` + null 短路,不再用 `Isar.getInstance`

CLAUDE.md / GDD.md / numbers.yaml 不动。Mac 端写 lib/、data/*.yaml（顶层）、test/、docs/handoff/；DeepSeek 写 data/narratives/、data/lore/、data/events/。
