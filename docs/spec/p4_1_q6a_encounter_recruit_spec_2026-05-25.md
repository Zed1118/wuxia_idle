# P4.1 Q6 A encounter recruit spec(默认决议草案 · 1.1 挂账起点)

> **2026-05-26 self-review 应用**:R2 markTriggered 延后(§3)+ R3 Sect lazy-init fallback(§3)+ R8 R5.8 标 delta 依赖 P-C ship(§7)+ Q9/Q10 补(§0)· 详 `docs/handoff/q6a_spec_self_review_2026-05-26.md`
>
> 日期:2026-05-25 起草 · 2026-05-26 self-review 应用 / 模型:Mac + Opus 4.7 xhigh / 估时 ~5-7h xhigh(B1 1.5-2h + B2 2-2.5h + B3 1.5-2.5h)
> 上游:P4.1 spec `docs/spec/p4_1_sect_management_spec_2026-05-25.md` §1 范围 OUT「Q6 A encounter recruit 留 1.1」
> 沿例:P4.1 spec §3 trigger hook 体例 + P1.2 `affectsReputation` schema 体例(`encounter_def.dart:221`)
> ⚠ **本 spec 基于 Q1-Q8 默认决议草案** · 用户拍板后改本文件 §0 + §2-7 局部即可,不需重写。

---

## 0. Q1-Q8 决议(默认占位 · 用户拍板后填)

| Q | 主轴 | 默认决议 | 理由 |
|---|---|---|---|
| Q1 | candidate 生成方式 | **A 预定义 yaml**(`data/sect_candidates.yaml` · 5-8 NPC) | 沿 P1.1 `recruit_candidates.yaml` 体例 · fixture-friendly · §5.3 三系锁可红线静态校 |
| Q2 | encounter type | **A 复用 fortuneEvent + affectsSectMembership flag** | 沿 `affectsReputation` 体例(`encounter_def.dart:173`)· 不开新 EncounterType enum |
| Q3 | cap 已满处理 | **A fallback outcome**(招收 outcome 静默 skip + 改走 fallback) | 玩家感知不破 + sect 不破 cap · 红线一致 |
| Q4 | 玩家确认路径 | **C confirm dialog 二次确认** | 沿 P1.1 RecruitmentDialog confirm 体例 · 决策权回玩家 |
| Q5 | sectRank 起阶 | **A 默认 initiate** | 沿 `SectMemberService.recruit:35` 现签名 · NPC 真贡献后再 promoteRank |
| Q6 | batch 拆分 | **A 3 batch**(schema+yaml + service+wire + R5+UI) | 粒度沿 P3.4 sect_event 体例 · ~5-7h xhigh |
| Q7 | Demo encounter 数量 | **A 3 条**(fortuneEvent × 3 跨 biome / school / 通用) | 不堆量 · 验证链路通即可 · 文案 ~6-9 条 |
| Q8 | events 文案产线 | **A Mac+Opus 单端**(沿 v1.8 协作模式) | DeepSeek 退役 · opening + 1-2 outcome + skip ~3 段/encounter |
| Q9 | candidate pool 随机性(self-review R1 补) | **A Demo 单一 `candidateRef`**(1.2 升 `candidateRefs: List<String>` rng pick) | PoC 验链路够 · 不开新参数 · 1.2 升 List 时再加 rng |
| Q10 | markTriggered 时机(self-review R2 补) | **A accept 成功 + recruit success 后 markTriggered**(拒绝 / cap 满 / lazy-init 失败 不 markTriggered · 玩家可重遇) | 沿 W14 体例延后到 effect 真应用之后 · §3 wire 已应用 |

## 1. 范围

- **核心 deliverable**:① `AffectsSectMembership` 类(`encounter_def.dart` 加 · 沿 `AffectsReputation` 体例)② `EncounterDef.affectsSectMembership: AffectsSectMembership?` 字段 ③ `data/sect_candidates.yaml`(5-8 NPC · 5-7 阶覆盖 · 含 starting 装备/心法 ref · 沿 `recruit_candidates.yaml` schema · 字段加 `targetSectId: int?` 可空) ④ `SectCandidateDef` def 类(`lib/data/defs/sect_candidate_def.dart`) ⑤ `GameRepository.sectCandidates: Map<String, SectCandidateDef>` + load + 红线 ⑥ `encounter_hook.dart` 加 sect recruit 分支(applyOutcome 之后判 `def.affectsSectMembership != null` → 创 NPC Character + SectMemberService.recruit + UI confirm) ⑦ `data/encounters.yaml` 新增 3 条 fortuneEvent · `affectsSectMembership` 字段 ⑧ `data/events/<id>.yaml` 新增 3 条文案 ⑨ `UiStrings` ~6-8 段(招收 confirm / cap 满 fallback / 拒绝反馈)⑩ R5 红线 6-8 族
- **配套**:① Demo 玩家=祖师场景 `playerSectId` 取 `Sect.founderId==playerCharacterId` 反向索引(沿 sect_screen 入口判断体例)② cap 满路径返 `AffectsSectMembership.fallbackOutcomeId` 走原 outcomeMapping(NPC 不入 Isar · attribute/skill 仍生效) ③ 拒绝路径同 cap 满 fallback(玩家拒招收不损 attribute)
- **范围 OUT**:① stage_boss 招降(Q6 B P4.1 spec OUT · 仍挂 1.1+) ② 主动招收 NPC list UI(Q6 C P4.1 spec OUT) ③ founder_buff_service 跨派系扩(P4.1 spec OUT · `!c.isInSect` early return 留 1.2 跨派系)④ NPC 多 sect 归属(Demo 单玩家 sect 假设) ⑤ encounter triggered NPC 后续 dismiss / promoteRank UI 流(走 sect_screen 已 ship · 不重写) ⑥ events 文案 ~20-30 条扩量(P4.1 1.1 挂账「member 招收 narrative」延续 · 本 spec 仅 3 条 PoC)

## 2. schema 改动

```dart
// lib/features/encounter/domain/encounter_def.dart(加 · 沿 AffectsReputation 体例)
/// Q6 A · encounter resolve 后触发 sect 招收 hook。
/// candidateRef 引 data/sect_candidates.yaml id;cap 满或玩家拒绝 → fallbackOutcomeId。
class AffectsSectMembership {
  final String candidateRef;       // sect_candidates.yaml id
  final String? fallbackOutcomeId; // cap 满 / 拒绝时 fallback(null = NoneOutcome)
  const AffectsSectMembership({required this.candidateRef, this.fallbackOutcomeId});
  factory AffectsSectMembership.fromYaml(Map<String, dynamic> y) =>
      AffectsSectMembership(
        candidateRef: y['candidateRef'] as String,
        fallbackOutcomeId: y['fallbackOutcomeId'] as String?,
      );
}

// EncounterDef 加字段(沿 affectsReputation:170 体例)
final AffectsSectMembership? affectsSectMembership;
```

```yaml
# data/sect_candidates.yaml(新文件 · Q1=A · 5-8 NPC · 沿 recruit_candidates.yaml 体例)
- id: bamboo_swordsman
  name: 竹影客
  defaultRealm: erLiu       # §5.3 七阶映射
  defaultLayer: ruMen
  school: lingQiao
  attributeProfile: {constitution: 5, enlightenment: 7, agility: 8, fortune: 6}
  startingEquipmentIds: [eq_jade_sword, eq_robe_qing, eq_bracer_jade]
  startingTechniqueIds: [tech_listen_rain_sword, tech_qing_yun_step]
  portraitPath: assets/characters/sect_candidate_bamboo.png
  lore: "竹林听雨,剑随心走"
# ... 共 5-8 NPC
```

```yaml
# data/encounters.yaml(尾部加 3 条 · Q7=A fortuneEvent × 3 · 沿 W14-2 体例)
- id: bamboo_recruit_meet
  type: fortuneEvent
  trigger: {biomeMinutes: {bambooForest: 120}, fortuneRequired: 6}
  baseProbability: 0.15      # numbers.yaml sect_management.recruit.encounter_base_prob
  outcomeMapping:
    accept_recruit: {type: none}        # 真效果走 affectsSectMembership
    decline_meet:   {type: attributeBonus, attributeKey: enlightenment, attributeDelta: 1}
  affectsSectMembership:
    candidateRef: bamboo_swordsman
    fallbackOutcomeId: decline_meet     # cap 满 / 拒绝走此 outcome
```

## 3. encounter_hook.dart wire(`lib/features/encounter/presentation/encounter_hook.dart` 加 sect 分支)

- **wire 点**(`encounter_hook.dart:95` `applyOutcome` 调用返回后 · 在 `showEncounterOutcomeBanner` 之前):
  ```
  if (triggered.affectsSectMembership != null && outcomeId == accept_id) {
    final candidateDef = repo.sectCandidates[def.candidateRef]
    // R3 修(self-review):Sect lazy-init fallback · 沿 sect_providers.dart:64-68 体例
    var sect = await isar.sects.get(1);
    if (sect == null) {
      await isar.writeTxn(() => isar.sects.put(_defaultSect(now)));
      sect = await isar.sects.get(1);
    }
    final playerSectId = sect?.id; // Demo 单 sect 假设
    if (playerSectId == null) → fallback outcome / SnackBar 「未建派」(理论不命中 · lazy-init 已守)
    else: showConfirmDialog(...)
      → 确认 → isar.writeTxn {
           Character.create(candidateDef · isFounder=false · isActive=false)
           SectMemberService.recruit(targetCharacterId: newChar.id, sectId, numbers)
           → cap 满 → 改走 fallback applyOutcome / SnackBar
           → 成功 → SaveData.recruitedDiscipleIds 追加(沿 P1.1 体例 · 同 inactive 池数据基础)
                 + **markTriggered(R2 修:延后到此处 · accept 成功 + sect.put 之后)**
         }
      → 取消 → 改走 fallback applyOutcome(等同 decline)· **不 markTriggered**(R2 修:玩家可重遇)
  }
  // R2 修关键:markTriggered 仅在 accept + recruit success 后调 · cap 满 / 拒绝 / lazy-init 失败 不 markTriggered
  ```
- **accept outcome id 约定**:`affectsSectMembership.candidateRef` 触发的 outcome id 必为 `accept_recruit` (encounters.yaml 强约定 + 加载层红线校)· 不走魔法字符串
- **caller 持锁纪律**:newChar.put + SectMemberService.recruit 同 writeTxn(沿 `SectMemberService` doc §caller 持锁)· Sect lazy-init writeTxn 独立(沿 currentSectProvider 体例)
- **encounter_service.applyOutcome 不改**(纯 service 不依赖 sect/character 创建 · 沿 `affectsReputation` 解耦体例)· sect wire 在 hook 层 · markTriggered hook 端 caller 持锁延后

## 4. UI 接入(`lib/features/encounter/presentation/encounter_hook.dart` + 新 widget)

- **confirm dialog**:`showSectRecruitConfirmDialog(context, candidateDef)` → 显 NPC portrait / 4 属性 / school chip / starting 装备-心法 / lore · 「招入门派」 / 「婉拒」 二按钮 · 沿 P1.1 `RecruitmentDialog` confirm 体例
- **UiStrings**(`lib/shared/strings.dart` 加):
  - `sectRecruitConfirmTitle` = '是否招入门派?'
  - `sectRecruitAcceptLabel` = '招入门派'
  - `sectRecruitDeclineLabel` = '婉拒'
  - `sectRecruitSuccess(String name)` = '$name 已入门派,任 [初入] 阶'
  - `sectRecruitCapFull` = '门派人数已满,$name 婉言告别'
  - `sectRecruitNoSect` = '尚未建派,无缘相邀'
- **encounter dialog 不改**(沿 W14 outcome 选择 UI · accept_recruit outcome 在 outcomeMapping 中已显示)· confirm dialog 在 outcome 选 accept_recruit 后弹

## 5. 联动(jianghu reputation / festival / founder_buff)

- **reputation**:Q6 A encounter 可同时配 `affectsReputation` + `affectsSectMembership`(独立字段)· 两个 hook 都跑(reputation 在 applyOutcome 内 / sect 在 hook 层)· 不互相阻塞
- **festival**:fortuneEvent 可加 `festivalRequired` 限节日 · 沿 W16 体例 · 无新接入
- **founder_buff_service 0 改**:沿 P4.1 spec 决议(`!c.isInSect` early return 留 1.2)· 新招的 NPC isInSect=true 但 founder_buff 当前不感知,作用域真扩留 1.2 跨派系

## 6. 数据流(yaml schema + 加载层 + 红线)

- **`data/sect_candidates.yaml`**(新 · 5-8 NPC)启动 `GameRepository.load` 解析 → `Map<String, SectCandidateDef>`(沿 `recruitCandidates` 体例)· 红线 `_enforceSectCandidateRedLines`:
  - 每条 NPC defaultRealm × defaultLayer 在 ranks.yaml 内(§5.3 七阶)
  - startingEquipmentIds / startingTechniqueIds tier ≤ defaultRealm · 沿 P1.1 `_enforceRecruitCandidateRedLines` 体例
  - school 与 mainTechnique school 一致
  - fixture-friendly:starting refs 不全 → 静默清空 `sectCandidates`(沿 P1.1 体例避免 12+ fixture loader 改)
- **`data/encounters.yaml` 加载层**:`affectsSectMembership.candidateRef` 必须在 `sectCandidates` 中(红线 · `GameRepository._enforceEncounterRedLines` 扩)
- **`data/events/<id>.yaml`**(3 条新文案 · sect_recruit_<biome>.yaml)`choices[].outcome_id` 含 `accept_recruit` + `decline_meet` · 沿 events 加载强校验体例
- **Isar schema 不动**(`SaveData.recruitedDiscipleIds` 已存在 · 沿 P1.1 数据基础 · 同 inactive 池)

## 7. R5 红线测族(~6-8 测 · `test/features/encounter/sect_recruit_test.dart` 新)

- **R5.1 招收 e2e**:encounter triggered + outcomeId=accept_recruit → Character 创 + SectMemberService.recruit success + sect.memberCount++ + SaveData.recruitedDiscipleIds 追加(1 测)
- **R5.2 cap 满 fallback**:sect.memberCount==cap 时招收 → fallback outcome 走 attributeBonus +1 enlightenment + Character 不创 + memberCount 不变(1 测)
- **R5.3 拒绝路径**:outcomeId=decline_meet → 直接 fallback · Character 不创(1 测)
- **R5.4 schema 红线**:`AffectsSectMembership.candidateRef` 不在 `sectCandidates` → load 抛 StateError(1 测 · 沿 `_enforceEncounterRedLines` 体例)
- **R5.5 §5.3 三系锁守**:NPC startingEquip tier > defaultRealm → 红线抛(1 测 schema-level · 沿 P1.1 R5.6 体例 · 禁 grep 校验)
- **R5.6 sectRank 默认 initiate**:R5.1 后 newChar.sectRank == SectRank.initiate(1 测)
- **R5.7 同 NPC 不重复招**:encounter triggered 在 progress.triggeredEncounterIds 后 evaluateTriggers 不再返回(1 测 · 沿 W14 体例)
- **R5.8 NPC isFounder=false**(**delta · self-review R8 修**):R5.1 后 newChar.isFounder == false 单测 OK(沿 P4.1 B4 R5.6 体例)· **但「founder_buff_service 不误激活给 NPC」语义需依赖 [[p4_1_founder_buff_cross_sect_spec_2026-05-26]] P-C spec ship 后 per-character `isBuffActiveFor` API 才能真测**;本 spec 实装时 R5.8 仅测 `isFounder==false` 字段 · per-character buff 验证测族延后到 P-C ship 后另加(1 测 isFounder + 后续 delta)
- **baseline ~1484 + delta ~6-8**(B3 实测 · 沿 P4.1 体例 · R5.8 后续 delta 等 P-C ship)

## 8. Batch 拆分(估时 ~5-7h xhigh)

| Batch | 内容 | 估时 |
|---|---|---|
| B1 schema + yaml | `AffectsSectMembership` 类 + `EncounterDef.affectsSectMembership` 字段 + `SectCandidateDef` def + `data/sect_candidates.yaml` 5-8 NPC + 3 条 encounters.yaml + 3 条 events.yaml + GameRepository.sectCandidates load + 双层红线 | ~1.5-2h |
| B2 service+wire+UI | `encounter_hook.dart` sect 分支(applyOutcome 之后判 affectsSectMembership · isar.writeTxn 包 newChar + SectMemberService.recruit · cap 满走 fallback)+ `showSectRecruitConfirmDialog` + UiStrings 6 段 + `playerSectId` 反向索引 helper | ~2-2.5h |
| B3 R5 + closeout | R5.1-5.8 测族 + closeout doc ≤80 行 + PROGRESS 1.1 起点段 + GDD §12.2 #6 v1.10 升档(P4.1 1.1 挂账 Q6 A → P4.1.E 实装 ✅)+ memory sink(若有)| ~1.5-2.5h |

## 9. 估时 + 风险 + 挂账

- **估时**:B1 1.5-2h + B2 2-2.5h + B3 1.5-2.5h = **~5-7h xhigh**(对齐 P4.1 1.1 挂账起点 · 单 task 颗粒度合适)
- **风险**:① B2 hook 层 isar.writeTxn 嵌套(newChar.put + SectMemberService.recruit · caller 持锁体例需严格)② B1 sect_candidates.yaml fixture-friendly 跨 12+ fixture loader 验证(沿 P1.1 体例)③ confirm dialog UI 在 encounter_hook async flow 内 mounted 校验(沿 W14 体例 · 不破 victory narrative)④ events.yaml 文案 3 条占位若不写真文案 PoC 不可信(沿 v1.8 Mac 单端接管 · ≤10min/条 opus)
- **不变量沿用**:§5.4 红线不动 · §5.3 三系锁死(NPC starting tier ≤ realm) · §5.5 在线=离线 · §5.1 反留存 · `encounter_service.dart` 0 改(sect wire 在 hook 层) · `SectMemberService` 0 改 · `RecruitmentService` 0 改(P1.1 inactive 池语义独立) · founder_buff_service 0 改 · §6 公式不动 · Isar schema 0.13.0 不动
- **doc 体量**:本 spec ≤150 行(memory `feedback_doc_inflation_overnight`) · B3 closeout ≤80 行 · PROGRESS 净增长 ≤ 0

---

**Q6 A encounter recruit spec 收口(默认决议草案)**:Q1=A / Q2=A / Q3=A / Q4=C / Q5=A / Q6=A / Q7=A / Q8=A · B1-B3 拆 · ~5-7h xhigh · ⚠ 用户改 Q1-Q8 后改 §0 + §2-7 局部 · 起 worktree `feat/p4_1_q6a_encounter_recruit` 走 B1
