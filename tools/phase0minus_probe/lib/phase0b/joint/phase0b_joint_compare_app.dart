import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart' hide Matrix4;
import 'package:flutter/material.dart';
import 'package:phase0minus_probe/phase0b/joint/joint_rig_model.dart';
import 'package:phase0minus_probe/phase0b/phase0b_runtime_app.dart';

final class Phase0bJointCompareApp extends StatefulWidget {
  const Phase0bJointCompareApp({super.key});

  @override
  State<Phase0bJointCompareApp> createState() => _Phase0bJointCompareAppState();
}

final class _Phase0bJointCompareAppState extends State<Phase0bJointCompareApp> {
  late final Phase0bJointCompareGame game = Phase0bJointCompareGame();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF171815),
      body: Stack(
        children: [
          Positioned.fill(
            child: GameWidget<Phase0bJointCompareGame>(game: game),
          ),
          const Positioned(
            left: 20,
            top: 16,
            child: _RouteLabel(title: '左：整帧姿态图集', detail: '基准路线 · 离散切帧'),
          ),
          const Positioned(
            right: 20,
            top: 16,
            child: _RouteLabel(
              title: '右：分层关节木偶',
              detail: '零新依赖 · 无蒙皮 / IK / 网格变形',
              alignEnd: true,
            ),
          ),
          const Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: IgnorePointer(
              child: Text(
                '同一 3 秒时线：idle → basic → dash。'
                '本页只比较资产路线，不是最终动画品质或性能 Gate。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFECE2CD),
                  fontSize: 13,
                  shadows: [Shadow(color: Colors.black, blurRadius: 5)],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

final class _RouteLabel extends StatelessWidget {
  const _RouteLabel({
    required this.title,
    required this.detail,
    this.alignEnd = false,
  });

  final String title;
  final String detail;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xD9181916),
        border: Border.all(color: const Color(0x887B7568)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: alignEnd
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFF0E7D2),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: const TextStyle(color: Color(0xFFBDB6A8), fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

final class Phase0bJointCompareGame extends FlameGame {
  static const rigAsset = 'assets/phase0b/joint/founder_rig_v1.yaml';

  ui.Image? _background;
  ui.Image? _poseAtlas;
  ui.Image? _partsAtlas;
  JointRig? _rig;
  double _elapsed = 0;

  bool get assetsReady =>
      _background != null &&
      _poseAtlas != null &&
      _partsAtlas != null &&
      _rig != null;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    images.prefix = 'assets/';
    final rig = await JointRig.load(rigAsset);
    _rig = rig;
    _background = await images.load(
      'phase0b/runtime/mountain_pass_background_v1.webp',
    );
    _poseAtlas = await images.load('phase0b/runtime/founder_pose_atlas_v1.png');
    _partsAtlas = await images.load(
      'phase0b/runtime/founder_cutout_parts_v1.png',
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final rig = _rig;
    if (rig != null) _elapsed = (_elapsed + dt) % rig.duration;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final background = _background;
    final poseAtlas = _poseAtlas;
    final partsAtlas = _partsAtlas;
    final rig = _rig;
    if (background == null ||
        poseAtlas == null ||
        partsAtlas == null ||
        rig == null) {
      return;
    }

    canvas.drawImageRect(
      background,
      Rect.fromLTWH(
        0,
        0,
        background.width.toDouble(),
        background.height.toDouble(),
      ),
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0x4415100B),
    );

    final scale = math.min(size.x / 1280, size.y / 720);
    final contentWidth = 1280 * scale;
    final contentHeight = 720 * scale;
    final origin = Offset(
      (size.x - contentWidth) / 2,
      (size.y - contentHeight) / 2,
    );
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    canvas.drawLine(
      const Offset(640, 105),
      const Offset(640, 635),
      Paint()
        ..color = const Color(0x66756F63)
        ..strokeWidth = 1,
    );

    final baselinePose = switch (_elapsed) {
      < 0.82 => 0,
      < 1.72 => 1,
      < 2.65 => 2,
      _ => 0,
    };
    _drawWholePose(canvas, poseAtlas, baselinePose, const Offset(330, 570));
    _drawCutout(canvas, partsAtlas, rig, const Offset(930, 390), _elapsed);
    canvas.restore();
  }

  static void _drawWholePose(
    Canvas canvas,
    ui.Image atlas,
    int pose,
    Offset base,
  ) {
    final source = Phase0bRuntimeGame.atlasCellRect(atlas, pose);
    final height = 390.0;
    final width = height * source.width / source.height;
    canvas.drawImageRect(
      atlas,
      source,
      Rect.fromLTWH(base.dx - width / 2, base.dy - height, width, height),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  static void _drawCutout(
    Canvas canvas,
    ui.Image atlas,
    JointRig rig,
    Offset base,
    double time,
  ) {
    final pose = rig.sample(time);
    final byId = {for (final part in rig.parts) part.id: part};
    final transforms = <String, Matrix4>{};

    Matrix4 resolve(JointPart part) {
      final cached = transforms[part.id];
      if (cached != null) return cached;
      final parent = part.parent == null ? null : byId[part.parent];
      final parentMatrix = parent == null
          ? Matrix4.translationValues(
              base.dx + pose.rootOffset.dx,
              base.dy + pose.rootOffset.dy,
              0,
            )
          : resolve(parent);
      final local = Matrix4.translationValues(part.offset.dx, part.offset.dy, 0)
        ..rotateZ(pose.angles[part.id] ?? 0);
      final result = parentMatrix * local;
      transforms[part.id] = result;
      return result;
    }

    final ordered = [...rig.parts]
      ..sort((a, b) {
        final layer = a.layer.compareTo(b.layer);
        return layer != 0 ? layer : a.id.compareTo(b.id);
      });
    for (final part in ordered) {
      final destination = Rect.fromLTWH(
        -part.pivot.dx * part.size.width,
        -part.pivot.dy * part.size.height,
        part.size.width,
        part.size.height,
      );
      canvas.save();
      canvas.transform(resolve(part).storage);
      canvas.drawImageRect(
        atlas,
        part.source,
        destination,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    }
  }
}
