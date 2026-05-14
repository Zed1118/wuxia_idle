# W14-1 C 任务奇遇/武学领悟 vertical slice closeout(2026-05-14)

> 写给下一会话开局者(Mac Opus 自己)+ C-W14-2/3 继续推进的人。
> 本文是 GDD §7.2 奇遇/武学领悟系统从 0 → 端到端跑通的总结。
> 单 commit `8ecdbe3`,**572/572**,analyze 0 issues。

---

## 1. 一句话结论

GDD §7.2 奇遇/武学领悟系统 unified 模型 vertical slice **跑通**:数据/逻辑/UI/test 完整闭环,3 条 encounter(bamboo_listen_rain / cha_ting_dui_ju / du_ke_wen_dao)端到端可触发。决策点 4 条全 lock(`§12 #6` 不再阻塞)。biome / weather / 挂机 tick / 闭关 hook / 余 23 events outcome map 留 C-W14-2/3。

---

## 2. 决策点 4 条 lock(用户拍板)

| # | 决策点 | 选项 | 公式/实现 |
|---|---|---|---|
| Q1 | §12 #6 机缘值累积 | **多维度 counter**,无全局机缘值 | `SchoolKillCount @embedded` per school,AND 语义满足全部 threshold |
| Q2 | 奇遇 vs 武学领悟 | **Unified**:武学领悟是奇遇的一个 type | `EncounterType.techniqueInsight` / `fortuneEvent` / `trial` / `karma`,单一 EncounterService |
| Q3 | fortune 软概率公式 | `base * (1 + fortune/20)` | fortune ∈ [1,10] → 系数 [1.05, 1.5] |
| Q4 | outcome 数值化范围 | 领悟新招 + 属性微调 + skip | `OutcomeType.unlockSkill` / `attributeBonus` / `none`,lifetime cap 5 |

**Q5(plan 边界)**:Phase 1 只用 enemy school 维度做 vertical slice,biome/weather 等 C-W14-2 补字段再加。

---

## 3. 实现栈(commit `8ecdbe3` 内容)

### 3.1 数据层

| 文件 | 角色 |
|---|---|
| `lib/data/defs/encounter_def.dart` | `EncounterDef` + 4 枚举(EncounterType / OutcomeType / AttributeKey / EncounterTrigger)+ `OutcomeDef` + yaml fromYaml |
| `lib/data/models/encounter_progress.dart` | Isar @collection:`triggeredEncounterIds` + 4 属性累计 + 奇遇专属 `unlockedSkillIds` + `SchoolKillCount @embedded` + `MapLikeOnSchoolKill` extension(同 SkillUsageEntry 体例) |
| `lib/data/encounter_event_loader.dart` | events/<id>.yaml 按需 load(沿用 NarrativeLoader 体例,placeholder 兜底) |
| `data/encounters.yaml` | 3 条 vertical slice(bamboo_listen_rain / cha_ting_dui_ju / du_ke_wen_dao) |

### 3.2 服务层

`lib/services/encounter_service.dart`:
- `getOrCreate(saveDataId)` — 初始化进度行
- `recordKill(saveDataId, defeatedSchools)` — 战斗 victory hook 调,W13 教训 `List.of` 转 growable
- `evaluateTriggers(saveDataId, attributes, encounters, rng)` — 评估候选,fortune 软概率 + 首个 roll 过返回
- `markTriggered(saveDataId, encounterId)` — UI 弹出前标记,防重复触发
- `applyOutcome(saveDataId, encounter, outcomeId)` — 三种 OutcomeApplied(`UnlockSkillApplied` / `AttributeBonusApplied` / `AttributeCapReached` / `NoneOutcome`)
- `attributeGainCap=5`(GDD §4.1 line 183 "生涯 +3~5 点"),达 cap 静默吞不抛错

### 3.3 UI 层

`lib/ui/encounter/encounter_dialog.dart`:
- `showEncounterDialog(context, def, content)` → 返回 outcomeId(String?)
- 三段式:title + opening 文 → choices 按钮列表 → outcome body + 确认 → 返回
- `showEncounterOutcomeBanner(context, applied)` SnackBar 摘要呈现

### 3.4 注入点(stage_entry_flow)

`lib/ui/mainline/stage_entry_flow.dart`:
- 新 `_checkAndShowEncounter(context, ref, stage)` 函数
- **位置**:`runStageFlow` 末尾,victory narrative 推完之后(通关剧情是这关收尾,奇遇作为下一段开端)
- 流程:recordKill → evaluateTriggers → load events → showDialog → applyOutcome → SnackBar
- 异常静默 catch + debugPrint(W13 教训)

### 3.5 接入

- `lib/data/isar_setup.dart`:加 `EncounterProgressSchema`,schema 升 **0.4.0 → 0.5.0**
- `lib/data/game_repository.dart`:
  - 字段 `encounterDefs: Map<String, EncounterDef>`
  - loadAllDefs 加载 `data/encounters.yaml`(测试 fixture 不带时静默)
  - `_enforceEncounterRedLines`:threshold > 0 + fortuneRequired ∈ [1, 10]
  - `findEncounter(id)` + `allEncounters` 查询便捷方法
- `lib/providers/isar_provider.dart`:加 `encounterServiceProvider`(nullable propagation)

---

## 4. 测试覆盖增量

| 文件 | 新增 case | 覆盖 |
|---|---|---|
| `test/services/encounter_service_test.dart`(新) | 10 | getOrCreate + recordKill(含 W13 fixed-length 回归)+ evaluateTriggers(threshold / fortune / 软概率 / markTriggered 跳过)+ applyOutcome(unlockSkill 去重 / attributeBonus + lifetime cap / skip none) |
| `test/data/encounter_yaml_test.dart`(新) | 10 | 3 条 encounters.yaml 解析正确 + allEncounters 排序 + findEncounter null safe + resolveOutcome skip fallback + fromYaml 边界 |
| `test/data/isar_setup_test.dart` | 1 修 | saveVersion 0.4.0 → 0.5.0 |

**552 → 572(+20),analyze 0 issues**。

---

## 5. 关键挂账(W14-2/3 待处理)

- **C-W14-2**(high):stages.yaml / 闭关地图 yaml 加 `biome` / `weather` 字段 + `EncounterDef` 加多维度 trigger + `seclusion_service.computeOutputs` 加 tickIdle hook + encounters.yaml 扩 10-15 条 + tower_entry_flow victory 也接 recordKill
- **C-W14-3**(medium):26 个 events outcome 全 map + dialog 节奏细化 + Codex 桌面 Pen 跑视觉验收
- **奇遇专属 skill 池**:`unlockedSkillIds` 当前 append-only 字符串,W14-2 加 `data/encounter_skills.yaml` + 接战斗系统消费
- **挂账 #34 / #30 / #28 / #31**:沿用 W13 closeout 未变

---

## 6. 关键工程教训(memory 沉淀)

### 6.1 W13 教训复用(无新踩坑)

- **fixed-length list 防御**:`SchoolKillCount @embedded` 走 W13 体例,caller `List.of` 转 growable + 一条 test 回归
- **catch 加 debugPrint**:stage_entry_flow `_checkAndShowEncounter` 两处 catch 都 print 出 e + st
- **service-level test 全过 ≠ 真生产路径落地**:W14-2 接 tower 后必须 e2e 验,不能只看 service test

### 6.2 设计 / 决策框架

- **决策点先 lock 再编码**:4 个决策点用 AskUserQuestion 一次性问完,不猜不补脑
- **vertical slice 优先**:Phase 1 不追求完整(3 条 encounter / 仅 school 维度 / 仅战斗 hook 一处),先把端到端走通,扩量留 Phase 2/3
- **加载层强校验,运行层 placeholder 兜底**:encounters.yaml 红线 fail-fast(数值层);events/<id>.yaml 缺失 placeholder(文案层,DeepSeek 异步补)
- **存档 schema 版本号是 W14-1 类工作的副作用,必须改 + 同步改测试期待值**

---

## 7. 数据快照

- main HEAD: `8ecdbe3`
- tag: `v0.4.0-w11` 未动(W14-1 不打新 tag,留 W14-3 整体闭环后打 `v0.5.0-w14`)
- 测试: **572/572** 全过,analyze 0 issues
- 累计 commit(项目至今): ~96 commits
- Demo 内容量:主线 15/15 ✅ / 章节 3/3 ✅ / 爬塔 30/30 ✅ / 闭关 5/5 ✅ / 师徒 3/3 ✅ / 装备 35/30-50 ✅ / 心法 21/20-30 ✅ / **奇遇 3/20-30(W14-2/3 扩)** / **武学领悟 1/30-50(W14-2/3 扩)**
- 关键架构: 在 W13 基础上 + **EncounterService + EncounterProgress collection + fortune 软概率 + lifetime cap 5**(W14-1)

---

## 8. 下次开局必读

1. `PROGRESS.md` 「当前阶段」段(W14-1 vertical slice 闭环)+「已完成」首条 + 「下一步」W14-2/3 候选
2. 本文档 §3 实现栈 + §5 挂账
3. **C-W14-2 起手**:先动 stages.yaml + 闭关地图 yaml 加 biome / weather 字段(schema 改动),再扩 `EncounterTrigger`(加 biomeMinutes / weatherMinutes / enemyClassKills 字段),最后扩 encounters.yaml 10-15 条 + tower_entry_flow 接 recordKill
4. **W14-3 起手**:写 `data/encounter_skills.yaml`(奇遇专属 skill 池)+ 接战斗系统消费 unlockedSkillIds + dialog 节奏细化

CLAUDE.md / GDD.md / numbers.yaml 不动。Mac 端写 `lib/` `data/*.yaml`(顶层)`test/` `docs/handoff/`;DeepSeek 写 `data/narratives/` `data/lore/` `data/events/`;Codex 桌面 @ Pen 写 `docs/screenshots/` + `docs/handoff/codex_*.md`。
