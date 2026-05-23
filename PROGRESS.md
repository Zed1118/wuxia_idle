# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**2026-05-24 §12.3 轻功对决 P3.1.B 子批收尾 ✅ · 1.0 P3.1 完整闭环 · 1.0 整体 ~77%**(Mac+Opus high 累计 ~1h · spec 估 ~1.5h · 精度 0.67× · **4 commit squash merge ✅ → main HEAD `b1f9e4d`(PR #2 · 2026-05-24)**):
- **Batch A · damage_multiplier 接入**(`31bb7bf` ~35min):`BattleCharacter` +`attackPowerMultiplier:double` default=1.0 + copyWith + `default_ground_strategy._calculateInBattle` raw 末乘 atkPowerMult + breakdown 输出 + `LightFootStrategy._bake` 烘焙 `terrain.damageMultiplier` 到 attackPowerMultiplier(双方对等)+ R6 4 测(water 1.0 / rooftop 1.15 / bamboo 0.90 / 双方对等)
- **Batch B · 18 招 lightfoot 池 + stages 切换**(`ff2a0be` ~20min):`skills.yaml +18` 招 `skill_lightfoot_<tier>_<school>_<type>`(yiLiu 9 招 cap=3000 menpai 倍率 + jueDing 9 招 cap=4000 jianghu 倍率 · parentTechniqueDefId: null 沿 joint_skill 体例)+ `stage_light_foot_01..05` enemyTeam.skillIds 全切到新池(sed 35 次替换)+ repo_test baseline 104→122
- **架构发现**:`DamageCalculator` 用 `Character`(Isar 实体)是 phase1 公式参考,不参与战斗 — 实际战斗走 `default_ground_strategy._calculateInBattle` 用 `BattleCharacter`,attackPowerMultiplier 加在 BattleCharacter 上接入正确路径
- **R5.1 实测**:50/50/49/50/50 leftWins(bamboo stage_03 draws 4→1 · ×0.90 双方等比 → 玩家击杀更稳定 acceptable · 主导格局未变)
- **doc 收口**(本)~15min:GDD v1.11→v1.12 §12.3 升「P3.1.B 子批收尾 ✅」+ ROADMAP P3.1.B 详条 + `docs/handoff/p3_1_b_closeout_2026-05-24.md` 78 行 + 本顶段
- **挂账留 1.0 P3.2+**:Pen Windows 视觉验收 P3.1(Codex 异步 ~1h · 非阻塞)
- **1242 pass / 0 analyze ✅**(原 1238 + 4 R6 · skill 总数 64→82)。数值红线 §5.4/§5.3/§6 公式形态不变(attackPowerMultiplier 是 BattleCharacter view layer 字段 · 末端独立乘项)

---

**2026-05-23 夜 → 2026-05-24 晨 §12.3 轻功对决 P3.1 全收尾 ✅ · 1.0 P3 战斗形态扩展首条主线落地 · 1.0 整体 ~76%**(8h overnight worktree `feat/p3_1_lightfoot` · Mac+Opus xhigh 累计 ~5h · spec 估 ~9.5h · 精度 0.53× · **2026-05-24 晨 PR #1 squash merge ✅ → main HEAD `eb56480` · worktree clean · 本地 feat branch -D**):
- **战斗形态全闭环**(`5b00b96` ~1.5h):`LightFootStrategy` 组合委派 `DefaultGroundStrategy` 零代码重复 + `applyTerrainTo` 入口烘焙 terrain modifier 到 BattleCharacter critRate/evasionRate/defenseRate(clamp 0.0-0.95 防 §5.4/§5.5 红线破)+ `TerrainBiome` 独立 enum 3 项(water/rooftop/bamboo,与 EncounterBiome 解耦)
- **5 关 + schema**(`53b3741` ~50min):`stage_light_foot_01..05` yiLiu(qiMeng/jingTong/dengFeng)+ jueDing(qiMeng/jingTong)2 Tier × 3 terrain · diff 5.0-6.5 · numbers.yaml light_foot 段 45 行 · StageDef.terrainBiome 字段
- **narrative ~2.1k 字**(`796a879` ~50min):chapter_light_foot 章首尾(无名轻身术 5 处试炼)+ 10 stage opening/victory + Tier yiLiu「沉着/肃杀/老练」 / jueDing「沉静/从容」风格梯度词
- **UI 入口 + reactive 三态**(`caf3fa8` ~30min):LightFootScreen cleared/available/locked + LightFootService.statusOf + main_menu 入口 Tower → InnerDemon → **LightFoot** → Leaderboard + strings + main_menu_test 12→13
- **R5 跨地形红线 3 测**(`0b6a6da` ~30min):R5.1 5 关 × 50 种子分布(实测 50/50/46/50/50 leftWins · 平行支线主导)+ R5.2 clamp + §5.4 红线 + R5.3 unlock 链 e2e
- **doc 收口**(本)~30min:GDD v1.10→v1.11 §12.3 升「全收尾 ✅」+ ROADMAP P3.1 实装详条 + closeout 78 行 + PROGRESS 顶段
- **挂账 1.0 P3.2+**(3 项):damage_multiplier 接入 damage_calculator(P3.1.B ~30min)+ 轻功专属 skill yaml(P3.1.B ~45min)+ Pen Windows 视觉验收(Codex 异步 ~1h)
- **1238 pass / 0 analyze ✅**(原 1220 + 新 18:15 lightfoot 单测 + 3 R5)。数值红线 §5.4/§5.3/§6 公式不动 · Ch1-Ch6 主线 + Demo 49 层 + 心魔 7 关 wuSheng 突破链路径完全不变(轻功对决独立支线 · isLayerLocked 无 lightFoot 路径)

**下波 候选**:① ⭐ P3.2 群战守城起步(spec 估 3-4h + AI 协作接口扩展 · 升 xhigh)② P2.3 A1 飞升 + 遗物 transfer(P2 闭环 · ~4h+ · 升 xhigh)③ inner_demon 战斗机制层调优(P2.2 挂账 #2 · ~1.5h)④ Pen Windows 视觉验收 P3.1(Codex 异步 ~1h)⑤ MJ Discord 派单 Ch4-6 + inner_demon 7 enemy ~25 张(异步)

---

**2026-05-23 §12.1 心魔系统 Batch 2.1-2.5 全收尾 ✅ · 1.0 P2.2 子阶段闭环**(Mac+Opus xhigh 累计 ~5.25h · spec 估 ~7-8h · 精度 0.66× · **10 commit `e666e4c → b15d34d` 全 push origin/main** · 准备进 1.0 P3):
- **Batch 2.5.B + 2.5.C**(`b15d34d` ~45min):① UI reactive 三态(InnerDemonScreen `mainlineProgressProvider` + `clearedStageIds` + `unlockTriggers` reverse 链 → cleared/available/locked + main_menu _MenuButton 入口 Tower 后 Leaderboard 前)② **inner_demon_07 决议**:R5.1 数据印证 `_07 +20%` 同 `_06 +20%` 完全同分布(3/0/47),改 +40% 单副本 YAGNI 不动 6v3 架构 ③ **cap 维度纠正**:`mirror_caps.attack_power_max 2000 → 6000` 纠 §5.4 维度(单件 vs 3 件求和)④ 1220 pass / 0 analyze ✅
- **P2.2 final closeout**(本)~25min:GDD v1.9 → v1.10 + ROADMAP P2.2 final 段 + `docs/handoff/p2_x_inner_demon_final_closeout_2026-05-23.md` 80 行 + 本顶段
- **挂账 1.0 P3+**(3 项):BreakthroughBlocker 集成 character_panel(1257 行 ~30-45min 推 P3+)+ inner_demon 战斗机制层调优(R5.1 实测数值层 buff 单维度调整不影响战斗结果)+ inner_demon 7 主题 enemy 立绘异步 MJ
- **1.0 整体 ~70%**(P2.2 子阶段闭环 + Ch4/5/6 主线全闭环 + 心魔系统 7 关接管 wuSheng 突破链 + UI 入口可达)

---

**2026-05-22 晚 §12.1 心魔系统 P2.2 Phase 1+2 历史段归档**:Phase 0 reality check + Phase 1 spec doc + Batch 2.1-2.4 全 7 commit `e666e4c → 86d55fc` 已被 P2.2 Batch 2.5 final 段(上)汇总。详 `docs/handoff/p2_x_inner_demon_phase1_closeout_2026-05-22.md`。

---

**2026-05-22 Ch6「飞升」Phase 2 全收口 ✅ + 复盘修补 ✅ · 1.0 P2 第二条主线全闭环**(~4h5min · 11 commit `15216a0 → d00e039` 全 push origin/main · 三章弧 Ch4+Ch5+Ch6 叙事完整):13 文件 ~5,800 字 + chapter_06 飞升 + 师父三句遗言第一次完整连成 + 无物之境收束 + R5 跨阶 wuSheng 红线一次过 + 复盘 6 项修补(epilogue 对称 / 普伤 ~9 万 spot check / closeout 100→72)。详 `docs/handoff/p2_x_chapter6_ascension_phase2_closeout_2026-05-22.md` + memory sink `feedback_user_offline_autonomous` / `feedback_doc_inflation_overnight`。**1.0 进度 ~42% → ~50%**。

**2026-05-21/22 历史段归档**(M4 美术 Stage 3 BOSS 22 张闭环 + Ch4 Phase 2.1-2.5 全收口 + 8h overnight + 审查修补 + 3h 托管):详 commit `319e15d` → `f6b0894` 范围 + handoff `art_stage3_boss_closeout` / `p1_x_chapter4_phase2_full_closeout_2026-05-22.md` / `8h_autonomous_handoff_2026-05-22.md` / `3h_managed_handoff_2026-05-22.md`。

**P1.1 全收口 ✅**(候选 1+2+3+4 实装 + 候选 5 文档对齐 + 候选 6 audit 复跑)。详条已迁末尾「### P1.1 候选 1-5 详条迁出 2026-05-21」段。

> 归档段「### M4 #46 美术详条迁出 2026-05-20/21」+「### W17-W18 详条迁出 2026-05-19/20」+ `docs/handoff/` 各 closeout。

## 已完成(近 W6 起,早期归档见末尾)

> W15 主战场详条 20 段 + W17-W18 详条 11 段均已归档,详末尾「### W14-W15 详条迁出」+「### W17-W18 详条迁出 2026-05-19」段。

## 已知偏差 / 挂账事项

- ~~37 / 38 / 40 / 41 / 42 / 43 / 44 / 45 全销账~~(2026-05-17/18/19/20):#37 详 `p1_37_orphan_decree_2026-05-19.md`;#38/40/41/42 详末尾 W17-W18 详条段;#43 详 `p1_43_higher_tier_closeout_2026-05-19.md`;#44 详 `p1_44_mac_takeover_closeout_2026-05-19.md`;#45 详顶段 + `p1_45_demo_polish_closeout_2026-05-20.md`

> 已销账条目(#1-#45)详见末尾归档。**P1 阶段全销账 ✅** + **Demo §8.4 14/14 全达标 ✅**(2026-05-20 #45 收尾)。

## 关键约束(每次开局必读)

- 数值红线:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000(GDD §5.2)
- 不硬编码数值/文案(走 numbers.yaml / data/narratives, lore, events)
- Riverpod 状态管理;Isar 本地存储;data/ asset 根
- 不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md(DeepSeek 领地)
- Mac 端写 lib/、data/*.yaml(顶层)、test/;DeepSeek 写 data/narratives/、data/lore/、data/events/

## 远程仓库

- GitHub:https://github.com/Zed1118/wuxia_idle · 主分支 main
- 双端协作:Mac+Opus 写代码与数值;Windows+DeepSeek 写文案;Codex 桌面 @ Pen 跑视觉验收

## 归档

### 已解决挂账(逆时序)

- **Phase 1-2 + W1-W13 全销账**(2026-05-10..14):#1/5/12-16/19-29/32(逐周详 git log)+ #18 验证为伪挂账(项目无 web target)

### Phase 1-4 早期详条已迁出

- Phase 1-3 + W4-W11:`phase{1,2,3}_summary.md` + git log + tags `v0.1.0-phase1` / `v0.3.0-w11`
- W14-W15 详条迁出(2026-05-15/17)+ Phase 5 #2/#3 销账详条:git log + handoff/各 closeout

### W17-W18 详条迁出 2026-05-19/20

13 段销账(P1 #42 Phase 1+P1.x+P1.y+P1.z+P2 扩段 / P1 #43 高阶占位 / P1 #44 协作 v1.8 切单端 / Nightshift 9 task / P0 4 段 / P0.1 #38 maxHp 重平衡 / 外部审查 + 6 项 / 1.0 路线图 launched / W18-A1.2 hot-loop / W18-A1 Codex 视觉)。详 git log + handoff/`p1_42_*` / `p1_43_higher_tier_closeout_2026-05-19.md` / `p1_44_mac_takeover_closeout_2026-05-19.md` / `nightshift_20260519_handoff.md` / `p0_38_maxhp_rebalance_closeout_2026-05-17.md` 等 11 closeout。

### P1.1 候选 1-5 详条迁出 2026-05-21

5 候选全收口(4 实装 + 1 文档对齐):候选 1 收徒池 E.1 / 候选 2 祖师爷 sect_wide_buff / 候选 3 共鸣度 4 子任务 + joint_skill / 候选 4 开锋 build / 候选 5 CLAUDE.md §12 表述对齐 — git log + handoff/`p1_1_*_closeout_2026-05-21.md` 5 closeout。

### M4 #46 美术 + Ch4 Phase 2 详条迁出 2026-05-20/22

- **M4 #46 美术** 5 段(2026-05-20/21):Stage 2 W1-W6 量产 74/74 + assets 89 张归位 + stage_audit + 候选 1 round 1 视觉验收 + #45 Demo §8.4 polish · 详 `art_poc_stage{0,1,1_5,2}_*_2026-05-20.md` + `art_assets_integration_*_2026-05-20.md` + `p1_45_demo_polish_closeout_2026-05-20.md`
- **Ch4 1.0 P2 第二条主线第 1 章**(2026-05-21/22):Phase 2.1 → 2.5 全收口 9 commit + 13 narrative ~5,880 字 + R5 跨阶红线压测 + GDD v1.3 / ROADMAP / PROGRESS · 详 `p1_x_chapter4_phase2_full_closeout_2026-05-22.md` + `p1_x_chapter4_phase2_batch1_closeout_2026-05-21.md` + `p1_x_chapter4_spec_2026-05-21.md` + `p1_x_chapter4_phase0_reality_check_2026-05-21.md`

详 git log + handoff/各 closeout。
