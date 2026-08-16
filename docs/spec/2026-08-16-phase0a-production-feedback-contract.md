# Phase 0A 根应用生产反馈事件契约（2026-08-16 · Kimi 规格）

> 消费方：下一片 reducer + 根应用纯 Flutter 战斗表现层（实装排期在 Qoder deterministic simulation core / input adapter 冻结之后，见接线审计 §4）。本契约只定义**语义事件**，不锁 Dart API、不绑定未实装类名、不含伤害倍率/CD 配置时长/技能半径等**调优/平衡常量**（一律归根配置层 yaml + 红线 validator）；但**必须携带模拟核已结算的运行时结果**（如 `resolved_damage`、`remaining_health`、`cooldown_remaining`、`qi_current`、`qi_required`）——这些是反馈数据而非平衡常量，表现层只消费、禁止重算。probe 不再改，仅作手感/性能对照；正式验收对象 = 根应用真实入口。
> 参考模型：probe `feedback_events.dart` / `feedback_cues.dart`（语义事件 + 事件→cue 纯函数映射，静音契约）；本契约沿用其「事件不携带视觉表现参数」的原则，运行时结算数值则是 payload 的一等公民。

## 全局约定

- **公共 payload**：每个事件必带 `seq`（单调递增序号，发射方维护）与 `tick`（模拟核逻辑拍）；实体类事件带 `actor`（出手者语义 id）/必要时的 `target`。表现层按 `seq` 排序消费，`seq` 重复即丢弃（去重）；乱序到达按 `seq` 重排，不依赖到达顺序。
- **坐标**：位置类字段用语义锚点（`actor` 脚底锚点 / 目标脚底锚点），不给像素坐标；像素换算归表现层相机。
- **音频**：全部走根 `lib/shared/audio` 现有后端（`SoundManager` + `sfxAssetPath` 槽位映射），不新增音频依赖、不引入 probe 音频。槽位缺失 = 静音，不报错（沿用 `_guard` 静默 no-op 语义）。
- **回退总纲**：任何事件对应视觉资产缺失时，回退顺序 = ①语义正确的 Canvas 直绘水墨占位（克制色板，禁 Material 饱和色）→ ②已有通用资产临时借用（须在 manifest 登记）→ ③纯 HUD 文本/印态变化。不得因资产缺失静默吞事件。
- **可读性/性能总纲**（对齐切片基线，不得回退）：双视口 1280×720 / 1440×900 下 20+1 同屏可辨；主角与精英不被特效遮挡；帧预算 p99 ≤9.1ms（probe Profile 基线）；反馈特效池有界（参照既有 ≤160 / 飘字 ≤48 量级）；同帧同类事件合并播放，禁逐事件 `saveLayer`。

## 普攻链路

### attack_started
- 触发：模拟核确认出手动作开始的拍。
- payload：`actor`、`move_kind`（light/heavy，语义档非数值）。
- 顺序/去重：仅按 `seq` + `actor` 去重；未命中合法，hit_landed 缺失不得用假 hit 封口，动作收束由模拟拍与表现层时序管理，不设事件间强制配对。
- 视觉：祖师/敌人攻击姿势序列帧起手段（缺失回退：既有姿势图 + 墨色挥迹 Canvas 占位）。
- 音频：无（出手不出声，克制）。
- 约束：起手动画不得遮挡目标血条；同屏多起手按 `seq` 播，不排队延迟。

### projectile_launched
- 触发：掌风等飞行体离手、进入判定的拍（近战无前摇弹道的事件可不发）。
- payload：`actor`、`origin`（出手者锚点）、`flight_kind`（palm_wind 等语义类）。
- 顺序/去重：一次 attack_started 至多对应一个 projectile_launched；`seq` 去重。
- 视觉：掌风水墨贴图 sprite 沿轨迹飞行（缺失回退：贝塞尔墨色块占位，probe 既有形态）。
- 音频：无（命中才出声）。
- 约束：飞行体属反馈池，数量并入池上限；不遮主角。

### hit_landed
- 触发：判定命中、结算完成的拍；闪避/未命中不发（对齐 `sfxForAction` 既有语义）。
- payload：`actor`、`target`、`move_kind`、`is_critical`、`is_ultimate`、`resolved_damage`（结算后伤害值，与飘字一一对应）、`remaining_health`（目标剩余生命）；数值由 simulation/settlement 产生，表现层禁止重算伤害。
- 顺序/去重：一次判定一发；同一拍多目标各发一条、按目标稳定顺序。
- 视觉：目标闪白 + 命中停顿（hit-stop）+ 暴击/大招题字（破·斩·震·断语义档）；缺失回退：ColorFilter 闪白（probe 已验证形态）。
- 音频：复用 `battleHit` 六变体（`battleHit_<side>_<slot>`，`audio_assets.dart:71-75`）；暴击 `battleCrit.mp3`；大招 `battleUlt.mp3`（现为借用资产，见 manifest）；优先级 ult > crit > hit。
- 约束：hit-stop 只停表现层动画、停不住模拟核推进；题字同屏去重合并。

### enemy_defeated
- 触发：敌方单位生命归零、进入移除流程的拍。
- payload：`target`（被击败者）、`defeat_kind`（normal/elite）。
- 顺序/去重：每个单位全场至多一条；其后不再出现以该单位为 `actor`/`target` 的事件。
- 视觉：死亡墨散粒子 + 倒地帧 + 错峰渐出（缺失回退：透明度渐出，probe 既有形态）。
- 音频：`battleDeath` 槽位预留未接线（`audio_assets.dart:47,55`）；接线前回退**锁为静音**（manifest 同步锁定），禁止借 `battleStagger` 冒充死亡。
- 约束：elite 死亡可与 elite_broken 同拍，先播破招反馈再播死亡渐出；尸体不挡存活单位。

## 位移与技能

### dash_started
- 触发：突进位移开始的拍。
- payload：`actor`、`dash_role`（engage/reposition 语义类）。
- 顺序/去重：一次 dash 一发；dash 期间该 actor 不发 attack_started。
- 视觉：残影/速度线（缺失回退：无特效纯位移）。
- 音频：无。
- 约束：残影并入反馈池；残影透明度低于本体，不混淆站位读数。

### gather_started / gather_applied（Q 聚怪）
- 触发：started = 拉拢力场出现的拍；applied = 拉拢结算生效（位移/失衡落地）的拍。
- payload：`actor`；applied 另带 `outcomes`（有序 target outcome 列表，每项至少 `{target, resolved_damage（无伤害可缺省）, defeated, status_applied}`，均为模拟核结算结果）。
- 顺序/去重：一次 Q 严格 started→applied 各一发；applied 不早于 started；缺 applied 时表现层超时收束特效，不挂起。
- 视觉：多层旋转墨环 + 拉拢轨迹线；applied 时受击方脚下失衡土色环（缺失回退：双描边椭圆环 + 内向短线，probe 既有形态）。
- 音频：聚怪音效为新资产（缺失回退：静音，不借用其他槽位）。
- 约束：拉拢期间受影响单位保持可辨；墨环层数有上限，不叠 `saveLayer`；群体飘字/失衡只消费 `outcomes`，不重算。

### clear_started / clear_applied（R 清场）
- 触发：started = 清场释放、镜头震动与停顿开始的拍；applied = 群体结算生效的拍。
- payload：`actor`；applied 另带 `outcomes`（同 gather_applied 的有序 target outcome 结构；群体飘字/死亡/失衡只消费结果不重算）。
- 顺序/去重：同 gather 的 started→applied 规则。
- 视觉：全屏径向墨迹扩散（缺失回退：Canvas 扩散墨环，probe 既有形态）+ 群体飘字。
- 音频：`battleUlt.mp3`（现借用，专属资产见 manifest）。
- 约束：清场是全屏最强反馈，同拍压掉普通命中题字；震动幅度不遮 HUD 技能印。

## 精英破招链路

### elite_telegraph_started
- 触发：精英蓄招预告出现的拍。
- payload：`actor`（精英）、`threat_level`（telegraph/imminent 语义档，对齐 probe `FeedbackDanger`）。
- 顺序/去重：一次蓄招一发；同一精英新 telegraph 隐含终结旧 telegraph。
- 视觉：预告环 + 窗口期变色（缺失回退：既有预告环 Canvas 形态）。
- 音频：`battleChargeStart.mp3`（现借用资产，见 manifest）。
- 约束：预告环是最高读优先级，不得被任何攻击特效覆盖。

### break_window_opened
- 触发：可破招窗口开启的拍。
- payload：`actor`。
- 顺序/去重：telegraph 后至多一发；窗口关闭无需事件（由 HUD 印态与 telegraph 终结表达）。
- 视觉：窗口高亮（绛红点色，仅允许在预告语义下出现，对齐 probe 冻结视觉语言）。
- 音频：无（避免与 chargeStart 叠音）。
- 约束：窗口视觉只在 elite_telegraph_started 之后出现，孤立 window 事件直接丢弃。

### elite_broken
- 触发：破招成功、精英进入失衡的拍。
- payload：`actor`。
- 顺序/去重：一次蓄招至多一发；与 telegraph 一一对应。
- 视觉：破招瞬间小爆发墨粒 + 失衡姿势帧（缺失回退：stagger 姿势格 + 闪白）。
- 音频：`battleInterrupt.mp3`（已接线，既有生产消费点 `battle_screen.dart:747-748` 同款槽位）。
- 约束：破招是精英链路最高奖励反馈，允许短暂 hit-stop；不破招（蓄招放出）无本事件。

## 波次与终局

### wave_started
- 触发：新一波敌人入场驱动的拍。
- payload：`wave_index`、`wave_total`。
- 顺序/去重：每场战斗 wave_index 严格递增；重复 index 丢弃。
- 视觉：宣纸横幅（第 N 波）+ 敌人墨入淡入（缺失回退：纯 HUD 顶栏文本）。
- 音频：复用 `uiPaperOpen.mp3` 或新资产（见 manifest）。
- 约束：横幅不遮战斗区主体；入场淡入期间敌人可辨不可误导为可命中。

### wave_cleared
- 触发：一波全部敌方单位移除完成的拍。
- payload：`wave_index`。
- 顺序/去重：与 wave_started 一一对应；最后一波 cleared 之后必有 victory/defeat 其一。
- 视觉：横幅收束 + 波间回气窗提示（缺失回退：HUD 文本）。
- 音频：无（克制，留白）。
- 约束：与 wave_started 间隔内不重复播横幅。

### battle_victory / battle_defeat
- 触发：结算结果翻转、全场仅一发的终局事件（对齐生产 resolve 语义：胜负自最终状态派生，唯一来源）。
- payload：`result` 隐含于事件名；无其他字段。
- 顺序/去重：全场至多一条终局事件；其后一切战斗事件被表现层忽略。
- 视觉：胜/败结算 overlay（复用根应用既有「勝/敗」overlay 语义）；前奏可加收刀/墨收姿态（缺失回退：直接 overlay）。
- 音频：`victory.mp3` / `defeat.mp3`（既有资产，已在生产结算 overlay 接线）。
- 约束：终局事件触发后反馈池清空，不再播残留特效。

## HUD

### skill_availability_changed
- 触发：任一技能印可用态迁移的拍（冷却转好 / 气不足 / 进入吟唱 / 被压制等）。
- payload：`slot`（技能印语义位）、`availability`（五态枚举：`ready` / `cooldown` / `qi` / `casting` / `down`）；`cooldown` 态必带 `cooldown_remaining`，`qi` / `ready` 态可带 `qi_current` / `qi_required`——均为模拟核运行态快照，不写成配置常量。
- 顺序/去重：同一 `slot` 状态未变不重发；同拍多槽各发一条。
- 视觉：技能印五态水墨化（probe `_SkillSeal` 五态为形态参考）；中文态名走 data 文案层，不硬编码。
- 音频：`ready` 迁移可配轻微提示音（默认无，克制）；其余静音。
- 约束：HUD 数据源 10Hz 轮询即可（probe 已验证），事件驱动只覆盖迁移瞬间；五态色不越水墨色板。

## 复核命令

```sh
grep -n "battleDeath" lib/shared/audio/audio_assets.dart          # :47,:55 预留未接线
grep -rn "temporaryBorrowed" lib/shared/audio/dedicated_audio_assets.dart  # battleUlt/battleChargeStart 借用
ls assets/audio/sfx/                                              # 19 个 mp3 在列
sed -n 70,86p lib/shared/audio/audio_assets.dart                  # battleHit 变体 + sfxForAction 语义
sed -n 13,23p tools/phase0minus_probe/lib/phase0b/feedback/feedback_cues.dart  # probe cue 枚举参考
```
