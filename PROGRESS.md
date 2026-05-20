# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 80 行内，超出归档到末尾。

## 当前阶段

**阶段性项目审查完工 ✅**(2026-05-20 续 美术 assets 归位后,主对话 opus xhigh ~25min,Pen 视觉验收异步等待期间 Mac 端并行盘点)。4 项审查全闭环:① **1.0 路线图 Demo 阶段加权 ~95%**(P0 100% / P1.3 美术 70% / P1.1 ~60%,真硬阻塞 1.0 启动 0 项)② **Demo §8.4 14/14 维度全达标实测**(主线 15 / 章节 3 / 主线字数 6858 / 爬塔 30 / 闭关 5 / 武学领悟 25 / 基础奇遇 29 超 4 但 1.0 翻倍不需补 / 节日 8 / 装备 35 / 心法 21 / 典故 360 段 / 武学领悟招式 40 / 心法相生 7 / 师徒 3),**候选 3 顺手 close 无需独立任务** ③ **代码健康满分**(test:code = 26735:25214 = 106%,1123 pass / 0 issues / pub direct 1 项 intl 0.19→0.20 可升 / debug 1999 行偏多但不清留 P5)④ **memory 3 条 sink**:扩展 `feedback_phase0_grep_two_axes` 三维→四维(加 D. UI widget 是否已建)+ 新写 `feedback_dart_underscore_wildcard`(Dart 3.7+ `(_, _, _)`)+ 新写 `feedback_image_asset_error_builder`(errorBuilder 守 widget test 不破)+ MEMORY.md 索引 +2 行。详 `docs/handoff/stage_audit_2026-05-20.md`(本审查报告)。**下波 ROI 最高**:候选 1 = 1.0 Demo §7 UI 完善阶段(装备列表页 + 详情弹窗 + 师徒展示页 + UI 类资源全接入,消费余下 64 装备 detail + 3 立绘 + 8 UI 资源,opus xhigh 2-5 工日,P1.3 收口最后里程碑)。

**M4 PoC #46 美术 89 张 assets 归位 + Flutter UI 接入完工 ✅**(2026-05-20 续,主对话 opus xhigh ~40min,spec 预估 1.5-2h,实测 1.7-3× 加速锚点验 memory `feedback_opus_xhigh_interactive_duration`)。Phase 0 三维 reality check:89 张实清 + equipment.yaml 35 件 iconPath 已就绪 + lib/ 0 处 Image.asset 接入 + forging_panel 不显示装备 icon。Phase 1 89 张全归位(bash 脚本一波 cp + rename,equipment 70/_alt 1/characters 3/maps 5/ui 10)。Phase 2 6 项 schema 注册:equipment.yaml 35 件加 `detailPath`(perl -i 批量)+ numbers.yaml maps 5 张加 `image_path`(snake_case)+ masters.yaml 3 角色加 `portraitPath` + pubspec assets 4 目录 + EquipmentDef/MasterDef/SeclusionMapDef 三 Def 加 nullable 字段 + factory parse。Phase 3 UI 3 处接入:① seclusion_map_list_screen `_MapCard` 加左侧 96×64 地图缩略(locked 自动灰化 + errorBuilder 兜底)② 新建 `lib/features/splash/presentation/splash_screen.dart` + main.dart wire `landscape_loading.png` 全屏闪屏 + 异步初始化迁入 ③ home_feed AppBar actions 加 `seal_red.png` 36×36 印章(GDD §1 水墨锚点)。**flutter test 1123 pass / analyze 0 issues 全程维持 baseline**。**美术成果首次落入 Flutter app**。沉淀 3 教训(Phase 3 接入受 widget 现状真实约束 / Dart 3.7+ underscore wildcard 新规则 `(_, _, _)` / Image.asset errorBuilder 守 widget test 不破)。详 `docs/handoff/art_assets_integration_{spec,closeout}_2026-05-20.md`。**下波**:① 候选 2 心法相生 §4.5 触上限 8 重设计 ② 候选 3 Demo §8.4 14/14 全达标确认 ③ 候选 4 Demo §7 UI 完善阶段(装备列表页/师徒展示页/详情弹窗,消费余下 64 装备图 + 3 立绘 + 8 UI 资源)。

**M4 PoC #46 美术 Stage 2 量产正式收官 · W1-W6 共 74/74 (100%) ✅**(2026-05-20 续,主对话 opus xhigh ~230min)。W1 寻常货 8 + W2 像样货 10 + W3 好家伙+利器 10 + W4 重器+师徒立绘 13 + W5 宝物+神物 18 + W6 5 闭关地图+10 UI 共 15 = **累计 74 张** + Stage 1 PoC 15 = **89 张产物**全归档于 `~/Desktop/MJ_Stage{1_PoC,2_W1,2_W2,2_W3,2_W4,2_W5,2_W6}/`。**Stage 2 总均 8.55/10**,各批 7.9-9.0 区间,**W6 9.0/10 ⭐⭐⭐ 是 Stage 2 至今最好的一批**(3 张极品:37 古剑冢 / 49 蒲团香炉 / 50 渔舟远山)。**W6 沉淀 1 教训**(memory 第 18 条):**Stage 2 收官两类批次配方区分** — 环境类(地图/loading)走 sref+sw 100 全继承 / UI 类(背景/卷轴/印章/图标)完全去 sref 避写实污染;6 周累计沉淀 memory 18 条形成完整 Stage 2 量产配方矩阵(装备 sw 50 / 立绘 sw 60 / 环境 sw 100 / UI 无 sref)。**Fast time 累计 ~180min**,**MJ Standard $30 月付 ROI**:74 张 ≈ $0.40/张(远低外包 $20-50/张行业价,节省 98%)。**Demo 美术资源 100% 就绪**,可启动 1.0 路线图下一阶段。**下波**:① assets 归位 + Flutter UI 接入 89 张图(opus 1-2 工日,1.0 必经路径) ② 心法相生 §4.5 触上限 8 重设计(sonnet+opus 1-2h)③ 1.0 LoRA 训练数据样本扩充(中国武器训练数据不足 3 件)。详 `docs/handoff/art_poc_stage2_w{1,2,3,4,5,6}_closeout_2026-05-20.md`。

> M4 PoC #46 Stage 0+1+1.5 + Stage 2 spec 详条见 `art_poc_stage{0_ref_exploration,1_closeout,1_5_equipment,2_full_production}_2026-05-20.md`。

**P1 #45 Demo §8.4 polish nightshift + cherry-pick 全收口**(2026-05-20,opus --print 8 task 34min + 主对话 cherry-pick + fix ~1h)。**Nightshift 8 task 全 OK**(03:18→03:52):T01 心法相生 +3→+2 回退 / T02 encounters +9 + skills +5 / T03 techniques.yaml 21 处 description 占位填实 / T04 武学领悟招式 narrative +5 / T05 events narrative +4 / T06 心法 narrative +4 / T07 Phase 5+ 师徒升级 spec 起草 / T08 closeout。**4 verify fail 全是脚本 bug,产出 0 真失败**,沉淀 4 memory + VERIFY_TEMPLATE.sh 修补下次 nightshift。**T01 设计 bug 发现 + 修复**:6 schoolPair 全覆盖方向后 sameTier 红线无空间,删 synergy_ling_yin_gui_yi 回 7 + 扩 fixture 5→7 角色。**Demo §8.4 14/14 全达标**(心法相生 5→7 中位 / 武学领悟 20→25 / 基础奇遇 17→21 / 招式 36→41)。HEAD `9f6c649`(本会话 9 commit 全 push origin/main),**flutter test 1123 pass + 1 skip + 0 fail / analyze 0 issues**。**1.0 路线图加权 ~22% → ~25%**。详 `docs/handoff/p1_45_demo_polish_closeout_2026-05-20.md`。

> P1 #43 / Nightshift 2026-05-19 / P1 #42 Phase 1+2 / P1 #44 延续典故文案抽 yaml 详条已迁出归档,见末尾「### W17-W18 详条迁出 2026-05-19/20」段。

## 已完成(近 W6 起,早期归档见末尾)

> W15 主战场详条 20 段 + W17-W18 详条 11 段均已归档,详末尾「### W14-W15 详条迁出」+「### W17-W18 详条迁出 2026-05-19」段。

## 已知偏差 / 挂账事项

- ~~37 / 38 / 40 / 41 / 42 / 43 / 44 / 45 全销账~~(2026-05-17/18/19/20):#37 详 `p1_37_orphan_decree_2026-05-19.md`;#38/40/41/42 详末尾 W17-W18 详条段;#43 详 `p1_43_higher_tier_closeout_2026-05-19.md`;#44 详 `p1_44_mac_takeover_closeout_2026-05-19.md`;#45 详顶段 + `p1_45_demo_polish_closeout_2026-05-20.md`

> 已销账条目(#1-#45)详见末尾归档。**P1 阶段全销账 ✅** + **Demo §8.4 14/14 全达标 ✅**(2026-05-20 #45 收尾)。

## 下一步

**下波候选**(优先级排):① **美术 PoC + 水墨 LoRA 调研**(opus xhigh + 用户主导 6-10h,M4 硬门槛,技术选型先讨论:AI 出图工具链 SD/Flux/MJ + LoRA 训练数据 + Demo 35 装备首批出图节奏 + 风格基调 GDD §1 水墨克制);② **P1.2+ 章节扩展 / 心法相生设计**(Phase 0 grep 起手:synergies.yaml/章节/§4.5 相生组合);③ **Phase 5+ 师徒系统升级**(路线图远期,GDD §7.1 飞升机制)。

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
- **W18-A1.2 hot-loop 升级 + A3 +5 lore 双端 + maxHp cap hotfix**(2026-05-17):synergy_hot_loop_upgrade_test +39 case,864/864,#38 暴露
- **W18-A1.2 hot-loop 红线压测 + A3 派单 spec**(2026-05-17):825/825,memory `feedback_red_line_test_semantics` 实践
- **W18-A1.2 心法相生 6 字段全消费 + W18-A2 副产物 4 event yaml**(2026-05-17):damage_calculator + seclusion hook 822/822,DeepSeek 4 events 落地
- **W18-A1 Codex 视觉验收 6 PASS / 1 WARN + Demo §7 GUI 收尾**(2026-05-17):7 截图全核完,A:B ratio = 1.20 命中
- **W18-A1 Codex 视觉验收派单准备**(2026-05-17):fixture self-check + 派单 spec 7 截图,phase2_seed_service.seedVisualCheckW18A1 5 角色全 yiLiu 配对

详 git log + handoff/各 closeout。
