import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/presentation/character_avatar.dart';

import '../../../tools/asset_audit.dart';

Future<String> _fileLoader(String path) => File(path).readAsString();

void main() {
  late GameRepository repo;

  setUpAll(() async {
    repo = await GameRepository.loadAllDefs(loader: _fileLoader);
  });

  test('生产敌人 source 全部解析为已登记透明 standee，portrait fallback 为 0', () {
    final sources = <String>{
      for (final stage in repo.stageDefs.values)
        for (final enemy in stage.enemyTeam)
          if (enemy.iconPath.isNotEmpty) enemy.iconPath,
      for (final floor in repo.towerFloors)
        for (final enemy in floor.enemyTeam)
          if (enemy.iconPath.isNotEmpty) enemy.iconPath,
      for (final team in [
        ...?repo.expeditionConfig?.normalEnemyTeams,
        ...?repo.expeditionConfig?.eliteEnemyTeams,
      ])
        for (final enemy in team.enemies)
          if (enemy.iconPath.isNotEmpty) enemy.iconPath,
      for (final team in [...?repo.bossGauntletConfig?.enemyTeams.values])
        for (final enemy in team)
          if (enemy.iconPath.isNotEmpty) enemy.iconPath,
    };

    expect(sources.length, greaterThanOrEqualTo(145));
    for (final source in sources) {
      final resolution = resolveBattleStandeeAsset(
        sourcePath: source,
        teamSide: 1,
        slotIndex: 0,
      );
      expect(
        registeredBattleStandeeSourcePaths,
        contains(source),
        reason: '$source 未登记 source→standee 角色',
      );
      expect(
        resolution.displayRole,
        BattleCharacterAssetRole.stageStandee,
        reason: source,
      );
      expect(resolution.displayPath, isNotNull, reason: source);
      expect(resolution.usesPortraitAsStandee, isFalse, reason: source);
    }
  });

  test('所有可出战玩家 portrait 均不会直接铺到战场', () {
    final playerPortraits = <String>{
      for (final master in repo.masters)
        if (master.portraitPath != null) master.portraitPath!,
      for (final candidate in repo.recruitCandidates.values)
        if (candidate.portraitPath != null) candidate.portraitPath!,
      for (final candidate in repo.sectCandidates.values)
        if (candidate.portraitPath != null) candidate.portraitPath!,
    };
    final identitySilhouettes = <String>{};
    var playerSlotIndex = 0;

    for (final source in playerPortraits) {
      final resolution = resolveBattleStandeeAsset(
        sourcePath: source,
        teamSide: 0,
        slotIndex: playerSlotIndex++,
      );
      expect(resolution.usesPortraitAsStandee, isFalse, reason: source);
      expect(
        resolution.displayRole,
        isNot(BattleCharacterAssetRole.sourcePortrait),
        reason: source,
      );
      if (resolution.displayRole ==
          BattleCharacterAssetRole.identitySilhouette) {
        identitySilhouettes.add(source);
        expect(resolution.displayPath, isNotNull, reason: source);
      }
    }

    expect(identitySilhouettes, {
      'assets/characters/recruit_candidate_a.png',
      'assets/characters/recruit_candidate_b.png',
      'assets/characters/recruit_candidate_c.png',
      'assets/characters/sect_candidate_bamboo.png',
      'assets/characters/sect_candidate_blacksmith.png',
      'assets/characters/sect_candidate_desert.png',
      'assets/characters/sect_candidate_mountain.png',
      'assets/characters/sect_candidate_river.png',
      'assets/characters/sect_candidate_valley.png',
    }, reason: '这 9 项是明确记录的专用 standee 美术缺口；补图时需同步更新门禁。');
  });

  test('全部登记 standee 满足透明、留边、最小尺寸与脚底标定', () async {
    final violations = <String>[];

    // 2026-07-26 Ch17 批新增:跳过「已登记但美术未交付」的 standee。
    // 背景——本测 2026-07-25 加入,晚于 Ch16 美术批,故从未见过「章批已落、出图批
    // 未跑」的中间态;Ch17 是第一个撞上的章批(章批与美术批历来分两次,见 5441ea3d
    // vs 589457cf)。跳过依据复用 asset_audit 的同一份 allowlist,不是本测私开口子:
    // 出图后 asset_audit guard 2「allowlist 无已补齐残留」会强制删表项,表项一删本
    // 测立刻恢复全量把关,构成双向棘轮、无法长期挂账。
    final pendingArt = loadAllowlist();

    for (final path in registeredBattleStandeeDisplayPaths) {
      if (pendingArt.contains(path)) continue;
      final profile = await _readAlphaProfile(path);

      void require(bool condition, String message) {
        if (!condition) violations.add('$path · $message');
      }

      require(profile.width >= 512, '宽度 ${profile.width} < 512');
      require(profile.height >= 768, '高度 ${profile.height} < 768');
      require(profile.visiblePixels > 0, '无有效像素');
      require(
        profile.maxCornerAlpha <= 16,
        '角落最大 alpha ${profile.maxCornerAlpha} > 16',
      );
      require(profile.left > 0, '左缘裁切（left=${profile.left}）');
      require(profile.top > 0, '顶缘裁切（top=${profile.top}）');
      require(
        profile.right < profile.width - 1,
        '右缘裁切（right=${profile.right}）',
      );
      require(
        profile.bottom < profile.height - 1,
        '脚底裁切（bottom=${profile.bottom}）',
      );
      require(
        profile.boundingHeight / profile.boundingWidth > 0.78,
        '有效人物比例 ${(profile.boundingHeight / profile.boundingWidth).toStringAsFixed(3)} <= 0.78',
      );
      final configuredFoot = battleStandeeFootFraction(path);
      final footDelta = (configuredFoot - profile.footFraction).abs();
      require(
        footDelta <= 0.035,
        '脚底标定漂移 ${footDelta.toStringAsFixed(4)} > 0.035'
        '（配置 ${configuredFoot.toStringAsFixed(4)}，实测 ${profile.footFraction.toStringAsFixed(4)}）',
      );
    }

    expect(
      violations,
      isEmpty,
      reason: 'standee 角色门禁失败：\n${violations.join('\n')}',
    );
  });
}

class _AlphaProfile {
  const _AlphaProfile({
    required this.width,
    required this.height,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.visiblePixels,
    required this.maxCornerAlpha,
  });

  final int width;
  final int height;
  final int left;
  final int top;
  final int right;
  final int bottom;
  final int visiblePixels;
  final int maxCornerAlpha;

  int get boundingWidth => right - left + 1;
  int get boundingHeight => bottom - top + 1;
  double get footFraction => (bottom + 1) / height;
}

Future<_AlphaProfile> _readAlphaProfile(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) {
    image.dispose();
    codec.dispose();
    throw StateError('$path 无法读取 RGBA 像素');
  }
  final rgba = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final width = image.width;
  final height = image.height;
  var left = width;
  var top = height;
  var right = -1;
  var bottom = -1;
  var visiblePixels = 0;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final alpha = rgba[(y * width + x) * 4 + 3];
      if (alpha <= 16) continue;
      visiblePixels++;
      if (x < left) left = x;
      if (x > right) right = x;
      if (y < top) top = y;
      if (y > bottom) bottom = y;
    }
  }

  int alphaAt(int x, int y) => rgba[(y * width + x) * 4 + 3];
  final maxCornerAlpha = [
    alphaAt(0, 0),
    alphaAt(width - 1, 0),
    alphaAt(0, height - 1),
    alphaAt(width - 1, height - 1),
  ].reduce((a, b) => a > b ? a : b);

  image.dispose();
  codec.dispose();
  return _AlphaProfile(
    width: width,
    height: height,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    visiblePixels: visiblePixels,
    maxCornerAlpha: maxCornerAlpha,
  );
}
