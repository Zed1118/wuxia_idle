# W14-2 C 任务 biome/weather + 闭关 idle tick + tower 接入 closeout(2026-05-14)

> 写给下一会话开局者(Mac Opus 自己)+ W14-3 继续推进的人。
> 用户离线 1 小时期间自主推进 11 个子任务全闭环。
> 单 commit + **590/590**,analyze 0 issues。

---

## 1. 一句话结论

W14-1 单维度(school)奇遇 trigger 扩到 **4 维 AND 语义**(school + biome + weather + fortune),闭关挂机时长(actualHours × 60)喂 biome/weather 累计,爬塔 victory 也接奇遇 hook,encounters.yaml 3→15 条。`§12 #7 节气清单`决策仍阻塞 — 但 W14-2 用 yaml 静态 biome/weather 标签绕开,**无人类决策依赖即闭环**。

---

## 2. 决策点 lock(自主拍板,可推翻)

| # | 决策点 | 选项 | 备注 |
|---|---|---|---|
| Q1 | biome 枚举范围 | **15 值**(覆盖主线 + 闭关 + encounter 专用) | 用户拍板 |
| Q2 | weather 枚举范围 | **5 值**(clear/rain/snow/mist/night,night 合并入 weather) | 用户拍板,不另起 TimeOfDayPhase |
| Q3 | 闭关 biome/weather 字段位置 | **numbers.yaml retreat.maps 内 append** | 用户拍板,不另起 seclusion_extras.yaml |
| Q4 | stages.yaml biome 映射 | 自主拍板,见 §4.1 | 战斗时长太短无意义,**战斗不喂 biome/weather**,仅闭关挂机喂 |
| Q5 | 嵌套 writeTxn 解 | 闭关 idle tick **分两 txn**(mojianshi 已落地后再喂奇遇) | 原子性损失:idle tick 失败仅缺奇遇累计,不破坏闭关数据 |
| Q6 | tower 是否复用 hook | **抽 `runEncounterHookAfterVictory` 共享** | encounter_hook.dart 新文件,stage + tower 双端 import |
| Q7 | W14-2 新 12 条 events 文案 | **走 placeholder** | DeepSeek 异步补,加载层兜底 |

---

## 3. 实现栈

### 3.1 枚举(`lib/data/models/enums.dart`)

```dart
enum EncounterBiome {
  mountainPath, inn, dock, cityWall, escortRoad, teaHouse, smithy,
  drillGround, alley, temple, mountainForest, swordTomb,
  cliffWaterfall, cliff, bambooForest,  // 15 值
}
enum EncounterWeather { clear, rain, snow, mist, night }  // 5 值
```

### 3.2 数据层

| 文件 | 改动 |
|---|---|
| `lib/data/defs/encounter_def.dart` | `EncounterTrigger` 加 `biomeMinutes` / `weatherMinutes` Map 字段 + 通用 `_parseEnumIntMap` |
| `lib/data/models/encounter_progress.dart` | 加 `BiomeMinutes` / `WeatherMinutes` @embedded 类 + `MapLikeOn{Biome,Weather}Minutes` extension `addMinutes` |
| `lib/data/defs/stage_def.dart` | 加 `biome` / `weather` nullable 字段 + fromYaml |
| `lib/data/defs/seclusion_map_def.dart` | 同上 |
| `lib/data/isar_setup.dart` | schema 升 0.5.0 → **0.6.0** |
| `lib/data/game_repository.dart` | `_enforceEncounterRedLines` 扩 biome/weather 分钟阈值 > 0 |

### 3.3 服务层

`lib/services/encounter_service.dart`:
- 新 API `recordIdleMinutes({saveDataId, biome, weather, minutes})`
- `_checkTrigger` 扩 biome + weather AND 校验
- W13 fixed-length list 教训沿用(`List.of` 转 growable)

`lib/services/seclusion_service.dart`:
- 构造加 optional `encounterService` 字段(默认 null = 不喂)
- `completeRetreat` writeTxn 之后单独跑 `_feedEncounterIdleMinutes`(嵌套 writeTxn 不允许,分两 txn)
- `_feedEncounterIdleMinutes`:`actualHours × 60` → recordIdleMinutes,异常静默 + debugPrint

### 3.4 UI 层

新文件 `lib/ui/encounter/encounter_hook.dart`:
- `runEncounterHookAfterVictory(context, ref, defeatedSchools)` 共享 hook
- stage_entry_flow 改 import + call helper(删原 `_checkAndShowEncounter`)
- tower_entry_flow 加 import + 在 victory narrative 之后 call

`lib/ui/seclusion/active_retreat_screen.dart`:
- new SeclusionService 时注入 EncounterService(ActiveRetreatScreen 是 StatefulWidget 不是 ConsumerStatefulWidget,不走 provider,直接 new)

### 3.5 Provider

`lib/providers/isar_provider.dart`:
- `seclusionServiceProvider` 注入 `EncounterService(isar)` 给 `SeclusionService`

### 3.6 数据

- `data/stages.yaml`:15 关全标 biome + weather(见 §4.1 映射)
- `data/numbers.yaml`:5 张闭关图加 biome + weather(append,既有数值不动)
- `data/encounters.yaml`:扩 12 条(见 §4.2 清单)

---

## 4. 配置映射

### 4.1 stages.yaml biome / weather 映射

| stage | biome | weather |
|---|---|---|
| stage_01_01 山门之外 | mountainForest | clear |
| stage_01_02 荒山野店 | inn | clear |
| stage_01_03 黑风岭 | mountainPath | mist |
| stage_01_04 洛阳城外 | cityWall | clear |
| stage_01_05 风雨渡口 | dock | rain |
| stage_02_01 镖局护送 | escortRoad | clear |
| stage_02_02 茶馆论剑 | teaHouse | clear |
| stage_02_03 春水堂 | smithy | clear |
| stage_02_04 城外校场 | drillGround | clear |
| stage_02_05 巷中夜雨 | alley | night |
| stage_03_01 武林会 | cityWall | clear |
| stage_03_02 许昌擂台 | drillGround | clear |
| stage_03_03 山寺夜话 | temple | night |
| stage_03_04 雁门旧事 | mountainPath | mist |
| stage_03_05 一剑封名 | drillGround | night |

闭关地图:
- shanLin → mountainForest, clear
- guJianZhong → swordTomb, mist
- cangJingGe → temple, clear
- xuanYaPuBu → cliffWaterfall, rain
- duanYaJueBi → cliff, snow

### 4.2 W14-2 新增 12 条 encounter

| # | id | type | trigger | outcome 亮点 |
|---|---|---|---|---|
| 4 | gu_jian_zhong_yin | techniqueInsight | swordTomb 60 + mist 30 + fortune 4 | unlock relic_blade |
| 5 | cang_jing_ge_wu | techniqueInsight | temple 120 + fortune 3 | enlightenment +1 / fortune +1 |
| 6 | shan_lin_qi_yu | fortuneEvent | mountainForest 90 + fortune 2 | 早期友好 |
| 7 | xuan_ya_pu_bu_li_lian | techniqueInsight | cliffWaterfall 60 + rain 60 + fortune 5 | unlock water_qi |
| 8 | duan_ya_chui_lian | techniqueInsight | cliff 60 + snow 60 + fortune 7 | unlock ice_break(后期高门槛) |
| 9 | shan_dao_wu_zhe | fortuneEvent | mountainPath 30 + mist 30 + fortune 3 | fortune +1 / none |
| 10 | xiao_zhen_wen_yi | fortuneEvent | inn 60 + fortune 4 | fortune +1 / enlightenment +1 |
| 11 | ye_xing_xun_dao | techniqueInsight | night 60 + fortune 5 | unlock night_strike |
| 12 | du_kou_chun_yu | fortuneEvent | dock 45 + rain 60 + fortune 4 | constitution / fortune |
| 13 | qun_xia_tu | techniqueInsight | gangMeng kill 5 + drillGround 30 + fortune 3 | unlock drill_strike |
| 14 | lu_pang_xian_xian | fortuneEvent | escortRoad 60 + fortune 4 | fortune / enlightenment |
| 15 | gu_dao_xue_ji | fortuneEvent | mountainPath 30 + snow 30 + fortune 5 | agility / constitution |

---

## 5. 测试增量

| 文件 | +case | 覆盖 |
|---|---|---|
| `test/services/encounter_service_test.dart` | +8 | recordIdleMinutes biome/weather 累加 / null 短路 / minutes=0 短路 / fixed-length 回归;multi-dim AND(biome 单 / weather 单 / 全达 / school+biome+fortune 三维) |
| `test/services/seclusion_service_test.dart` | +3 | idle tick 4h 喂 240min / encounterService=null 短路 / actualHours=0 短路 |
| `test/data/encounter_yaml_test.dart` | +6 | W14-2 4 条 biome/weather 维度解析(gu_jian_zhong_yin / cang_jing_ge_wu / ye_xing_xun_dao / qun_xia_tu) + 2 边界(未知 biome / weather 枚举抛 ArgumentError) |
| `test/data/seclusion_map_def_test.dart` | +2 | biome/weather 解析 + 未配 null |
| `test/data/isar_setup_test.dart` | 1 修 | saveVersion 0.5.0 → 0.6.0 |
| `test/data/encounter_yaml_test.dart` | 2 修 | 3 条 → 15 条 length;字典序断言改 [...].sort() 比较 |

**572 → 590(+18 net),analyze 0 issues**。

---

## 6. 关键挂账(W14-3 待处理)

- **奇遇专属 skill 池**(W14-1 已留):`EncounterProgress.unlockedSkillIds` 当前 append-only,战斗系统未消费。W14-3 新建 `data/encounter_skills.yaml`(30-50 招 unlock 池)+ 接战斗系统
- **W14-2 新 12 条 events 文案**:全走 placeholder,outcome 玩家选不到实际效果。DeepSeek 异步补 12 个 `data/events/<id>.yaml`
- **W14-1 既有 23 events outcome 未全 map**:沿用挂账
- **挂账 #34 / #30 / #28 / #31**:沿用 W13 closeout 未变
- **闭关 biome 喂法粗糙**:每张地图当前只有 1 个 biome + 1 个 weather 标签,挂机时整体喂。Phase 2+ 可考虑随机抽样 / 时辰切换天气等(GDD §7.3 节气 §12 #7 决策阻塞)
- **战斗不喂 biome/weather**:决策为"战斗时长太短无意义",若后期奇遇需要"在某地图战斗 N 次"型 trigger,需要扩 stage_entry_flow 同步喂 biome 1min(战斗约 30s-2min)

---

## 7. 工程教训

### 7.1 嵌套 writeTxn(Isar 限制)

SeclusionService.completeRetreat 已开 writeTxn,EncounterService.recordIdleMinutes 内部也开 writeTxn → 嵌套抛 IsarError。解决:写产出 txn 之后**单独再跑一次 txn**喂奇遇。

**取舍**:原子性损失(写产出后崩则 idle 累计丢);但闭关收功用户感知层面只关心 mojianshi/装备/经验,奇遇累计是隐藏维度,可接受。

### 7.2 Dart extension 同名方法冲突

`MapLikeOnBiomeMinutes.add(biome, minutes)` 与 `List.add(element)` 同名不同签名 — Dart extension 无法 override 原方法,会编译失败。解:重命名 `addMinutes`。

### 7.3 W13 教训沿用

- `BiomeMinutes`/`WeatherMinutes` @embedded:写前 `List.of` 转 growable(test 显式回归)
- 所有 catch 块加 debugPrint(`_feedEncounterIdleMinutes`)

### 7.4 ConsumerStatefulWidget vs StatefulWidget

`ActiveRetreatScreen` 是 StatefulWidget,没 ref。强行改 Consumer 改动大。**简单 fallback**:直接 new EncounterService 注入。生产路径行为一致。

### 7.5 设计 lock 前先问关键决策

biome/weather 枚举范围 + numbers.yaml 字段位置两个决策点用一次 AskUserQuestion 问完,15 + 5 + numbers.yaml 直接 append 全 lock,之后无人类介入推完。

---

## 8. 数据快照

- main HEAD:(本次 commit 待打)
- tag:`v0.4.0-w11` 仍是 W14-1 的(W14-2 不打新 tag,留 W14-3 闭环后打 `v0.5.0-w14`)
- 测试:**590/590** 全过,analyze 0 issues
- 累计 commit(项目至今):~97 commits
- Demo 内容量:主线 15/15 ✅ / 章节 3/3 ✅ / 爬塔 30/30 ✅ / 闭关 5/5 ✅ / 师徒 3/3 ✅ / 装备 35/30-50 ✅ / 心法 21/20-30 ✅ / **奇遇 15/20-30(W14-3 补到 20-30)** / **武学领悟 5/30-50**(unlock outcome 仅 5 条:ting_yu_jian + relic_blade + water_qi + ice_break + night_strike + drill_strike — 实际 6 条,但 ting_yu_jian + 5 新)
- 关键架构:在 W14-1 EncounterService 基础上 + **biome/weather 多维度 AND + 闭关 idle tick + tower 共享 hook**(W14-2)

---

## 9. 下次开局必读

1. `PROGRESS.md` 「当前阶段」段 + 「已完成」首条(W14-2)+ 「下一步」W14-3 候选
2. 本文档 §3 实现栈 + §4 配置映射(W14-3 扩 encounter 时要继续这套维度)+ §6 挂账
3. **W14-3-A 起手**(high):写 `data/encounter_skills.yaml`(奇遇专属 skill 池)→ GameRepository 加载 + 红线 → 战斗系统(skill_pool selector / 装备 slot 配置)消费 `EncounterProgress.unlockedSkillIds`。注意 GDD §5.3 三系锁死,**奇遇所得 skill 也受境界锁约束**
4. **W14-3-B(parallel)**:派 DeepSeek 补 12 个 W14-2 events 文案(`data/events/<id>.yaml`),id 列见 §4.2

CLAUDE.md / GDD.md / numbers.yaml 数值层不动(W14-2 已在 retreat.maps 加 biome/weather 字段,这是 schema 扩展不是数值改动)。Mac 端写 `lib/` `data/*.yaml`(顶层)`test/` `docs/handoff/`;DeepSeek 写 `data/narratives/` `data/lore/` `data/events/`;Codex 桌面 @ Pen 写 `docs/screenshots/` + `docs/handoff/codex_*.md`。
