import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flutter/material.dart';

enum GameplayActorArt { founder, bandit, elite }

final class GameplayArt {
  const GameplayArt({
    required this.panorama,
    required this.founder,
    required this.bandit,
    required this.elite,
  });

  final ui.Image panorama;
  final ui.Image founder;
  final ui.Image bandit;
  final ui.Image elite;

  static Future<GameplayArt> load(Images images) async {
    images.prefix = 'assets/';
    return GameplayArt(
      panorama: await images.load(
        'phase0b/runtime/scroll_panorama_mountain_to_gate_v1.png',
      ),
      founder: await images.load('phase0b/runtime/founder_pose_atlas_v1.png'),
      bandit: await images.load('phase0b/runtime/bandit_pose_atlas_v1.png'),
      elite: await images.load('phase0b/runtime/elite_pose_atlas_v1.png'),
    );
  }

  void drawPanorama(Canvas canvas, Size size) {
    canvas.drawImageRect(
      panorama,
      Rect.fromLTWH(
        0,
        0,
        panorama.width.toDouble(),
        panorama.height.toDouble(),
      ),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0x24181310),
    );
  }

  void drawActor(
    Canvas canvas, {
    required GameplayActorArt actor,
    required int pose,
    required Offset foot,
    required double height,
    required bool mirror,
    double opacity = 1,
    bool flash = false,
  }) {
    final atlas = switch (actor) {
      GameplayActorArt.founder => founder,
      GameplayActorArt.bandit => bandit,
      GameplayActorArt.elite => elite,
    };
    final columns = actor == GameplayActorArt.elite ? 2 : 3;
    final rowDivider = actor == GameplayActorArt.bandit ? 500 / 941 : 0.5;
    final source = atlasCellRect(
      atlas,
      pose.clamp(0, columns * 2 - 1),
      columns: columns,
      rowDividerRatio: rowDivider,
    );
    final width = height * source.width / source.height;
    final bottomBleed = switch (actor) {
      GameplayActorArt.founder => height * 0.13,
      GameplayActorArt.bandit => height * 0.10,
      GameplayActorArt.elite => height * 0.08,
    };

    canvas.drawOval(
      Rect.fromCenter(
        center: foot.translate(0, -2),
        width: width * 0.46,
        height: height * 0.075,
      ),
      Paint()
        ..color = Color.fromRGBO(25, 22, 18, 0.34 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: foot.translate(0, -1),
        width: width * 0.29,
        height: height * 0.035,
      ),
      Paint()..color = Color.fromRGBO(22, 19, 16, 0.48 * opacity),
    );

    canvas.save();
    canvas.translate(foot.dx, foot.dy);
    if (mirror) canvas.scale(-1, 1);
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..color = Color.fromRGBO(255, 255, 255, opacity);
    if (flash) {
      paint.colorFilter = const ColorFilter.mode(
        Color(0xFFF7E8C8),
        BlendMode.modulate,
      );
    }
    canvas.drawImageRect(
      atlas,
      source,
      Rect.fromLTWH(-width / 2, -height + bottomBleed, width, height),
      paint,
    );
    canvas.restore();
  }

  static Rect atlasCellRect(
    ui.Image atlas,
    int pose, {
    required int columns,
    required double rowDividerRatio,
  }) {
    final column = pose % columns;
    final row = pose ~/ columns;
    final left = atlas.width * column / columns;
    final divider = atlas.height * rowDividerRatio;
    return Rect.fromLTRB(
      left,
      row == 0 ? 0 : divider,
      atlas.width * (column + 1) / columns,
      row == 0 ? divider : atlas.height.toDouble(),
    );
  }
}
