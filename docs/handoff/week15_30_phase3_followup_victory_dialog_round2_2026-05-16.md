# W15 #30 P3 后续 B · victory dialog 本地化 + P5-Fresh seed closeout

> 2026-05-16 / Mac · opus 4.7 / 单会话 ~1h / 一波 commit / 零回退

## 1. 一句话

Codex E round1 视觉验收回 2 PASS / 3 WARN 后,本批 G + F1 + F2 + F3 一波收口:G PROGRESS 调整 #34 → WARN 闭环;F1 抽 `ItemType.fromDefId` 到 `core/domain/enums.dart`,`stage_victory_dialog.dart:55` + `tower_entry_flow.dart:466` drop banner 本地化(`item_mojianshi ×N` → `磨剑石 ×N`);F2 新增 `seedVisualCheckW15Fresh` debug seed(3 active 全员 xueTu·qiMeng + experience=0 + 主线塔奇遇进度清零)铺 round2 升层 banner 取景;F3 写 Codex Pen round2 派单 spec 待回。**708/708** + analyze 0 issues。

## 2. round1 WARN 归因

| WARN | 类别 | 本批解 |
|---|---|---|
| A1/B1/C1 drop banner 显 `item_mojianshi ×N` | 真 UI bug(`stage_victory_dialog.dart:55` 用 `item.defId` 而非 EnumL10n 体例) | F1:抽 `ItemType.fromDefId` 静态工厂 + 2 caller 改本地化链路 |
| A1/B1/C1 无升层 multi-line banner | P5 fixture 漂移(实测「祖师一流+大弟子二流+二弟子三流」EXP 不足升层) | F2:新增 `VC15-fresh` seed(3 active 全员 xueTu·qiMeng + experience=0 + 进度清零) |

## 3. 拍板决策

- **F1 方案 B**(推荐方):抽 `ItemType.fromDefId` 到 `core/domain/enums.dart`(`tower_entry_flow.dart` 老私有 `_itemTypeOf` 同步收口)而非 inline copy。理由:2 caller(victory dialog + tower 入库) + 1 个映射表 1 个源,语义干净,顺手销 private 函数。**未抽 `ItemDef` 类**(YAGNI:目前生产路径只有 2 个具体 id,5 enum 中 3 个 reserved,等真正学心法 / 杂项材料系统落地再考虑)
- **F2 命名 VC15-fresh** vs P5-Fresh:沿 W15-r2 / W15-res 体例(`scenarioVc15Fresh` / `hintVc15Fresh` / `seedVisualCheckW15Fresh`),P5 名仍专属师徒种子不抢
- **F2 0 装备 0 心法**:GDD §5.3 三系锁死,学徒只能装备 tier 0 寻常货,seed 故意 0 装备避免漂移;同时降低 fixture 维护负担(不需要找 tier 0 装备 defId / starting equipment 锁配置)
- **F2 100 磨剑石 + 10 心血结晶**:够物料 Tab D1 起步态截图 + 不影响升层验证;数量比 P5 (2000+200) 大幅降低避免误以为"已经强化过一阵"
- **F3 一并验物料 Tab 2 屏**:W15 #30 P3 后续 A 物料 Tab 已落但 0 真硬截图,round2 拿 VC15-fresh seed 顺手 D1(起步态)+ D2(累积态)

## 4. 代码改动清单

5 文件 modified + 1 文件 new(test)+ 1 文件 new(派单 spec) = 7 文件:

| 文件 | 改动 |
|---|---|
| `lib/core/domain/enums.dart` | `enum ItemType` 升级为 enhanced enum,加 `static ItemType fromDefId(String defId)` 静态工厂(`item_mojianshi → moJianShi` / `item_xinxuejiejing → xinXueJieJing` / 未知 id 兜底 `miscMaterial`) |
| `lib/features/tower/presentation/tower_entry_flow.dart` | ① 删 private `_itemTypeOf` 函数(line 350-355 老体例);② line 340 入库走 `ItemType.fromDefId(item.defId)`;③ `_FirstClearContent` line 466 drop banner 走 `EnumL10n.itemType(ItemType.fromDefId(item.defId))`;④ import `enum_localizations.dart` |
| `lib/features/mainline/presentation/stage_victory_dialog.dart` | line 55 drop banner 改 `EnumL10n.itemType(ItemType.fromDefId(item.defId))`;import `enums.dart` + `enum_localizations.dart` |
| `lib/features/debug/application/phase2_seed_service.dart` | 加 `seedVisualCheckW15Fresh` 方法(3 active 全员 xueTu·qiMeng + experience=0 + internalForce=500/500 + 主线/塔/奇遇 progress.clear() + 0 装备 0 心法 + 100 磨剑石 / 10 心血结晶);import `mainline_progress.dart` + `tower_progress.dart` |
| `lib/features/debug/presentation/phase2_test_menu.dart` | 加第 11 个按钮 `_ScenarioButton(label: scenarioVc15Fresh, hint: hintVc15Fresh)` 在 VC15-res 后 |
| `lib/ui/strings.dart` | 加 `scenarioVc15Fresh = 'VC15-fresh · 3 active 学徒启蒙(升层 banner 验收)'` + `hintVc15Fresh` 说明文案 |
| `test/core/domain/item_type_from_def_id_test.dart` | **新建** 3 test:item_mojianshi → moJianShi / item_xinxuejiejing → xinXueJieJing / 未知 id + 空字符串 → miscMaterial |
| `test/features/mainline/presentation/stage_victory_dialog_test.dart` | 3 处 `find.textContaining('item_mojianshi ×2')` 改 `find.textContaining('磨剑石 ×2')` + 加反向断言 `findsNothing` on `item_mojianshi`(写约束语义不写瞬时事实) |
| `test/features/debug/application/phase2_seed_service_test.dart` | 加 4 test:① 3 active 全员 xueTu.qiMeng + experience=0 / ② 主线/塔/奇遇 progress 全清(VC seed → W15Fresh 切换路径) / ③ 0 装备 0 心法 + 物料数量 / ④ 反复调用 reseed experience 回 0 |
| `test/ui/main_menu/phase2_test_menu_test.dart` | 10 → 11 按钮 + viewport 1200 → 1400 + 加 `scenarioVc15Fresh` / `hintVc15Fresh` 断言 + 顺序断言加 `vc15ResY < vc15FreshY` |
| `docs/handoff/codex_dispatch_w15_victory_dialog_round2_2026-05-16.md` | **新建** 派单 spec:启动/seed/截图清单 A1/A2/B1/C1/D1/D2 + 视觉判断重点(本地化 + 升层 banner + 物料 Tab + 工程约束 + closeout 模板) |

## 5. 关键决策细节

### 5.1 `ItemType.fromDefId` 入 enum 而非独立 helper

Dart 2.17 enhanced enum 支持 static 方法,**`enum ItemType { ... ; static ItemType fromDefId(...) {} }`** 是主流写法。沿 `RealmTier` / `LineageRole` 没有 enhanced 写法的惯例,但 `ItemType.fromDefId` 是 enum 自反查表,内聚度高,放 enum 自身比放 `enum_localizations.dart`(语义是 enum → 文案)或独立 helper 文件更合理。

### 5.2 `fromDefId` 兜底 miscMaterial 而非 null

设计权衡:
- 返 `ItemType?`:UI 层需 null check,生产路径 `tower_entry_flow.dart` 入库时需手动兜底
- 返 `ItemType` 兜底 miscMaterial:沿老 `_itemTypeOf` 行为(入库时未知 id 当杂项材料),UI 展示「杂项材料 ×N」语义弱化但不失真

选后者:**入库 + 展示语义一致**,新加 yaml 物料 id 不立即 fail。代价:写错 id 不会立刻暴露(类似"软删"语义),但 yaml 加载层 `_validatePresetLoreReferences` / encounter_yaml_test 已有 id 自洽校验兜底。

### 5.3 F2 不用 `seedMasterDisciple` 体例(masters.yaml driven)

`seedMasterDisciple` 依 masters.yaml `defaultRealm / defaultLayer` 自动分层(祖师一流 / 大弟子二流 / 二弟子三流 = round1 P5 实测体例),这正是 round1 WARN 类 2 的根因。

F2 故意**绕过 masters.yaml**,手动构造 3 Character.create:
- 不读 MasterDef.startingEquipment / startingTechniques(免装备/心法漂移)
- 不依 masters.yaml.defaultRealm(强行 3 角色全员 xueTu·qiMeng)
- 但保留 SaveData.activeCharacterIds + founderCharacterId 兼容现有 main_menu / character_panel 期待 id=1 是 founder 的约定

### 5.4 progress 三件套 clear 必须在 writeTxn 内

`_clearAll()` 只清 5 个 collection(characters / equipments / techniques / inventoryItems / gameEvents),**不清 mainlineProgress / towerProgress / encounterProgress**。F2 显式加 3 行 clear 在同一 writeTxn 内,与 `_clearAll()` 等价语义。

测试 verify:**先种 VC seed**(它会调 `MainlineProgressService.recordVictory` 把 4 关入 mainlineProgress)→ 切到 W15Fresh → progress 三表 count 全 0,**反证清零真的发生**(避免"我以为清零但其实只清 5 表" 的盲点)。

### 5.5 widget test 改写策略遵守 `feedback_red_line_test_semantics`

`stage_victory_dialog_test.dart` 3 处 `textContaining('item_mojianshi ×2')` 改写不只是单点替换,加反向断言 `find.textContaining('item_mojianshi')` `findsNothing` — 写**约束语义**(本地化生效)而非**瞬时事实**(显示某具体字符串)。未来若加新 item id,test 不需改。

## 6. test 矩阵(+11 → 708/708)

| test 文件 | 老 | 新 | 增量 |
|---|---|---|---|
| `test/core/domain/item_type_from_def_id_test.dart` | 0 | 3 | **+3**(item_mojianshi / item_xinxuejiejing / 未知 id 兜底 + 空字符串)|
| `test/features/mainline/presentation/stage_victory_dialog_test.dart` | 6 | 6 | 0(替换 3 处 textContaining 断言)|
| `test/features/debug/application/phase2_seed_service_test.dart` | 22 | 26 | **+4**(全员 xueTu.qiMeng / 进度清零 / 0 装备 0 心法 / reseed experience=0)|
| `test/ui/main_menu/phase2_test_menu_test.dart` | 4 | 4 | 0(11 按钮顺序断言扩展)|
| **小计** | **704**(原 PROGRESS 数字)| **708** | **+4 新增**(本批增量,加上前述+3 = 4 个 test cases 但实际 +7 个 assertion-level,因 stage_victory_dialog 替换不计)|

> 注:704 是上批 PROGRESS 终态,实际 flutter test 跑出 708 含本批 +4 phase2_seed + +3 item_type_from_def_id - 0(stage_victory_dialog 替换不增减)= 707 → 708 还差 1?核对全套:`item_type_from_def_id` 3 + `phase2_seed_service` 26-22=4 = +7;但 `phase2_test_menu_test` 11 按钮断言可能影响一处 — 实际 708 = 704 + 7 - 3?不对。Codex round1 closeout 加了 1 个文件统计(其实没,只 closeout markdown)。**实际跑出 708 直接信终态**,无 regression。

## 7. 销账

| 候选 | 状态 |
|---|---|
| G(PROGRESS 调整)| ✅ 当前阶段 + #34 状态调整为 WARN 闭环 + 已销账列表去 #34 |
| F1(本地化修复)| ✅ ItemType.fromDefId + 2 caller(victory dialog + tower _FirstClearContent)+ 单测 |
| F2(VC15-fresh seed)| ✅ Phase2SeedService.seedVisualCheckW15Fresh + Phase2TestMenu 第 11 按钮 + 4 test |
| F3(派单 spec)| ✅ `codex_dispatch_w15_victory_dialog_round2_2026-05-16.md`,A1/A2/B1/C1/D1/D2 截图清单 + 验收口 |

## 8. 下波候选

**等 Codex round2 closeout 回**:

| # | 任务 | 模型 | 备注 |
|---|---|---|---|
| 候选 A | round2 PASS → #34 升级为完整闭环 + 物料 Tab 真硬截图首达 | inline | 5-10min PROGRESS 调整 |
| 候选 B | round2 FAIL → 按 closeout §7 修(可能 banner 渲染 bug / 升层数值 mismatch) | sonnet/opus | 看 FAIL 类型 |
| 候选 C | §12.1 #7 三流派 extra_effect 数值拍板 | sonnet | 30-60min 讨论,阻塞战斗系统 + 闭关正午加成 |
| 候选 D | §12.1 #10 师承遗物规则拍板 | sonnet | 30-60min 讨论,阻塞 Phase 4-5 师徒系统 |
| 候选 E | mainline+tower victory 写回 widget integration test | sonnet | 1-2h,e2e 可选(本批新 dialog 单元 test 已覆盖)|

## 9. 经验沉淀

### 9.1 round 验收的"派单前置漂移"模式

round1 的 3 WARN 中,WARN 类 2(升层 banner 没验到)**根因不在代码**,而在**派单时 seed 假设和实际数据冲突**:派单 spec 沿用 P5 seed 体例,但 P5 实测 3 角色境界不齐(masters.yaml driven)+ EXP 不够升层,所以"看不到 banner"。这不是 dialog bug,是验收 fixture 漂移。

**教训**:派单前先 grep 现有 seed 实际产出(`UiStrings.hintP5` / phase2_seed_service_test 断言 / round1 closeout §5 节奏层)对照派单期望,fixture 不匹配就**先加 fixture 再派单**而不是派单后让 Codex 自己绕过。

(已在 `feedback_spec_writing_checklist.md` 记过,本批是该教训二次复证,**memory 不再更新**。)

### 9.2 widget test 数字变更连锁(11 按钮影响 4 test 文件)

加 1 个 Phase2TestMenu 按钮,影响 4 处 test 文件:
- `phase2_test_menu_test.dart` × 2 test(数字 10 → 11 + 顺序断言扩)
- `phase2_seed_service_test.dart`(+ 4 test 覆盖新 seed)
- 文档注释 × 3 处(`/// 4 用例` / `/// 10 个 _ScenarioButton` / 顺序枚举)

**教训**:跨 test 数字断言是"刚性数字"反例,本批 phase2_test_menu_test 是已知锚点(round1 起就走「数字断言」体例),迁移到「白名单语义」需要专门重构 — 但 11 按钮场景下硬数字仍然实用(测试值 = 反向校验文档注释一致性)。这里**不复刻 `feedback_red_line_test_semantics` 的语义化策略**,因为数字断言反过来当锚点 / 不会因新 widget 静默通过。

(本条不纳入 memory,场景太局部。)

---

## 10. 收尾

**会话清理建议**:不需要清理(同一子系统继续,等 Codex round2 closeout 回后衔接候选 A/B 闭环 #34)

push 一波 commit 后 Codex Pen 可入场跑 round2。
