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
