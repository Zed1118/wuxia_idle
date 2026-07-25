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

- **状态**：Slice 4 已完成，准备进入 Slice 5（视觉基础设施）。
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
- **下一步**：
  1. 盘点现有字号、表面和分区标题的真实复用簇，先定最小语义 token；
  2. 建立 `DarkSurfaceTheme`，与已完成的 `paperSurfaceTheme` 对齐交互态；
  3. 先迁移高频共用标题栏、SectionHeader、状态 pill 和空状态；
  4. 每个迁移小批次用双视口生产 route 验证，不做全仓机械替换。
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
- **阻塞项**：无。
- **残留风险**：
  - 伪文字规则和跨平台正式字体方案仍需后续设计拍板；
  - 当前 macOS 可验证，Windows 缩放只能在 ship 前实机终验；
  - Claude 后续可能推进 `main`，本分支每个大批次前需要以 `merge-tree` 评估冲突，不直接重写其改动；
  - 9 名可出战候选仍是专用透明站姿美术债；当前身份墨影是风格一致的安全降级，不冒充完成稿，补图后必须更新角色门禁预期；
  - visual route 当前固定全新进度，后段当前章的画面定位由 1280/1440 widget 几何测试覆盖；Slice 3 补视觉 route 状态矩阵时再加入后段进度截图；
  - 首次设置 route 尝试因本机存档自动叠加「归来」弹层，顺带发现该弹层在 1280×720 仍有 47px 底部溢出；已隔离 route 污染，问题列入 Slice 7，不在设置切片擅改其既定结构。
