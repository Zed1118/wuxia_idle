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

- **状态**：Slice 0 已完成，准备进入 Slice 1。
- **最后完成**：
  - 已从 `main@fbd567df` 创建 `codex/global-visual-polish`；
  - 已建立独立 worktree；
  - 已把全局审查报告移入独立 worktree，主 checkout 恢复干净；
  - 已确认 Claude Code worktree 为 `.claude/worktrees/damage-popup-parseback`，本任务不访问其文件；
  - 已执行 `flutter pub get`；
  - 新 worktree 首次 analyze 因 gitignored 的生成文件缺失而失败，已用 `dart run build_runner build --delete-conflicting-outputs` 重建 128 个输出；
  - 重建后 `flutter analyze` 为 0 issue；
  - 章节、设置和视觉 route 定向基线共 55 tests 全部通过。
- **下一步**：
  1. 通过 CodeGraph 读取章节路引及其调用关系；
  2. 修复 16 章在 1280/1440 视口下的横向溢出；
  3. 补当前章节自动定位、鼠标/键盘横向操作和回归测试；
  4. 目检 1280×720、1440×900 后提交 Slice 1。
- **已跑验证**：
  - 建分支前主线视觉/资产 targeted tests：55 pass / 0 fail；
  - 建分支前 `flutter analyze`：0 issue；
  - 新 worktree `flutter analyze`：0 issue；
  - 新 worktree章节/设置/视觉 route baseline：55 pass / 0 fail。
- **阻塞项**：无。
- **残留风险**：
  - 伪文字规则和跨平台正式字体方案仍需后续设计拍板；
  - 当前 macOS 可验证，Windows 缩放只能在 ship 前实机终验；
  - Claude 后续可能推进 `main`，本分支每个大批次前需要以 `merge-tree` 评估冲突，不直接重写其改动。
