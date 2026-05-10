/// 全局配置仓储（yaml 加载到内存的所有 Def）。
///
/// **占位实现**：T07 才会真正读 yaml。当前提供空的 [loadAllDefs] 让 main
/// 启动序可以照预定流程走。Phase 1 后续任务会逐步填实。
class GameRepository {
  /// 启动时一次性加载全部 yaml 配置。当前空实现。
  static Future<void> loadAllDefs() async {
    // TODO T07: 加载 numbers.yaml / equipment.yaml / techniques.yaml /
    // stages.yaml / encounters.yaml 等到内存。
  }
}
