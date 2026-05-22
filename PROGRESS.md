# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**2026-05-22 Ch6「飞升」Phase 2 全收口 ✅ · 1.0 P2 第二条主线全闭环**(Mac+Opus xhigh 3h 无人看管批,6 commit `15216a0` → `486d39b` 全 push origin/main · Ch4+Ch5+Ch6 三章弧叙事完整):
- **Phase 0 + Phase 1**(`15216a0`+`5db61a8` ~1h):6 维 grep + spec doc 173 行 + GDD v1.5→v1.6 + 用户拍板 4 主轴(章名「飞升」/ zongShi 全章跨 wuSheng·qiMeng / 师父第三句完整联通 + 西凉霸主本人复出 / 末 Boss B 复合)
- **Batch 2.1+2.2**(`f6379d7` ~45min):data/stages.yaml +5 entries stage_06_01..05(HP 30k→52k / Atk 2.0k→2.7k 跨阶 wuSheng·qiMeng)+ 末 Boss B 复合(主西凉霸主 wuSheng + 2 副 zongShi·dengFeng 三弟子)+ strings.dart + chapter_list + 4 test fixture 扩 6 章 30 关 + **schema 0 扩**(shenWu / chuanshuo 心法 / shichuan skill 全现成)+ 1186→1191 pass(+5 e2e)
- **Batch 2.3.① 子波 1**(`ea8ea2d` ~45min):11 stage narrative + chapter_06 占位 ~4,700 字 · 玄天斧/雪莲鞭/金丝甲/黄河玉/昆仑佩物理遗物多处闭环 · 黑名单 0 命中
- **Batch 2.3.② 子波 2**(`486d39b` ~25min):chapter_06 prologue/epilogue 精写 ~1,500 字 + stage_06_05_defeat ~500 字 · **师父三句遗言第一次完整连成一句** + **无物之境收束**(四件物事并放青石不带走雪埋)
- **narrative 全统计**:13 文件 ~5,800 字 · Tier zongShi「澄澈/无为/玄妙/化境」 · 西凉霸主本人首次开口(三章沉默→飞升前夜对话)· 视角切换沿 Ch4-Ch5

**1191 pass / 0 analyze**(+5 Ch6 e2e stage,P2.5 R5 跨阶 wuSheng 红线压测待)。**P2 第二条主线 100% ✅**(Ch4 + Ch5 + Ch6 三章弧 全闭环)。**1.0 进度 ~42% → ~50%**(P2 主线全闭环跳变)。

**下波 候选**:① **P2.5 R5 跨阶 wuSheng 红线压测 + Phase 2 closeout**(本批续 ~35min)② P2.4 GDD v1.6→v1.7 + ROADMAP P2.1 加 Ch6 子项 + PROGRESS(已部分完成)③ 1.0 P3 起步 / §12.1 心魔 spec 起草(P2.2 独立)/ MJ 派单 Ch4-6 enemy ~20 张异步

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
