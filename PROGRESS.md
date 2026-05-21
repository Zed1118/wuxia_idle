# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**2026-05-21 晚 候选 1 M4 美术 Stage 3 · BOSS 题材 22 张闭环 ✅**(Mac opus xhigh ~3h,4 commit `319e15d` + `f14ba0c` + `7ada9b8` + `e6d5806`):用户拍板二选一 → 候选 1 美术 Stage 3 优先(BOSS + 场景 + 心法卷轴 3 题材,~50 张轻收口,BOSS 优先)。Phase 0 reality check 核心发现 ⭐:character_avatar.dart 占位 widget 改造 1 处 = 60+ enemy iconPath sleeper schema 一次性激活(stages + towers yaml 早锚 + StageDef.iconPath 早 parse 但 widget 没消费)。Phase 1 三 widget 全接入(character_avatar / battle_screen Stack 背景 / technique_panel tier banner)+ 5 def schema 加可空字段。**MJ 出图 22/22** = v1 旧违规版 7 张过 → 触发 Moderator manual review(锁 ~5h)→ v5 合规版 14 张全过 → v6.1 thug_a 老者意境加固 1 张重抽。towers.yaml 6 BOSS iconPath 撞名(F15-30 全占位 wulin_bazhu.png)sed 精确改 6 行 → tower_boss_<floor>.png。1172 pass / 0 analyze 全程不破。详 [`art_stage3_boss_closeout_2026-05-21.md`](docs/handoff/art_stage3_boss_closeout_2026-05-21.md) + Phase 0 [`art_stage3_phase0_reality_check_2026-05-21.md`](docs/handoff/art_stage3_phase0_reality_check_2026-05-21.md)。memory sink:`feedback_mj_character_batch_v6_evolution`(≥10 张大批量 Moderator 累计触发 + v6 进化体例)。

**P1.3 美术线 75% → ~80%**(89 + 22 = 111 张落 app)。**P2 第二条主线 ~5% → ~25%**(Ch4 5 关数值落,narratives 待 Batch 2.3)。

**2026-05-21 晚 候选 2 Ch4「西出阳关」Phase 2.1+2.1.5+2.2 实装 ✅**(Mac+Opus xhigh ~1.5h,commit `4f7fb6d` push):**5 关 stages.yaml entry 落地 + 主线红线放开 4 章 20 关 + UI/strings 适配 + 5 test fixture 适配**。**Phase 0/1 spec 漏检披露 ⭐**:`_enforceMainlineRedLines` 硬绑 15/3 章 + ChapterListScreen `_chapters [1,2,3]` 硬绑 + 5+ test 硬绑 15 全包修(Phase 0 4 维 grep 漏 schema/UI/test fixture 维度)。改动总览:① enums.dart EncounterBiome + desert/frontier ② game_repository.dart 红线放开动态 5*chapterCount ③ chapter_list_screen.dart 4 章 + strings.dart chapter4Title「西出阳关」④ stages.yaml 5 关 entry(HP 7,200→15,500 / Atk 720→1,250 全 §5.4 红线内 / dropTable zhongqi_qing_xu_jian 1.0 给 Ch5 起步)⑤ Isar codegen 重生 ⑥ test fixture 4 章 20 关 8 文件 395+ inserts。**1177 pass / 0 analyze**。

**2026-05-21 晚续 候选 2 Ch4 Batch 2.3.①+② v1 全 13 文件 ~5,880 纯正文字 ✅**(Mac+Opus xhigh ~1.5h,3 commit `be9ac31` + `4bdb90d` + `0c8175b` push):**4 拍板文化叙事弧落地** ⭐ — ① 章首释然(自许昌→潼关→长安灞桥→陇右→酒泉,师父遗言「看不懂的就先走一走」承上)② 章末「已知不足」顿悟(yiLiu→jueDing 拐点,师父遗言「听那处地方的风」终听懂一半)③ 末 Boss 沉默克敌(灰袍人三招手势 + 留小铜镜 hook Ch5/Ch6)④ Batch 2.3 拆 3 子波。**13 文件**:chapter_04.yaml 章首尾(~1,100 字 v1) + 10 段 stage narratives(~4,460 字 opus 单写)+ stage_04_05_defeat(~320 字 v1)。Tier 7 阶风格锚定「沉着/肃杀/老练/冷静」+ 西北风物词 + 嘉峪关社会词「西凉/校场/边军/酒葫芦」。**黑名单词 0 命中**。子波 ② 字数 1,432 字符对齐 spec 1,420 预算 ⭐ 100%。1177 pass / 0 analyze 不破。**v1 草稿待用户审稿**:情感顶峰段(epilogue 顿悟 + defeat 落败)opus 单写可能空洞,等用户局部 Edit 精修指点。详 commit `be9ac31`/`0c8175b` + spec `p1_x_chapter4_spec_2026-05-21.md`。

**Phase 2 剩余**:① **用户审稿 v1 草稿**(chapter_04 prologue/epilogue + stage_04_05_defeat,~1,420 字,Tier 7 阶风格锚定,情感顶峰段可指点局部精修)② **Batch 2.4 同步**(GDD §12.5 P2 启动备注 + §7 容量决议主线 20/20 上限 + PROGRESS + ROADMAP_1_0)③ **Batch 2.5 收尾**(R5 末 Boss 跨阶红线压测 case + closeout)。

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

夜班 T01 PROGRESS 清理批次 + 2026-05-20 #45/#46 迁出 5 段(完整内容见各 closeout):

- **P1 #44 延续典故文案抽 yaml · Mac 接手 280 条文案全补齐 + 协作模式 v1.8 切单端**(2026-05-19,opus xhigh ~1h):Phase 0 协作切换 CLAUDE.md v1.8 + WINDOWS_DEEPSEEK_GUIDE 归档 + Phase 1 7 批 280 条文案(Tier 风格梯度 7 阶 + 占位符 obtained/boss 无串池 + 通篇无网游词)+ Phase 2 红线 1119 pass 0 issues,HEAD `99f4733`,详 `docs/handoff/p1_44_mac_takeover_closeout_2026-05-19.md`
- **P1 #43 高阶占位补齐 · jueDing/zongShi 段战斗内容全到位**(2026-05-19 傍晚,sonnet ~50min):audit 误判 27 条 skill 已全落不新增,towers.yaml 21-30 阶梯 skillIds/dropTable + equipment.yaml 10 件 dropSourceTags 修正,1117 pass + 0 issues,详 `p1_43_higher_tier_closeout_2026-05-19.md`
- **Nightshift 2026-05-19 夜班 9 task 销账 + 外部审查修正**(2026-05-19,Mac+Opus ~30min):10 worktree 串行 sonnet --print 1h17min,8 task 产出 OK + T01 API 32K output cap 真失败,cherry-pick 8 commit + 外部审查 3 修正(T02 audit / T03 fortune / T08 deadcode),1086→1111 pass,沉淀 3 memory bug,详 `nightshift_20260519_handoff.md`
- **P1 #42 Phase 2 §10 P1.x+P1.y+P1.z + P2 扩段 100% 全闭环里程碑**(2026-05-18,Mac+DeepSeek 双端 1086 pass + 0 issues,HEAD `8f85fd4`):§10 三方式 100% 全闭环(强制引导 + 气泡 banner + 见闻录百科 19 条),Phase 0 reality check 发现 codex/ 已存 18 md,新沉淀 `feedback_listview_widget_test_viewport`,详 `p1_42_phase2_p1{x,y,z}_*_2026-05-18.md`
- **P1 #42 Phase 1 销账 + nightshift 加固**(2026-05-17/18):6 phase 一波收口 971/971(§9 上线第一屏 + 江湖见闻录 + 延续典故 hook + GameEvent 7 type),nightshift 8 task widget test 加固 997/997,详 `p1_42_phase1_closeout_2026-05-17.md`
- **P1 #42 Phase 2 §10 P1.x 销账**(2026-05-18,Mac+Opus xhigh ~1.5h):tutorialStep 业务读写层 + MainMenu 灰显 2 按钮 + NarrativeContent.mandatory wire + DeepSeek 5 yaml mandatory: true 闭环,1022/1022,详 `p1_42_phase2_p1x_tutorial_closeout_2026-05-18.md`
- **P1 #42 Phase 1 nightshift 4 子系统加固**(2026-05-18 凌晨 sonnet 2h 5m):8 task 串行 6 completed + 2 skipped,997/997 + 1 skip,详 nightshift/T08 SUMMARY
- **P1 #42 Phase 1 销账**(2026-05-17 晚,Mac+Opus xhigh ~2h 50min):6 phase 一波收口 971/971,§9 上线第一屏 + 江湖见闻录 + 延续典故 hook + GameEvent 7 type,详 `p1_42_phase1_closeout_2026-05-17.md`
- **P0 阶段 4 段销账**(2026-05-18 整理迁出):P0 battle_engine strategy 943/943 / P0.3 #41 砍方案 C / P0.2 #40 排行榜 888/888 / P0.2 #40 spec 起草
- **P0.1 #38 maxHp 重平衡**(2026-05-17 晚,Mac+Opus xhigh ~2h):方案 D 多 lever 组合 864→873 + analyze 0,详 `p0_38_maxhp_rebalance_closeout_2026-05-17.md`
- **外部审查 + 6 项收尾计划**(2026-05-17 晚):奇遇口径 3 维度 + 节日数对齐 + 主线字数 5000→7000 + #38 spec 起草
- **1.0 路线图 launched + W18 全收口**(2026-05-17 晚):Demo §7 12/12 全 ✅,`docs/ROADMAP_1_0.md` v1.0(后 v1.1),16 月总时长 P0-P5 阶段
- **W18-A1.2 hot-loop / 红线压测 / 心法相生 6 字段消费 + A3 lore 双端 + maxHp cap hotfix**(2026-05-17 3 段合并):synergy_hot_loop_upgrade_test +39 / 825→864 pass / DeepSeek 4 events / #38 暴露 / memory `feedback_red_line_test_semantics` 实践
- **W18-A1 Codex 视觉验收 6 PASS / 1 WARN + Demo §7 GUI 收尾**(2026-05-17):7 截图全核完,A:B ratio = 1.20 命中
- **W18-A1 Codex 视觉验收派单准备**(2026-05-17):fixture self-check + 派单 spec 7 截图,phase2_seed_service.seedVisualCheckW18A1 5 角色全 yiLiu 配对

### P1.1 候选 1-5 详条迁出 2026-05-21

2026-05-21 主对话 P1.1 5 候选(4 实装 + 1 文档对齐)全收口顶段已迁出(完整内容见各 closeout):

- **候选 5 CLAUDE.md §12 表述对齐**(2026-05-21 晚,opus ~20min,纯 markdown):6 处 Edit — v1.9 顶部摘要 + §12.1 末备注删 #11 + §12.2 #11 反转(候选 2 已激活)+ §12.2 #9 补候选 3-b 实装注 + §12.2 #1 enum_localizations 路径修正 + §12.2 #6 encounter 公式行号修正。**0 代码 / 0 yaml / 0 test 改动**,1172 pass 不动。详 `p1_1_candidate5_claudemd_align_closeout_2026-05-21.md`
- **候选 4 A4 开锋 build 内容扩**(2026-05-21 晚,opus xhigh ~50min):audit + 实装一波,grill 4 项全走推荐(G1.a 不参与 / G2.b N=2 / G3.a 复用 / G4.a 不动 lore)。21 件 weapon yaml 各填 2 个同流派同阶 skills.yaml 现成招(机械映射),14 件 armor/accessory 留空走 UI 兜底。0 代码 / 0 schema / 0 新增 skills.yaml。1170→1172 pass(+2)/ 0 issues。详 `p1_1_a4_forging_closeout_2026-05-21.md` + `p1_1_a4_forging_phase0_audit_2026-05-21.md`
- **候选 3 A3 共鸣度满级体验**(2026-05-21 午,opus xhigh ~3h):4 子任务 3a/3b/3d/3c 串行收口。3-a banner victory dialog 加共鸣度晋阶 sub-row(`3cb9918` ~30min);3-b joint_skill battle 释放(`15ff8aa` ~1.2h,核心改动)— skills.yaml 新增 `skill_joint_skill`(mult=4500),`ResonanceStageConfig` +2 字段,battle_ai 优先级 pending>jointSkill>powerSkill>normalAttack 自动放,红线 27,421<100,000 ✅;3-d equipment_detail 共鸣度晋升信息透明 section(`9e54cf9` ~25min);3-c sword_song 暴击剑鸣浮字纯文字降级(`225ee8e` ~40min)。1147→1170 pass(+23)/ 0 issues。详 `p1_1_a3_resonance_closeout_2026-05-21.md` + `p1_1_a3_resonance_phase0_audit_2026-05-21.md`
- **候选 2 A1 E.5 祖师爷 buff**(2026-05-21 早,opus xhigh ~1.5h,commit `a0eae82`):祖师爷在世时门派全员 +X% 加成(GDD §7.1)。`numbers.yaml inheritance.founder_ancestor_buff` 4 字段已激活(enabled_when_alive: true)+ buff 应用层 + UI 显。详 `p1_1_a1_founder_buff_closeout_2026-05-21.md`
- **候选 1 A1 E.1 收徒弹窗**(2026-05-21 早,opus xhigh ~3.5h,commit `86618f1`):师徒"收徒池"E.1 流程实装 — 池采样 + 弹窗 UI + 入门即学徒境界 + 心法/装备初始化。详 `p1_1_a1_recruitment_closeout_2026-05-21.md` + `p1_1_a1_recruitment_audit_2026-05-21.md`

### M4 #46 美术详条迁出 2026-05-20/21

2026-05-20 ~ 21 主对话 5 段顶段已迁出(完整内容见各 closeout):

- **候选 1 round 1 视觉验收 4/4 实质 PASS**(2026-05-21):Codex Pen `flutter run -d windows` 截 4 图 + closeout · splash WARN(搜狗输入法 + Pen 1280×720 限制 测试环境)+ home_feed seal WARN(派单 prompt 凭注释引用旧标题 vs `strings.dart:456 = '江湖见闻'` 教训)+ seclusion 5 地图缩略 PASS + locked 灰化 PASS · 详 `art_assets_integration_visual_check_closeout_2026-05-21.md`
- **stage_audit 阶段性项目审查**(2026-05-20,opus xhigh ~25min):1.0 路线图 Demo ~95% / Demo §8.4 14/14 全达标 / test:code = 106% / memory 3 sink(`feedback_phase0_grep_two_axes` 四维 + `feedback_dart_underscore_wildcard` + `feedback_image_asset_error_builder`)· 详 `stage_audit_2026-05-20.md`
- **assets 89 张归位 + Flutter UI 接入(round 1)**(2026-05-20,opus xhigh ~40min):Phase 0 三维 + Phase 1 89 张归位 + Phase 2 6 项 schema(detailPath/image_path/portraitPath/pubspec assets)+ Phase 3 UI 3 处接入(seclusion 96×64 地图缩略 / splash landscape_loading / home_feed seal_red)· 详 `art_assets_integration_{spec,closeout}_2026-05-20.md`
- **Stage 2 W1-W6 量产正式收官 74/74**(2026-05-20,opus xhigh ~230min):W1-W6 累计 74 + Stage 1 PoC 15 = 89 张全归档 ~/Desktop/MJ_Stage*。均 8.55/10,W6 ⭐⭐⭐ 9.0 · MJ Standard $30 ROI ≈ $0.40/张(节省外包 98%)· 18 条 memory 量产配方矩阵 · 详 `art_poc_stage2_w{1..6}_closeout_2026-05-20.md`
- **P1 #45 Demo §8.4 polish nightshift + cherry-pick**(2026-05-20,opus --print 8 task 34min + 主对话 ~1h):synergies +2 / encounters +9 / skills +5 / techniques 21 处占位 / 招式 narrative +5 / events +4 / 心法 +4 / Phase 5 师徒 spec · Demo §8.4 14/14 全达标 · 详 `p1_45_demo_polish_closeout_2026-05-20.md`

> M4 #46 Stage 0/1/1.5 spec 详条见 `art_poc_stage{0_ref_exploration,1_closeout,1_5_equipment,2_full_production}_2026-05-20.md`。

详 git log + handoff/各 closeout。
