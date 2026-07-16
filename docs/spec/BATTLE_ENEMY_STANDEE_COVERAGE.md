# 战斗敌人全身立绘覆盖与验收台账

> 目标：所有正式主线与爬塔敌人使用透明全身战斗立绘，统一为低饱和、写实水墨武侠风格，并在真实关卡数据下完成 1280×720 / 1440×900 双视口验收。

## 基线盘点（2026-07-16）

- 正式数据：`data/stages.yaml` + `data/towers.yaml`
- 不重复敌人原画：79 种
- 关卡中敌人出场记录：120 次
- 已接入透明全身立绘：79 / 79
- 已覆盖出场记录：120 / 120

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
- `guntou_zhu`（专属擂主光头汉立绘）
- `seng_huiyi`（专属灰袍僧人立绘）
- `balian`（专属疤脸汉子 Boss 立绘）
- `huiyi`（专属章末灰衣剑客 Boss 立绘）
- `lightfoot_shuikou_a`（专属渡口水寇立绘）
- `lightfoot_shuikou_b`（专属渡口船工立绘）
- `lightfoot_shuikou_c`（专属渡口刀客立绘）
- `lightfoot_yexun_a`（专属城防夜巡立绘）
- `lightfoot_yexun_b`（专属飞檐捕快立绘）
- `lightfoot_yexun_c`（专属瓦上刺客立绘）
- `lightfoot_zhuke_a`（专属江南剑客立绘）
- `lightfoot_zhuke_b`（专属密竹刀客立绘）
- `lightfoot_zhuke_c`（专属竹林游侠立绘）
- `lightfoot_pubu_a`（专属山涧剑客立绘）
- `lightfoot_pubu_b`（专属瀑布刀客立绘）
- `lightfoot_pubu_c`（专属险崖游侠立绘）
- `lightfoot_changfeng_a`（专属关楼守将 Boss 立绘）
- `lightfoot_changfeng_b`（专属长风剑客立绘）
- `lightfoot_changfeng_c`（专属万里刀客立绘）
- `massbattle_cunfei_a`（专属山贼头目立绘）
- `massbattle_cunfei_b`（专属山贼弓手立绘）
- `massbattle_cunfei_c`（专属山贼刀客立绘）
- `massbattle_zhenkou_a`（专属匪众头领立绘）
- `massbattle_zhenkou_b`（专属匪众游侠立绘）
- `massbattle_zhenkou_c`（专属匪众刺客立绘）
- `massbattle_xianjie_a`（专属他派宗主立绘）
- `massbattle_xianjie_b`（专属他派护法立绘）
- `massbattle_xianjie_c`（专属他派门徒立绘）
- `massbattle_guanqi_a`（专属胡骑万夫长立绘）
- `massbattle_guanqi_b`（专属胡骑游骑立绘）
- `massbattle_guanqi_c`（专属胡骑铁卫立绘）
- `massbattle_canbu_a`（专属西凉残将 Boss 立绘）
- `massbattle_canbu_b`（专属西凉狂骑立绘）
- `massbattle_canbu_c`（专属西凉刺客立绘）
- `jianghu_a`（专属戴笠江湖掌客立绘）
- `mingmen_a`（专属名门弟子立绘）
- `tower_boss_05`（专属试剑石老叟立绘）
- `tower_boss_10`（专属黑风寨主立绘）
- `tower_boss_15`（专属暗夜阁主立绘）
- `tower_boss_25`（专属绝顶剑魔立绘）
- `bandit_b`（专属三流刀客立绘）
- `bandit_c`（专属黑风寨老喽啰立绘）
- `jianghu_b`（专属江湖游侠立绘）
- `liukou_a`（专属流寇头领立绘）
- `guard_a`（专属玉门关把总立绘）
- `shafei_a`（专属沙匪头领立绘）
- `xiliangboss`（专属西凉武林名宿立绘）
- `xiliangbazhu`（专属西凉霸主立绘）
- `tongguan_shoujiang`（过渡复用 `battle_tower_boss_20`）
- `songshan_daozong_dizi`（过渡复用 `battle_umbrella`）
- `caobang_duozhu`（过渡复用 `battle_jianghu_qianbei`）
- `zhongzhou_lunjian_xianfeng`（专属中州论剑先锋立绘）
- `xiliang_sandizi`（专属西凉霸主三弟子立绘）
- `lunjian_sanchang_xunluo`（过渡复用 `battle_black_killer`）
- `songshan_shouguan`（过渡复用 `battle_hidden_elder`）
- `huanghe_yuantou_yufu`（过渡复用 `battle_jianghu_qianbei`）
- `kunlun_waimen_shouguan`（专属昆仑外门守关立绘）
- `xiliang_bazhu`（专属武圣阶段西凉霸主立绘）

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

### 批次 09：第三章长尾与 Boss 专属化（资产接入完成，整队验收中）

- 专属立绘：`guntou_zhu` → `battle_guntou_zhu`（光头黑须、赤臂拳架的擂台霸主）；`seng_huiyi` → `battle_seng_huiyi`（瘦削老僧、灰袍开掌的阴柔武者）；`balian` → `battle_balian`（面有长疤、旧红褐短甲的近战 Boss）；`huiyi` → `battle_huiyi`（束发短须、冷灰长袍与直剑的章末 Boss）。
- 新增覆盖：4 种敌人 / 4 次出场；累计覆盖 49 / 79 种、90 / 120 次出场。
- 身份去重：擂主不复用第二章长棍客；灰袍僧不做魁梧拳师；灰衣人不复用白须祖师或普通文士，四人轮廓、年龄、兵器均可区分。
- 技术验收：四图均为 RGBA、alpha `0–255`、四角透明、完整头脚；脚底比例与宽体画像的光学校准已写入战场路径。
- 待完成：`stage_03_02` / `stage_03_03` / `stage_03_04` / `stage_03_05` 的真实整队双视口验收。

### 批次 10：轻功特殊玩法专属化（进行中）

- 已完成渡口队：`lightfoot_shuikou_a`（宽刃水寇）、`lightfoot_shuikou_b`（斗笠竹篙船工）、`lightfoot_shuikou_c`（蒙巾窄刀客）。
- 已完成夜巡队：`lightfoot_yexun_a`（长枪城防夜巡）、`lightfoot_yexun_b`（绳钩飞檐捕快）、`lightfoot_yexun_c`（双匕瓦上刺客）。
- 已完成竹林队：`lightfoot_zhuke_a`（灰绿长袍直剑客）、`lightfoot_zhuke_b`（暗紫褐伏身刀客）、`lightfoot_zhuke_c`（卷发阔背棍游侠）。
- 已完成瀑布队：`lightfoot_pubu_a`（湿灰披风山涧剑客）、`lightfoot_pubu_b`（瘦削长刀客）、`lightfoot_pubu_c`（卷发灰须铁环杖游侠）。
- 已完成长风队：`lightfoot_changfeng_a`（暗铁甲关楼守将 Boss）、`lightfoot_changfeng_b`（削鬓灰须蓝灰剑客）、`lightfoot_changfeng_c`（风尘高领阔刀客）。
- 新增覆盖：15 种敌人 / 15 次出场；累计覆盖 64 / 79 种、105 / 120 次出场。
- 组队差异：三人共享渡口旧衣与湿冷暗色，但分别使用宽刃、竹篙、窄刀，并以壮年、老者、中年三种体态拆分轮廓。
- 技术验收：三图均为 RGBA、alpha `0–255`、四角透明、完整头脚与兵器；脚底比例及长兵器画像的视觉体量已校准。
- 资产覆盖：15 名轻功敌人全部完成专属透明全身立绘。
- 待完成：`stage_light_foot_01` 至 `05` 的真实整队双视口验收。

### 批次 11：群战特殊玩法专属化（进行中）

- 已完成村匪队：`massbattle_cunfei_a`（卷须阔背铁蒺藜头目）、`massbattle_cunfei_b`（布帽猎弓手）、`massbattle_cunfei_c`（卷须伏身阔刀客）。
- 已完成镇口队：`massbattle_zhenkou_a`（皮护胸巨斧头领）、`massbattle_zhenkou_b`（灰衣双头枪游侠）、`massbattle_zhenkou_c`（黑帽匕首钩刃刺客）。
- 已完成险界队：`massbattle_xianjie_a`（冷灰青直剑宗主）、`massbattle_xianjie_b`（方巾双判官笔护法）、`massbattle_xianjie_c`（灰青铁棍青年门徒）。
- 已完成关骑队：`massbattle_guanqi_a`（玄甲弓刀万夫长）、`massbattle_guanqi_b`（轻甲披风游骑）、`massbattle_guanqi_c`（圆盾短矛铁卫）。
- 已完成残部队：`massbattle_canbu_a`（残旗环首刀西凉残将 Boss）、`massbattle_canbu_b`（伏身长弧刀狂骑）、`massbattle_canbu_c`（双短刃轻甲刺客）。
- 新增覆盖：15 种敌人 / 15 次出场；累计覆盖 79 / 79 种、120 / 120 次出场。
- 组队差异：每队共享材质和色相，但通过统领、轻捷、重守三类体态及不同兵器拆分轮廓；关骑队不使用坐骑，避免破坏三人阵型和脚底落地关系。
- 技术验收：关骑与残部六图均为 RGBA、alpha `0–255`、四角透明、完整头脚和兵器；四边有效留白均不小于 8%。
- 待完成：`stage_mass_battle_01` 至 `05` 的真实整队双视口验收，以及台账中“过渡复用”条目的专属化重做。

### 批次 12：爬塔 Boss 过渡复用清理（进行中）

- `tower_boss_05` 已由普通山匪刀客复用替换为专属“试剑石老叟”：秃顶白发、补丁灰袍、横持试剑铁剑。
- `tower_boss_10` 已由江湖前辈复用替换为专属“黑风寨主”：文士面貌、黑风披肩、铁骨扇与佩剑。
- `tower_boss_15` 已由普通暗夜剑客复用替换为专属“暗夜阁主”：长发黑袍、冷峻直剑、克制阴柔轮廓。
- `tower_boss_25` 已由普通山匪刀客复用替换为专属“绝顶剑魔”：破旧蓝灰衣、双剑、写实疲惫面貌。
- 四图均为 RGBA、alpha `0–255`、四角透明、完整头脚和兵器；已接入脚底锚点及光学校准。
- 待完成：塔 5 / 10 / 15 / 25 的真实双视口验收。

### 批次 13：章节 Boss 过渡复用清理（进行中）

- `xiliangboss` 已由师爷复用替换为专属“西凉武林名宿”：灰发长髯、厚重旅袍、无兵器掌法起手。
- `xiliangbazhu` 已由通用武林霸主复用替换为专属“西凉霸主”：毛领重衣、重型长柄刀、宽阔压迫体态。
- `zhongzhou_lunjian_xianfeng` 已由左护法复用替换为专属“中州论剑先锋”：烟灰正统袍服、正式低位剑势。
- `xiliang_sandizi` 已由右护法复用替换为专属“西凉霸主三弟子”：年长秃首、暗梅短披、双月牙钩刃。
- `kunlun_waimen_shouguan` 已由通用塔 20 守将复用替换为专属昆仑守关：冷地毛领、额甲、铁头长棍。
- `xiliang_bazhu` 已由通用霸主复用替换为专属武圣形态：年长灰髯、无兵器开掌、克制宗师轮廓。
- 六图均为 RGBA、alpha `0–255`、四角透明、完整头脚和兵器；生产映射、脚底锚点均已接入。
- 待完成：章节 Boss 真实双视口验收；正式数据中已无仍复用他人立绘的 Boss。

### 批次 14：早期普通敌人过渡复用清理（进行中）

- `jianghu_a`、`mingmen_a`、`bandit_b`、`bandit_c`、`jianghu_b` 已分别替换为戴笠掌客、名门剑弟子、青年三流刀客、黑风寨老喽啰与中年游侠专属立绘。
- 五图均为 RGBA、alpha `0–255`、四角透明、完整头脚和兵器；四边有效留白均不小于 7%。
- 早期塔层与江湖队伍不再复用江湖前辈、武林霸主、山匪刀客、打手或师爷的脸。
- `liukou_a`、`guard_a`、`shafei_a` 已分别替换为巨斧流寇头领、长枪玉门把总、弓刀沙匪头领专属立绘。
- 边塞三图均为 RGBA、alpha `0–255`、四角透明、完整头脚和兵器；长枪画像保留完整枪尖与脚底。
- 待完成：余下 6 名普通敌人过渡复用及真实双视口验收。

## 后续优先级

1. 完成高复用组真实关卡整队双视口验收。
2. 完成早期主线与低层塔整队双视口验收。
3. 章节 Boss 与爬塔 Boss 专属重做组。
4. 轻功与群战专属敌人组。
5. 其余低复用普通敌人，最后进行全关卡自动截图审计。
