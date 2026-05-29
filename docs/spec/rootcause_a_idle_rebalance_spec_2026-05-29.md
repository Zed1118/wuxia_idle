# 根因A 挂机循环重平衡 spec(2026-05-29 · xhigh)

> 出处:`h2_midgame_audit_2026-05-29.md` 根因A「挂机循环与中期成长脱节」。
> 用户拍 3 数值方向(2026-05-29):①共鸣度双管 ②闭关 EXP ×2.5 ③insightPoints 轻量兑换 sink。
> 数值方向锁定,具体数字本 spec 拍(CLAUDE.md 授权实现细节自主),实装中 R5 + simulator 验。

## 现状量化(grep 实测锚点)

- 共鸣度:趁手 [100,500]×1.10 / 默契 [500,2000]×1.20 解锁人剑合一(`numbers.yaml:528+`)· battleCount 仅实战 +1(`battle_resolution.dart:136`)· **idle 0 喂**
- 闭关 EXP:中期 erLiu 70/h · 藏经阁 sanLiu 90/h · 72h≈8.4k EXP≈1.4 Ch3 Boss(6000/Boss)
- 闭关产 `techniqueLearnPoints`→写 `Character.insightPoints`(`seclusion_service:342`)→ `TechniqueLearningService.learn()` 有骨架但 **0 caller+0 UI** = 死钱包
- 修炼度 progress:仅实战 skillUsageCount 喂(`cultivation_service.recordSkillUsage`)· 每层阈值 100/250/500/900/...(`numbers.yaml:669-685`)

## B1 — 共鸣度双管(schema wire + 阈值)

- **阈值下调**:`numbers.yaml resonance.stages` moQi `[500,2000]→[300,2000]` · chenShou `[100,500]→[100,300]`(默契 500→300,趁手起点 100 不变)
- **闭关喂 battleCount**:新 `numbers.yaml resonance.seclusion_battle_count_per_hour: 5`(挂机折算,明显低于实战 ~30-50/h,保「实战为主」)
  - `NumbersConfig` ResonanceConfig 加 `seclusionBattleCountPerHour` 解析
  - wire `seclusion_service.completeRetreat` writeTxn 内(`ch != null` 块):`gain = floor(actualHours × rate)`,加到角色 3 件出战装备(`equippedWeaponId/ArmorId/AccessoryId`)的 `Equipment.battleCount`,put 回
  - 数值:72h × 5 = +360 > 默契 300 → 纯挂机也可达人剑合一 · 8h挂机 = +40(可观推进)
- R5:闭关 N 小时 → 出战装备 battleCount += floor(N×5) · 阈值 300 反映(resonance stage 推进)

## B2 — 闭关 EXP ×2.5(纯 numbers)

- `numbers.yaml retreat.maps[*].base_outputs.experience_per_hour` ×2.5:
  - 100→250(xueTu) · 80→200(sanLiu) · 90→225(藏经阁) · 70→175(erLiu) · 200→500(zongShi)
- 验证:erLiu(scale 1.69)72h = 175×72×1.69 ≈ 21,300 ≈ 3.5 Boss ✓ · 藏经阁(1.3)72h ≈ 21,060 ≈ 3.5 Boss ✓
- R5:computeOutputs EXP 反映新值 + 72h erLiu ∈ [3,4]×6000 区间断言

## B3 — insightPoints 轻量兑换 sink(service + UI + numbers)

- **机制**:玩家花 insightPoints 凝练主修修炼度。闭关挂机→insightPoints→玩家凝练→修炼度,死钱包变 idle→中期成长链路(不开学心法 UI,维持 GDD §7.2 Phase 5+ scoped)
- `numbers.yaml cultivation.insight_to_cultivation_ratio: 1.0`(1 insightPoint → 1 progress · 72h闭关 ~70-91 → ~0.9 早期层)
- 新 `InsightExchangeService.refine({character, mainTech, insightSpend})`:校验(有主修 / insightPoints 足) → `delta = floor(insightSpend × ratio)` → 复用 `CultivationService.recordSkillUsage(tech, delta)` 升层 → 扣 `ch.insightPoints` → writeTxn put · 返回 result enum(success/noMainTech/insufficient)
- UI:`technique_panel_screen` 主修 technique 加「凝练领悟」按钮 → dialog 选消费量(全部/自定义)→ SnackBar 反馈 · UiStrings 段
- R5:凝练 → 主修 progress↑ + insightPoints↓ · 不足守卫 · 无主修守卫 · 升层正确

## 批次 + verify

- B1 → B2 → B3 顺序(B3 依赖 cultivation_service 复用)· 每批 TDD 红绿 + 全量回归
- 全量 baseline 1540 · 0 analyze · R5 新增 ~10-12 测
- numbers.yaml 改 3 段(resonance/retreat/cultivation)· 红线不破(§5.4 不涉及战斗数值)
