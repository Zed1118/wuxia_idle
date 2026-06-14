# P1 周目进化 · Closeout 2026-06-14

## 范围

主线 + 爬塔周目进化：通关后敌人进化、反制词条注入、per-cycle 进度追踪、选关屏周目选择 UI、红线压测。

## 合 main 状态

**未合 main**。分支：`worktree-p1-cycle-evolution`。**stage_06_05 红线已拍板(选项 B,见下)** → 唯一剩余阻塞 = Codex 视觉验收;PASS 后 ff-only 合 main。

## 闸门

- `flutter analyze` 0 error / 0 warning
- 全量 **2169 测** / 1 skip / 零回归（+4 对抗审计补测：凝甲 in-battle e2e / §7 真 clamp 路径 ×2 / advanceCycle cap）
- 12 任务两阶段 review + **整条分支最终 opus review** 全通
- saveVersion **0.21.0**

> **最终 review 修复(052869c3)**:opus 整体 review 抓到 per-task review 全漏的 bug —— **识破词条原为死机制**(`_enemyToBattle` 注入 chargeSkillId 但未加进 `availableSkills`,BattleAI 选不到→永不蓄力)。已修(识破注入时真接入 availableSkills)+ 加战斗 e2e 测(`shipo_charge_live_test` T3 真证 `chargingSkill != null`)。另修爬塔 cycle≥2 漏传 cycleHint + 真气 yaml 注释 drift。5 词条现全部生效。

---

## 已交付内容（A-F1）

**A · Schema**：`MainlineProgress.clearedStageCycleKeys`(per-关-周目 key) + `recordVictory(cycle:)/highestClearedCycle/currentChallengeCycle`；`TowerProgress.currentCycleIndex/maxClearedCycle/advanceCycle`；saveVersion 0.20.0→0.21.0；迁移旧 clearedStageIds→#1 key / 塔 cycle1 基线。

**B · 敌人 Scale**：`numbers.yaml cycle_evolution`(scale_per_cycle=0.06 / max_cycle_mainline=3 / max_cycle_tower=2 / defense_rate_cap=0.6 / 5 词条参数)；`_enemyToBattle` hp/attack/IF ×(1+0.06×(cycle-1)) + 词条标签注入。

**C · 反制词条**：5 词条复用现有机制，确定性无新 rng：御体(defense↑ clamp≤0.6) / 真气(IF↑ clamp红线) / 识破(注入蓄力技) / 凝甲(defender暴击增量×0.5) / 反震(命中反弹内伤，复用 InternalInjurySlot)。

**D · 入口接周目**：`stage_entry_flow/_StageBattleHost` 加 `targetCycle`(默认1零回归)；battleKey/isCleared per-cycle；录制带 cycle；tower 读 `currentCycleIndex`。

**E · UI**：`CycleSelectControl`(三态)接 4 选关屏 cleared tile；`BattleScreen.cycleHint`(cycle≥2 显江湖记招琥珀提示)；爬塔「当前：第N轮回」+挑战下一轮回入口；验收 route `stage_list_cycle/tower_cycle` + Codex 派单。

**F1 · 红线压测**：`test/balance/cycle_evolution_redline_test.dart` 23 测（对抗审计补 §7 真生产路径 clamp 测 + 凝甲 in-battle e2e + advanceCycle maxCycleTower cap）；cycle scale 红线安全；§7 scaledHp clamp 分支已由 `debugEnemyToBattle(baseHp=58000, cycle3)→maxHp=60000` 真路径证明（非数学重演）；内力/御体 clamp 守线。

---

## 已拍板(原合 main 阻塞,已解除)

### ✅ stage_06_05 红线 → 选项 B 已实装(`9576b048`)

用户 2026-06-14 拍板**选项 B**:Boss HP 红线 50,000→**60,000**(接受终局周目膨胀)。已实装:numbers.yaml `boss_hp_max:60000`(config 化) + `_enemyToBattle` scaledHp clamp(防越线,真生产路径测覆盖) + GDD §5.2/§5.4 + CLAUDE.md §5.4 同步 + 压测改 config 驱动并 hard-assert stage_06_05(cycle3=58,240 < 60,000 ✅)。stage_06_05 baseHp=52,000 不动(选 B 非 A)。

<details><summary>原待拍板记录(已解除)</summary>

- **现状**：`stages.yaml` stage_06_05 baseHp=**52,000**（pre-existing，P1 未改）
- **P1 放大**：cycle1=52,000 / cycle3=**58,240**——均超 §5.4 Boss 红线 50,000
- **选项 A**：降 baseHp ≤ 44,642（cycle3=44,642×1.12=50,000 刚好卡线）
- **选项 B**：调 GDD §5.4 / numbers.yaml 红线至 60,000（需同步 redline 测断言）
- **需用户拍板**（数值/规则层），拍板后合 main。 → **已拍板 B,见上。**

</details>

---

## 可选 future-proofing（非阻塞，记录不实装）

- ~~`_enemyToBattle` 给 scaledHp 加 clamp~~：**已实装**（对抗审计 Fix 2）。scaledHp clamp 已在代码中并由 §7 两个生产路径测试覆盖（Fix 2 关闭）。
- 敌人 attack 在 stage_06 cycle3 peak 3,024 / tower floor30 cycle2 2,385，超 §5.4「2,000」；§5.4 注明的是玩家装备红线非敌人约束，记录待数值层确认是否需加敌人 attack 帽。
- `towerCycleReadyHint` 硬编「30 层」（可接受，塔层固定）；`advanceCycle` async fire-and-forget 无错误面（可接受）。

---

## 下一步

1. **Codex 视觉验收**：按派单 `docs/codex_dispatch_cycle_evolution_2026-06-14.md`（route `stage_list_cycle` / `tower_cycle`）
2. **用户拍板** stage_06_05 红线（选 A 或 B）
3. PASS + 拍板后 ff-only 合 main
4. 真玩验收：周目手感 + 词条战斗体验（首通手动→自动回放→二周目江湖记招触发流）
