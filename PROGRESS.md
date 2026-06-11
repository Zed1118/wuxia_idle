# 挂机武侠 · 开发进度

> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

> ✅ **2026-06-10 续(音频接入 v1 · §12 上线门 E 段素材落位)**:3 BGM + 8 SFX 真素材入库 `assets/audio/{bgm,sfx}/`(**零 Dart 改动**,文件名按 enum 约定,SoundManager 缺素材 no-op 兜底保留)。**BGM**:mainMenu/seclusion=V2 裁切版 candidate_01(128s/148s · 初筛推荐),battle=V1 candidate_01(122s · V2 battle 全 <18s 不合格 · 裁头 0.6s 静音防 loop 空白)。**SFX**:uiTap/uiTabSwitch=V2 tap 两 take 分用(tap +6dB)· battleHit=hit_01 / battleStagger=hit_02(-3dB 次级提示)· battleCrit=crit_02 · battleInterrupt=interrupt_01(+7dB)· **转用**:battleUlt=realmAdvance_v2_01 裁 2.4s+淡出 / battleChargeStart=defeat_v2_02(负向预警)。**留空**:uiPaperOpen(V2 prompt 未产出,no-op)。**迭代1(真玩反馈)**:battle BGM **-6dB**(原盖过战斗音效)+ 新增 `SfxId.victory` 接「勝」结算 overlay(leftWin)+ 既有占位 `reward` 接**主线+塔胜利 dialog 装备掉落**(纯道具/空掉落不响)——victory/reward 用 V1 jingle 3s 剪辑版(loudnorm -16 LUFS,音乐性强补「惊喜震撼感」)。dialog sfx 守卫测 +3。**迭代2**:`BgmScope` 加 scope 栈(dispose 恢复上一层轨道,修「战斗退主菜单 BGM 不切回」)+ bgm_scope 测 +2。**顺带抓到** main checkout `.g.dart` 过期(P1b worktree 跑的 build_runner 没带回,Character 装配槽不入 Isar schema → 装配不落库),已重生成(memory `feedback_wuxia_pen_build_runner` 的 main checkout 变体)。**全量 1883→1888 测**(+5)/1 skip main checkout 实测全绿(.g.dart 重生成后基线坐实)。剩余 jingle(defeat/realmAdvance)+扩展 BGM 8 轨=backlog(`playability_phase2_backlog.md` §七)。

> ✅ **2026-06-10 续(可玩性 P1b 藏经阁+技能装配全闭环 · subagent-driven 11 task · worktree-p1b-cangjingge)**:把 P1a「已解锁但玩家看不见/用不上」接到可见可操作。**schema** Character +5 装配槽(主2辅1共1大1 · 奇遇复用第6槽 `equippedEncounterSkillId`)+ saveVersion 0.16→0.17。**纯域** `SkillLoadout.autoFill`(只填空槽 / 主修2按 power 降序 / 大招≥阈值[yaml] / 共鸣=joint / 境界 gate 用 canEquipAtRealm)。**service** `SkillLoadoutService`(equipSkill sealed gate 结果 + applyAutoFill 落库)。**注入** `BattleState.fromCharacter` availableSkills 改读 6 槽(**5 心法槽全空→fallback 主修全招**,护旧存档/现有测试)+ 删 joint 特殊注入(改走共鸣槽)。**wire** 进战斗前 + 进藏经阁 autoFill(抽 `SkillLoadoutResolver` 共享,非复制)。**UI** `CangJingGeScreen`(6 槽出战配置 + 武学库按主/辅修分组 `SkillProficiencyRow` + 残页 `FragmentProgressRow` + 进入 autoFill)+ 换招 picker(沿 encounter 体例 gate 灰显)+ 熟练度阶段名走 UiStrings 映射 + 主菜单入口 §5.7 门控。**闸门** analyze 0 / 全量 1857→**1883 测**(+26)/1 skip / TDD 先红后绿 / 两阶段 review(控制方读 diff + 全仓 analyze)。**留 backlog**:破招 build gate(§9.1) / 24 招内容 / source tag / 奇遇槽 gate 对齐。spec+plan `docs/superpowers/{specs,plans}/2026-06-10-cangjingge-skill-loadout*`。

> ✅ **2026-06-10 续(B3 题字水墨墨团升级 · 接 Codex B3 复验 FAIL)**:Codex B3 FAIL(题字衬底=规则圆角矩形框非墨团)查为判据/实现错配 —— B3 与已 PASS 大招题字共用 `UltimateCaptionContent`,FAIL 暴露真问题(水墨感不足),用户拍板**升级**。MJ 泼墨圆团 _1_3 抠图(**纯 numpy 连通域**从墨团重心 flood 去纸纹矩形雾 + 亮度→alpha 浓淡 + 羽化 → `assets/ui/mj/caption_ink_blob.png`)→ `UltimateCaptionContent` 改 Stack:`ColorFilter.srcIn` 染 accent 色晕墨团(暖金破招/绛红敌 · 浓淡靠 alpha)+ `errorBuilder` 兜底回旧矩形 + 浅宣纸字 `WuxiaUi.paper` 深墨描边两层 Text。**大招+破招题字一并升级**(共用 widget,overlay 动画不动)。闸门 analyze 0 / caption 测族 4→**5**(+errorBuilder 缺图守 · find.text→findsNWidgets(2))/ `visual_capture battle_interrupt_caption` 两档 Flutter 终验 PASS(墨团飞白有机、无矩形雾、浅字描边醒目)。spec `docs/superpowers/specs/2026-06-10-ultimate-caption-ink-upgrade-design.md`。**B5 battle_defeat 验收图补齐 PASS**(2026-06-10 续 · bg `visual_capture` 这次稳出两档 1280×720+1920×1080 · 我读图:敗题字水墨绛红晕染 + 败北面板宣纸笺/破招提示/战报「18640·暴击7·42回合」/继续 CTA · 低分辨率不溢出 · 验收环闭合)。

> ✅ **2026-06-10(B3 破招「破！」题字转场 + B5 败北页路由 · 合 main `98f95ede` · 1856 测)**:`BattleAction.interrupted` + battle_screen 弹题字 + `battle_interrupt_caption`/`battle_defeat` 两视觉路由。Codex 复验已收口(机制 e2e 7/7 + 题字 PASS + `battle_charge_break` route autoStart:false 不可真玩 → 真玩破招走真实关卡 stage_02_05)。详 session 记录。

> ✅ **2026-06-10 overnight（可玩性 P1a 养成内核全闭环 · `feat/p1a-cultivation-core` 15 commit 合 main · da94ec3）**：subagent-driven 16 任务全落。**单元 C 熟练度**(C1-C6)：numbers `skill_proficiency` 5阶(1.00→1.30)+ `SkillProficiency` 纯域(combinedMult 130% cap)+ `SkillDef.proficiency.effects` + damage_calculator `proficiencyDamageMult` **双路径 wire**(Character + 实战 `_calculateInBattle` 经 `BattleCharacter.skillUses` 进场快照)+ per-skill cooldown/破招窗口，实战验证 900→1170。**单元 A 解锁进度**：`SkillUnlockEntry` @embedded + `SkillUnlockService`(阈值幂等 · Isar list growable 修复)。**单元 B Boss掉书**：`StageDef.dropSkill*` 红线 + victory hook(首通快照)。**D1** 3主线真解 + proficiency.effects；**D2** `SkillDef.canEquipAtRealm` §5.3 gate；**E1** +30% 相对 cap 红线测。**闸门** analyze 0 / 全量 1809→**1846 测**(+37)/1 skip / balance 3000run 全过 / §5.4 守。两轮只读 review(C / A·B·D·E)。续补**残页 tower wiring**(`f4b1c7b2`):TowerFloorDef.dropSkillFragmentId + 红线 + hook 泛化 + tower flow wire(floor 10/20,每次Boss胜利rng掉) → **残页端到端可用**(全量 1853 测)。**剩余 deviation**(backlog 六):解锁态消费=P1b / interrupt_power_pct schema-only / source tag 降级。**待明早一起**：视觉验收相关(B3+B5路由/音频/真玩)全留。详 `docs/handoff/p1a_cultivation_core_closeout_2026-06-10.md`。

> ✅ **2026-06-09(四批续 · 详各 session/closeout/plan)**：① P0 手动 Boss 破招全闭环(战斗内力每场预算 + Boss 蓄力状态机 + 破招打断踉跄减防 + 破势/青锋绝 · 合 `8373a9e` · 1801 测)② 视觉路由 `battle_charge_break`(autoStart 开关 + scenarioChargeBreak seed · `992dc76`)③ 音频系统全闭环(SoundManager/AudioBackend + 三类 hook + 零素材 no-op · 合 `1a92532` · 1778 测)④ P1a spec+985 行 plan + Suno 59 音频体检 + Codex P0 UI 验收(6 PASS/4 FAIL=覆盖缺口 · B3/B5 待返修)。

> ✅ **2026-06-05..09 归档**(UI kit v1 序 0 = 9 组件 + `WuxiaUi` token · Codex 两天 UI 包装/MJ 56 张接入 `a195547` · §5.6 硬编码审计抽 UiStrings/T5 闭关地图化/截图基建/心法 cover 重出 `c991984` · 1713→1763 测/0 analyze):详 git log `feat/ui-kit-v1`→`e767c42` + 各 closeout/plan。

> 🎨 **2026-06-04 续(8 张装备图重出 + 工作树清理 + UI 包装改造方案 v1)**:① **8 张产品照/借线感装备 detail 重出归位**(铜铃/蛇胆丸/平安扣/棉甲/短褂/锁子甲/铁片甲/柳叶刀 · 白底产品照/藏品照 → MJ v7 水墨统一风格,**配方=主环境 sref `ae8355ca` + `--sw 50`**〔先前漏写,这批坐实是装备 detail 核心配方〕+ 题字朱印 + 7阶梯度词 + 柳叶刀锁 dao 无 jian 漂移 · pngquant+oxipng 244-361KB · 读图选片归位 `229e7ea` · 派单 `mj_equipment_reshoot_productphoto8_2026-06-04.txt`)。② **工作树清理**(drop stash + macos 构建产物/`.claude/` 入 .gitignore + skip-worktree 屏蔽 pbxproj 噪音 · `5f83d31` 已 push)。③ **UI 包装改造方案 v1 · brainstorming 收口**(承外部 UI 评估「系统页停在 Flutter 功能面板视觉语言」· 力度=**重度游戏化重做** · 9 组件 UI kit〔TitleBar/PlaqueTab/PaperPanel/SectionHeader/ItemSlot/MeridianBar/SealBadge/PlaqueButton/PaperDialog〕+ 母题 token/红线〔宣纸/墨边/木牌/朱印/卷轴 · 不走网游金光〕+ 5 核心屏〔主菜单/角色/仓库/详情/战斗胜利〕· **真实资产 demo** `docs/handoff/ui_mockup_v1/`〔python http.server 预览,主菜单三版对比后**定 C 宣纸笺**〕· spec `docs/superpowers/specs/2026-06-04-ui-packaging-pass-v1-design.md` · `9ea8f4f`)· **下一步 = writing-plans 拆实现计划,kit 先行**(0 代码尚未动)。

> ✅ **2026-06-04 续(P0-3 ②③ 主修 hero + 心魔成长瓶颈面板 · xhigh · `f9425b8`)**:角色卡核心玩法视觉收口最后一块。**②** 主修心法 tile hero 化(`WuxiaPaperPanel` 宣纸底〔包 `IntrinsicHeight` 解滚动列无界高度〕+ 主修真名 `techniqueDefs[defId].name` 加大 20px 校色 + 阶名/段位/进度条保留;辅修不动)。**③** 心魔成长瓶颈面板(武圣**常驻** · 旧 `_BreakthroughBlockerSection` 仅「被拦窗口」显 → 改常驻 X/7)——3 层纯单元:`InnerDemonProgress.from`(派生 clearedCount/totalCount〔派生不硬编码 7〕/nextUncleared)+ `resolveInnerDemonPanel`(cleared/blocked/inProgress 三态 + 非武圣/空配置 null)+ `InnerDemonProgressPanel`(泛化旧 blocker,纯渲染);`innerDemonProgressProvider` 从 `mainlineProgressProvider` 派生(单一真相源 = clearedStageIds);「突破」CTA 仅导航不引新机制(进阶仍自动)。文案全 `UiStrings`。验收 seed `seedCharacterPanelGrowth` + route `character_panel_growth`(祖师 bump 武圣·熟练 exp满 → 2/7 被拦,不动被广依赖的 seedMasterDisciple)。**brainstorm→spec→plan→TDD 9 task 全流程** · 只读对抗式 review 2 findings(total==0 空配置 → 采纳改 null;IntrinsicHeight 无界高度 → 误报,测证 takeException null 保留)· 全量 **1697→1712 测 / 0 analyze** · 验收包重编 @ `f9425b8`(hub)· 派单 `codex_vis_char_panel_bc_2026-06-04.md` 待 Codex 截图。spec/plan 见 `docs/superpowers/{specs,plans}/2026-06-04-p0-3-bc-*`。**待 Codex 视觉验收 PASS 后核心玩法视觉 pass(战斗+角色页+仓库)全闭环**。

> **2026-06-01..03 详条已压缩归档**(git log/closeout 完整可溯 · 1661→1697 测/0 analyze):① **P0-2 战斗单位可见化全闭环**(玩家立绘+单位放大 110+死亡 grayscale+弹道笔触+受击闪+折叠日志+胜负 vignette · 弹道/受击走 actionLog 不写 BattleState 红线 · `c7fb79c`)② **P0-3 角色卡 ① 装备外观可视化**(装备槽 iconPath+tier 色 _EquipGlyph)③ **P0-4b 仓库格子化实装**(列表→部位分组网格+tier 边框+强化徽章+师承标+境界锁灰化 · `2049265` · Codex R3 PASS `880d7f7`)④ **装备 detail 45 件 + 敌人图 37/37 全归位**(美术缺口归零 `239d1d9` · 129 敌人图 + 80 装备 detail)⑤ **验收提速基建**(`VISUAL_ROUTE=hub` 一次 build 点遍 12 路由 + `tool/build_acceptance.sh` 预编 · `d94a56a`)。详 `docs/handoff/overnight_2026-06-03_handoff.md` + 各 closeout。

> **2026-05-30..06-02 出版美术 pass(1.0 Presentation Pass)全闭环已归档**(1581→1667 测/0 analyze · `docs/PUBLISHING_ART_PASS_1_0.md`):战斗屏(主菜单水墨山门 + B1 背景按 biome 接线+scrim+胜负仪式 overlay + B2 大招题字+Boss 金边)+剧情屏(narrative_scene 基建+30 图)+战斗场景 16 biome 全覆盖+角色页档案化+章节封面 6 章 · Codex 多门视觉验收 PASS · D 段性能稳定性验证(8h/leak/ANR 逻辑层已验)+窗口 min size Pen 3/3 PASS + B1 release audit doc 同步(CLAUDE v1.17 测数 1667)+ P5.2 敌人内力按境界对称化 scale=0.20 + 文案 polish H 段全角标点 + #4③ 数值迁 yaml + V3 神物金掉落验收 3/3 PASS。git log `c97c682→880d7f7` 区间 + 各 closeout 完整可溯。

> **2026-05-30 H1 修复批全闭环已压缩归档**(`58c6f29`→`2dd597b` · 1555→1569 测 / 0 analyze):批1 主菜单 7 未解锁系统 §5.7 门控 + 门派名迁 UiStrings · 批2 `EquipmentService.equip/unequip` 装备穿戴入口(修核心循环断裂 · §5.3 守卫 + picker)· 批3 掉落 dialog 品阶仪式感 + 闭关装备名 bug + 凝练常驻态 + 过场调色 + tick→回合术语 · picker「他人装备中」移装标注。详各 commit/closeout。

> **2026-05-29 详条已压缩归档**(全程 commit/closeout/git log 完整可溯,1534→1555 测):① 方向调整(F/G Steam 搁置 · H 段升主聚焦 · balance_simulator PoC)· H1-Q1 主菜单产品名 P0 清零 · H2/H3/H1 三部曲 audit(`h{1,2,3}_*_audit_2026-05-29.md`)② 外部 review 修复批 P1-a 飞升 auto_swap §5.3 守卫 / P2-a 奇遇招式池空 fail-fast / P2-b 敌人属性抽 numbers / P2-c 战斗公式双路径收敛单一真相源 / P3 三文档血量公式 drift 对齐(commit `559455f`/`f719172`/`62b0b7e`/`2686815`/`1afc888`)③ 根因A 挂机循环重平衡 B1+B2+B3 实装(共鸣双管+闭关 EXP+insightPoints sink · `a359dc2`/`d7ee3f9`)+ B2 低 tier EXP 回 ×1.0 修正 + idle_economy 验证 · 红线值统一 numbers.yaml(`7a1d1e7`)· balance_simulator 升真 build + floor/ceiling bracket + on-level 修正 ④ D 段难度修复:stage_01_05 Ch1 Boss +2 阶硬墙(`781c85b`)+ stage_05_05 跨阶过苛缓和(`24cea80`)→ 过难关清零。

> 2026-05-28 三条(CHECKLIST v1.5+ROADMAP v1.8+R4 派单 / 装备 drop 全覆盖+P2.1 4 批 / P3.2.B+P1.2+P3.x+过夜清理 · 1508→1519 测)已归档,详末尾「2026-05-25/26/27/28 详条归档」段。

---

**2026-05-25/26/27/28 归档**:见末尾归档段。

## 已完成(近 W6 起,早期归档见末尾)

> W15 + W17-W18 + P5+ + P3.1+P3.2+心魔+Ch4-6 详条均已归档,详末尾归档段。

## 已知偏差 / 挂账事项

- ~~#37-#45 / stage_05_05 跨阶墙 / equipment_detail '(基 $base)' nit~~ 全销账(2026-05-17..06-08):详各 closeout + 末尾归档

> 已销账条目(#1-#45)详见末尾归档。**P1 阶段全销账 ✅** + **Demo §8.4 14/14 全达标 ✅** + **1.0 ~95% release ready ✅**(A+B+C 全 PASS · 剩 D-G 留 M15-16)。

## 关键约束(每次开局必读)

- 数值红线:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000(GDD §5.2)
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

### P1.1 候选 1-5 详条迁出 2026-05-21

5 候选全收口(4 实装 + 1 doc):候选 1 收徒池 E.1 / 候选 2 祖师爷 sect_wide_buff / 候选 3 共鸣度 4 子任务 + joint_skill / 候选 4 开锋 build / 候选 5 CLAUDE.md §12 对齐 — `p1_1_*_closeout_2026-05-21.md` 5 closeout。

### M4 #46 美术 + Ch4 Phase 2 详条迁出 2026-05-20/22

- **M4 #46 美术** 5 段(2026-05-20/21):Stage 2 W1-W6 74/74 + assets 89 张 + stage_audit + #45 Demo §8.4 · 详 art_poc_* / art_assets_integration_* / p1_45_demo_polish_*
- **Ch4 1.0 P2 第二条主线第 1 章**(2026-05-21/22):Phase 2.1-2.5 全收口 + 13 narrative ~5,880 字 · 详 p1_x_chapter4_phase2_*

### 2026-05-22/23/24 详条归档

- **2026-05-22 Ch5 + Ch6 飞升 P2 主线全闭环**(2 章 ~12,438 字 · 师父三句遗言完整连通 · 小铜镜+玉佩 hook 闭环 · 详 `p2_x_chapter{5,6}_phase2_full_closeout_2026-05-22.md`)
- **2026-05-23 心魔 Batch 2.1-2.5 + P3.1 轻功对决**(8h overnight worktree · 7+5 关 · 详 `p2_x_inner_demon_final_closeout_2026-05-23.md` + `p3_1_lightfoot_closeout_2026-05-23.md`)
- **2026-05-24 P3.2 群战守城 + P3.1.B 子批 + P5+ 多代飞升 + 真传位 + 8h overnight v2/v3 + nightshift v2 首跑 + UI polish**(git log `efc7604 → b6d8191` 区间 · 详 handoff `p3_2_*` / `p3_1_b_*` / `p5_lineage_full_closeout_2026-05-24.md` / `nightshift_v2_first_run_closeout_2026-05-24.md` / `8h_autonomous_handoff_2026-05-24.md`)
- **2026-05-25 v2.1 工具完善 + T17-T22 cherry-pick + T23/T24 6 关键问题闭环批**(main `74ba519 → b6d8191` · 1458 测 / 0 analyze · 批次质量 A 9.05/10 · P1.2 江湖恩怨+声望 100% + 技术债 3 合一 · 详 `session_closeout_2026-05-25_nightshift_6h_review.md` + `p1_2_jianghu_full.md` + `p3_tech_debt.md`)

### 2026-05-25/26/27/28 详条归档

- **2026-05-25 P4.1+P5.0+audit v2**(1458→1484 测 · 详各 closeout)
- **2026-05-26 P4.1 1.1 四项+audit v3+P5.2+Boss 招降叙事**(1484→1505 测 · 详各 closeout)
- **2026-05-27 Boss 招降叙事+debug 招募+R2 派单**(1505 测 · 详 `session_closeout_2026-05-27_boss_narrative_debug_recruit.md`)
- **2026-05-28 过夜清理+P3 三项+P2.1 4 批+drop 全覆盖+CHECKLIST v1.5+R4 派单**(1505→1519 测 · 详 `overnight_1_1_cleanup_handoff_2026-05-28.md` / `session_closeout_2026-05-28_p3_p1_triple.md` / `codex_dispatch_r4_p2_1_content_drop_2026-05-28.md`)
