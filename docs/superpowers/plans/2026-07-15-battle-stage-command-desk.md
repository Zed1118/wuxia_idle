# 战斗界面重构 · 水墨人物舞台与武学案台实施计划

> 设计真相源：`docs/spec/2026-07-15-battle-stage-command-desk-design.md`  
> 视觉基准：`docs/spec/battle_ui_stage_command_desk_v2_2026-07-15.png`  
> 分支：`codex/battle-ui-stage`  
> worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-ui-stage`

## 1. 目标与边界

将生产 `BattleScreen` 从“左右头像列 + 横向按钮栏”升级为已拍板的水墨人物舞台与武学案台，并保持现有两段点选、自动战斗、战斗结算和全部数值语义不变。

本计划不实现战斗药品消费规则，只预留 3 个战备行囊槽；不做药品自动补位、战斗中药品自动禁用提示、站位数值、3D/骨骼动画或逐技能序列帧。

## 2. 实施切片

1. **案台灰盒**：顶栏接管自动/速度/暂停；底部接入真实焦点角色、最多 7 个技能签和 3 个行囊预留槽；保持现有 key 与两段点选。
2. **人物舞台灰盒**：新增全身人物位和 1v1/2v2/3v3/Boss 斜向阵列；现有图经墨晕遮罩作临时降级，保留状态/目标/伤害反馈。
3. **动作模板**：接 `melee/projectile/area/control/cinematic` 表现类型，迁移攻击位移、弹道锚点、受击与回位；不改引擎 tick。
4. **透明立绘样板**：祖师、两弟子、三普通敌和一 Boss 共约 7 张；校验 alpha、脚底基线、镜像与性能。
5. **特殊战斗适配**：Boss、心魔、轻功、群战与自动/允许点选双形态。
6. **收口**：双视口视觉验收、targeted tests、`flutter analyze`、GDD 旧拖招口径同步与交付证据。
7. **特殊舞台收尾**：心魔镜像墨化、轻功上下错层、群战前三名完整立绘 + 余敌墨影队列，并修复 5–7 人群战动画槽越界。

每完成一个可独立运行的切片即提交并更新恢复点；切片 1–6 已提交，当前收口切片 7。

## 3. 切片 1 验收标准

- 生产 `BattleScreen` 使用新案台，不停留在孤立 demo。
- 1280×720 同屏可见：执招者、最多 7 个稳定技能槽、3 个行囊预留槽；无横向滚动与 overflow。
- 自动/速度/暂停/日志/撤退进入顶栏；底部右侧不再混入快进键。
- 单体两段点选、唯一目标直放、群体直放、长按简介、ESC/空白取消全部保持。
- 现有 `skill_cmd_<characterId>_<skillId>`、`focus_chip_<slot>` 等测试 key 尽量保持，避免无价值破坏。
- 桌面语义：技能/队员/顶栏控制保留 focus、键盘激活、tooltip/semantics 与鼠标指针能力；不得用裸 `GestureDetector` 丢掉已有可访问性。
- 行囊只显示空态/占位态，不读背包、不消费物品、不自动补位。
- 中文文案只进 `UiStrings`；布局尺寸集中在战斗 presentation token/config，不散写到多个 Widget。
- 1280×720、1440×900 visual smoke；概念图是构图基准，不要求像素复刻。

## 4. §8.2 交付清单

- [x] **生产接线证据**：`BattleScreen` 生产树将播放控制传入 `Header`，将真实 `BattleState`/技能回调传入 `BottomBar`；行囊仅为 presentation 空槽，无数据消费方。
- [x] **targeted tests**：4 个战斗/widget 文件共 56 项通过，含 7 槽、3 行囊槽、顶栏快进、两段点选、ESC/空白取消、单敌直放、群体直放与 1280×720 / 1440×900 密度回归。
- [x] **红线影响**：零数值、零 schema/saveVersion、零三系门槛、零在线/离线规则；行囊不实现消费；中文进 `UiStrings`，新布局数值进 `BattleLayoutTokens`。
- [x] **桌面语义**：技能签改为原生 `ElevatedButton` 承接点击/长按，保留 semantics、focus、键盘激活与 mouse cursor；顶栏继续使用 `IconButton`。
- [x] **视觉证据**：`battle_tap_preview` 已截 1280×720（实图 2560×1440）与 1440×900（实图 2880×1800），路径 `build/visual_acceptance/battle_ui_stage_slice1/`；二次截取无 overflow/exception/error 日志。
- [x] **残留风险**：透明立绘、人物舞台、动作模板、特殊战斗均明确留在后续切片，本次只交付案台灰盒。
- [x] **清洁度**：无 debugPrint 高频噪声、无误提交 `.g.dart`/临时 capture/log；中文动宾提交信息。

## 5. 当前恢复点

- **状态**：切片 1 `4599d73d`、切片 2 `917e143d`、切片 3 `1a8a2598`、祖师样板 `63eb0822`、两弟子样板 `750dfcf6`、敌方立绘与 Boss 体量 `17eadf85`、全人物别名与点按口径 `ac12adc9`、特殊战斗人物舞台 `d6c29b4c` 均已提交；切片 1–7 完成。
- **最后完成**：七张透明战斗立绘已齐备：祖师、两弟子、山匪、黑衣杀手、撑伞高手和塔主 Boss。旧头像路径仅在战场展示层映射为透明全身图，其他角色页面不受影响；Boss 在同一阵列深度上额外放大 `1.12×`，不改变碰撞、目标或数值语义。蓄力/破招圆环、目标高亮、死亡灰显继续复用现有状态层。心魔敌方人物增加反相墨色与阴柔晕光；轻功阵列扩大上下错层和交锋位移；群战只渲染前三名完整人物，额外 2–4 人显示远阵墨影，溢出角色动作与受击归并到安全表现槽，消除 3v5/6/7 索引越界。
- **下一步**：交付用户目检；不主动 push/开 PR，避免 main 尚未 push 时扩大并行集成面。
- **已跑验证**：切片 7 完成后，战斗 presentation、播放控制器、群战策略与视觉路由合计 245 项通过；定向 `flutter analyze` 无问题，`dart format --set-exit-if-changed` 与 `git diff --check` 通过。七张战斗立绘均为有效 RGBA、alpha 范围 `0–255` 且四角透明。Boss 实战帧位于 `build/visual_acceptance/battle_ui_stage_slice5_boss_initial/`，蓄力/破招帧位于 `build/visual_acceptance/battle_ui_stage_slice5_states/`，最终双视口帧位于 `build/visual_acceptance/battle_ui_stage_slice6_final_alias_fixed/`，心魔/轻功帧位于 `build/visual_acceptance/battle_ui_stage_special_modes/`，最终群战帧位于 `build/visual_acceptance/battle_ui_stage_special_modes_final/`；日志均无 overflow/exception/error。macOS 截图外围黑边为窗口缩放捕获伪影，不计入游戏画布。

## 视觉纠偏恢复点（2026-07-15）

- 用户以 V2 概念稿复核后明确指出实机与效果图差距过大；原“完成视觉验收”仅代表功能/溢出验收，不再视为视觉质量达标。
- 已完成纠偏 V1：标准 3v3 改为概念稿式非对称纵深，人物最大高度提升并移除卡片式立绘框，状态板缩为贴身墨底；顶栏改为居中题字；武学案台改为木案底、竖向宣纸招式签、纸化空槽与收束式行囊框。
- 1280×720 最大密度场景曾因 Boss 前景倍率使角色高度超过可用战场，现于 `BattleField` 在站位倍率之后按实际约束等比回落；对应 Boss 低血与最大密度 HUD 复现测试已通过。
- 纠偏截图：`build/visual_acceptance/battle_ui_concept_realign_final/`（最终点选预览）与 `build/visual_acceptance/battle_ui_concept_realign_v2/`（动态战斗帧）。后续仍需用户对纠偏方向做视觉确认，再继续处理敌方重复立绘、场景题签与案台细节，不得再次把“测试绿”表述成“视觉已定稿”。
- **阻塞项**：无。集成风险为 Claude 并行分支可能同时改 `lib/shared/strings.dart` / `GDD.md`；本分支仅追加战斗案台必要文案，并在 GDD §5.7/§5.8 修正点按口径，交付时明确冲突点。

## 效果图拉齐恢复点（2026-07-15）

- 重做祖师、隐世老者、山贼刀客与山贼弓手 4 张写实水墨 RGBA 透明全身立绘，标准 3v3 不再出现敌方重复模型；旧角色资产路径只在战场展示层映射，不影响角色面板。
- 标准战场改用中央留白的山林长卷构图，实图场景下将原三条椭圆雾带降至极弱模糊层，去除调试站位带观感；无场景图时仍保留完整水墨兜底。
- 人物状态牌收窄并改为绛红气血 / 青灰真气，数值改用紧凑排版，消除文字裁切。顶栏场景题签代替验收说明长文。
- 满配验收场景展示 7 张真实可点技能签，两段点选机制不变；战备行囊的葫芦与药囊预留图标提亮，仍不读背包、不消耗道具。
- 最终对照帧：`build/visual_acceptance/battle_ui_match_final/battle_tap_live/1440x900/` 与 `1280x720/`；两视口无 overflow，结构已与 V2 概念稿统一为“上方全人物水墨舞台 + 下方竖签武学案台 + 右侧战备行囊”。

## 站位与落地融合恢复点（2026-07-15）

- 根因修正：战场注释与编成规则均定义 `slot 0` 为靠近中场的首席，但概念稿纠偏曾将我方 `slot 0` 写成最外侧且为敌方单独写了一组非镜像坐标。现改为首席居中前排，1v1 / 2v2 / 3v3 左右同序槽位严格镜像。
- 系统调整能力已存在：`TeamLineupScreen` 以 `activeCharacterIds` 列表顺序作为站位顺序，点出战角色可与其他席位交换；祖师必须出战，但不强制永远占首席。
- 立绘落地不再依赖 Widget 容器底边：根据每张 RGBA 立绘的 alpha 有效边界标定真实脚底，将接触墨影和状态牌贴到真实脚底。其中山贼刀客原图有约 18% 透明底边，不再导致信息牌大幅下坠。
- 新增无人物、无 UI 的专用山口战场背景 `assets/scenes/battle_mountain_pass_stage_v2.png`，中央与两侧六个站位共享连续石滩地面和同一透视；1440 对照帧位于 `build/visual_acceptance/battle_ui_ground_plane_v3/`，1280 无异常复验帧位于 `build/visual_acceptance/battle_ui_ground_plane_final/`。

## 特殊状态融合恢复点（2026-07-16）

- 破绽窗口原先对整个 `CharacterSlot` 施加绛红 `boxShadow`，会直接显露矩形 Widget 边界，与透明全身立绘冲突。现改为脚下窄幅破绽印，保留呼吸节拍和既有测试 key，不改战斗机制。
- `battle_charge_break` 1440×900 复截位于 `build/visual_acceptance/battle_ui_stagger_ground_seal/`；旧帧右侧杀手背后大面积红色矩形已消失，无 overflow / exception / error。
- Boss、蓄势/破招、点选冻结与 Boss 阶段验收路由统一使用山口舞台，不再在特殊状态中退回旧纸墙/城墙背景。`scenarioBoss` 冻结帧的六人也改用透明全身立绘，去除四张带底纸的历史头像。
- 后排立绘缩小后的状态牌独立放宽，1280 视口下四位/五位气血值不再挤成一团。统一后 Boss 帧位于 `build/visual_acceptance/battle_ui_boss_standee_unified/`。

## 战斗邻接编成页恢复点（2026-07-16）

- 将原本横向三张深灰信息卡改为山口地图上的阵列预览：第三席 → 第二席 → 第一席朝交锋方向递进，首席放大并保留前排印，与战场 `slot 0/1/2` 语义对齐。
- 交互仍是点击卡片后在纸弹窗选换席，未引入拖放；三卡刻意不重叠，并增加 widget 几何断言保护整卡点选面。
- 出战/替补卡改用宣纸底与水墨占位字，无立绘角色不再显示空黑框。两视口帧位于 `build/visual_acceptance/team_lineup_formation_stage/`，最终 1280 帧位于 `build/visual_acceptance/team_lineup_formation_final/`。

## 战场状态牌数值收口（2026-07-16）

- 全人物舞台的紧凑气血/真气条对五位数以上使用 `K` 缩写（例如 `12K/12K`、`40K/40K`），解决边缘后排状态牌的数字挤压；角色详情等未开 `compactLabel` 的界面仍保留完整数值。
- 最终 1280 帧位于 `build/visual_acceptance/battle_ui_compact_status/`，六人的状态值均可快速读取。

## 实战动效与命中轮廓收口（2026-07-16）

- 通过 macOS 真实窗口连续抓取 60 帧验证动作模板：近战人物前压到交锋线后回位，远程人物留在原位并走水墨弹道，不改战斗 tick 与技能释放口径。
- 命中特效与「斩/震/断」题字降低饱和度、尺寸与不透明度，从高亮手游贴纸收为墨痕/印记，保留流派可读性。
- 修复受击闪用矩形 `ColoredBox` 铺满整个人物槽位的问题，改为 `srcATop` 只染亮目标非透明轮廓，命中瞬间不再暴露 Widget 矩形边界。
- 修复后逐帧证据位于 `build/visual_acceptance/battle_ui_live_vfx_silhouette/`；定向题字、破绽、受击闪与重绘边界测试均通过。

## 关卡行程界面统一（2026-07-16）

- 章内关卡页从冷灰 Material 容器改为暖墨桌面：章节卷景作全屏低明度底图，上层路线长卷、周目条与关卡站点改用暖褐墨底/旧金边，与战场案台同色系。
- 章标题改为居中题字并增加细金分隔线，关卡路线、周目选择、掉落传闻、情报入口与原进战流程全部保留。
- 1280×720 实机帧位于 `build/visual_acceptance/stage_list_warm_route/`；关卡列表、周目、掉落情报合计 24 项定向测试通过。

## 章节路引界面统一（2026-07-16）

- 章节页与关卡页共用同一套居中旧金题字、墨黑顶栏和细金分隔线，移除顶部尺寸过小、像占位符的卷轴图。
- 以第一章水墨卷景作为低明度全屏底纹，保留江湖路引宣纸和六章卡的原交互/锁定状态，使「章节 → 关卡 → 编成 → 战斗」的视觉底色连续。
- 1280×720 实机帧位于 `build/visual_acceptance/chapter_list_warm_route/`；六章解锁状态 3 项定向测试通过。

## 战后胜负仪式收口（2026-07-16）

- 生产胜利闪印与胜负结算大字从 96px 高饱和奖励黄收为 76px 旧纸金，败北从高饱和流派红收为深绛印泥；印符和投影同步缩小。
- 首通视觉验收路由 `_VictorySealMark` 同步生产参数，不再用比真实界面更夸张的孤立黄字。胜利卷宗、掉落、境界精进与继续流程未改。
- 收口后 1280×720 帧位于 `build/visual_acceptance/battle_victory_ceremony_refined/frame3.png`；胜负、诊断、仪式与视觉路由定向测试通过。
- 败北诊断在 720p 下无溢出；重试弹框验收路由改用山口战场底图并套入生产的灰/绛红按钮色，避免黑底黄字造成错误视觉判断。复核帧位于 `build/visual_acceptance/stage_retry_dialog_refined/`。

## 角色面板全人物档案（2026-07-16）

- 角色档案头的 102×102 证件照框改为 126×174 竖向人物签，祖师/两名弟子直接复用已完成的透明全身战斗立绘；其他角色仍走原头像/占位降级路径。
- 人物签增加真实脚底接触影、上浅下深宣纸底和克制的流派边线，保留师承身份条与朱印；不改属性、装备、心法和角色切换交互。
- 1280×720 实机帧位于 `build/visual_acceptance/character_panel_full_standee/`；角色面板主流与边界共 36 项定向测试通过。

## 心法面板标题栏统一（2026-07-16）

- 心法面板从默认冷灰 `AppBar` 改用与角色面板一致的宣纸 `WuxiaTitleBar`，保留返回/主页与莲花题签，并使养成页与角色档案在同一导航层级上。
- 主修、辅修、领悟点、三系相克和研习流程未改；1280×720 实机帧位于 `build/visual_acceptance/technique_panel_titlebar_unified/`，18 项定向测试通过。

## 问鼎九霄标题栏统一（2026-07-16）

- 问鼎九霄从默认冷灰 `AppBar` 改为宣纸 `WuxiaTitleBar`，与角色/心法页的导航层一致；塔势长卷、楼层轴、节点、周目与挑战流程不变。
- 1280×720 实机帧位于 `build/visual_acceptance/tower_titlebar_unified/`；9 项楼层状态/挑战/扫荡定向测试通过。

## 闭关地图标题栏统一（2026-07-16）

- 闭关修炼地图页改用宣纸 `WuxiaTitleBar`，帮助入口和打坐题签收入统一右侧操作区；原五张水墨地图卡、进行中状态、境界门槛与产出信息不变。
- 1280×720 实机帧位于 `build/visual_acceptance/seclusion_titlebar_unified/`；9 项地图状态与双视口定向测试通过。

## 最终验收恢复点（2026-07-16）

- 标准战斗最终双视口帧已固化：`build/visual_acceptance/final_acceptance/battle_tap_live/1280x720/frame.png` 与 `1440x900/frame.png`。站位按首席靠近交锋线、双方同序严格镜像；人物脚底依据透明图 alpha 边界锚定，并由接触墨影接入连续石滩地面。
- 技能仍为点击释放：单体技先点技能签再点目标，群体技点击后立即释放；长按只看详情，没有拖放。战备行囊只保留可见预留位，不接入背包消费。
- 全量 `flutter test` 共 4048 项通过；纸面文字对比审计零发现；`flutter analyze` 零问题；`flutter build macos --debug` 成功生成 `wuxia_idle.app`；Dart format 与 `git diff --check` 通过。
- 共享文件仅在 `lib/shared/strings.dart` 追加 6 条战斗案台文案，并在 `GDD.md` 把既已拍板的拖放口径改为点按；未改数值 YAML、schema/saveVersion 或战斗结算。未 push、未开 PR、未合入 main，继续保留在 `codex/battle-ui-stage` 独立 worktree 等待人工目检。

## 江湖见闻录视觉收口（2026-07-16）

- 见闻录从默认深灰 `AppBar` 改为宣纸 `WuxiaTitleBar`，五个分页改为独立暖纸签栏；正常入口仍从「见闻」开始，直达验收可指定奇缘/武学首屏。
- 奇缘与武学验收路由现在渲染完整生产外壳，不再只截孤立 tab；奇缘样例不再把内部英文 id 当标题。武学点亮/未解锁条目改为有边界的卷册卡，增加书卷、锁和行进提示，解决列表像未排版文本的问题。
- 1280×720 复核帧位于 `build/visual_acceptance/baike_titlebar_unified/` 与 `build/visual_acceptance/baike_cards_refined/`；百科 presentation 26 项、视觉路由 30 项及武学页 6 项定向测试通过，`flutter analyze` 零问题。

## 正式敌人立绘覆盖恢复点（2026-07-16）

- **状态**：持续推进，尚未完成。正式 `stages.yaml` / `towers.yaml` 共 79 种敌人、120 次出场，目前 42 种 / 83 次已接入透明全身战斗立绘。
- **最后完成**：除塔 6/7/12 层及主线 4-1/4-2/4-3 外，继续覆盖 `stage_04_04` 至 `stage_06_05` 的 12 名连续主线敌人；按武林名宿、掌门、甲胄守将、持剑先锋、门人、杖客与老者轮廓分组，先消除纸底头像。第四至六章的 15 个正式关卡现均有独立冻结路由与原关卡背景。
- **下一步**：在桌面 2 集中执行第四至六章双视口目检，重点检查连续关卡是否出现过度复用；随后处理轻功/群战专用敌人和过渡 Boss 专属重做。
- **已跑验证**：`character_avatar_test.dart` 14 项通过；视觉路由与真实数据接线 38 项通过；正式数据覆盖脚本确认 42/79、83/120；新增第四至六章 12 个冻结路由后相关路由测试 38 项再次通过；`flutter analyze --no-pub` 零问题；`git diff --check` 通过。
- **阻塞项**：当前图像生成服务曾返回 403，无法稳定产出新专属位图；可继续做保守复用覆盖与真实关卡验收，但专属画像重做仍依赖图像生成恢复。
