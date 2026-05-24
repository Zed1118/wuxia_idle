# P1.2 §12.1 江湖恩怨 + §12.2 声望 spec(默认决议草案)

> 日期:2026-05-24 / 模型:Mac + Opus 4.7 xhigh / 估时 ~7-8h xhigh(B1 2h + B2 2h + B3 1.5h + B4 1.5h)
> 上游 Phase 0:`docs/phase0/p1_2_jianghu_enmity_phase0_2026-05-24.md`(Q1-Q5 候选 · 5 维 greenfield ✅)
> 沿例:`docs/spec/p2_3_ascension_spec_2026-05-24.md` + `docs/spec/p3_2_mass_battle_spec_2026-05-24.md`
> ⚠ **本 spec 基于 Q1-Q5「默认决议版」起草** · 用户起床改 Q1-Q5 后改本文件 §0 表 + §2-7 局部即可,不需要重写。

---

## 0. Q1-Q5 决议(默认占位 · 用户拍板后填)

| Q | 主轴 | 默认决议 | 理由 |
|---|---|---|---|
| Q1 | §12.1 + §12.2 合批 / 拆批 | **B 拆批**:声望先(B1+B2)· enmity 后(B3 局部 + 1.1 全) | 降单波风险 · 用户偏好小步快跑 |
| Q2 | NpcRelation schema 粒度 | **B 稀疏 NpcRelation{source,target,type,level}** | 全连接 N×N 矩阵爆 schema · 单向 enmity 表达不够 |
| Q3 | 触发维度 | **A stage_boss kill + B encounter NPC** | C 心法 / D narrative 选项留 1.1 · A+B 覆盖 Demo §8.4 主轴 |
| Q4 | NPC 反应影响 | **A UI narrative + B 战斗 ±15-25%** | 沿 P3.1.B `attackPowerMultiplier` view layer 体例 · D 援军 stage 留 1.1 |
| Q5 | 声望分阶 | **A 沿 GDD §5.2 七阶节奏** | 锁三系 · 不为 P1.2 单开新阶 anti-pattern(违反 §5.2 红线) |

## 1. 范围

- **核心 deliverable**:① `Reputation` Isar Collection(多门派 [-100,+100])② `NpcRelation` Isar Collection(稀疏 source/target/type/level)③ `ReputationService`(累积 + 阶映射 + invalidate)④ `NpcRelationService`(CRUD + enmity 阈值查询)⑤ `ReputationPanelScreen`(7 阶进度 + 关系列表)⑥ Hud 角标(当前声望阶)⑦ 战斗集成:enmity ≥ 阈值 → `attackPowerMultiplier ±0.15-0.25`(沿 P3.1.B `light_foot_strategy.dart:120` 体例)⑧ encounter NPC 反应分支(沿 `encounter_service.dart` fortune 软概率体例)⑨ R5 红线 4-5 族(7 阶 cap / enmity 阈值 / 战斗 buff / 沿 §5.2 不破)
- **配套**:numbers.yaml 加 `jianghu` 段(7 阶阈值 + enmity 战斗 modifier + 阶递进事件量)· stages.yaml 5-8 关 boss 加 `npcId` 字段 · 6-10 encounter 加 `affects_reputation` 字段
- **范围 OUT**:Q3 C 心法触发 / Q3 D narrative 选项分支 / Q4 D enmity ≥80 援军 stage / Q5 C 双轴行侠+行恶 / §12.4 P3.4 sect 维度(独立 Collection 不共用)/ 心魔系统(P3.2.C 销账)/ Ch4-6 narrative 集成(P1.x 已闭)

## 2. schema 改动

```dart
// lib/features/jianghu/domain/reputation.dart(新 Isar Collection)
@collection
@Index(composite: [CompositeIndex('playerId'), CompositeIndex('factionId')], unique: true)  // 防同 (player, faction) 多行重复
class Reputation {
  Id id = Isar.autoIncrement;
  late int playerId;            // 多 save 隔离 · 沿 SaveData.playerCharacterId 体例(Demo 单 save 但 schema 预留)
  late String factionId;        // door_id e.g. "shaolin" / "wudang" / "luLin"(Demo 6-8 门派)
  @Index() late int value;      // [-100, +100] · clamp 入仓
  late DateTime updatedAt;
  // 阶映射 derived(走 ReputationService.tierOf · 7 阶沿 §5.2)
}

// lib/features/jianghu/domain/npc_relation.dart(新 Isar Collection · 稀疏)
@collection
class NpcRelation {
  Id id = Isar.autoIncrement;
  @Index() late int sourceCharacterId;  // 玩家 = SaveData.playerCharacterId · NPC = npcDef.id 映射
  @Index() late int targetCharacterId;
  late String type;             // friend / foe / master / disciple / owed(沿 phase0 §12.4 草案)
  late int level;               // [-100, +100] · enmity = level ≤ -50
  late DateTime updatedAt;
}
```

```yaml
# data/numbers.yaml(尾部加 jianghu 段 · 沿 inner_demon/mass_battle 体例)
jianghu:
  reputation_tiers:                # 7 阶沿 §5.2:学徒/三流/二流/一流/绝顶/宗师/武圣
    - { tier: xueTu,    min: -100, max: -71, label: "声名狼藉" }
    - { tier: sanLiu,   min: -70,  max: -41, label: "恶名" }
    - { tier: erLiu,    min: -40,  max: -11, label: "默默无闻" }
    - { tier: yiLiu,    min: -10,  max:  10, label: "薄有微名" }  # 中间区间
    - { tier: jueDing,  min:  11,  max:  40, label: "侠名初显" }
    - { tier: zongShi,  min:  41,  max:  70, label: "声振江湖" }
    - { tier: wuSheng,  min:  71,  max: 100, label: "天下闻名" }
  enmity_combat_modifier:          # Q4=B 战斗整合
    threshold: -50                  # enmity ≥ |threshold| 触发(第 1 档)
    player_attack_power_mult: 1.15  # vs 敌对 NPC +15% 攻击(玩家方)
    enemy_attack_power_mult: 1.15   # 敌方亦 +15% 攻击(双向恩怨 · sane default 对等不偏护)
    severe_threshold: -80           # 第 2 档:深仇大恨 level ≤ -80 触发
    severe_mult: 1.25               # severe 档 ±25%(对齐 clamp_max · 否则原 25% 永远触不到)
    clamp_max: 1.25                 # ≤25% 防越 §5.4 隐性红线
  triggers:                        # Q3=A+B
    stage_boss_kill_delta: 5        # 击杀有派别 boss · 该派 -5 / 敌对派 +3
    stage_boss_kill_rival_delta: 3
    encounter_npc_delta_min: -8
    encounter_npc_delta_max: 8
```

> **不改 numbers.yaml**(实装时 B1 加)· 此处仅 schema 引用 `numbers.yaml.jianghu.<key>` 锚字段名。

## 3. ReputationService + NpcRelationService 设计(~140 行 · `lib/features/jianghu/application/`)

- **`ReputationService`**(沿 `founder_buff_service.dart` provider 体例)
  - `applyDelta(factionId, delta)` writeTxn upsert + clamp [-100,+100]
  - `tierOf(value) → ReputationTier`(查 `numbers.yaml.jianghu.reputation_tiers`)
  - `allReputations()` stream(UI 反应)
  - invalidate:`reputationByFactionProvider(factionId)` + `reputationTierProvider`
- **`NpcRelationService`**(沿 `lineage_service.dart` 体例)
  - `upsert(source, target, type, level)` writeTxn
  - `enmityAgainst(playerCharacterId) → List<NpcRelation>` where `type=foe && level ≤ -50`
  - `attackPowerMultFor(playerCharacterId, enemyNpcId) → double` 1.0 / 1.15 / 1.25 clamp
- **`EncounterIntegration`**(沿 `encounter_service.dart:216` softProbability 公式 · 0 新公式)
  - encounter resolve 时若 `affects_reputation` 非空 → `ReputationService.applyDelta`
  - encounter pickPool 时按当前 `tierOf(value)` 过滤(高声望解锁正派 encounter · 反之亦然)

## 4. UI 接入(`lib/features/jianghu/presentation/`)

- **`ReputationPanelScreen`**(沿 `lineage_panel_screen.dart` 卡片三段式)
  - 顶:玩家姓名 + 当前 reputation 主阶 chip(7 阶颜色梯度 · 沿 RealmTier 色板)
  - 中:门派列表 ListView · 每行 factionId / value progress bar / tier label(`numbers.yaml.jianghu.reputation_tiers[*].label`)
  - 底:NPC 关系卡(`NpcRelationService.allFor(playerCharacterId)`)分组 friend / foe / master / owed
- **HUD 角标**:`main_menu` 顶部插主阶 chip(沿 `character_panel` realm chip 体例)· 点击 push ReputationPanelScreen
- **`UiStrings`**:`reputationTitle` / `reputationTierLabels` (7) / `enmityWarning` / `panelFriendSection` / `panelFoeSection` 共 ~12 段
- **narrative 分支**(Q4=A):encounter 文本按 `tierOf(value)` 切换 · 沿 `encounter_service.dart` outcome 分支 · `data/events/<encounter_id>.yaml` 加 `branches_by_reputation_tier` 可选段(其余 encounter 不改)

## 5. 战斗整合(`attackPowerMultiplier` 接入 · Q4=B)

- 沿 `light_foot_strategy.dart:120` `attackPowerMultiplier: m.damageMultiplier` view layer 体例 · base 公式 §6 不动
- `BattleCharacter` 已有 `attackPowerMultiplier` 字段(v1.12 P3.1.B 实装,无 schema 改)
- battle setup 阶段(`battle_providers.dart:73 startBattle()`)注入:对 each `enemyNpcId in rightTeam` 查 `NpcRelationService.attackPowerMultFor(playerId, enemyNpcId)` → 烘焙到 leftTeam[*].attackPowerMultiplier 与 rightTeam[*].attackPowerMultiplier(双向对等)· clamp `numbers.yaml.jianghu.enmity_combat_modifier.clamp_max = 1.25`
- **不动 `DamageCalculator` / `DefaultGroundStrategy._calculateInBattle`**(已乘 attackPowerMultiplier)

## 6. 数据流(yaml schema + 加载层)

- **`data/factions.yaml`**(新 · 6-8 门派 Demo)`{id, name, alignment: orthodox/evil/neutral, npcIds: [...]}` · 沿 `techniques.yaml` 列表体例
- **`stages.yaml`**:5-8 关 boss entry 加 `npcId` 可选字段(`stage_03_05 boss_zhao_yima`)· 加载层 `stage_def.dart` 扩字段 nullable
- **`encounters.yaml`**:6-10 encounter 加 `affects_reputation: {factionId, deltaMin, deltaMax}` 可选段(rng [min,max])
- **加载层**:`NumbersConfig` 扩 `JianghuConfig`(reputation_tiers 列表 + enmity_combat_modifier + triggers)· 沿 `HeritageItems` / `MassBattleConfig` 解析体例

## 7. R5 红线测族(~10-12 测 · `test/jianghu/`)

- **R5.1 reputation 7 阶 e2e**:从 -100 → +100 sweep 21 测点 · `tierOf(value)` 匹配 `numbers.yaml.jianghu.reputation_tiers` · clamp ±100 不越界(2 测)
- **R5.2 enmity 阈值**:level=-49/-50/-51 · `attackPowerMultFor` 返 1.0 / 1.15 / 1.15(2 测)
- **R5.3 战斗 §5.4 cap 不越**:fixture wuSheng·dengFeng + enmity active · damage_calculator 输出 ≤ 8000 普伤红线(1 测)
- **R5.4 trigger e2e**:stage_boss_kill → reputation delta + rival delta(2 测)/ encounter delta(1 测)
- **R5.5 §5.2 不破**:7 阶 label 全等 §5.2 7 境界词(`xueTu..wuSheng`)· 不开新阶(1 测)
- **R5.6 P3.4 隔离**:`Reputation` 与 `SectReputation`(若存)Collection 字段分离 · Dart schema-level 断言(1 测,沿例 `expect(Reputation.factionId.runtimeType, isNot(SectReputation.sectId.runtimeType))` 或 isar collection schema name 断言两 collection name 不等;**禁 grep 校验**,grep 跨文件文本匹配脆性 + 不反映 schema 真隔离)
- **baseline ~1297 + delta ~10-12**(B4 落地后实测)

## 8. Batch 拆分(估时 ~7h xhigh)

| Batch | 内容 | 估时 |
|---|---|---|
| B1 schema + numbers | `data/numbers.yaml jianghu` 段 + `Reputation/NpcRelation` Isar Collection + `JianghuConfig` 解析 + `data/factions.yaml` + stages.yaml boss `npcId` + encounters.yaml `affects_reputation` | ~2h |
| B2 service + trigger | `ReputationService` + `NpcRelationService` + `EncounterIntegration` + stage_boss_kill hook(`battle_result_service` 调 applyDelta)+ provider 4 项 | ~2h |
| B3 UI + battle 集成 | `ReputationPanelScreen` + HUD 角标 + `UiStrings` 12 段 + battle setup 注入 attackPowerMultiplier + narrative branches 接入 1-2 encounter | ~1.5h |
| B4 R5 + closeout | R5.1-5.6 测族 + closeout doc + GDD §12.1 / §12.2 升档(占位 → P1.2 实装 ✅)+ PROGRESS 顶段 + ROADMAP P1.2 段 | ~1.5h |

## 9. 估时 + 风险 + 挂账

- **估时**:B1 2h + B2 2h + B3 1.5h + B4 1.5h = **~7h xhigh**(对齐 phase0 ~6-8h 估)
- **风险**:① Q3 C 心法触发挂账 1.1(无影响 Demo)② Q4 D 援军 stage 挂账 1.1 ③ P3.4 sect 维度独立 Collection(`Reputation.factionId` vs `SectReputation.sectId` 不共用 · R5.6 校验)
- **不变量沿用**:GDD §5.4 红线完全不动(enmity buff clamp 1.25 + R5.3 校验)· §5.3 三系锁死(不开新阶)· §5.5 在线 = 离线(reputation 变化仅靠 stage_boss kill / encounter trigger,无后台累积)· §5.1 反留存(无每日声望任务)· BattleStrategy / DamageCalculator 0 改 · §6 公式不动 · founder_buff_service 0 改
- **doc 体量**:本 spec ≤150 · B4 closeout ≤80 · PROGRESS 净增长 ≤ 0(新顶段加 = 旧段砍)
- **memory `feedback_phase05_diagnose_before_solve`**:R5 测有挂账时 B4 不直上候选解法

---

**P1.2 spec 收口(默认决议草案)**:Q1=B 拆批 / Q2=B 稀疏 / Q3=A+B / Q4=A+B / Q5=A 七阶 · Batch B1-B4 拆解 · 估时 ~7h xhigh · ⚠ 用户起床改 Q1-Q5 后改本 spec §0 + §2-7 局部 · 起新 worktree `feat/p1_2_jianghu_impl` 走 B1
