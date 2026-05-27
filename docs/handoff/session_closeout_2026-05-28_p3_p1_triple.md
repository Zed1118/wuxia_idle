# Session Closeout · 2026-05-28 P3.2.B + P1.2 + P3.x 三项实装

## commit 链(3 commit on main `8b7f9fc → d4757ac`)

| commit | 内容 |
|---|---|
| `8b7f9fc` | P3.2.B 群战数值调优 · `aliveIfRecoveryPct=0.50` |
| `a6f3e14` | P1.2 Boss 击杀声望 wire + factions.yaml 加载 |
| `d4757ac` | P3.x 群战 UI wiring · MassBattleStrategy 接入 |

测族:1508 → 1514(+6 R5.8 Boss 击杀声望)· 0 analyze

## 1. P3.2.B 群战数值调优

**根因**:`preserve_internal_force=true` + 无 IF 恢复 → wave 3+ 内力耗尽 → maxTicks 超时全 draw

**修法**:沿 `aliveHpRecoveryPct` 体例加 `aliveIfRecoveryPct`(3 文件):
- `mass_battle_def.dart`:加 `aliveIfRecoveryPct` 字段 + ctor + defaults(0.50) + yaml 解析
- `numbers.yaml`:加 `alive_if_recovery_pct: 0.50`
- `mass_battle_strategy.dart`:`_intermission` 加 IF 恢复(取 max 不降)

**分布**:01 50W/0D · 02 50W/0D · 03 37W/13R · 04 45W/5R · 05 30W/20R

## 2. P1.2 Boss 击杀声望 wire

**发现**:encounter → reputation 已完整 wire(Phase 0 确认)· 只缺 stage boss kill 路径

**改动**(4 文件):
- `stage_def.dart`:加 `factionId: String?`
- `stages.yaml`:6 主线 Boss 配 factionId(Ch1 shaolin/Ch2 jiaoMen/Ch3 wudang/Ch4 cijianzhuang/Ch5 emei/Ch6 luLin)
- `game_repository.dart`:加载 factions.yaml → `factionAlignments` map + `rivalFactionIds` helper(orthodox↔evil rival · neutral 无)
- `stage_entry_flow.dart`:victory 末段 `_applyBossKillReputation`(boss 派 -5 · rival 派各 +3)

**R5.8 测族 6 测**:faction 覆盖 / rival orthodox→evil / rival evil→orthodox / neutral 空 / e2e delta / factionAlignments 6 门派

## 3. P3.x 群战 UI wiring

**核心缺失**:MassBattleStrategy 从未被实例化 · stage_entry_flow 群战走 fallback DefaultGround 3v3

**改动**(3 文件):
- `stage_battle_setup.dart`:加 `buildEnemyTeamsPerWave` 静态方法(模板循环 + characterId -10000 递减)+ `_enemyToBattle` 加 `characterIdOverride`
- `stage_entry_flow.dart`:massBattle 分支(在 lightFoot 前检查)+ `_pickFormation` dialog + `_FormationPickerDialog` widget(雁行/八卦/锋矢 3 选)
- `strings.dart`:7 段阵型文案

## Phase 0 副产:P3 技术债 + P1.2 B3+B4 已完成确认

会话初始排查发现 ROADMAP T19 FAIL 记录过时:
- P3 技术债 3 项(PvpDef/SectEventDef 强类型 + Isar 持久化 + systemClockProvider)全已实装
- P1.2 江湖恩怨 B3 UI + B4 R5 全已实装(44 测 · main_menu wire)

## 下波候选

| # | 任务 | effort |
|---|---|---|
| 1 | 内容扩充(装备 35→80 / 心法 21→50) | xhigh |
| 2 | RELEASE_CHECKLIST / ROADMAP 状态对齐 | high |
| 3 | Codex R2 视觉验收(Pen 开机后) | — |
