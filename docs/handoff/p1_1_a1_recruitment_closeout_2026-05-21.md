# P1.1 A1 师徒 E.1 收徒弹窗 closeout(2026-05-21 三段)

> **会话总览**:2026-05-21 主对话三段(P2 audit closeout 后续)· Mac opus xhigh ~3.5h · 1.0 路线图 P1.1 系统纵深首项 A1 E.1 收徒弹窗完整闭环
>
> **HEAD**:`<本会话 commit 后填>` → 待 push origin/main
> **测试基线**:1127 → **1139 pass**(净 +12)+ 1 skip + 0 fail / analyze 0 issues
> **PROGRESS.md**:98 行(在 100 cap 内)
> **saveVersion**:0.11.0 → 0.12.0

---

## §1 会话三段落

### 1.1 段 A · 候选 0 顺手 ops(~1 min)
- 删 8 nightshift/T01-T08 local branch(reflog 30 天保险,内容已合 main),`git branch -D` 一行干净

### 1.2 段 B · 候选 1 Phase 0 audit + 5 决策拍板(~30 min)
- **Phase 0 四维 grep**:
  - 维度 A schema:`CharacterRecruitmentService` / `RecruitmentDef` / `recruitCandidates` / `recruit_candidates.yaml` 全仓 **0 命中**(校正 closeout §6.1 误写「service 已建」)
  - 维度 B caller:`_applyVictoryResolution`(stage_entry_flow:331)+ `_applyTowerVictoryResolution`(tower_entry_flow:263)+ tutorial step 6 hook(tutorial_service:84)已建可复用
  - 维度 C 邻近目录:`lib/features/character_panel/` 已建 4 文件;`lib/features/recruitment/` 不存在
  - 维度 D UI:`LineagePanelScreen` 已建 + `_LineageDisciplesRow` 显 discipleIds;**收徒 Dialog 未建**
  - 与 Phase 5 预研 `wuxia_phase5_master_disciple_prep_2026-05-17.md` 三方一致:Demo 不做 E.1,1.0 P1.1 阶段做(本会话进度)
- **3 方案对比**(audit doc §3):方案 1 完整扩容(4-6h opus,改 demo_max_characters 红线) / 方案 2 纯仪式(1-2h sonnet,弱 gameplay) / 方案 3 inactive 池(3-4h opus,中间路径不破红线)
- **5 决策 ✅ 全拍板**:
  - **M** = 方案 3 inactive 池收徒(active 上限不动)
  - **D1.b** 沿 `SaveData.activeCharacterIds` 列表 outside 即 inactive(无 schema bump for Character.isActive)
  - **D2.b** 3 NPC(刚猛 + 灵巧 + 平衡型)
  - **D3.a** 一次性 only(拜师 / 谢绝都 markOffered=true 不可重触)
  - **D4.b** 完整 UI(portrait + 4 属性 + 流派 chip + 起手心法/装备 + lore)
- 产出:`docs/handoff/p1_1_a1_recruitment_audit_2026-05-21.md` 313 行(§0 Phase 0 grep + §1 现状与三方一致 + §2 3 维 27 组合筛 3 方案 + §3 三方案对比 + §4 推荐路径 + §5 工作量拆分 + §6 风险与回退 + §7 候选 2-4 协同 + §8 待拍板汇总)

### 1.3 段 C · 候选 1 实装(opus xhigh ~3h)
**新建 5 文件**:
1. `data/recruit_candidates.yaml`(73 行):3 候选 NPC 完整配置(name/portrait/4 属性/流派/起手心法+装备/lore)
2. `lib/data/defs/recruit_candidate_def.dart`(73 行):`RecruitCandidateDef` 体例对齐 `MasterDef.fromYaml`
3. `lib/features/recruitment/application/recruitment_service.dart`(190 行):5 method · caller 持锁 · 幂等 · fail-fast
4. `lib/features/recruitment/application/recruitment_providers.dart`(42 行):`recruitmentService` / `recruitmentOffered` / `recruitedDiscipleIds` 3 provider
5. `lib/features/recruitment/presentation/recruitment_dialog.dart`(424 行):ConsumerStatefulWidget · 3 候选 Card · confirm dialog 二次校验

**改 8 文件**:
1. `lib/core/domain/save_data.dart`:加 `recruitmentOffered: bool = false` + `recruitedDiscipleIds: List<int> = []`
2. `lib/data/isar_setup.dart`:saveVersion `0.11.0` → `0.12.0`(注释加 P1.1 A1 E.1 条目)
3. `lib/data/game_repository.dart`:`recruitCandidates: Map<String, RecruitCandidateDef>` 字段 + load(fixture-friendly:starting refs 不全则视 fixture 模式静默 skip)+ `_enforceRecruitCandidateRedLines` 红线
4. `lib/shared/strings.dart`:加 16 条 recruitment 文案 + 2 条 inactive section 文案
5. `lib/features/tutorial/presentation/tutorial_banner_card.dart`:加 `onTapOverride: Future<void> Function()?` 参数,默认 null 走原 markHintRead 路径(step 7/8);非 null 时走 override
6. `lib/features/main_menu/presentation/main_menu.dart`:step 6 wire `onTapOverride` → push `RecruitmentDialog`(MaterialPageRoute);step 7/8 不传 override 保持原行为
7. `lib/features/character_panel/application/lineage_info_provider.dart`:`LineageInfo.inactiveDisciples` 字段 + 派生逻辑(recruitedIds ∖ activeIds → isar.characters.getAll)
8. `lib/features/character_panel/presentation/lineage_panel_screen.dart`:加 `_InactiveDisciplesSection`,空 inactive 列表时不渲染段头

**Test +12 全 pass**:
- +4 `test/data/game_repository_test.dart` red line:生产 3 候选 + 数量 ≠ 3 + lineageRole=founder + attributeProfile.total > 24
- +8 `test/features/recruitment/application/recruitment_service_test.dart`:hasOffered/getRecruitedIds 默认值 + getCandidates 升序 + declineRecruitment 写 markOffered + decline 幂等 + acceptCandidate 创 Character + accept 幂等(-1 返回值)+ candidateId 不在 yaml 抛 StateError

**回归 test 修复**:
- 5 处 `LineageInfo(...)` 旧 constructor 加 `inactiveDisciples: const []`(test/features/character_panel)
- 5 处 saveVersion `'0.11.0'` → `'0.12.0'`(test/data + test/features/encounter + test/features/equipment)

---

## §2 关键设计点

### 2.1 触发流程(T1 决议)
```
玩家境界突破 → 一流 (yiLiu) → tutorial step 6 hook 推进
  → MainMenu 渲染 step 6 banner(顶部红点)
  → 玩家点击 banner
  → main_menu onTapOverride 拦截(step==6 时)→ push RecruitmentDialog
  → Dialog 显 3 候选 + 拒绝按钮
  → 玩家选拜师 → confirm 弹窗 → service.acceptCandidate
       OR 玩家选谢绝 → confirm 弹窗 → service.declineRecruitment
  → 任一路径都:
     ① markOffered=true(D3.a 一次性)
     ② markHintRead(step=6) → 主菜单 banner 隐藏
     ③ ref.invalidate 3 个 provider → UI 全刷新
     ④ snack 反馈 + Navigator.pop 退 Dialog
```

### 2.2 inactive 池语义(D1.b 决议)
```
SaveData.activeCharacterIds = [1, 2, 3]  // 祖师 + 大弟子 + 二弟子(不动)
                                         // ← active 上限 3 红线不破

新弟子 Character id=4 (拜师后)
  → 存入 Isar.characters(Character.isActive=false 但语义不依赖此字段)
  → NOT in activeCharacterIds(D1.b 真判定)
  → SaveData.recruitedDiscipleIds = [4]
  → masters.discipleIds.add(4) 双向关系

求 inactive 列表:
  allCharacters.where((c) => !activeCharacterIds.contains(c.id) &&
                            c.lineageRole == LineageRole.disciple)
```

### 2.3 红线 fixture-friendly 设计
- 生产 `data/recruit_candidates.yaml` 完整加载 + `_enforceRecruitCandidateRedLines` 严格校验
- fixture loader 走 File fallback 读真实 yaml 但 fixture techniques/equipment 是 stub → starting refs 不全
- **预先校验 starting refs**:`_enforceRecruitCandidateRedLines` 之前的 load 段 + try 区块在 starting refs 不全时清空 recruitCandidates(视 fixture 模式)
- 红线 enforce 只在 `recruitCandidates.isNotEmpty` 时执行
- 12 个 fixture loader test 全部自动 pass,无需逐个加 stub yaml

### 2.4 与 tutorial 体例的解耦
- `TutorialBannerCard.onTapOverride` 是 nullable callback,默认走原 markHintRead → 关 banner
- step 6 时 main_menu 注入 override → push RecruitmentDialog
- Dialog 内部完成 markHintRead(关 banner)+ markOffered(防重触)
- tutorial 模块 0 知识耦合于 recruitment 模块,反向依赖避免

---

## §3 与候选 2-4 的协同(audit §7)

| 协同点 | 候选 1 ← 候选 2/3/4 |
|---|---|
| 候选 2 E.5 founder_ancestor_buff | 候选 1 落 inactive 池 → 候选 2 buff 作用域 = founder + active disciples + inactive disciples;数据基础已铺 |
| 候选 3 A3 共鸣度满级体验 | 候选 1 新弟子若装备 isLineageHeritage → 共鸣度 retention 0.7 启动;候选 3 关注的 joint_skill 表现层不直接受影响 |
| 候选 4 A4 开锋 3 槽 build | 候选 1 弟子 starting 装备 enhanceLevel < 10 → 不直接触发开锋,但弟子后续 forge 行为同 founder |

**结论**:候选 1-4 独立性强 + 候选 1 为候选 2 提供数据基础,串行推进顺序 1 → 2 → 3 → 4 合理。

---

## §4 commit 链(本会话)

| # | SHA | 描述 |
|---|---|---|
| 1 | 即将创建 | feat(recruitment): A1 师徒 E.1 收徒弹窗 · 方案 3 inactive 池 · audit + 5 决策 + 12 test |

---

## §5 待决 ops / 挂账

1. **本会话产物 commit + push**:本 closeout + audit + PROGRESS + 5 新文件 + 8 改文件 + 12 test 加/改(2 commit:1 主 feat + 1 docs/handoff)
2. **挂账(下波收口)**:RecruitmentDialog widget test 未加(loadAllDefs fixture 体例复杂,候选 5 一并加 / 或下次)
3. **portrait 占位**:`assets/characters/recruit_candidate_{a,b,c}.png` 文件不存在,Image.asset errorBuilder 已兜底返回 avatarFill;M4 美术阶段补充 3 张 portrait 自动生效

---

## §6 教训 sink

| # | 教训 | memory 落点 |
|---|---|---|
| 1 | closeout 描述「service 已建」需 Phase 0 grep 实测校正 — closeout §6.1 误写,grep 0 命中校正 | `feedback_closeout_numbers_grep`(已有,本次又一锚点)|
| 2 | yaml 引用 def id 必须 grep 实测,不可凭推测命名(`xiangyanghuo` vs `xiangyang`)| 已沉淀 `feedback_phase0_grep_two_axes`(维度 A schema 实测)|
| 3 | red line fixture-friendly 设计:starting refs 不全时静默清空 + 红线 enforce 跳过,避免 12 个 fixture loader 逐个加 stub | 未独立 sink(实战 ≥3 次再总结)|
| 4 | tutorial banner 加 onTapOverride callback 解耦反向依赖(recruitment 不污染 tutorial 模块)| 未独立 sink |

---

## §7 下波 P1.1 候选 2 入口(新会话 / 本会话续推用)

### 7.1 任务
- **候选 2** A1 师徒 E.5 founder_ancestor_buff(`numbers.yaml inheritance.founder_ancestor_buff.enabled_when_alive: false → true` + `sect_wide_buff` 数值激活)
- **GDD 锚**:§7.1 飞升后祖师爷 sect buff;CLAUDE.md §12.2 #11 v1.5 决议「Demo 不实装,1.0 版本激活」 → P1.1 收口本项

### 7.2 Phase 0 reality check 必跑维度
- 维度 A schema:`grep founder_ancestor_buff numbers.yaml + grep ancestor lib/`
- 维度 B caller:`grep applyFounderBuff\|sectWideBuff lib/` + 是否有 stats service 钩子
- 维度 C 邻近目录:`find lib/features/inheritance lib/features/sect` 等
- 维度 D UI widget:LineagePanelScreen 是否有「祖师爷 buff」一栏

### 7.3 模型选型 + 估时
- **opus xhigh ~1-2h**(跨 inheritance + character + save_data + UI 4 模块)— audit 决议候选 2 估时
- 若实装时发现 buff 公式跨多 service(stats + battle + 修炼度)→ 可能升到 2-3h

### 7.4 提示词体例
开局必读:PROGRESS.md(顶段)+ 本 closeout § 7 + audit `p1_1_a1_recruitment_audit_2026-05-21.md`(§7 协同)+ memory `feedback_phase0_grep_two_axes`

---

**closeout 完结**。本会话 P1.1 候选 1 A1 师徒 E.1 收徒弹窗 audit → 5 决策拍板 → 实装 → 12 test 净增 → 0 regress 一波闭环。1.0 路线图 P1.1 第 1 项 ✅,下波候选 2 A1 E.5 founder_ancestor_buff(opus xhigh 1-2h)推进 P1.1 收口路径。
