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

每完成一个可独立运行的切片即提交并更新恢复点；切片 1–6 均已完成，当前进入交付收口。

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

- **状态**：切片 1 `4599d73d`、切片 2 `917e143d`、切片 3 `1a8a2598`、祖师样板 `63eb0822`、两弟子样板 `750dfcf6`、敌方立绘与 Boss 体量 `17eadf85` 均已提交；切片 1–6 已完成，敌方旧资源别名与 GDD 点按口径待最终恢复提交。
- **最后完成**：七张透明战斗立绘已齐备：祖师、两弟子、山匪、黑衣杀手、撑伞高手和塔主 Boss。旧头像路径仅在战场展示层映射为透明全身图，其他角色页面不受影响；Boss 在同一阵列深度上额外放大 `1.12×`，不改变碰撞、目标或数值语义。蓄力/破招圆环、目标高亮、死亡灰显继续复用现有状态层。心魔、轻功、群战确认共用同一 `BattleScreen`，仅替换策略和背景；群战维持纯自动，心魔/轻功维持点按干预。
- **下一步**：提交最终恢复点并交付用户目检；不主动 push/开 PR，避免 main 尚未 push 时扩大并行集成面。
- **已跑验证**：战斗 presentation 全套与 controller 共 198 项通过；心魔/轻功/群战链路 116 项通过；定向 `flutter analyze` 无问题，`dart format --set-exit-if-changed` 与 `git diff --check` 通过。七张战斗立绘均为有效 RGBA、alpha 范围 `0–255` 且四角透明。Boss 实战帧位于 `build/visual_acceptance/battle_ui_stage_slice5_boss_initial/`，蓄力/破招帧位于 `build/visual_acceptance/battle_ui_stage_slice5_states/`，最终双视口帧位于 `build/visual_acceptance/battle_ui_stage_slice6_final_alias_fixed/`；日志均无 overflow/exception/error。macOS 截图外围黑边为窗口缩放捕获伪影，不计入游戏画布。
- **阻塞项**：无。集成风险为 Claude 并行分支可能同时改 `lib/shared/strings.dart` / `GDD.md`；本分支仅追加战斗案台必要文案，并在 GDD §5.7/§5.8 修正点按口径，交付时明确冲突点。
