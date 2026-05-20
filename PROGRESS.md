# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 80 行内，超出归档到末尾。

## 当前阶段

**M4 PoC #46 美术 Stage 0 spec 起草 · MJ v7 Standard 路径锁定**(2026-05-20,主对话 opus xhigh ~1h)。4 维度技术选型 4 项拍板:① **风格 暗黑厚涂水墨**(GDD §1 水墨克制 + ChatGPT 11 张样图审美北极星);② **工具链 MJ v7 Standard $30 月付主用 + ChatGPT Plus 副用辅助**(prompt 翻译 / 风格分析,**不出生产图**);③ **装备 混合双轨**(列表清晰 icon + 详情厚涂大图);④ **节奏 Stage 0 → 1 → 2**(ref 探索 → PoC 5 装备 → 量产 35+ 装备 / 3 角色 / 5 场景 / UI)。**重大改向**:推翻"ChatGPT 11 张当 MJ `--sref`",改"MJ 自跑一组 ref 候选"(**工具同源原则**)。**产物**:`docs/art_ref/chatgpt_baseline/` 归档 11 张(30MB 不进 build)+ `docs/handoff/art_poc_stage0_ref_exploration_2026-05-20.md` spec(3 套候选 prompt A 极致水墨 / B 暗黑沉郁 / C 山水意境 + MJ 操作手册 + 评估清单 + Stage 0→1 路径 + fal.ai LoRA 降级备案)。**1.0 路线图加权 ~25% → ~26%**(M4 启动 1/4)。**Stage 0 已收官**(套 A/B/C 共 ~28 张候选 ~30min,验收主观 8/10 + 客观 4/4 全 pass,锁 4 张 sref:主角色 / 备用角色 / 主环境 ⭐(雪景古松,与 baseline 04 神还原)/ 备用环境)。**Stage 1 PoC 5 装备 spec 已起草**(铁剑/青锋剑/龙泉剑/长虹剑/天问剑 yaml 真实名跳采样,双轨 prompt icon 白底 + 详情大图带主环境 sref,详 `art_poc_stage1_5_equipment_2026-05-20.md`)。教训沉淀:MJ 水墨防护三件套 `ink wash + sumi-e + monochrome` + `--no oil painting, red, vibrant, cinematic`。**下一步**:用户跑 10 张装备图。

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
