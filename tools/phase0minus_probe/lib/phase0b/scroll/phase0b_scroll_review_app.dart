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
    this.mirror = false,
  });

  final int id;
  final _ReviewActorKind kind;
  final Offset position;
  final int pose;
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

  final Set<LogicalKeyboardKey> _keys = {};
  final List<_ReviewActor> _enemies = _buildEnemies();
  ui.Image? _background;
  ui.Image? _founder;
  ui.Image? _bandit;
  ui.Image? _elite;
  Offset _hero = const Offset(420, 510);
  double _cameraLeft = 0;
  double _autoDirection = 1;
  bool _manualInputSeen = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    images.prefix = 'assets/';
    _background = await images.load(
      'phase0b/runtime/mountain_pass_background_v2.png',
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
      horizontal = _autoDirection;
      if (_hero.dx >= worldWidth - 420) _autoDirection = -1;
      if (_hero.dx <= 420) _autoDirection = 1;
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

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final background = _background;
    final founder = _founder;
    final bandit = _bandit;
    final elite = _elite;
    if (background == null ||
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
    _drawBackground(canvas, background);
    final actors =
        <_ReviewActor>[
          ..._enemies.where(
            (actor) =>
                actor.position.dx >= _cameraLeft - 220 &&
                actor.position.dx <= _cameraLeft + viewWidth + 220,
          ),
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
      _drawActor(canvas, actor, founder, bandit, elite);
    }
    _drawRegionProgress(canvas);
    canvas.restore();
  }

  void _drawBackground(Canvas canvas, ui.Image background) {
    final source = Rect.fromLTWH(
      0,
      0,
      background.width.toDouble(),
      background.height.toDouble(),
    );
    canvas.drawImageRect(
      background,
      source,
      Rect.fromLTWH(-_cameraLeft, 0, worldWidth, viewHeight),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  void _drawActor(
    Canvas canvas,
    _ReviewActor actor,
    ui.Image founder,
    ui.Image bandit,
    ui.Image elite,
  ) {
    var displayPosition = actor.position;
    if (actor.kind == _ReviewActorKind.bandit) {
      final dx = displayPosition.dx - _hero.dx;
      final dy = displayPosition.dy - _hero.dy;
      if (dx.abs() < 112 && dy.abs() < 78) {
        displayPosition = Offset(
          _hero.dx + (dx < 0 || (dx == 0 && actor.id.isEven) ? -112 : 112),
          displayPosition.dy,
        );
      }
    }
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
      for (var index = 0; index < count; index++) {
        final row = index % 5;
        final column = index ~/ 5;
        actors.add(
          _ReviewActor(
            id: id++,
            kind: _ReviewActorKind.bandit,
            position: Offset(
              centerX + (column - 1.5) * 118 + (row.isEven ? -32 : 34),
              395 + row * 50 + region * 3,
            ),
            pose: index % 4,
            mirror: index.isEven,
          ),
        );
      }
    }

    addCluster(930, 6, 0);
    addCluster(1880, 10, 1);
    addCluster(3000, 20, 2);
    actors.add(
      const _ReviewActor(
        id: 998,
        kind: _ReviewActorKind.elite,
        position: Offset(3290, 520),
        pose: 1,
        mirror: true,
      ),
    );
    return actors;
  }
}
