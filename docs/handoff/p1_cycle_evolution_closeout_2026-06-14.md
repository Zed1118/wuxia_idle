# P1 周目进化 · Closeout 2026-06-14

## 范围

主线 + 爬塔周目进化：通关后敌人进化、反制词条注入、per-cycle 进度追踪、选关屏周目选择 UI、红线压测。

## 合 main 状态

**未合 main**。分支：`worktree-p1-cycle-evolution`。阻塞项见「待拍板」。

## 闸门

- `flutter analyze` 0 error / 0 warning
- 全量 **2160 测** / 1 skip / 零回归
- 12 任务两阶段 review（控制方只读 diff + 全仓 analyze）全通
- saveVersion **0.21.0**

---

## 已交付内容（A-F1）

**A · Schema**：`MainlineProgress.clearedStageCycleKeys`(per-关-周目 key) + `recordVictory(cycle:)/highestClearedCycle/currentChallengeCycle`；`TowerProgress.currentCycleIndex/maxClearedCycle/advanceCycle`；saveVersion 0.20.0→0.21.0；迁移旧 clearedStageIds→#1 key / 塔 cycle1 基线。

**B · 敌人 Scale**：`numbers.yaml cycle_evolution`(scale_per_cycle=0.06 / max_cycle_mainline=3 / max_cycle_tower=2 / defense_rate_cap=0.6 / 5 词条参数)；`_enemyToBattle` hp/attack/IF ×(1+0.06×(cycle-1)) + 词条标签注入。

**C · 反制词条**：5 词条复用现有机制，确定性无新 rng：御体(defense↑ clamp≤0.6) / 真气(IF↑ clamp红线) / 识破(注入蓄力技) / 凝甲(defender暴击增量×0.5) / 反震(命中反弹内伤，复用 InternalInjurySlot)。

**D · 入口接周目**：`stage_entry_flow/_StageBattleHost` 加 `targetCycle`(默认1零回归)；battleKey/isCleared per-cycle；录制带 cycle；tower 读 `currentCycleIndex`。

**E · UI**：`CycleSelectControl`(三态)接 4 选关屏 cleared tile；`BattleScreen.cycleHint`(cycle≥2 显江湖记招琥珀提示)；爬塔「当前：第N轮回」+挑战下一轮回入口；验收 route `stage_list_cycle/tower_cycle` + Codex 派单。

**F1 · 红线压测**：`test/balance/cycle_evolution_redline_test.dart` 21 测；cycle scale 红线安全(合规 boss ×1.12 最高 44800/余量5200)；内力/御体 clamp 守线；词条不叠加确定性验证。

---

## 待拍板（合 main 阻塞项）

### 🔴 stage_06_05 西凉霸主 baseHp 超红线

- **现状**：`stages.yaml` stage_06_05 baseHp=**52,000**（pre-existing，P1 未改）
- **P1 放大**：cycle1=52,000 / cycle3=**58,240**——均超 §5.4 Boss 红线 50,000
- **选项 A**：降 baseHp ≤ 44,642（cycle3=44,642×1.12=50,000 刚好卡线）
- **选项 B**：调 GDD §5.4 / numbers.yaml 红线至 60,000（需同步 redline 测断言）
- **需用户拍板**（数值/规则层），拍板后合 main。

---

## 可选 future-proofing（非阻塞，记录不实装）

- `_enemyToBattle` 给 scaledHp 加 clamp（类比 IF/御体 clamp）：防未来 baseHp 44,643-50,000 的 boss 被 cycle3 静默推过线。需先把 `boss_hp_max` 入 `numbers.yaml red_lines`。当前无此 boss，不阻塞。
- 敌人 attack 在 stage_06 cycle3 peak 3,024 / tower floor30 cycle2 2,385，超 §5.4「2,000」；§5.4 注明的是玩家装备红线非敌人约束，记录待数值层确认是否需加敌人 attack 帽。
- `towerCycleReadyHint` 硬编「30 层」（可接受，塔层固定）；`advanceCycle` async fire-and-forget 无错误面（可接受）。

---

## 下一步

1. **Codex 视觉验收**：按派单 `docs/codex_dispatch_cycle_evolution_2026-06-14.md`（route `stage_list_cycle` / `tower_cycle`）
2. **用户拍板** stage_06_05 红线（选 A 或 B）
3. PASS + 拍板后 ff-only 合 main
4. 真玩验收：周目手感 + 词条战斗体验（首通手动→自动回放→二周目江湖记招触发流）
