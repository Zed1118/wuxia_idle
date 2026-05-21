# P1.1 A1 E.5 祖师爷 buff closeout(2026-05-21 四段)

> **会话总览**:2026-05-21 主对话四段(候选 1 收徒 closeout 后续)· Mac opus xhigh ~1.5h · 1.0 路线图 P1.1 系统纵深第 2 项 A1 E.5 founder_ancestor_buff 完整闭环
>
> **HEAD**:`<本会话 commit 后填>` → 待 push origin/main
> **测试基线**:1139 → **1147 pass**(净 +8)+ 1 skip + 0 fail / analyze 0 issues
> **PROGRESS.md**:95 行(在 100 cap 内)
> **saveVersion**:0.12.0(不动,无 SaveData schema 变化)

---

## §1 会话段 D · 候选 2 实装

### 1.1 Phase 0 reality check
- 维度 A schema:`founder_ancestor_buff` 仅 numbers.yaml 2 占位字段 + lib/ **0 命中** 代码引用
- 维度 B caller:`sectWideBuff` / `ancestorBuff` / `FounderAncestor` 全仓 0 命中
- 维度 C 邻近目录:`lib/features/inheritance/` 不存在(全新建)
- 维度 D UI:无 buff 显示

**判定**:**0→1 全新落地**(比候选 1 还干净,候选 1 schema 50% 已铺,候选 2 完全 0)。

### 1.2 设计决议
- **E.5.A 方案**(用户拍板):`enabled_when_alive: false → true`,玩家本人=祖师即享 buff
- GDD §7.1「玩家是开派祖师」直译;CLAUDE.md §12.2 #11 v1.5「Demo 不实装,1.0 版本再设计」对应 P1.1 阶段激活
- buff 数值:internal_force_max_pct=0.05 / max_hp_pct=0.05 / crit_rate_bonus=0.02 / cultivation_progress_pct=0.03
- 作用域:`apply_to_disciples_only=false`,active 中 founder 自身也享(玩家=祖师)
- 触发条件(P1.1 简化):active 中存在 `isFounder=true` + yaml `enabled_when_alive=true` → buff 激活

### 1.3 实装(新 3 文件 + 改 8 文件 + 加 8 test)

**新 3 文件**:
1. `lib/features/inheritance/application/founder_buff_service.dart`(50 行):`FounderBuffService.computeBuffActive` 判 active 是否含 founder + buff yaml 是否启用
2. `lib/features/inheritance/application/founder_buff_providers.dart`(28 行):`founderBuffActiveProvider`(async)+ `recruitmentService` 体例对齐
3. `test/features/inheritance/application/founder_buff_service_test.dart`(160 行):8 test

**改 8 文件**:
1. `data/numbers.yaml`:`founder_ancestor_buff` 段 flip + 数值填实(行 1097-1110 新增 4 子字段)
2. `lib/data/numbers_config.dart`:新 `FounderAncestorBuff` class(80+ 行)+ NumbersConfig 加 `founderAncestorBuff` 字段 + load
3. `lib/features/battle/domain/derived_stats.dart`:`maxHp` / `internalForceMaxWithLineage` / `criticalRate` 各加可选 `founderBuffActive: bool = false` 参数 + `_founderBuffAppliesTo` 私有 helper
4. `lib/features/battle/domain/battle_state.dart`:`BattleCharacter.fromCharacter` 加 `founderBuffActive` 参数 + 传给 derived_stats 各方法
5. `lib/features/battle/application/stage_battle_setup.dart`:`_buildPlayerTeam` 算 `founderBuffActive`(active 含 founder + yaml isActive)+ 传给 `_playerToBattle`
6. `lib/features/character_panel/presentation/character_panel_screen.dart`:UI 显示用 `ref.watch(founderBuffActiveProvider).maybeWhen` 拿 active state 传给 derived_stats(loading 默认 false)
7. `lib/features/character_panel/presentation/lineage_panel_screen.dart`:加 `_FounderBuffSection`(摆台 4 行 buff 数值显示 + subtitle)
8. `lib/shared/strings.dart`:加 6 条 lineagePanelFounderBuff* 文案

### 1.4 Test +8 全 pass(1139 → 1147)

| 维度 | test 数 | 内容 |
|---|---|---|
| FounderAncestorBuff schema | 3 | 生产 yaml 加载值校验 / disabled 兜底 / sect_wide_buff: null 兜底 |
| 数值红线说明 | 1 | 4 件 lineage + founder 叠加上限 18900(说明性,clamp 在公式层) |
| FounderBuffService.computeBuffActive | 4 | SaveData 未初始化 / active 含 founder / active 仅 disciple / disabled 兜底 |

**回归 test 修复**(2 处):
- `test/features/battle/application/master_disciple_battle_test.dart`:`祖师 maxInternalForce` 期望值 `baseIfMax × 1.10` → `baseIfMax × 1.155`(lineage +10% × founder +5%)+ 注释更新
- `test/features/battle/application/stage_battle_setup_test.dart`:`Codex 视觉验收 A:B:C maxHp ratio`:6360 → 6678 / 5300 → 5565(各 ×1.05 founder buff),A:B = 1.20 比例不变

---

## §2 关键设计点

### 2.1 buff 应用语义
```
isFounderBuffApplies(c, buff):
  if not buff.isActive:                      return false
  if buff.applyToDisciplesOnly and c.isFounder: return false
  return true
```

P1.1 决议 `applyToDisciplesOnly=false`,即 founder 也享 buff。Phase 5+ 飞升后改为 true(祖师自己已飞升退出 active,不应再享自己的 buff)。

### 2.2 derived_stats 接 buff 体例

| stat | 公式 | buff 注入 |
|---|---|---|
| internalForceMaxWithLineage | base × (1 + heritageCount × 0.05) | × (1 + founder.internalForceMaxPct) |
| maxHp | base + IF × 0.5 + cons × 400 + ΣEqHp | × (1 + founder.maxHpPct) |
| criticalRate | base + agility × perPt + (lingQiao 的话 + 0.20) | + founder.critRateBonus (clamp 前) |

cultivation_progress_pct 暂未接入公式(本批 yaml 占位 + NumbersConfig 字段,留 Phase 5+ 修炼度路径接入)。

### 2.3 fixture 兜底
fixture loader 走 `File(path)` fallback 加载真实 numbers.yaml → 自动拿真实 founder_ancestor_buff 数值。`FounderAncestorBuff.disabled` 静态常量供 stub 测试用。**`NumbersConfigStub`** 是 test-only helper(`noSuchMethod` 兜底)。

### 2.4 P1.1 简化 vs Phase 5+
- **P1.1 简化**:`enabled_when_alive=true` + 玩家=祖师自享 buff
- **Phase 5+ 飞升**:`enabled_when_alive=false`(原 Demo 决议) + 飞升后前任 founder 退 active → buff 作用于新 active(大弟子继承祖师位 + 二弟子/玩家创角的新二弟子);需扩 trigger 条件(`founder.realm >= wuSheng` AND `not in active`)

本批 `FounderBuffService.computeBuffActive` + `FounderAncestorBuff.isActive` 留扩展点,Phase 5+ 切换 trigger 时改 service + yaml 字段语义即可。

---

## §3 commit 链(本会话候选 2)

| # | SHA | 描述 |
|---|---|---|
| 1 | 即将创建 | feat(inheritance): P1.1 A1 E.5 祖师爷 buff · E.5.A 玩家=祖师直挂 buff |

---

## §4 待决 ops / 挂账

1. **本会话产物 commit + push**:候选 2 = 11 改/新文件 + 8 test + 2 test 期望值修复 + closeout
2. **挂账**:cultivation_progress_pct buff 公式接入(留 Phase 5+ 修炼度路径成熟时一起做);damage_calculator(test-only,生产用 BattleCharacter 缓存)不动 critRate 直接调用
3. **下波**:候选 3 A3 共鸣度满级体验完整化(joint_skill 表现层 + banner 时机 + 拆分提示 UI,opus xhigh 2-4h)

---

## §5 教训 sink

| # | 教训 | memory 落点 |
|---|---|---|
| 1 | derived_stats 公式加可选参数 `{...:false}` 不破现有 caller,渐进接入 buff | 未独立 sink |
| 2 | red line test 期望值更新时同步加 reason 注释「(lineage +10% × founder +5%)」防再 regression 难定位 | `feedback_red_line_test_semantics`(已有,本次又一锚点)|
| 3 | NumbersConfigStub + noSuchMethod 兜底 test-only 路径,避免 mock 真实 yaml load | 未独立 sink(实战 ≥3 次再总结)|

---

**closeout 完结**。本会话候选 2 A1 E.5 祖师爷 buff 一波闭环。1.0 路线图 P1.1 第 2 项 ✅,下波候选 3 A3 共鸣度推进 P1.1 收口路径。
