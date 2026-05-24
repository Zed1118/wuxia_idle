# P3.4 §12.1 门派事件 spec(默认决议版)

> 日期:2026-05-24 凌晨 / 模型:Mac + Opus 4.7 nightshift T04
> 上游 Phase 0:`docs/phase0/p3_4_sect_event_phase0_2026-05-24.md`
> 沿例:`docs/spec/p3_2_mass_battle_spec_2026-05-24.md`(P3.2 9 节体例)
> **Q1-Q5 默认决议**:Phase 0 各 Q 取 A 候选作 spec 占位 · 真定留 reviewer

---

## 1. 范围

### Q1-Q5 默认决议(spec 占位 · 真定见 Phase 0 §spec Q&A 候选清单)

| Q | 默认 | 取舍 |
|---|---|---|
| Q1 sect 粒度 | **A** 玩家自建门派 | 沿 `numbers.yaml:1107 sect_wide_buff` 已有锚点 · GDD:269 7 大门派典籍降级为 tag |
| Q2 sect_event 类型 | **A** 比武大会 | 单 event 类型 ship · PVP-lite 月度 cooldown · B 弟子任务 / C 门派危机 留 1.0 |
| Q3 reputation 关系 | **A** 独立 sect_reputation 轴(0-100) | 零 P1.2 依赖 · P3.4 可独立 ship |
| Q4 sect_building | **B** 否 · 纯抽象 sect_level int | 1-7 沿七阶 · 升级走比武胜场 · P4.1 帮派统一做建筑层 |
| Q5 与 P5+ 师徒整合 | **B** 独立 schema · `founderId` 弱挂 lineage | P3.4 不依赖 P5+ inheritance schema · 不强校验 |

### IN

- `Sect` / `SectEvent` Isar @Collection · `sectReputation` 嵌入 Sect · `SectEventService.checkAndTrigger`(月度 tick · cooldown + 境界 + 概率)
- `SectScreen` + `SectEventDialog`(挂 MainMenu 平级 `LineagePanelScreen`)· `data/lore/sect_event/tournament_<NN>.yaml` 5-8 条 + `numbers.yaml sect_event:` 段

### OUT

- Q2 B 弟子任务 / Q2 C 门派危机 → 1.0 · Q4 A 建筑层 UI → P4.1 · 多 sect 同存 / sect-vs-sect war → 1.0
- 战斗机制层(tournament 复用 default ground strategy · 不引入新数值轴)

## 2. schema

```dart
// lib/features/sect/domain/sect.dart(新建)· Sect 默认 name=「无名宗」· founderId 弱挂 LineageMember.id 不强校验
@Collection() class Sect {
  Id id = Isar.autoIncrement;
  late String name; late int founderId;
  late int sectLevel;      // 1-7 · Q4.B 抽象
  late int sectReputation; // 0-100 · Q3.A 独立轴
  late int totalWins;      // 累计 tournament 胜 · 驱动 level 升级
  late DateTime createdAt; DateTime? lastEventAt;  // cooldown 锚
}
@Collection() class SectEvent {
  Id id = Isar.autoIncrement;
  @Index(composite: [CompositeIndex('triggeredAt')]) late int sectId;
  @Enumerated(EnumType.name) late SectEventType type;     // tournament(Demo)· mission/crisis 留扩
  @Enumerated(EnumType.name) late SectEventStatus status; // pending / resolved / expired
  late DateTime triggeredAt; DateTime? resolvedAt;
  late String narrativeId;  // FK data/lore/sect_event/<id>.yaml
  int? reputationDelta;
}
enum SectEventType { tournament, mission, crisis }
enum SectEventStatus { pending, resolved, expired }
```

**composite index** `(sectId, triggeredAt)` 沿 P1.2 enmity / P2.x inner_demon 体例,支持「本 sect 时序」O(log n) 查询。

## 3. yaml 数值

```yaml
# data/numbers.yaml 尾部加段 · 避 sect_wide_buff 名冲突
sect_event:
  tournament:
    trigger_probability: 0.30        # 月触发概率
    cooldown_days: 30
    trigger_realm_min: yiLiu         # 沿 §5.3 三系锁死
    expire_days: 7                   # 7 天不应战 → expired + reputation -5
  reputation:
    initial: 50
    win_delta: 10
    loss_delta: -5
    decay_per_month_idle: 5          # 30 天无 event → -5/月
    max: 100
    min: 0
  sect_level:
    max: 7
    initial: 1
    promote_wins_threshold: 3        # 每累计 3 胜 → +1 sectLevel
  active_events_max: 3               # 同 sect 同时 pending 上限 · 防过载
```

## 4. 行为(SectEventService)

**触发链路**(月度 tick · 沿 `founder_buff_service` heartbeat 体例):

```
monthly tick → checkAndTrigger(sectId)
  ① (now - lastEventAt) < cooldown → skip
  ② player.realm < trigger_realm_min → skip
  ③ activeEvents(sectId).length ≥ active_events_max → skip
  ④ rand < trigger_probability → 创建 SectEvent(pending)
                                 → 随机选 data/lore/sect_event/tournament_*.yaml
                                 → 通知 UI(红点 + badge)
resolve(eventId, outcome)
  win:     reputation +10 · totalWins +=1 · if %3==0 → sectLevel +=1(clamp ≤7)
  loss:    reputation -5(clamp ≥0)
  expired: reputation -5 + status=expired
  → Sect.lastEventAt = now
SectReputationDecayService.tick(monthly)
  if (now - lastEventAt) ≥ 30d → reputation -= decay_per_month_idle
```

**关键 callsite**:`lib/core/game_loop/monthly_tick.dart`(新)→ `SectEventService.checkAndTrigger` · `lib/features/sect/application/{sect_event_service,sect_reputation_decay}.dart`(新) · `main_menu.dart` → SectScreen 入口

## 5. UI

- `lib/features/sect/presentation/sect_screen.dart`(新):顶 sect_name + sect_level + sect_reputation 进度条 / 中 active SectEvent list(pending 红点 + 应战 CTA)/ 底 history tab(resolved/expired)
- `SectEventDialog`(新):弹 narrative opening + 「应战」/「拒绝」按钮 · 应战 → default ground strategy → `resolve(outcome)`
- `main_menu.dart` 入口插序:Tower → InnerDemon → LightFoot → MassBattle → **Sect** → Lineage → Leaderboard

## 6. narrative

`data/lore/sect_event/tournament_01.yaml` 样本(Demo ship `tournament_01..08`):

```yaml
id: tournament_01
type: tournament
title: 群英会
opening: |
  江湖传檄,武林大会三日后在五台山开设。你接掌门派以来,声名渐起,
  今受邀赴会,与诸派高手切磋武艺,以扬本派声威。
choices:
  - { text: 应战赴会, outcome: accept }
  - { text: 闭门谢客(reputation -5), outcome: refuse }
victory_text: 群雄退避,你立于擂台中央。本派声威远播,弟子归心。
defeat_text: 败下阵来,心知技艺尚需精进。归山闭关三月,再图江湖。
```

文案沿 LightFoot ~2.1k 风格梯度词(粗豪 → 沉稳),第二人称「你」,黑名单同 Ch4-6。

## 7. 测试

- **R1 触发链路** 4 测:cooldown 满足 + 境界达标 → trigger / cooldown 未到 → skip / 境界不够 → skip / activeEvents ≥ max → skip
- **R2 联动** 5 测:win +10 / loss -5 / expired -5 / 3 连胜 → sectLevel +1 / 30 天无 event → -5 衰减
- **R3 narrative loader** 3 测:tournament_01..08 schema 校验 + id 唯一 + opening/victory/defeat 非空
- **R4 schema 红线** 4 测:sectLevel ∈ [1,7] / sectReputation ∈ [0,100] / composite index 命中 / tick = 系统时间 monotonic(不破 §5.5)
- **预期 baseline +12-15 test pass**

## 8. Batch 拆分(估时 ~6-8h opus xhigh · 沿 P2.2 心魔 2.1-2.5 节奏)

| Batch | 内容 | 估时 |
|---|---|---|
| 2.1 schema | `Sect` / `SectEvent` @Collection + enum + composite index + Isar 生成 + repo 解析 | ~1h |
| 2.2 yaml + service | `numbers.yaml sect_event` + `SectEventService` trigger/resolve + decay + monthly tick wire | ~2h |
| 2.3 战斗联动 | `SectEventDialog` + default ground strategy 复用 + outcome → reputation/sectLevel mutation | ~1.5h |
| 2.4 UI + narrative | `SectScreen` + main_menu 入口 + tournament_01..08 narrative + `UiStrings` | ~1.5h |
| 2.5 R1-R4 + doc | R1-R4 测族 + closeout + GDD §12.1.X 升档 + ROADMAP P3.4 段 + PROGRESS 顶段 | ~1h |

## 9. 风险

- **R1 数值红线**:tournament 复用 default ground strategy 不引入新数值轴 → §5.4 零碰 ✅;sectLevel 1-7 沿七阶 ✅
- **R2 触发链路死循环**:active_events_max=3 + cooldown=30d → 最坏 3 月 9 event pending · `expire_days: 7` 限 pending 堆积 → 不应战自动 expired
- **R3 与 P1.2 reputation 衰减撞**:Q3.A 独立轴 · 字段名 `sectReputation` ≠ P1.2 `reputation` · decay timer 独立 30 天 cycle
- **R4 与 P5+ 师徒耦合**:Q5.B 独立 schema · `founderId` 弱挂不强校验 · P3.4 可独立 ship · P5+ 飞升 attach 新 founder 留扩
- **R5 数据迁移**:旧档无 Sect 时 lazy-init(首入 yiLiu 境界 → 建 sect「无名宗」可改名)· 旧档兼容 ✅

---

**P3.4 spec(默认决议版)收口**:沿 P3.2 体例 + Q1-Q5 A 占位 + Batch 2.1-2.5 拆解 + 估时 6-8h xhigh · reviewer 真定后起 worktree `feat/p3_4_sect_event`。
