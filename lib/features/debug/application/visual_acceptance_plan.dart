import 'visual_route.dart';

/// Codex/Claude 视觉验收的固定入口清单。
///
/// 这里不负责截图,只生成稳定 route/seed/checklist 元数据。真实截图仍由
/// `tools/visual_capture/visual_capture.sh` 启动 macOS app 并等待
/// `VISUAL_ROUTE_READY`。
enum VisualAcceptanceSuite {
  smoke,
  full;

  static VisualAcceptanceSuite parse(String raw) {
    for (final suite in values) {
      if (suite.name == raw) return suite;
    }
    throw ArgumentError.value(raw, 'suite', 'expected: smoke|full');
  }
}

class VisualAcceptanceRoute {
  const VisualAcceptanceRoute({
    required this.route,
    required this.seed,
    required this.checks,
  });

  final VisualRoute route;
  final String seed;
  final List<String> checks;
}

const String visualAcceptanceSeed = 'visual-route-host-fixture-20260627';

const List<VisualRoute> _smokeRoutes = [
  VisualRoute.mainMenu,
  VisualRoute.inventory,
  VisualRoute.battleScene,
  VisualRoute.techniquePanelTierAll,
  VisualRoute.shop,
  VisualRoute.seclusionMapList,
  VisualRoute.towerFloorList,
  VisualRoute.zangjuange,
  VisualRoute.encounterCodex,
  VisualRoute.skillCodex,
  VisualRoute.battleChargeBreak,
];

List<VisualAcceptanceRoute> visualAcceptanceRoutes(
  VisualAcceptanceSuite suite,
) {
  final routes = switch (suite) {
    VisualAcceptanceSuite.smoke => _smokeRoutes,
    VisualAcceptanceSuite.full =>
      VisualRoute.values.where((r) => r != VisualRoute.hub).toList(),
  };
  return [
    for (final route in routes)
      VisualAcceptanceRoute(
        route: route,
        seed: visualAcceptanceSeed,
        checks: _checksFor(route),
      ),
  ];
}

List<String> visualAcceptanceRouteIds(VisualAcceptanceSuite suite) {
  return visualAcceptanceRoutes(suite).map((r) => r.route.id).toList();
}

String visualAcceptanceChecklistMarkdown(
  VisualAcceptanceSuite suite, {
  List<String> resolutions = const [
    '1280x720',
    '1440x900',
    '1920x1080',
    '2560x1080',
  ],
}) {
  final buffer = StringBuffer()
    ..writeln('# 视觉验收清单')
    ..writeln()
    ..writeln('- suite: `${suite.name}`')
    ..writeln('- seed: `$visualAcceptanceSeed`')
    ..writeln('- resolutions: `${resolutions.join(', ')}`')
    ..writeln(
      '- capture: `tools/visual_capture/visual_capture.sh --suite ${suite.name}`',
    )
    ..writeln()
    ..writeln('| route | seed | checks |')
    ..writeln('|---|---|---|');

  for (final target in visualAcceptanceRoutes(suite)) {
    buffer.writeln(
      '| `${target.route.id}` | `${target.seed}` | '
      '${target.checks.join('<br>')} |',
    );
  }
  return buffer.toString();
}

List<String> _checksFor(VisualRoute route) {
  return switch (route) {
    VisualRoute.mainMenu => const ['主菜单入口可见', '水墨克制基调', '按钮文字无溢出'],
    VisualRoute.inventory => const ['背包分组清楚', '装备/材料标题无溢出', '操作按钮 hitbox 可见'],
    VisualRoute.battleScene => const [
      '战斗深色底文字可读',
      'HUD 不遮挡角色',
      '无明显 repaint 闪烁',
    ],
    VisualRoute.techniquePanelTierAll => const [
      '七阶心法 cover 同屏',
      '阶层梯度清楚',
      '列表滚动/卡片不挤压',
    ],
    VisualRoute.techniquePanelHero => const [
      '主修 hero 视觉焦点明确',
      '角色/心法信息无遮挡',
      '水墨氛围一致',
    ],
    VisualRoute.battleChargeBreak => const [
      '蓄力敌人可辨认',
      '破招按钮高亮明确',
      '战斗指令区不遮挡角色',
    ],
    VisualRoute.battleInterruptCaption => const [
      '破招题字可读',
      '玩家/敌方两态颜色区分',
      '题字不遮挡核心 HUD',
    ],
    VisualRoute.battleDefeat => const ['败北题字与战报可读', '破招提示存在', '背景压暗后内容层级清楚'],
    VisualRoute.shop => const ['货币顶栏可读', '可买/不可买态清楚', '货架按钮无文字溢出'],
    VisualRoute.resourceOverview => const [
      '五类资源分组可扫读',
      '来源/用途/近期去向文字无溢出',
      '库存数量与折叠来源可辨认',
    ],
    VisualRoute.seclusionMapList => const [
      '五处闭关地图可扫读',
      '状态 chip 不挤压',
      '超宽下卡片不过散',
    ],
    VisualRoute.towerFloorList => const ['30 层节点可辨认', 'Boss 标记清楚', '横向滚动无遮挡'],
    VisualRoute.zangjuange => const ['百科入口齐全', '卡片标题无溢出', '浅底文字用墨色'],
    VisualRoute.encounterCodex => const ['奇遇录分组齐全', '点亮/剪影态区分', '浅宣纸底对比足够'],
    VisualRoute.skillCodex => const ['武学图鉴分组齐全', '招式名无溢出', 'chip/状态条可读'],
    _ => [route.label],
  };
}
