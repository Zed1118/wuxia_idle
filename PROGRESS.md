# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**2026-05-21 晚 候选 1 M4 美术 Stage 3 · BOSS 题材 22 张闭环 ✅**(Mac opus xhigh ~3h,4 commit `319e15d` + `f14ba0c` + `7ada9b8` + `e6d5806`):用户拍板二选一 → 候选 1 美术 Stage 3 优先(BOSS + 场景 + 心法卷轴 3 题材,~50 张轻收口,BOSS 优先)。Phase 0 reality check 核心发现 ⭐:character_avatar.dart 占位 widget 改造 1 处 = 60+ enemy iconPath sleeper schema 一次性激活(stages + towers yaml 早锚 + StageDef.iconPath 早 parse 但 widget 没消费)。Phase 1 三 widget 全接入(character_avatar / battle_screen Stack 背景 / technique_panel tier banner)+ 5 def schema 加可空字段。**MJ 出图 22/22** = v1 旧违规版 7 张过 → 触发 Moderator manual review(锁 ~5h)→ v5 合规版 14 张全过 → v6.1 thug_a 老者意境加固 1 张重抽。towers.yaml 6 BOSS iconPath 撞名(F15-30 全占位 wulin_bazhu.png)sed 精确改 6 行 → tower_boss_<floor>.png。1172 pass / 0 analyze 全程不破。详 [`art_stage3_boss_closeout_2026-05-21.md`](docs/handoff/art_stage3_boss_closeout_2026-05-21.md) + Phase 0 [`art_stage3_phase0_reality_check_2026-05-21.md`](docs/handoff/art_stage3_phase0_reality_check_2026-05-21.md)。memory sink:`feedback_mj_character_batch_v6_evolution`(≥10 张大批量 Moderator 累计触发 + v6 进化体例)。

**P1.3 美术线 75% → ~80%**(89 + 22 = 111 张落 app)。**P2 第二条主线 ~5% → ~25%**(Ch4 5 关数值落,narratives 待 Batch 2.3)。

**2026-05-21 晚 候选 2 Ch4「西出阳关」Phase 2.1-2.4 全收口 ✅**(Mac+Opus xhigh ~2.5h 合计,6 commit push):**Ch4 1.0 P2 第二条主线第 1 章数值 + narrative + doc 全到位**。
- **Batch 2.1+2.1.5+2.2 实装**(`4f7fb6d`):5 关 stages.yaml entry + 主线红线放开 4 章 20 关 + UI/strings 适配 + 8 文件 395+ inserts(EncounterBiome desert/frontier + game_repository 红线 + chapter_list 4 章 + stages.yaml HP 7,200→15,500 / dropTable zhongqi_qing_xu_jian 1.0 给 Ch5 起步)
- **Batch 2.3.①+② v1 narrative 13 文件 ~5,880 纯正文字**(`be9ac31` + `0c8175b`,**v1 草稿用户审稿通过**):4 拍板文化叙事弧落地 — ① 章首释然(许昌→酒泉,师父遗言承上)② 章末「已知不足」顿悟(yiLiu→jueDing 拐点)③ 末 Boss 沉默克敌(三招手势 + 小铜镜 hook Ch5/Ch6)④ Tier 7 阶风格锚定「沉着/肃杀/老练/冷静」+ 西北风物词 + 嘉峪关社会词 + 黑名单词 0 命中
- **Batch 2.4 doc 同步**(2026-05-21 晚 ~30min):GDD v1.3 顶部摘要 + §8.1 注释 Demo 锁 3 章 + §12.4 第二条主线行加 Ch4 启动备注 + Ch5/Ch6 升档预期(25-30 关) + ROADMAP_1_0 P2.1 加 Ch4 桥头堡子项
- **Batch 2.5 R5 红线压测 + Phase 2 全收口 closeout**(2026-05-22 凌晨 ~1h):`test/balance/ch4_r5_crosstier_redline_test.dart` 50 种子玩家 yiLiu·dengFeng 满 build vs jueDing 跨阶 boss 三人组 · (leftWins+draws) ≥ rightWins 综合不输面;Phase 2 全收口 closeout 9 commit + 13 narrative + 4 拍板叙事弧 + 工作量复盘 + memory sink 候选 5 项 + Phase 0/1 spec 漏检披露(R0 红线层 5 维 grep)+ PROGRESS 110 → 81 行归档(W17-W18 + P1.1 + M4 美术 3 段合 ~30 行)。详 [`p1_x_chapter4_phase2_full_closeout_2026-05-22.md`](docs/handoff/p1_x_chapter4_phase2_full_closeout_2026-05-22.md)

**1178 pass / 0 analyze 不破**(原 1177 + R5 跨阶红线压测 +1)。**P2 第二条主线 ~25% → ~85%**(Ch4 1.0 P2 第二条主线第 1 章全收口 ✅,留 Ch5/Ch6 主轴 spec 待用户拍板)。详 commit + spec [`p1_x_chapter4_spec_2026-05-21.md`](docs/handoff/p1_x_chapter4_spec_2026-05-21.md) + full closeout [`p1_x_chapter4_phase2_full_closeout_2026-05-22.md`](docs/handoff/p1_x_chapter4_phase2_full_closeout_2026-05-22.md)。

**Phase 2 全收口 ✅** → 8h autonomous 工作流(2026-05-22 凌晨)批次 B-E 进行中。

**Ch4 Phase 1 spec**:[`p1_x_chapter4_spec_2026-05-21.md`](docs/handoff/p1_x_chapter4_spec_2026-05-21.md)(325 行)+ Phase 0 [`p1_x_chapter4_phase0_reality_check_2026-05-21.md`](docs/handoff/p1_x_chapter4_phase0_reality_check_2026-05-21.md)(227 行)。

**下波 候选**:① **候选 2 Batch 2.3 narratives**(直接接 Phase 2 主轴,接续度最高);② **候选 1 Stage 3 剩 28 张**(MJ 解封后场景 18 + 心法 10,场景 Type A sref+sw100+ar 16:9+stylize 300 / 心法 Type B 无 sref+ar 2:3+stylize 200,≤8 张/批+间隔 ≥ 45min)。

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
