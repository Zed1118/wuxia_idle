# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

**Phase 4 W15 开局,A + B 双销账 + LoreLoader 接入 + EquipmentDetailScreen 显化 lore + Codex round3 6/6 PASS + DeepSeek 34 招映射 22 招交付 13 留空 + Codex 装备详情屏 6/7 PASS 1 WARN + #37 部分挂回 6 条 + 像样货 lore 段数审计**(2026-05-15)。**A: #35** 35 装备 lore 75 段销账(GDD §6.6 0→75 首达)。**B: #36** SkillDef.narrativeInsightId nullable + ting_yu_jian 首条映射销账。**LoreLoader 接入**:`lib/data/lore_loader.dart` + 35 yaml `presetLoreIds` 自洽 + GameRepository fail-fast 校验,test +7。**EquipmentDetailScreen**:新屏(信息卡 + FutureBuilder + 段落 scroll + 强化/开锋分流)+ EnhanceDialog 加 initialTab + InventoryScreen Navigator.push,test +5,**626/626**,analyze 0 issues。**C: Codex round3 dialog 视觉验收 6/6 PASS**:du_kou_chun_yu / gu_dao_xue_ji / lu_pang_xian_xian / qun_xia_tu / xiao_zhen_wen_yi / ye_xing_xun_dao 12 张主截图(opening + outcome 各 6)无错字 / 网文腔 / UI 数值泄露,closeout `6809eba`。Codex 反馈 r3-5 标题 OCR 看成"小镇问翁"实为「小镇问翳」(yì,医字异体),非文案 bug;"翳"字生僻记入 DeepSeek polish 候选。Codex 派单 §4.2 schtasks Access denied 改 Start-Process 成功(更新 Pen 视觉验收 memory)。**DeepSeek 34 招 narrativeInsightId 映射** closeout `38b8f26`:22/35 招填(ting_yu_jian + 新增 21)/ 13/34 留空 / 13 insight 未被引用 / 无多招重复引用 — 符合派单 §6 预期 15-25,质量优于数量纪律守住。映射决策 21 条覆盖 long_yin / yi_jian / ice_break / qing_feng_jian / xuan_bing / jian_yi / wu_ming / water_qi / shan_he / chen_xin / drill_strike / xuan_yin / fei_xian / night_strike / xuan_jian / huo_quan / pai_yun_zhang / huo_du / jin_gang / tian_dao / jian_bu;留空 13 条覆盖基础步法/呼吸/暗器/拳法/火电类(insights 无对应主题)。Mac 端跑测试 + analyze 验:**627/627**(W15 #36 原"除 ting_yu_jian 外全 null"红线测试改写为"引用 ↔ 35 insights 自洽"+ 新增 ting_yu_jian 锚点保护测试,净 +1),analyze 0 issues。

## 已完成(近 W6 起,早期归档见末尾)

- **Phase 4 W15 C-2 收尾 奇遇 outcome banner 显 SkillDef.name**(2026-05-15,opus):W14-3-A 收尾 C-2 子项。`encounter_dialog.dart` `showEncounterOutcomeBanner` UnlockSkillApplied 摘要从 raw skillId(`skill_encounter_ting_yu_jian`)升级为 SkillDef.name 中文招名(「听雨剑」)。`_resolveSkillName` 通过 `GameRepository.instance.skillDefs[skillId]?.name ?? skillId` lookup,GameRepository 未加载 / id 未注册时降级回 raw id(test fixture 不全 / yaml race 兜底,无 throw)。`test/ui/encounter/encounter_outcome_banner_test.dart` 新建 4 widget test(已知 skill name / 未注册降级 / AttributeBonus / NoneOutcome),**631/631**,analyze 0 issues。C-1(扩 outcome 引用 tier 1-2/7 池)留下波蹔 DeepSeek polish closeout 后派"新 encounter 套餐"。
- **Phase 4 W15 #38 反审撤回 + closeout 数字纠错 + memory 沉淀 3 条**(2026-05-15,opus):W15 整批闭环后开局即查,Mac 端复审 35 件 yaml 段数撞二重错:① closeout §3.6 自审"实测 70 段"是加和算术错,5+5+10+10+15+15+15 = **75 段**(实际派单全量交付);② 像样货 5 件 1 段是 W15 #35 派单 §3.2 明文规定"各 1 段",**DeepSeek 没漏配**;③ Codex 装备详情屏 04 WARN 是 spec 抄了错误 PROGRESS"预期 2 段",纠正后**详情屏 7/7 PASS**。**挂账 #38 撤回**。DeepSeek polish 派单从三合一减为二合一(35 招 description + 翳字),独立 dispatch 文档 `docs/handoff/deepseek_w15_polish_dispatch_2026-05-15.md`。memory 沉淀 3 条:`reference_pen_wuxia_flutter_run` 补 schtasks Access denied → Start-Process fallback / 新建 `feedback_red_line_test_semantics`(W15 #36 红线被自己写死的教训,写约束语义不写瞬时事实) / 新建 `feedback_closeout_numbers_grep`(closeout 数字必 grep 实测,自审 grep 后加和也要复测,本会话写完 memory 立刻撞二重错的活实例)。
- **Phase 4 W15 Codex 装备详情屏视觉验收 7/7 PASS**(2026-05-15,Codex Pen,~~原报 6/7 PASS 1 WARN~~ 反审纠正):派单 `2a4c19a` → closeout `e67659c`,7 张目标截图齐(`docs/screenshots/w15_equipment_detail/`):01 仓库列表 4 tier 分组 PASS / 02 利器龙泉剑 2 段 PASS / 03 好家伙青锋剑 2 段 PASS / **04 像样货钢刀 1 段 PASS**(原 WARN 已纠正 — 派单 §3.2 规定像样货各 1 段)/ 05 寻常货布衣 1 段 PASS / 06 强化 Tab 0 PASS / 07 开锋 Tab 1 PASS。视觉/节奏/工程三层反馈:信息卡 chip+三围层级清楚 / tier 颜色映射明显 / 段间「· · ·」分隔稳定 / Navigator.push 详情屏过渡自然 / EnhanceDialog initialTab 分流正确 / scroll 无卡顿。原 04 WARN 是 Mac 端装备详情屏派单 spec 误抄了错误 PROGRESS 的"预期 2 段",反审纠正后实际 PASS。
- **Phase 4 W15 像样货 lore 段数审计反审纠错**(2026-05-15,W15 整批闭环后开局即查):整批闭环 closeout §3.6 自审"实测 70 段"双重错。① 加和算术错:寻常货 5×1=5 / 像样货 5×1=5 / 好家伙 5×2=10 / 利器 5×2=10 / 重器 5×3=15 / 宝物 5×3=15 / 神物 5×3=15 加起来是 **75 段不是 70 段**(罗列对、加和错)。② 像样货 5 件 1 段不是 DeepSeek 漏配,是 W15 #35 派单 §3.2 明文规定:`week15_deepseek_dispatch_35_lore_2026-05-15.md:57` "第 2 阶 · 像样货(三流境界开放,主线 ch2)· 各 1 段"。所以**实测 75 段 = 派单全量交付,无缺口**。Codex 装备详情屏 04 像样货钢刀 WARN 是 spec 抄了错误 PROGRESS"预期 2 段"导致,实际 PASS — 装备详情屏整体 **7/7 PASS**。**挂账 #38 撤回**,A 派单从 3 项改 2 项(只剩 35 招 description + "翳"字 polish)。教训:写完 `feedback_closeout_numbers_grep.md` memory 立刻复审撞二重错,memory 教训的活实例。
- **Phase 4 W15 #37 23 orphan events 部分挂回 6 条**(2026-05-15,opus):W14-4 audit 暴露 23 orphan events 文案完整但加载 0 命中,本会话 B1 方案挂回 6 条雨雪夜主题(数据/文案双端 Mac 独作:文案 _archive/ 已有,Mac 端写 trigger + outcome)。`git mv _archive/<id>.yaml events/<id>.yaml` × 6 + encounters.yaml 加 6 entry(15 → 21):**xue_ye_gu_qin** (techniqueInsight, temple+snow+night+fortune≥6, unlock xuan_jian tier 3 + enlightenment +1) / **feng_xue_gu_dian** (fortuneEvent, inn+snow+fortune≥3, constitution +1 + fortune +1) / **ye_du_gu_chuan** (fortuneEvent, dock+night+fortune≥4, constitution +1 + enlightenment +1) / **han_mei_ying_xue** (techniqueInsight, mountainPath+snow+fortune≥5, enlightenment +1 + unlock xuan_yin tier 4) / **xing_chen_wu_dao** (techniqueInsight, mountainForest+night+clear+fortune≥8 ★ 高门槛, unlock tian_dao tier 7 ★ + enlightenment +2) / **qiu_ye_wei_qi** (fortuneEvent, teaHouse+night+fortune≥4, fortune +1 + enlightenment +1)。3 unlock + 3 attributeBonus 半对半,unlock 3 招 (xuan_jian/xuan_yin/tian_dao) 跨 tier 3/4/7 均散,均已被 DeepSeek 22 招 narrativeInsightId 映射(内容统一性高)。**encounter_yaml_test** "15 条全解析" 红线测试更新到 21 + 加 6 条核对断言,**627/627** 仍全过,analyze 0 issues。Demo 奇遇总数 15 → 21,接近 GDD §8.4 下限 20。**#37 挂账由"23 全悬"改为"剩 17 待评估"**,后续会话或下波 DeepSeek 派单评估悬崖/青楼/荒原等 17 条主题。
- **Phase 4 W15 DeepSeek 34 招 narrativeInsightId 映射 22 招交付**(2026-05-15,DeepSeek Pen):W15 #36 销账后剩余 34 招的语义映射任务。派单 `8cb6d18` → DeepSeek `0fbe572` 编辑 + closeout `38b8f26`。**22/35 映射**(ting_yu_jian + 新增 21)/ **13/34 留空**(基础步法/呼吸/暗器/拳法/火电类无对应主题保留独立性)/ **13 insight 未被引用**(2 体系独立的另一面) / **无多招重复引用**。Mac 端测试更新:原 W15 #36 红线测试"除 ting_yu_jian 外 narrativeInsightId 全 null"改写为"每条 narrativeInsightId 引用必须在 35 篇 insights 自洽"+ 新增"ting_yu_jian 仍是映射锚点(#36 不退)"保护测试,净 +1。**627/627**,analyze 0 issues。Mac 端无 Python yaml 解析校验环境,通过 Dart fromYaml + test 红线兜底。Mac 端只验 yaml 解析 + 自洽,不评判 21 条映射的具体语义对错(信任 DeepSeek 文学判断,W14-4 audit 已锚定 2 体系独立性纪律)。
- **Phase 4 W15 Codex round3 dialog 视觉验收 6/6 PASS**(2026-05-15,Codex Pen):W14-2/W14-3-B 新增 12 条 events 文案的视觉验收,Phase2TestMenu「VC-EVENT · 触发奇遇 debug」按钮 + encounter_debug_picker 强制触发 6 条(du_kou_chun_yu/gu_dao_xue_ji/lu_pang_xian_xian/qun_xia_tu/xiao_zhen_wen_yi/ye_xing_xun_dao)× opening + outcome = 12 张主截图(`docs/screenshots/w15_round3/r3-Na/Nb`),全 PASS。closeout `6809eba` 反馈:① 文案层 0 错字 / 0 乱码 / 0 网文腔 / 0 UI 数值句,1280×900 dialog 可读气质区分明显;② 节奏层 opening 弹窗淡入淡出 + opening↔outcome 切换流畅,12 张稳定帧无截字 / 漏底 / 按钮错位;③ 工程层 schtasks /RU INTERACTIVE /RL HIGHEST Access denied → 改用 RDP session 直 Start-Process 启 Debug exe 成功(派单 §4.2 写的 schtasks 路径走不通,memory 需更新);④ CopyFromScreen 截图含窗口标题栏点击坐标须+20px 偏移;⑤ debug picker 底部 snackbar 短暂挡贴底条目 tile。Codex OCR 把 r3-5「小镇问翳」(yì,医字异体)看成「小镇问翁」属 OCR 误读非文案 bug,但"翳"字生僻可记入 DeepSeek polish 候选清单(非强制)。round3 验收口完,W14-3 整批的 Codex 视觉验收 round1/2/3 全闭环。
- **Phase 4 W15 EquipmentDetailScreen 显化 lore**(2026-05-15,opus):W15 LoreLoader 接入后下一步,75 段 lore 从"加载层 + 校验"到 UI 可见。新建 `lib/ui/inventory/equipment_detail_screen.dart`(Scaffold + AppBar + 信息卡 tier chip/slot chip/school chip/师承遗物 chip/三围/+N/共鸣度阶段/战斗次数 + FutureBuilder<LoreContent?> 包 LoreLoader.load 异步 + ListView scroll 渲染 default_lore 多段含「◇ 典故 ◇」标题 + 段间「· · ·」分隔 + 底部 [强化]/[开锋] 按钮分流)。EnhanceDialog 加 `initialTab` 可选参数(0=强化 / 1=开锋,详情屏底部按钮按需切 Tab)。InventoryScreen row.onTap def 非空时 `Navigator.push(EquipmentDetailScreen)`,def 空(fixture / 未知 defId)兜底仍直弹 EnhanceDialog 不破坏现有 widget test。**lore 消费纯 UI 层**:`Equipment.defId → EquipmentDef.presetLoreIds.first → LoreLoader.load`,**不动 Equipment / Isar / drop / craft / Equipment.lores 字段**(W15 LoreLoader 接入纪律延续:preset 按需读 yaml,Isar 留给"延续典故"动态追加)。LoreLoader 注入 widget 通过 optional `loreLoader` 参数,生产路径默认 `LoreLoader.load`,widget test 传 fake loader 不接 rootBundle。test +5(基础信息卡渲染/lore 3 段全显含 2 分隔符/loader placeholder 兜底「典故待补」/presetLoreIds 空 loader 不调用「典故待补」/底部强化按钮 tap 弹 Dialog),**626/626**(W15 LoreLoader 621 → +5),analyze 0 issues。
- **Phase 4 W15 #35 35 装备 lore 文案 75 段交付**(2026-05-15,DeepSeek 主):派单 commit `d929875`,DeepSeek batch1 `77b6511`(寻常货 5 件)+ batch2 `7aea49d`(像样货~神物 30 件)+ closeout `f6382aa`。35 件装备每件 1/2/3 段(按阶位)共 **75 段**首达 GDD §6.6 50-80 段。2 件完全同名直接迁用(qing_feng_jian / jin_si_jia)+ 2 件师承遗物按 master_legacy 体例(锦袍秦门衬里绣字 / 龙泉剑女子藏纸 + 「剑不说话,但剑记得」)+ 神物级 3 段文学性显著(天问剑·屈原/血莲鞭·苗寨血藤)。Mac 抽审发现 1 错字「那那道」→「那道」已修。当前 lore 无加载机制(`EquipmentDef.presetLoreIds` 字段在 `presetLoreIds: []` 全空,GameRepository 无 lore loader),本批属内容备料层,等装备详情页 / 江湖见闻录功能落地时再接入加载。**销账 #35**。
- **Phase 4 W15 LoreLoader + presetLoreIds 接入**(2026-05-15,sonnet):W15 #35 暴露的"75 段 lore 0 加载机制"硬缺口。新建 `lib/data/lore_loader.dart`(LoreContent / LoreSegment 纯 Dart class + LoreLoader.load 按需,沿 NarrativeLoader / EncounterEventLoader 体例 placeholder 兜底)+ 35 件 equipment.yaml `presetLoreIds: []` → `[<装备 id>]`(perl 一行批改 + py 自洽核验)+ GameRepository.loadAllDefs 末尾加 async `_validatePresetLoreReferences`(yaml 缺失 / id 不自洽 / default_lore 空 → StateError fail-fast,test fixture presetLoreIds 空时跳过)。**preset 按需加载不写 Isar**(`Equipment.lores: List<Lore>` 留给"延续典故"动态追加,语义隔离)。test +7(6 LoreLoader 单测 + 35 yaml 真实加载红线),**621/621**。装备实例化路径**未动**,等装备详情页 UI 落地时再做。
- **Phase 4 W15 #36 SkillDef.narrativeInsightId nullable 映射字段**(2026-05-15,opus):W14-4 audit 暴露 insights(35 篇 `move_insight_*` 中文诗意命名)vs encounter_skills(35 招 `skill_encounter_*` 拼音功能命名)2 体系独立、命名 1/35 巧合。Mac 端在 SkillDef 加 `narrativeInsightId: String?`(纯 Dart class 不入 Isar,无 schema 升版),`fromYaml` 读 nullable 字段,encounter_skills.yaml `ting_yu_jian` 那条加 `narrativeInsightId: ting_yu_jian` 作首条真实映射(W14-4 audit 唯一已匹配,其余 34 招留空待 DeepSeek 后续填)。test +4(2 fromYaml case + 2 yaml 红线),**614/614**。**销账 #36**。
- **Phase 4 W14 整批闭环 tag `v0.5.1-w14`**(2026-05-14 to 2026-05-15,xhigh):① **W14-3-A** 奇遇专属 skill 池(`data/encounter_skills.yaml` 35 招 / 7 阶 × 5,SkillDef 加 nullable tier + isEncounterSkill + Character.equippedEncounterSkillId schema 0.6.0→0.7.0 + EncounterService.equipEncounterSkill sealed result GDD §5.3 三系锁死 + BattleCharacter 3+1 + EncounterSkillSection widget,+17 test);② **W14-3-B** DeepSeek 12 条 events 文案;③ **W14-3-C** EncounterDialog 节奏(入场 fade 500ms + opening↔outcome AnimatedSwitcher 420ms FadeTransition)+ Codex Pen round1 视觉验收 6 张截图 5 PASS + 1 WARN(fade-in 中间帧抓不到非 bug);④ `seedVisualCheckW14_3` fixture(预 unlock tier 1-7 各 1 + 大弟子 erLiu 装 tier 3 + Phase2TestMenu「VC14_3」按钮);⑤ **round2** Codex Pen 完整 EncounterSkillSection 验收 4/4 PASS(slot 填充 / bottom sheet 7 招 / 师徒 3/4/5 lock 验证 + 切角色 TabBar T56 早有 + bottom sheet 第 7 项 1280×900 略贴底建议加 padding);⑥ **VC-EVENT 强制触发 debug picker**(`lib/ui/debug/encounter_debug_picker.dart`,Phase2TestMenu 第 8 按钮,绕过软概率 — 为下次 dialog 视觉验收做工具);⑦ **W14-4 DeepSeek audit**(lore 45 orphan 全归档 `_archive/`/ events 23 orphan 归档 / insights vs encounter_skills 1/35 match 推荐保留 2 体系 / IDS_REGISTRY.md 143→326 + 补 W14-2/W14-3 新 ID v1.2)。**610/610**(W14-2 590 → +20 net),analyze 0 issues。详 `docs/handoff/week14_3a_encounter_skill_pool_2026-05-14.md` / `codex_w14_3_round2_visual_check_2026-05-15.md` / `deepseek_audit_w14_4_2026-05-15.md`
- **Phase 4 W14-2 C 任务 biome/weather + 闭关 idle tick + tower 接入**(2026-05-14,high):W14-1 单 school 维度扩到 4 维 AND(school + biome 60+ values 累计 + weather 5 values 累计 + fortune)。EncounterBiome 15 值 / EncounterWeather 5 值枚举,stages.yaml 15 关 + numbers.yaml 5 闭关图 全标 biome/weather。SeclusionService 注入 encounterService 闭关收功喂 actualHours×60 累计(分两 txn,嵌套 writeTxn 限制)。runEncounterHookAfterVictory 抽到 encounter_hook.dart 共享,stage + tower 双端 victory 都接奇遇。encounters.yaml 3→15 条。schema 升 0.5.0→0.6.0。18 新 test,**590/590**(W14-1 572 → +18)。详 handoff `week14_2_biome_weather_idle_tick_2026-05-14.md`
- **Phase 4 W14-1 C 任务 vertical slice tag v0.4.0-w11**(2026-05-14,xhigh):GDD §7.2 奇遇/武学领悟系统 0→1。新建 `EncounterDef` + 4 枚举 + `EncounterProgress` Isar collection + `EncounterService`(recordKill / evaluateTriggers fortune 软概率 / applyOutcome lifetime cap 5) + 3 条 encounters.yaml + UI 三段式 dialog + 战斗 victory hook。20 新 test,**572/572**(W13 552 → +20)。
- **Phase 5 W6 升级 + 架构重构 tag v0.3.0-w6**(2026-05-14):isar→isar_community 3.3.2 / flutter_riverpod 3.x / riverpod_annotation 4.x / riverpod_generator 4.x / analyzer 5.x→9.x。8 个有 Isar 依赖的 service 改实例化 + 构造函数接 Isar;新 `IsarSetup.instanceOrNull` + nullable isarProvider + 9 个 service provider,widget test 自动短路。**销账 #23**(架构层面)。530/530 测试,详条 `docs/handoff/week6_full_closeout_2026-05-14.md`
- **Phase 3 Week 7 T63 装备 fixture 扩 10→35 件 + 覆盖度红线**(2026-05-13):equipment.yaml 7 阶 × 5 件重写;GameRepository `_enforceEquipmentRedLines`(单件 baseAttackMax ≤ 2000 + 三件套覆盖)。test +2,532/532
- **Phase 3 Week 8 T64 心法扩 6→21 本 + 招式扩 18→63 招 + 覆盖度红线**(2026-05-13):techniques.yaml 7 阶 × 3 流派 + skills.yaml 21×3=63 招;GameRepository `_enforceTechniqueRedLines`(组合 + 3 招 type + parent 指向)。test +2,534/534
- **Phase 4 W11 victory 路径接 BattleResolutionService 双端 + 销账 #32**(2026-05-13,xhigh,commit `a2de8a2`):W10 自审发现 `BattleNotifier.resolveBattle` 全仓库 0 调用,主线/爬塔 victory 装备 battleCount/心法 skillUsage/主修升层全未生产路径落地。`BattleResolutionService.resolve` stageDef 改 nullable;主线 `_applyVictoryResolution` + 爬塔 `_applyTowerVictoryResolution`,与 W10 体例对齐;test +2,544→546
- **Phase 4 W10 战斗结算扩展 Boss 战败被动散功**(2026-05-13,xhigh,commit `4e59e9b`):四决策点拍板:① 仅 Boss 关 ② 不掉装备 ③ 主修「无换修」散功(IF×0.5 + progress×0.5 + layer 重算,境界不动) ④ 损失摘要走 NarrativeReader topBanner。numbers.yaml `techniques.defeat` 段 + DispelService.applyDefeatPenalty + _DefeatLossBanner widget。test +10,534→544
- **Phase 3 Week 2 T42-T46 详条补录 + Week 9 A 自审 + W6 drift 收尾**(2026-05-13):自审发现 W9 候选 A「爬塔 UI 串联」实际在 W2 已交付完整(commits `41530aa`-`0b25229` merge `74d30bd` v0.3.0-w2,11 tower widget test);本会话仅做 W6 drift 收尾(`tower_entry_flow.dart` `_persistDrops` 迁 `ref.read(isarProvider)`)。挂账 #31 widget test 死循环已记。534/534

## 已知偏差 / 挂账事项

- 2. **lib/ 目录结构**:CLAUDE.md 写 DDD,实际用 phase1_tasks 的 flat。Phase 5 整理
- 3. **`riverpod_lint` 未引入**(W6 重评估):custom_lint 0.8.x 锁 analyzer ^7.5/^8 与 link 4.x ^9 互斥,等 custom_lint 升级
- 6. **GDD §5.3/§5.6 公式系数 vs numbers.yaml**:GDD 字面 ×8/×5 是「口误」,代码以 yaml 平衡值为准
- 7. **numbers.yaml 节气列表混入「中秋」**:中秋是农历节日不是节气,GDD 没明确 24 节气,待定
- 8. **CLAUDE.md §12 待人类决策清单 13 条**:境界/修炼度层重名等,实现到对应位置时按需提问
- 9/11. **T05/T07 验收**:Mac 无 Xcode 跑不了 desktop,留 Windows 首跑验
- 10. **yaml key 命名约定差异**:numbers.yaml snake_case,内容 yaml camelCase,按文件类型隔离不冲突
- 17. **phase1_tasks T12 §709 笔误**:差 2 守方 0.05 错(实际差 2 守方=0.3,差 3+ 才 0.05),「必败」语义仍成立
- 28. **闭关 widget e2e test 缺失**(2026-05-13 xhigh 5 轮探路无解):W6 后 service 注入完成但 3 屏(list/setup/active)仍走 `IsarSetup.instance`(W6 drift)。`fake_async vs native Isar zone 边界`不可解,真解需 ≈ Phase 5 #2 DDD 级(3 屏 Consumer 化 + service interface),留 Pen 视觉验收兜底
- 30. **闭关 3 个扩展维度未接 service**(§12 #5 收口留尾):numbers.yaml retreat 已配 technique_learn_rate / internal_force_growth / 节气日 / 正午阳刚,但 `seclusion_service.computeOutputs` 未消费;依赖 §12 #7 节气清单 + 农历库
- 31. **main_menu「问鼎九霄」widget test 写不出**(2026-05-13 W9 自审踩坑):`pumpAndSettle` 死循环,多 provider+Navigator 链异步 future + 帧 ticker 冲突。已有 11 个 tower widget test 覆盖核心,nav 路径不再硬塞
- 34. **#10 stage drop 视觉验收未取得硬截图**(2026-05-14 Codex v4):RDP 高度 + 1280×900 窗口下 Codex 主菜单底部入口/滚动操作不稳定,跑了 stage_01_01 victory 但没成功进库存页拍到新增装备。代码层 service test 兜底验证 dropTable 配置生效(`game_repository_test` line 124+)。后续视觉验收建议给 Pen 配 ≥1080 屏幕高 + 库存页快捷入口
- ~~35. 35 装备 0 lore 文案 Demo 硬缺口~~(**2026-05-15 W15 销账**:DeepSeek 35 yaml × 75 段交付 commit `7aea49d`,GDD §6.6 0→75 首达标,1 错字已修)
- ~~36. insights ↔ encounter_skill 显式映射缺~~(**2026-05-15 W15 销账**:Mac 端 `SkillDef.narrativeInsightId` nullable 已落,encounter_skills.yaml `ting_yu_jian` 首条真实映射已填,test +4 全过 614/614)
- 37. **17 events orphan 剩余可后续挂回**(原 23 → W15 已挂 6 → 余 17):W15 #37 B1 方案挂回 6 条(xue_ye_gu_qin / feng_xue_gu_dian / ye_du_gu_chuan / han_mei_ying_xue / xing_chen_wu_dao / qiu_ye_wei_qi),雨雪夜主题优先 + 3 unlock(xuan_jian/xuan_yin/tian_dao)+ 3 attributeBonus。剩余 17 条(悬崖/青楼/荒原/古船/古井等主题)留后续会话评估
- ~~38. 像样货 5 件 lore 缺第 2 段~~(**2026-05-15 反审撤回**:整批闭环后 Mac 端 grep 复审 35 件 yaml 实测**75 段不是 70 段**(closeout §3.6 各阶罗列加和 5+5+10+10+15+15+15 = 75 算成 70)。**像样货 5 件 1 段是 W15 #35 派单 §3.2 明文规定体例**(`week15_deepseek_dispatch_35_lore_2026-05-15.md:57` "第 2 阶 · 像样货 · 各 1 段"),DeepSeek 没漏配。Codex 装备详情屏 04 WARN 是 spec 误抄错误 PROGRESS 数字,实际**详情屏 7/7 PASS**)

> 已销账条目(#1/#4/#5/#12/#13/#14/#15/#16/#18/#19/#20/#21/#22/#23/#24/#25/#26/#27/#29/#32/#35/#36)详见末尾归档。

## 下一步

W15 整批闭环 tag `v0.5.2-w15`(2026-05-15)。**整批 closeout 见 `docs/handoff/week15_full_closeout_2026-05-15.md`**(§5.5 修正版 + #38 反审撤回详 §3.6)。下波候选:
- **等 DeepSeek polish closeout**(派单已发 `deepseek_w15_polish_dispatch_2026-05-15.md`,二合一:35 招 description + 翳字 polish,~1.5-2h)
- **C-1 收尾 扩 outcome 引用 tier 1-2/7 池**(DeepSeek closeout 后,新 encounter 套餐:Mac 数值 + DeepSeek 文案;tier 1-2 池 0 引用 / tier 7 池 4/5 未引用,缺口大)
- **Pen 端视觉验收装备详情屏**(真机渲染需 Pen flutter run + InventoryScreen 进装备 → 详情屏看 lore 段排版 + 强化/开锋按钮分流;Codex 可上)
- **#37 23 orphan events 第 2 批挂回**(剩 17 条:悬崖/青楼/荒原/古船/古井等主题)
- **Phase 5 #2 DDD 目录整理 + 屏 Consumer 化收尾**(xhigh,可重新捡回 #28 闭关 widget e2e)
- **#30 闭关 3 维度接 service**(§12 #7 节气清单 + 农历库阻塞,先解人类决策)
- **#34 stage drop 视觉验收 Pen 环境改善**(配 ≥1080 屏幕 + 库存页快捷入口)
- **Pen-only T64 test fail 排查**(`.dart_tool/build` cache stale 推测,Mac 端不重现)

> CLAUDE.md §12 #1(境界 vs 修炼度名重叠)实质消解:Phase 1 已用「启蒙/入门/熟练/精通/圆熟/化境/登峰」vs「初窥/小成/中成/大成/圆满/巅峰/通神/无瑕/极境」严格不同名,见 `enum_localizations.dart:39,78`。

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

### Phase 1-3 W1-W5 详条已迁出

- **Phase 1 T01-T18**:`phase1_summary.md` + git log `v0.1.0-phase1` 前 commits(约 25 条带 `[Tnn]` 前缀)
- **Phase 2 T19-T32**:`phase2_summary.md` + git log `v0.2.0-phase2` 前 commits + merge `5efe8d5`
- **Phase 3 Week 1-3**:`phase3_summary.md` §Week 1-3 + git log + tags `v0.3.0-w1` / `v0.3.0-w3`
- **Phase 3 Week 4-5**:git log `9349626`(T53)→ `73c1f37`(stage_01_05 balance) + tags `v0.3.0-w4` / `v0.3.0-w5` + handoff `t58_visual_check_spec_2026-05-13.md` / `t62_visual_check_spec_2026-05-13.md` / `week5_full_closeout_2026-05-13.md`
