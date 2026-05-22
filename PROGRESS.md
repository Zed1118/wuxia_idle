# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**2026-05-22 晚 §12.1 心魔系统 Phase 1 spec 起草拍板 + GDD v1.7 → v1.8 ✅ · 1.0 P2.2 子阶段启动**(Mac+Opus xhigh ~1h 接 Ch6 全收口后 · **2 commit `e666e4c` + `4558359` 全 push origin/main** · ROADMAP_1_0.md:110/200/247):
- **Phase 0 reality check**(`e666e4c` ~30min):5 维 grep — D1 突破 0 玩家主动(character_advancement_service.dart:30 自动 while-loop)/ D2 lib/features/inner_demon/ 新模块 / D3 EncounterType.trial 语义不合 / D4 BattleStrategy plug-in ready / D5 EncounterBiome 缺 innerRealm / D6 散功公式 ×0.5 参 / D7 RealmTier×RealmLayer 49 层 + **4 主轴用户拍板 B+B+A 微调+B** + Phase 0 doc 59 行
- **Phase 1 spec doc 起草**(`4558359` ~30min):148 行 spec doc + GDD v1.7→v1.8 — 7 关 unlock 矩阵(wuSheng 6 内部 + 1 飞升前置:qiMeng→ruMen→...→dengFeng → 飞升 A1 接管)+ 镜像 +10-20% 强加 §5.4 cap(HP ≤20k / 内力 ≤15k / 装备 ≤2k)+ 散功 ×0.5 阉割版失败惩罚(内力 ×0.85 / 主修修炼度 ×0.9 + 「心魔余毒」debuff 闭关 8h 清)+ StageType/EncounterBiome enum 各 +1 项 + numbers.yaml inner_demon 段 ~25 行 + lib/features/inner_demon/ 新模块(domain InnerDemonDef + application InnerDemonService + InnerDemonStrategy implements BattleStrategy + presentation InnerDemonScreen + BreakthroughBlocker)+ advancement_service unlock hook 2-3 行
- **数值红线 §5.4/§5.3/§6 不动** + Demo 49 层 EXP 自动升层路径完全不变(isLayerLocked 严格 wuSheng 短路)+ B 路线 0 contamination(Phase 0 codebase 0 心魔引用 verify)

**Phase 2+ 实装估时 ~7-8h opus xhigh**(Batch 2.1 schema → 2.2 strategy+service → 2.3 narrative ~3,500 字 → 2.4 doc → 2.5 R1-R5)。**1.0 进度 ~50% → ~52%**(P2.2 Phase 1 完成,Phase 2 占 P2.2 大头)。

**下波 候选**:① **P2.2 心魔 Phase 2+ 实装**(本批 spec 拍板后接续 ~7-8h opus xhigh)② MJ Discord 派单 Ch4-6 enemy ~20 张异步(Ch4 15 + Ch5 6 + Ch6 4-5)③ Codex Pen Windows 视觉验收 Ch4-6 主线 narrative(Pen ~1.5h)④ 用户精修 Ch6 narrative 补到 spec budget(可选 ~30-45min)

---

**2026-05-22 Ch6「飞升」Phase 2 全收口 ✅ + 复盘修补 ✅ · 1.0 P2 第二条主线全闭环**(Mac+Opus xhigh 3h 无人看管批 + ~1h 复盘修补 + 5min memory sink ≈ ~4h5min,**11 commit `15216a0` → `d00e039` 全 push origin/main** · Ch4+Ch5+Ch6 三章弧叙事完整):
- **Phase 0 + Phase 1**(`15216a0`+`5db61a8` ~1h):reality check 6 维 grep + spec doc 173 行 + GDD v1.5→v1.6 + 用户拍板 4 主轴(章名「飞升」/ zongShi 全章跨 wuSheng·qiMeng / 师父第三句完整联通 + 西凉霸主本人复出 / 末 Boss B 复合)
- **Batch 2.1+2.2 数值**(`f6379d7` ~45min):stages.yaml +5 entries(HP 30k→52k / Atk 2.0k→2.7k 跨阶 wuSheng·qiMeng)+ 末 Boss B 复合 + UI/test fixture 扩 6 章 30 关 + **schema 0 扩** + 1186→1191 pass
- **Batch 2.3.①+② narrative**(`ea8ea2d`+`486d39b` ~70min):13 文件 ~5,800 字 + chapter_06 章首尾 + defeat · **师父三句遗言第一次完整连成一句** + **无物之境收束**(四件物事并放青石不带走雪埋)+ 物理遗物三章 hook 全闭环
- **Batch 2.4 doc + 2.5 R5**(`3bb629e`+`2dea111` ~50min):GDD v1.6→v1.7 + ROADMAP P2.1 加 Ch6 + R5 跨阶 wuSheng 红线 50 种子双边断言一次过(1192 pass)
- **closeout v1 + handoff v1**(`e546b00` ~15min):100+65 行
- **复盘修补 6 项**(`d00e039` ~1h):用户提示「评估工作内容」后自查 7 项问题 + 立即修补 — chapter_06 玄妙词补(Tier 词 2/2/0/4 → 2/2/2/5) + epilogue 砍堆叠 + prologue/epilogue 对称(各 ~770 字) + R5 加 print 分布(**实测 1/0/49 = 98% 平局,Ch6 末关「拉锯偏向平局」格局**) + 普伤 spot check ~9 万接近 §5.4 上限 ⚠️ + spec 数值对齐实装 + closeout 100→72 ✅ + handoff 65→63(归 3 类决策)
- **memory sink 2 项**:`feedback_user_offline_autonomous` 加 Ch6 复盘 6 反例 + 6 教训 / `feedback_doc_inflation_overnight` 加 pattern bug 警示「连续超 +15-30% 不是 acceptable」+ 强制砍法 4 项

**1192 pass / 0 analyze ✅**(+5 Ch6 e2e + 1 R5)。**P2 第二条主线 100% ✅**(Ch4 + Ch5 + Ch6 三章弧全闭环)。**1.0 进度 ~42% → ~50%**。

**下波候选已被 P2.2 Phase 1 启动覆盖,见顶段下波候选**(原 ① 1.0 P3 起步 → P2.2 心魔 Phase 1 已实现,Phase 2 接续中)。

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

- **W12-W13 销账**(2026-05-14):#12 / #23 / #28 / #32
- **W4-W5 销账**(2026-05-13):#25 / #26 / #29
- **W3 销账**(2026-05-12):#27
- **W1-W2 销账**(2026-05-11):#22 / #24
- **Phase 1-2 销账**(2026-05-10/11):#1 / #5 / #13 / #14-15 / #16 / #19 / #20 / #21
- **W6 验证为伪挂账**:#18(项目无 web target)

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
