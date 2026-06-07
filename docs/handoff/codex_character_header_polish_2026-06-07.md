# 角色档案头头像签 polish 验收

日期：2026-06-07
分支：`codex/t11-inventory-section-header`

## 范围

本轮处理角色页一个细粒度视觉问题：档案头头像区域略像独立贴图，人物身份层级不够像“档案签”。

- 画像签新增「人物签」小题与横线，强化档案感。
- 画像签外框改为流派色弱描边 + 纸底阴影，减少头像突兀感。
- `PortraitFrame` 增加 `fit` 参数，默认仍 `cover`；角色档案头单独使用 `BoxFit.contain`，避免祖师立绘被裁到暗部。
- 不改角色、师徒、属性、装备、心法、相生等业务逻辑。

## 结论

总判：通过。角色页测试与师承页测试均通过；1280x720 截图未见 overflow；人物签框架与身份条同屏可见。

| 验收点 | 结果 | 说明 |
|---|---:|---|
| 头像不再像裸贴图 | 通过 | 新增人物签标题、纸底和流派弱描边。 |
| 身份层级可读 | 通过 | 原「开派祖师 / 门下弟子」身份条保留，人物签补充档案语境。 |
| 立绘裁切改善 | 通过 | 档案头 `PortraitFrame` 使用 `BoxFit.contain`，避免只截到暗部。 |
| 原页面功能不变 | 通过 | 角色面板、边界、师承面板测试通过。 |

## 截图清单

- `docs/handoff/codex_character_header_polish_2026-06-07/01_character_header_portrait_plaque.png`

## 验证

```bash
flutter test test/features/character_panel/presentation/character_panel_screen_test.dart test/features/character_panel/presentation/character_panel_screen_edge_test.dart test/features/character_panel/presentation/lineage_panel_screen_test.dart test/features/character_panel/presentation/lineage_panel_screen_edge_test.dart
flutter analyze lib/features/character_panel/presentation/character_panel_screen.dart lib/shared/widgets/portrait_frame.dart lib/shared/strings.dart test/features/character_panel/presentation/character_panel_screen_test.dart test/features/character_panel/presentation/character_panel_screen_edge_test.dart
flutter build macos --debug --dart-define=VISUAL_ROUTE=character_panel
```

## 备注

- 当前桌面处于 macOS 锁屏，真实 app 窗口无法截图；截图由临时 widget capture 生成，临时文件已删除。
- 临时 widget capture 对 `PortraitFrame` 的图片解码仍会回退占位，因此截图主要验收签框/排版；真实资源路径由 `flutter build` 与项目 asset bundle 覆盖，`founder.png` 本身可正常读取。
