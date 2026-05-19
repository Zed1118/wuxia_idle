# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 80 行内，超出归档到末尾。

## 当前阶段

**P1 #43 高阶占位补齐 · jueDing/zongShi 段战斗内容全到位**(2026-05-19 傍晚,sonnet ~50min)。**audit 误判 27 条 skill 已全落不新增**(jianghu/shichuan/chuanshuo,memory `feedback_audit_report_phase0_verify` 实战)。towers.yaml 21-30 阶梯 skillIds(21-22/26-27 basic only / 23-24/28-29 +skill / 25/30 Boss +ult)+ dropTable 阶梯加 zhongQi(21-25 5 件)/baoWu(26-30 5 件)全覆盖 + equipment.yaml 10 件 dropSourceTags 修正(zhongQi tower_30→tower_25 audit 误判,baoWu zongShi_unlock→[tower_30, zongShi_unlock],shenWu Phase 4+ 飞升机制后补)。test **1117 pass + 1 skip + 0 issues** 无回归。详 `docs/handoff/p1_43_higher_tier_closeout_2026-05-19.md`。

**P1 #44 延续典故文案抽 yaml · 协作模式 v1.8 切单端 + Mac 接手文案补齐**(2026-05-19,opus xhigh,Phase 0 ~10min)。**协作模式切换**:DeepSeek 端文案产线退役,Mac+Opus 4.7 单端接管 `data/lore/` + `data/narratives/` + `data/events/`。CLAUDE.md v1.8 同步(§3 目录所有权 / §8 工作流表单行 / §9 红线第 3 条删) + `WINDOWS_DEEPSEEK_GUIDE.md` 归档至 `docs/_archive/` + memory `project_wuxia_idle` 协作段更新。**Mac 端 wire 全闭环**(本日早段):LoreContent + GameEventService + 占位符 + fallback + 红线 case 5 strict + 1 soft(默认 skip),test 1117 pass + 3 skip + 0 issues。**下波动作**:Mac 端 35 件 × 2 池 ≈ 280 条文案补齐 7 批(按 tier 分)+ 红线 case 启用 + closeout。HEAD 待 Phase 1 推进。

**Nightshift 2026-05-19 夜班 9 task 销账 + 外部审查修正**(2026-05-19 上午,Mac+Opus 主对话 ~30min)。10 worktree 串行 sonnet --print 跑 1h17min,T02-T09 8 task 实际产出 OK + T01 真失败(API 32K output cap)。**cherry-pick 8 commit 合 main + 外部审查 3 修正**:T02 audit Demo 30 层验收强化 / T03 fortune 最大 10 加来源引用 / T08 deadcode §1 内部矛盾修。**测试 1086→1111 pass + 1 skip + analyze 0 issues**,HEAD `352cdb4`。**沉淀 3 memory bug**:`feedback_nightshift_max_output_token` / `feedback_nightshift_verify_changedoutside_bug` / `feedback_flutter_analyze_fatal_errors_invalid`(修正旧 `feedback_nightshift_verify_lint_severity`)。本批 T01 修正:PROGRESS.md 98→<80 行 + W17-W18 详条迁出归档。**T08 chip + T07/T08 死代码 + #37 yu_zhong_qiao_men 挂回 续推进**(2026-05-19 sonnet ~45min):① `_CodexListView` 接 chip provider;② 删 `StageDef.narrativeId` @Deprecated + 3 死 provider(`leftTeam`/`rightTeam`/`gameEventService`)+ defs_test T33 + 占位字段 Phase 0 grep 保留;③ T03 yu_zhong_qiao_men 挂回(`fortuneEvent` rain×inn,encounters.yaml +1 条 / 文件 mv archive→events,fortuneEvent 16→17)。新沉淀 memory `feedback_audit_report_phase0_verify`(audit 推 7 项实测 4 项真死)。→ **1111 pass + 1 skip + 0 issues**。详 `docs/handoff/nightshift_20260519_handoff.md`(含 emergency addendum)+ T10 SUMMARY(`/Users/a10506/Desktop/wuxia-idle-T10/.nightshift/SUMMARY.md`)。

**P1 #42 Phase 2 §10 P1.x+P1.y+P1.z + P2 扩段 100% 全闭环里程碑**(2026-05-18,Mac+DeepSeek 双端 1086 pass + 1 skip + 0 issues,HEAD 同期 `8f85fd4`)。**§10 三方式 100% 全闭环**:1️⃣ 强制引导(P1.x,DeepSeek 5 yaml mandatory: true) + 2️⃣ 气泡 banner(P1.y,TutorialBannerCard step 6-8 hook) + 3️⃣ 见闻录百科(P1.z,CodexTab 19 条 = 12 机制 + 7 lore,P2 扩段)。Phase 0 reality check 实战 `feedback_phase0_grep_two_axes` 发现 `data/narratives/codex/` 已存 18 md。新沉淀 `feedback_listview_widget_test_viewport`(ListView ≥ 8 行扩 800x3000 viewport)。详 closeout `p1_42_phase2_p1{x,y,z}_*_2026-05-18.md`。

**P1 #42 Phase 1 销账 + nightshift 加固**(2026-05-17/18):6 phase 一波收口 971/971(§9 上线第一屏 + 江湖见闻录 + 延续典故 hook + GameEvent 7 type);nightshift 8 task widget test 加固 997/997(2026-05-18 凌晨 sonnet 2h 5m)。新挂账 #44 延续典故文案抽 yaml。详 closeout `p1_42_phase1_closeout_2026-05-17.md`。

> W18 + P0 全收口 + 1.0 路线图 launched(2026-05-17)详条已迁出归档,见末尾「### W17-W18 详条迁出 2026-05-19」段。

## 已完成(近 W6 起,早期归档见末尾)

> W15 主战场详条 20 段 + W17-W18 详条 11 段均已归档,详末尾「### W14-W15 详条迁出」+「### W17-W18 详条迁出 2026-05-19」段。

## 已知偏差 / 挂账事项

- ~~37 / 38 / 40 / 41 / 42 / 43 全销账~~(2026-05-17/18/19):#37 详 `p1_37_orphan_decree_2026-05-19.md`;#38/40/41/42 详末尾 W17-W18 详条段;#43 详顶段 + `p1_43_higher_tier_closeout_2026-05-19.md`
- 44. **延续典故文案抽 yaml**(部分销账 2026-05-19):Mac 端 wire 完成(详顶段),DeepSeek 端待补 35 件装备各 2 池文案

> 已销账条目(#1-#43/#45)详见末尾归档。**剩余 P1**:#44 文案。

## 下一步

**下波候选**(优先级排):① **#44 DeepSeek 35 件文案补齐**(DeepSeek 主导 3-5h,Mac 端到位后红线 case 验收);② **美术 PoC + 水墨 LoRA**(opus + 用户主导 6-10h,M4 硬门槛,技术选型先讨论);③ **P1.2+ 章节扩展 / 心法相生设计**(待 #44 闭环后排期)。

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

### W17-W18 详条迁出 2026-05-19

夜班 T01 PROGRESS 清理批次,以下顶段段落迁出归档(完整内容见各 closeout):
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
