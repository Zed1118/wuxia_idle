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
  VisualRoute.battleScene,
  VisualRoute.mainlineFirstClearBattle,
  VisualRoute.mainlineFirstClearBattleAuto,
  VisualRoute.techniquePanelTierAll,
  VisualRoute.shop,
  VisualRoute.seclusionMapList,
  VisualRoute.towerFloorList,
  VisualRoute.taohuaBuildingPopup,
  VisualRoute.zangjuange,
  VisualRoute.encounterCodex,
  VisualRoute.skillCodex,
  VisualRoute.battleChargeBreak,
];

final List<VisualAcceptanceRoute> _battleRoutes = [
  for (var chapter = 1; chapter <= 6; chapter++)
    for (var stage = 1; stage <= 5; stage++)
      _battleStageRoute(
        'battle_audit_stage_${_twoDigits(chapter)}_${_twoDigits(stage)}',
      ),
  for (var floor = 1; floor <= 30; floor++) _battleTowerRoute(floor),
  for (var stage = 1; stage <= 5; stage++)
    _battleStageRoute('battle_audit_stage_light_foot_${_twoDigits(stage)}'),
  for (var stage = 1; stage <= 5; stage++)
    _battleStageRoute('battle_audit_stage_mass_battle_${_twoDigits(stage)}'),
  for (final route in const [
    VisualRoute.battleV2CasualtyReplacement,
    VisualRoute.battleV2FastForwardPeak,
    VisualRoute.battleV2PreResult,
    VisualRoute.battleV2Neutral3v3,
    VisualRoute.battleV2ResourcePressure,
  ])
    VisualAcceptanceRoute(
      route: route,
      id: route.id,
      seed: visualAcceptanceSeed,
      kind: route.kind,
      checks: _checksFor(route),
    ),
];

VisualAcceptanceRoute _battleStageRoute(String id) => VisualAcceptanceRoute(
  route: VisualRoute.battleStageAudit,
  id: id,
  seed: visualAcceptanceSeed,
  kind: VisualRoute.battleStageAudit.kind,
  checks: _checksFor(VisualRoute.battleStageAudit),
);

VisualAcceptanceRoute _battleTowerRoute(int floor) => VisualAcceptanceRoute(
  route: VisualRoute.battleTowerAudit,
  id: 'battle_audit_tower_${_twoDigits(floor)}',
  seed: visualAcceptanceSeed,
  kind: VisualRoute.battleTowerAudit.kind,
  checks: _checksFor(VisualRoute.battleTowerAudit),
);

String _twoDigits(int value) => value.toString().padLeft(2, '0');

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
    VisualRoute.battleScene => const [
      '战斗深色底文字可读',
      'HUD 不遮挡角色',
      '无明显 repaint 闪烁',
    ],
    VisualRoute.battleStageAudit => const [
      '真关卡背景与敌队配置接线',
      '三人站位/立绘脚底/血条无遮挡',
      '技能栏无溢出且文字完整',
    ],
    VisualRoute.battleTowerAudit => const [
      '真塔层敌队配置接线',
      '敌我站位对称且全身立绘清晰',
      'HUD/血条/技能栏无溢出',
    ],
    VisualRoute.mainlineFirstClearBattle => const [
      '真主线 stage 首通起手暂停可见',
      'readable pacing 下 HUD/血条/伤害层级可读',
      '单步/继续控件不遮挡关键角色',
    ],
    VisualRoute.mainlineFirstClearBattleAuto => const [
      '真主线 stage 首通可自动播放',
      '起手/爆发/胜利三帧可连续截图',
      '短战斗不会立即跳过观看窗口',
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
    VisualRoute.battleFirstClearShowcase => const [
      '三态题字可读(初战/蓄力可破/峰值破！)',
      'flourish 峰值字号明显大于基准且带辉光',
      '双分辨率无溢出裁切',
    ],
    VisualRoute.battleDefeat => const ['败北题字与战报可读', '破招提示存在', '背景压暗后内容层级清楚'],
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
    VisualRoute.battleGuardianWard => const [
      '「护法结界」护罩 pill 可辨(内力色·水墨克制不网游味)',
      'Boss 金边 + 护罩 pill + 流派克制标多 tag 同屏不挤压/不遮头像',
      '最低分辨率下多 tag 堆叠仍可读',
    ],
    VisualRoute.battleV2CasualtyReplacement => const [
      '固定 seed 首次阵亡递补完成后暂停',
      '阵亡者褪墨且替补进入同一视觉槽',
      'READY 日志含实际 tick 与存活摘要',
    ],
    VisualRoute.battleV2FastForwardPeak => const [
      '固定 seed 同拍双伤害峰值后暂停',
      '飘字与命中特效不互撞',
      'READY 日志含实际 tick 与峰值动作数',
    ],
    VisualRoute.battleV2PreResult => const [
      '冻结在最后一次致胜 action 前',
      '结算层尚未覆盖战场',
      'READY 日志含实际 tick 与存活摘要',
    ],
    VisualRoute.battleV2Neutral3v3 => const [
      '标准 3v3 无待发/大招/结算遮挡',
      '三人阵列与完整案台同屏',
      'READY 只在战斗初态挂载后发出',
    ],
    VisualRoute.battleV2ResourcePressure => const [
      '同帧至少一张冷却签和一张真气不足签',
      '两种不可用状态可独立识别',
      'READY 只在资源压力初态成立后发出',
    ],
    _ => [route.label],
  };
}
