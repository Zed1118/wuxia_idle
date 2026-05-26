# P4.1 Q6 B stage_boss recruit spec(默认决议 · 1.1 挂账第三项收齐)

> 日期:2026-05-26 / Mac + Opus 4.7 high(spec) → xhigh(实装)
> spec sonnet baseline 4-6h · **xhigh 实测 ~1.5-2.5h**(同会话续 0.25-0.30× · 沿 founder_buff 0.13-0.20× 锚)
> 上游:Q6A spec ship + Q6A closeout · 沿例:`AffectsSectMembership` schema + `_handleSectRecruit` helper 抽共用 + `sect_recruit_confirm_dialog` widget 复用
> ⚠ Q1-Q8 默认采纳 → 直接起 B1

---

## 0. Q1-Q8 决议(默认采纳)

| Q | 决议 |
|---|---|
| Q1 数据源 | **A 复用 sect_candidates.yaml** + stages 加 `bossRecruit: {candidateRef, baseProbability}`(0 新 yaml · Q6A 5 NPC 池 PoC 3 余 2 够) |
| Q2 触发 | **B rng pick 40%**(`numbers.yaml stage_boss_recruit_prob: 0.40` · 对照 Q6A encounter 0.15 · Boss 招降隆重 ↑↑) |
| Q3 数量 | **C PoC 3 章末大 Boss**(stage_01_05/02_05/03_05 → bamboo/desert/mountain · 跨三系)· 04_05+ 留 1.1+ |
| Q4 语义 | **A 仅入派**(isInSect/sectId/sectRank=initiate)· Q6A 一致 · 1.2 character_panel 集成时再扩 |
| Q5 UI | **A 独立 dialog 复用 Q6A `showSectRecruitConfirmDialog`** + SnackBar · 0 改 stage_victory_dialog |
| Q6 入派 rank | **A 全 initiate** · `promoteRank` 走 sect_screen 已 ship |
| Q7 失败处理 | **A NPC 离去**(SnackBar 「{name} 婉言告别」)· rng 不命中 / 玩家拒 / cap 满 全静默 |
| Q8 markTriggered | **A 每 Boss 1 次性**(`SaveData.triggeredBossRecruitStageIds`)· 防玩家刷 |

## 1. 范围

**核心 deliverable**:① `BossRecruitConfig` class + `StageDef.bossRecruit` 字段(沿 `AffectsSectMembership` 体例)② `data/stages.yaml` 3 Boss 加 bossRecruit 段 ③ `numbers.yaml stage_boss_recruit_prob: 0.40` ④ `SaveData.triggeredBossRecruitStageIds` + saveVersion bump 0.13.0 → 0.14.0 ⑤ **抽 `_handleSectRecruit`** from `encounter_hook.dart:174` → `lib/features/sect/presentation/sect_recruit_handler.dart`(`runSectRecruitFlow` 共用 API · Q6A wrapper 调用)⑥ 新 `stage_boss_recruit_hook.dart` ⑦ `stage_entry_flow.dart:182` wire 一行(`runEncounterHookAfterVictory` 之后)⑧ `_enforceBossRecruitRedLines` 三重校 ⑨ UiStrings 3 段 ⑩ R5 测族 8 测

**范围 OUT**:Boss 招降 narrative(留 1.2 文案扩)· character_panel sect NPC 集成(1.2)· stage_event_picker debug 分支 · founder_buff Boss NPC 验证(已自然享 sectId)· stage_04_05+ 池扩(1.1+)· 失败 narrative 推

## 2. schema 改动

```dart
// stage_def.dart 加 · 沿 AffectsSectMembership 体例
class BossRecruitConfig {
  final String candidateRef;
  final double baseProbability;  // 省略走 numbers.yaml 0.40
  const BossRecruitConfig({required this.candidateRef, this.baseProbability = 0.40});
  factory BossRecruitConfig.fromYaml(Map<String, dynamic> y) => BossRecruitConfig(
    candidateRef: y['candidateRef'] as String,
    baseProbability: (y['baseProbability'] as num?)?.toDouble() ?? 0.40);
}
// StageDef 加 `final BossRecruitConfig? bossRecruit;`(沿 npcId:75 体例)

// save_data.dart 加(沿 recruitedDiscipleIds:66 体例)
List<String> triggeredBossRecruitStageIds = [];
```

```yaml
# data/stages.yaml 3 章末 Boss(stage_01_05 / 02_05 / 03_05)
bossRecruit:
  candidateRef: bamboo_swordsman   # Q6A sect_candidates.yaml 已配

# data/numbers.yaml sect_management.recruit 加
stage_boss_recruit_prob: 0.40
```

## 3. wire 改动

### 3.1 抽 `_handleSectRecruit` → 共用模块(B2 第 1 步)

新 `lib/features/sect/presentation/sect_recruit_handler.dart`:

```dart
enum SectRecruitOutcome { success, capFull, declined, noSect, unexpectedFail }
// Q6A/Q6B 共用 · Sect lazy-init + confirm dialog + writeTxn + result 处理。
// caller 传 onMarkTriggered/onFallback callback 让语义解耦(Q6A 调 encounter.markTriggered
// + applyOutcome fallback;Q6B 调 SaveData writeTxn + onFallback=null 静默)。
Future<SectRecruitOutcome> runSectRecruitFlow({ctx, ref, isar, candidate,
  required Future<void> Function() onMarkTriggered,
  required Future<void> Function()? onFallback,
  required String successSnackBar, capFullSnackBar, noSectSnackBar}) async {...}
```

Q6A `encounter_hook._handleSectRecruit:174` 改 ~10 行 wrapper 调 `runSectRecruitFlow`:`onMarkTriggered` = `svc.markTriggered(saveDataId, encounterId)` · `onFallback` = `svc.applyOutcome(fallbackOutcomeId)` + `showEncounterOutcomeBanner` · 3 SnackBar 用 `UiStrings.sectEncounterRecruit*`。

### 3.2 新 hook `stage_boss_recruit_hook.dart`(B2 第 2 步)

算法:① `if (!stage.isBossStage || stage.bossRecruit == null) return;` 守 ② `IsarSetup.instanceOrNull` 守 ③ `save.triggeredBossRecruitStageIds.contains(stage.id)` 防刷 ④ `ref.read(rngProvider).nextDouble() >= prob` rng pick ⑤ `repo.sectCandidates[ref]` 解 candidate(null debugPrint return)⑥ `mounted` 守 + `runSectRecruitFlow(...)` · `onMarkTriggered = writeTxn { triggeredBossRecruitStageIds 追加 }` · `onFallback = null` 静默

`stage_entry_flow.dart:182` 加一行:`await runStageBossRecruitHookAfterVictory(context, ref, stage);`(在 `runEncounterHookAfterVictory:176` 之后)。

## 4. UI(复用 + 新 SnackBar)

- **复用** `showSectRecruitConfirmDialog`(Q6A widget · 0 改)
- **UiStrings 加 3 段**:`stageBossRecruitSuccess(name)` = '$name 折服于你的剑下,入门派任 [初入] 阶' · `stageBossRecruitCapFull(name)` = '门派人数已满,$name 婉言告别' · `stageBossRecruitNoSect(name)` = '尚未建派,$name 不知归处'

## 5. 联动

- **encounter hook 独立**:`runEncounterHookAfterVictory:176` → `runStageBossRecruitHookAfterVictory:182` 顺序 · 互不阻塞(各自 mounted check)· 玩家可经 encounter 后再 Boss recruit
- **festival 0 改** · **founder_buff 0 改**(Boss NPC sectId=playerSectId 自然享 · 沿 founder_buff cross_sect ship)

## 6. 数据流(yaml + 加载层 + 红线)

- `data/stages.yaml` 3 Boss 加 `bossRecruit` · `StageDef.fromYaml` 解析 · 新 `_enforceBossRecruitRedLines` 三重校:① 仅 isBossStage=true 可配 ② candidateRef 必在 sectCandidates ③ baseProbability ∈ [0.0, 1.0]
- `data/sect_candidates.yaml` 0 改(Q6A 5 NPC 复用)
- **Isar bump**:`SaveData.triggeredBossRecruitStageIds` 新字段 → saveVersion 0.13.0 → 0.14.0 · `isar_setup_test` 期待值改 · `build_runner` regen 必跑

## 7. R5 红线测族(8 测 · `test/features/sect/stage_boss_recruit_test.dart` 新)

| # | 内容 |
|---|---|
| R5.1 | 招收 e2e(rng injected 命中 + 玩家确认 → Character 创 + recruit success + memberCount++ + triggeredBossRecruitStageIds 追加) |
| R5.2 | rng 不命中(prob 0.40 + rng 0.99) → 不弹 dialog + 不 markTriggered |
| R5.3 | markTriggered 1 次性(triggeredBossRecruitStageIds 已含 stage.id) → 直接 return |
| R5.4 | 玩家拒绝 → Character 不创 + 不 markTriggered(可重战重遇) |
| R5.5 | cap 满 → SnackBar cap full + Character 不创 + 不 markTriggered |
| R5.6 | schema 红线:非 isBossStage 配 bossRecruit → StateError |
| R5.7 | schema 红线:candidateRef 不在 sectCandidates → StateError |
| R5.8 | isBossStage 但 bossRecruit=null → 不 trigger · victory 流照常(1.0 ship Boss 全 null 兼容) |

baseline ~1497 + delta ~8 = **~1505**(B3 实测)

## 8. Batch 拆分(估时 ~1.5-2.5h xhigh 实测)

| Batch | 内容 | 估时 |
|---|---|---|
| **B1 schema+yaml** | `BossRecruitConfig` + `StageDef.bossRecruit` + `SaveData.triggeredBossRecruitStageIds` + saveVersion 0.14.0 + build_runner + stages.yaml 3 Boss + numbers.yaml + `_enforceBossRecruitRedLines` | ~30-45min |
| **B2 抽 helper+wire** | 抽 `_handleSectRecruit` → `sect_recruit_handler.dart` + encounter_hook 改 wrapper + 新 `stage_boss_recruit_hook.dart` + `stage_entry_flow.dart:182` wire + UiStrings 3 段 | ~30-45min |
| **B3 R5+closeout** | R5.1-5.8 测族 + closeout ≤80 行 + PROGRESS 顶段(净增长 ≤0)+ GDD §12.2 #6 v1.14 升档(P4.1 1.1 三项收齐)| ~30-45min |

## 9. 估时 + 风险

- **估时**:B1+B2+B3 = **~1.5-2.5h xhigh 实测**(同会话续 0.15× 锚)
- **风险**:① 抽 helper 时 Q6A 语义保持 — `onFallback: nullable Function` 支持 Q6B 静默 ② Isar saveVersion bump 影响 fresh checkout + SaveData migration(沿 W6/P3.2 体例 · build_runner regen + isar_setup_test 期待值改)③ stage_04_05+ 池余 NPC 不够(2 余 vs 4 章需)留 1.1+ ④ R5 e2e 需 mock rng(沿 W14 `rngProvider.overrideWithValue(AlwaysHitRng())` 体例)
- **不变量沿用**:1 行 link CLAUDE.md v1.13 · 详 [`CLAUDE.md`](../../CLAUDE.md)(§5.1/§5.3/§5.4/§5.5 + Riverpod/Isar + encounter_service/SectMemberService/RecruitmentService/founder_buff_service/stage_victory_dialog 0 改 + 1497 测保持过)
- **doc 体量**:本 spec ≤150 行 · B3 closeout ≤80 行 · PROGRESS 净增长 ≤ 0

---

**Q6 B 收口**:Q1=A / Q2=B 40% / Q3=C PoC 3 / Q4-Q8=A · B1-B3 拆 · ~1.5-2.5h xhigh · 起 worktree `feat/p4_1_q6b_stage_boss_recruit` 走 B1
