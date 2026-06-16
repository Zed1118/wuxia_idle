# Session 交接 · 上下文帮助系统 阶段一~三(overnight 自主)

**时间:** 2026-06-17 凌晨
**分支:** main(已 ff-merge + push)
**HEAD:** 49a46452

## 本次完成(用户睡前拍板:阶段1-3扎实 + 阶段4留 handoff · TDD + 分阶段 commit)

源:桌面《上下文帮助系统_修订版_对齐现状.md》→ `docs/spec/contextual_help_system_spec_2026-06-16.md`。
核心设计:**砍双真相源**——中文全引用 `UiStrings`,step/category 经 `CodexIndex` 派生。

- **阶段一 `441b2bf0`**:新建 `features/help`:`HelpTopic`(21→23 词)+ `HelpBinding` + `HelpCatalog` 薄映射;`GlossaryTopicLabel`(术语级 ? tooltip,薄包装委托 shared `GlossaryLabel`)+ `ContextHelpButton`(页面级 ? · ConsumerWidget · 复用 `codexListItemsProvider`+`currentTutorialStepProvider` 判解锁 · 解锁跳 `CodexEntryDetail` / 未解锁灰显「阅历未至」)。UiStrings 补 12 释义 + 6 label + contextHelpLocked。
- **阶段二 `e695ad69`**:`WuxiaTitleBar` 加通用 `trailing` 槽(加法,shared 不依赖 features)。4 屏标题栏注入 ?:角色面板→realm / 装备详情+仓库→equipmentTier / 藏经阁→mainTechnique。
- **阶段三 `49a46452`**:战斗屏 `_Header` 末尾 ?→combat_advanced;闭关 4 屏 AppBar.actions ?→retreat。+combatAdvanced/seclusion 2 topic。

## 当前状态

全量 analyze **0** · 全量 **2301 测 +1 skip**(baseline 2286,+15 零回归)。主 checkout 已验(analyze + help 测)。

## 视觉验收

- **PASS(CLI 自截 720p + Read)**:character_panel(普通标题栏)+ equipment_detail(神物大标题)→ 同一 ContextHelpButton ? 渲染克制、不溢出、不挤标题。
- **未直接截图(如实)**:battle_scene / seclusion_map_list 两 route 本环境 CLI 截图 flake(app build 正常,route 始终不发 `VISUAL_ROUTE_READY`,与本次只加 AppBar 图标无关)→ 靠 widget 测(含 battle 指令台 1280×720 不溢出测)+ 同构视觉验证兜底。**建议下次真机/Codex 补这两屏目检**。

## 阶段四 backlog(留)

1. battle/seclusion 两屏 ? 真机目检(本次截图 flake)。
2. tower/stage:无对应 codex 条目 → 需先拍板新增 codex 条目或映射既有(realm?)再接。
3. encounter:走 dialog/flow 无 AppBar → 需定术语级接入点。
4. 后期系统(江湖恩怨/心魔/帮派/轻功/群战/飞升/真传位)+ step gating 灰显。
5. 「首次遇到机制金色提示点」净新发现感基建(单列 scope)。
6. 角色面板现有 11 处 GlossaryLabel 迁 GlossaryTopicLabel(纯收口,可选)。

## 踩坑

- `ContextHelpButton` 是 ConsumerWidget,嵌入的屏其 widget 测必须包 `ProviderScope`(retreat_result_screen_test 本次补)。无 GameRepository 时优雅降级:codexListItems→[] + currentTutorialStep→0 → 渲染 locked,不崩。
- worktree 跑 visual_capture 改 `macos/Runner.*`,commit 前 `git checkout -- macos/`。
