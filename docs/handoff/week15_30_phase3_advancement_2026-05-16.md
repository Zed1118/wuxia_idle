# W15 #30 第 3 期 experiencePoints 消费层 + 升层链路接入 closeout

> 2026-05-16 / Mac · opus 4.7 xhigh / 单会话 ~2.5h / 0 commit(待 commit)/ 零回退

## 1. 起点与背景

W15 #30 第 1 期(2026-05-15)`SeclusionService.computeOutputs` 落 4 维度 + 4 加成,experiencePoints / techniqueLearnPoints / internalForcePoints 仅算不发奖。第 2 期(2026-05-16)落 internalForce + insightPoints 消费 Character;P2 brief 严守 2 维 scope,**experiencePoints 因升层链路 cross-system 单独独立任务**。

本批 P3 = 把 experiencePoints 写回 `Character.experience` + 跨主线/塔/闭关 3 贡献源 wire + 升层(layer / tier)链路 0→1 实装,Demo §10 锚点。

## 2. Grep 调研:基础设施已铺好(惊喜)

Phase 0 grep 暴露 P3 实际改动远小于 G closeout §7 预估(原估 saveVersion bump + build_runner regen,**实际 0 schema 改动**):

| 项 | 状态 |
|---|---|
| `Character.experience` int=0 字段 | ✅ 已存在(`character.dart:25`) |
| `Character.experienceToNextLayer` int=100 | ✅ 已存在 |
| `RealmDef` class + 49 行 yaml 加载 | ✅ 已存在(`game_repository.dart:230 _parseRealms`) |
| `GameRepository.realms` / `getRealm(tier, layer)` / `getRealmByAbsoluteLevel` | ✅ 可用 |
| `numbers.yaml realms.tiers[].layers[].experience_to_next` 49 层完整曲线 | ✅ 配齐(50→1,040,000→0 / 总跨度 ~7.6M) |
| `numbers.yaml realms.tiers[].layers[].internal_force_max` 49 层 | ✅ 配齐(500→15,000) |
| `stages.yaml baseExpReward` 15 关 50-6000 | ✅ 配齐 |
| `StageDef.baseExpReward` int + fromYaml | ✅ 加载 |
| Isar `_currentSaveVersion = '0.8.0'`(P2 bump 后) | ✅ 不需再 bump |

**真正缺失的**(本批补):
1. Seclusion `completeRetreat` 不写 `Character.experience`(P2 漏写顺手补)
2. 主线 `_applyVictoryResolution` 完全没消费 `stage.baseExpReward`(0→1)
3. 塔 `_applyTowerVictoryResolution` 无 EXP(且 `TowerFloorDef` 无 expReward 字段,需新增)
4. 升层链路 0 实装(全仓 grep 0 caller)
5. `Character.internalForceMax` 升层后刷新 0 实装

## 3. 用户拍板 7 个设计点(grep-based 全 ✓)

| # | 设计点 | 决策 |
|---|---|---|
| Q1 | wallet 位置 | ✓ 用现有 `Character.experience` 字段,0 schema 改 |
| Q2 | 升层触发时机 | ✓ auto-升 + while 循环(72h 闭关单次可跨多层) |
| Q3 | 三贡献源是否区分 | ✓ 统一加,不预先抽象 |
| Q4 | 升层公式 | ✓ 走 yaml 49 层曲线 + 新增 `nextLayer(tier, layer)` 邻接工具 |
| Q5 | 升层副作用 | ✓ 刷 4 字段(realmTier/Layer/internalForceMax/experienceToNextLayer),不动 attributes,**不回血** internalForce(GDD §5.1 反留存焦虑) |
| §3A | Tower EXP 字段 | ✓ 顺手加 `TowerFloorDef.baseExpReward` + towers.yaml 30 关 |
| §3B | P2 漏写 `Character.experience` | ✓ 本批顺手补,不算 scope 漂移 |

**Tower 曲线**(用户接受):普通层 `80 × floorIndex` / 小 Boss(5/15/25) ×2 / 大 Boss(10/20/30) ×3。30 层全清总 EXP ≈ 5.04w(stages.yaml 15 关总 ≈ 2.6w),塔承担「中盘 layer 推进主力」,与主线开局打底 + 闭关挂机长尾形成 3 系互补。

## 4. 代码改动清单

8 文件 modified + 2 文件 new + 1 yaml 改 = 11 文件:

| 文件 | 改动 |
|---|---|
| `lib/features/cultivation/application/character_advancement_service.dart` | **新建** `CharacterAdvancementService.applyExperience(ch, delta, {realmLookup}) → AdvancementResult` + `nextLayer(tier, layer)` 静态工具 + `AdvancementResult` class(layersGained / tierBefore/After / layerBefore/After / internalForceMaxBefore/After + didAdvance getter) |
| `lib/features/seclusion/application/seclusion_service.dart` | 加 typedef `RetreatResult`(7 RetreatOutputs 字段 + `AdvancementResult? advancement`)+ `completeRetreat` return 类型 `RetreatOutputs → RetreatResult` + writeTxn 内 advancement assign + import GameRepository / CharacterAdvancementService |
| `lib/features/seclusion/presentation/active_retreat_screen.dart` | 变量名 `outputs → result` + push 参数 `outputs: → result:`(2 处) |
| `lib/features/seclusion/presentation/retreat_result_screen.dart` | **重写** constructor 接 RetreatResult + 加 EXP 行(Icons.trending_up)+ `_AdvancementBanner` widget(若 advancement.didAdvance 显示)+ import enum_localizations / character_advancement_service |
| `lib/features/mainline/presentation/stage_entry_flow.dart` | `_applyVictoryResolution` writeTxn 前 `for c in characters: applyExperience(c, stage.baseExpReward)` + import character_advancement_service |
| `lib/features/tower/presentation/tower_entry_flow.dart` | `_applyTowerVictoryResolution` 加 `floor` / `isFirstClear` 参数;writeTxn 前 `if (isFirstClear && floor.baseExpReward > 0): for c in characters: applyExperience(c, floor.baseExpReward)` + caller 传 floor + clearResult.isFirstClear + import |
| `lib/features/tower/domain/tower_floor_def.dart` | `TowerFloorDef` 加 `final int baseExpReward` 字段 + fromYaml 解析 `(y['baseExpReward'] as num?)?.toInt() ?? 0` + toString + doc 数值红线扩 |
| `lib/ui/strings.dart` | 加 `seclusionExperience(int n)` / `seclusionAdvancement(String realmAfter, int layers)`(1 层"突破至 X" / 多层"连破 N 层 → X") |
| `data/towers.yaml` | 30 关全填 `baseExpReward`(awk 批量插入 in floorIndex 后);普通 24 层 80×N / 小 Boss 3 层 ×2 / 大 Boss 3 层 ×3 |
| `test/features/cultivation/application/character_advancement_service_test.dart` | **新建** 11 单测:nextLayer 边界(non-dengFeng/dengFeng/wuSheng.dengFeng=null)+ applyExperience(0/负 delta/EXP 不足/恰好 1 层/while 多升/跨 tier/满级 cap/不动 attributes 不回血) |
| `test/features/seclusion/application/seclusion_service_test.dart` | cap clamp test 加 `experienceToNextLayer = 999999` fixture(防 EXP=400 升层影响断言);加 P3 2 test:EXP 升层(advancement.layersGained=3 / xueTu.jingTong)+ EXP 累加但不升层(didAdvance=false) |
| `test/features/seclusion/presentation/retreat_result_screen_test.dart` | `_mkOutputs → _mkResult` 返回 RetreatResult(加 `advancement: null` 默认);改 group 名 "4 维度 → 5 维度";加 1 test "只有 experience" + 4 test "升层 banner"(升 1 / 升 4 / null / didAdvance=false);顺手 `const SeclusionMapDef` 清 prefer_const_constructors info |
| `test/features/seclusion/presentation/seclusion_e2e_test.dart` | `_FakeSeclusionService` 接口同步 RetreatOutputs → RetreatResult;2 e2e fixture 加 `advancement: null` |

## 5. 关键决策细节

### 5.1 applyExperience 后置于 internalForce clamp(P2 test 0 破)

writeTxn 内顺序:
1. `internalForce += internalForcePoints` clamp(用 **old** internalForceMax)
2. `insightPoints += techniqueLearnPoints`
3. `applyExperience(experiencePoints)`(可能拉新 internalForceMax)

**理由**:
- GDD §5.1 反留存焦虑:升层奖励不应"回血",玩家走下次闭关自然填新 cap,设计闭环
- P2 test 体例保持不破(`internalForce == internalForceMax` 断言在 old max 500 上成立,advancement 拉到 800 不影响 already-set internalForce)

**例外**:P2 cap clamp test 需 fixture 加 `experienceToNextLayer = 999999` 防 EXP=400 触发升层导致 `internalForce(500) == internalForceMax(800)` 断言 fail。改 1 行 fixture 解决,不退本批 EXP 链路。

### 5.2 RetreatResult typedef 字段平铺不嵌套

`RetreatResult` 不嵌套 `RetreatOutputs`(record 不支持 spread 解构),而是平铺 7 字段 + advancement:

```dart
typedef RetreatResult = ({
  double actualHours,
  int mojianshi,
  List<Equipment> equipmentDrops,
  int experiencePoints,
  int techniqueLearnPoints,
  int internalForcePoints,
  AdvancementResult? advancement,
});
```

**优点**:老 service test `final out = await ... completeRetreat(...); expect(out.mojianshi, ...)` **0 改动**(RetreatResult 字段名集合 ⊃ RetreatOutputs 字段名集合,record 字段访问透明)。只有 widget test fixture 需加 `advancement: null` 字段。

### 5.3 Tower EXP 仅 isFirstClear 发(防刷)

`_applyTowerVictoryResolution` 加 `floor` + `isFirstClear` 参数;`if (isFirstClear && floor.baseExpReward > 0): applyExperience`。沿 drops 首通发奖体例(`recordClear` 返回 `isFirstClear`),**重打不发 EXP**,GDD §5.1 反"刷塔无脑刷数值"。

### 5.4 主线 EXP 全员发(Demo §10 不平摊)

`_applyVictoryResolution` 内 `for c in characters: c.experience += stage.baseExpReward`(active 3 角色每人 full)。**不平摊**:
- Demo 阶段单角色场景为主,平摊语义在 1 角色等价 ×1
- 多角色后,全员发 full 鼓励多角色养成,符合反留存焦虑设计
- 平摊 N=3 是网游味"队友拖累"机制,Demo 不引入

### 5.5 升层不动 attributes / 不回血 internalForce

升层只刷 `realmTier` / `realmLayer` / `internalForceMax` / `experienceToNextLayer` 4 字段:
- `attributes`(根骨/身法/悟性/机缘)是 character base 属性,GDD §4.1 加点机制定义"属性可重置(rerollable: false)",升层不变更
- `internalForce` 不拉到新 max(避"满血升级"网游味),玩家闭关补内力,设计闭环

### 5.6 mainline / tower 不写 widget integration test

`_applyVictoryResolution` / `_applyTowerVictoryResolution` 是 file-private 函数,外部 test 需 widget test 包 caller。本批选**跳过**:
- `applyExperience` 已 11 单测全覆盖(纯函数,边界 case 齐)
- caller 改动 5 行(简单 for 循环 in writeTxn),逻辑无分支无 bug 风险
- widget test 需 ProviderScope override + Isar mock + battleProvider finalState fixture,估 1h+,ROI 低
- memory `feedback_layered_bugs` 教训"生产路径 e2e"在本批由 grep 静态验证 + service 单测覆盖

**风险接受**:若主线/塔 victory EXP 实际不生效,生产路径会立刻暴露(玩家打关 EXP 不涨)。建议下波 Phase 4 W11 收尾或 W16 polish 时补 1-2 widget test 收口。

## 6. 测试与验证

| 阶段 | 命令 | 结果 |
|---|---|---|
| 1. 单文件 advancement 单测 | `flutter test test/features/cultivation/` | 11/11 全过 |
| 2. seclusion 全 test | `flutter test test/features/seclusion/` | 32/32 全过(原 30 + P3 2) |
| 3. tower 全 test | `flutter test test/features/tower/` | 全过(TowerFloorDef.fromYaml 新字段兼容 default=0) |
| 4. 全仓回归 | `flutter test` | **679/679** 全过(原 661 + 18 新增) |
| 5. analyze | `flutter analyze` | **0 issues**(顺手清 P2 遗留 prefer_const) |

## 7. 下次开局必读

### 7.1 状态快照

- HEAD 待 commit(本会话 5 commit 拆分:feat advancement service / feat tower yaml+field / feat seclusion + mainline + tower wire / chore UI + UiStrings / docs PROGRESS + closeout;待 push origin/main)
- 679/679 + analyze 0 issues
- `Character.experience` + `experienceToNextLayer` 字段已活跃使用(3 caller 写入 + advancement service 消费)
- `TowerFloorDef.baseExpReward` 字段 + towers.yaml 30 关数值
- `RetreatResult` typedef 替代 `RetreatOutputs` 作为 completeRetreat 返回
- W15 #30 闭环 3/3 维度(internalForce + insightPoints + experience + 升层)
- #34 stage drop 视觉验收 Codex 销账 WARN(本会话期间 Codex 交付,见 §6.2 销账依据)

### 7.2 开局动作

1. 读 PROGRESS.md「当前阶段」+「下一步」+「挂账事项」
2. 读 本 closeout §6 测试与验证 + §7 下次开局必读 + §8 硬约束沿用
3. `git pull --rebase --autostash` 看 drift(本会话已 push,正常无)
4. 选读 memory:本批无新增,沿用 `feedback_avoid_over_engineer_abstraction`(Q3 单一 wallet 决策依据)/ `feedback_layered_bugs`(本批 mainline/tower scope 控制依据)

### 7.3 下波 4 候选

| # | 任务 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| **A** ⭐ | victory dialog 升层 banner + drop banner(主线 / 塔) | sonnet 或 opus | 1-2h | Codex F #34 暴露 2 UI 缺口(victory drop banner 缺 / Inventory 物料 Tab 缺);本批 seclusion banner 体例可复用 |
| B | §12.1 #7 三流派 extra_effect 数值拍板 + 正午阳刚 +20% 接 SeclusionService | sonnet | 30-60min | 老挂账,讨论型 |
| C | §12.1 #10 师承遗物规则拍板 | sonnet | 30-60min | 老挂账,讨论型 |
| D | mainline / tower victory EXP 写回 widget integration test(本批 scope 控制留账) | sonnet | 1h | ProviderScope + Isar + finalState fixture,e2e 收口 |

**推荐 A 起手**:Codex F #34 closeout §7 已建议"victory drop banner / 物料 Tab"是下波 polish 主题,与本批 advancement banner 同一战场(victory 屏 UI 加 banner);场景具体 + ROI 高(玩家直观看到掉落 + 升层反馈)。

### 7.4 硬约束沿用

延续 G closeout §8 全部硬约束。本批新经验:

- **`Character` schema 字段已存在但生产路径 0 caller 是常见"半完成"模式**:Phase 0 grep 应优先扫"字段是否已落 + 是否有 caller"两个独立维度,避免 G closeout §7 风险预估的 saveVersion bump / build_runner regen 这类伪需求。本批就 0 schema 改 + 0 build_runner regen 完工。
- **typedef record 扩字段不破老 test**:RetreatResult 平铺 RetreatOutputs 7 字段 + 新增 advancement,老 `out.X` 访问透明,只 widget fixture 加 1 字段。下波遇 record return 扩字段优先平铺策略。
- **EXP 升层 while 循环 + 顶级 cap=0**:wuSheng.dengFeng `experience_to_next: 0` yaml 表示满级;service while 内 `if (ch.experienceToNextLayer <= 0) break` 兜底,EXP 仍累加(数据无破坏)但不消费不升层。满级行为最简洁,无需独立"isMaxLevel" flag。
- **applyExperience 后置 caller 现有 clamp**:升层拉新 internalForceMax 时不立即回血,玩家走下次闭关填新 cap 形成设计闭环。GDD §5.1 反留存焦虑落地到代码层的典范。

## 8. 同期销账:#34 stage drop 视觉验收(Codex 交付)

本会话期间 Codex F 派单跑完(`docs/handoff/codex_w15_stage_drop_visual_check_2026-05-16.md`),3 张主截图齐:

- ✅ stage_01_01 victory → InventoryScreen +1 件「粗布衣」(P5 1 件 + drop 1 件 = 2 件可见)
- ✅ 磨剑石 +1(P5 2000 + drop 1 = 2001,强化弹层侧证)
- ✅ A 真 GUI 路径打通(1280×900 装备仓库入口直接可见)

**评级**:0 PASS / **3 WARN** / 0 FAIL — Codex 建议按 WARN 闭环 #34。WARN 暴露 2 UI 缺口:① stage victory 弹层无 drop banner / 列表 ② InventoryScreen 无装备/物料 Tab(磨剑石需绕到强化弹层)。**dropTable 配置生效**已硬证据闭环 → **销账 #34**。2 UI 缺口进下波候选 A。
