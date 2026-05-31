# sect 立绘 portraitPath 渲染 wiring 设计

日期: 2026-05-31
分支: worktree-sect-portrait-wiring
背景: Codex 复验 B 段 FAIL — 6 张 sect_candidate + 入派 NPC 立绘资产已落地,但生产 UI 从未接 portraitPath 渲染链路(`sect_recruit` 确认 dialog / 强制招募 debug 列表 / `sect_screen` 成员行三处缺口)。

## 目标

让 sect 立绘在生产 UI 真正呈现,关闭 Codex B 段验收缺口。验收项:6 张 sect_candidate 在成员列表呈现 + dialog/debug 列表显立绘 + 一键 VISUAL_ROUTE 复验。

## 决议(brainstorming 拍板)

- **方案 A**:`Character.portraitPath` 新字段为成员立绘单一真相源(方案 B「存 candidateDefId 反查」同样要升 schema,反而多一层间接 + fallback,被证伪)。
- **全成员统一显**:祖师/弟子/NPC 成员行都显立绘。
- 成员行立绘 **48×48** 紧凑尺寸;强制招募 debug 列表 **做**(40×40)。

## 架构

`Character.portraitPath` 单一真相源。所有能成为 sect 成员的 Character 在创建时写入 portraitPath,成员行统一读 `member.portraitPath`。Dialog / debug 列表直接持有 `SectCandidateDef`,不经 Character,直读 `candidate.portraitPath`。

立绘来源已确认:
- 祖师/弟子:`MasterDef.portraitPath`(`data/masters.yaml` founder.png/first_disciple.png/second_disciple.png 已有值)
- NPC:`SectCandidateDef.portraitPath`(`data/sect_candidates.yaml` 6 张 sect_candidate_*.png 已有值)

## 改动清单(6 处)

### ① Schema(Isar 升版)
- `lib/core/domain/character.dart`:`Character` 加 `String? portraitPath;` + `Character.create` 增可选命名参数 `portraitPath`(默认 null,向后兼容)。
- `lib/data/isar_setup.dart`:`_currentSaveVersion` `0.14.0 → 0.15.0` + 注释行(沿既有升版体例)。
- 需跑 `build_runner`(Isar `.g.dart` 重生,fresh worktree 注意 libisar.dylib)。

### ② 立绘写入(两条创建路径)
- `lib/features/onboarding/application/master_builder.dart:buildMasterCharacter`:`Character.create(..., portraitPath: def.portraitPath)`。
- `lib/features/sect/presentation/sect_recruit_handler.dart:97 runSectRecruitFlow`:`Character.create(..., portraitPath: candidate.portraitPath)`。

### ③ sect_screen 成员行
- `lib/features/sect/presentation/sect_screen.dart:_MemberRow`:Row 最左插 48×48 portrait `Container`(边框 schoolColor + avatarFill 底)+ `Image.asset(member.portraitPath!, fit: BoxFit.cover, errorBuilder: → avatarFill)`;`portraitPath == null` 时 `SizedBox.shrink()` 不破现有布局。

### ④ sect_recruit 确认 dialog
- `lib/features/encounter/presentation/sect_recruit_confirm_dialog.dart:_CandidateInfo`:姓名 Row 前插 96×96 portrait,直读 `candidate.portraitPath`,体例同 `recruitment_dialog.dart:268`。

### ⑤ 强制招募 debug 列表
- `lib/features/debug/presentation/sect_recruit_debug_screen.dart`:list item 的 `Icon(Icons.person_add)` 前置 40×40 portrait 缩略图,直读 `candidate.portraitPath`(无需反查,本就遍历 SectCandidateDef)。

### ⑥ L3 VISUAL_ROUTE
- `lib/features/debug/application/visual_route.dart`:加枚举 `sectScreenNpc('sect_screen_npc', 'sect_screen·成员立绘验收(祖师+6 NPC 完整显)')`。
- `lib/features/debug/presentation/visual_route_host.dart`:加 case → 新 seed `seedSectWithFullNpc` → 直达 `SectScreen`。
- seed 放 `Phase2SeedService`(沿 `seedVisualMasterAllTiers` 体例):ensureFoundingMasters + Sect lazy-init + 招满 6 sect_candidate 入派。

## 渲染体例(统一)

```dart
Container(
  width: <size>, height: <size>,
  decoration: BoxDecoration(
    border: Border.all(color: schoolColor, width: 1),
    color: WuxiaColors.avatarFill,
  ),
  child: portraitPath == null
      ? const SizedBox.shrink()
      : Image.asset(portraitPath!, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(color: WuxiaColors.avatarFill)),
)
```

## 测试

- wiring 测:`Character.create` 透传 portraitPath(founder def 路径 + candidate 路径各 1)。
- member row widget 测:`setSurfaceSize` 扩 viewport + `addTearDown`,Image.asset errorBuilder 守(memory `feedback_listview_widget_test_viewport` / `feedback_image_asset_error_builder`)。
- seed 单测:`seedSectWithFullNpc` 后,6 招募的 sect_candidate NPC 全部 `isInSect=true` 且 `portraitPath` 非空 + 祖师 `portraitPath` 非空(语义断言,不写死成员总数 — 弟子是否计入 sect 成员取决于 Sect lazy-init,避免脆弱锚)。
- Isar saveVersion compat 测:沿既有 0.14 compat 体例升 0.15。
- 全量 baseline:1620 测 + 0 analyze(改动后重跑,delta = +新增测数)。

## 不做(YAGNI)

- 不引入 candidateDefId 反查(方案 A 不需要)。
- 不动 recruitment 收徒池立绘(已 PASS)。
- 不改 GDD / numbers.yaml / 规则层。

## 验收

- L3:`flutter run -d macos --dart-define=VISUAL_ROUTE=sect_screen_npc` → `VISUAL_ROUTE_READY` → Codex 截图复验祖师 + 6 sect_candidate 立绘完整显(弟子若在派一并显)。
- dialog / debug 列表立绘呈现(Codex 走可达路径)。
