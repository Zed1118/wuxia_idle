import 'dart:ui';

import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import 'phase0a_presentation_tokens.dart';

/// Phase 0A 舞台:世界坐标 → 屏幕坐标变换、纵深缩放与绘制排序。
///
/// 纯几何映射,不做任何战斗结算;世界范围与边距全部取自
/// [Phase0aPresentationTokens]。
final class Phase0aStage {
  Phase0aStage({required this.viewport, ArenaVector? cameraCenter})
    : _cameraCenter = cameraCenter;

  /// 当前视口尺寸(像素)。
  final Size viewport;

  /// null 保持完整 arena 投影；生产 battle screen 传玩家脚点，启用 75%
  /// camera-aware 视野。camera 只改变表现投影，不改变 domain arena。
  ArenaVector? _cameraCenter;

  ArenaVector? get cameraCenter => _cameraCenter;

  /// 同一帧几何见证可在战斗状态推进后更新玩家脚点，避免重建 viewport
  /// 相关对象；生产 build 仍通过构造参数逐帧提供同一权威中心。
  void updateCameraCenter(ArenaVector center) {
    _cameraCenter = center;
  }

  /// 世界可活动范围(token 直引,视口无关)。
  ArenaVector get worldMin => Phase0aPresentationTokens.worldMin;

  ArenaVector get worldMax => Phase0aPresentationTokens.worldMax;

  /// 扣除内边距后的安全绘制区。
  Rect get safeRect => Rect.fromLTRB(
    Phase0aPresentationTokens.safeMarginHorizontal,
    Phase0aPresentationTokens.safeMarginVertical,
    viewport.width - Phase0aPresentationTokens.safeMarginHorizontal,
    viewport.height - Phase0aPresentationTokens.safeMarginVertical,
  );

  /// 当前可见的世界矩形。跟随中心在 arena 边缘会被 clamp，保证视野不越界。
  Rect get cameraWorldRect {
    final fullWidth = worldMax.x - worldMin.x;
    final fullHeight = worldMax.y - worldMin.y;
    final fraction = cameraCenter == null
        ? 1.0
        : Phase0aPresentationTokens.cameraWorldFraction;
    final width = fullWidth * fraction;
    final height = fullHeight * fraction;
    final halfWidth = width / 2;
    final halfHeight = height / 2;
    final requested =
        cameraCenter ??
        ArenaVector(
          (worldMin.x + worldMax.x) / 2,
          (worldMin.y + worldMax.y) / 2,
        );
    final centerX = requested.x.clamp(
      worldMin.x + halfWidth,
      worldMax.x - halfWidth,
    );
    final centerY = requested.y.clamp(
      worldMin.y + halfHeight,
      worldMax.y - halfHeight,
    );
    return Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: width,
      height: height,
    );
  }

  double get cameraWorldDiagonal {
    final rect = cameraWorldRect;
    return Offset(rect.width, rect.height).distance;
  }

  /// 世界点相对当前 camera 线性投影。故意不 clamp：camera 外脚点必须保留
  /// 真实方向，供屏外提示与被 Stack 裁切的 actor/VFX 共用。
  Offset worldToScreen(ArenaVector world) {
    final rect = safeRect;
    final camera = cameraWorldRect;
    final tx = camera.width == 0 ? 0.0 : (world.x - camera.left) / camera.width;
    final ty = camera.height == 0
        ? 0.0
        : (world.y - camera.top) / camera.height;
    final inset = Phase0aPresentationTokens.screenEdgeInset;
    final dx = rect.left + tx * (rect.width - inset);
    final dy = rect.top + ty * (rect.height - inset);
    return Offset(dx, dy);
  }

  bool isWorldPointVisible(ArenaVector world) =>
      safeRect.contains(worldToScreen(world));

  /// 屏幕点击位置 → 世界坐标。safeRect 外输入先 clamp，保证窗口边缘点击
  /// 仍产生有限、可复现的世界方向；与 [worldToScreen] 使用同一线性变换。
  ArenaVector screenToWorld(Offset screen) {
    final rect = safeRect;
    final inset = Phase0aPresentationTokens.screenEdgeInset;
    final projectionWidth = rect.width - inset;
    final projectionHeight = rect.height - inset;
    final dx = screen.dx.clamp(rect.left, rect.right - inset);
    final dy = screen.dy.clamp(rect.top, rect.bottom - inset);
    final tx = projectionWidth == 0 ? 0.0 : (dx - rect.left) / projectionWidth;
    final ty = projectionHeight == 0 ? 0.0 : (dy - rect.top) / projectionHeight;
    final camera = cameraWorldRect;
    return ArenaVector(
      camera.left + tx * camera.width,
      camera.top + ty * camera.height,
    );
  }

  /// 纵深缩放:世界 y 越大单位越大,在线性插值区间内取值。
  double depthScale(double worldY) {
    final spanY = worldMax.y - worldMin.y;
    final t = spanY == 0 ? 0.0 : (worldY - worldMin.y) / spanY;
    const min = Phase0aPresentationTokens.depthScaleMin;
    const max = Phase0aPresentationTokens.depthScaleMax;
    return min + t.clamp(0.0, 1.0) * (max - min);
  }

  /// 绘制排序:y 升序(远处先画、近处后画并覆盖),
  /// y 相同按语义 id 字典序,保证逐帧确定。
  List<Phase0aActor> sortActors(
    List<Phase0aActor> actors, {
    ArenaVector Function(Phase0aActor actor)? positionOf,
  }) {
    final sorted = List<Phase0aActor>.of(actors);
    sorted.sort((a, b) {
      final byY = (positionOf?.call(a) ?? a.position).y.compareTo(
        (positionOf?.call(b) ?? b.position).y,
      );
      return byY != 0 ? byY : a.id.compareTo(b.id);
    });
    return sorted;
  }
}
