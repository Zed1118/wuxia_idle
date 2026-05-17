# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**W17 nightshift 6 task 全链闭环 + 收编 + worktree 全清**(2026-05-17 早,opus low):**首跑无人值守自动调度 6/6 completed 0 SKIPPED**。① **夜班修复沉淀 commit `4f6d63e`**:dispatcher.sh bash 3.2 兼容(`${TASKS[-1]}` → `LAST_TASK` 常量)+ idempotency 保护(worktree 已有 nightshift commit 时跳过 claude 直接 verify)/ 5 个 T0X.verify.sh 加 `dart run build_runner build`(worktree 内 `.g.dart` gitignored 首次 analyze 必缺,这是首次 T01 verify FAIL 的根因)/ launch.sh 沉淀(nohup + caffeinate + disown + pgrep 重复运行保护)。② **6 task 全合并 main**:T04(`8d0489a`)LineagePanelScreen 边界用例 +5 真合 5/5 全过 / T03(`4f9d1c0`)死代码 scan 扫出 2 死 provider 候选(`gameRepositoryProvider` + `chapterCompletedProvider`)留 follow-up / T05(`ac06bb5`)NavigatorObserver mock 套路项目级沉淀(W6 5 轮失败矩阵 + 真解推导) / T02(`a1e58ce`)widget test pattern 审计 + pumpAndSettle 风险扫描 / T01(`9ccc4d9`)#37 6 events orphan 永久封档 / T06(`b21d4f3`)夜班 SUMMARY。③ **6 worktree + 6 nightshift 分支全清**。④ **770/770 + analyze 0 issues**(765 → 770 因 T04 +5 用例)。⑤ **T03 follow-up 销账 2 死 provider**(2026-05-17 早,sonnet ~5 min):删 `gameRepositoryProvider`(`lib/data/isar_provider.dart`,全仓走 `GameRepository.instance` 单例)+ `chapterCompletedProvider`(`lib/features/mainline/application/mainline_providers.dart`,UI 直调静态方法 `MainlineProgressService.chapterCompleted`)。770/770 + analyze 0 issues。⑥ **工程教训**:bash 3.2 不支持负索引 / worktree 验证脚本必须含 codegen,已落入 dispatcher 修复 commit。**夜班机制实战验证可行 + 修复后可复用 + T03 scan→delete 一波闭环**。
**W17 候选 E 师徒名单 UI panel 全链闭环 + Codex Pen 视觉验收 3 PASS**(2026-05-17,commit `9dcfe8a` + Codex `de7b862`,closeout `codex_w17_lineage_panel_visual_check_2026-05-17.md`):LineagePanelScreen 独立 Scaffold(主菜单按钮 push)+ `lineageInfoProvider` 派生(0 schema bump / 0 新 service / 0 isar entity)+ 3 widget test + strings 8 const + 1 函数。764/764 + analyze 0 issues。Codex 3 PASS:主菜单 9 按钮全景 / 全空态文案 / 完整态 chip+heritage 0 raw defId fallback。GDD §7.1 Demo 师徒 95% 完整,E.1/E.2/E.3/E.5 进 1.0 路线图。
**W17 候选 B 节日 encounter 扩 chuXi/qingMingJie + D 双销账**(2026-05-17,commits `9b795a0`/`0bb496c`/`ae9bb67`/`9a18245`/`5406f54`,closeout `codex_w17_festival_chip_extend_visual_check_2026-05-17.md`):Festival enum 8 / encounters 36→38 / 761/761。D-#17 phase1_tasks 反审撤回 / D-#3 riverpod_lint 半销账(plugin 启用预演 closeout `wuxia_d3_plugin_enable_dry_run_2026-05-17.md`,commit `bd5c8f3`)。3 段并行预研:A PROGRESS 清理 / B 师徒预研(E 实际值 sonnet 1-2h)/ C 余 8 orphan 复审(2 条可挂回)。
**W16 节日 encounter 全链闭环**(2026-05-16,详 closeout `codex_w16_festival_chip_visual_check_2026-05-16.md`):framework(`5ea1f60`)+ DeepSeek 6 节日文案(`5a3a06c`)+ Mac DEBUG override(`cdee42e`)+ Codex 7 PASS(`9421c55`),759/759。GDD §12.4 节日通道接口 + 内容首批落地里程碑销账。
**W15 收尾里程碑回顾(已归档)**(2026-05-16):① Phase 5 #3 第 6 批 lib 目录结构 finalization 销账 #2(closeout `week15_phase5_3_lib_structure_finalization_2026-05-16.md`,723/723);② Codex round2 全 PASS 销账 #34 + VC15-fresh hotfix `d6509ec`(closeout `codex_w15_victory_dialog_round2_visual_check_2026-05-16.md`,722/722);③ §12.1 #7 三流派 extra_effect v1.4 决议 + 代码层全链路销账(closeout `week15_section12_7_school_extra_effects_2026-05-16.md`,722/722)。详条迁归档段。

## 已完成(近 W6 起,早期归档见末尾)

- **W15 主战场详条 20 段已归档**(2026-05-17 行数清理):W15 G+F polish 双销账 / #30 P3 InventoryScreen 物料 Tab / #30 P3 victory dialog 升层 / #30 第 3 期 experiencePoints 升层链路 / G 任务 Pen-only T64 CRLF 修救 / #30 第 2 期 内力 + 心法领悟点 / Phase 5 #3 第 5 批 E+K / 第 5 批 I isar_provider 拆分 / 第 5 批 C 装备系统 features 迁 / 第 5 批 B 战斗系统 features 迁 / 第 4 批 A lib/core 抽公共 / 第 3 批 character_panel+inventory+technique_panel UI / 第 2 批 tower+mainline+encounter / Phase 5 #2 DDD 整理 + 闭关 feature 试点(销账 #28) / #30 闭关 3 维度接 service(销账 #30) / §12 待决清单收口方案 A / W15 共鸣强化开锋 + C-1 收尾 / polish + round2 双闭环 / #37 第 2 批挂回 7 条 + W15-r2 fixture / C-2 banner SkillDef.name。详条迁出归档段 `### W14-W15 详条迁出 2026-05-17`。

## 已知偏差 / 挂账事项

- 37. **6 events orphan 剩余可后续挂回**(原 23 → 第 1 批 6 + 第 2 批 7 + C-1 收尾 2 + W17 polish-C 2 → 余 6):W17 polish-C 挂回 2 条(huang_yuan_yi_zhong → qiu_quan tier 2 / jiang_xin_ye_hua → wu_xia_yi tier 3)。剩余 6 条主题不适配(duan_qiao_can_yue/gu_chuan_deng_ying/huang_cun_yao_ren/qing_lou_can_meng/lao_jing_hui_xiang/yu_zhong_qiao_men),心境/江湖故事/邪门调子/音律无对应武学,留 _archive/ 不动

> 已销账条目(#1/#2/#3/#4/#5/#6/#8/#9/#10/#11/#12/#13/#14/#15/#16/#17/#18/#19/#20/#21/#22/#23/#24/#25/#26/#27/#28/#29/#30/#31/#32/#34/#35/#36/#39)详见末尾归档。**W17 长期挂账冲刺销账 4 条 #9/#10/#11/#31**,剩余仅 #37(6 events orphan 主题不适配,留 _archive)。

## 下一步

**W17 nightshift 6 task 全合并 + 收编 + T03 follow-up 删 2 死 provider**(2026-05-17 早)已完整收口。**770/770 + analyze 0 issues**。下波待用户拍板(候选:**F** mainline+tower victory integration test sonnet 1-2h(现 #31 NavigatorObserver mock 套路加持下风险降低)/ **二次跑 nightshift** 验证修复后 dispatcher 健壮性 / W18 起步预研需大方向)。

## 关键约束(每次开局必读)

- 数值红线:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000(GDD §5.2)
- 不硬编码数值(走 numbers.yaml)、不硬编码中文文案(战斗调试日志走 enum_localizations.dart,UI 走 lib/ui/strings.dart,剧情走 data/narratives, lore, events)
- Riverpod 状态管理;Isar 本地存储;data/ 是 asset 根目录
- 写代码不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md(DeepSeek 领地)
- Mac 端写 lib/、data/*.yaml(顶层)、test/;DeepSeek 写 data/narratives/、data/lore/、data/events/

## 远程仓库

- GitHub:https://github.com/Zed1118/wuxia_idle
- 主分支 main
- 双端协作:Mac+Opus 写代码与数值;Windows+DeepSeek 写文案;Codex 桌面 @ Pen 跑视觉验收(详 `feedback_codex_pen_windows_visual_check.md`)

## 归档

### 已解决挂账(逆时序)

- **W12-W13 销账**(2026-05-14):#12 LevelDiff 数据/公式层语义统一(commit `0771c90`) / #23 widget test 不接真 Isar 架构层销账(W6 service 实例化 + nullable propagation) / #28 探路终结判不可解(5 轮 fake_async 边界,留 Pen 兜底) / #32 victory 接 resolveBattle(commit `a2de8a2`)
- **W4-W5 销账**(2026-05-13):#25 Phase2SeedService 缺主修(T54 seedMasterDisciple) / #26 闭关入口硬编码(T56 _SeclusionMenuButton) / #29 defeat hook + 9 关扩容(T59+T60)
- **W3 销账**(2026-05-12):#27 narrative schema 对齐(NarrativeLoader 子目录扫描 + stages 6 关 id 迁移)
- **W1-W2 销账**(2026-05-11):#22 T32 #22a/#22b service.persistResult + widget guard / #24 装备名未渲染(EquipmentDef.name + Flexible/ellipsis)
- **Phase 1-2 销账**(2026-05-10/11):#1 Riverpod 锁 2.x / #5 T17 笔误差 2→差 3 / #13 yaml b/c max_hp / #14-15 灵巧暴击 +0.20 与 ×2.0 yaml 化 / #16 战例 E ≤100000 / #19 T15 远程沙箱无 Flutter / #20 T15-17 Windows 视觉验收(5 截图 4 场景全命中)/ #21 screen_shake + tier_colors helper 抽取
- **W6 验证为伪挂账**:#18 flutter build web 被 Isar 阻塞(项目无 web platform target)

### Phase 1-4 早期详条已迁出

- **Phase 1 T01-T18**:`phase1_summary.md` + git log `v0.1.0-phase1` 前 commits
- **Phase 2 T19-T32**:`phase2_summary.md` + git log `v0.2.0-phase2` + merge `5efe8d5`
- **Phase 3 Week 1-3**:`phase3_summary.md` §Week 1-3 + tags `v0.3.0-w1` / `v0.3.0-w3`
- **Phase 3 Week 4-5**:git log `9349626`→`73c1f37` + tags `v0.3.0-w4` / `v0.3.0-w5` + handoff `t58_visual_check_spec` / `t62_visual_check_spec` / `week5_full_closeout`
- **Phase 3 Week 7-8 + Phase 4 W9-W11 详条迁出**(2026-05-15 Phase 5 #2 PROGRESS 行数清理):T63 装备 fixture 10→35(532/532)/ T64 心法 6→21 + 招式 18→63(534/534)/ W9 A 自审 W2 已完整交付 + W6 drift `tower_entry_flow` ref.read 迁(挂账 #31 widget test 死循环)/ W10 战斗结算 Boss 战败被动散功 4 决策点 + `DispelService.applyDefeatPenalty`(544/544)/ W11 victory 接 BattleResolutionService 双端 + 销账 #32(546/546)。详 git log + handoff `week11_*` / `week10_*`
- **Phase 5 #3 第 5 批 J 任务 lib/services/ 收尾**(2026-05-16,详条迁出):lib/services/ 目录消失 / phase2_seed_service → features/debug/application/ + technique_learning → features/cultivation/application/。详 closeout `week15_phase5_3_j_lib_services_cleanup_2026-05-16.md`
- **W14-W15 早段 + W6 架构详条迁出**(2026-05-14 → 2026-05-15):W14-1 vertical slice EncounterDef + EncounterService 0→1 / W14-2 biome+weather 4 维 AND / W14-3-A 35 招池 + W14-3-B DeepSeek 12 events + W14-3-C dialog 节奏 + Codex round1/2 视觉 + VC-EVENT picker / W14-4 DeepSeek audit 45 lore + 23 events orphan / W15 #37 第 1 批 6 挂回 + Codex 详情屏 7/7 + DeepSeek 22 招映射 + Codex round3 dialog 6/6 + EquipmentDetailScreen 显化 lore / #35/#36 销账 / #38 反审撤回 + closeout 数字纠错。**Phase 5 W6 升级**(isar_community 3.3.2 + Riverpod 3.x + nullable provider 链)销账 #23 架构层。tags `v0.4.0-w11` / `v0.5.1-w14` / `v0.3.0-w6`。详 git log + handoff `week14_*` / `week15_*` / `week6_full_closeout_*`
- **W15 主战场 23 段详条迁出**(2026-05-17 W17 行数清理):W15 G+F polish 双销账 / #30 P3 InventoryScreen 物料 Tab(closeout `week15_30_phase3_followup_inventory_material_tab_2026-05-16.md`)/ #30 P3 victory dialog 升层(`week15_30_phase3_followup_victory_dialog_2026-05-16.md`)/ #30 第 3 期 experiencePoints 升层链路(`week15_30_phase3_advancement_2026-05-16.md`)/ G Pen-only T64 CRLF 修救(`week15_g_pen_t64_crlf_fix_2026-05-16.md`)/ #30 第 2 期 内力 + 心法领悟点(`week15_30_phase2_consumption_layer_2026-05-16.md`)/ Phase 5 #3 第 5 批 E+K(`week15_phase5_3_e_k_2026-05-16.md`)/ 第 5 批 I isar_provider 拆分(`week15_phase5_3_isar_provider_split_2026-05-16.md`)/ 第 5 批 C 装备系统 features(`week15_phase5_3_equipment_features_2026-05-16.md`)/ 第 5 批 B 战斗系统 features(`week15_phase5_3_battle_features_2026-05-16.md`)/ 第 4 批 A lib/core 抽公共(`week15_phase5_3_lib_core_extract_2026-05-16.md`)/ 第 3 批 character_panel+inventory+technique_panel UI(`week15_phase5_3_batch3_ui_features_2026-05-16.md`)/ 第 2 批 tower+mainline+encounter(`week15_phase5_3_batch2_features_2026-05-15.md`)/ Phase 5 #2 DDD + 闭关试点销账 #28(`week15_phase5_2_ddd_seclusion_pilot_2026-05-15.md`)/ #30 闭关 3 维度接 service 销账 #30 / §12 待决清单收口方案 A / W15 共鸣强化开锋 + C-1 收尾 / polish + round2 双闭环 / #37 第 2 批挂回 7 条 + W15-r2 fixture / C-2 banner SkillDef.name / Phase 5 #3 第 6 批 lib 目录 finalization 销账 #2(`week15_phase5_3_lib_structure_finalization_2026-05-16.md`)/ Codex round2 全 PASS 销账 #34 + VC15-fresh hotfix `d6509ec`(`codex_w15_victory_dialog_round2_visual_check_2026-05-16.md`)/ §12.1 #7 三流派 v1.4 决议销账 §12.1 #7(`week15_section12_7_school_extra_effects_2026-05-16.md`)。详 git log + handoff/ 各 closeout。
