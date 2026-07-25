# 全局内容与视觉质量收口计划

**日期**：2026-07-25  
**分支**：`codex/global-visual-polish`  
**worktree**：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/global-visual-polish`  
**依据**：`docs/audit/global_content_visual_audit_2026-07-25.md`  
**模式**：独立 worktree、可恢复长任务、小切片提交；不触碰 Claude Code 当前 worktree。

## 目标

按全局审查报告推进既有界面的视觉收口：先清 4 个 P1，再建立字体/浅深表面 token，随后依次处理战斗、高频页面、长尾页面、内容术语和全局视觉门禁。目标综合质量由 7.2 提升至约 8.5，不增加玩法、不改数值经济。

## 边界与红线

- 不实现 `docs/spec/rejected_task_registry.md` 中已否或暂缓功能。
- 不改 GDD 数值红线、三系锁死、在线=离线和反主流清单。
- Dart 新增玩家可见文案必须进入 `UiStrings`；数值继续来自 data 配置。
- 不在 `main` 或 Claude Code 的 worktree 写文件、切分支、提交或合并。
- 截图与 capture 产物只留在 `/tmp` 或 gitignored 目录，不提交。
- 视觉方向保持“写实、沉郁、水墨、宣纸、绛红点缀”，不做通用 Material 美化。
- 已经确认的页面结构、信息顺序与交互路径不重做；仅修失效布局、可读性、反馈和资产误用。结构候选项只记录，不擅自落地。

## 总体验收标准

1. **生产接线**：所有修复接入真实 production path；视觉 route 只作为验收入口。
2. **targeted tests**：每个切片至少运行直接相关 widget/unit tests，并记录通过数。
3. **红线说明**：每个切片确认是否触及数值、三系、在线离线、文案硬编码；默认应为不触及。
4. **残留风险**：每个恢复点记录未测视口、未目检状态、性能与跨平台风险。
5. **桌面视觉**：UI 切片必须覆盖 1280×720、1440×900；交互组件需检查 semantics、键盘 focus、hover/mouse cursor。
6. **批末门禁**：`flutter analyze` 0 issue、相关 targeted tests、阶段末一次全量 `flutter test --no-pub`。
7. **就绪信号**：所有改动提交、worktree 干净，分支 tip 以 `[READY]` 开头后才交 Claude 审核。

## 任务切片

### Slice 0：隔离与基线

- 建立独立 worktree/分支。
- 搬入全局审查报告。
- 运行依赖安装与 baseline analyze。
- 盘点现有视觉 route、测试入口和 P1 生产调用链。

### Slice 1：P1-A 章节 16 项路引

- 以条目数和最小卡宽决定横向滚动，不再用固定 1040 阈值。
- 覆盖 16 章、长章节名、当前章可见和桌面横向操作。
- targeted widget tests + 1280/1440 route。

### Slice 2：P1-B 设置面板浅底 Theme

- 为 `PaperDialog` 建立完整浅色组件 Theme。
- 修复 ListTile、Switch、Slider、Dropdown、disabled 状态对比。
- 优化 720p 内容高度与操作区关系。
- 增加设置面板生产视觉 route 与颜色测试。

### Slice 3：P1-C 视觉验收覆盖

- 新增 splash、save select、clean main menu、settings 顶/底/disabled route。
- route metadata 区分 production shell、component、gallery、transient overlay。
- 将高风险隐藏页加入 smoke。

### Slice 4：P1-D 战斗资产角色

- 盘点正式战斗 route 的 portrait→standee fallback。
- 建立资产角色门禁，先清方图/半身/同脸敌我等高曝光问题。
- 修复状态牌文字对比、脚底与尺度明显异常。

### Slice 5：视觉基础设施

- 语义 typography tokens。
- `PaperSurfaceTheme` / `DarkSurfaceTheme`。
- 标题栏、SectionHeader、状态 pill、浅/深卡、空状态统一。
- 按高频使用迁移，不做全仓机械替换。

### Slice 6：高频页面

- 启动/存档/主菜单。
- 角色/编成。
- 章节/关卡/塔。
- 仓库/装备/商店。
- 闭关/桃花岛。

### Slice 7：长尾系统

- 门派、门派谱、见闻录、技能库、兵器谱、战绩册。
- 资源总览、江湖远行、断魂庄、藏卷阁。
- 归来、奖励、失败、确认等弹层。

### Slice 8：内容与全局验收

- UI 术语表、中英混排、单位与重复说明收口。
- 叙事/lore/event 分层编辑。
- 116+ 路由双视口、关键页 1920、Windows 发布前缩放清单。
- 阶段全量测试、报告、冻结并打 `[READY]`。

## 当前恢复点

- **状态**：Slice 7 长尾系统已完成；下一阶段进入全局内容、术语、资源与无障碍检查。
- **最后完成**：
  - Slice 1 章节路引已提交：`c5e9afc7`；
  - 新增 `paperSurfaceTheme`，统一浅宣纸上的 ColorScheme、TextTheme、ListTile、Switch、Slider、Dropdown、Menu、输入框、禁用态与交互态；
  - `PaperDialog` 保持原 420 宽、标题/正文/动作结构，只将原局部输入框 Theme 替换为完整浅纸 Theme；
  - 设置面板保持原 360 宽单栏、原分区顺序和原操作路径；撤销未提交的双栏尝试；
  - 设置正文最大高度由全屏 80% 收至 68%，只让原滚动区提前滚动，为 720p 标题与固定动作区留足空间；
  - 段标题从浅纸低对比亮金改为既有绛红 token，一处切档确认文案改用既有墨色 token；
  - 新增 `settings_panel` 生产调用视觉 route，并纳入 smoke；READY 只在真实 `SettingsPanel.show` 弹窗完全打开后发出；
  - 1280×720、1440×900 真窗口截图均确认原布局、控件对比、固定关闭按钮与无溢出。
  - 新增真实 `SplashScreen` 加载态 route；
  - 新增 `SaveSelectScreen` 三空槽与“最近存档 + 两空槽”两条确定性 route；
  - 新增 `main_menu_clean`，并让原 `main_menu` 同样先清理视觉库中的 active retreat、刷新在线基准，避免本机存档自动弹出归来卡；
  - 启动/存档/纯净主菜单 4 route × 2 视口共 8 张真窗口截图均 READY、无异常；
  - Slice 3A 已提交：`feb58d14`；
  - 新增 `settings_panel_bottom` 与 `settings_panel_disabled`，分别稳定停在真实设置单栏底部和“全屏开启→分辨率禁用”状态；
  - 设置面板仅增加可选验收滚动控制器/显示段锚点，生产调用默认值、360 宽度、分区顺序与交互路径均不变；
  - route metadata 已区分 `productionShell`、`component`、`gallery`、`transientOverlay`，checklist 显式输出类型；
  - 两条隐藏状态 route 已加入 smoke，1280×720、1440×900 真窗口均确认关闭动作固定、禁用态清楚、无溢出。
  - 生产主线、塔、远征、断魂庄共盘出 145 个唯一敌人 source，全部已登记为透明 `stageStandee`，正式战斗 portrait fallback 为 0；
  - 新增 `sourcePortrait / stageStandee / identitySilhouette` 三类显式资产角色与 source→display 解析门禁，未登记肖像不再进入战场；
  - 3 名招募候选与 6 名门派候选尚无专用站姿，当前统一使用“既有透明站姿 alpha 外形 + 纯墨覆盖 + 姓名首字小印”的身份墨影；不显示原人物纹理，不改变战位与阵列；
  - 新增真实数据资产门禁：覆盖全部生产敌人、全部可出战玩家肖像，并逐图检查透明角、四边裁切、最小尺寸、有效人物比例与脚底标定；
  - 门禁发现 `battle_bandit_blade.png` 刀尖贴左缘，已对称补 12px 透明安全边距，人物造型和战斗站位不变；
  - 战场状态牌仍沿用原深墨纸、原尺寸和原锚点，仅把角色名改为宣纸亮字并收窄描影，解决浅雾/暗牌上的低对比；
  - 中性调试 3v3 的首名敌人由与祖师近似的白须老者换成已登记独立敌人，只修验收样例的同脸干扰，不改生产数值或关卡；
  - 新增 `battle_identity_silhouette` 确定性组件 route，并加入 battle suite；battle suite 现为 70 条动态真关卡/塔路由 + 6 条确定性素材/状态路由。
  - 新增 `WuxiaTypography` 语义字阶，等值收拢共享组件已经使用的 19/18/17/15/14/13/12/11 尺寸、既有字重与字距；战斗 HUD 继续独立使用 `BattleTypography`；
  - `WuxiaTitleBar`、`PaperDialog`、`SectionHeader`、`InkEmptyState`、`WuxiaStatusPill` 已改为消费语义字阶，所有尺寸、间距和信息结构保持不变；
  - 新增 `darkSurfaceTheme`，与 `paperSurfaceTheme` 对称覆盖 ListTile、Switch、Checkbox、Radio、Slider、输入框、Dropdown/Menu、Tooltip、禁用/hover/focus/选中态；
  - 46 个 `LightPaperPanel` 与 18 个 `DarkParchmentPanel` 现在自动向内部 Material 组件提供正确浅/深 Theme，同时继续提供原 `PanelSurface.light/dark` 文字语义；
  - 主题门禁新增 onSurface 对比度、组件交互态和面板 Theme 接线测试；`inventory` 与 `technique_panel_tier_all` 双视口前后比对确认布局/密度无漂移。
  - 启动页保持原背景、标题位置、底部状态结构，仅把加载/继续文字改为深景可读的白字、字重和墨影，并为题字补墨影；字号与几何不变；
  - 存档页三张 380 宽单列卡片、操作顺序和点击路径完全不变；修复空槽未收到深色 `PanelSurface`、青灰标题/图标落到深底后几乎像禁用态的问题；
  - 新增 `qingOnDark` 同色相深底 token，深色空状态的标题、图标与副描述均有明确表面语义，并以 4.5:1 对比门禁约束；
  - 主菜单入口卡片、分组与滚动布局不变；锁定卡仍维持原 0.4 灰显契约，只把锁印移到灰显层外并改为绛红小印，使“未解锁”不再只靠低透明度表达；
  - `splash`、`save_select_filled`、`main_menu_clean` 双视口前后目检确认，仅目标可读性/状态细节改变，无结构漂移。
  - 角色页继续沿用原“人物签在左、身份详情在右、后续成长模块纵向排列”的结构；宽屏详情列只将既有门人小传撑满可用宽度并贴齐人物签底部，使中间留白成为有边界的呼吸区，不新增/重排信息；
  - `PortraitFrame` 新增可选 `placeholderShapePath`：仅消费既有透明站姿 alpha，以统一墨色绘制身份剪影并叠姓名首字小印；原无 shape 调用仍保留首字兼容降级；
  - 出战三席和替补池无肖像角色均接入身份墨影，角色名、境界、流派、AI 倾向、装备攻击、弱势/闭关/未修主修标签及点选交换流程完全不变；
  - 编成身份墨影按师承角色/稳定 id 选择三种现有外形，原人物肤色、衣纹、五官全部被 `srcIn` 墨色覆盖，不把他人的站姿冒充成该角色正式肖像。
  - 主线章内行程继续保持原五节点、连线、图标和上下结构，仅将配置已明确的小 Boss / 章末大 Boss 从两个相同的 `Boss` 标签区分为“强敌 / 章末”，补回原数据已有的层级语义；
  - 塔势总览继续使用原 30 节点单行与窄屏横向滚动，将 29 段连线各收窄 1px，使节点总宽度在 1080 内容栏的 1020px 面板安全区内完整落下，第 30 层不再被裁切；
  - 塔势节点状态标签改为“当前 / 最高”优先于 Boss 大小标签，解决第 5、10……层恰为当前或最高时状态印被 Boss 字样盖住；当前和最高边框仅增强 0.4px，未改色相、节点尺寸或排列。
  - 仓库筛选面板、分组、行距与按钮数不变；可点击未选项从 disabled 同款灰阶提升为深底次级正文色，真正禁用态仍保留低透明度，解决“所有筛选都像不可点”的状态误读；
  - `PlaqueButton` 继续保持禁用牌面 0.4 透明度、原木纹/朱漆、尺寸与鼠标/键盘行为，只把操作名移出牌面透明层并用墨色绘制；仓库“装备”和商店“购买”现在可读但仍明显弱于可用朱漆按钮；
  - 神物/宝物详情继续保留原题字尺寸、品阶色相、英雄图亮金框和左右栏结构，仅把浅宣纸顶栏标题改用已有 `paperTierColorForEquipment`，神物标题对宣纸对比约 4:1，不再近似亮黄隐形；
  - 仓库长名继续使用既有单行省略，商店名称/用途继续由左侧 `Expanded` 与 `IntrinsicHeight` 自适应；复查未发现需要改变网格、卡高或货架分组的溢出。
  - 闭关地图、设置、进行中、结果四页与桃花岛继续保留原地图构图、卡片尺寸、信息顺序、结算/收取路径；双视口复核未发现需改结构的溢出；
  - 新增 `goldOnPaper` 同色相纸面金文字 sink，对宣纸达到 4.5:1；亮金装帧边框、进度条和深底金色不变；
  - 闭关活跃地图卡的纸面门槛/状态标签、圆满印与完成提示、结果路线编号、采集事件图标和跨境界徽记改用纸面金，不再把装帧亮金直接用作浅底小字；
  - 桃花岛满载热区在原“产出进度”单行槽内改显“仓储已满”，金色满条、建筑热区位置、宽高与点击详情路径均不变；满载不再只靠颜色表达。
  - 长尾档案簇先跑门派、战绩册、兵器谱、门派谱、奇遇/武学图鉴、藏卷阁、资源总览 14 条 route 双视口基线；门派、战绩、门派谱、奇遇/武学列表未发现可在“不改布局”边界内成立的明确视觉缺陷，保留现状；
  - 兵器谱已获得/未获得卡原有深墨 `Ink` 牌面因缺局部 `Material` 被画到宣纸后方，现补本地透明 Material 使原深墨卡面、品阶边和点击涟漪按声明呈现；92px 卡宽、Wrap 行列与筛选路径不变；
  - 兵器详情继续保持两张 760 宽纸卡，仅把“开锋候选技 1”孤字断行收为“开锋候选 1 式”；
  - 藏卷阁线索标题从深底亮金改为纸面金，四部卷册与 760 宽纵列不变；
  - 资源总览保留原左侧卡宽和分组，把“来源：主要来源：”重复标题收为单一“来源：”；
  - 玩家可见的招式 `powerMultiplier` 统一标为“威力”而非易误读为乘数的“倍率”；数值与伤害计算完全不变，武学详情、战斗技能浮层和角色招式信息共享同一 `UiStrings`。
  - 江湖远行总览/在途/归来、断魂庄装载/关间/奖励/失败，以及购买、使用、授业、重试、凝练等 13 条流程 route 已完成双视口基线；未发现可在“不改布局”边界内成立的新增缺陷，既有顶部对齐、大片留白、底部操作区与流程顺序全部保留；
  - 新增 `offline_recap_active`，使用生产 `Dialog` inset 与长材料明细稳定覆盖 active 闭关归来卡，不再依赖本机存档偶发弹层才能验收；
  - active 归来卡仍为原 420 宽、原题头/摘要/分组/双操作顺序；仅把可能超高的正文与明细放入内部滚动区，两个操作固定在卡底，正常高度截图与修改前保持相同几何；
  - 归来卡新增 800×520 长明细回归，确保正文过长时无 Flex overflow，且“稍后再说 / 前去收功”仍可命中。
  - Slice 8 资源扫描发现 14 张物品 PNG 均把图片编辑器透明棋盘格烘进了 RGB 源图；已用确定性像素阈值去除背景、保留原主体笔触与外形，并在宣纸底逐张目检；
  - 透明成品统一收为 768×768 调色板 PNG，总体积约 2.58 MiB，与原 1254×1254 不透明源图同量级；仓库 80px 图格、商店与来源表所需 Retina 清晰度仍有充足余量；
  - 新增物品成品图门禁：固定覆盖 14 图、最小 512×512、四角透明、透明像素占比 ≥30%、主体非空，防止编辑器棋盘格再次进入发布包。
- **下一步**：
  1. 扫描玩家可见文案中的术语漂移、重复前缀、内部字段名、占位文本与全半角细节；
  2. 复查物品/人物/场景资源的透明、裁切、编辑器底纹和低质量占位；
  3. 补键盘焦点、语义标签、非纯颜色状态与窄高窗口门禁；
  4. 独立提交内容与无障碍切片，再进入全量 analyze/test/visual route 终验。
- **已跑验证**：
  - 建分支前主线视觉/资产 targeted tests：55 pass / 0 fail；
  - 建分支前 `flutter analyze`：0 issue；
  - 新 worktree `flutter analyze`：0 issue；
  - 新 worktree章节/设置/视觉 route baseline：55 pass / 0 fail；
  - Slice 1 章节 widget tests：6 pass / 0 fail；
  - Slice 1 `flutter analyze`：0 issue；
  - Slice 1 真窗口截图：`chapter_list` @ 1280×720、1440×900，日志含 READY 且无异常；
  - Slice 2 主题/设置/visual route 与高影响调用方回归：122 pass / 0 fail；
  - Slice 2 真实 1280×720 设置弹窗几何回归：2 pass / 0 fail（含窄视口原回归）；
  - Slice 2 `flutter analyze`：0 issue；
  - Slice 2 真窗口截图：`settings_panel` @ 1280×720、1440×900，日志含受控 READY 且无 overflow/exception。
  - Slice 3A splash/save/main-menu/debug route targeted tests：57 pass / 0 fail；
  - Slice 3A `flutter analyze`：0 issue；
  - Slice 3A 真窗口截图：4 route × 1280×720、1440×900，8/8 READY 且无 overflow/exception。
  - Slice 3B 设置/弹窗/route targeted tests：64 pass / 0 fail；
  - Slice 3B 锚点复核 targeted tests：50 pass / 0 fail；
  - Slice 3B `flutter analyze`：0 issue；
  - Slice 3B 真窗口截图：`settings_panel_bottom`、`settings_panel_disabled` × 1280×720、1440×900，4/4 READY 且无 overflow/exception。
  - Slice 4 资产角色门禁：145 个生产敌人 source 全登记，9 个玩家专用站姿缺口被明确隔离，所有登记 standee 的透明/裁切/尺寸/比例/脚底检查通过；
  - Slice 4 `character_avatar` 与资产角色 targeted tests：22 pass / 0 fail；
  - Slice 4 提交前 battle/route/acceptance targeted tests：70 pass / 0 fail；
  - Slice 4 `flutter analyze`：0 issue；
  - Slice 4 真窗口截图：`battle_v2_neutral_3v3`、`battle_audit_stage_01_05`、`battle_identity_silhouette` × 1280×720、1440×900，6/6 READY 且无 overflow/exception；人工确认原三人阵列/站位不变、姓名牌可读、墨影无矩形肖像。
  - Slice 5 typography/surface/shared-kit targeted tests：44 pass / 0 fail；
  - Slice 5 inventory/technique/shop/character 高影响调用方回归：93 pass / 0 fail；
  - Slice 5 `flutter analyze`：0 issue；
  - Slice 5 真窗口截图：`inventory`、`technique_panel_tier_all` × 1280×720、1440×900，4/4 READY 且无 overflow/exception；后者 4/4 像素一致，前者仅确定性 fixture 数值变化，几何与样式人工复核无漂移。
  - Slice 6A splash/save/main-menu/shared state targeted tests：85 pass / 0 fail；
  - Slice 6A `surface_themes`、`ink_empty_state`、`wuxia_ink_button` 补充门禁：14 pass / 0 fail；
  - Slice 6A `flutter analyze`：0 issue；
  - Slice 6A 真窗口截图：`splash`、`save_select_filled`、`main_menu_clean` × 1280×720、1440×900，6/6 READY 且无 overflow/exception；锁印最终绛红版本另复核 2/2 READY。
  - Slice 6B portrait/character/lineup targeted tests：51 pass / 0 fail（含编成交换真 Isar e2e 与 1440×900 smoke）；
  - Slice 6B `flutter analyze`：0 issue；
  - Slice 6B 真窗口截图：`character_panel`、`team_lineup` × 1280×720、1440×900，4/4 READY 且无 overflow/exception；人工确认原上下模块、三席位置、替补行和操作路径不变。
  - Slice 6C mainline/tower targeted tests：25 pass / 0 fail（含 1280 塔势第 30 层几何、Boss 当前/最高优先级与主线双 Boss 语义）；
  - Slice 6C `flutter analyze`：0 issue；
  - Slice 6C 真窗口截图：`stage_list`、`tower_floor_list` × 1280×720、1440×900，4/4 READY 且无 overflow/exception；人工确认五节点行程、30 层塔势、章节卷轴与塔层之字卡片排列不变。
  - Slice 6D inventory/equipment/shop targeted tests：82 pass / 0 fail；
  - Slice 6D `PlaqueButton` 58-symbol 影响面扩展回归：197 pass / 0 fail（shared kit、存档、心法、角色、桃花岛、闭关 gate）；
  - Slice 6D `flutter analyze`：0 issue；
  - Slice 6D 真窗口截图：`inventory`、`equipment_detail_screen`、`shop` × 1280×720、1440×900，6/6 READY 且无 overflow/exception；人工确认仓库三栏网格、详情左右栏、货架分组与购买路径不变。
  - Slice 6E seclusion/taohua/theme targeted tests：61 pass / 0 fail；
  - Slice 6E `flutter analyze`：0 issue；
  - Slice 6E 真窗口截图：`seclusion_map_list`、`seclusion_setup`、`seclusion_active`、`seclusion_result`、`taohua_island` × 1280×720、1440×900，10/10 READY 且无 overflow/exception；人工确认原地图构图、卡片几何、闭关流程与桃花岛点击路径不变。
  - Slice 7A archive/resource/baike/battle 扩展回归：78 pass / 0 fail；
  - Slice 7A `flutter analyze`：0 issue；
  - Slice 7A 基线截图：14 route × 1280×720、1440×900，28/28 READY 且无 overflow/exception；
  - Slice 7A 修复后截图：`weapon_codex`、`weapon_codex_detail`、`zangjuange`、`resource_overview`、`skill_codex_detail` × 1280×720、1440×900，10/10 READY 且无 overflow/exception；人工确认页面宽度、卡位、网格、分组和导航不变。
  - Slice 7B 流程基线：13 route × 1280×720、1440×900，26/26 READY 且无 overflow/exception；人工确认江湖远行、断魂庄和确认类弹层无需改版；
  - Slice 7B active/passive 归来卡与 route 回归：64 pass / 0 fail；
  - Slice 7B `offline_recap_active` × 1280×720、1440×900，2/2 READY 且无 overflow/exception；修改前后正常高度几何一致，800×520 长明细由 widget test 覆盖内部滚动和固定操作。
  - Slice 8 物品图透明/解码/声明/全资产审计回归：13 pass / 0 fail；
  - Slice 8 `inventory`、`item_use_confirm_dialog` × 1280×720、1440×900，4/4 READY 且无 overflow/exception；人工确认棋盘底消失、物品造型/色相/图格尺寸不变。
- **阻塞项**：无。
- **残留风险**：
  - 伪文字规则和跨平台正式字体方案仍需后续设计拍板；
  - 当前 macOS 可验证，Windows 缩放只能在 ship 前实机终验；
  - Claude 后续可能推进 `main`，本分支每个大批次前需要以 `merge-tree` 评估冲突，不直接重写其改动；
  - 9 名可出战候选仍是专用透明站姿美术债；当前身份墨影是风格一致的安全降级，不冒充完成稿，补图后必须更新角色门禁预期；
  - 自动 Theme 已覆盖共享浅/深面板，高频调用方已回归；仍需在 Slice 6/7 用生产 route 继续覆盖长尾 Material 控件状态，避免极少数页面依赖旧的隐式 Theme；
  - visual route 当前固定全新进度，后段当前章的画面定位由 1280/1440 widget 几何测试覆盖；Slice 3 补视觉 route 状态矩阵时再加入后段进度截图；
  - active「归来」弹层的偶发高度溢出已在 Slice 7B 通过正文内部滚动与固定操作区收口，并有独立生产 Dialog route；后续只需在 Windows 缩放终验复核。
