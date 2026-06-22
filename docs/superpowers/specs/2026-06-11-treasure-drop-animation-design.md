# 爆品展示动画 + reward 音效重做 — 设计

> 2026-06-11 · 真玩验收驱动 · brainstorming 收敛
> 背景:用户真玩反馈 ① reward(爆装备)jingle 与 victory 风格太像、听感重叠 ② 现有掉落只在结算 AlertDialog 里一行行列出,高阶爆品「没有爽感」。
> 目标:高阶爆品掉落时先播一段水墨印章盖落全屏动画(爽感),再照常进结算弹窗;reward 音效重做并门槛化(只高阶爆品才响)。

## 决策汇总(brainstorming 拍板)

| 项 | 决策 |
|---|---|
| 触发门槛 | 装备 tier ≥ **重器(zhongQi, 5阶)** → 重器/宝物/神物。写 numbers.yaml 可配。 |
| 动画与弹窗 | **动画在前 → 弹窗保留**。动画播完照常 `showStageVictoryDialog`(弹窗仍承载升层/共鸣/全部掉落)。 |
| 动画形态 | **印章盖落 + 震屏 + 墨团炸开背景 + 墨点四散**,tier 色梯度(重器青铜/宝物紫/神物金,神物墨团更大)。印章统一绛红。 |
| 触发范围 | **主线 + 爬塔** 都要,抽公共触发点。 |
| 低阶掉落音 | 重器以下掉装备 **完全静音**(只靠弹窗 tier 色行)。新 reward 专属高阶爆品。 |
| 多件高阶 | **取最高 tier 播一次**,其余高阶仍在弹窗列表。 |
| reward 音效 | 重做(Suno),「获得宝物」珍稀质感,明确区别 victory 上扬。 |

## 架构(5 单元)

### 1. 触发判定(纯函数,可测)
- numbers.yaml 加 `treasure_drop.min_tier: zhongQi`(枚举名,可配)。Numbers 模型加对应字段 + 解析。
- 新纯函数 `pickTreasureHighlight(DropResult drops, EquipmentTier minTier) → TreasureHighlight?`:
  扫 `drops.equipments`(经 GameRepository 取 tier),返回 tier ≥ minTier 中**最高 tier**那件(`defId / tier / name`);并列取首件;无则 null。
- `TreasureHighlight` 值对象(defId, tier, name)。放 `lib/features/equipment/domain/`。
- 复用现有 `isHighTreasureTier`(tier_colors.dart:24)体例,但门槛改读 yaml。

### 2. 动画组件(新 widget,复用现有基建)
- `TreasureDropContent`(静态展示,无动画):墨团背景(复用 `assets/ui/mj/caption_ink_blob.png` + ColorFiltered 染 tier 色)+ 装备图标(`EquipGlyph`,equipment_glyph.dart)+ 名 + 绛红印章(tier 题字「重器/宝物/神物」)+ 墨点。沿 `UltimateCaptionContent`(ultimate_caption_overlay.dart:17)体例,便于 widget test + 视觉验收路由。
- `TreasureDropOverlay`(StatefulWidget + AnimationController,沿 `UltimateCaptionOverlay`:78/104/119 体例):驱动墨团炸开→印章盖落→震屏→墨点四散→保持→淡出,总时长 ~1.3s;**barrier 点击跳过**(挂机防烦)。
- tier 色梯度:扩 `tier_colors.dart`,新增 `treasureGlowColor(tier)` / `treasureSeedColor(tier)`(重器青铜 #c89b3c / 宝物紫 #b886e6 / 神物金 #f0d878)。印章色统一绛红(WuxiaColors 绛红 token)。
- 文案「重器/宝物/神物」走 `EnumL10n.equipmentTier`(已有);标题文案(如「获此神物」)走 UiStrings,不硬编码。

### 3. 音效(reward 重做)
- `assets/audio/sfx/reward.mp3` 重新生成(Suno Sounds,珍稀获得质感)。Prompt 写入 `docs/_archive/suno/suno_reward_treasure_sfx_prompts_2026-06-11.md`(沿 battlehit v3 prompt 体例),用户生成→裁切归一→替换。enum/路径不变,零接线改动。
- 触发:只在动画播放时(§4 触发点)随动画起播。重器以下静音。

### 4. Wiring(主线+塔公共触发点)
- 新公共函数 `playTreasureDropIfAny({context, drops, required bool gate}) → Future<void>`:
  `gate && (h = pickTreasureHighlight(drops, minTier)) != null` → 播 `TreasureDropOverlay`(showGeneralDialog 透明 barrier,沿 victory_overlay 体例 + 新 reward 音)→ await 动画/跳过结束。否则立即返回。
- 主线 `stage_entry_flow.dart:184`(showStageVictoryDialog 前)插入 `await playTreasureDropIfAny(context, drops, gate: true)`。
- 塔 `tower_entry_flow.dart`(_showVictoryDialog 前)插入 `gate: isFirstClear`(沿现有 reward 的 isFirstClear gate,行为一致)。
- **删旧 reward 触发**:`stage_victory_dialog.dart:35-36` + `tower_entry_flow.dart:550-551` 的 `playSfx(SfxId.reward)` 删除(移到动画层 + 门槛化)。`realmAdvance` 优先逻辑**保留**(跨 tier 突破时弹窗里仍播 realmAdvance 音;动画在前、弹窗在后,时序分开不叠)。

### 5. 测试 + 红线
- 纯函数 `pickTreasureHighlight` 边界测:空掉落/全低阶→null;重器边界(像样货 4 不触发、重器 5 触发);多件取最高 tier;并列取首。
- `TreasureDropContent` widget pump 测(三档 tier 渲染不崩 + 图标 errorBuilder)。
- 素材存在守卫测(reward.mp3)+ numbers 解析测(min_tier 字段)。
- 红线:门槛进 numbers.yaml(不硬编码)、印章/标题文案走 EnumL10n/UiStrings(不硬编码中文)、§5.4 数值无关、Image.asset 带 errorBuilder。

## 文件清单
**新建**:`lib/features/equipment/domain/treasure_highlight.dart`(值对象+纯函数) · `lib/features/equipment/presentation/treasure_drop_overlay.dart`(Content+Overlay+playTreasureDropIfAny) · `docs/_archive/suno/suno_reward_treasure_sfx_prompts_2026-06-11.md` · 对应 test。
**修改**:`data/numbers.yaml`(+treasure_drop.min_tier) · Numbers 模型+解析 · `tier_colors.dart`(+treasure 色) · `stage_entry_flow.dart`(插触发点) · `tower_entry_flow.dart`(插触发点+删旧 reward) · `stage_victory_dialog.dart`(删旧 reward) · `assets/audio/sfx/reward.mp3`(重做素材) · UiStrings(标题文案)。

## 风险 / 开放点
- 动画在战斗结束后、弹窗前的 Navigator context 播(showGeneralDialog),需确认此时 context.mounted(主线已有 `if (outcome != null && context.mounted)` 守卫,沿用)。
- realmAdvance(跨 tier 突破)与 treasure 动画可能同场:动画播爆品(视觉+新 reward 音),弹窗播 realmAdvance 音,时序分离不叠。若同场观感仍重,后续可让突破时跳过 treasure 动画(留观察,不预先做)。
- reward 素材依赖用户 Suno 生成:动画 wiring 可先用占位/旧 reward 落地,素材到位后替换(解耦)。
