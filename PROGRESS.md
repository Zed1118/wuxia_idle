# 挂机武侠 · 开发进度

> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。
>
> **当前阶段：1.0 长线打磨期（质量优先 · 不设上线时间压力）** — Demo ✅(2026-05) → 1.0 内容周期 ✅(P1-P5+) → 打磨中。阶段一变只改本行；工作原则见 CLAUDE.md §7。

## 当前阶段

> ✅ **2026-06-22 续41(P4 长期档案·子项6 藏经阁2.0 武学收录图鉴 · brainstorm→spec→plan→10task subagent-driven TDD · 合 main(worktree-martial-codex 11commit) · opus xhigh)**：江湖见闻录第5tab「武学」——205招武学典籍(心法147+真解6+残页9+破招3+奇遇40,排轻功18+joint1)账号级**收录图鉴**(区别藏经阁1.0装配操作屏 `lib/features/cangjingge/`)。**纯派生展示层**:零collection/零saveVer/零数值改,全派生 `skillDefs`过滤(单一真相源`isMartialCodexSkill`)+**三套点亮口径**(心法招→active学过该心法 techDef.skillIds并集/稀有招真解残页奇遇→`unlockedSkillIdSet`/破招→active队伍含该style角色)+全队最高熟练度(`skillUsageCount.countOf` max→`stageFor`)。**来源分5组**(心法组内按所属心法小节·名·tier·流派)+剪影藏名§5.7不泄来源+空态守(全未点亮不甩剪影墙)+详情屏纯同步(复用`skill.description`零async)。共享纯函数`martialSourceKindOf`/`labelForMartialGroupKind`防双份漂移。10task每task implementer + UI层spec reviewer + final review **READY_TO_MERGE**(端到端类型连贯/三套点亮精确/单一真相源/红线全守/边界全覆盖)。全量 **2815测+1skip**(基线2800 **+15** 零回归)/analyze**0**(worktree实测)。spec/plan `docs/spec/2026-06-22-p4-martial-codex-{design,plan}.md`。**🎉 P4 长期档案全6子项达成**(战绩册/兵器谱/材料经济/门派谱1.1/奇遇录/藏经阁2.0)。**真机目检 PASS**(2026-06-22 双路由 macos 截图:tab 已习6/205·混态点亮+剪影藏名·心法小节·水墨配色无溢出 / 详情屏招名「直拳」+description+倍率500+来源心法绝学+所属刚猛入门+熟练阶未曾习练·宣纸面板绛红普攻标·无溢出)。**下一步**:P4 全闭环,待用户指定新打磨方向。

> **2026-06-22 续34-40 已压缩归档**(P4长期档案子项1-5全闭环：续31战绩册`4669fbac`/续33兵器谱`2e4b7ed6`/续34-38材料经济`5f3899fb`/续39门派谱1.1`4cfc1565`/续40奇遇录`fe4c0751`·均纯展示层零saveVer·2676→2800测·spec `2026-06-2{0,1,2}-p4-*`)

> ✅ **2026-06-21 续33(P4 长期档案·子项2 兵器谱 · brainstorm→spec→plan→11 task subagent-driven TDD · 合 main `2e4b7ed6` 未 push · opus xhigh)**:收集式装备图鉴(区别于江湖见闻录「典故」tab 的静态全展示)。**6 决策锚点**:收集图鉴(点亮式)/ 收录全 80 件装备(沿「兵器谱」雅称)/ 曾获得即永久点亮 / 新建 `EquipmentCatalogEntry` @collection 记获得历程 / 老档回填「来历不详」/ 未获得剪影藏名。**架构对称战绩册 battle_record**(domain/application/presentation 三层)。**写入双策略**(Phase 0 发现装备进库存散落 6+ 点无单一 chokepoint):`reconcileFromInventory` 扫库存兜底(接存档加载 isar_setup,兼老档回填+漏 hook 安全网)为骨干 + 主线/爬塔掉落挂 `runEquipmentCatalogHookAfterObtain` 给首得来源(`stage.name`/`宝塔第N层`),幂等防双计;**奇遇接线 implementer 核证后故意不做**(`game_event_service:147/:257` 均是已掉/参战装备追加 lore 的 re-persist 非新获得,挂上会污染图鉴)。saveVer **0.26→0.27**(连带修 5 测试文件 7 处硬编码版本断言 + 删无消费的 sourceEncounter 死常量)。UI:主屏(tier 7 档分组 + slot 筛选 chips + 进度 X/80 + 剪影/点亮卡,唯一色源 tierColorForEquipment + IntrinsicHeight + errorBuilder)+ 详情屏(静态档案 + 个人历程双态「来历已不可考」)+ 主菜单入口(获得任一装备解锁,镜像战绩册)+ VISUAL_ROUTE 双路由。**每 task implementer + 复杂任务 subagent 双审(spec+质量)+ 最终整体 review 全 APPROVED**(端到端链路闭合/双策略无重复无遗漏/红线全守纯展示零伤害经济改动/spec 6 锚点全到位)。全量 **2688 测 +1 skip**(baseline 2676 **+12** 零回归)/ analyze **0**(主 checkout 实测)。spec+plan `docs/spec/2026-06-20-p4-weapon-codex-{design,plan}.md`。**目检 PASS**(真机 macos 截主屏:进度4/80·tier分组·slot筛选·铁剑折刀轻甲粗布衣点亮+剪影未得之器藏名·布局无溢出;详情屏:器物档案立绘+寻常货武器+攻100~160·个人历程得于黑风寨之战,图 docs/handoff/visual_capture_2bdedf67_weapon_codex)。**待**:清理 worktree-weapon-codex 分支。**下一步**:目检后 P4 余 4 子项(材料系统/奇遇补全/藏经阁2.0/门派谱1.1)。

> ✅ **2026-06-20 续31(P4 长期档案·子项1 战绩册 · 发现并解决两套并行实装冲突 · 合 main `4669fbac` 未 push · opus xhigh)**:本会话先 brainstorm→spec→plan→8 task 做了 **A 套**战绩册(embedded list 挂 SaveData + 江湖见闻录第4 tab + 静态详情卡 · 已合 main)。/handoff 收尾 0c 检查**发现孤儿 worktree `p4-battle-record`** 有同日另一会话做的 **B 套**战绩册(22 commit,从 faa0bdd0 分叉,未合 main):独立 `BossMemory` collection + 独立战绩册主屏(分组+剩影占位)+ Boss 纪念详情屏 + 主菜单入口(首胜解锁)+ 重打累加 + 老档骨架回填。子代理评估:B 套更完整、更贴 master spec §八「战绩册」野心(但漏跑 baike 测族)。**用户拍板采纳 B 套**,2 偏离点保留 B 原生(① 老档 isPreRecord 骨架回填〔只名字+日期不填快照,规避「快照无源」顾虑〕② 爬塔全 6 Boss 含小 Boss)。**迁移**:`backup-main-A-set-20260620` 备份 A 套 → main reset 到 `369381b2`(留 hero_camera 路由+backlog 收口,去 A 套战绩册) → merge B 套 → 解 3 冲突(visual_route 三文件双方路由全留) → **修 B 套自带 bug**:`enforceLineageOnboardingRedLines` 对「空 stages 测试 fixture+真实 numbers」误杀(baike_screen_tier_group_test 挂),加 `existingStageIds.isEmpty` 跳过(与既有覆盖度红线同约定)。全量 **2676 测 +1 skip**(零失败)/ analyze **0**。**教训**:并行会话/孤儿 worktree 致重复劳动——开工 Phase 0 应先 `git worktree list`+`git branch` 查在途分支(A 套白做)。**目检 PASS**(续32 `flutter run -d macos` 截 battle_record 主屏 + boss_memory_detail 详情屏 @720p/1080p:纪念卡+剩影占位混合态 / 英雄镜头快照+总伤害43280·暴击12·38回合 / pre-record「此役不详」骨架,布局无溢出·水墨配色全 PASS,图 docs/handoff/visual_capture_2f14a80c_*)。**A 套遗留已全清**:删 backup-main-A-set-20260620 + worktree-p4-battle-record + worktree-hero-camera-visual-route 三分支 + 移除 hero-camera/p4 worktree(`git worktree`/`branch` 仅余 main)。**下一步**:P4 余 5 子项(兵器谱/材料系统/奇遇补全/藏经阁2.0/门派谱1.1)。

> **2026-06-17..20 续19-续30 已压缩归档**(第五~七阶段·git log/各closeout可溯·2301→2605测)：续19上下文帮助系统·续20主线一战斗UI表达+aoe全体伤害·续22主线三掉落传闻UI·续23即放时序2.3+首通门控2.5·续24打击感表现层2.4·续25三人协同破绽窗口·续26战后体验英雄镜头·续27Boss多阶段/弱点抗性/技能珍稀·续28批二目检+帮助按钮修·续29队伍成长渐进解锁+二弟子控制·续30四批真机目检全PASS+hero_camera路由。spec `2026-06-1{7,8,9}-*`。

> **2026-06-16 续16-18 已压缩归档**(规则层全域摸排+按级修复 `c384a0d3` + M6 心魔失败惩罚实装 `cf694faf` + M6 余毒战败摘要 UI 上下文感知标题视觉验收 · 2247→2286 测 · 详 git log + `docs/audit/full_audit_2026-06-16.md`)

> ✅ **2026-06-16 续15 已压缩归档**(全功能真审计 + 按级修复 · 合 main `b8330c14` · 2247 测):纠上会话幻觉(谎称落盘的「45 项」审计全仓查无)→重跑真审计(1 High+7 Med+1 Low+2 drift,3 个吹的 High 红线项实证全误报,报告 `docs/audit/full_audit_2026-06-16.md`)。修 H1 爬塔周目迁移数据丢失版本门 + §6 路径 drift + EnumL10n/battle_log 正名合法 sink + M3-M5 散写中文迁 UiStrings + M6 确认心魔惩罚未 wire 留拍板。

> **2026-06-15 续10-续14 五条已压缩归档**(全 commit/spec/closeout 可溯 · 2190→2245 测):续10 L3 闭关非阻塞 + M2 离线收益范围A(`7efb82c8`)+ L1 显示设置 window_manager 全屏/3 档分辨率(`130b40ac`) · 续11 L1 Codex 验收 + 两 fail 回修(720p overflow / F11→Alt+Enter `a0f77a8b`) · 续12 M2 范围B 通用被动离线挂机(saveVer0.24.0 · 9 决策 · `212b572c`) · 续13 P1b MeridianBar wiring(StageProgressRow 四系统收口) · 续14 P3 战报失败诊断(三段式复盘 `BattleDiagnosis` 5 规则 · `6a32901a`)。spec `2026-06-15-*`。

> **2026-06-14 红线/战斗交互重做批已压缩归档**(git log `7adc8532→3edc99ae` · 详各 closeout · 2160→2165 测):战斗交互重做 Phase1-4(自动播放+随时拖招,废半手动/录制回放净 -2050 行)+ 周目按章(saveVer0.23)+ 周目进化 A-F1(敌人 scale/5 反制词条/Boss HP 红线 50000→60000 · Codex 视觉 10/10)+ 拖招表现层微调(引导线外发光/蓄势呼吸光晕 · Codex 5/5)+ **红线语义收口分两层**(硬=配置基础表值 schema 拦截 / 软=极值满 build 实战可见值不进百万,balance_simulator 极值×周目诊断证伪「不进十万」)+ towers 注释补漏。

> **2026-06-13 半手动战斗 master spec + P0 全闭环已压缩归档**(详 `2026-06-13-semi-manual-battle-*` spec/plan + 各 closeout · 2011→2067 测):半手动+seed重放+周目进化 master spec 定稿 → P0 步骤 3b-5 全闭环(逐 actor 单步 stepOne/单步 UI/重放执行/schema 0.19 落盘 BattleReplayRecord/全局+per-stage 自动开关 UI · 自/手印章 glyph)+ AGENTS.md 瘦身 stub 根治双文档漂移。

> **2026-06-12 UX 整合 + 爆品展示 + 音视频批已压缩归档**(详 `2026-06-12-*` spec + 各 closeout · 1950→2002 测):战斗/装备 UX 整合方案 12/12(藏经阁+装备链路+战斗指令台 · Codex R2 5/5)+ 爆品展示(印章盖落动画/tagline 35句/时序重排爆品当第一高潮)+ BGM 扩 8 轨细分 + D 四类养成进度五要素标准化(StageProgressRow)+ UI 视觉 sweep + 神物金光 TreasureGlowLayer + E 音频 Phase0 摸底。

> **2026-06-11 长线打磨 波A/波B + 音频批已压缩归档**(详 `2026-06-11-wave-{a,b}-*` spec + 各 session · 1888→1932 测):波A P1 机制深度(破招 build gate §9.1/interrupt_power_pct/per-skill 熟练度铺广/来源统一 skillUnlockProgress)+ 波B 24 招全内容+机制 Boss×6+装配池 wiring+30 关高熟练度 sweep + 平A 命中音 6 变体 + 战斗 BGM 短前奏版 + jingle 扩槽 + 工程清理。

> **2026-06-09/10 可玩性 P1a/P1b 养成内核批已压缩归档**(详 `p1a_cultivation_core_closeout_2026-06-10.md` + 各 closeout · 1778→1883 测):P1a 养成内核(per-skill 熟练度 1.00→1.30/解锁进度 SkillUnlockService/Boss 掉书+残页)+ P1b 藏经阁技能装配(Character 5 装配槽 saveVer0.17/SkillLoadout autoFill)+ B3 破招「破!」题字+B5 败北页路由 + P0 手动 Boss 破招全闭环 + 音频系统全闭环(SoundManager/三类 hook)。

> ✅ **2026-06-05..09 归档**(UI kit v1 序 0 = 9 组件 + `WuxiaUi` token · Codex 两天 UI 包装/MJ 56 张接入 `a195547` · §5.6 硬编码审计抽 UiStrings/T5 闭关地图化/截图基建/心法 cover 重出 `c991984` · 1713→1763 测/0 analyze):详 git log `feat/ui-kit-v1`→`e767c42` + 各 closeout/plan。

> **2026-06-04 两条已压缩归档**(8 张装备图重出+工作树清理+UI 包装方案 v1 `9ea8f4f` / P0-3 ②③ 主修 hero+心魔瓶颈面板 `f9425b8` · 1697→1712 测):详 git log + 各 spec/closeout。

> **2026-06-01..03 详条已压缩归档**(git log/closeout 完整可溯 · 1661→1697 测/0 analyze):① **P0-2 战斗单位可见化全闭环**(玩家立绘+单位放大 110+死亡 grayscale+弹道笔触+受击闪+折叠日志+胜负 vignette · 弹道/受击走 actionLog 不写 BattleState 红线 · `c7fb79c`)② **P0-3 角色卡 ① 装备外观可视化**(装备槽 iconPath+tier 色 _EquipGlyph)③ **P0-4b 仓库格子化实装**(列表→部位分组网格+tier 边框+强化徽章+师承标+境界锁灰化 · `2049265` · Codex R3 PASS `880d7f7`)④ **装备 detail 45 件 + 敌人图 37/37 全归位**(美术缺口归零 `239d1d9` · 129 敌人图 + 80 装备 detail)⑤ **验收提速基建**(`VISUAL_ROUTE=hub` 一次 build 点遍 12 路由 + `tool/build_acceptance.sh` 预编 · `d94a56a`)。详 `docs/handoff/overnight_2026-06-03_handoff.md` + 各 closeout。

> **2026-05-30..06-02 出版美术 pass(1.0 Presentation Pass)全闭环已归档**(1581→1667 测/0 analyze · `docs/PUBLISHING_ART_PASS_1_0.md`):战斗屏(主菜单水墨山门 + B1 背景按 biome 接线+scrim+胜负仪式 overlay + B2 大招题字+Boss 金边)+剧情屏(narrative_scene 基建+30 图)+战斗场景 16 biome 全覆盖+角色页档案化+章节封面 6 章 · Codex 多门视觉验收 PASS · D 段性能稳定性验证(8h/leak/ANR 逻辑层已验)+窗口 min size Pen 3/3 PASS + B1 release audit doc 同步(CLAUDE v1.17 测数 1667)+ P5.2 敌人内力按境界对称化 scale=0.20 + 文案 polish H 段全角标点 + #4③ 数值迁 yaml + V3 神物金掉落验收 3/3 PASS。git log `c97c682→880d7f7` 区间 + 各 closeout 完整可溯。


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
- **2026-05-26 P4.1 1.1 四项+audit v3+P5.2+Boss 招降叙事**(1484→1505 测 · 详各 closeout)
- **2026-05-27 Boss 招降叙事+debug 招募+R2 派单**(1505 测 · 详 `session_closeout_2026-05-27_boss_narrative_debug_recruit.md`)
- **2026-05-28 过夜清理+P3 三项+P2.1 4 批+drop 全覆盖+CHECKLIST v1.5+R4 派单**(1505→1519 测 · 详 `overnight_1_1_cleanup_handoff_2026-05-28.md` / `session_closeout_2026-05-28_p3_p1_triple.md` / `codex_dispatch_r4_p2_1_content_drop_2026-05-28.md`)
