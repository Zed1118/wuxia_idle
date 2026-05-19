# Phase 5+ 师徒系统升级 spec · 2026-05-20

> Nightshift T07 起草。**audit 类 0 改 yaml/lib**,纯方案文档。供 1.0 路线图 Phase 5+(Demo 后)激活时回头看。引用以 `GDD.md §7.1`(L395-407)+ `data/numbers.yaml inheritance` 段(L1065-1095)为锚。

## §1 当前状态(Demo 锚定)

- **角色固定 3**:`data/masters.yaml` 三条(`founder` / `first_disciple` / `second_disciple`),`enabledInDemo: true`
- **`LineageRole` 枚举**:`lib/core/domain/enums.dart:146-148` 只 `founder` / `disciple` 两值,无 `grandDisciple` / `ancestor`
- **飞升禁用**:`numbers.yaml:1094 founder_ancestor_buff.enabled_when_alive: false`(`sect_wide_buff: null`)
- **遗物 4 规则字段已锚定**:`numbers.yaml:1087-1090`(`transfer_trigger` / `multi_disciple_allocation` / `stack_across_generations` / `conflict_slot_resolution`)
- **UI 预研已落**:`lib/features/character_panel/application/lineage_info_provider.dart`(W17 候选 E 派生 view model,`LineageInfo {founder, disciples, heritageEquipments}`)+ `presentation/lineage_panel_screen.dart`,**无 Isar 写入 / 无 schema bump**
- **未铺**:`lib/features/lineage/` 目录、`MasterRepository.unlockDisciple` / `AscendService` / `AncestorBuffService` 均 0(Phase 5+ 时点新建)

## §2 Phase 5+ 解锁节奏(`numbers.yaml:1068-1071 unlock_rules` 锚)

| 突破到 | yaml 锚字段 | Demo 现状 | Phase 5+ 实装位置 |
|---|---|---|---|
| 一流 / 结丹 | `can_take_disciple_at: yiLiu` | 大弟子 / 二弟子 yaml 直挂 active | (已实装,无需新增) |
| 绝顶 / 化神 | `disciple_can_take_grand_disciple_at: jueDing` | 未实装 | **新增** `LineageRole.grandDisciple` 枚举值 + `MasterRepository.unlockGrandDisciple()` + masters.yaml 扩 2 角色 |
| 武圣 / 飞升 | `can_pass_legacy_at: wuSheng` | 不实装(`§3`) | **新增** `AscendService` + `AncestorBuffService` + `enabled_when_alive: true` |

## §3 飞升机制设计(Phase 5+ 实装)

### §3.1 触发条件

玩家(`isFounder=true`)同时满足:① `realm == wuSheng` ② `internalForce >= 内力红线 15000`(`CLAUDE.md §5.4`)③ 主修心法修炼度 9 层圆满 ④ 主线特殊章节解锁(章节 ID 后期拍)。

### §3.2 自动遗物分配 UI 流程

新增 `AscendInheritanceScreen`,沿 `multi_disciple_allocation: player_pick`(L1088):列出全部 `isLineageHeritage=true` 装备 + active 弟子,玩家逐件拖拽分配(非自动)。提交后调 `AscendService.transferHeritage(Map<EquipmentId, DiscipleId>)`。

### §3.3 数据迁移

`AscendService.ascendFounder` 一步事务:① 原 founder 角色 `lineageRole=founder → ancestor`(枚举需扩)、`isFounder=false`、置入 inactive 持久层 ② 大弟子 `lineageRole=disciple → founder`、`isFounder=true`、`slotIndex=0` ③ 二弟子升大弟子(`slotIndex=1`)④ 玩家创角新二弟子(空位 `slotIndex=2`)⑤ heritage 装备按 §3.2 入对应背包槽。

## §4 祖师爷 buff(`founder_ancestor_buff`)激活方案

- **§4.1 触发**:`numbers.yaml:1094 enabled_when_alive: false → true`(Phase 5+ 切换 yaml,无 schema bump)+ `sect_wide_buff` 字段填实(从 `null` 改为 buff list)
- **§4.2 buff 维度建议**(具体数值 v1.0 平衡时拍):内力上限 +5% / 修炼度 base +3% / 暴击率 +2%,**不进伤害公式直接乘,通过 `CharacterStatsService` 派生层挂**
- **§4.3 作用域**:所有 `lineageRole ∈ {founder, disciple, grandDisciple}` 的 active 角色;`ancestor` 自身不享受
- **§4.4 UI 显示**:`LineagePanelScreen` 顶部新增「祖师爷 [名字]」卡片 + 一行 buff 摘要,复用 `lineage_info_provider` 派生(扩 `LineageInfo.ancestor` 可空字段)

## §5 遗物 4 规则代码实装清单(`numbers.yaml:1087-1090` 锚)

| 规则字段 | 代码层落点 | 实装难度 |
|---|---|---|
| `transfer_trigger: ascend_to_wusheng` | `AscendService.transferHeritage`(Phase 5+ 飞升触发,Demo 0 调用) | 中(联动 `AscendInheritanceScreen` + 事务回滚) |
| `multi_disciple_allocation: player_pick` | `AscendInheritanceScreen` 拖拽 UI | 中(逐件分配交互 + 校验弟子是否符合三系锁死) |
| `stack_across_generations: false` | `HeritageBuffCalculator.compute` 只取当代 buff,UI 可显传承链路但不叠 | 低(纯计算层) |
| `conflict_slot_resolution: auto_swap` | `EquipmentService.equipHeritage` 同部位自动卸原装入背包 | 低(沿用现有 swap 逻辑) |

## §6 closeout

本 spec 起草背景:`CLAUDE.md §12.1 #10` v1.5(2026-05-16)规则层 4 子项收口后,Phase 5+ 代码层 0 触碰,趁 nightshift 把方案文档化避免 1.0 路线图回看时 yaml 字段含义需考古。实装顺序建议:**§3 飞升 → §5 遗物 → §4 祖师爷 buff**(飞升是入口,遗物分配是必经,buff 是收尾)。估时锚点:Phase 5+ 三块合计 8-12 工日(Mac + Opus 4.7 单端),具体 1.0 路线图启动时再拆 ticket。
