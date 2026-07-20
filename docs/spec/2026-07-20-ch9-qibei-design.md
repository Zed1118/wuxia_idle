# Ch9「碛北」二流第 3 章 设计 spec（**已冻结 · 2026-07-20 用户拍板 A 案**）

> **拍板结果（2026-07-20）**：§5 末 Boss = **A 案 二流收束**（隐世碛北二流绝顶老者/铜符本主·沉默出手即决型·边塞三章弧闭环不抬发布上限）；章首心境「不怕没有路」+ 章末拐点「符的那头不是答案,是又一个开始」认可；Batch 6-commit 节奏认可。以下草案 §5 三选一以 A 为准,B/C 存档备参。


> 承 Ch7「北望」/ Ch8「出塞」边塞·灰衣人·铜符线（**非** Ch4-6 西出阳关弧）。
> 体例复用 memory `project_wuxia_idle_ch4_cultural_arc`（4 拍板维度 + 遗物 hook + 师父遗言承上启下 + 视角 + 黑名单 + 字数预算）。
> reconcile 复用 memory `feedback_wuxia_add_mainline_chapter_reconcile`（~11 测站点 + 6 生产站点·开工先全 Phase-0 grep）。

## 0. 承接线索（Phase 0 已确认）

- Ch7:北派宗匠临终赠**铜符**（刻北派门纹）,「它该往哪里去,你日后自会知道」;灰衣人（原北派重手窃者·用阴柔）现身,两线阴山交叉。
- Ch8:灰衣人败而未死,再点破——「那一位,在符的那一头」「有些话,说给能进碛北的人听」;赠符 + 转盟友;玩家习得**灰袖回风**（skill_hui_xiu_hui_feng·已在 skills.yaml）。
- **Ch9:循符入碛北**（「连路都没有了」的无路大漠边塞）,寻符尽头的「那一位」。

## 1. 四拍板维度（我的推荐 + 待你拍板）

| 维度 | 推荐 | 拍板点 |
|---|---|---|
| **章首心境** | 「不怕没有路」（承 Ch8 尾「他已经不怕没有路了」）——从追逐灰衣人到主动循符入无人之境的笃定 | 认可/调整 |
| **章末境界拐点** | 二流 yiLiu 风格「沉着/肃杀/老练/冷静」的收束顿悟:「符的那头不是答案,是又一个开始」——**边塞三章弧收束**,铜符使命完成 | 认可/调整 |
| **末 Boss「那一位」类型** ⭐ | **待你拍板的核心**。三选一见 §5 | **必拍** |
| **Batch 切分** | 沿 Ch4/5/6 的 6-commit 节奏(Phase1 spec+GDD / 2.1数值红线 / 2.3①10段narrative / 2.3②章首尾+defeat / 2.4 GDD+PROGRESS / 2.5 R5+closeout) | 认可 |

## 2. 地理梯度（5 关 · stage_09_01..05）

碛北纵深弧（无路大漠越走越绝）:
| 关 | 地名 | biome | 叙事锚 |
|---|---|---|---|
| 09_01 | 符引·出关 | frontier/desert | 循符出受降城以北,最后一段有路的路 |
| 09_02 | 瀚海无路 | desert | 进真正的无路之地,风蚀白骨,符是唯一方向 |
| 09_03 | 蜃楼(章中考验) | desert | 海市蜃楼幻敌/心志考验,灰衣人同行点拨 |
| 09_04 | 黑水绝壁 | frontier | 碛北最深处的隘口,那一位的门槛守卫 |
| 09_05 | 那一位（末 Boss） | frontier | 符尽头,那一位现身 |

## 3. 敌人设计（每关敌队 + 立绘）

- 09_01~04:碛北边民/马匪/蜃楼幻敌/隘口守卫（三流派覆盖,二流数值带）——新敌立绘走 codex image_gen 配方（已验证·参考现有 battle 立绘锚）。
- 灰衣人 09_03 **同行盟友**（叙事,不作敌;或作蜃楼幻境里玩家须"不追"的镜像考验,呼应 Ch8 回风"专等追的人"母题）。
- 末 Boss「那一位」= §5 拍板。

## 4. 招式设计

- 复用现有二流招式池 + 灰袖回风（玩家 Ch8 已得）。
- **是否新增 1 招真解**（那一位的本命技,章末 Boss 首通掉·同 Ch7/8 体例）= 随 §5 末 Boss 拍板定;若新增须配 bossPhase `onEnterMechanic: chargeCounter`（memory 成对红线）。

## 5. 末 Boss「那一位」三选一 ⭐（核心拍板）

| 案 | 那一位是谁 | tier | 机制 | 弧意义 |
|---|---|---|---|---|
| **A 二流收束（推荐）** | 北派真正的隐世宗主/铜符本主——一位早已退隐碛北的二流绝顶老者 | erLiu 顶 | 沉默克敌·出手即决型（同 Ch4 西凉霸主体例） | 边塞三章弧圆满收束,铜符使命达成,不强开一流 |
| **B 一流拐点** | 那一位是**超出二流的存在**(一流/绝顶),碛北是通往更高武学之门 | yiLiu 跨阶 | 跨阶机制型(承伤窗口/相位)——满配也非纯 DPS 秒 | 抬发布上限触发（reconcile 面大·见 memory `feedback_wuxia_release_cap_raise_reconcile` 4 站点）,开一流新篇 |
| **C 反转** | 「那一位」不是敌人——符引到的是一位**已故之人的遗留**/一段真相,末关是心志/机制考验非杀人 | erLiu | 限时生存/守护类非击杀胜负条件 | 叙事反转,边塞线以"放下"收（呼应灰衣人"不追就赢了"） |

**我倾向 A**:边塞三章（北望/出塞/碛北）作二流完整弧收束,铜符线闭环,不牵动发布上限 reconcile;一流留作独立新篇（Ch10+）另起。B 的抬 cap reconcile 面大且改变全局 Lv 曲线,宜专章专议。C 叙事精彩但与"挂机战斗爽感主旋律"稍偏。

## 6. 数值/tier（按 A 案）

- 5 关 requiredRealm: erLiu（同 Ch8）。
- exp 布局沿 Ch8 体例（Boss 关 Lv jump≥1·章总 ~180 exp 带）,末 Boss 血线收尾 0.94-0.96 同 Ch7/8 带。
- Lv 快照:实测迭代（首通 Lv 位移 + 全内容 Lv,守 <解锁线）——**逐值实测禁猜**（memory anti_hallucination）。
- 掉落 cap 按发布上限（cap-agnostic·非 per-stage 硬编）。

## 7. reconcile 清单（~17 站点 · 开工前全 Phase-0 grep）

**count（40→45 关·章 8→9）**:progression_playtest_diagnostic（+CSV byte-lock 重生）/game_repository_test（≥3 处:mainlineCount / 主线关红线 / R3 prevStageId 单链）/mainline_narrative_completeness（count+章循环 1→9）/balance_simulator（>= 不破·硬编破）/readable_tempo（名+章 ratchet）。
**boss 计数**:stages_boss_enemy（+2）/boss_memory_providers（图鉴）。
**progression 级联**:progression_release_budget（章 exp 推高全局 Lv·逐值实测位移）。
**tier 红线**:mainline_stage_curve（章→境界·cap-agnostic 语义化）。
**生产可见性**:chapter_list `[1..9]`+widget 测章卡计数（viewport 扩）/main_menu+status_summary 章循环 `<=9`/boss_memory_key group index（Ch9 与心魔/轻功/群战撞→偏移·持久化不重排旧值）/UiStrings.chapterTitle/Hint switch/strings.dart「九章…」hint。
**chargeSkill**:若那一位有蓄力真解必配 bossPhase `onEnterMechanic: chargeCounter`（成对）。

## 8. 字数/视角/黑名单（沿体例）

- 字数 ~5-6k 纯正文（章首尾 ~1.2k + 10 段 stage ~4k + 1-2 defeat ~0.4k）。
- 视角:chapter prologue/epilogue 第三人称 / stage + defeat 第二人称「你」。
- 铜符**物理遗物 hook**贯穿（Ch7 得符 → Ch8 再点 → Ch9 符尽头兑现 → 章末符的处置=弧收束象征）。
- 师父遗言/顿悟回响 3 处（章首承上 / 章末启下 / defeat）。
- 黑名单 14 词 grep 0 命中（legendary/epic/史诗/神器/传说级/无敌/最强/究极/霸气/逆天/血溅/刀光剑影…）。

## 9. Batch 切分（实装·A 案 · 预估 ~3-3.5h opus xhigh + codex 立绘批）

1. Phase 1:本 spec 冻结 + GDD 章表同步
2. Phase 2.1:stages.yaml +09_01..05 + 数值 + reconcile 红线层 patch
3. Phase 2.3①:10 段 stage narrative ~4k 字
4. Phase 2.3②:章首尾 + defeat ~1.5k 字
5. Phase 2.4:GDD/PROGRESS + 生产可见性 reconcile
6. Phase 2.5:R5 红线压测 + Lv 快照实测 + closeout
7. 并行:codex image_gen 出 Ch9 新敌立绘（沿已验证配方）

## 10. 待拍板汇总

1. **§5 末 Boss「那一位」三选一**（A 二流收束推荐 / B 一流拐点 / C 反转）——决定全章 tier 与 reconcile 面
2. §1 章首心境 /章末拐点 认可或调整
3. §1 Batch 6-commit 节奏认可
