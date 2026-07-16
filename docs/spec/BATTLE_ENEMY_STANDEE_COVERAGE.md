# 战斗敌人全身立绘覆盖与验收台账

> 目标：所有正式主线与爬塔敌人使用透明全身战斗立绘，统一为低饱和、写实水墨武侠风格，并在真实关卡数据下完成 1280×720 / 1440×900 双视口验收。

## 基线盘点（2026-07-16）

- 正式数据：`data/stages.yaml` + `data/towers.yaml`
- 不重复敌人原画：79 种
- 关卡中敌人出场记录：120 次
- 已接入透明全身立绘：8 / 79
- 已覆盖出场记录：25 / 120

已覆盖正式敌人：

- `thug_a`
- `qingshan_main`
- `black_killer`
- `umbrella`
- `tower_boss_20`
- `zuo_hufa`
- `you_hufa`
- `tower_boss_30`

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

## 后续优先级

1. 高复用组：`jianghu_qianbei` / `wulin_bazhu` / `anye` / `shiye` / `fu_zhaizhu`。
2. 早期主线组：`thug_b` / `thug_c` / `ruffian_a` / `bandit_head` / `qingshan`。
3. 章节 Boss 与爬塔 Boss 组。
4. 轻功与群战专属敌人组。
5. 其余低复用普通敌人，最后进行全关卡自动截图审计。
