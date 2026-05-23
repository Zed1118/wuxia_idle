# P5+ 多代飞升 + 真传位完整链路 spec(④+⑤ 合并)

> 日期:2026-05-24 / 模型:Opus 4.7 xhigh / 估时 ~5-7h
> 主 cwd `/Users/a10506/Desktop/挂机武侠` @ main · 直推 main(无 PR)
> 接续 spec:`docs/spec/p2_3_ascension_spec_2026-05-24.md`(P2.3 已实装一代飞升底层)
> 路线图段:ROADMAP P2.3 §挂账 / handoff p2_3_ascension_closeout_2026-05-24.md §挂账下波

---

## TL;DR

合并 ④ P5+ 多代飞升(`stack_across_generations` enforce + `conflict_slot_resolution=auto_swap`)+ ⑤ P5+ 真传位(promotedDiscipleId 接管 founder 身份 · founder_buff trigger 转移)一批做。**0 schema 改 · 0 公式改 · founder_buff_service 0 代码改**(P2.3 留好的 isFounder+isActive 两轴语义自然承载传位)。3 batch ship:Batch 1.1 schema+Service / Batch 1.2 UI / Batch 1.3 R5+closeout。

## Phase 0 reality check 结论(已跑)

| 维度 | 现状 | 改动 |
|---|---|---|
| schema | Character.{lineageRole/isFounder/isActive} + Equipment.{isLineageHeritage/previousOwnerCharacterIds:List<int>} 齐 | 0 改 |
| Equipment.inheritFrom | reassign list `[...old, new]`(P2.3 修)+ 天然多代追加 | 0 改 |
| AscendService.performAscend | 单代 transfer 完整 + 选件 player_pick 真消费 | 加 promotedDiscipleId 参数 + auto_swap 副作用 |
| FounderBuffService.computeBuffActive | 已是「active 中 isFounder=true → 激活」语义 | **0 代码改**(promotedDisciple.isFounder=true 自然接管) |
| derived_stats §244 | lineage bonus 按 instance count(不读 prev len) | 0 改(stack_across=false 天然满足 · 加 1 test 防回退) |
| NumbersConfig.HeritageItems | stackAcrossGenerations + conflictSlotResolution 字段已落 | 真消费(原 P2.3 YAGNI) |

## 拍板 Q&A

| Q | 方案 | 理由 |
|---|---|---|
| Q1 promotedDiscipleId 由谁选 | **玩家手动下拉**(player_pick) | 沿 P2.3 multi_disciple_allocation 体例 · 留 P5+ 门派争斗 narrative 空间 |
| Q2 lineageRole 是否真切 | **不真切 · 只切 isFounder** | 沿 P2.3 Q2c 体例 · 0 schema 改 · 0 LineageRole enum 改 · founder_buff_service 0 改 |
| Q3 conflict_slot_resolution=auto_swap 真语义 | **disciple 自动 equip 新遗物 + 同槽位旧装 unequip 仍持** | disciple.equippedWeaponId/ArmorId/AccessoryId 指新 eqId · 旧装 ownerCharacterId 不变(disciple 仍持入背包语义) |
| Q4 stack_across_generations=false enforce | **加 R5 防回退测 · 不动 derived_stats**(已天然满足) | derived_stats 按 instance count 不按 prev len · §5.4 红线 +15%(3 槽)远低于 +25% 警戒 |
| Q5 founder_buff_service trigger 扩 | **0 改** | P2.3 已设计「active 中存在 isFounder=true → 激活」· promotedDisciple.isFounder=true 自然接管 |
| Q6 R5 多代测族 | R5.6 多代 e2e + R5.7 auto_swap + R5.8 stack_across enforce | 沿 R5.1-5.5 体例 |
| Q7 UI 改动 | AscensionScreen + LineagePanel | 加 promotedDisciple 下拉 + 多代链路显示 chip |

## Batch 拆分

### Batch 1.1 schema(0 改)+ Service 扩(~1.5-2h)
- `lib/features/ascension/application/ascend_service.dart` · `performAscend` 加 `promotedDiscipleId: int?` 参数:
  - 校验 promotedDiscipleId(若非 null)在 discipleTargets 内
  - 副作用 5(原 P2.3):**改** `promotedDisciple.isFounder=true`(不动 founder.isFounder · 不动 lineageRole)
  - 副作用 6(新增 · Q3 auto_swap):每件 heritage 装备 transfer 后,**若 disciple 该槽位已有装备(同 slot Equipment.slot),`disciple.equipped{Slot}Id` 指向新遗物 · 旧装备 ownerCharacterId 仍是 disciple(自动入背包语义)**
  - 副作用 7(新增):若 promotedDiscipleId 非 null,**SaveData.activeCharacterIds 不动**(promotedDisciple 已在 active)+ 触发 invalidate `founderBuffActiveProvider`
- `lib/features/ascension/domain/ascension_models.dart` · `AscensionResult` 加 `promotedDiscipleId: int?`(摘要给 UI snackbar)
- `lib/features/ascension/application/ascend_service_providers.dart` · 0 改(provider 复用)

### Batch 1.2 UI(~1.5-2h)
- `lib/features/ascension/presentation/ascension_screen.dart` · 末加 `_PromotedDiscipleRow`(沿 `_EquipmentRow` 体例 DropdownButton 列 discipleTargets 选第 1 个默认 = 大弟子)+ `_performAscend` 改 `await svc.performAscend(selections, promotedDiscipleId: _promotedId)`
- `lib/features/character_panel/presentation/lineage_panel_screen.dart` · `_AscensionSection` 加 promotedDisciple 提示行(button click 前显示「将传位于:大弟子 X」)
- `lib/features/character_panel/presentation/character_panel_screen.dart` · 多代师承链路 chip:渲染 `equipment.previousOwnerCharacterIds.length` 若 > 1 → 显「N 代传承」chip
- `lib/shared/strings.dart` · 加 5-8 段 UiStrings:`ascensionPromotedLabel`/`ascensionPromotedHint`/`ascensionMultiGenChip(N)`/`ascensionPromotionSnackbar`/`ascensionAutoSwapNote`

### Batch 1.3 R5 多代测族 + closeout(~1-1.5h)
- `test/features/ascension/application/ascend_service_test.dart` 加 3 族 ~5-7 测:
  - **R5.6 多代飞升 e2e**(2 测):gen1 founder=1 → promoted=2(传 1 件 → prev=[1])· gen2 founder=2 → promoted=3(传 1 件 → prev=[2])· 第 2 件 prev=[1,2] 验证 · 第二代 founder_buff 激活 promotedDisciple=2 · 第三代 promotedDisciple=3
  - **R5.7 conflict_slot_resolution=auto_swap**(2 测):disciple 已戴 weapon Y(gen0)· gen1 飞升传 weapon X 给 disciple → disciple.equippedWeaponId=X · Y.ownerCharacterId=disciple(仍持入背包语义)· 验证 founder.equippedWeaponId=null
  - **R5.8 stack_across_generations=false enforce**(1 测):disciple 装多件遗物(prev len=1, prev len=2, prev len=3)· `CharacterDerivedStats.maxHp / criticalRate / internalForceMaxWithLineage` 算 lineage bonus 仅按 isLineageHeritage instance count(3 件 = +15%)· 不按 prev len 累加
- `docs/handoff/p5_lineage_full_closeout_2026-05-24.md`(≤80 行)
- PROGRESS 顶段加(净增长 ≤ 0 · 砍同等旧段)
- GDD §12.2 #10 段更新「P5+ 多代飞升 + 真传位实装 ✅」
- CLAUDE.md v1.10 注

## 改动文件清单 + 行数估

| 文件 | 改动 | 行数估 |
|---|---|---|
| `lib/features/ascension/application/ascend_service.dart` | performAscend 加 promotedDiscipleId 参数 + auto_swap 副作用 + Doc 扩 | +50/-5 |
| `lib/features/ascension/domain/ascension_models.dart` | AscensionResult 加 promotedDiscipleId | +5/-1 |
| `lib/features/ascension/presentation/ascension_screen.dart` | _PromotedDiscipleRow + _performAscend 改 + dialog 加确认 promoted | +90/-10 |
| `lib/features/character_panel/presentation/lineage_panel_screen.dart` | _AscensionSection 加 promoted 提示 | +15/-2 |
| `lib/features/character_panel/presentation/character_panel_screen.dart` | 多代 chip 渲染 | +10/-0 |
| `lib/shared/strings.dart` | 5-8 段 UiStrings | +12/-0 |
| `test/features/ascension/application/ascend_service_test.dart` | R5.6/R5.7/R5.8 3 族 5-7 测 + boostToAscensionReady 扩 | +200/-5 |
| `docs/handoff/p5_lineage_full_closeout_2026-05-24.md`(new) | closeout | +75 |
| `data/numbers.yaml` | yaml 注释扩(4 行)说明 P5+ 实装 | +5/-3 |
| `data/numbers_config.dart` | doc 注释扩(4 行)说明字段 P5+ 真消费 | +5/-2 |

合计 +467/-28 · 7 lib + 1 test + 1 closeout + 2 yaml/config doc 改

## 不变量沿用

- **GDD §5.4 红线完全不动**(普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000)· §5.3 三系锁死 · §5.5 在线=离线 · §5.6 公式 0 改
- **Character/Equipment Isar schema 0 改**(复用 isFounder + isActive · 不加 isAscended / generationIndex · 不动 LineageRole enum)
- **founder_buff_service 0 代码改**(P2.3 已设计「active 中 isFounder=true → 激活」语义自然承载传位)
- **BattleStrategy 接口 3 method 不动**(飞升非战斗)
- **AscendService 体例**:caller 持锁 writeTxn 不变(对齐 RecruitmentService / FounderBuffService · 不在 service 内开 writeTxn)
- **R5.1-5.5 原 14 测全过**(不破 P2.3 一代飞升 e2e)· R5 加 3 族保 baseline 1283 → 1289-1291
- **doc 体量**:本 spec 实测 ~125 行 ≤150(memory `feedback_doc_inflation_overnight`)· closeout 目标 ≤80 · PROGRESS 净增长 ≤0
- **数值红线**:lineage heritage 件数 cap 自然 3 件(disciple 3 装备槽)+5% × 3 = +15% < +25%(yaml 注 §5.4 警戒)

## 挂账下批

- 批 2 = ⑥ P1.2 江湖恩怨(~6-8h xhigh)· NPC 关系网 + Isar 持久化 + 触发条件 + 影响 NPC 反应 · 与师徒升级链解耦
- Pen Codex Windows 视觉验收 P5+ 多代飞升流(异步 ~1h · 非阻塞)
- narrative 多代师承「太祖→祖师→新祖师」叙事弧(留 P5+ 真做飞升 narrative 扩展时同步)
