# wuxia_idle UI 差距细化与 Claude Code 推进指南

日期：2026-06-02  
项目：`F:\Projects\wuxia_idle`  
目标：把当前 UI 从“可运行的数据面板”推进到“玩家相信这是一个武侠游戏世界”的状态。  
使用对象：后续 Claude Code / Codex 接手 UI、美术接线、验收任务时阅读。

---

## 0. 先读规则

1. 必须先读项目根目录 `AGENTS.md` 和 `GDD.md`。
2. 本项目是写实武侠挂机游戏，不是修仙动作沙盒；《鬼谷八荒》只作为 UI 表达参考，不搬玩法、不搬美术、不复制素材。
3. 不要改 `data/narratives/`、`data/lore/`、`data/events/`，除非人类明确授权。
4. 不要新增每日任务、登录奖励、体力、抽卡、VIP、快进券等 GDD 禁区功能。
5. UI 改动优先走现有 Flutter/Riverpod 结构，不引入 Flame 等游戏引擎。
6. 每个任务都要带截图验收；Windows Desktop 实机优先。

---

## 1. 一句话结论

当前项目已有系统骨架、部分水墨背景和可用流程，但许多核心界面仍像“工程数据面板”：

- 战斗看不到真正角色。
- 角色面板缺少“人”的存在感。
- 装备像仓库列表，武器详情图还会被裁。
- 主线、爬塔、闭关多是列表入口，缺少江湖路径感。
- 成长事件缺少仪式感。
- 图片缺失被静默吞掉，导致空白和首字占位。

《鬼谷八荒》的主要参考价值不是玩法，而是：它会把系统包装成世界里的场所、器物、人物和事件。

---

## 2. 《鬼谷八荒》参考素材是否写入项目

结论：写入“参考索引”，不要把图片文件复制进项目，也不要把它们当可用资产。

原因：

- 商业游戏截图有版权，不能作为项目素材直接使用。
- 可以作为 UI 对标参考：布局、视觉隐喻、信息层级、交互密度。
- 后续美术应按 wuxia_idle 的写实武侠方向重新产出，不做修仙化、妖兽化、二创搬运。

建议文档中保留这些链接和观察点，方便 Claude Code / 美术 / 策划统一讨论。

---

## 3. 参考素材索引

主要来源：

- Steam 商店页：https://store.steampowered.com/app/1468810/
- SteamDB 截图页：https://steamdb.info/app/1468810/screenshots/
- 游民星空系统界面说明：https://www.gamersky.com/handbook/202101/1359482_6.shtml
- 鬼谷八荒 Fandom 突破：https://guigubahuang.fandom.com/zh/wiki/%E7%AA%81%E7%A0%B4
- BWiki 技能分类：https://wiki.biligame.com/ggbh/%E6%8A%80%E8%83%BD

官方 Steam 截图观察索引：

| # | 图像类型 | 可借鉴点 | 链接 |
|---|---|---|---|
| 00 | 突破/角色成长 | 卷轴大框、路径立牌、材料图标、选中光效，成长像仪式而非表格 | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1468810/ss_b9c957bb0bbbbb8424539df6ceb88cfb5db6e432.1920x1080.jpg |
| 01 | 大地图 | 地点、天气、路线、载具、区域差异共同构成世界层 | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1468810/ss_925f334a68756499cb41514e76674f17022e544f.1920x1080.jpg |
| 02 | 宗门藏经阁 | 商店/心法不只是列表，而是建筑剖面、楼层、货架 | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1468810/ss_2867104a1a0176169463ec788ec275c3e62e713b.1920x1080.jpg |
| 03 | 过场/试炼 | 一张大图建立角色、地点、事件关系 | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1468810/ss_c1701379f00439e2299ba6300b9c2b79f9cc6b6e.1920x1080.jpg |
| 04 | 炼丹/材料 | 丹炉、材料槽、属性柱让数字变成器物操作 | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1468810/ss_9818406c160a6f22117007c99b222abcdb960863.1920x1080.jpg |
| 05 | 画符小游戏 | 任务不是按钮，而是具体道具与操作对象 | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1468810/ss_27ea26e3b6d1994e9191f4ef8ec3a143bde5751b.1920x1080.jpg |
| 06 | 灵妖编队 | 单位卡有形象，右侧队伍槽能看出编队关系 | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1468810/ss_76b533fd97daec4f74f32299606e46bc5994e40c.1920x1080.jpg |
| 07 | NPC 对话 | 左右立绘 + 背景虚化 + 对话框，人物关系立即成立 | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1468810/ss_538bddce6871717d402e30d1d3ce749a66c08c08.1920x1080.jpg |
| 08 | 属性克制盘 | 抽象规则被做成器物，降低说明文字负担 | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1468810/ss_50b8ca4426afd14b5d833720379e1cae447b3ad2.1920x1080.jpg |
| 09 | 大规模战斗 | 大体量敌人、弹道、受击数字、场地特效，战斗可见 | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1468810/ss_0928992aa4687b7f87b18b0946874d616db66ab3.1920x1080.jpg |
| 10 | BOSS 战 | 地形、弹幕、技能条、角色比例共同支撑战斗阅读 | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1468810/ss_e2bfd77c31a2d46a502bb908fdc711df6b3b83b7.1920x1080.jpg |
| 11 | 事件弹窗 | 事件插画、边框、龙纹、云纹让文本成为可记住的事件 | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1468810/ss_be198b449ce344b16a6dd22506440064e4686cd2.1920x1080.jpg |
| 12 | 编队英文页 | 信息密集但仍靠单位图承托；也提醒我们避免小字问题 | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1468810/ss_26952dfdb97a824fac7d9c965c2dbd441c0acb5f.1920x1080.jpg |
| 13 | 宗门战地图 | 战场节点、资源条、范围圈、目标提示形成战略态势 | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1468810/ss_ad5f520b05798e81c6c963b447da6b0b4a01cfdf.1920x1080.jpg |
| 14 | 设施升级 | 场所中心物、角色立绘、说明牌、资源条共同表达成长 | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1468810/ss_ddf9eef113b38e453c422dc8b45b7d9472e48741.1920x1080.jpg |

---

## 4. 当前项目已观察问题

### 4.1 战斗角色不可见

现象：

- 战斗画面中玩家和敌人多为小圆头像、首字占位、血条和日志。
- 背景已经存在，但中心战斗区域没有清晰角色站位、攻击轨迹、受击反馈。
- 胜利遮罩出现后，小头像更难辨认。

代码证据：

- `lib/features/battle/domain/battle_state.dart`：`BattleCharacter.fromCharacter` 对玩家 `iconPath: null`。
- `lib/features/battle/presentation/character_avatar.dart`：默认 `avatarSize = 80`，缺图降级为首字圆头像。
- `lib/features/battle/presentation/battle_screen.dart`：左侧日志固定 `width: 220`，日志比战斗角色更抢眼。

对标差距：

- 《鬼谷八荒》战斗中，角色身体、敌人体量、弹道、伤害数字、范围特效是第一视觉。
- 我们现在第一视觉是日志和背景，战斗单位本身不是主角。

### 4.2 角色面板像数值报表

现象：

- 根骨、悟性、身法、机缘、派生数值、装备、心法、招式都是文字块。
- 角色身份、立绘、师徒关系、当前修行状态没有成为主视觉。
- 旧存档或缺 `portraitPath` 时，立绘框会空着。

代码证据：

- `lib/shared/widgets/portrait_frame.dart`：`portraitPath == null` 时 child 为 `SizedBox.shrink()`，外框仍存在。
- `data/masters.yaml` 有 `portraitPath`，但战斗侧没有使用角色立绘。

对标差距：

- 《鬼谷八荒》人物对话和角色相关页会用大立绘、头像、关系、气运/能力共同建立人物存在。
- 我们现在更像角色数据库。

### 4.3 装备展示不完整

现象：

- 仓库是 56px 小图标长列表，大量文字和空白。
- 装备详情页固定 180 高横幅，`BoxFit.cover` 会裁掉细长武器。
- 武器、护甲、饰品的视觉差异没有成为第一阅读层。

代码证据：

- `lib/features/inventory/presentation/inventory_screen.dart`：图标固定 56x56，`BoxFit.cover`。
- `lib/features/inventory/presentation/equipment_detail_screen.dart`：详情图 `height: 180`，`BoxFit.cover`。

对标差距：

- 《鬼谷八荒》的秘籍、材料、丹炉、货架都把物品放在具体场所和容器里。
- 我们现在更像后台物品表。

### 4.4 世界层缺失

现象：

- 主线、爬塔、闭关多是列表和卡片入口。
- 玩家看不到自己的江湖路径、塔层进度、闭关地点关系。

对标差距：

- 《鬼谷八荒》的大地图和宗门战地图把进度、地点、资源、目标做成空间。
- Demo 不需要开放世界，但需要一个静态或轻交互的“江湖路径图”。

### 4.5 成长事件缺少仪式感

现象：

- 心法升层、装备共鸣、境界推进、离线结算多依赖数字、进度条、结果文本。
- 缺少“我悟了 / 我突破了 / 我得了一件好兵器”的瞬间。

对标差距：

- 《鬼谷八荒》的突破页、炼丹页、事件页都让系统结果有实体仪式。

### 4.6 资产缺失与静默失败

只读扫描结果：

- `data` 和 `lib` 中 png 引用共 332 个。
- 缺失 152 个。
- 其中 `assets/enemies` 缺 107 个，`assets/equipment` 缺 45 个。

风险：

- 敌人、装备、角色图静默消失。
- QA 不容易发现，因为大量 `errorBuilder` 使用 `SizedBox.shrink()` 或首字兜底。

---

## 5. 推进原则

1. 先补“看得见”，再补“更好看”。
2. 角色、装备、地点、事件必须有视觉锚点。
3. 小字和数字保留，但不要做第一视觉。
4. 宽屏 1280x720 基准下，界面不能只是居中小卡片加大片空背景。
5. 资产缺失要在 QA 阶段暴露，不要静默吞掉。
6. 《鬼谷八荒》只借鉴表达方式，不借修仙内容，不引入与 GDD 冲突的系统。

---

## 6. 任务包拆分

### P0-1 资产完整性 QA 门

目标：

- 所有 `data/*.yaml` 和 Dart 中引用的图片必须存在，至少 QA 命令能报清单。

建议实现：

- 增加只读检查脚本或 Flutter test，扫描 `assets/...png` 引用并验证文件存在。
- QA 构建中缺图不再完全静默，可在 debug overlay 或日志列出缺失路径。

验收：

- 运行检查能列出当前缺失的敌人图和装备图。
- 补图后缺失数归零。
- 不影响 release 正常容错。

### P0-2 战斗单位可见化

目标：

- 3v3 战斗第一眼能看出谁在打谁。

建议方向：

- 玩家侧战斗单位使用角色 `portraitPath` 或专用 battle sprite。
- 敌人侧不再只作为 80px 圆头像，至少有 140-220px 可辨识图。
- 战斗区域建立左右或上下站位：我方三人、敌方三人、技能轨迹、受击数字。
- 日志改为可折叠或弱化，默认不抢第一视觉。
- 胜负遮罩不能把战斗单位全部压暗到不可读。

验收截图：

- `battle_normal.png`：战斗进行中，六个单位可辨认。
- `battle_skill.png`：技能触发时能看到轨迹或命中特效。
- `battle_victory.png`：胜利时仍能看清战场和单位。

### P0-3 角色面板重排

目标：

- 玩家打开角色面板时，先看到“这是一个人”，再看详细数值。

建议方向：

- 顶部做角色身份区：大立绘、姓名、境界、流派、当前主修、当前状态。
- 中部做装备/心法/招式三块视觉区。
- 数值进入次级面板，可展开或分组。
- 缺立绘时使用明确的开发占位图，不要空黑框。

验收截图：

- `character_founder.png`：祖师页有完整立绘和身份层级。
- `character_disciple.png`：弟子页能看出人物差异。
- `character_missing_portrait_debug.png`：缺图时显示明确占位，而非空白。

### P0-4 装备详情与仓库重做

目标：

- 武器能完整显示，仓库像玩家背包/装备架，不像数据库列表。

建议方向：

- 装备详情大图用 `BoxFit.contain` 或专门构图容器，避免细长武器裁切。
- 列表 icon 与详情大图分离，不强迫同一素材适配所有场景。
- 仓库改为格子/装备架/部位分组：兵器、护具、饰物。
- 装备阶位用边框、底纹、印章或铭牌表达，不只靠文字。

验收截图：

- `equipment_weapon_detail.png`：剑、刀、鞭都完整可见。
- `inventory_grid.png`：宽屏下不再是长空行。
- `equipment_missing_debug.png`：缺图有清晰 QA 占位。

### P1-1 主线/爬塔/闭关地图化

目标：

- 列表入口之外，提供能表达旅程的空间视图。

建议方向：

- 主线：江湖路线图，章节是区域，关卡是节点。
- 爬塔：纵向塔身图，30 层可滚动，Boss 层有特殊视觉。
- 闭关：5 张地图做地点卡或山水区域图，显示产出和当前驻留。

验收截图：

- `mainline_route.png`
- `tower_map.png`
- `seclusion_map.png`

### P1-2 成长仪式画面

目标：

- 关键成长不是只弹数字，而是成为可记住的瞬间。

候选事件：

- 境界突破。
- 心法升层。
- 装备共鸣提升。
- 奇遇领悟。
- 离线挂机结算。
- Boss 首胜。

建议方向：

- 使用卷轴、木牌、剑匣、闭关石室、战报帖等武侠器物。
- 保留克制水墨风，不走高饱和修仙特效。

验收：

- 每个事件至少有一个专用视觉状态，不只是通用 dialog。

### P1-3 心法与流派可视化

目标：

- 刚猛、灵巧、阴柔和心法搭配不只靠说明文字理解。

建议方向：

- 做三系克制图，可借鉴“属性盘”的表达方式，但改成武侠语境：拳、剑、掌/身法、内劲等符号要符合 GDD。
- 心法相生组合做成关系线或插槽，不要只是长列表。
- 移除 debug 可见的 `skillUsage: N`，改为玩家可读的“实战熟练”或仅 QA 显示。

验收：

- 玩家不用读长说明也能看出三系关系。
- 心法列表能一眼区分主修、辅修、可练、锁定。

### P1-4 菜单与系统入口游戏化

目标：

- 主菜单不只是按钮面板，而是一个江湖门户。

建议方向：

- 每个入口配小图标/场景缩略/状态提示。
- 弱化纯文本按钮密度。
- 保持 1280x720 下完整可读，不拥挤。

验收：

- 主菜单截图中，玩家能快速分辨主线、爬塔、闭关、角色、装备、心法。

---

## 7. 不建议做的事

1. 不要把《鬼谷八荒》的截图、图标、立绘放进 `assets/`。
2. 不要把项目改成开放世界大地图玩法；Demo 当前还是挂机武侠。
3. 不要引入大量教程弹窗解释 UI。
4. 不要靠更小字体塞更多信息。
5. 不要把缺图继续用空白吞掉。
6. 不要为了“仙气”偏离写实武侠基调。

---

## 8. Claude Code 接手建议顺序

第一阶段：不改大结构，先让核心可见。

1. 资产缺失检查。
2. 战斗单位使用真实图像。
3. 装备详情图不裁切。
4. 角色面板空立绘兜底。

第二阶段：重排核心界面。

1. 战斗布局视觉重排。
2. 角色面板身份区。
3. 仓库格子化。
4. 心法三系关系可视化。

第三阶段：补世界感。

1. 主线路线图。
2. 爬塔塔身图。
3. 闭关地图图。
4. 成长仪式页。

---

## 9. 每轮 UI 工作的验收清单

每次提交前至少截图：

- `01_main_menu.png`
- `02_character_panel.png`
- `03_inventory.png`
- `04_equipment_detail.png`
- `05_technique_panel.png`
- `06_mainline_or_tower.png`
- `07_battle_running.png`
- `08_battle_result.png`

每张图检查：

- 是否有主要视觉对象。
- 是否有缺图、空框、首字占位。
- 是否有文字太小、对比太弱。
- 是否有大量无意义空白。
- 是否有图片被裁切到无法辨认。
- 是否有 debug 字段外露。
- 是否在 1280x720 逻辑基准下不溢出。

---

## 10. 成功标准

短期成功：

- 玩家不看说明，也能知道角色是谁、敌人是谁、拿的是什么、当前在打什么。
- 战斗截图能独立说明这是一款武侠游戏，而不是日志模拟器。
- 装备和角色图不再大量空白或裁切。

中期成功：

- 主线、爬塔、闭关有各自空间感。
- 成长事件有记忆点。
- UI 信息仍完整，但第一眼是世界、人物、器物，不是数字。

最终目标：

- 保持 wuxia_idle 的挂机节奏和写实武侠基调，同时让界面呈现达到“真正游戏”的最低可信度。

