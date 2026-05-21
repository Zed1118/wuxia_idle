# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**2026-05-21 主对话 P1.1 候选 1+2 ✅**(Mac opus xhigh ~5h):候选 1 A1 E.1 收徒弹窗 + 候选 2 A1 E.5 祖师爷 buff 一波连击。HEAD `<候选 2 commit 即将创建>`,1127→1147 pass(+20 净)/ analyze 0 issues / saveVersion 0.12.0。

**候选 2 A1 E.5 祖师爷 buff(opus xhigh ~1.5h)**:
- Phase 0:`founder_ancestor_buff` 全仓 0 代码引用(纯 yaml 占位),**0→1 全新落地**
- **决议 E.5.A**(用户拍板):enabled_when_alive: false→true,玩家本人=祖师即享 buff,作用 active 全员(`apply_to_disciples_only: false`)
- 实装:numbers.yaml flip + sect_wide_buff 4 字段(internal_force_max_pct=0.05 / max_hp_pct=0.05 / crit_rate_bonus=0.02 / cultivation_progress_pct=0.03)+ `FounderAncestorBuff` 强类型 class + `FounderBuffService` (active 含 founder 时激活) + provider
- derived_stats 接入:maxHp / internalForceMaxWithLineage / criticalRate 各加可选 `founderBuffActive: bool`(默认 false 不破现有 caller);**stage_battle_setup 端 caller 接入** + **character_panel_screen UI 显示接入**
- LineagePanelScreen 加「祖师爷光环」摆台(4 行 buff 数值显示)
- test +8(NumbersConfig load + service 4 case + disabled 兜底 + 红线说明)+ 2 test 期望值更新(master_disciple buff 1.10×1.05=1.155 / stage_setup VC18-A1 maxHp +5%)

**候选 1 A1 E.1 收徒弹窗(opus xhigh ~3.5h)**:audit + 5 决策拍板(方案 3 inactive 池 / D1.b 列表 outside / D2.b 3 NPC / D3.a 一次性 / D4.b 完整 UI)+ 新 5 文件 + 改 8 文件 + +12 test。saveVersion 0.11.0 → 0.12.0。详 `p1_1_a1_recruitment_closeout_2026-05-21.md`。

**下波 ⭐**:候选 3 A3 共鸣度满级体验完整化(joint_skill 倍率 4500 已在 numbers.yaml,表现层 + banner 时机 + 拆分提示 UI,**opus xhigh 2-4h**)。

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

### M4 #46 美术详条迁出 2026-05-20/21

2026-05-20 ~ 21 主对话 5 段顶段已迁出(完整内容见各 closeout):

- **候选 1 round 1 视觉验收 4/4 实质 PASS**(2026-05-21):Codex Pen `flutter run -d windows` 截 4 图 + closeout · splash WARN(搜狗输入法 + Pen 1280×720 限制 测试环境)+ home_feed seal WARN(派单 prompt 凭注释引用旧标题 vs `strings.dart:456 = '江湖见闻'` 教训)+ seclusion 5 地图缩略 PASS + locked 灰化 PASS · 详 `art_assets_integration_visual_check_closeout_2026-05-21.md`
- **stage_audit 阶段性项目审查**(2026-05-20,opus xhigh ~25min):1.0 路线图 Demo ~95% / Demo §8.4 14/14 全达标 / test:code = 106% / memory 3 sink(`feedback_phase0_grep_two_axes` 四维 + `feedback_dart_underscore_wildcard` + `feedback_image_asset_error_builder`)· 详 `stage_audit_2026-05-20.md`
- **assets 89 张归位 + Flutter UI 接入(round 1)**(2026-05-20,opus xhigh ~40min):Phase 0 三维 + Phase 1 89 张归位 + Phase 2 6 项 schema(detailPath/image_path/portraitPath/pubspec assets)+ Phase 3 UI 3 处接入(seclusion 96×64 地图缩略 / splash landscape_loading / home_feed seal_red)· 详 `art_assets_integration_{spec,closeout}_2026-05-20.md`
- **Stage 2 W1-W6 量产正式收官 74/74**(2026-05-20,opus xhigh ~230min):W1-W6 累计 74 + Stage 1 PoC 15 = 89 张全归档 ~/Desktop/MJ_Stage*。均 8.55/10,W6 ⭐⭐⭐ 9.0 · MJ Standard $30 ROI ≈ $0.40/张(节省外包 98%)· 18 条 memory 量产配方矩阵 · 详 `art_poc_stage2_w{1..6}_closeout_2026-05-20.md`
- **P1 #45 Demo §8.4 polish nightshift + cherry-pick**(2026-05-20,opus --print 8 task 34min + 主对话 ~1h):synergies +2 / encounters +9 / skills +5 / techniques 21 处占位 / 招式 narrative +5 / events +4 / 心法 +4 / Phase 5 师徒 spec · Demo §8.4 14/14 全达标 · 详 `p1_45_demo_polish_closeout_2026-05-20.md`

> M4 #46 Stage 0/1/1.5 spec 详条见 `art_poc_stage{0_ref_exploration,1_closeout,1_5_equipment,2_full_production}_2026-05-20.md`。

详 git log + handoff/各 closeout。
