import 'visual_route.dart';

/// Codex/Claude 视觉验收的固定入口清单。
///
/// 这里不负责截图,只生成稳定 route/seed/checklist 元数据。真实截图仍由
/// `tools/visual_capture/visual_capture.sh` 启动 macOS app 并等待
/// `VISUAL_ROUTE_READY`。
enum VisualAcceptanceSuite {
  smoke,
  battle,
  full;

  static VisualAcceptanceSuite parse(String raw) {
    for (final suite in values) {
      if (suite.name == raw) return suite;
    }
    throw ArgumentError.value(raw, 'suite', 'expected: smoke|battle|full');
  }
}

class VisualAcceptanceRoute {
  const VisualAcceptanceRoute({
    required this.route,
    required this.id,
    required this.seed,
    required this.kind,
    required this.checks,
  });

  final VisualRoute route;
  final String id;
  final String seed;
  final VisualRouteKind kind;
  final List<String> checks;
}

const String visualAcceptanceSeed = 'visual-route-host-fixture-20260627';

const List<VisualRoute> _smokeRoutes = [
  VisualRoute.splash,
  VisualRoute.saveSelectEmpty,
  VisualRoute.saveSelectFilled,
  VisualRoute.mainMenuClean,
  VisualRoute.mainMenu,
  VisualRoute.settingsPanel,
  VisualRoute.settingsPanelBottom,
  VisualRoute.settingsPanelDisabled,
  VisualRoute.inventory,
  VisualRoute.phase0aBattlePlayable,
  VisualRoute.phase0aBattleBossMechanics,
  VisualRoute.phase0aBattleGuardianMechanics,
  VisualRoute.techniquePanelTierAll,
  VisualRoute.shop,
  VisualRoute.seclusionMapList,
  VisualRoute.towerFloorList,
  VisualRoute.taohuaBuildingPopup,
  VisualRoute.zangjuange,
  VisualRoute.encounterCodex,
  VisualRoute.skillCodex,
];

final List<VisualAcceptanceRoute> _battleRoutes = [
  for (final route in const [
    VisualRoute.phase0aBattlePlayable,
    VisualRoute.phase0aBattleAttackFeedback,
    VisualRoute.phase0aBattleGatherFeedback,
    VisualRoute.phase0aBattleClearFeedback,
    VisualRoute.phase0aBattleBossMechanics,
    VisualRoute.phase0aBattleGuardianMechanics,
  ])
    VisualAcceptanceRoute(
      route: route,
      id: route.id,
      seed: visualAcceptanceSeed,
      kind: route.kind,
      checks: _checksFor(route),
    ),
];

List<VisualAcceptanceRoute> visualAcceptanceRoutes(
  VisualAcceptanceSuite suite,
) {
  final routes = switch (suite) {
    VisualAcceptanceSuite.smoke => _smokeRoutes,
    VisualAcceptanceSuite.battle => const <VisualRoute>[],
    VisualAcceptanceSuite.full =>
      VisualRoute.values.where((r) => r != VisualRoute.hub).toList(),
  };
  if (suite == VisualAcceptanceSuite.battle) return _battleRoutes;
  return [
    for (final route in routes)
      VisualAcceptanceRoute(
        route: route,
        id: route.id,
        seed: visualAcceptanceSeed,
        kind: route.kind,
        checks: _checksFor(route),
      ),
  ];
}

List<String> visualAcceptanceRouteIds(VisualAcceptanceSuite suite) {
  return visualAcceptanceRoutes(suite).map((r) => r.id).toList();
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
    ..writeln('| route | kind | seed | checks |')
    ..writeln('|---|---|---|---|');

  for (final target in visualAcceptanceRoutes(suite)) {
    buffer.writeln(
      '| `${target.id}` | `${target.kind.name}` | `${target.seed}` | '
      '${target.checks.join('<br>')} |',
    );
  }
  return buffer.toString();
}

List<String> _checksFor(VisualRoute route) {
  return switch (route) {
    VisualRoute.splash => const ['启动背景完整铺满', '标题与展卷状态可读', '无系统 loading 圈混入'],
    VisualRoute.saveSelectEmpty => const [
      '三空槽同屏',
      '首次启动信息层级清楚',
      '1280×720 不需要滚动即可理解入口',
    ],
    VisualRoute.saveSelectFilled => const [
      '最近存档、祖师与进度摘要可扫读',
      '重命名/删除与整卡进入层级分明',
      '有档/空槽/快速开局三态区分',
    ],
    VisualRoute.mainMenu => const ['主菜单入口可见', '水墨克制基调', '按钮文字无溢出'],
    VisualRoute.mainMenuClean => const [
      '无归来或一次性弹层遮挡',
      '主菜单题字、状态区与首屏入口同时可见',
      '水墨门面和锁定态保持生产样式',
    ],
    VisualRoute.settingsPanel => const [
      '真实设置弹窗已完全打开',
      '浅宣纸上的标题、滑条、开关和下拉均为墨色可读态',
      '720p 下底部操作区固定可见且正文可滚动',
    ],
    VisualRoute.settingsPanelBottom => const [
      '真实单栏滚动已抵达底部',
      '存档管理、切换存档、关于与退出入口完整可读',
      '720p 下关闭按钮仍固定可见且无内容遮挡',
    ],
    VisualRoute.settingsPanelDisabled => const [
      '真实显示设置段已进入视口',
      '全屏开启时分辨率下拉呈明确禁用态',
      '禁用态仍可辨认但不与可交互控件混淆',
    ],
    VisualRoute.inventory => const ['背包分组清楚', '装备/材料标题无溢出', '操作按钮 hitbox 可见'],
    VisualRoute.phase0aBattlePlayable => const [
      '单角色与敌群清晰分离',
      '键鼠提示、技能印与暂停入口可读',
      '最低视口无布局溢出',
    ],
    VisualRoute.phase0aBattleAttackFeedback => const [
      '普攻命中反馈与伤害数字可辨',
      '角色、目标和反馈层不互相遮挡',
      '反馈结束后画面状态稳定',
    ],
    VisualRoute.phase0aBattleGatherFeedback => const [
      '聚怪范围与受影响目标可辨',
      'Q 技能印状态与真气消耗清楚',
      '反馈不遮挡 Boss 机制提示',
    ],
    VisualRoute.phase0aBattleClearFeedback => const [
      '清场爆发范围与命中反馈清楚',
      'R 技能印状态与真气消耗清楚',
      '多目标飘字无关键重叠',
    ],
    VisualRoute.phase0aBattleBossMechanics => const [
      'Boss 蓄力预警与剩余节拍清楚',
      '破招、踉跄和破绽窗口反馈可区分',
      '机制提示与 Boss 血条不挤压',
    ],
    VisualRoute.phase0aBattleGuardianMechanics => const [
      '护法结界、拦截和合击状态可辨',
      'Boss 与护法身份、血条和反馈不混淆',
      '最低视口下机制标签无溢出',
    ],
    VisualRoute.phase0aM4DensityProfile => const [
      '24 active 下玩家与关键威胁仍可辨',
      '伤害数字、屏外提示与音效不遮蔽判断',
      '双视口正式 Profile 性能矩阵另行签字',
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
    VisualRoute.offlineRecapActive => const [
      'active 闭关长明细在 720p 不溢出',
      '明细可滚动且双操作始终可见',
      '离线时长、地图状态与待收收益层级清楚',
    ],
    VisualRoute.offlineRecapPassive => const [
      '被动收益已入库语义明确',
      '仅保留告知关闭操作',
      '720p 下完整可读且无领取诱导',
    ],
    VisualRoute.shop => const ['货币顶栏可读', '可买/不可买态清楚', '货架按钮无文字溢出'],
    VisualRoute.resourceOverview => const [
      '五类资源分组可扫读',
      '来源/用途/近期去向文字无溢出',
      '库存数量与折叠来源可辨认',
    ],
    VisualRoute.taohuaBuildingPopup => const [
      '产业弹窗默认打开',
      '产出/升级/配方/建筑志信息分区清楚',
      '弹窗不依赖页面滚动才能理解操作入口',
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
