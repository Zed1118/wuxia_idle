# P5+ 多代飞升 + 真传位完整链路 closeout(④+⑤ 合并)

> 日期:2026-05-24 / 模型:Opus 4.7 xhigh / 工时 ~2h30min(spec 估 ~5-7h · 精度 0.42×)
> 主 cwd `/Users/a10506/Desktop/挂机武侠` @ main · 直推 main(无 PR)
> 上游 spec:`docs/spec/p5_lineage_full_spec_2026-05-24.md`(96 行)

---

## TL;DR

P5+ ④ 多代飞升 + ⑤ 真传位完整链路全闭环 ✅(spec 合并方案 · 1 batch ship 3 commit + 1 doc · 4 commit `1e875d6 → 1b1bb86`)。**0 schema 改 · 0 公式改 · founder_buff_service 0 代码改**(P2.3 留好的 isFounder+isActive 两轴语义自然承载传位)。1286 pass / 1 skip / 0 analyze → **1291 pass / 1 skip / 0 analyze**(+5 R5 多代测 · R5.6 2 + R5.7 2 + R5.8 1)。1.0 P2 + P5+ 真传位 → **1.0 整体 ~90%**。

## R5 测族(18 测 · `test/features/ascension/application/ascend_service_test.dart`)

| 族 | 测数 | 范围 |
|---|---|---|
| R5.1 飞升红线 e2e | 1 | P2.3 baseline |
| R5.2 eligibility 子条件 | 5 | P2.3 baseline |
| R5.3 player_pick 分配 | 3 | P2.3 baseline |
| R5.4 边界 throw | 4 | P2.3 baseline |
| R5.5 §5.4 数值红线 | 1 | P2.3 baseline |
| **R5.6 多代飞升 e2e** | 2 | gen1→gen2 完整链 + promotedDiscipleId=null 兼容 P2.3 路径 |
| **R5.7 conflict_slot_resolution=auto_swap** | 2 | weapon+armor swap + accessory enum 分支防漏 |
| **R5.8 stack_across_generations=false enforce** | 1 | 多代 prev len=2 仍按 instance count(防回退) |

## 关键改动

| 文件 | 改动 | 行数 |
|---|---|---|
| `lib/features/ascension/application/ascend_service.dart` | performAscend 加 promotedDiscipleId + 副作用 4 auto_swap + 副作用 7 promoted 接管 | +55/-13 |
| `lib/features/ascension/domain/ascension_models.dart` | AscensionResult 加 promotedDiscipleId 字段 | +5/-1 |
| `lib/features/ascension/presentation/ascension_screen.dart` | _promotedDiscipleId state + _setPromotedDisciple + _PromotedDiscipleRow widget + _performAscend 传参 | +95/-7 |
| `lib/shared/strings.dart` | 4 段 UiStrings(promoted section/hint/none + multiGenChip) | +7/-0 |
| `data/numbers.yaml` | yaml 注释扩(stack/swap 字段 P5+ 真消费状态) | +6/-4 |
| `lib/data/numbers_config.dart` | doc 注释扩(stack/swap P5+ 真消费 + spec ref) | +5/-3 |
| `test/features/ascension/application/ascend_service_test.dart` | R5.6/R5.7/R5.8 4 测 + 删 unused import | +261/-1 |
| `docs/spec/p5_lineage_full_spec_2026-05-24.md`(new) | spec doc | +96 |
| `docs/handoff/p5_lineage_full_closeout_2026-05-24.md`(new) | closeout(本) | +70 |
| `PROGRESS.md` | 顶段加 + 砍同等旧段 | net ≤0 |
| `GDD.md` | v1.15 + §12.2 #10 段加 P5+ 实装注 | +3/-1 |

合计 +603/-30 · 6 lib + 1 test + 2 yaml/config doc + 4 doc 改

## 诊断时间线

1. **Phase 0 reality check**(~15min):6 维 grep 摸清 P2.3 已铺好 70%+ 底(`Equipment.previousOwnerCharacterIds: List<int>` 天然多代 / `Character.{isFounder,isActive}` 两轴齐 / `FounderBuffService.computeBuffActive` 已是「active 中 isFounder=true → 激活」语义)。**关键发现**:④ 单独做没真多代场景可测(需 ⑤ 真传位 founder promotion 当前置)→ 推荐合并 ④⑤ 一批
2. **spec 起草**(~20min · 96 行):Q1 player_pick 沿 P2.3 体例 + Q2 不真切 lineageRole + Q3 auto_swap 真实装 + Q4 stack=false 加 R5 防回退 + Q5 founder_buff_service 0 改 + Q6 R5.6/7/8 测族 + Q7 UI 集中 AscensionScreen
3. **Batch 1.1 Service**(~45min):performAscend 加 promotedDiscipleId 参数 + 副作用 4 auto_swap + 副作用 7 promoted 接管(commit `a1d17ea`)
4. **Batch 1.2 UI**(~40min):AscensionScreen 加 _promotedDiscipleId state + _PromotedDiscipleRow widget(commit `15fc187`)
5. **Batch 1.3 R5 测族**(~30min):R5.6/R5.7/R5.8 4 测全过(commit `1b1bb86`)+ 顺手删 ascend_service_test pre-existing unused_import warning
6. **本 doc 收口**(~20min):closeout + PROGRESS + GDD v1.15 + 本 commit

## 不变量沿用

- **GDD §5.4 红线完全不动**(普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000)· §5.3 三系锁死 · §5.5 在线=离线 · §5.6 公式 0 改
- **Character/Equipment Isar schema 0 改**(复用 isFounder + isActive · 不加 isAscended / generationIndex · 不动 LineageRole enum)
- **founder_buff_service 0 代码改**(P2.3 已设计「active 中存在 isFounder=true → 激活」语义自然承载传位 · §Q5 验证)
- **BattleStrategy 接口 3 method 不动**(飞升非战斗)
- **AscendService 体例**:caller 持锁 writeTxn 不变 + 4 method 签名向后兼容(promotedDiscipleId 可选 · null = P2.3 路径)
- **R5.1-5.5 原 14 测全过**(不破 P2.3 一代飞升 e2e · 向后兼容验证 ✅)
- **doc 体量**:本 closeout 实测 70 行 ≤80 ✅ · spec 96 行 ≤150 ✅ · PROGRESS 净增长 ≤0
- **数值红线**:lineage heritage 件数 cap 自然 3 件(disciple 3 装备槽)+5% × 3 = +15% < +25% 警戒

## 挂账下批

- ~~spec~~ ✅ · ~~Batch 1.1 Service~~ ✅ · ~~Batch 1.2 UI~~ ✅ · ~~Batch 1.3 R5~~ ✅
- 批 2 = ⑥ **P1.2 江湖恩怨**(~6-8h xhigh) · NPC 关系网 + Isar 持久化 + 触发条件 + 影响 NPC 反应 · 与师徒升级链解耦 · ROADMAP P1.2 候选
- P5+ UI polish 留下批(可与批 2 并行 · 非阻塞):character_panel 多代师承链路 chip(equipment.previousOwnerCharacterIds.length > 1 显「N 代传承」)+ LineagePanel 显多代弟子链 + 真 narrative 弧(「太祖→祖师→新祖师」叙事)
- Pen Codex Windows 视觉验收 P5+ 多代飞升流(异步 ~1h · 非阻塞)
- `listDiscipleTargets` 已 promoted disciple 过滤(边界 · 防 UI 误显已 promoted 的 disciple 作为 target · YAGNI Demo 不破)留 P5+ UI polish

**会话清理建议**:`建议清理` — P5+ ④+⑤ 完整 4 commit ship · 上下文已堆积较深 · 下波批 2 ⑥ P1.2 江湖恩怨 是全新独立模块(NPC 关系网 + Isar schema + 触发条件)· 新会话起来更紧凑。
