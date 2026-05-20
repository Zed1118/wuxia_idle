# 5 波连击 session closeout(2026-05-21)

> **会话总览**:2026-05-21 主对话 Mac opus high+xhigh ~5h + Codex Pen 异步,5 波连击大里程碑收口。
>
> **HEAD**:`275487a` 全 push origin/main 0/0 同步
> **测试基线**:1127 pass + 1 skip + 0 fail / analyze 0 issues
> **PROGRESS.md**:100 行(= 100 cap)
> **commit 累计**:Mac 6 + Codex Pen 1 = 7 commit

---

## §1 候选 1 · 1.0 Demo §7 UI 完善阶段(美术接入)

**commit**:`3b5c36e` 7 文件 +226/-45,opus high ~1h
**前置**:stage_audit `art_assets_integration_visual_check_closeout_2026-05-21.md` 预估「2-5 工日 0→1 大改」

### Phase 0 reality check 关键发现
- `lib/features/character_panel/` + `lib/features/inventory/` + `lib/features/technique_panel/` **全部已建**
- `InventoryScreen` 396 行 / `EquipmentDetailScreen` 486 行 / `LineagePanelScreen` 314 行 全在
- **任务实质 = 加 Image.asset 接 path 字段,不是 0→1 大改**
- **拍板降档 opus xhigh → opus high + scope Option B(3 主接图 + 8 UI 资源全消费)**

### 实装范围
**3 主接入**:
1. `inventory_screen.dart _Row` 左侧 56×56 iconPath + tier 色边 + errorBuilder
2. `equipment_detail_screen.dart` 顶部 180h detailPath 大图 + paper_bg body 背景 alpha 0.12 + ink_divider `_SegmentDivider` 装饰
3. `lineage_panel_screen.dart _CharacterChip` 80×80 portraitPath(slotIndex 0/1/2 派生 GameRepository.masters)+ scroll_vertical 顶部 80h 装饰

**8 UI 资源全消费**(GDD §1 水墨克制):paper_bg / mountain_bg(MainMenu 远景 200h alpha 0.25)/ ink_divider / coin_icon(物料 16×16)/ lotus_icon + meditation_icon(TechniquePanel + Seclusion AppBar 24×24)/ scroll_vertical / scroll_horizontal(ChapterList AppBar bottom 36h)

### 教训 sink
- widget test Image.asset errorBuilder 触发不稳,纯 errorBuilder fallback text 可能 0 渲染 → Column 同挂图 + 文本(memory `feedback_image_asset_error_builder` 扩展)
- Phase 0 四维 grep 实战再印证「目录已建 vs 0→1 大改」误判(memory `feedback_phase0_grep_two_axes`)

---

## §2 候选 3 · Pen 工作树脏态处理

**commit**:无代码 commit(纯远程 git ops),SSH ~20min
**根因**:不是「git pack EOF 网络问题」,是 **partial clone 错配 promisor remote**

### 关键诊断
`git config --list` 发现:
```
remote.https://github.com/Zed1118/wuxia_idle.git.promisor=true
remote.https://github.com/Zed1118/wuxia_idle.git.partialclonefilter=blob:none
```
- HTTPS URL 作 promisor remote(非标准配置)
- `origin` 是 SSH URL(git@github.com)
- `git remote -v` 第一行 URL 占 name 位置无 fetch/push 后缀 = 非标准 remote 信号

`git reset --hard origin/main` 触发的 missing blob 拉取从 HTTPS promisor 走,反复 EOF → 看似网络问题,实际配置雷。

### 修复链
```bash
git config --unset 'remote.https://github.com/Zed1118/wuxia_idle.git.promisor'
git config --unset 'remote.https://github.com/Zed1118/wuxia_idle.git.partialclonefilter'
git fetch --refetch origin     # 全量 refetch
git reset --hard origin/main   # 这次过
```

### 教训 sink
- 新 memory `feedback_git_partial_clone_promisor_eof`:reset 报「unable to read sha1 file」/「fatal: early EOF」时第一反应不是网络,先排查 partial clone + promisor remote 错配;`git fetch --refetch` 一次救场
- handoff 原方案 A/B/C(SSH 代理 / Mac scp .git/ / 冷启动 clone)均不必要

### 副产物
- Pen F: 仓库 stash@{0}「before-reset-2026-05-21-candidate3」保留(CRLF 虚假差异 + Codex raw fallback 拉的文件 + libisar.dll/install_vs 本地 build 依赖)
- Pen Desktop 仓库 `C:\Users\Administrator\Desktop\wuxia_idle`(HEAD `b53b0d1` Phase 1 时代 v0.1.0-phase1 附近)保留作 Phase 1 历史镜像

---

## §3 候选 5 · round 2 视觉验收(综合 round 1 + round 2)

**commit**:派单 `9d5cb65`(Mac)+ closeout `6a6c21a`(Codex Pen)
**结果**:**round 2 9/9 PASS ✅**(round 1 已 4/4 PASS,综合 13 张图覆盖)

### round 2 截图清单(9 张全 PASS)
| # | 文件 | Screen | 验收点 |
|---|---|---|---|
| 01 | round2_01_main_menu_mountain.png | MainMenu | mountain_bg 顶部远景 200h alpha 0.25 + 9 按钮 |
| 02 | round2_02_chapter_list.png | ChapterListScreen | AppBar bottom 36h scroll_horizontal |
| 03 | round2_03_inventory_equipment.png | InventoryScreen 装备 Tab | _Row 56×56 iconPath + tier 色边 |
| 04 | round2_04_equipment_detail.png | EquipmentDetailScreen | 180h detailPath 大图 + paper_bg + ink_divider |
| 05 | round2_05_inventory_material.png | InventoryScreen 物料 Tab | _MaterialRow coin_icon 16×16 |
| 06 | round2_06_lineage_panel.png | LineagePanelScreen | scroll_vertical 80h + 3 portrait 80×80 |
| 07 | round2_07_technique_panel.png | TechniquePanelScreen | AppBar lotus_icon 24×24 |
| 08 | round2_08_seclusion_meditation.png | SeclusionMapListScreen | AppBar meditation_icon 24×24 + 5 地图缩略 |
| 09 | round2_09_home_feed_seal_baseline.png | HomeFeedScreen | seal_red 36×36(baseline 复核)|

**M4 #46 候选 1 实测视觉收口 100%**。round 1 (4/4) + round 2 (9/9) 合计 13 张图覆盖 8 Screen + 8 UI 资源 + 2 baseline。

---

## §4 候选 2 · 心法相生 §4.5 触上限 8 重设计

**commit**:`d8b98ff` 7 文件 +209/-19,opus xhigh ~1.5h
**前置**:P1 #45 closeout §96 列 3 候选方向(sameTier 高阶变体 / specificTechniques / 三流派 combo)

### 设计方向 3 选 1
| # | 方向 | 复杂度 | 贴 GDD 程度 | 选择 |
|---|---|---|---|---|
| A | 补回 synergy 8 lingQiao+yinRou + sameTier 排除 | 低(~1h) | 弱(只恢复 W18-A1.2 原设计)| ❌ |
| B | 加 specificTechniques 枚举(具体心法 ID 对)| 中(~1.5-2h) | **强**(GDD §4.5 「九阳+九阴」原意) | ✅ |
| C | 三流派 combo(threeSchool) | 中-高(~2-3h) | 中(GDD 无明确例子) | ❌ |

**用户拍板 B + opus xhigh**。

### 实装明细
1. **enum**:`SynergyRequirementType` 加 `specificTechniques`(放在第一位,detectActive 遍历自动按优先级)
2. **SynergyDef**:加 `requiredMainTechniqueId` + `requiredAssistTechniqueId`(nullable String)
3. **matches**:签名加 `mainTechniqueId` + `assistTechniqueId` 必填参数 + specificTechniques 分支
4. **detectActive**:优先级 `specificTechniques > schoolPair > sameSchool > sameTier`(enum 顺序保证),调 matches 传 `mainTech.defId` / `assistTech.defId`
5. **game_repository._enforceSynergyRedLines**:specificTechniques 类型必填 mainTechniqueId + assistTechniqueId + id 存在于 techniqueDefs(可选 + 反向 mainSchool/assistSchool 不应配)
6. **data/synergies.yaml**:加 synergy 8「太极初成」(主 `tech_gangmeng_chuanshuo` + 辅 `tech_yinrou_chuanshuo`,attack 0.20 + def 0.15 + hp 0.10 + internalForceMax 0.25 各 ≤ §5.4 红线 0.30)
7. **test**:synergy_def_test +4 case(3 matches + 1 fromYaml)+ game_repository_test synergies.length 7→8 + phase2_seed_service_test seedVisualCheckW18A1 yamlIds 过滤掉 specificTechniques 类型(fixture 角色 yiLiu·qiMeng cap=menPaiJueXue 不能拥有 chuanShuoShenGong 心法)

### 教训 sink
- **GDD 原意 vs yaml 落地简化的「精神回归」**:W18-A1.2 schoolPair 抽象类型是 Demo 阶段的落地简化(GDD 例子是「九阳+九阴」「降龙+打狗」「易筋经+少林外功」等具体心法对),candidate 2 加 specificTechniques 类型贴回 GDD §4.5 原意。设计文档与实现的语义差距 = 「重设计」的真正起点。

### 影响
- **Demo §8.4 心法相生从 7 → 8**(GDD §4.5 上限触满 ✅)
- detectActive 优先级链扩展,新 yaml synergy 8 不冲突现有 7 synergy(specificTechniques 优先级最高,但 fixture 5 角色 yiLiu 不触发,实际生产中需玩家修到 chuanShuoShenGong tier 才命中)

---

## §5 PROGRESS 整理 + memory sink

### PROGRESS.md
- 顶段 5 段 stacked → 1 主段(5 波连击)+ 5 bullet
- 新归档段「### M4 #46 美术详条迁出 2026-05-20/21」5 段 1-line summary
- self-cap 80 → 100 与 user CLAUDE.md 全局规则对齐
- 终态 100 行(= 100 cap)

### memory sink
- 新 memory `feedback_git_partial_clone_promisor_eof`(43 行)
- 扩展 memory `feedback_image_asset_error_builder` 加「单纯 errorBuilder fallback 在 widget test 中不稳」段
- MEMORY.md 索引 78 行(≤ 200 cap)

---

## §6 5 教训汇总

| # | 教训 | memory 落点 |
|---|---|---|
| 1 | Phase 0 四维 grep 实战再印证「目录已建 vs 0→1 大改」误判 | `feedback_phase0_grep_two_axes`(已存,本次又一锚点)|
| 2 | widget test Image.asset errorBuilder 触发不稳,Column 同挂图+文本 fallback | `feedback_image_asset_error_builder` 扩展 |
| 3 | partial clone promisor 错配 unset + refetch 救场 | **新** `feedback_git_partial_clone_promisor_eof` |
| 4 | Phase 0 reality check 驱动 spec 降档 + 缩 scope,工程纪律最佳实践 | 复用 `feedback_phase0_grep_two_axes` + `feedback_opus_xhigh_interactive_duration` |
| 5 | GDD 原意 vs yaml 实现的「精神回归」(W18-A1.2 schoolPair 抽象是落地简化,specificTechniques 贴 GDD 原意)| 未独立 sink(实战 anchor 较少,留下次出现再总结)|

---

## §7 累计 commit 链(本会话 7 commit)

| # | SHA | 描述 |
|---|---|---|
| 1 | `3b5c36e` | M4 #46 美术 候选 1 收口 · 6 Screen Image.asset 接入 + 8 UI 资源全消费 |
| 2 | `0f8bde3` | docs: PROGRESS 顶段更新 · M4 #46 候选 1 1.0 Demo §7 UI 完善阶段收口 |
| 3 | `9d5cb65` | docs(handoff): codex round2 视觉验收派单 spec · 9 张图覆盖候选 1 实装 |
| 4 | `641d46b` | docs(progress): PROGRESS 顶段压缩 5 段→1 主段+5 bullet · M4 #46 美术详条迁出归档 |
| 5 | `6a6c21a` | docs(handoff): codex round2 视觉验收 closeout 2026-05-21(**Codex Pen push**)|
| 6 | `d8b98ff` | [schema] 候选 2 心法相生 §4.5 触上限 8 重设计 · specificTechniques 新类型 |
| 7 | `275487a` | docs(progress): PROGRESS 顶段升级 5 波连击 · 候选 2 收口 + Codex round 2 9/9 PASS |

---

## §8 下波建议

### 路线图状态
- **1.0 Demo 阶段加权 ~95% → ~98%**(P0 100% / P1.1 ~60% / P1.2 待开 / **P1.3 美术 100% ✅** / Demo §8.4 14/14 全达标 + 心法相生 8 上限触满)
- 真硬阻塞 1.0 启动 0 项

### 下波候选(优先级)
1. **候选 4 · P2 第二条主线启动准备**(opus xhigh 2-4h 起手)— M5-M10 主战场,需先 audit lib/features/mainline/ 现状 + spec P2 entry point + 1.0 ROADMAP 拆分
2. **章节扩展 Ch4+**(1.0 路线图远期,Demo polish 100% 后可开)
3. **美术 LoRA 训练数据扩充**(候选 4 衍生,GDD §1 水墨基调强化,中国武器数据不足 3 件)
4. **Phase 5+ 师徒系统升级实装**(T07 已起草 spec,opus xhigh 8-12 工日,远期)

### 不阻塞但可顺手
- Pen F: stash@{0} drop(如不再需要 libisar.dll/install_vs 本地依赖恢复)
- pub direct 1 项 intl 0.19→0.20 可升(stage_audit 已建议)
- debug 1999 行偏多(stage_audit 建议留 P5)

---

**closeout 完结**。5 波连击大里程碑收口,M4 #46 美术 PoC + 心法相生设计两大主题完工。1.0 Demo 阶段加权 ~98%,真硬阻塞 0 项。下波 P2 主线启动准备 = 1.0 路线图新里程碑入口。
