# 候选 2 主线扩 Ch4 「西出阳关」 · Phase 2.1+2.1.5+2.2 实装 closeout

> 日期:2026-05-21 晚
> 模型:Mac + Opus 4.7 xhigh
> commit:`4f7fb6d`(主实装)+ `73fe060`(PROGRESS 升级)
> 上游 spec:[`p1_x_chapter4_spec_2026-05-21.md`](p1_x_chapter4_spec_2026-05-21.md)
> 上游 Phase 0:[`p1_x_chapter4_phase0_reality_check_2026-05-21.md`](p1_x_chapter4_phase0_reality_check_2026-05-21.md)

---

## TL;DR

Ch4 5 关 stages.yaml entry 落地 + 主线红线放开 4 章 20 关 + UI/strings 适配 + 5 test fixture 适配。**Phase 0/1 spec 漏检披露 ⭐**:`_enforceMainlineRedLines` 硬绑 15/3 章 + `ChapterListScreen _chapters [1,2,3]` 硬绑 + 5+ test 硬绑 → 全包修(原 2h estimate → 实际 ~1.5h xhigh)。1177 pass / 0 analyze。

---

## 一 · 改动总览(8 文件 395 inserts / 45 deletes)

### lib/ 4 文件

| 文件 | 改动 |
|---|---|
| `lib/core/domain/enums.dart` | EncounterBiome 加 `desert` + `frontier` 2 enum |
| `lib/data/game_repository.dart` | `_enforceMainlineRedLines` 放开硬码 15/3 章 → 动态 `5 * chapterCount` + chapterIndex 必须从 1 起连续 + 每章 5 关循环保留 |
| `lib/features/mainline/presentation/chapter_list_screen.dart` | `_chapters [1,2,3] → [1,2,3,4]` + 文档注释 4 章扩同步 |
| `lib/shared/strings.dart` | 加 `chapter4Title「西出阳关」` + `chapter4Hint「潼关西行,玉门古道、大漠迷踪、嘉峪关一决」` + `chapterTitle/Hint switch case` 加 ch=4 分支 + `mainMenuMainlineHint「4 章 20 关」` |

### data/ 1 文件

- `data/stages.yaml` +332 行 5 关 entry(stage_04_01..05):
  - **数值矩阵**:HP 7,200→15,500 / Atk 720→1,250 / Speed 165→215(全在 GDD §5.4 红线内,普伤 ≤8,000 / Boss HP ≤50,000)
  - **境界**:01-03 yiLiu·qiMeng/shuLian/jingTong / 04 yiLiu·yuanShu / 05 跨阶 **jueDing·qiMeng**(主 Boss)+ yiLiu·dengFeng(护法)
  - **biome**:`mountainForest / frontier / desert / drillGround / frontier`(2 新 enum 落地)
  - **weather**:`clear / clear / mist / clear / night`
  - **dropTable**:
    - `weapon_zhongqi_qing_xu_jian` 1.0(给 Ch5 jueDing 起步)
    - `armor_baowu_jin_si_jia` 0.4(传承 Ch3 雁门 lore 串联,跨章 lore 系统)
    - `accessory_zhongqi_qing_yu_huan` 0.5
  - **narrativeOpeningId/VictoryId/DefeatId** 字段已写,文件留 Batch 2.3 补(NarrativeLoader graceful 兜底「[剧情待补]」)

### test/ 3 文件

| 文件 | 改动 |
|---|---|
| `test/data/game_repository_test.dart` | `stageDefs.length 15→20` + 主线 20 关红线 case 加 ch=4 循环 |
| `test/features/mainline/presentation/chapter_list_screen_test.dart` | 3 章卡 widget test 全改 4 章卡(锁数/通关数/cleared list) |
| `test/balance/battle_strategy_e2e_test.dart` | 主线 15 关 e2e 加 Ch4 5 关 stageIds(45→50 战斗场景 e2e) |

### Isar codegen

- `lib/features/encounter/domain/encounter_progress.g.dart` 重生:enum index 15/16 = desert/frontier(.gitignore 不进 git,Pen 端 clone 后跑 build_runner)

---

## 二 · Phase 0/1 spec 漏检披露 ⭐

### 2.1 漏检 1:`_enforceMainlineRedLines` 硬绑 15/3 章

**spec §九 R 列未含此项**。实际触发:

```dart
// lib/data/game_repository.dart:1159-1184(改前)
if (mainlines.length != 15) throw StateError('主线关卡应为 15 关');
for (final ch in [1, 2, 3]) { ... }
if (byChapter.keys.any((ch) => ch < 1 || ch > 3)) throw StateError(...)
```

### 2.2 漏检 2:UI `ChapterListScreen._chapters` 硬绑 `[1,2,3]`

`lib/features/mainline/presentation/chapter_list_screen.dart:23` static const list。

### 2.3 漏检 3:5+ test fixture 硬绑 15 / 3 章

- `test/data/game_repository_test.dart:43` `expect(repo.stageDefs.length, 15)`
- `test/data/game_repository_test.dart:189-211` 主线红线 case 硬循环 `[1,2,3]`
- `test/features/mainline/presentation/chapter_list_screen_test.dart:49,63,82` 3 fail
- `test/balance/battle_strategy_e2e_test.dart:90-95` `stageIds[15]` 硬列

### 2.4 漏检根因 + 工作流改进

**Phase 0 reality check 走「stages.yaml/narratives/encounters/lore」4 维盘点,缺「红线层 grep」维度**。spec 起草前应跑:

```bash
# spec 起草前必跑:红线层 grep
grep -n "_enforce.*RedLines" lib/data/game_repository.dart
grep -rn "_chapters\s*=" lib/  # UI 硬码章节 list
grep -rn "stageDefs\.length, [0-9]" test/  # test 硬绑总数
```

**memory sink 候选**:`feedback_phase0_grep_two_axes` 加子格「红线/UI 硬码 list/test 总数 三维」+ 1.5h 拓 batch 实战锚点。

---

## 三 · 红线自查(GDD §5.4 + §7)

| 字段 | Ch4 最高值 | 红线 | 状态 |
|---|---|---|---|
| 单 enemy HP | 15,500(stage_04_05 西凉霸主) | Boss 50,000+ | ✅ 远低 |
| 单 enemy Atk | 1,250 | 普伤上限 8,000 | ✅ |
| 单 enemy Speed | 215 | 公式约束 | ✅ |
| **主线总关数** | **20**(4 章 × 5 关) | **GDD §7 15-20 关上限** | ⚠ **顶上限**,1.0 P2 Ch5/Ch6 进来需升档 §7 |
| 主线字数 | 8,233(未动)| GDD §8.4 7,000 | ⚠ 已超 +1,233(Demo 既成接受,Ch4 narratives 计 1.0 P2 +6-10k 字预算)|

**容量预警**(memory `feedback_living_doc_state_drift` 类型 C):
- 主线 20/20 关 = 100% §7 上限,Ch5/Ch6 进 1.0 P2 需 GDD §7 升档到 25-30 关
- Batch 2.4 GDD 同步必须挂账 §7 容量上限决议

---

## 四 · Phase 2 剩余路径

| Batch | 内容 | 估时 | 模型 | 触发 |
|---|---|---|---|---|
| 2.3 | chapter_04.yaml ~1,300 字 + 12 narratives ~4,840 字 | 3-5h | opus xhigh + **用户介入精修章首尾 + 末 Boss defeat** | 直接接续(narrative id 字段已锚 stages.yaml,文件生即活)|
| 2.4 | GDD §12.5 P2 启动备注 + §7 容量决议 + PROGRESS + ROADMAP_1_0 同步 | 30-60 min | opus | Batch 2.3 后 |
| 2.5 | R5 末 Boss 跨阶红线压测 case(yiLiu·dengFeng + 利器满 + menpai 满 vs jueDing·qiMeng boss 三人组,验胜率 60-80%)+ closeout doc | 1-2h | opus xhigh | 全 Ch4 内容到位后 |

**Batch 2.3 用户精修分工**(spec §三 拍板):
- 章首尾 prologue/epilogue(~1,300 字)— 文化承载强,用户精修 Tier 7 阶风格锚定
- 末 Boss defeat(stage_04_05_defeat ~320 字)— 情感强度顶峰,opus 单写易空洞
- 其余 10 段(opening/victory/stage_04_04_defeat)opus 单端走 Tier 风格梯度词体例

---

## 五 · memory sink 候选(Batch 2.5 收尾时审)

### 5.1 `feedback_phase0_grep_two_axes` 加子格(必)

加「红线层 / UI 硬码 list / test 总数」三维 grep + Ch4 Phase 2.1 +1.5h 拓 batch 实战锚点。

### 5.2 工作量估时校准

- Phase 0 spec 起草前缺红线层 grep → 实装期才浮现 → 工作量 +1.5h(75% over)
- 锚点:opus xhigh 机械改动(red line + UI + 5 test fixture)~1.5h(memory `feedback_opus_xhigh_interactive_duration` 验证再 1 锚点)

### 5.3 NarrativeLoader graceful 兜底设计模式(可选)

stages.yaml 写 narrativeOpeningId 但文件未生 → loader 兜底「[剧情待补]」,test 期望 `narrativeDefeatId notnull` 仍通过。这种「字段提前锚定 + 文件后补」模式可复用未来 Ch5/Ch6 spec 起草。

---

## 六 · 工作量复盘

| 阶段 | 估时(spec)| 实际 | 偏差原因 |
|---|---|---|---|
| Batch 2.1 enum 扩 | 30-45 min | ~15 min | 0 switch case 漏检(byName 解析) |
| Batch 2.1.5 红线放开 | **未估**(漏检) | ~30 min | spec Phase 0 漏检红线层 |
| Batch 2.2 stages.yaml + test 红线压测 case | 1-1.5h | ~45 min(含 5 test fixture 修)+ R5 留 Batch 2.5 | test fixture 修比想象快(grep + Edit 直接) |
| **合计** | **~2h** | **~1.5h** | spec 漏检 +1.5h 反而提速 ~25%(机械改动 opus 节奏好) |

---

## 七 · 不变量沿用

- GDD §5.4 数值红线 / §5.3 三系锁死 / §5.6 不硬编码 / §6 核心公式 / §6.6 装备典故
- CLAUDE.md v1.9 Mac+Opus 单端全权
- spec §八 6 风险挂账(R0 红线层 grep 漏检 = 本批新发现)
- memory `feedback_wuxia_boss_balance_crosstier`(末 Boss 跨阶 jueDing,数值已落 stages.yaml)
- memory `feedback_avoid_over_engineer_abstraction`(EncounterWeather 不扩 sandstorm,sandstorm 走 mist + biome desert 组合)

---

## 八 · 上下游 reference

- **上游**:`p1_x_chapter4_spec_2026-05-21.md`(Phase 1 spec)+ `p1_x_chapter4_phase0_reality_check_2026-05-21.md`(Phase 0)
- **commit**:`4f7fb6d`(主实装)+ `73fe060`(PROGRESS 升级)
- **下游 next**:
  - 优先 Batch 2.3 narratives 起草(12 文件 + chapter_04.yaml)
  - 同步 Batch 2.4 GDD §7 容量决议(主线 20/20 关 = 100% 上限,1.0 P2 Ch5/Ch6 升档)
- **同级**:`docs/ROADMAP_1_0.md` P2 路径明确

---

## 九 · 收尾状态(2026-05-21 晚)

- HEAD `73fe060`(本批 +2 commit 全 push origin/main)
- worktree clean,与 origin/main 0/0 同步
- 1177 pass / 0 analyze
- 1.0 路线图:Demo ~95% / P0 100% / P1.1 ~100% / P1.2 ~25% / P1.3 美术线 ~80% / **P2 第二条主线 ~25%**(Ch4 数值落,narratives 待)
- **Phase 2 Batch 1 闭环 ✅**,Batch 2.3 narratives 待启动
