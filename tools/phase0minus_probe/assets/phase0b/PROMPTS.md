# Phase 0B Imagegen 提示词账本

生成方式：Codex 内置 `imagegen`。所有图片均为新生成概念样片，现有角色和场景图片只作为身份、材质和画风参考。完整原始输出保留在当前 Codex task 的 generated-images 目录；本目录保存项目内选定版本。

## 清场关键帧

以祖师、山贼刀客、弓手、隐世老者与山道场景为参考；要求 16:9 横版实时战斗构图、单主角、约 20 名普通人类敌人和 1 名精英。祖师位于中左，聚怪后的清场墨环击退 8–12 人，精英在右侧抵抗。纸黄、墨灰、青袍和克制朱砂；只有一个主墨环，无 UI、文字、霓虹、魔法阵或全屏光效。

## 聚怪关键帧

沿用清场帧镜头与身份；约 12 名敌人沿贴地曲线向祖师内收，另外约 8 名留在外围，精英只轻微位移。强调空间控制而非伤害，无爆炸、死亡和高抛；中心不得用浓烟遮住主角与脚下。

## 破招关键帧

沿用同一场景；精英在右侧进行 1.2 秒重击蓄力，主角在中左做短促掌击破招。主角—精英之间保留干净走廊；朱砂仅用于精英危险方向，普通敌人分三层围绕且同时只有三人显示进攻意图。

## 主角六动作表

同一祖师身份，二行三列：战斗待机、移动普攻、低位身法、聚怪、清场、精准破招。锁定面容、发髻、长须、青色外袍、灰白内袍和徒手掌法。每个姿势露出脚、关节、衣袖、衣摆与头发方向，服务骨骼拆分；无敌人、武器、文字、光效。

## 普通刀客六动作表

同一山贼刀客，二行三列：待机、接近跑动、攻击预警、横斩、被聚怪拉动、被清场击退。短衣、单腰带尾、单刀，作为低成本量产骨架；无精英装饰、魔法和文字。

## 精英四动作表

同一隐世老者精英，一行四列：接近、1.2 秒蓄力、破招踉跄、重击释放。1.25 倍普通敌人体量、深墨长袍、实用长刀；只有蓄力姿势允许一小笔朱砂，无巨型光环或奇幻盔甲。

## 主角透明姿态图集源图

以现有祖师立绘与六动作表为身份参考，生成严格二行三列、六格等尺寸的单人动作图集：待机、移动普攻、低位身法、聚怪、清场、破招。锁定白发长须、青绿长袍和徒手掌法；每格只有一个完整角色，不越界、不接触边缘，无阴影、地面、敌人、文字或特效。背景必须是纯平坦 `#ff00ff` 高纯品红，角色不得含品红反光，用于色键去背。

## 山贼透明姿态图集源图

以现有山贼刀客与六动作表为身份参考，生成严格二行三列、六格等尺寸的单人动作图集：待机、接近跑动、攻击预警、横斩、被聚怪拉动、被清场击退。锁定同一中年男性、黑发发髻、破旧灰褐短衣和单刀；每格只有一个完整角色，不越界、不接触边缘，无阴影、地面、文字、飘散碎片或特效。背景必须是纯平坦 `#ff00ff` 高纯品红，角色不得含品红反光，用于色键去背。

两张源图均通过 `remove_chroma_key.py --auto-key border --soft-matte --despill` 转为 RGBA PNG。项目内仅保留去背结果；原始品红图保留在当前 Codex task 的 generated-images 目录和本地 `tmp/imagegen/`。

## 精英透明姿态图集源图

以现有隐世老者立绘和精英四动作表为身份参考，生成严格二行二列、四格等尺寸的单人动作图集：接近/环绕、1.2 秒重击蓄力、破招后踉跄、重刀向下释放。锁定同一老年男性、白发发髻与长须、深墨长袍和一把实用长刀；体量约为普通山贼 1.25 倍，保持写实人类，不做超自然变形。每格只有一个完整角色，脚、刀尖、衣袖和胡须均不越界；无阴影、地面、文字、粒子、光环、血迹或额外人物。背景为纯平坦 `#ff00ff` 高纯品红，危险朱砂由引擎单独渲染。

精英源图同样通过 `remove_chroma_key.py --auto-key border --soft-matte --despill` 转为 RGBA PNG。

## 主角自动拆件关节木偶源图（失败路线证据）

以祖师立绘与透明姿态图集为参考，生成严格四行四列的 16 部件切片：头、须、发、躯干、左右袖/手、左右袍片、双腿与前后衣摆；纯 `#ff00ff` 背景，用于 Flame 原生父子层级、旋转和位移验证。源图经色键去背后接入 `idle → basic → dash` 三秒循环。

结果不通过正式美术线：自动切片只给出可见表面，没有关节背后的隐藏延伸区与盖片，运动时出现断袖、断手和袍片开缝。本资产只保留为“技术可运行、自动拆件不可用”的负证据，不进入生产。

## 纯山道背景底板 V2

编辑现有山道样片：删除所有人物、腾空武者、武器和人物状阴影；保持写实克制的水墨山谷、树木、远山和中央道路透视。中央与下半部必须是宽阔、空白、可落脚的横版战斗地面，加入轻微横向纵深层次；远景低对比，不与前景角色争夺轮廓。无角色、动物、文字、UI 和高饱和色。输出裁切为 1280×720 的干净背景底板。

## 连续地图三段背景 V1

三张均以纯山道 V2 为画风、镜头高度、道路尺度和宣纸色参考，生成 16:9 空场景；下方约 42% 保留浅纵深可战地面，左右边缘保持低细节雾路。共同禁止人物、剪影、武器、动物、文字、UI、边框、魔法与高饱和色。

- 山口引入：左侧风化界碑与折松作为地标，中央道路保持开放；
- 林道交战：道路两侧竹松与废弃木轮作为地标，不遮挡战斗带；
- 关隘高潮：后景残破木石关门与一小面暗朱残旗，前景留出 20+1 空间。

三张由内置 imagegen 分别生成后，实机发现跨图地平线和明度仍留下拼接痕迹，因此未进入项目资产，只作为被否决尝试保留在临时目录。

## 单张连续超宽山道长卷 V1

改为一次生成一张不中断的超宽全景母图，明确禁止三联画、面板、边框、镜像重复和多个中心消失点。同一条道路从左至右自然经过界碑折松、竹林木轮，最后抵达残破关隘；统一地平线、光照、纸纹、镜头高度和地面透视。原始母图约 2.5:1，从中部等比裁出连续战斗带，再等比放大为 3600×720；没有横向拉伸，也没有跨图拼缝。

最终生成提示词（内置 imagegen）：

> Use case: stylized-concept. Asset type: ONE SINGLE continuous ultra-wide panoramic side-scrolling wuxia game map master plate, exact composition ratio 5:1, intended runtime size 3600x720. This must be one uninterrupted landscape, not a triptych, not panels, no seams, no borders, no repeated mirrored sections. From left to right, the same road naturally progresses through: (1) an open mountain-pass entrance with a weathered boundary stele and bent pine; (2) a wooded/bamboo mountain road with a discarded cart wheel near the edge; (3) an approach to a ruined timber-and-stone checkpoint with one tiny muted dark-red torn banner. Preserve one continuous horizon, one continuous ground plane, consistent camera height, perspective, lighting, paper texture and restrained realistic Chinese ink-wash brushwork across the entire panorama. The lower 42% is a broad continuous shallow-depth playable road for human sprites about 160px tall. Keep landmarks at the sides or rear and the central combat band open. Far mountains are soft and desaturated. No characters, silhouettes, people-shaped shadows, weapons, animals, text, UI, frames, borders, panel dividers, duplicated central vanishing points, magic effects, or bright colors. Produce a clean seamless continuous panoramic background plate with generous detail across the full width.
