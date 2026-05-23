# P2.3 §7.1 飞升 + 遗物 transfer closeout

> 日期:2026-05-24 / 模型:Opus 4.7 xhigh / 工时 ~2h30min
> 主 cwd `/Users/a10506/Desktop/挂机武侠` @ main · 直推 main(无 PR)
> 上游 spec:`docs/spec/p2_3_ascension_spec_2026-05-24.md`(125 行)

---

## TL;DR

P2.3 §7.1 飞升 + 遗物 transfer 全闭环 ✅(方向 B + Q1a/Q2c/Q3b/Q4d)· 1.0 P2 主线 3 子阶段(P2.1 + P2.2 心魔 + P2.3 飞升)收口 · **1.0 P2 全闭环 ~87%**。3 commit 推 main:`eaa3e00` spec + `05e2135` Batch 3.1 schema/Service + `f8cd163` Batch 3.2 UI + 本批 Batch 3.3 R5 + 顺手修 Equipment.inheritFrom Isar fixed-length list bug。**1283 pass / 1 skip / 0 analyze**(baseline 1269 + delta 14)· 公式层 §5.4 红线 0 改。

## R5 测族(14 测 · `test/features/ascension/application/ascend_service_test.dart`)

| 族 | 测数 | 范围 |
|---|---|---|
| R5.1 飞升红线 e2e | 1 | 全条件 ok + performAscend 2 件 → owner 改 + 遗物标 + founder 出阵 + buff 自然退 |
| R5.2 eligibility 子条件 | 5 | 4 子条件取反 + 1 全 ok |
| R5.3 player_pick 分配 | 3 | 全大弟子 / 1+1 分 / 全二弟子 |
| R5.4 边界 throw | 4 | 0 件 / 3 件 / 非 founder owner / 非 disciple target |
| R5.5 §5.4 数值红线 | 1 | heritage 2 件 → mult 1.10 < 1.20 cap |

## 关键改动

| 文件 | 改动 | 行数 |
|---|---|---|
| `data/numbers.yaml` | 加 `ascension.unlock_triggers` 段(3 条件并存) | +25/-0 |
| `lib/data/numbers_config.dart` | 扩 `HeritageItems`(6 字段消费)+ `AscensionConfig`(unlock_triggers 解析 · empty 兜底) | +127/-0 |
| `lib/core/domain/equipment.dart` | **生产 bug 修**:`inheritFrom` reassign list 替代 `.add()`(Isar fixed-length list · memory `feedback_isar_pitfalls`) | +6/-2 |
| `lib/features/ascension/domain/ascension_models.dart` | AscensionEligibility(5 子条件 + missingReasons)+ AscensionResult | +93 (new) |
| `lib/features/ascension/application/ascend_service.dart` | AscendService(4 method + caller 持锁 writeTxn) | +218 (new) |
| `lib/features/ascension/application/ascend_service_providers.dart` | 4 Riverpod providers(service / eligibility / candidates / disciples) | +66 (new) |
| `lib/features/ascension/presentation/ascension_screen.dart` | AscensionScreen 三段式 ConsumerStatefulWidget | +401 (new) |
| `lib/features/character_panel/presentation/lineage_panel_screen.dart` | 末加 `_AscensionSection`(button + tooltip + 5 子条件) | +84/-2 |
| `lib/shared/strings.dart` | 加 15 段飞升 UiStrings | +30/-0 |
| `test/features/ascension/application/ascend_service_test.dart` | R5.1-5.5 5 族 14 测 + boostToAscensionReady helper | +297 (new) |
| `test/features/character_panel/presentation/lineage_panel_screen_edge_test.dart` | 修宽 finder false positive(memory `feedback_red_line_test_semantics`) | +3/-1 |

## 诊断时间线

1. **Phase 0 六维 grep**(~15min):基础 schema 70%+ 就绪(Equipment.isLineageHeritage / Character.lineageRole+isFounder+isActive / Equipment.inheritFrom / heritage count derived bonus / FounderBuffService + UI panel) · 缺 AscendService + AscensionScreen + numbers.yaml ascension 段
2. **Batch 3.1**(~50min):numbers.yaml + NumbersConfig 扩 2 class + AscendService 4 method + 4 providers · analyze 0 / test 1269 pass 维持
3. **Batch 3.2 UI**(~55min):AscensionScreen 401 行三段式 + LineagePanel 末 _AscensionSection + UiStrings 15 段 · 修 test 宽 finder false positive(「飞升条件未满足」字串「件」字 false positive)
4. **Batch 3.3 R5**(~30min):14 测族 + 暴露 production bug(`inheritFrom .add()` 不能 mutate Isar fixed-length list)修 reassign · entities_test 兼容

## 不变量沿用

- **GDD §5.4 红线完全不动** · §5.3 三系锁死 · §5.5 在线 = 离线 · §5.1 反留存(飞升手动触发不强推)
- **Character/Equipment Isar schema 0 改**(复用 isFounder + isActive + lineageRole · 不加 isAscended 字段)
- **`founder_buff_service` 0 代码改**(只更新注释 · founder isActive=false 自然让 buff 退出)
- **`stack_across_generations=false`** Demo 仅一代飞升,不验证多代场景(YAGNI · P5+ 多代师徒升级再实装)
- **`conflict_slot_resolution=auto_swap` 不实装**(spec 注 P5+ 路径)
- **doc 体量**:本 closeout 实测 65 行 ≤80(memory `feedback_doc_inflation_overnight`)· PROGRESS 净增长 ≤0(新顶段加 = 旧段砍)

## 顺手沉淀

- **memory `feedback_isar_pitfalls`** 新增实战例:Isar `@Collection` 实例的 `List<int>` 字段从 db 读出 = fixed-length,`.add()` 抛 `Unsupported operation: Cannot add to a fixed-length list`。修法:reassign 新 list `xs = [...xs, x]`。本批 `Equipment.inheritFrom` 是 W6+ 实装的老代码,但只在 entities_test 用 fresh Equipment 测过(growable list),生产路径 P2.3 飞升首次走 Isar 读 path 才暴露。

## 挂账下波

- ~~AscendService 主流程~~ ✅
- ~~AscensionScreen UI~~ ✅
- ~~LineagePanel 入口~~ ✅
- ~~R5 红线 5 族~~ ✅
- ~~Equipment.inheritFrom Isar fixed-length list bug~~ ✅
- **narrative ~600 字**(spec §7):`data/narratives/ascension/` 4 yaml(intro / complete / pick_hint / disciple_thank)推下批做(loader 接入 + 文案 + R5 narrative reference test)· 当前 AscensionScreen 走 UiStrings 5 段精简文案,UX 闭环不阻塞
- **Phase 5+ 多代飞升**(`stack_across_generations` / `conflict_slot_resolution` 实装)留 P5+
- **Phase 5+ 真传位**(大弟子接管 founder 身份)留 P5+

**会话清理建议**:`不需要清理` — P2.3 子系统完整闭环,下波 narrative / 其他 1.0 P2 收口子任务紧密关联,继续推进 OK。
