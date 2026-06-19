# 第七阶段·批三·队伍成长 设计

> 2026-06-19 · brainstorm 拍板 · opus xhigh
> 「做 2+3」三批之批三(批一战后体验✅ / 批二 Boss 机制✅ / 本批=队伍成长)。
> 范围拍板:**① 渐进解锁 + ③ 二弟子控制差异化 + ④ 开局体验**(不做 ② 编成 UI)。

## 1. 一句话与目标

把开局从「一上来 3 人满队」重塑成「孤身祖师 → 早期剧本节点收徒 → 队伍渐进成长(1→2→3)」的弧线,并让三角色在战斗中职责三分。**全程不碰伤害公式量级、不加属性、不发明新战斗机制**(守 §5)。

玩家体感:孤身闯江湖寡不敌众(§5.7 先感受问题)→ 大弟子拜入有了帮手 → 二弟子拜入满队 → 三人各司其职(爆发/破防/控场)。

## 2. 现状基线(摸排实测 · file:line)

- **开局即 3 人满队**:`onboarding_service.dart:95-99` 写 `activeCharacterIds=[1,2,3]`,大弟子/二弟子是 `masters.yaml` 开局种子直接给,**无单人阶段**。
- **LineageRole**(`enums.dart:160`)现 3 值 `founder/disciple/grandDisciple`,**两弟子都是 disciple 无区分**;`Character.lineageRole` @Enumerated(EnumType.name) 落盘(`character.dart:90`)。
- **关卡线性链**:Ch1 = 01_01→_02→_03→_04(小Boss)→_05(章末大Boss),前 5 关全 1v3,早期流民弱(HP 1500-3800/Atk 80-165)。`prevStageId` 链式解锁。
- **通关 hook 接线点**:`stage_entry_flow.dart` victory 流程(line 182-292),已有 `triggeredBossRecruitStageIds` 一次性防重模式 + `clearedStageIds`。
- **autoFill 职责倾向**:`skill_loadout.dart:94-129` 现「disciple→破防(`defenseBreakPct>0`)」;founder 已 power 降序。
- **控制机制盘点**:无减速/定身/stun;可复用 = 踉跄 stagger(`battle_state.dart:186`)、蓄力打断(`canInterrupt` 技,`default_ground_strategy.dart:703-722`)、内伤(阴柔独占)。
- **招式内容**:3 破防技(`defenseBreakPct>0`)+ 3 破招技(`canInterrupt`),三流派各一,**够用零新招式**。
- **saveVer = 0.24.0**(`isar_setup.dart:121`)。

## 3. 设计

### A. ① 渐进解锁 + 开局重塑

- **新游戏**:`OnboardingService` 只种**祖师单人**(`activeCharacterIds=[祖师]`)。大弟子、二弟子采用**懒创建**——到剧本节点才 `buildMasterCharacter(masters[slot])` 从 masters.yaml 建角色入队(天然「还没遇到」,无需到处过滤隐藏)。
- **加入触发**(数据驱动 · 配置进 yaml 不硬编):
  | 触发关 | 加入 | 角色 role |
  |---|---|---|
  | 通过 `stage_01_02` | 大弟子(masters slot 1) | senior |
  | 通过 `stage_01_04`(小Boss) | 二弟子(masters slot 2) | junior |
  - 满队迎章末大Boss 01_05。
- **接线**:挂 `stage_entry_flow.dart` victory 流程,复用 `triggered…Set` 一次性防重(新增 `triggeredDiscipleJoinStageIds`);join 配置读 yaml(`lineage_onboarding.disciple_joins: [{stageId, masterSlot, role}]`)。

### B. ③ 三角色职责差异化

- **LineageRole** 加 `senior`/`junior`(**保留 `disciple` 值**供老档反序列化安全,迁移后无角色再用)。三角色职责:祖师→爆发终极 / 大弟子(senior)→破防开窗 / 二弟子(junior)→破招打断控场。
- **autoFill**(`skill_loadout.dart`):现「disciple→破防」拆成 **senior→`defenseBreakPct>0` / junior→`canInterrupt`**;founder 不变。
- **battle_ai**:给 junior(`lineageRole==junior`)「优先打断敌方蓄力技」更高权重(~30-50 行,复用现有破招/蓄力机制接入点 line 64-66/72,新增可选职责分支)。
- 职责 = **autoFill 软倾向 + AI 优先级**,非硬锁、不改伤害量级、不加属性 → 守 §5.4。

### C. ④ 拜入仪式

过关后:短**拜师 narrative**(复用 `NarrativeReaderScreen`,文案进 `data/narratives/`)+ **HeroCameraOverlay 立绘切入**(批一基建复用)+ 题字「XX 拜入门下」(UiStrings)。接入点同 §A 的 victory hook,排在 victory narrative 之后、其它 hook 协调位。

### D. 存档迁移(saveVer 0.24.0 → 0.25.0)

老档(已有 [1,2,3] 满队)迁移两步:
1. 两个 join 关 id 预填进 `triggeredDiscipleJoinStageIds`(hook 不再触发、不重复建角色)。
2. 现有 `lineageRole=disciple` 按顺序重映射:**先(id 小/discipleIds 序)→ senior,后 → junior**。
**老玩家的弟子一个不动**(数据零丢失,只补 role + 防重触发)。

### E. 内容产出

- 2 段短拜师 narrative(`data/narratives/`):大弟子(过 01_02)、二弟子(过 01_04)。
- UiStrings 题字词条「XX 拜入门下」等。
- yaml(numbers 或新 config)加 `lineage_onboarding.disciple_joins` 触发表(stage→master slot→role)。

## 4. 红线自检(§5)

| 红线 | 守法 |
|---|---|
| §5.1 反抽卡 | 弟子走确定性剧本节点,非随机抽取 ✓ |
| §5.3 三系锁死 | 弟子照常受境界↔装备阶↔心法阶约束,本批不碰 ✓ |
| §5.4 数值红线 | 职责走 autoFill 软倾向 + AI 优先级,不加属性/不改伤害公式量级 ✓ |
| §5.5 在线=离线 | 单人开局不影响离线挂机收益(active 队伍照常) ✓ |
| §5.6 不硬编码 | 文案进 data/narratives、中文进 UiStrings/EnumL10n、触发进 yaml ✓ |
| §5.7 先感受后给答案 | 先感受孤身寡不敌众,再得弟子相助;拜入走 narrative 非教程弹窗 ✓ |

## 5. 范围外(明确不做)

- **② 编成 UI**:Demo 正式角色 ≤3,出战即全部,编成屏无可选项 = YAGNI。
- **现有 `bossRecruit`**(01_05/02_05/03_05 把通用 sect_candidates 弟子塞 inactive 池):既有行为,与命名弟子两套角色,本批不碰。

## 6. 工程量预警

- 改 onboarding 为单人开局会**冲击大量假设「开局 3 人满队」的测试**(断言 `activeCharacterIds==[1,2,3]` / 直接取弟子角色的测试)。需改成显式 join 弟子或加测试 helper(如 `seedFullTeamForTest`)。这是本批主要工程量来源之一,plan 阶段专门处理。
- LineageRole 改枚举 → Character.g.dart 需 build_runner 重生成(.g.dart gitignored)。
