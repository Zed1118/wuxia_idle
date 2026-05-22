# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**2026-05-22 Ch5「征东」1.0 P2 第二条主线第 2 章 Phase 2 全收口 ✅**(Mac+Opus xhigh ~2.5h actual,5 commit `62ba01f` → `d9b7e98` 全 push):**用户 7 项拍板**(章名「征东」/ jueDing 全章 / 推荐文化主轴 / C 复合末 Boss / GDD §12.4.1 同步升 v1.5 / Batch 沿 Ch4 拆 3 子波 / 升 xhigh)。
- **Phase 1**(`62ba01f` ~30min):Ch5 spec doc 172 行 + GDD v1.4 → v1.5 正式拍板(§12.4.1 标签移除 + §12.4 Ch5 启动条目)
- **Batch 2.1+2.2**(`9a37db0` ~45min):5 关 stages.yaml entry + 红线层 4 patch(chapter_list / strings / game_repository_test / chapter_list_screen_test / battle_strategy_e2e_test 5 章 25 关动态化)+ HP 14.5k→32k / Atk 1.2k→1.95k 跨阶 zongShi·qiMeng / **EncounterBiome 0 扩**(全复用 17 enum)+ **equipment.yaml 0 扩**(zhongQi/baoWu 现成)+ 1180→1185 pass(+5 e2e)
- **Batch 2.3.① 子波 1**(`f76028e` ~50min):opus 单写 12 narrative v1(11 stage opening/victory + stage_05_04_defeat + chapter 占位)~4,500 字 / 黑名单 0 命中 / 用户审 v1 通过
- **Batch 2.3.② 子波 2**(`d9b7e98` ~30min):chapter_05 章首尾精写 ~1,640 字(prologue 小铜镜回取 + 师父第二句承上 / epilogue 镜玉佩并放 + **师父第三句遗言反转** Ch6 hook)+ stage_05_05_defeat ~510 字 / 用户审 v1 通过
- **narrative 全统计**:13 文件 ~6,638 字 / 师父遗言 3 处贯穿 + 物理遗物 hook 5 处闭环(小铜镜回取→玉佩出场→玉佩兑现→二字并放→defeat 反例)/ Tier jueDing「沉静/从容/通达/入微」全章 / 视角切换沿 Ch4 体例
- **Batch 2.4 doc 同步**(本批):GDD §12.4 Ch5 行升「Phase 2 全收口 ✅」+ ROADMAP_1_0 P2.1 加 Ch5「征东」子项(P2.1 字数累计 12,518 ≈ 预算上限)+ PROGRESS 顶段(本批)
- **Batch 2.5 R5 跨阶红线压测 + Phase 2 closeout**:待 ~45min

**1185 pass / 0 analyze**(+5 Ch5 e2e stage)。**P2 第二条主线 ~85% → ~92%**(Ch4 + Ch5 全收口,留 Ch6 spec 起草)。

**下波 候选**:① **Batch 2.5 R5 跨阶红线压测 + Phase 2 closeout 收口**(本会话续)② **Ch6「飞升」spec 起步**(zongShi+wuSheng 全章 + 飞升前置,用户拍板后)③ MJ Discord 派单 15 张 Ch4 enemy / Codex Pen 视觉验收 / Stage 3 剩 28 张(异步)

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
