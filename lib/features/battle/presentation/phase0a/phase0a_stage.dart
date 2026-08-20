import 'dart:ui';

import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import 'phase0a_presentation_tokens.dart';

/// Phase 0A 舞台:世界坐标 → 屏幕坐标变换、纵深缩放与绘制排序。
///
/// 纯几何映射,不做任何战斗结算;世界范围与边距全部取自
/// [Phase0aPresentationTokens]。
final class Phase0aStage {
  Phase0aStage({required this.viewport});

  /// 当前视口尺寸(像素)。
  final Size viewport;

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

  /// 世界点线性映射到 safeRect 内;右/下边界按 token 内缩,
  /// 保证世界四角均落在 safeRect 半开区间内。
  Offset worldToScreen(ArenaVector world) {
    final rect = safeRect;
    final spanX = worldMax.x - worldMin.x;
    final spanY = worldMax.y - worldMin.y;
    final tx = spanX == 0 ? 0.0 : (world.x - worldMin.x) / spanX;
    final ty = spanY == 0 ? 0.0 : (world.y - worldMin.y) / spanY;
    final inset = Phase0aPresentationTokens.screenEdgeInset;
    final dx = (rect.left + tx * rect.width).clamp(
      rect.left,
      rect.right - inset,
    );
    final dy = (rect.top + ty * rect.height).clamp(
      rect.top,
      rect.bottom - inset,
    );
    return Offset(dx, dy);
  }

  /// 屏幕点击位置 → 世界坐标。safeRect 外输入先 clamp，保证窗口边缘点击
  /// 仍产生有限、可复现的世界方向；与 [worldToScreen] 使用同一线性变换。
  ArenaVector screenToWorld(Offset screen) {
    final rect = safeRect;
    final dx = screen.dx.clamp(rect.left, rect.right);
    final dy = screen.dy.clamp(rect.top, rect.bottom);
    final tx = rect.width == 0 ? 0.0 : (dx - rect.left) / rect.width;
    final ty = rect.height == 0 ? 0.0 : (dy - rect.top) / rect.height;
    return ArenaVector(
      worldMin.x + tx * (worldMax.x - worldMin.x),
      worldMin.y + ty * (worldMax.y - worldMin.y),
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

  /// 绘制排序:y 升序(近处先画、远处后画由调用方按序覆盖),
  /// y 相同按语义 id 字典序,保证逐帧确定。
  List<Phase0aActor> sortActors(List<Phase0aActor> actors) {
    final sorted = List<Phase0aActor>.of(actors);
    sorted.sort((a, b) {
      final byY = a.position.y.compareTo(b.position.y);
      return byY != 0 ? byY : a.id.compareTo(b.id);
    });
    return sorted;
  }
}
