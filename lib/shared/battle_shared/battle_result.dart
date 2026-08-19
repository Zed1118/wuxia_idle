/// 战斗结果枚举(2026-08-19 共享层拆分迁移批自 `battle/domain/battle_state.dart` 提取,
/// 防 shared 层反向依赖 battle 引擎;`battle_state.dart` re-export 保持旧 import 口径不破)。
enum BattleResult { leftWin, rightWin, draw }
