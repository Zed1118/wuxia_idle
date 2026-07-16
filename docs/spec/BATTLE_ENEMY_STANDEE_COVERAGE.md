# 战斗敌人全身立绘覆盖与验收台账

> 目标：所有正式主线与爬塔敌人使用透明全身战斗立绘，统一为低饱和、写实水墨武侠风格，并在真实关卡数据下完成 1280×720 / 1440×900 双视口验收。

## 基线盘点（2026-07-16）

- 正式数据：`data/stages.yaml` + `data/towers.yaml`
- 不重复敌人原画：79 种
- 关卡中敌人出场记录：120 次
- 已接入透明全身立绘：18 / 79
- 已覆盖出场记录：57 / 120

已覆盖正式敌人：

- `thug_a`
- `qingshan_main`
- `black_killer`
- `umbrella`
- `tower_boss_20`
- `zuo_hufa`
- `you_hufa`
- `tower_boss_30`
- `jianghu_qianbei`
- `wulin_bazhu`
- `anye`
- `shiye`
- `fu_zhaizhu`
- `thug_b`（过渡复用 `battle_bandit_archer`）
- `thug_c`（过渡复用 `battle_bandit_blade`）
- `ruffian_a`（过渡复用 `battle_thug_a`）
- `bandit_head`（过渡复用 `battle_bandit_blade`）
- `qingshan`（过渡复用 `battle_bandit_blade`）

## 统一资产规格

- 单人、完整头脚、至少保留 4% 画布边缘。
- 正面或四分之三侧面战斗站姿，默认朝战场左侧。
- 脚底共线，头、袖、裙摆、武器不得裁切。
- 人体比例写实，避免动漫脸、高饱和、游戏卡牌边框、幻想重甲和过度仙侠光效。
- 材质以磨损布衣、皮革、暗色金属为主；色相限于炭黑、旧褐、烟灰、暗靛等低饱和色。
- 生成中间稿使用纯色抠像背景；入库文件必须为 RGBA PNG，四角透明，无绿边、无投影、无文字与水印。
- 文件名：`assets/enemies/battle_<enemy_id>.png`；原画保留作为身份参考与降级路径。

## 单图技术验收

1. 图像格式为 RGBA PNG。
2. alpha 包围盒不触及画布边缘，头脚可见。
3. 脚底比例写入 `_stageStandeeFootFraction`。
4. 旧 `iconPath` 在 `_battleStandeeOverrides` 映射到新立绘。
5. 若透明画布留白导致视觉体量偏差，只在 `_stageStandeeOpticalProfile` 校准，不改战斗槽位。
6. 通过 `character_avatar_test.dart` 映射回归测试。

## 整队与关卡验收

- 验收最小单位是“一支完整敌队”，不以单张立绘通过代替整队验收。
- 检查同槽位视觉体量、脚底线、头部层级、武器互相遮挡、状态牌与技能栏边界。
- 检查人物与每张关卡背景的色温、明度和笔触兼容性。
- 普通 3v3、Boss、心魔、轻功和群战阵型分别验收。
- 截图日志不得出现 `RenderFlex overflow`、`FlutterError` 或 `VISUAL_ROUTE_ERROR`。

## 批次记录

### 批次 01：终局爬塔队（已完成）

- 新立绘：`tower_boss_30`、`zuo_hufa`、`you_hufa`
- 复用覆盖：14 次敌人出场记录
- 验收路由：`battle_guardian_ward`（真实 floor 30 敌队）
- 验收视口：1280×720、1440×900
- 结果：三名敌人完整头脚，无旧画像矩形背景，脚底与状态牌未侵入技能栏。
- 纠偏：`tower_boss_30` 初稿与玩家祖师同为白长须宽袍老者，身份轮廓冲突；已重做为瘦削短灰黑须、高领窄袍的 V2，并加映射回归约束。
- 场景：塔境使用独立冷灰低彩背景，`battle_innerrealm` 路径与 `tower` 轨道均禁止灯笼暖光，避免原画右半区返黄。
- 最终证据：`build/visual_acceptance/tower_background_and_boss_identity_final/`；双视口日志无 overflow / exception / route error。

### 批次 02：高复用敌人组（接入完成，逐关卡验收中）

- 新立绘：`jianghu_qianbei`、`wulin_bazhu`、`anye`、`shiye`、`fu_zhaizhu`
- 新增覆盖：26 次敌人出场记录；累计覆盖 51 / 120。
- 风格纠偏：`anye` 由动漫线稿重做为写实青年刺客；其余四人按宿将、掌门、谋士、寨主拆分体态与轮廓，避免同质老者。
- 技术验收：五图均为 RGBA PNG，alpha 范围 `0–255`、四角透明、完整头脚；脚底比例已写入战场锚点。
- 待验收：真实关卡整队的 1280×720 / 1440×900 体量、遮挡、色温与状态牌边界。

### 批次 03：早期主线过渡覆盖（已接入，待专属重做）

- 过渡映射：`thug_b` → `battle_bandit_archer`、`thug_c` → `battle_bandit_blade`、`ruffian_a` → `battle_thug_a`、`bandit_head` → `battle_bandit_blade`、`qingshan` → `battle_bandit_blade`
- 新增覆盖：6 次敌人出场记录；累计覆盖 57 / 120。
- 目的：先让早期主线与低层爬塔脱离旧纸底头像降级路径，进入透明全身立绘战斗展示。
- 限制：本批为复用过渡，不代表五名敌人专属画像最终完成；待图片生成能力恢复后补 `battle_thug_b` / `battle_thug_c` / `battle_ruffian_a` / `battle_bandit_head` / `battle_qingshan` 专属立绘。
- 真实截图：`stage_01_04` 1440×900 已跑通，发现 `qingshan` 复用白须长者会与玩家祖师撞脸，已改为刀客系过渡；山道背景右半区仍有暖黄块，待后续做山道冷灰校正。
- 待验收：`stage_01_02`、`stage_01_03`、`stage_01_04` 与塔 2 / 3 / 8 层整队双视口。

## 后续优先级

1. 完成高复用组真实关卡整队双视口验收。
2. 将早期主线过渡覆盖替换为专属新立绘：`thug_b` / `thug_c` / `ruffian_a` / `bandit_head` / `qingshan`。
3. 章节 Boss 与爬塔 Boss 组。
4. 轻功与群战专属敌人组。
5. 其余低复用普通敌人，最后进行全关卡自动截图审计。
