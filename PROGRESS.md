# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**W17 候选 B framework 落地 + D 双销账 + DeepSeek 派单已发**(2026-05-17,opus high ~1.5h):**B + D 合并一波**。① **D-#17 phase1_tasks §709 笔误**反审撤回(`5400cee`):Mac 端 grep 复审 phase1_tasks.md §463/§464/§709 三处「差 2 → (2.5, 0.3) + 差 3+ → (1.0, 0.05) + 三流打绝顶守方 0.05」全部正确,挂账记忆错误。② **D-#3 riverpod_lint 半销账**(`5400cee`):riverpod_lint 3.1.3 已抛弃 custom_lint 转用 `analysis_server_plugin`,原阻塞「custom_lint 0.8.x 锁 analyzer ^7.5/^8」过时;pubspec.yaml 加 dev_dep `riverpod_lint: ^3.1.3` resolve 通过 + .g.dart 重生 + analyze 0 issues + 759/759;**plugin 启用留 follow-up**(启用需 analysis_options 加 `plugins: riverpod_lint: ^3.1.3` + 3 处 dependency 标注,Phase 5+ 引入 family/scoped override 时再启用)。③ **B framework 6→8 扩 chuXi/qingMingJie**(`9b795a0`):Festival enum 加 chuXi(2026-02-16 春节前一天) + qingMingJie(2026-04-05 既节气又节日,两通道独立) + EnumL10n 2 中文 + numbers.yaml `festivals.days_2026` 2 日期 + 2 处 dartdoc 6→8 / 359→357 天 / 7→9 选项 + festival_service_test 6→8 + enum_localizations_festival_test 6 case→8 case,**761/761** + analyze 0 issues。④ **DeepSeek 派单已发**(`0bb496c`):`docs/handoff/deepseek_w17_festival_extend_dispatch_2026-05-17.md` 239 行,沿 W16 已验证体例,chu_xi_ci_sui(辞岁 fortune+enlightenment)+ qing_ming_yu_si(雨思 enlightenment+constitution)2 文案,encounters.yaml 36→38 + events/<id>.yaml +2 文件,差异化提示(除夕 vs 春节、清明 vs 中秋)+ 清明双重身份不写节气字眼。预计 DeepSeek ~30-45 min。**待 DeepSeek 文案 + Codex Pen 截 2 chip 视觉验收两步收尾**,W17 候选 B 全链闭环。

**W16 节日 encounter 全链闭环 · framework + DeepSeek 文案 + Mac override + Codex 视觉验收 7 PASS**(2026-05-16):**四段一波完成 GDD §12.4 接口预留 + 内容层首批落地里程碑**。① **W16 framework 0→1**(commit `5ea1f60`):Festival enum 6 节日 + numbers.yaml `festivals.days_2026` 公历 hardcode + FestivalConfig + 新 feature lib/features/festival/(service 纯函数 clock injection + 双 provider GameRepository 未加载兜底 null)+ EncounterTrigger.festivalRequired 字段 + encounter_service._checkTrigger AND 新维度 + encounter_hook wire + main_menu _TodayFestivalChip + EnumL10n.festival 6 中文 + UiStrings.mainMenuTodayFestival,**0 数值红线 / 0 战斗装备改 / 0 schema bump**,test +30 → 753。② **DeepSeek 6 节日文案**(commit `5a3a06c`):encounters.yaml 30→36(春节守岁夜 / 元宵观灯 / 端午渡龙舟 / 七夕乞巧 / 中秋月下独酌 / 重阳登高 各 1 entry,fortuneEvent + fortuneRequired=4 + baseProbability=0.5,outcome 全 attributeBonus)+ 6 events/<id>.yaml 文案(opening 5-7 行意象渗透不报节日名 + 3 choices path_a→path_b→skip 水墨克制武侠味),Mac 7 项自检 grep 全 0 命中。③ **Mac DEBUG · 切今日节日**(commit `cdee42e`):`debugFestivalOverrideProvider` NotifierProvider(apply/clear)+ `todayFestivalProvider` 读 override 优先 + Phase2TestMenu 11→12 按钮(SimpleDialog 7 选项 + SnackBar 反馈)+ UiStrings 7 段 debug 文案 — Mac debug build 现场切节日验证 chip 视觉无需调系统时间。test +6 widget + encounter_yaml_test 30→36 + phase2_test_menu_test 11→12。**759/759** + analyze 0 issues + GDD §8.4 加节日独立通道备注。④ **Codex Pen 视觉验收 7 PASS / 0 WARN / 0 FAIL**(commit `9421c55`,closeout `codex_w16_festival_chip_visual_check_2026-05-16.md`):7 张 1280×950 截图(6 节日 chip + 1 baseline)真 GUI 路径,Codex 用 Phase2TestMenu「DEBUG · 切今日节日」入口逐一覆盖,水墨胶囊样式一致 / 中文渲染无方框 / chip 出现未挤压 8 按钮 layout / baseline SizedBox.shrink 不占空间。**工程教训沉淀 memory**:`flutter clean` 后必须先 `dart run build_runner build` 再 `flutter build windows --debug`(wuxia_idle `.g.dart` gitignored,clean 顺手清掉 codegen 产物)→ `feedback_codex_pen_windows_visual_check` 加 W16 实证。**销账 W16 GDD §12.4 全链闭环**:接口预留(framework)+ 内容层(DeepSeek 文案)+ DEBUG 入口(Mac override)+ 视觉证据(Codex 7 PASS)四段完整收口。下波 W17 待用户拍板(候选:Festival enum 扩 chuXi/qingMingJie / mainline+tower victory integration test / 长期挂账冲刺)。

**W15 收尾里程碑回顾(已归档)**(2026-05-16):① Phase 5 #3 第 6 批 lib 目录结构 finalization 销账 #2(closeout `week15_phase5_3_lib_structure_finalization_2026-05-16.md`,723/723);② Codex round2 全 PASS 销账 #34 完整闭环 + VC15-fresh fixture hotfix `d6509ec`(closeout `codex_w15_victory_dialog_round2_visual_check_2026-05-16.md`,722/722);③ §12.1 #7 三流派 extra_effect v1.4 决议 + 代码层全链路销账 § 12.1 #7→§12.2(closeout `week15_section12_7_school_extra_effects_2026-05-16.md`,722/722)。详条迁归档段。


## 已完成(近 W6 起,早期归档见末尾)

- **W15 主战场详条 20 段已归档**(2026-05-17 行数清理):W15 G+F polish 双销账 / #30 P3 InventoryScreen 物料 Tab / #30 P3 victory dialog 升层 / #30 第 3 期 experiencePoints 升层链路 / G 任务 Pen-only T64 fail-fast CRLF 修救 / #30 第 2 期 内力 + 心法领悟点 / Phase 5 #3 第 5 批 E+K / 第 5 批 I isar_provider 拆分 / 第 5 批 C 装备系统 features 迁 / 第 5 批 B 战斗系统 features 迁 / 第 4 批 A lib/core 抽公共 / 第 3 批 character_panel+inventory+technique_panel UI / 第 2 批 tower+mainline+encounter / Phase 5 #2 DDD 整理 + 闭关 feature 试点(销账 #28) / W15 #30 闭关 3 维度接 service(销账 #30) / §12 待决清单收口方案 A / W15 共鸣强化开锋视觉验收 + C-1 收尾 / polish + round2 双闭环 / #37 第 2 批挂回 7 条 + W15-r2 fixture / C-2 outcome banner SkillDef.name。详条迁出归档段 `### W14-W15 详条迁出 2026-05-17`。
## 已知偏差 / 挂账事项

- ~~2. **lib/ 目录结构**~~(**2026-05-16 Phase 5 #3 第 6 批销账**:lib/ 100% 对齐 CLAUDE.md §3 — core/{domain,application}/ + data/{defs/,*.dart,isar_provider} + features/{14 feature 含新增 main_menu / narrative}/ + shared/{effects,theme,utils,strings.dart}/ + main.dart;lib/ui/ + lib/utils/ + lib/providers/ + lib/data/models 4 目录消失;9 commit + 1 rmdir-only step + 0 codegen regen;closeout `week15_phase5_3_lib_structure_finalization_2026-05-16.md`)
- ~~3. **`riverpod_lint` 未引入**~~(**2026-05-17 W17 D-#3 半销账**:`riverpod_lint 3.1.3` 已抛弃 custom_lint 转用 `analysis_server_plugin`,原阻塞描述过时。本批 pubspec.yaml 加 dev_dep `riverpod_lint: ^3.1.3` resolve 通过 + .g.dart 重生 + 759/759 + analyze 0 issues。**plugin 启用留 follow-up**:启用需 analysis_options.yaml 加 `plugins: riverpod_lint: ^3.1.3` 段,启用后将出 3 处 dependency 标注 warning(tower_providers `towerProgress` 加 `@Riverpod(dependencies: [])` + tower_floor_list_screen ConsumerStatefulWidget 加 `@Dependencies([towerProgress])` + tower_entry_flow runTowerFlow 函数加 `@Dependencies([towerProgress])`)。Phase 5+ 引入 family/scoped override 时再启用)
- ~~6. **GDD §5.3/§5.6 公式系数 vs numbers.yaml**~~(**2026-05-16 v1.6 销账**:GDD §5.3 装备攻击 ×8 → ×1.0 + §5.6 内力 ×5 → ×0.7,各加历史脚注;CLAUDE.md §6 镜像公式块同步对齐 + 升 v1.6;代码以 yaml 为准早已平衡到位无代码改动)
- ~~7. numbers.yaml 节气列表混入「中秋」~~(**2026-05-15 §12 收口销账**:本批方案 A 删中秋 + 补 4 节气(雨水/谷雨/处暑/小雪)凑 12 节气,均为节气非节日)
- ~~8. CLAUDE.md §12 收口剩 1 条~~(**2026-05-16 v1.5 §12.1 真硬阻塞清零**):#10 师承遗物 4 子项决议落 numbers.yaml 4 字段(`transfer_trigger=ascend_to_wusheng` / `multi_disciple_allocation=player_pick` / `stack_across_generations=false` / `conflict_slot_resolution=auto_swap`)。代码层 Phase 5+ 师徒升级时按此实装,本批仅规则层锚定。**13 条原始待决全 100% 收口**,详 §12.2 归档
- 9/11. **T05/T07 验收**:Mac 无 Xcode 跑不了 desktop,留 Windows 首跑验
- 10. **yaml key 命名约定差异**:numbers.yaml snake_case,内容 yaml camelCase,按文件类型隔离不冲突
- ~~17. **phase1_tasks T12 §709 笔误**~~(**2026-05-17 反审撤回**:Mac 端 grep 复审 phase1_tasks.md §463「差 2 大境界 → (2.5, 0.3)」+ §464「差 3+ → (1.0, 0.05)」+ §709「三流满员去打绝顶满员…守方 0.05 修正」三处全部正确(三流 index=1 / 绝顶 index=4 差 3 阶,0.05 是对的)。**phase1_tasks 实际无笔误**,本挂账条目早期记忆错误)
- ~~28. 闭关 widget e2e test 缺失~~(**2026-05-15 Phase 5 #2 销账**:3 屏 Consumer 化后 `_FakeSeclusionService implements SeclusionService` + `seclusionServiceProvider.overrideWithValue(fake)` 绕过 native Isar zone,4 e2e widget test 全过(list→setup→active→result 导航 + confirm dialog 双路径)。W6 drift 5 轮探路无解的"fake_async vs native Isar zone 边界"真解 = Consumer 化把边界封死在 provider override 之下,fake_async 不再必要)
- ~~30. 闭关 3 个扩展维度未接 service~~(**2026-05-15 销账**:`SeclusionService.computeOutputs` 已接 technique_learn_rate / internal_force_growth / 节气日 +30% / 子时 +20%(只乘内力维度,修原 bug);RetreatOutputs typedef 加 techniqueLearnPoints / internalForcePoints;numbers.yaml 加 base_internal_force_per_hour=5 / base_technique_learn_per_hour=0.5 锚点。test +6,649/649。**正午阳刚 +20% 留 §12.1 #7 实装阻塞**,本批不接)
- 31. **main_menu「问鼎九霄」widget test 写不出**(2026-05-13 W9 自审踩坑):`pumpAndSettle` 死循环,多 provider+Navigator 链异步 future + 帧 ticker 冲突。已有 11 个 tower widget test 覆盖核心,nav 路径不再硬塞
- ~~34. #10 stage drop 视觉验收完整闭环~~(**2026-05-16 Codex round2 全 PASS**):W15 P3 同期 + 后续 A/B 三批 + Codex E/round2 真机视觉验收 5 张截图收口。Codex round2 closeout `codex_w15_victory_dialog_visual_check_2026-05-16.md` **6 PASS / 1 WARN / 0 FAIL**(WARN = 增量 build 缓存假象工程教训,非产品 bug,已沉淀 memory):A1/B1/C1 drop banner 中文「磨剑石 ×N」✅(F1 ItemType.fromDefId 修复生效)+ A1/B1/C1 升层 3 行 banner ✅(F2 VC15-fresh seed 解锁 + 升层链路验证 yaml.experience_to_next=50 → qiMeng→ruMen→shuLian→jingTong 3 层连升)+ A2 dialog→narrative→encounter hook 链路完整 + D1/D2 物料 Tab 真硬截图首达(D2 累积态磨剑石 ×104 精确匹配 dropTable A1+B1+C1 累积值 +4)
- ~~35. 35 装备 0 lore 文案 Demo 硬缺口~~(**2026-05-15 W15 销账**:DeepSeek 35 yaml × 75 段交付 commit `7aea49d`,GDD §6.6 0→75 首达标,1 错字已修)
- ~~36. insights ↔ encounter_skill 显式映射缺~~(**2026-05-15 W15 销账**:Mac 端 `SkillDef.narrativeInsightId` nullable 已落,encounter_skills.yaml `ting_yu_jian` 首条真实映射已填,test +4 全过 614/614)
- 37. **8 events orphan 剩余可后续挂回**(原 23 → 第 1 批 6 + 第 2 批 7 + C-1 收尾 2 → 余 8):C-1 收尾 2 条(huang_miao_jiu_seng → long_yin tier 7 / jiu_lou_jue_yin → wu_ming tier 7)。剩余 8 条主题不适配(duan_qiao_can_yue/gu_chuan_deng_ying/huang_cun_yao_ren/huang_yuan_yi_zhong/jiang_xin_ye_hua/qing_lou_can_meng/lao_jing_hui_xiang/yu_zhong_qiao_men),心境/江湖故事/邪门调子无对应武学,留 _archive/ 不动
- ~~38. 像样货 5 件 lore 缺第 2 段~~(**2026-05-15 反审撤回**:整批闭环后 Mac 端 grep 复审 35 件 yaml 实测**75 段不是 70 段**(closeout §3.6 各阶罗列加和 5+5+10+10+15+15+15 = 75 算成 70)。**像样货 5 件 1 段是 W15 #35 派单 §3.2 明文规定体例**(`week15_deepseek_dispatch_35_lore_2026-05-15.md:57` "第 2 阶 · 像样货 · 各 1 段"),DeepSeek 没漏配。Codex 装备详情屏 04 WARN 是 spec 误抄错误 PROGRESS 数字,实际**详情屏 7/7 PASS**)
- ~~39. **物料 Tab 行右侧 defId 显示**~~(**2026-05-16 销账**:`_MaterialRow` 删 raw `item.defId` Text widget,行内仅保留本地化「磨剑石 × N」/「心血结晶 × N」,Expanded 简化为直接 Text;widget test line 201 期望反转 `findsOneWidget` → `findsNothing` + reason 注;723/723 全过)

> 已销账条目(#1/#2/#3/#4/#5/#6/#8/#12/#13/#14/#15/#16/#17/#18/#19/#20/#21/#22/#23/#24/#25/#26/#27/#28/#29/#30/#32/#34/#35/#36/#39)详见末尾归档。

## 下一步

**W17 候选 B 待 DeepSeek 文案 + Codex 视觉验收两步收尾**。DeepSeek 派单已发(commit `0bb496c`),DeepSeek closeout 后 Mac 端 pull + 改 encounter_yaml_test 36→38 + 派 Codex Pen 截 2 chip 截图 → W17 候选 B 全链闭环。**已用户拍板,本会话顺势把 B + D 合一波**。后续候选 **C**(sonnet 1-2h 易撞 #31 长期低优先) / **E**(opus xhigh 4h+ 师徒系统 Phase 5+ 跨模块大动作)。

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
