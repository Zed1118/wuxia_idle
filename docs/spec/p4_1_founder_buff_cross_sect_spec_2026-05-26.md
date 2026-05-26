# P4.1 1.1 挂账 · founder_buff 跨派系扩 spec(默认决议草案)

> **2026-05-26 self-review 应用**:R1 callsite 回归扫描清单(§7)+ R2 Sect lazy-init 守(§3)+ R4 Q6 founder isInSect 拍板(§0)· 详 `docs/handoff/founder_buff_cross_sect_self_review_2026-05-26.md`
>
> 日期:2026-05-26 起草 + self-review 应用 / 模型:Mac + Opus 4.7 xhigh / 估时 ~3-5h xhigh(B1 1-1.5h + B2 1-1.5h + B3 1-2h)
> 上游:P4.1 spec `docs/spec/p4_1_sect_management_spec_2026-05-25.md` §1 范围 OUT 「founder_buff_service derived_stats 作用域扩留 1.1」+ Q6A spec §5 「founder_buff_service 0 改」
> 沿例:P1.1 candidate 2 founder_ancestor_buff 实装(`a0eae82` `enabled_when_alive: true`)+ P4.1 R5.6 当前测族
> ⚠ **本 spec 基于 Q1-Q5 默认决议草案** · 用户拍板后改 §0 + §2-6 局部即可。

---

## 0. Q1-Q5 决议(默认占位 · 用户拍板后填)

| Q | 主轴 | 默认决议 | 理由 |
|---|---|---|---|
| Q1 | API 升级形态 | **A `isBuffActiveFor(character, ...)` per-character 接口**(保留 `computeBuffActive` 旧 API 委派) | 沿 `SectMemberService` per-character writeTxn 体例 · 旧 callsite 0 改 |
| Q2 | playerSectId 信源 | **A 派生**(无新字段 · `Sect.findBy(founderId == save.founderCharacterId)` 反向索引) | Demo 单 sect 假设 · `Sect.id=1` lazy-init by `currentSectProvider` · `SaveData.founderCharacterId` P5.0 已 wire id=1 |
| Q3 | NPC 不享 buff 判定 | **A `c.isInSect && c.sectId == playerSectId`**(`isInSect=false` 时 fallback 单 founder 自享) | P1.1 R5 维持(Demo player+disciples 默认 isInSect=false → 仍享 buff 单代 fallback)· P1.2 跨派系真扩(招进 NPC isInSect=true 但 sectId≠player → 不享) |
| Q4 | derived_stats wire 形态 | **A caller 端 per-character 算 buff bool**(stage_battle_setup 循环 buildPlayerTeam 3 character 各算一次 · 传入 derived_stats) | 不破 derived_stats 当前签名 · 加 R5 测族单测 buff 是否真不串扰 |
| Q5 | batch 拆分 | **A 3 batch**(API 升级 / wire + derived_stats / R5+closeout) | 粒度合适 ~3-5h xhigh |
| Q6 | founder 在 sect lazy-init 时是否自动加入 sect(self-review R4 补) | **A 不动**(保持 isInSect=false · founder 单代路径享 buff · 不破 P1.1 R5) | 1.2 跨派系 wire + NPC 招收路径配合时再拍 · 当前最小动作 |

## 1. 范围

- **核心 deliverable**:① `FounderBuffService.isBuffActiveFor(character, numbers)` 新 per-character API + 旧 `computeBuffActive` 委派(沿 P1.1 单 founder fallback) ② `playerSectIdProvider` Riverpod 派生(`currentSectProvider.value?.founderId == save.founderCharacterId ? sect.id : null`) ③ `stage_battle_setup._buildPlayerTeam` 循环内 per-character 算 buff bool + 传入 derived_stats ④ R5 红线测族 6-8 测(原 R5 维持 + 跨派系真扩 + 玩家自己有 sect/无 sect fallback)⑤ P4.1 R5.6 测族升档(原占位 → 真 wire)
- **配套**:① `lib/features/sect/application/sect_providers.dart` 加 `playerSectIdProvider`(派生 currentSect / SaveData) ② `lib/features/battle/application/stage_battle_setup.dart:97` `founderBuffActive` 单点改 per-character map(每 character.id → bool)③ `numbers_config.dart` `founderAncestorBuff` 段不动(yaml schema 已 OK)
- **范围 OUT**:① P1.2 跨派系 NPC 招进路径(Q6A spec 已拍 sect_candidates · 本 spec 不重做) ② 多代飞升 founder buff 跨代 sect 跟随(P5+ 已实装 isFounder rewire · 本 spec 不动) ③ NPC 多 sect 归属(Demo 单 sect 假设) ④ founder_buff effect 公式调整(numbers.yaml `founder_ancestor_buff` 段不动 · 仅 wire 作用域扩) ⑤ joint_skill / cultivation_progress_pct buff 路径(P5+ 留)

## 2. schema 改动

```dart
// lib/features/inheritance/application/founder_buff_service.dart(扩 · 加 per-character API)
class FounderBuffService {
  final Isar isar;
  FounderBuffService(this.isar);

  /// 整体 buff 激活态(老 API · P1.1 体例 · 单代 fallback caller 用)。
  /// Demo 单 sect / 多代飞升场景沿用,不破 P1.1 R5 红线。
  Future<bool> computeBuffActive(NumbersConfig n) async { ... 现有 46 行 }

  /// **per-character buff 激活态**(P4.1 1.1 跨派系扩)。
  ///
  /// 判定规则:
  /// 1. yaml `enabled_when_alive=true`(同 [computeBuffActive])
  /// 2. SaveData.activeCharacterIds 中存在 isFounder=true 角色(同上)
  /// 3. **跨派系**(本扩展):
  ///    - target.isInSect=false → fallback 单 founder 自享(P1.1 维持)
  ///    - target.isInSect=true && target.sectId==playerSectId → 享
  ///    - target.isInSect=true && target.sectId!=playerSectId → 不享(NPC 跨派系)
  Future<bool> isBuffActiveFor({
    required Character target,
    required NumbersConfig numbers,
    required int? playerSectId,
  }) async {
    final active = await computeBuffActive(numbers);
    if (!active) return false;
    if (!target.isInSect) return true;           // P1.1 fallback 维持
    return target.sectId == playerSectId;
  }
}
```

```dart
// lib/features/sect/application/sect_providers.dart(末加 · ≤10 行)
/// 玩家 sect.id 派生(Demo 单 sect 假设)。
/// founder=save.founderCharacterId · sect.id=1(lazy-init)· 无 founder 时 null。
final playerSectIdProvider = Provider<int?>((ref) {
  final sect = ref.watch(currentSectProvider).value;
  if (sect == null) return null;
  // 玩家是否 founder of this sect(Demo 单 sect 玩家 = 祖师 = sect.founderId=1)
  // SaveData.founderCharacterId == sect.founderId → 玩家 sect
  // 此处简化:Demo 单 sect 即为 player sect(无 jianghu sect 区分)
  return sect.id;
});
```

> **不改 numbers.yaml**(founder_ancestor_buff 段不动)· **不改 Isar schema**(`Character.{isInSect, sectId, sectRank}` P4.1 已加)· **不改 derived_stats 签名**(`founderBuffActive: bool` 参数保留 · 仅 caller 端传入算法变)

## 3. wire 路径(`lib/features/battle/application/stage_battle_setup.dart`)

- **当前 line 97**:`founderBuffActive = await founderBuffSvc.computeBuffActive(numbers)`(整队同一 bool)
- **改后**(per-character map):
  ```dart
  final playerSectId = ref.read(playerSectIdProvider);
  final founderBuffByChar = <int, bool>{};
  for (final c in playerTeamCharacters) {
    founderBuffByChar[c.id] = await founderBuffSvc.isBuffActiveFor(
      target: c, numbers: numbers, playerSectId: playerSectId,
    );
  }
  // 每 character build BattleCharacter 时传入对应 bool
  ```
- **derived_stats 三处 caller**(`derived_stats.dart:109, 168, 241`):signature 不变 · stage_battle_setup 端按 character 拿对应 bool 传入
- **battle_state.dart:168** `founderBuffActive` 参数同步(BattleCharacter build 路径)
- **caller 持锁纪律**:per-character 算法纯 read(无 writeTxn)· 沿 P4.1 spec 体例
- **Sect lazy-init 守**(self-review R2 修):`playerSectIdProvider` 在 `currentSectProvider.value == null` 时返 null · isBuffActiveFor 内 fallback `target.isInSect=false → true`(P1.1 单代享路径维持)· 沿 Q6A spec §3 R3 修体例(本 spec 不重复 Sect.put fallback · `currentSectProvider` 自动 lazy-init Sect.id=1 在 watch 第一帧)
- **P5+ 真传位兼容**(self-review R7 注):promoted disciple `isFounder=true` 后 `isInSect/sectId/sectRank` 是否同步 — 1.2 跨派系 wire 时拍 · 本 spec 不动 founder 端 schema · 沿 P5+ v1.15 已实装路径

## 4. R5 红线测族(~6-8 测 · `test/features/inheritance/application/founder_buff_service_test.dart` + 新 cross_sect 段)

- **R5.1 P1.1 原红线维持**(回归保护 · **self-review R1 必改:加 callsite 回归扫描清单**):Demo 玩家 = 祖师 + 大弟子 + 二弟子 全 isInSect=false → 3 character 全享 buff(`isBuffActiveFor` 全 true · 沿 P1.1 单 founder fallback)· **本测须先跑确保不破老红线** · **B2 实装前必跑 callsite sweep**:`grep -rn "founderBuffActive" lib/ test/`(全仓 28 锚 · lib 15 + test 13)· 每锚验证 per-character map 传入对应 bool 不破 P1.1 红线 · 沿 P0.2 strategy 重构 sweep 体例
- **R5.2 跨派系 NPC 不享**:招进 NPC sectId=2(假设另一 sect)→ `isBuffActiveFor` 返 false · player 仍享(1 测)
- **R5.3 同 sect 成员享**:招进 NPC sectId=playerSectId=1 → `isBuffActiveFor` 返 true(1 测)
- **R5.4 fallback 单 founder 无 sect**:玩家 isInSect=false + sect 不存在(currentSectProvider null)→ `playerSectId=null` → fallback isInSect=false 路径享(1 测)
- **R5.5 founder 飞升退 active 后 buff 失效**:founder isActive=false(P5+ 多代后)+ 无新 isFounder=true 角色 active → `isBuffActiveFor` 全 false(回归 P5+ 已 ship 体例 · 1 测)
- **R5.6 多代飞升 promoted disciple 接管**:promoted disciple isFounder=true && isActive=true → 自身享 + 接管 isInSect=false 弟子享(1 测 · 沿 P5+ v1.15 体例)
- **R5.7 derived_stats per-character 不串扰**:battle 中 player(isInSect=false 享)+ NPC(isInSect=true,sectId≠player 不享)同队 → derived_stats.maxHp 算分别正确(1 测 · stage_battle_setup 集成)
- **R5.8 §5.4 红线守**:跨派系扩 wire 后 maxHp 不破 20000 / crit 不破 50% / internal 不破 15000(1 测)
- **baseline ~1484 + delta ~6-8**(B3 实测 · 沿 P4.1 体例)

## 5. Batch 拆分(估时 ~3-5h xhigh)

| Batch | 内容 | 估时 |
|---|---|---|
| B1 API 升级 | `FounderBuffService.isBuffActiveFor` 新 API + `computeBuffActive` 保留委派 + `playerSectIdProvider` Riverpod 派生 + Provider 注入 service signature 调整(可选)+ founder_buff_service_test 加 R5.2-5.4 单测(3 测) | ~1-1.5h |
| B2 wire + derived_stats | `stage_battle_setup._buildPlayerTeam` per-character map 改 + derived_stats 三处 caller 传入对应 bool + battle_state.dart 同步 + 回归测 R5.1 维持 | ~1-1.5h |
| B3 R5 + closeout | R5.5-5.8 4 测(多代飞升 + per-character 不串扰 + 红线守)+ closeout ≤80 行 + GDD §12.2 #11 v1.x 升档(P4.1 R5.6 占位 → 真 wire ✅)+ PROGRESS 顶段 + ROADMAP P4.1 1.1 挂账段更新 | ~1-2h |

## 6. 估时 + 风险 + 挂账

- **估时**:B1 1-1.5h + B2 1-1.5h + B3 1-2h = **~3-5h xhigh**(P4.1 1.1 挂账核心项 · 单 task 颗粒度)
- **风险**:① B2 stage_battle_setup per-character 循环 await isBuffActiveFor 性能(3 character × ~5ms isar query · 可接受 · 战斗前一次性算)② R5.1 P1.1 原红线测族跨 12+ test 文件回归(需逐个跑确认不破)③ playerSectIdProvider 在 Sect lazy-init 未触发时返 null(Q6A spec 同 race 风险 · 本 spec 兜底 fallback 单 founder isInSect=false 路径 OK)④ P5+ 多代飞升 isFounder rewire 与本扩兼容性(R5.6 守)
- **不变量沿用**:§5.4 红线不动 · §5.3 三系锁 · §6 公式不动 · numbers.yaml founder_ancestor_buff 段不动 · Isar schema 不动 · derived_stats 签名不变(参数语义保留) · `computeBuffActive` 旧 API 保留(向后兼容) · P5+ isFounder rewire 沿用
- **doc 体量**:本 spec ≤120 行 · B3 closeout ≤80 行 · PROGRESS 净增长 ≤ 0

---

**P4.1 1.1 founder_buff 跨派系扩 spec 收口(默认决议草案)**:Q1=A / Q2=A / Q3=A / Q4=A / Q5=A · B1-B3 拆 · ~3-5h xhigh · ⚠ 用户改 Q1-Q5 后改 §0 + §2-5 · 起 worktree `feat/p4_1_founder_buff_cross_sect` 走 B1
