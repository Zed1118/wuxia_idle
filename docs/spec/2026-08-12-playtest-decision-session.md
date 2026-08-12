# 真机决策局清单(2026-08-12)

> 本清单为「备局」产物:把项目主人一次坐下(约 30-60 分钟)清掉 8 项积压决策所需的一切备齐。
> **本清单不替人做决定**,只把「要定什么 / 看哪里 / 有哪些选项 / 已有什么证据 / 拍完改什么」摆出来。取舍留白。
> 配套启动脚本:`tools/playtest/decision_session.sh`(分步、可中断、可从任意步继续,带 `--dry-run`)。

---

## 一页速览

| 步 | 编号 | 一句话 | 组别 | 预计耗时 |
|---|---|---|---|---|
| 1 | 一#17 | 桃花岛入口背景图四张候选取舍 | A·视觉 | 15min |
| 2 | 一#19(实为 P11 视觉档位化) | 资质 chip 六档的视觉表达方向 | A·视觉 | 5min |
| 3 | 二#7 | 战斗屏立绘融合观感是否调 | A·视觉 | 5min |
| 4 | 一#4 | 丹房强度(已定不动)复核 | B·玩 | 10min |
| 5 | 一#5 | 残页集齐数量(默认 5)是否调 | B·玩 | 10min |
| 6 | 一#6 | 高熟练度难度微调候选 | B·玩 | 15min |
| 7 | 一#18 | 死链扫描器「可试用·非终审」定位是否升级 | C·桌面 | 3min |
| 8 | P12 | 远端 4 个遗留备份分支是否删 | C·桌面 | 3min |

**时间总和:约 66 分钟**(略超 60)。A 组连看 25min + B 组连玩 35min + C 组连清 6min。

**最少必做子集(约 45 分钟)**:A 组全做(25min)+ C 组全做(6min)+ B 组选做一#5 或一#6(10-15min)。跳过一#4(已定「不动」,只需口头确认不改)与 B 组另一项。B 组三项都需要实际游戏进度,若该存档未推进到相应位置,整组延后另行试玩,不影响 A/C 组清账。

**排序理由**:同类连着看,不在美术与数值间来回跳。A 组内部:一#17 先(不依赖 app 启动,纯看图)、一#19 与 二#7 各需启动一次视觉路由。B 组三项都需进游戏玩。C 组纯桌面,最后清。

---

## 前置核验记录(本单开工前已现查)

- **硬前置**:派单包要求 `fix/visual-route-save-isolation` 已合入 main。本仓本地 `main` ref 陈旧,改查 `git log --oneline -8 origin/main`,tip = `9cbd9a54 合入 夜批集成:视觉路由存档隔离 + ...`,前置**已满足**。
- **P10(死链扫描归档类单列)合入状态**(一#18 前提):`68692a90 合入 死链扫描归档类单列与 EXCLUDE_DIRS 接线(滚动池 P10)` 已在 origin/main。一#18 拍板前提「先做 P10」**已满足**。
- **P12 四分支独有 commit 数**(2026-08-12 现算 `git rev-list --count origin/main..origin/<b>`):codex/taohua-art-0807=0、qoder/p4-audit-scripts-0808=0、pi/p6-link-label-0808=2、worktree-claude-rarity=3。与池登记一致。

---

## 编号说明(一#19)

派单包列为「一#19 资质档位的视觉表达」,但 **BACKLOG.md 一区未见 #19 编号条目**(一区实际编号:17/18/15/16/4/5/6)。该项对应 `docs/dispatch/pool/README.md` 的 **P11 滚动池条目**:

> P11 资质三连实装(BACKLOG 一#15 老档档位迁移 + 一#16 chip 拼法 + 视觉档位化;2026-08-11 用户按推荐拍板:#15 取 (c) 按出生点数重算、#16 取 (b) 改显出生点数、**视觉档位化并入试玩局再定**)

即 #15/#16 已于 2026-08-11 拍板且已实装(chip 已改显 `birthAttributeTotal`),**只剩「视觉档位化」未拍**。派单包描述的「六档共用一个灰底标签,只靠档名文字区分」是 #16 拍板前的旧现状,现状已改(显出生点数),但视觉档位化仍未做——代码注释 `lineage_character_detail_screen.dart:303-304` 仍明文「视觉表现为临时版...待视觉终拍」。**决策项真实成立,非前提失效**,本清单按 P11 口径处理,只覆盖视觉档位化。

---

## A 组 · 需要真机「看」(视觉观感)

### 步 1 · 一#17 桃花岛入口背景图四张候选取舍

**要定什么**:主菜单桃花岛入口按钮现在复用了一张城防图作缩略图,已出过两张专属候选图(v1/v2)及扩幅版,挑哪一张、还是维持现状。

**看哪里**:

- **候选图与复检对照图**(用 `open` 打开,目录 `~/Desktop/Projects/挂机武侠素材/桃花岛美术候选_20260807/`):
  - C 类原图(1456×816):`entry_taohua_island_v1.png`、`entry_taohua_island_v2.png`
  - D 类 2448 扩幅版:`_entry_v1_scaled.png`、`_entry_v2_scaled.png`
  - 复检对照:`_复检_三图对照_现役vs候选.png`、`_复检_建筑区放大_查文字污染.png`
- **真机现役对照**:主菜单桃花岛入口按钮。现役缩略图 = `WuxiaUi.entryJianghu` = `assets/ui/mj/entry_city_defense_01.png`(`lib/shared/theme/wuxia_tokens.dart:97`,城防图被复用)。入口按钮在 `lib/features/main_menu/presentation/main_menu.dart:532`。**需第二章通关存档**才解锁可见(`main_menu.dart:184-194` 读 `taohuaIsland.unlockChapterIndex`)。
- **视觉路由**:仓里有 `taohua_island` 路由(`lib/features/debug/application/visual_route.dart:318`),但它进的是**桃花岛主屏**(背景是 `assets/maps/taohuaIsland.webp` 地图,`taohua_island_screen.dart:145`),**不是入口图所在的主菜单**。**仓里无专属路由展示「主菜单桃花岛入口态」**,该项主要靠 `open` 候选图;真机现役对照需游戏内进主菜单(且需解锁存档)。

**选项**(照抄 BACKLOG 一#17 原文,不发明):

- (a) 采用 v1
- (b) 采用 v2
- (c) 都不采用,维持现役(继续用 `entryJianghu` 城防图)
- (d) 下次真机看完整场景再定

**已有证据**(BACKLOG 一#17 原文压缩,证据目录同上):

- 构图同构成立、左右是真加宽非拉伸、零文字污染(三处建筑逐个看过无匾额假汉字)、零禁令项
- 色调实测比现役略暗(平均亮度 160.6/159.8 vs 168.6)、墨占比更高(16.1% vs 12.3%)、对比度持平
- **一项未独立验证**:执行端自曝「原生 1774×887 等比放大到 2448」,频谱法自校验失败(已知 1456 上采样对照组反而高于 1774 对照组,该指标不随源分辨率单调)→ 如实标未验证

**拍完之后**:

- 若选 (a)/(b):需另开实装任务——给桃花岛入口单独一个 token(如 `entryTaohua`),替换 `main_menu.dart:532` 的 `thumbnailPath: WuxiaUi.entryJianghu`;候选图入仓 `assets/ui/mj/`;更新 `tools/` MJ 资产清单。注意 `entryJianghu` 被群战/远征/断魂庄/门派/江湖多个入口共用(`main_menu.dart:434/448/457/543/554`),**不能直接改 `entryJianghu` 指向**,必须新立 token。
- 若选 (c):维持现状,BACKLOG 一#17 销账。
- 若选 (d):推迟,本局不清。

---

### 步 2 · 一#19(实为 P11 视觉档位化)资质 chip 视觉表达方向

**要定什么**:角色档案页的资质 chip 现在是灰底文字,六档(庸才/寻常/标准/资优/天才/绝世,`lib/core/domain/enums.dart:150-157`)只靠档名文字+出生点数区分,要不要给六档做视觉档位化表达。

**看哪里**:

- **视觉路由**:`lineage_character_detail`(门派谱角色详情屏·祖师态,含「资质四项」chip;`visual_route.dart:289-292`)。脚本会启动到此路由。
- **代码现状**:`lib/features/character_panel/presentation/lineage_character_detail_screen.dart:305-310`,资质 chip 沿用 `_AttrChip` 同款样式(`textSecondary` 灰色文字、fontSize 13,`:319-331`)。注释 `:303-304` 明文:「⚠ 视觉表现为临时版(沿用 _AttrChip 同款样式,未做色阶/印章等档位化表达),待视觉终拍」。
- **六档定义**:`lib/core/domain/enums.dart:150-157`(庸才 16-17 / 寻常 18-19 / 标准 20 / 资优 21-22 / 天才 23 / 绝世 24,详 GDD §4.1)。

**选项**(派单包与代码注释给的方向,整理成可勾选;不发明新方向):

- (a) 色阶:六档对应六种水墨色阶递进(如淡墨→浓墨)
- (b) 印章:档位以印章图形标记(沿现有朱红印章母题,`docs/PUBLISHING_ART_PASS_1_0.md:215`)
- (c) 边框:chip 加不同档位边框样式
- (d) 底纹:chip 加不同档位底纹
- (e) 维持现状(只显档名+出生点数,不做视觉档位化)

**已有证据**:

- 代码自注「视觉表现为临时版,待视觉终拍」(`lineage_character_detail_screen.dart:303-304`,本单现查)
- P11 已拍 #15/#16,chip 拼法已改为显 `birthAttributeTotal`(`:306-309`),视觉档位化明确「并入试玩局再定」(`docs/dispatch/pool/README.md` P11 行)
- BACKLOG 一#16 原文记录了拼法分叉问题(已解决),视觉档位化是同源未决项

**拍完之后**:

- 若选 (a)-(d):需另开实装任务(改 `_AttrChip` 或新建专用 chip widget,涉及 `lib/features/character_panel/presentation/` 与可能 `lib/shared/theme/`;**不触数值**,纯展示层)
- 若选 (e):维持现状,在 BACKLOG/P11 销账

---

### 步 3 · 二#7 战斗屏立绘融合观感

**要定什么**:战斗屏我方立绘与背景的「大气融合」观感好不好,要不要调三常量。

**看哪里**:

- **视觉路由**:`battle_v2_neutral_3v3`(中性标准 3v3 静态帧,`visual_route.dart:104`)。另可参考 `battle_scene`(带背景 scrim,`:59-62`)。
- **三常量位置**:`lib/features/battle/presentation/battle_standee_fusion.dart`
  - `battleStandeeFusionLuminanceFloor = 125.0`(`:92`,明度下沿)
  - `battleStandeeFusionLuminanceCeil = 195.0`(`:96`,明度上沿)
  - `battleStandeeFusionOpacityAtFull = 0.85`(`:104`,满档 opacity)

**选项**(BACKLOG 二#7 原文「需先看真机实拍图;要调只动三常量,门禁测守边界」):

- (a) 维持现状(三常量不动)
- (b) 调整三常量(看完真机后定具体值)

**已有证据**(BACKLOG 二#7 原文 + 代码注释压缩):

- 背景明度全表实测在案(`battle_standee_fusion.dart:68-85`,16 个资产逐值 PIL 实测)
- 取样带跨数据集自校验:与 2026-07-30 夜批独立实测平均绝对误差 5.9/最大 8.9/秩相关 0.80,精度按 **±9** 记(`:60-63`)
- cliffwaterfall boss 取样带侵入已证伪销(2026-08-05,`docs/audit/cliffwaterfall_fusion_band_probe_2026-08-05.md`)
- 门禁测 `test/features/battle/presentation/battle_standee_fusion_test.dart` 守边界

**拍完之后**:

- 若选 (a):销账
- 若选 (b):改 `battle_standee_fusion.dart` 三个常量值,`battle_standee_fusion_test.dart` 需同步更新,**不触美术资产**(杠杆全在立绘侧,`battle_standee_fusion.dart:13` 明确「零触 90 关背景美术」)

---

## B 组 · 需要真机「玩」(数值手感)

> B 组三项都需要实际游戏进度。脚本只负责「把游戏启起来 + 打印该玩哪段、看什么指标」,**不自动试玩**。

### 步 4 · 一#4 丹房强度

**要定什么**:桃花岛丹房建筑的产出强度(产速/配方比率)是否合适。已定「不动」,待真人试玩复核。

**玩哪段**:从主菜单进桃花岛(`taohua_island` 主屏)→ 丹房建筑(`danFang`)→ 看产出队列与产出物。需第二章通关解锁桃花岛。玩到能判断「产速/仓储 cap/配方比率是否合理」的程度(约 10 分钟观察 1-2 轮产出)。

**选项**:

- (a) 维持不动(2026-07-19 1A 批决议)
- (b) 调整(需指出具体哪个产出参数不合理)

**已有证据**:

- BACKLOG 一#4 原文仅一行:「丹房强度 2B | 已定『不动』,待真人试玩数据复核(2026-07-19 1A 批决议)」
- 数值在 `data/numbers.yaml` `taohua_island` 段(本单未深挖具体值,未附独立审计文档——BACKLOG 条目本身未引)

**拍完之后**:

- 若选 (a):销账
- 若选 (b):改 `data/numbers.yaml` `taohua_island` 段,需守数值红线(详 CLAUDE.md §5.4 / GDD §5.2)

---

### 步 5 · 一#5 残页集齐数量

**要定什么**:爬塔/章末重打掉的残页,集齐多少片解锁一招。当前默认 5 片。

**玩哪段**:爬塔 Boss 层(5/10/15/20/25/30,`data/skills.yaml:3099`)与章末重打关(`data/skills.yaml:3243`)掉残页,集齐 5 片自动解锁。玩到能判断「集齐节奏太快/太慢/合适」的程度。

**选项**:

- (a) 维持默认(真解 1 / 残页 5)
- (b) 调整残页阈值(如改为 3 或 7)
- (c) 调整掉率

**已有证据**(2026-08-12 现查):

- 当前默认值:`fragmentThreshold = 5`、`towerFragmentDropProb = 0.20`(`lib/data/numbers_config.dart:2893-2894`,从 `data/numbers.yaml` `skill_unlock` 段读)
- P1a spec §16#4 拍板「真解 1 本即解锁 / 残页 5 片一套」(`docs/spec/2026-06-09-playability-p1a-cultivation-core-design.md:69`)
- BACKLOG 一#5 原文:「实玩后可调(P1a §16#4 默认值)」
- 测试契约:`test/data/numbers_config_skill_unlock_test.dart:11` 断言 `fragmentThreshold == 5`

**拍完之后**:

- 若选 (a):销账
- 若选 (b)/(c):改 `data/numbers.yaml` `skill_unlock` 段,`test/data/numbers_config_skill_unlock_test.dart` 需同步

---

### 步 6 · 一#6 高熟练度难度微调候选

**要定什么**:30 关主线在高熟练度态(满熟练 vs 零熟练)的难度曲线是否需要微调。

**玩哪段**:30 关主线,分别用 floor(零熟练)与 ceiling(满熟练)态玩,重点看已知杠杆点:01_05 floor(变易)、05_05 ceiling(fresh 0%→满熟练 76%)。玩到能判断「偏难/偏易/合适」的程度。

**选项**:

- (a) 维持现状(全表 sweep mean +8.3pt 全过)
- (b) 微调具体关卡(指出哪关偏难/偏易)

**已有证据**:

- 波B 全表 sweep 读数(`docs/spec/playability_phase2_backlog.md:58`):30 mainline × floor/ceiling × uses{0,800} × 25 seed 全表 sweep,首跑 mean **+8.3pt** 全过;蓄力 Boss 难度面变化(01_05 floor 变易 / 05_05 ceiling fresh 0%→满熟练 76%,熟练度成跨阶杠杆)
- 常驻测:`test/tools/balance_simulator_test.dart:146`(容噪 10pt 单调断言 + mean delta ≥ 0)
- BACKLOG 一#6 原文:「波B 全表 sweep 读数在案,待真玩拍板」
- 三项同源归口:`docs/audit/direction_candidates_2026-08-07.md:10` 明确 #4/#5/#6 全部标「待真人试玩数据」

**拍完之后**:

- 若选 (a):销账
- 若选 (b):改对应关卡数值(`data/stages.yaml` 或 `data/numbers.yaml`),需守数值红线与 `balance_simulator_test` 测

---

## C 组 · 桌面决策(不需要真机)

### 步 7 · 一#18 死链扫描器「可试用·非终审事实源」定位是否升级

**要定什么**:`tools/README.md` 里 `doc_link_scan.py` 的定位写的是「可试用,非终审事实源」,要不要升级为终审事实源(即别处引用扫描器输出不再加免责标注)。

**看哪里**:`tools/README.md` `doc_link_scan.py` 那一行(现文:「当前定位=可试用,非终审事实源(该定位是否升级仍属待拍板项)」)。脚本会摘录该行。

**前提核验**:BACKLOG 一#18 原文写「建议先做 P10 再拍此项」。P10 = `68692a90 合入 死链扫描归档类单列与 EXCLUDE_DIRS 接线(滚动池 P10)`,**已在 origin/main**(`git show 68692a90 --stat` 改 tools/README.md / doc_link_scan.py / 两测试)。**前提已满足**。

**选项**:

- (a) 升级为「终审事实源」(引用扫描器输出不再加免责标注)
- (b) 维持「可试用·非终审事实源」

**已有证据**(BACKLOG 一#18 原文 + `tools/README.md` P10 后现状):

- **支持升级**:P6 标注验证 90 条分层抽样 → precision 95.0% / recall 100%;两处系统性假阳已于 2026-08-11 修复合入(`ab38b43c`),由 `test_doc_link_scan_gitfixture.py` 红线守住;工作树漂移已归零(两地逐值相同 `refs=7442 alive=5929 dead=908 ignored=605`)
- **P10 后 dead 已收敛**:`tools/README.md` 现登记(2026-08-12)归档类单列后 `dead` 从 908 降至 **322**(归档类 585 条单列,`ARCHIVAL_DIRS` 现仅 `docs/handoff`)。原本反对升级的主要理由(handoff 噪声约 600 条)已被 P10 处理。
- **仍可能反对升级**:`dead` 322 是否可直接当修复清单仍待判断(本单未逐条核);其他目录是否同属归档性质是范围决策,`tools/README.md` 标注「待派单方拍板」。

**拍完之后**:

- 若选 (a):改 `tools/README.md` `doc_link_scan.py` 那一行的定位描述
- 若选 (b):维持现状,BACKLOG 一#18 销账

---

### 步 8 · P12 远端 4 个遗留备份分支清理

**要定什么**:远端 4 个遗留备份分支要不要删。

**看哪里**:脚本会现算每个分支 `origin/main..origin/<b>` 的独有 commit 数并打印。人直接答删/留。

**选项**(逐分支):

| 分支 | 独有 commit(2026-08-12 现算) | 含义 | 选项 |
|---|---|---|---|
| `codex/taohua-art-0807` | 0 | git 可断言已包含,删除零风险 | 删 / 留 |
| `qoder/p4-audit-scripts-0808` | 0 | git 可断言已包含,删除零风险 | 删 / 留 |
| `pi/p6-link-label-0808` | 2 | rebase/cherry-pick 前旧 SHA,内容在 main 但 git 证明不了 | 删 / 留 |
| `worktree-claude-rarity` | 3 | 同上 | 删 / 留 |

**已有证据**:上表独有 commit 数为 2026-08-12 本单 `git rev-list --count origin/main..origin/<b>` 现算(与 `docs/dispatch/pool/README.md` P12 登记数 0/0/2/3 一致)。前两个 0 独有 commit 的分支,git 可断言其内容已全部包含于 origin/main,删除零代码风险;后两个非零的是 rebase/cherry-pick 前的旧 SHA,内容在 main 但 git 无法证明等价,需人工确认。

**拍完之后**:若决定删,另开任务执行 `git push origin --delete <分支名>`(本单不执行,只备事实)。

---

## 附:本清单核证边界(如实声明)

1. **一#19 编号错位**:BACKLOG 一区无 #19 条目,本项实为 P11 登记的「视觉档位化」,详见上文「编号说明」。决策项真实成立。
2. **一#17 真机现役对照**:仓里无专属视觉路由展示「主菜单桃花岛入口态」,`taohua_island` 路由进的是桃花岛主屏(地图背景,非入口图)。真机现役对照需游戏内进主菜单且需第二章通关存档。
3. **一#4 丹房强度**:BACKLOG 原文仅一行,未附独立审计文档,具体数值在 `data/numbers.yaml` `taohua_island` 段(本单未逐值摘录,只指路)。
4. **一#18 P10 后 dead 计数**:P10 已将 handoff 归档类单列,`tools/README.md` 现登记 `dead` 从 908 降至 322(归档类 585 条单列,2026-08-12)。本单未逐条核 dead 322 是否可当修复清单。
5. **所有视觉路由 id 均已现查**(`lib/features/debug/application/visual_route.dart`),代码行号均现查。
6. **P12 commit 数为 2026-08-12 现算**,非抄 BACKLOG 旧数。
