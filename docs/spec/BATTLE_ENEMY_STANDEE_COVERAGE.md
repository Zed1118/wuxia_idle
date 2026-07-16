# 战斗敌人全身立绘覆盖与验收台账

> 目标：所有正式主线与爬塔敌人使用透明全身战斗立绘，统一为低饱和、写实水墨武侠风格，并在真实关卡数据下完成 1280×720 / 1440×900 双视口验收。

## 基线盘点（2026-07-16）

- 正式数据：`data/stages.yaml` + `data/towers.yaml`
- 不重复敌人原画：79 种
- 关卡中敌人出场记录：120 次
- 已接入透明全身立绘：45 / 79
- 已覆盖出场记录：86 / 120

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
- `thug_b`（专属青年棍手立绘）
- `thug_c`（专属落魄短刃客立绘）
- `ruffian_a`（专属乡野泼皮立绘）
- `bandit_head`（专属独眼匪首立绘）
- `qingshan`（专属青衫青年剑客立绘）
- `elder_grey`（专属竹杖灰须老者立绘）
- `shaonian`（专属春水堂拳掌青年立绘）
- `guntou`（专属光头长棍客立绘）
- `jianghu_a`（过渡复用 `battle_jianghu_qianbei`）
- `mingmen_a`（过渡复用 `battle_wulin_bazhu`）
- `tower_boss_05`（过渡复用 `battle_bandit_blade`）
- `tower_boss_10`（过渡复用 `battle_jianghu_qianbei`）
- `tower_boss_15`（过渡复用 `battle_anye`）
- `tower_boss_25`（过渡复用 `battle_bandit_blade`）
- `bandit_b`（过渡复用 `battle_bandit_blade`）
- `bandit_c`（过渡复用 `battle_thug_a`）
- `jianghu_b`（过渡复用 `battle_shiye`）
- `liukou_a`（过渡复用 `battle_fu_zhaizhu`）
- `guard_a`（过渡复用 `battle_wulin_bazhu`）
- `shafei_a`（过渡复用 `battle_bandit_archer`）
- `xiliangboss`（过渡复用 `battle_shiye`）
- `xiliangbazhu`（过渡复用 `battle_wulin_bazhu`）
- `tongguan_shoujiang`（过渡复用 `battle_tower_boss_20`）
- `songshan_daozong_dizi`（过渡复用 `battle_umbrella`）
- `caobang_duozhu`（过渡复用 `battle_jianghu_qianbei`）
- `zhongzhou_lunjian_xianfeng`（过渡复用 `battle_zuo_hufa`）
- `xiliang_sandizi`（过渡复用 `battle_you_hufa`）
- `lunjian_sanchang_xunluo`（过渡复用 `battle_black_killer`）
- `songshan_shouguan`（过渡复用 `battle_hidden_elder`）
- `huanghe_yuantou_yufu`（过渡复用 `battle_jianghu_qianbei`）
- `kunlun_waimen_shouguan`（过渡复用 `battle_tower_boss_20`）
- `xiliang_bazhu`（过渡复用 `battle_wulin_bazhu`）

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

### 批次 03：早期主线专属覆盖（资产接入完成，整队验收中）

- 专属立绘：`thug_b` → `battle_thug_b`（青年棍手）；`thug_c` → `battle_thug_c`（瘦削落魄短刃客）；`ruffian_a` → `battle_ruffian_a`（束发短棍、斜挎布囊的乡野泼皮）；`bandit_head` → `battle_bandit_head`（独眼、灰须、宽背刀的魁梧匪首）；`qingshan` → `battle_qingshan`（青色束额、窄身直剑的青年剑客）。
- 新增覆盖：6 次敌人出场记录；累计覆盖 57 / 120。
- 目的：先让早期主线与低层爬塔脱离旧纸底头像降级路径，进入透明全身立绘战斗展示。
- 限制：五名早期过渡敌人均已替换为专属画像；本批剩余工作是 `stage_01_02`、`stage_01_03`、`stage_01_04` 与塔 2 / 3 / 8 层整队双视口验收。
- 真实截图：`stage_01_04` 1440×900 已跑通，发现 `qingshan` 复用白须长者会与玩家祖师撞脸，已改为刀客系过渡；山道背景右半区仍有暖黄块，待后续做山道冷灰校正。
- 待验收：`stage_01_02`、`stage_01_03`、`stage_01_04` 与塔 2 / 3 / 8 层整队双视口。

### 批次 04：高频纸底半身图过渡覆盖（已接入，待专属重做）

- 过渡映射：`jianghu_a` → `battle_jianghu_qianbei`、`mingmen_a` → `battle_wulin_bazhu`
- 新增覆盖：4 次敌人出场记录；累计覆盖 61 / 120。
- 目的：优先移除仍以纸底半身图进入正式战斗的高频敌人。
- 限制：本批为复用过渡，不代表 `jianghu_a` / `mingmen_a` 专属画像最终完成；后续需要按“江湖客 / 名门执事”身份重做专属透明全身立绘。

### 批次 05：中段爬塔 Boss 过渡覆盖（已接入，待专属重做）

- 过渡映射：`tower_boss_05` → `battle_bandit_blade`、`tower_boss_10` → `battle_jianghu_qianbei`、`tower_boss_15` → `battle_anye`、`tower_boss_25` → `battle_bandit_blade`
- 新增覆盖：4 次敌人出场记录；累计覆盖 65 / 120。
- 目的：优先移除 Boss 关卡中的纸底半身图，保证正式战斗至少全身透明展示。
- 限制：本批为复用过渡，四名爬塔 Boss 身份差异明显，后续必须补专属透明全身立绘。

### 批次 06：低层塔敌与西域主线过渡覆盖（已接入，待专属重做）

- 过渡映射：`bandit_b` → `battle_bandit_blade`、`bandit_c` → `battle_thug_a`、`jianghu_b` → `battle_shiye`
- 西域映射：`liukou_a` → `battle_fu_zhaizhu`、`guard_a` → `battle_wulin_bazhu`、`shafei_a` → `battle_bandit_archer`
- 新增覆盖：6 次敌人出场记录；累计覆盖 71 / 120。
- 选择依据：分别保留刀客、喽啰、游侠、魁梧头领、关隘武官与荒漠远程手的体型/武器轮廓差异，避免整队使用同一模型。
- 限制：仍属过渡复用；特别是 `guard_a` 和 `shafei_a` 需在图像生成恢复后重做带关隘甲胄、风沙衣料的专属立绘。

### 批次 07：第四至六章主线全身化（已接入，待专属重做）

- 覆盖范围：`stage_04_04` 至 `stage_06_05` 共 12 名正式敌人。
- 新增覆盖：12 次敌人出场记录；累计覆盖 83 / 120。
- 轮廓分组：武林名宿/霸主使用文士与掌门体型；潼关、论剑、昆仑守将使用甲胄、持剑与长兵轮廓；嵩山门人、漕帮舵主、黄河渔人使用轻袍、杖客与老者轮廓。
- 限制：本批目标是让连续主线不再回落到纸底头像，仍非专属画像定稿。`tongguan_shoujiang`、`kunlun_waimen_shouguan`、`xiliangbazhu` / `xiliang_bazhu` 的身份级别差异需要后续专属立绘强化。

### 批次 08：第二章长尾专属化（资产接入完成，整队验收中）

- 专属立绘：`elder_grey` → `battle_elder_grey`（布帽、灰须、竹杖的笑面老者，避免与白发宽袍祖师撞型）；`shaonian` → `battle_shaonian`（轻灰练功服、拳掌架势的春水堂青年）；`guntou` → `battle_guntou`（粗壮光头、长铁头棍的乡野棍客，区别于僧人和精瘦刀客）。
- 新增覆盖：3 种敌人 / 3 次出场；累计覆盖 45 / 79 种、86 / 120 次出场。
- 技术验收：三图均为 RGBA、alpha `0–255`、四角透明、完整头脚；脚底比例已写入战场锚点。
- 待完成：`stage_02_02` / `stage_02_03` / `stage_02_04` 的真实整队双视口验收。

## 后续优先级

1. 完成高复用组真实关卡整队双视口验收。
2. 完成早期主线与低层塔整队双视口验收。
3. 章节 Boss 与爬塔 Boss 专属重做组。
4. 轻功与群战专属敌人组。
5. 其余低复用普通敌人，最后进行全关卡自动截图审计。
