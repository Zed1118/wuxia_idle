# Ch19 章级设计 spec — 武圣段首章 · 回望弧开篇 · cross-tier · 待拍板

**日期**:2026-07-28 · **载体**:worktree `ch19-wusheng-shouzhang`(叠在 PR #91 上)
**上游**:段级 spec `2026-07-28-wusheng-arc-ch19-21-design.md` 九项**全 A 已拍板**
**状态**:**待拍板 6 项**(§4)· 零代码改动 · 拍板后即实装
**前置实测**:HEAD `a3e69caf` · pub get / build_runner EXIT=0 · 64 .g.dart · dylib sha 对齐主仓

---

## 1. Phase 0 复定(2026-07-28 本会话现 grep · 行号会 drift,实装前再核一次)

### 1.1 结构锚

| 项 | 实测 | 位置 |
|---|---|---|
| cap | 42 | `data/numbers.yaml:206` |
| wuSheng 层表 | qiMeng 43 / ruMen 44 / **shuLian 45** / jingTong 46 / yuanShu 47 / huaJing 48 / dengFeng 49 | `numbers.yaml:465-495` |
| 主线 | 18 章 90 关 | `stages.yaml` mainline 计数 |
| Ch18 收官值 | HP 58300→**59500** · 攻 1960→**2000** · 速 362→370 · diffMult 19.0→19.8 · exp 76/78/80/100/120 | `stages.yaml:4171-4414` |
| 首通 | cumExp **4087** → **Lv105** | `progression_release_budget_test.dart:22,47` |
| 全内容 | Lv121 / abs13 / 余量 75 · 缺口 **4425** | `progression_idle_horizon_simulation_test.dart:59-74` |
| 结晶 | **3192**(≈12.09 件·上界 13) | `enhancement_material_supply_test.dart:30,47` |

### 1.2 资源池(全部现测)

- **tier7 招 21 门**(9 基础 + 9 fang + 3 nei)`skills.yaml:837-960, 2359-2480, 2739-2775`,已用**仅** `yinrou_chuanshuo_fang_*`(Ch6)→ **6 组 18 招闲置**。
- **tier7 显式 drop/fragment/gauntlet = 0 门**(全仓 tier7 只 4 招且全 `special`:3 神物开锋 + 心魔蓄力)→ **cross-tier 红线⑦ 零暴露**,但仍须复跑证。
- **神物 11 件**:5 weapon / 3 armor / 3 accessory · 全带 `dropSourceTags: ["wuSheng_unlock"]` · **dropTable 命中 0**。
- `cycleVulnerability` schema **已存在**(`stage_def.dart:280,327-332`),约束:配它必须先配 `vulnerability`。

### 1.3 人物连续性(回望弧复用既有人物的硬约束)

| 人物 | 既定 enemy id | school | 出处 |
|---|---|---|---|
| 接关人 | `enemy_zongShi_liangzhouci_jieguan_ren` | **gangMeng** · shuLian | Ch16 末 Boss `stage_16_05` |
| 黑石守镜人 | `enemy_zongShi_liangzhouci_heishi_shoujing` | **yinRou** · qiMeng | Ch16 `stage_16_02`(非 Boss) |

> **地理走向锁死关序**:Ch16 西行为 黑石滩(16_02)→ 关城(16_05),故**东返先关城、后黑石滩**。19_04 章中 Boss = 接关人、19_05 末 Boss = 守镜人 由地理决定,不可互换。

## 2. 叙事底盘(既有伏笔,非新编)

- Ch18 章尾:「西边到这里就到头了。**人间的路走到头,剩下的那一段,不在东西南北里**。」→ 段级拍板 9A 回望弧。
- **合镜线现成**:黑石那半镜仍在原地(`stage_16_02_opening:5` 巴掌大·缠枝纹);守镜人立过条件「镜是霸主的一句话,**话,要他亲口说出来才算数**」(`stage_16_02_victory:7`);Ch18 霸主**已亲口说了并交出另半面**(`chapter_18:42`)。→ **Ch19 = 带着霸主那半面往回走,把两半合上**,条件在 Ch16 就写死了,Ch19 只是兑现。
- 守镜人留白待用:「兜帽底下那双眼睛,很亮,**不像守了几十年荒滩的人该有的眼睛**」(`stage_16_02_victory:4`)。
- 反向对称:Ch16 接关人拦的是「你够不够格**进去**」;Ch19 拦的是「你带出来的东西够不够格**出来**」。

## 3. 数值框架(上界已封顶 · 难度全走机制层)

- **HP**:段级 §7 定三章 ~58000 / 59000 / 59500。Ch19 段首回落照体例 → **56500 → 58000** 五关递进(< 60000 硬线)。
- **攻**:段级已定「2000 用尽」→ Ch19 全段钉 **2000**(无余量可涨,故难度不靠攻)。
- **敌层**:qiMeng(43) → **shuLian(45)**,末 Boss shuLian = cap 45 同层(照 Ch18 末 Boss dengFeng = cap 42 同层体例)。
- **真解倍率**:tier7 cap **8000 = §5.4 全局硬线本身**,零上浮空间。宗师段真解 6400 是唯一参照 → Ch19 候选 **7000**(留 Ch20/21 各一档:7400 / 7800)。
- **流派**:01 gangMeng / 02 lingQiao / 03 yinRou / 04 gangMeng(接关人既定)/ 05 yinRou(守镜人既定)。

## 4. 待拍板 6 项(逐项带推荐)

| # | 决策点 | 候选 | 推荐 |
|---|---|---|---|
| 1 | **章名** | A「旧路照人」/ B「黑石合镜」/ C「寂照」(wuSheng 风格词) | **A** — 「旧路」兑现回望弧,「照」兼指铜镜;C 太抽象不合本项目具象文风 |
| 2 | **末 Boss** | A: 黑石守镜人(合镜 = 章眼·守成一生者失其所守)/ B: 接关人 | **A** — 合镜是本章唯一硬伏笔;且地理上黑石滩在东返路线更靠后,天然压轴 |
| 3 | **真解** | A: 新写 tier7 yinRou「一镜双照」(mult 7000·守镜人本命)/ B: 改让 gangMeng 接关人当末 Boss 以求三系变化 | **A** — 人物连续性优先(Ch18 同理保 yinRou);三系各一留 Ch20/21 取 gangMeng/lingQiao |
| 4 | **机制层档位** | A: 引入 `cycleVulnerability`(周期开窗·新机制非更狠数值)/ B: 沿 0.12 复合 ward | **A** — 段级 §4 三档递进:Ch19 周期窗 → Ch20 ward×vuln 复合 → Ch21 新胜负条件;**档位值不预钉,探针实测校准** |
| 5 | **神物投放** | A: Ch19 首批 4 件(2 weapon + 1 armor + 1 accessory)/ B: 全 11 件本章投完 | **A** — 11 = 4+4+3 三章分,B 会让 Ch20/21 无掉落可投 |
| 6 | **章中 Boss 机制** | A: 接关人只配 chargeCounter 相位(不配 vulnerability·作周期窗前置教学)/ B: 同配窗口 | **A** — 照 Ch17「先学打断蓄招 → 再学只有窗口能打」两级递进先例 |

## 5. reconcile 面(现测站点 · 实装时逐项核)

- **count 90→95**:`mainline_narrative_completeness_test:58,62` / `chapter_list_screen_test:131` / `game_repository_test:92,690,696` / `progression_playtest_diagnostic_test:15`(注释写「新增主线章时改此一处」)/ playtest CSV byte-lock 重生。
- **章循环 18→19**:`mainline_narrative_completeness_test:66,67` / `game_repository_test:707` / `chapter_list_screen_test:57,91` / `main_menu_status_summary_provider.dart:156` / `chapter_list_screen.dart:18,20,31`。
- **boss 敌 38→40**:`stages_boss_enemy_test:35,41`。**catalog 51→53**:`boss_memory_providers_test:50`。
- **boss_memory_key**:`boss_memory_key.dart:37-41` 公式 `chNum>=7 → chNum+3` → Ch19 归 22,**公式自适应无需改**(实装时验)。
- **skill 计数 216→217 / 256→257**:`skill_count_contract_test:12,28,38` + **GDD 字串两处** `:43,45`。
- **cap 42→45**:真相源 `numbers.yaml:206`;测侧多数 cap-agnostic(动态读),须逐一确认 `truth_source_guard_test:26` / `wave_b_content_redline_test:228` / `skill_source_redline_test:553` / `mainline_stage_curve_redline_test:64,254` / `inner_demon_r5_redline_test:438`。
- **cross-tier zongShi→wuSheng 全套**:挂载完备(§1.2 实测零暴露仍须证)/ 三系锁死连动 / stale 文案 grep。
- **wave_b 白名单**:新真解须登记进 `wave_b_content_redline_test.dart` `standaloneBossManualIds`(否则打破 2/2/2 配平)。
- **生产可见性**:`strings.dart:1405`(「18 章 90 关」)`:1440,1458`(chapter19Title/Hint)`:1530,1555`(两 switch)。
- **GDD**:头部**当前状态块**(`GDD.md:11-13` cap 42 / 18 章 90 关,`truth_source_guard_test` 自动拦)+ §8.1 章表(`:555-575`)+ 招式池(`:618,620`)。
- **progression 逐值实测禁猜**:`progression_release_budget_test`(4087/Lv105)/ `progression_idle_horizon_simulation_test`(4425 缺口·多处)/ `enhancement_material_supply_test`(3192)。
- **美术**:`known_missing_assets.txt` 登记 11 图 · `character_avatar.dart:865` `_battleStandeeOverrides` 补 5 敌。
- **stale 注释顺修**(段级 spec §3):`numbers.yaml:1392` / `masters.yaml:3` / `equipment.yaml:17` 均写「飞升 Demo 不做」已被推翻。

## 6. 红线守卫

- Boss HP ≤58000 < 60000 · 敌攻 = 2000(上限)· 真解 ≤8000(= 硬线本身,无余量)· 敌招全 tier7。
- 三系锁死:武圣 ↔ 神物 ↔ 传说神功,敌招不降档充数。
- `stage_19_01` 无 `prevStageId` · 末 Boss `chargeSkillId` 与 `dropSkillManualId` 同招(双用 canon)· `cycleVulnerability` 必须先配 `vulnerability`。
- 机制层只走减伤/新胜负条件方向,不膨胀伤害数字(§5.4 例外条款)。

## 7. 恢复点(CLAUDE.md §8.0)

- **状态**:Phase 0 完成 · 章级 spec 待拍板 · **零代码改动**
- **分支**:`worktree-ch19-wusheng-shouzhang`(基于 PR #91 的 `a3e69caf`)
- **下一步**:6 项拍板 → 按 stages → skills → equipment dropTable → numbers(cap) → narratives → reconcile → verify 顺序实装
- **已跑验证**:环境预热 EXIT=0(pub get / dylib sha 对齐 / build_runner 64 outputs)
- **阻塞项**:§4 六项拍板
