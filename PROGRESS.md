# 挂机武侠 · 开发进度

> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。
>
> **当前阶段：1.0 长线打磨期（质量优先 · 不设上线时间压力）** — Demo ✅(2026-05) → 1.0 内容周期 ✅(P1-P5+) → 打磨中。阶段一变只改本行；工作原则见 CLAUDE.md §7。

## 当前阶段

> 🥋 **2026-06-29 招式熟练度可视化二期完成(codex/night-skill-proficiency-visibility-2)**:在一期藏经阁基础上,统一战报/角色页/心法页/武学详情的熟练度说明。复用 `SkillProficiencyFormatter` + `StageProgressRow` + `combat.skill_proficiency` 配置,新增 compact 文案与心法内最高使用招式摘要;战报从 `BattleCharacter.skillUses` 读当前招阶段并追加 marker;角色页主修卡、心法 tile、武学详情均显示当前效果/下阶效果/战斗放招来源。**零改 numbers.yaml / 战斗公式 / schema / saveVersion**。验证:formatter、battle_log、character_panel、technique_panel、martial_arts_tab targeted tests + touched-file analyze。

> 🔧 **2026-06-28 codex/audit-fix-plan 审计修复第一批合入 main(评审通过·merge `4c79ee82` --no-ff·已 push origin)**:2026-06-28 三审计报告的低风险事实修复+诊断切片。**改动**:桃花岛银两口径订正(注释+新测从真实 7 建筑 config 派生 **88,800 银**=4 source×10,500+3 processor×15,600,旧 52,200 留作 4 建筑 fixture 改名测)/ production 单人空手开局 Ch1 前 4 关(01_01–04)3 敌→1 敌+小 Boss 3200/145→2200/100(根因=弟子终局 06_05 才拜入·祖师单人走主线)+ stage_01_02 首把武器掉率 0.35→1.0 / 强化材料供需只读模拟(几何均值失败模型·+15/+30/+49 期望)/ 离线被动 settle 不产银两红线锁(作用域仅 `OfflinePassiveService.settle`·不误伤主动闭关)/ 塔 25/30 Boss 数值上调(15000/2300·20000/2800·均<60000)+二阶段(接线复用既有大 Boss 范式·skills/mechanic 实存)+只读体感诊断。复核实跑 78 改动测试全绿·合并后主 checkout 复跑 25 测全绿。**零碰 numbers.yaml 数值/saveVer/schema/isar**(numbers.yaml 仅改注释)。**后续登记(2)**:① 单人主线 `stage_01_05→06_05`(26 关仍 2-3 敌=单人 1v3)待全程平衡审计——同根因最大缺口 ② 塔单人路径未覆盖(诊断用三人队·但塔仅 `requiredRealm` 解锁无弟子门槛·高境界塔层可能仍单人)。**设计待拍板**:终局 Boss 体感——实测 floor 24-30 三人队 100% 胜/2-5 tick 速决/二阶段沦为装饰,非硬墙但偏软,单体 Boss 堆数值无法威胁三人队需换杠杆(机制/多目标/阶段强控)。

> 🔀 **2026-06-28 codex 挂机 7 分支评审→合并→push→清理全闭环(main `b2bc6066→d9659815` · 已 push origin)**:本批「挂机工作流」7 个 codex 分支(均 merge-base=b2bc6066,各自 --no-ff)经 7 个并行只读评审子代理复核后**全部判可合并(0 暂缓)**。**4 实现**:material-source-lookup(材料来源**真反查**非硬编码副本·新 `item_source.dart`/`material_source_lookup_service.dart`)/ equipment-filter-lock(背包流派+锁定+受保护筛选·复用 `equipmentProtectionReason` 不碰 canEquip)/ skill-proficiency-visibility(藏经阁熟练度当前/下阶效果·从 skills.yaml+config 派生)/ offline-recap-detail(离线收益明细 formatter·**无重算/加成守在线=离线**)。**3 审计文档归档**:tower_structure_review(30+ 数字复算无误)/ onboarding_30min_review(正确反映祖师空手起家新现状)/ long_balance_audit(可作 balance spec 输入)。**全批零碰 numbers.yaml/saveVer/schema/isar**;唯一共享 `lib/shared/strings.dart` 四分支插入位分散→**合并零冲突**。合并后主 checkout 实测 `flutter analyze` **0 issue** · `flutter test --no-pub -j1` **3297 passed/1 skip/0 fail**(基线 3283→净增 14 测全绿)。7 worktree+7 分支合并后已 `worktree remove`+`branch -d` 清净。**6 条低优先小修挂账(不阻塞)**:① offline `skillProficiencyPoints` 恒 0 显「招式熟练度:0」(无数据源·建议 0 值隐藏)② skill formatter 重复 domain 公式(`skill_proficiency_formatter.dart:108-124`·加同步头注防 drift)③ dead 字段 `item_source.dart:20,22`+死代码 `strings.dart:1921`④ onboarding 审计漏报 `stage_01_04` 也是失败点⑤ tower 审计 §5.2→应 §5.4(文档笔误)。**后续可开工**:终局装备目标追踪(依赖 filter+source 底座)/ 匠人委托(依赖 source 反查)·先读 `docs/spec/playability_phase2_backlog.md` 定范围。

> 🔍 **2026-06-28 战前情报弹窗 opt-in 重做合入 main(销 11 暂缓挂账 · 独立 worktree stage-intel-optin · ff `0e610bc0→06e30c22`)**:睡觉模式被排除的第 11 项「战前情报」重做成 opt-in 纯查看入口并去四重冗余后合入。**复用关卡行现有 `ⓘ` 图标**(原弹掉落传闻)升级为「战前情报」弹窗,`onTap` 关卡行**仍直接进战斗不变**(守即拖即放)。弹窗四段:敌阵(每敌名/境界/门派/首领·蓄力 tag,行内独有)+应对(克制/破招/群战,剔推荐境界/难度)+风险(首领折损/蓄力/围攻,剔境界低)+可能收获(复用 `LootRumorContent`)。删原版每点必弹+「开战」确认门,改单「关闭」。隔离:`loot_rumor_dialog` 不动(爬塔/preview 仍用),仅改 stage_list 一个 onPressed。**零 schema/saveVer/numbers.yaml**。新建 `stage_intel_dialog.dart`(231 行)+保留子集 18 文案+3 新测(dialog 2+stage_list 1),守旧 loot wiring 测随之更新(plan 漏列,verify 期补)。subagent-driven 5 task+最终 review APPROVED。`flutter analyze` 0 · `flutter test --no-pub -j1` **3283 passed/1 skip/0 fail**(主仓实测) · macOS run 已起目检。spec/plan `docs/superpowers/{specs,plans}/2026-06-28-stage-intel-dialog-optin-redesign.md`。**挂账**:真机目检手感(弹窗排版/信息密度)进行中;集成分支 `codex/nightly-2026-06-28-integration` 11 素材已用完可随遗留 worktree 一并清理。

> 🌙 **2026-06-28 睡觉模式·Codex 16 任务并行 worktree 批量集成(15 功能合入 main · 11 暂缓)**:Codex 用「睡觉模式」(每任务独立 worktree/分支并行产出+定时续跑)产 16 候选分支,Claude 派 11 只读子代理审查+冲突矩阵分析→集成分支 `codex/nightly-2026-06-28-integration`→**ff 合入 main(ce94caea→ebd4c499 · 16 提交)**。**合入 15 功能**:01 爆率行内化/02+10 疗伤丹消费+药材丹药闭环(统一恢复模型)/03 桃花岛主屏/04 江湖恩怨战斗乘区(配置化 clamp≤1.25 不破百万)/05 specialSkill 开锋槽(三系锁死加固)/06+12 仓库批量安全+装备保护(护栏收窄 locked/heritage·删批量分解 UI)/07 战败诊断/08 藏经阁装配建议(越阶过滤)/09 闭关地图事件化(零收益纯表现·在线=离线)/13 扫荡分层/14 关卡整备条/15 商店分组/16 心魔余毒。**11 战前情报暂缓**(与 01/14 关卡行高冲突+强制弹窗违即拖即放爽感,排除该提交)。Claude 独立复验:`flutter analyze` 0 · `flutter test --no-pub -j1` **3280 passed/1 skip/0 fail**(ebd4c499 实测·非转抄)。**未 push**。**挂账(合并后跟进)**:① 07 realm_gap priority110 跨阶 Boss 战败误推刷境界(未修)② 09 叙事 prose 仍塞 numbers.yaml 应迁 data/narratives ③ 04 宜补恩怨×1.25 不破百万派生测 ④ 11 待重做 opt-in ⑤ 高风险入口(关卡列表/批量出售/疗伤丹/锻造3槽)真机目检待 `flutter run -d macos`。审查报告 `docs/audit/stage_review_2026-06-28.md`(Codex 留未跟踪)。

> 🌱 **2026-06-27 祖师起手回归学徒新手·空手·入门功(balance · 独立 worktree balance-founder-start-realm)**:真机试玩发现新档祖师过强(一流·带3装备·碾压学徒野怪6-8×)。诊断=非bug非泄漏,是 Demo 期高境界 fixture 漂移(week4_d「开局展示完整队伍/全员<武圣避飞升锚点」理由已失效:弟子改终局拜入·飞升已实装),且与 GDD Ch1-3 学徒→一流 进程矛盾。用户拍板 B:祖师降 `xueTu·qiMeng` + `startingEquipmentIds: []`(空手) + 心法 `tech_gangmeng_mingjia→tech_gangmeng_jichu`(入门功)。**放宽移除 T55**「祖师起手须含师承遗物」校验(`game_repository._enforceMasterRedLines`)——依据全证伪:GDD §6.1 是「师父留给徒弟」传递机制非起手种子·`ascend_service` 飞升任选已装备/库存传徒不依赖起手(空选优雅兜底)·heritage 装备 Ch3/tower25 游戏中可掉。**GDD/schema/saveVer 不动**;老档 slot1 幂等不重建。debug `Phase2SeedService.seedMasterDisciple` 显式复现进阶祖师(yiLiu+原3装备)与生产解耦,27 个飞升/battle 测原样过。全量 `flutter analyze` 0 · `flutter test` **3231 passed/1 skip/0 fail**(演出+祖师同树)。**挂账**:学徒空手能否过 stage_01_01 属真机校值(不可过则早期平衡另调);弟子起手境界仍 Demo 高值(终局拜入匹配,范围外单列)。spec `docs/superpowers/specs/2026-06-27-founder-start-realm-novice-design.md`。

> 🎬 **2026-06-27 战斗命中演出分级(spec+plan · 独立 worktree feat-combat-hit-tier · 代码实装完成)**:战斗爽感主旋律表现层。**纯表现层零 schema、不碰结算**(diff 无 damage_calculator/saveVer)。① 配置层 `animation.hit_tier`(题字峰值字号/辉光/特写缩放/脉冲时长 · `HitTierConfig` 防御 fallback)② 真相源 `hitClimaxFor(action,state)→HitClimax{none,ultimateCrit,kill}` 纯函数(基础档×修饰叠加 · 零字段新增 · `BattleState.characterById` DRY 击杀查找)③ 题字分级(大招暴击特大68+辉光 · 普通大招56现状不变 · `show()` 默认参数保现有调用)④ 命中特写镜头(大招暴击/击杀缩放脉冲 · `_closeupCtrl` 独立触发非嵌 profile 块故普通击杀也触发 · 快进/扫荡/拖招抑制守在线=离线)。TDD +9 测(2 config+6 hitClimax+1 caption widget)。全量 `flutter analyze` 0 · `flutter test` **3230 passed/1 skip/0 fail**。**挂账(姐妹真机 pass)**:绝对值(峰值字号/辉光/缩放/脉冲 ms · 节奏 action_interval/key_moment_hold/popup)+ 内力当平衡问题修(提消耗/降玩家预算) 均需 `flutter run -d macos` 边玩边校;特写/题字分级真机目检待跑。spec `docs/superpowers/specs/2026-06-27-combat-hit-tier-presentation-design.md` / plan 同名。

> 🧑‍🏫 **2026-06-27 弟子加入战斗后移至终局解锁(spec A · 独立 worktree disciple-endgame-unlock)**:`disciple_joins` 两条 stage_id 02_05/03_05 → 均改 `stage_06_05`(祖师单人走完 Ch1-6,终局一并拜入两弟子)。`DiscipleJoinService.joinForClearedStage` 单匹配→遍历多匹配返回 `List<Character>`,**关级防重标记移到遍历后一次性写**(防 senior 先标记挡掉同关 junior);hook 遍历多弟子按 role 依次弹拜师叙事+立绘;红线校验 dedup 由 stage_id 唯一→**role 唯一**(允许同关多 role)。旧档祖年化(角色级 guard 不重建/迁移 backfill 读 live config 标 06_05)。飞升/真传/师承遗物**不改**(06_05 通关与拜入同时点)。全量 `flutter analyze` 0 · `flutter test` **3210 passed/1 skip/0 fail**。**独立验证项(spec §4 未做)**:主线变单人,武圣单人能否通 Ch4-6(尤其 06_05 Boss 52000 血)需 balance_simulator 单独跑+不可通则敌人调参待用户拍板,本任务不静默 buff/nerf。

> 🌸 **2026-06-27 桃花岛二期 + 藏卷阁 Hub + 整备建议联动合入 main(PR #17 · merge `7335927e`)**:三条 Codex 前置分支集成——桃花岛二期底座(muGongFang/lingQuan/zhuZaoTai 7 栋两层生产链 + 据点式分组屏 + 旧档安全补建) / 藏卷阁 Hub(聚合战绩册/兵器谱/奇遇/藏经阁,装备·残页·Boss周目三类只读派生线索,主菜单 social 门控入口) / 整备建议 + 岛务工程碑只读 first slice(不写存档不发奖励)。审核发现灵泉水孤儿产出 → 修:丹房疗伤丹改双输入(药草+灵泉水·扩 secondaryInput schema + 供应自洽/防 unused 校验 · 灵泉供给 4/hr>满速消耗 3/hr 恒非约束 → 离线=在线不变性测 brew_liaoshang×5 level 全过)。全量 `flutter analyze` 0 issue · `flutter test` 3207 passed/1 skip/0 fail。清理 3 worktree + 3 已合并分支。**backlog**:疗伤丹/锻材/开锋辅材/行囊补给 4 加工产物暂无终端消费系统(疗伤/开锋系统未接)待拍板。另:CLAUDE.md §8.0 可恢复任务协议(v1.25)cherry-pick 补回 main(`0b7c888a`),planning 分支唯一独有提交保全,三 Codex worktree(含 .codex 磁盘空残留目录 rmdir)+4 分支(含 planning)全清理。

> **2026-06-27 Codex 14 分支批量集成 + #8 突破材料退役 + 外部审查 P1-P3 三条已压缩归档**(13/14 合 main `0d75f49b` · #8 不引入销账 · 外部审查 `c1a1e636`→`a82aa9d2` · 详 `docs/handoff/codex_branch_merge_closeout_2026-06-27.md` + git log · 3176→3177 测)

> **2026-06-26 续2-6 + 第八阶段 + 一键扫荡 9 条已压缩归档**(git log/各 closeout/spec `2026-06-2{5,6}-*` 可溯 · 3001→3172 测):装备出售/分解+仓库格子化+升级放慢(推翻 §2.1 装备永久收藏品红线·CLAUDE v1.23·+31 测) · 问鼎九霄 6 Boss 层剧情 12 篇+完整性守护测 · 队伍三人解锁靠后(stage_id 02_05/03_05 章末) · 装备槽对话框居中重做+全量对比 · 副本屏 chip 收口+周目难度双调(scale_per_cycle 0.10/二周目加真气) · 周目可见化 5 改(扫荡周目标签/灰显门槛/keepAlive 保活/悬停 IgnorePointer) · 一键扫荡黑屏 hang 修复(battleProvider autoDispose 回收根因)+主菜单按钮等高+启动直达主菜单 · 第八阶段 角色 Lv+推荐境界难度+掉落悬停预览+稀有彩头 E(saveVer 0.31·Isar 哨兵回填修复) · 一键挂机扫荡实装(门槛/recap/连播状态机)。**未销账 backlog**:形与势 16 项战斗轴(#1/2/4/11/12/16 未动工) · D 余 2 候选(题字命中分级/掉落金光分桶) · 二周目平衡待拍板(backlog §十一) · 各 balance 初值(scale/彩头/Lv 曲线/材料 ×1.5)+全批未真机目检待 `flutter run -d macos` 实玩。

> **2026-06-25 桃花岛 + 战斗张力替代 + 健康报告#3 6 条已压缩归档**(git log/spec `2026-06-25-*`/`docs/audit/windows_acceptance_2026-06-25.md` 可溯 · 2905→3031 测):桃花岛一期新养成经营支柱(14 task·saveVer 0.30·offline=online 单 settle 纯函数·~120 测)+balance(cap 对齐 72h·升级成本节奏 B 前低后高+境界分阶) · 爬塔/战斗/结算 UI 5 修 · 体力系统需求→守红线写实替代(不做体力·三套:内力弹药/境界门槛/双层伤势 saveVer 0.29 已实装) · 健康报告#3 11 招搁浅 encounter 接线+11 奇遇文案 · Windows 真机验收(SSH 自驱·test/build 逐位同 Mac·平台风险清零)。**未销账 backlog**:桃花岛二期(木工坊/矿洞/灵泉/行商/装饰/多品类原料) · 伤势 balance 初值待真机校(疗养 8h/减内力 15%/攻击 ×0.85) · GUI 手感 ship 前人工目检。

> **2026-06-23..24 全系统审计 A-E + 掉落 F1-F8 + 战斗节奏 已压缩归档**(git log `5aa89cf2→3ed20d7b`/audit `full_system_audit_2026-06-24.md`+`drop_consistency_2026-06-23.md`/各 closeout 可溯 · 2815→2904 测):A 开锋吸血/破甲接战斗 · B 系统接 game loop · C 设计冲突拍板(招式倍率全局 ≤8000 单线·CLAUDE v1.21) · D/E 死字段+散写中文 honest 化 / 续47-51 掉落表一致性审计+F1 里程碑装备授予(saveVer 0.28)+F2 首通门控+F3 章末护甲越阶+F4 终局塔层去水分+F5/F7/F8 配置卫生 / 续45-46 战斗节奏可读性 A+C(ATB 一拍一行动+关键帧顿帧)+审计修 bug 批。**backlog**:specialSkill 槽3 单列 · floor20 一流 yu_pei_lao -1 阶留底 · 战斗节奏 `action_interval_ms`/`key_moment_hold_ms`/`damage_popup_ms` 初值待真机校(backlog 九)。

> **2026-06-22..23 续34-44 已压缩归档**(P4长期档案子项1-6全闭环+续42审查+续43散写中文复扫+续44 backlog checkbox 同步/清 _formatAction 死字段：续31战绩册`4669fbac`/续33兵器谱`2e4b7ed6`/续34-38材料经济`5f3899fb`/续39门派谱1.1`4cfc1565`/续40奇遇录`fe4c0751`/续41藏经阁2.0武学图鉴(P4全6子项闭环里程碑)/续43迁4处真违规进UiStrings`de290e6c`/续44 backlog 8 stale checkbox 翻[x]+删 default_ground_strategy._formatAction 死字段`15d4235b`·均纯展示层零saveVer·2676→2815测·spec `2026-06-2{0,1,2}-p4-*`)

> **2026-06-17..20 续19-续30 已压缩归档**(第五~七阶段·git log/各closeout可溯·2301→2605测)：续19上下文帮助系统·续20主线一战斗UI表达+aoe全体伤害·续22主线三掉落传闻UI·续23即放时序2.3+首通门控2.5·续24打击感表现层2.4·续25三人协同破绽窗口·续26战后体验英雄镜头·续27Boss多阶段/弱点抗性/技能珍稀·续28批二目检+帮助按钮修·续29队伍成长渐进解锁+二弟子控制·续30四批真机目检全PASS+hero_camera路由。spec `2026-06-1{7,8,9}-*`。

> **2026-06-16 续15-18 已压缩归档**(全功能真审计纠幻觉重跑 1H+7M+1L+2drift·3 吹的 High 实证误报 + 规则层全域摸排按级修复 `c384a0d3` + M6 心魔失败惩罚实装 `cf694faf`/余毒战败摘要 UI · 合 main `b8330c14`→2286 测 · 详 `docs/audit/full_audit_2026-06-16.md` + git log)

> **2026-06-14..15 续10-14 + 红线/战斗交互重做批已压缩归档**(git log/spec/closeout 可溯 · 2160→2245 测):续10-14(闭关非阻塞/离线收益 A+B 被动挂机 saveVer0.24/显示设置全屏3档/MeridianBar wiring/战报失败诊断 `BattleDiagnosis`)+ 战斗交互重做 Phase1-4(自动播放+随时拖招,废录制回放净 -2050 行)+ 周目按章 saveVer0.23 + 周目进化 A-F1(敌人 scale/5 反制词条/Boss HP 50000→60000)+ **红线语义收口分两层**(硬=配置基础表值 schema 拦截 / 软=极值满 build 实战可见不进百万)。

> **2026-06-12..13 半手动战斗 master spec/P0 + UX 整合/爆品展示批已压缩归档**(详 `2026-06-1{2,3}-*` spec + 各 closeout · 1950→2067 测):半手动+seed重放+周目进化 master spec 定稿 → P0 3b-5 全闭环(逐 actor stepOne/单步 UI/重放/schema 0.19 BattleReplayRecord/自手印章)+ AGENTS.md 瘦身根治双文档漂移;战斗/装备 UX 整合 12/12(藏经阁+装备链路+指令台 Codex 5/5)+ 爆品展示(印章动画/tagline 35句/时序重排)+ BGM 扩 8 轨 + StageProgressRow + 神物金光 + E 音频 Phase0。

> **2026-06-11 长线打磨 波A/波B + 音频批已压缩归档**(详 `2026-06-11-wave-{a,b}-*` spec + 各 session · 1888→1932 测):波A P1 机制深度(破招 build gate §9.1/interrupt_power_pct/per-skill 熟练度铺广/来源统一 skillUnlockProgress)+ 波B 24 招全内容+机制 Boss×6+装配池 wiring+30 关高熟练度 sweep + 平A 命中音 6 变体 + 战斗 BGM 短前奏版 + jingle 扩槽 + 工程清理。

> **2026-06-09/10 可玩性 P1a/P1b 养成内核批已压缩归档**(详 `p1a_cultivation_core_closeout_2026-06-10.md` + 各 closeout · 1778→1883 测):P1a 养成内核(per-skill 熟练度 1.00→1.30/解锁进度 SkillUnlockService/Boss 掉书+残页)+ P1b 藏经阁技能装配(Character 5 装配槽 saveVer0.17/SkillLoadout autoFill)+ B3 破招「破!」题字+B5 败北页路由 + P0 手动 Boss 破招全闭环 + 音频系统全闭环(SoundManager/三类 hook)。

> ✅ **2026-06-05..09 归档**(UI kit v1 序 0 = 9 组件 + `WuxiaUi` token · Codex 两天 UI 包装/MJ 56 张接入 `a195547` · §5.6 硬编码审计抽 UiStrings/T5 闭关地图化/截图基建/心法 cover 重出 `c991984` · 1713→1763 测/0 analyze):详 git log `feat/ui-kit-v1`→`e767c42` + 各 closeout/plan。

> **2026-06-04 两条已压缩归档**(8 张装备图重出+工作树清理+UI 包装方案 v1 `9ea8f4f` / P0-3 ②③ 主修 hero+心魔瓶颈面板 `f9425b8` · 1697→1712 测):详 git log + 各 spec/closeout。

> **2026-06-01..03 详条已压缩归档**(git log/closeout 完整可溯 · 1661→1697 测/0 analyze):① **P0-2 战斗单位可见化全闭环**(玩家立绘+单位放大 110+死亡 grayscale+弹道笔触+受击闪+折叠日志+胜负 vignette · 弹道/受击走 actionLog 不写 BattleState 红线 · `c7fb79c`)② **P0-3 角色卡 ① 装备外观可视化**(装备槽 iconPath+tier 色 _EquipGlyph)③ **P0-4b 仓库格子化实装**(列表→部位分组网格+tier 边框+强化徽章+师承标+境界锁灰化 · `2049265` · Codex R3 PASS `880d7f7`)④ **装备 detail 45 件 + 敌人图 37/37 全归位**(美术缺口归零 `239d1d9` · 129 敌人图 + 80 装备 detail)⑤ **验收提速基建**(`VISUAL_ROUTE=hub` 一次 build 点遍 12 路由 + `tool/build_acceptance.sh` 预编 · `d94a56a`)。详 `docs/handoff/overnight_2026-06-03_handoff.md` + 各 closeout。

---

## 已知偏差 / 挂账事项

- ~~#37-#45 / stage_05_05 跨阶墙 / equipment_detail '(基 $base)' nit~~ 全销账(2026-05-17..06-08):详各 closeout + 末尾归档

> 已销账条目(#1-#45)详见末尾归档。**P1 阶段全销账 ✅** + **Demo §8.4 14/14 全达标 ✅** + **1.0 ~95% release ready ✅**(A+B+C 全 PASS · 剩 D-G 留 M15-16)。

## 关键约束(每次开局必读)

- 数值硬红线(配置基础表值·schema 拦截):装备基础攻击 ≤2000 / 玩家血 ≤20000 / 内力 ≤15000 / Boss 血 60000+(GDD §5.4)
- 数值软红线(极值满 build 实战可见值·保可读):核心唯一线=不进百万膨胀(普攻真实峰值~13.5万 / 大招~21万,均六位可读)
- 不硬编码数值/文案(走 numbers.yaml / data/narratives, lore, events)
- Riverpod 状态管理;Isar 本地存储;data/ asset 根
- 不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md(数值/规则层 · 改前 ask)
- Mac 端写 lib/、data/(顶层)、test/、文案(v1.8 起 DeepSeek 退役)

## 远程仓库

- GitHub:https://github.com/Zed1118/wuxia_idle · 主分支 main
- 协作:Mac 单端代码+数值+文案;视觉验收 Mac 本地 Codex(Pen Windows AI 工具 2026-06-11 全下线)

## 归档

### 已解决挂账(逆时序)
- **心法 7 阶 cover 伪书法 G5.1 红线**(2026-06-08):重出透明无字卷轴替换(`c991984`)· flood-fill 抠白底+收边 · 真木底自检无白晕

- **Phase 1-2 + W1-W13 全销账**(2026-05-10..14):#1/5/12-16/19-29/32 + #18 伪挂账

### Phase 1-4 早期详条已迁出

- Phase 1-3 + W4-W11:`phase{1,2,3}_summary.md` + tags `v0.1.0-phase1` / `v0.3.0-w11`
- W14-W15 + Phase 5 #2/#3 销账详条:git log + handoff/各 closeout

### W17-W18 详条迁出 2026-05-19/20

13 段销账(P1 #42-45 / Nightshift 9 task / P0 4 段 / 外部审查 6 项 / 路线图 launched / Codex 视觉)。详 `p1_4{2,3,4}_*` / `nightshift_20260519_handoff.md` / `p0_38_maxhp_rebalance_closeout_2026-05-17.md` 11 closeout。

- **P1.1 候选 1-5**(2026-05-21):5 候选全收口(4 实装 + 1 doc)— 收徒池 E.1 / 祖师爷 sect_wide_buff / 共鸣度 4 子任务 + joint_skill / 开锋 build / CLAUDE.md §12 对齐 · `p1_1_*_closeout_2026-05-21.md`。

### M4 #46 美术 + Ch4 Phase 2 详条迁出 2026-05-20/22

- **M4 #46 美术** 5 段(2026-05-20/21):Stage 2 W1-W6 74/74 + assets 89 张 + stage_audit + #45 Demo §8.4 · 详 art_poc_* / art_assets_integration_* / p1_45_demo_polish_*
- **Ch4 1.0 P2 第二条主线第 1 章**(2026-05-21/22):Phase 2.1-2.5 全收口 + 13 narrative ~5,880 字 · 详 p1_x_chapter4_phase2_*

### 2026-05-22/23/24 详条归档

- **2026-05-22 Ch5 + Ch6 飞升 P2 主线全闭环**(2 章 ~12,438 字 · 师父三句遗言完整连通 · 小铜镜+玉佩 hook 闭环 · 详 `p2_x_chapter{5,6}_phase2_full_closeout_2026-05-22.md`)
- **2026-05-23 心魔 Batch 2.1-2.5 + P3.1 轻功对决**(8h overnight worktree · 7+5 关 · 详 `p2_x_inner_demon_final_closeout_2026-05-23.md` + `p3_1_lightfoot_closeout_2026-05-23.md`)
- **2026-05-24 P3.2 群战守城 + P3.1.B 子批 + P5+ 多代飞升 + 真传位 + 8h overnight v2/v3 + nightshift v2 首跑 + UI polish**(git log `efc7604 → b6d8191` 区间 · 详 handoff `p3_2_*` / `p3_1_b_*` / `p5_lineage_full_closeout_2026-05-24.md` / `nightshift_v2_first_run_closeout_2026-05-24.md` / `8h_autonomous_handoff_2026-05-24.md`)
- **2026-05-25 v2.1 工具完善 + T17-T22 cherry-pick + T23/T24 6 关键问题闭环批**(main `74ba519 → b6d8191` · 1458 测 / 0 analyze · 批次质量 A 9.05/10 · P1.2 江湖恩怨+声望 100% + 技术债 3 合一 · 详 `session_closeout_2026-05-25_nightshift_6h_review.md` + `p1_2_jianghu_full.md` + `p3_tech_debt.md`)
- **2026-05-28 过夜清理+P3 三项+P2.1 4 批+drop 全覆盖+CHECKLIST v1.5+R4 派单**(1505→1519 测 · 详 `overnight_1_1_cleanup_handoff_2026-05-28.md` / `session_closeout_2026-05-28_p3_p1_triple.md` / `codex_dispatch_r4_p2_1_content_drop_2026-05-28.md`)
