import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phase0minus_probe/phase0b/phase0b_runtime_app.dart';

final class Phase0bScrollReviewApp extends StatelessWidget {
  const Phase0bScrollReviewApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF171815),
      body: Stack(
        children: [
          Positioned.fill(
            child: GameWidget<Phase0bScrollReviewGame>(
              game: Phase0bScrollReviewGame(),
            ),
          ),
          const Positioned(
            left: 18,
            top: 14,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xD9181916)),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'SCROLLING WORLD REVIEW · 3 SCREENS · WASD\n'
                    'AUTO TOUR STOPS ON INPUT / NOT FINAL MAP ART',
                    style: TextStyle(color: Color(0xFFECE2CD), fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

enum _ReviewActorKind { bandit, hero, elite }

final class _ReviewActor {
  const _ReviewActor({
    required this.id,
    required this.kind,
    required this.position,
    required this.pose,
    this.region = -1,
    this.spawnDelay = 0,
    this.spawnPosition,
    this.mirror = false,
  });

  final int id;
  final _ReviewActorKind kind;
  final Offset position;
  final int pose;
  final int region;
  final double spawnDelay;
  final Offset? spawnPosition;
  final bool mirror;
}

final class Phase0bScrollReviewGame extends FlameGame with KeyboardEvents {
  static const worldWidth = 3600.0;
  static const viewWidth = 1280.0;
  static const viewHeight = 720.0;
  static const combatTop = 365.0;
  static const combatBottom = 640.0;
  static const leftDeadZone = 455.0;
  static const rightDeadZone = 765.0;
  static const encounterTriggers = [620.0, 1450.0, 2630.0];
  static const encounterHoldSeconds = [3.2, 4.0, 5.5];

  final Set<LogicalKeyboardKey> _keys = {};
  final List<_ReviewActor> _enemies = _buildEnemies();
  ui.Image? _background;
  ui.Image? _founder;
  ui.Image? _bandit;
  ui.Image? _elite;
  Offset _hero = const Offset(420, 510);
  double _cameraLeft = 0;
  bool _manualInputSeen = false;
  final List<double?> _encounterStartedAt = [null, null, null];
  double _tourElapsed = 0;
  double _autoHoldRemaining = 0;
  int _nextEncounter = 0;
  final List<int> observedEncounterPeaks = [0, 0, 0];
  double finalPeakVisibleSeconds = 0;

  double get cameraWorldX => _cameraLeft;
  double get heroWorldX => _hero.dx;
  int get activeEnemyCount => _activeEnemies().length;
  int get visibleEnemyCount => _activeEnemies()
      .where(
        (actor) =>
            actor.position.dx >= _cameraLeft &&
            actor.position.dx <= _cameraLeft + viewWidth,
      )
      .length;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    images.prefix = 'assets/';
    _background = await images.load(
      'phase0b/runtime/scroll_panorama_mountain_to_gate_v1.png',
    );
    _founder = await images.load('phase0b/runtime/founder_pose_atlas_v1.png');
    _bandit = await images.load('phase0b/runtime/bandit_pose_atlas_v1.png');
    _elite = await images.load('phase0b/runtime/elite_pose_atlas_v1.png');
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _keys
      ..clear()
      ..addAll(keysPressed);
    if (keysPressed.isNotEmpty) _manualInputSeen = true;
    return KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _tourElapsed += dt;
    _activateDueEncounter();
    var horizontal = 0.0;
    var vertical = 0.0;
    if (_manualInputSeen) {
      if (_pressed(LogicalKeyboardKey.keyA, LogicalKeyboardKey.arrowLeft)) {
        horizontal -= 1;
      }
      if (_pressed(LogicalKeyboardKey.keyD, LogicalKeyboardKey.arrowRight)) {
        horizontal += 1;
      }
      if (_pressed(LogicalKeyboardKey.keyW, LogicalKeyboardKey.arrowUp)) {
        vertical -= 1;
      }
      if (_pressed(LogicalKeyboardKey.keyS, LogicalKeyboardKey.arrowDown)) {
        vertical += 1;
      }
    } else {
      horizontal = _autoHoldRemaining > 0 ? 0 : 1;
      _autoHoldRemaining = math.max(0, _autoHoldRemaining - dt);
      if (_hero.dx >= worldWidth - 420) _resetAutoTour();
    }
    final length = math.sqrt(horizontal * horizontal + vertical * vertical);
    if (length > 0) {
      horizontal /= length;
      vertical /= length;
      _hero = Offset(
        (_hero.dx + horizontal * 320 * dt).clamp(80, worldWidth - 80),
        (_hero.dy + vertical * 220 * dt).clamp(combatTop, combatBottom),
      );
    }
    _cameraLeft = nextCameraLeft(_cameraLeft, _hero.dx, dt);
    for (var region = 0; region < _encounterStartedAt.length; region++) {
      final startedAt = _encounterStartedAt[region];
      if (startedAt == null) continue;
      observedEncounterPeaks[region] = math.max(
        observedEncounterPeaks[region],
        activePopulationAt(region, _tourElapsed - startedAt),
      );
    }
    if (_nextEncounter == 3 && visibleEnemyCount == 21) {
      finalPeakVisibleSeconds += dt;
    }
  }

  void _resetAutoTour() {
    _hero = const Offset(420, 510);
    _cameraLeft = 0;
    _tourElapsed = 0;
    _autoHoldRemaining = 0;
    _nextEncounter = 0;
    for (var index = 0; index < _encounterStartedAt.length; index++) {
      _encounterStartedAt[index] = null;
    }
  }

  void _activateDueEncounter() {
    if (_nextEncounter >= encounterTriggers.length) return;
    if (_hero.dx < encounterTriggers[_nextEncounter]) return;
    _encounterStartedAt[_nextEncounter] = _tourElapsed;
    if (!_manualInputSeen) {
      _autoHoldRemaining = encounterHoldSeconds[_nextEncounter];
    }
    _nextEncounter++;
  }

  bool _pressed(LogicalKeyboardKey first, LogicalKeyboardKey second) =>
      _keys.contains(first) || _keys.contains(second);

  @visibleForTesting
  static double nextCameraLeft(
    double current,
    double heroX, [
    double dt = 1 / 60,
  ]) {
    final screenX = heroX - current;
    var target = current;
    if (screenX < leftDeadZone) target = heroX - leftDeadZone;
    if (screenX > rightDeadZone) target = heroX - rightDeadZone;
    target = target.clamp(0, worldWidth - viewWidth);
    final alpha = 1 - math.exp(-dt / 0.12);
    return current + (target - current) * alpha;
  }

  @visibleForTesting
  static List<int> encounterPopulationByRegion() => const [6, 10, 21];

  @visibleForTesting
  static int spawnedPopulationAt(int region, double elapsed) => _buildEnemies()
      .where((actor) => actor.region == region && actor.spawnDelay <= elapsed)
      .length;

  @visibleForTesting
  static int activePopulationAt(int region, double elapsed) =>
      elapsed >= encounterHoldSeconds[region] - 0.35
      ? 0
      : spawnedPopulationAt(region, elapsed);

  List<_ReviewActor> _activeEnemies() =>
      _enemies.map(_activeActorFrame).whereType<_ReviewActor>().toList();

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final founder = _founder;
    final bandit = _bandit;
    final elite = _elite;
    if (_background == null ||
        founder == null ||
        bandit == null ||
        elite == null) {
      return;
    }
    final scale = math.min(size.x / viewWidth, size.y / viewHeight);
    final content = Rect.fromLTWH(
      (size.x - viewWidth * scale) / 2,
      (size.y - viewHeight * scale) / 2,
      viewWidth * scale,
      viewHeight * scale,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.black,
    );
    canvas.save();
    canvas.translate(content.left, content.top);
    canvas.scale(scale);
    canvas.clipRect(const Rect.fromLTWH(0, 0, viewWidth, viewHeight));
    _drawBackground(canvas);
    final activeEnemies = _activeEnemies().where(
      (actor) =>
          actor.position.dx >= _cameraLeft - 220 &&
          actor.position.dx <= _cameraLeft + viewWidth + 220,
    );
    final actors =
        <_ReviewActor>[
          ...activeEnemies,
          _ReviewActor(
            id: 999,
            kind: _ReviewActorKind.hero,
            position: _hero,
            pose: _manualInputSeen && _keys.isNotEmpty ? 1 : 0,
          ),
        ]..sort((a, b) {
          final depth = a.position.dy.compareTo(b.position.dy);
          return depth != 0 ? depth : a.id.compareTo(b.id);
        });
    for (final actor in actors) {
      _drawActorShadow(canvas, actor);
    }
    for (final actor in actors) {
      _drawActor(canvas, actor, founder, bandit, elite);
    }
    _drawRegionProgress(canvas);
    canvas.restore();
  }

  _ReviewActor? _activeActorFrame(_ReviewActor actor) {
    final startedAt = actor.region < 0
        ? 0.0
        : _encounterStartedAt[actor.region];
    if (startedAt == null) return null;
    final encounterElapsed = _tourElapsed - startedAt;
    final localElapsed = encounterElapsed - actor.spawnDelay;
    if (localElapsed < 0) return null;
    if (encounterElapsed >= encounterHoldSeconds[actor.region] - 0.35) {
      return null;
    }
    final progress = (localElapsed / 0.75).clamp(0, 1).toDouble();
    final eased = Curves.easeOutCubic.transform(progress);
    final entryPosition = Offset.lerp(
      actor.spawnPosition ?? actor.position,
      actor.position,
      eased,
    )!;
    return _ReviewActor(
      id: actor.id,
      kind: actor.kind,
      position: applyReadabilityPocket(entryPosition, _hero, actor.id),
      pose: progress < 1 ? 1 : actor.pose,
      mirror: actor.mirror,
      region: actor.region,
      spawnDelay: actor.spawnDelay,
      spawnPosition: actor.spawnPosition,
    );
  }

  void _drawBackground(Canvas canvas) {
    final image = _background!;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(-_cameraLeft, 0, worldWidth, viewHeight),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  void _drawActorShadow(Canvas canvas, _ReviewActor actor) {
    final size = switch (actor.kind) {
      _ReviewActorKind.hero => const Size(52, 11),
      _ReviewActorKind.bandit => const Size(40, 8),
      _ReviewActorKind.elite => const Size(58, 12),
    };
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(actor.position.dx - _cameraLeft, actor.position.dy - 2),
        width: size.width,
        height: size.height,
      ),
      Paint()..color = const Color(0x3325221D),
    );
  }

  void _drawActor(
    Canvas canvas,
    _ReviewActor actor,
    ui.Image founder,
    ui.Image bandit,
    ui.Image elite,
  ) {
    final displayPosition = actor.position;
    final atlas = switch (actor.kind) {
      _ReviewActorKind.hero => founder,
      _ReviewActorKind.bandit => bandit,
      _ReviewActorKind.elite => elite,
    };
    final source = Phase0bRuntimeGame.atlasCellRect(
      atlas,
      actor.pose,
      rowDividerRatio: actor.kind == _ReviewActorKind.bandit ? 500 / 941 : 0.5,
      columns: actor.kind == _ReviewActorKind.elite ? 2 : 3,
      rows: 2,
    );
    final perspective = ui.lerpDouble(
      0.80,
      1.06,
      ((displayPosition.dy - combatTop) / (combatBottom - combatTop)).clamp(
        0,
        1,
      ),
    )!;
    final baseHeight = switch (actor.kind) {
      _ReviewActorKind.hero => 166.0,
      _ReviewActorKind.bandit => 130.0,
      _ReviewActorKind.elite => 182.0,
    };
    final height = baseHeight * perspective;
    final width = height * source.width / source.height;
    canvas.save();
    canvas.translate(displayPosition.dx - _cameraLeft, displayPosition.dy);
    if (actor.mirror) canvas.scale(-1, 1);
    canvas.drawImageRect(
      atlas,
      source,
      Rect.fromLTWH(-width / 2, -height, width, height),
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }

  void _drawRegionProgress(Canvas canvas) {
    final progress = (_hero.dx / worldWidth).clamp(0, 1).toDouble();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(500, 684, 280, 5),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0x552C2A24),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(500, 684, 280 * progress, 5),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xCCDED2B8),
    );
  }

  static List<_ReviewActor> _buildEnemies() {
    final actors = <_ReviewActor>[];
    var id = 0;
    void addCluster(double centerX, int count, int region) {
      final rows = count >= 10 ? 4 : 3;
      final columns = (count / rows).ceil();
      for (var index = 0; index < count; index++) {
        final row = index % rows;
        final column = index ~/ rows;
        final target = Offset(
          centerX +
              (column - (columns - 1) / 2) * 135 +
              (row.isEven ? -26 : 26),
          405 + row * 62 + region * 3,
        );
        final firstBatchCount = switch (region) {
          0 => 4,
          1 => 5,
          _ => 12,
        };
        final secondBatchDelay = switch (region) {
          0 => 0.7,
          1 => 0.8,
          _ => 0.9,
        };
        final fromLeft = index % 4 == 0;
        actors.add(
          _ReviewActor(
            id: id++,
            kind: _ReviewActorKind.bandit,
            position: target,
            pose: index % 4,
            region: region,
            spawnDelay: index < firstBatchCount
                ? index * 0.06
                : secondBatchDelay,
            spawnPosition: Offset(
              fromLeft ? centerX - 760 : centerX + 760,
              target.dy + (index.isEven ? -35 : 32),
            ),
            mirror: index.isEven,
          ),
        );
      }
    }

    addCluster(700, 6, 0);
    addCluster(1540, 10, 1);
    addCluster(2700, 20, 2);
    actors.add(
      const _ReviewActor(
        id: 998,
        kind: _ReviewActorKind.elite,
        position: Offset(2990, 520),
        pose: 1,
        region: 2,
        spawnDelay: 1.2,
        spawnPosition: Offset(3650, 470),
        mirror: true,
      ),
    );
    return actors;
  }

  @visibleForTesting
  static Offset applyReadabilityPocket(
    Offset enemyPosition,
    Offset heroPosition,
    int actorId,
  ) {
    final dx = enemyPosition.dx - heroPosition.dx;
    final dy = enemyPosition.dy - heroPosition.dy;
    if (dx.abs() >= 112 || dy.abs() >= 78) return enemyPosition;
    return Offset(
      heroPosition.dx + (dx < 0 || (dx == 0 && actorId.isEven) ? -112 : 112),
      enemyPosition.dy,
    );
  }
}
