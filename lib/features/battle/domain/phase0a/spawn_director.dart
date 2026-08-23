/// Phase 0A SpawnDirector 纯 Dart 领域合同候选。
///
/// 把遭遇名单明确切分为 总量(total)/活跃(active)/后备(pending)，生成只来自
/// 显式入口；活跃数降至补兵阈值时按稳定 reserve 顺序补到 activeLimit；
/// 暴露入口预警(entry warning)与攻击宽限(attack grace)快照。
///
/// 引擎无关：不依赖 reducer、数据 loader、UI 或存档。所有 tuning 数值
/// （activeLimit / reinforcementThreshold / entryWarningTicks /
/// attackGraceTicks）均由调用方经 [SpawnDirectorConfig] 显式传入并在构造期
/// 严格校验，本文件不写任何 20%–30%、8–16 之类默认 tuning。
///
/// 合同要点：
/// - 入口列表构造时做防御性不可修改副本并排序，输入顺序无关；输出确定性且
///   不可变（快照/事件列表均不可变，advance/markExited 返回新 director）。
/// - entryId/enemyId 全量唯一（重复 fail closed），且非空、不含空白。
/// - 空入口列表 → 永不生成，仅推进 tick。
/// - 生命周期：pending → warning → active → removed（仅 active 可离场）。
/// - 补兵条件：activeCount <= reinforcementThreshold 且
///   activeCount + warningCount < activeLimit 且后备非空；预警拍大于 0 时
///   先进 warning，等于 0 时直接 active。
/// - 攻击宽限：上场当拍 remainingGraceTicks = attackGraceTicks，次拍起逐拍
///   递减；canAttack 仅当 stage == active 且 remainingGraceTicks == 0。
enum SpawnUnitStage { pending, warning, active, removed }

enum SpawnDirectorEventType { warningStarted, entered, graceExpired }

/// 生成导演配置：四个数值全部由调用方显式传入，构造期 fail-fast。
final class SpawnDirectorConfig {
  SpawnDirectorConfig({
    required this.activeLimit,
    required this.reinforcementThreshold,
    required this.entryWarningTicks,
    required this.attackGraceTicks,
  }) {
    if (activeLimit <= 0) {
      throw ArgumentError.value(activeLimit, 'activeLimit', 'must be positive');
    }
    if (reinforcementThreshold < 0 || reinforcementThreshold >= activeLimit) {
      throw ArgumentError.value(
        reinforcementThreshold,
        'reinforcementThreshold',
        'must be in [0, activeLimit)',
      );
    }
    if (entryWarningTicks < 0) {
      throw ArgumentError.value(
        entryWarningTicks,
        'entryWarningTicks',
        'must not be negative',
      );
    }
    if (attackGraceTicks < 0) {
      throw ArgumentError.value(
        attackGraceTicks,
        'attackGraceTicks',
        'must not be negative',
      );
    }
  }

  /// 同时在场（active + warning 管道）上限，必须为正。
  final int activeLimit;

  /// 活跃数降至该值及以下时触发补兵，须在 [0, activeLimit) 内。
  final int reinforcementThreshold;

  /// 单位被补入后、上场前的入口预警拍数；0 表示无预警直接上场。
  final int entryWarningTicks;

  /// 单位上场后的攻击宽限拍数；宽限期内 canAttack 为 false。
  final int attackGraceTicks;
}

/// 一个显式生成入口：什么敌人从哪个入口生成。
///
/// [entryId]/[enemyId] 全量唯一（重复 fail closed），且均须非空、
/// 不含任何空白字符。[enemyId] 表示敌人实例 ID；敌人类型应由后续
/// 数据合同以独立字段表达，不得复用实例 ID。
final class SpawnEntry {
  SpawnEntry({required this.entryId, required this.enemyId}) {
    _requireCleanId(entryId, 'entryId');
    _requireCleanId(enemyId, 'enemyId');
  }

  final String entryId;
  final String enemyId;

  static void _requireCleanId(String value, String field) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, field, 'must not be empty');
    }
    if (RegExp(r'\s').hasMatch(value)) {
      throw ArgumentError.value(value, field, 'must not contain whitespace');
    }
  }
}

/// 单个单位的不可变快照。
final class SpawnUnitSnapshot {
  const SpawnUnitSnapshot({
    required this.entryId,
    required this.enemyId,
    required this.stage,
    required this.remainingWarningTicks,
    required this.remainingGraceTicks,
    this.enteredTick,
    this.removedTick,
  });

  final String entryId;
  final String enemyId;
  final SpawnUnitStage stage;

  /// 仅 warning 阶段有意义，其余阶段为 0。
  final int remainingWarningTicks;

  /// 仅 active 阶段有意义，其余阶段为 0。
  final int remainingGraceTicks;

  /// 上场拍；尚未上场为 null。
  final int? enteredTick;

  /// 离场拍；尚未离场为 null。
  final int? removedTick;

  /// 是否可发起攻击：已上场且攻击宽限已到期。
  bool get canAttack =>
      stage == SpawnUnitStage.active && remainingGraceTicks == 0;

  @override
  bool operator ==(Object other) =>
      other is SpawnUnitSnapshot &&
      other.entryId == entryId &&
      other.enemyId == enemyId &&
      other.stage == stage &&
      other.remainingWarningTicks == remainingWarningTicks &&
      other.remainingGraceTicks == remainingGraceTicks &&
      other.enteredTick == enteredTick &&
      other.removedTick == removedTick;

  @override
  int get hashCode => Object.hash(
    entryId,
    enemyId,
    stage,
    remainingWarningTicks,
    remainingGraceTicks,
    enteredTick,
    removedTick,
  );
}

/// 导演状态的不可变快照（每拍可安全读取/比对/回放）。
final class SpawnDirectorState {
  SpawnDirectorState._({
    required this.tick,
    required this.totalCount,
    required this.activeCount,
    required this.warningCount,
    required this.pendingCount,
    required this.removedCount,
    required List<SpawnUnitSnapshot> units,
  }) : units = List.unmodifiable(units);

  /// 已推进的逻辑拍数。
  final int tick;

  /// 总量：全部显式入口数（恒等于构造时 entries.length）。
  final int totalCount;

  /// 活跃：已上场（on field）单位数。
  final int activeCount;

  /// 预警：已补入但尚未上场单位数。
  final int warningCount;

  /// 后备：仍在队列等待补入单位数。
  final int pendingCount;

  /// 已离场单位数。
  final int removedCount;

  /// 不可变单位快照，稳定顺序：pending → warning → active → removed，
  /// 组内按 entryId 升序，active/removed 再按 tick 升序。
  final List<SpawnUnitSnapshot> units;

  SpawnUnitSnapshot? unitById(String entryId) {
    for (final unit in units) {
      if (unit.entryId == entryId) return unit;
    }
    return null;
  }
}

/// 单拍事件：预警开始 / 上场 / 攻击宽限到期。
final class SpawnDirectorEvent {
  const SpawnDirectorEvent(this.type, this.entryId, this.enemyId, this.tick);

  final SpawnDirectorEventType type;
  final String entryId;
  final String enemyId;
  final int tick;

  @override
  bool operator ==(Object other) =>
      other is SpawnDirectorEvent &&
      other.type == type &&
      other.entryId == entryId &&
      other.enemyId == enemyId &&
      other.tick == tick;

  @override
  int get hashCode => Object.hash(type, entryId, enemyId, tick);
}

/// 单拍推进结果：新 director + 不可变事件列表。
final class SpawnAdvanceResult {
  SpawnAdvanceResult(this.director, List<SpawnDirectorEvent> events)
    : events = List.unmodifiable(events);

  final SpawnDirector director;
  final List<SpawnDirectorEvent> events;
}

/// 不可变生成导演：advance / markExited 均返回新实例，原实例不受影响。
final class SpawnDirector {
  SpawnDirector({required this.config, required List<SpawnEntry> entries})
    : _units = _initUnits(entries),
      _tick = 0;

  SpawnDirector._(this.config, this._units, this._tick);

  final SpawnDirectorConfig config;
  final List<_SpawnUnit> _units;
  final int _tick;

  static List<_SpawnUnit> _initUnits(List<SpawnEntry> entries) {
    final seenEntryIds = <String>{};
    final seenEnemyIds = <String>{};
    final sorted = List<SpawnEntry>.of(entries)
      ..sort((a, b) => a.entryId.compareTo(b.entryId));
    final units = <_SpawnUnit>[];
    for (final entry in sorted) {
      if (!seenEntryIds.add(entry.entryId)) {
        throw ArgumentError.value(
          entry.entryId,
          'entries',
          'duplicate entryId',
        );
      }
      if (!seenEnemyIds.add(entry.enemyId)) {
        throw ArgumentError.value(
          entry.enemyId,
          'entries',
          'duplicate enemyId',
        );
      }
      units.add(_SpawnUnit(entry));
    }
    return units;
  }

  SpawnDirectorState get state {
    final pending = <_SpawnUnit>[];
    final warning = <_SpawnUnit>[];
    final active = <_SpawnUnit>[];
    final removed = <_SpawnUnit>[];
    for (final unit in _units) {
      switch (unit.stage) {
        case SpawnUnitStage.pending:
          pending.add(unit);
        case SpawnUnitStage.warning:
          warning.add(unit);
        case SpawnUnitStage.active:
          active.add(unit);
        case SpawnUnitStage.removed:
          removed.add(unit);
      }
    }
    pending.sort(_byEntryId);
    warning.sort(_byEntryId);
    active.sort(_byActiveOrder);
    removed.sort(_byRemovedOrder);
    return SpawnDirectorState._(
      tick: _tick,
      totalCount: _units.length,
      activeCount: active.length,
      warningCount: warning.length,
      pendingCount: pending.length,
      removedCount: removed.length,
      units: [
        for (final unit in pending) unit.snapshot(),
        for (final unit in warning) unit.snapshot(),
        for (final unit in active) unit.snapshot(),
        for (final unit in removed) unit.snapshot(),
      ],
    );
  }

  /// 活跃数是否已到 activeLimit。
  bool get activeFull => state.activeCount >= config.activeLimit;

  /// 是否仍有后备可补。
  bool get hasReserve => state.pendingCount > 0;

  /// 活跃数是否已降至补兵阈值（及以下），即是否处于「待补兵」状态。
  bool get needsReinforcement =>
      state.activeCount <= config.reinforcementThreshold;

  /// 推进一拍：先倒计攻击宽限，再倒计预警并上场，最后按阈值补兵。
  /// 返回新 director 与本拍不可变事件列表。
  SpawnAdvanceResult advance() {
    final nextTick = _tick + 1;
    final events = <SpawnDirectorEvent>[];
    final units = _units.map((unit) => unit.copy()).toList();

    // 1. 攻击宽限倒计时（仅对当拍开始前已上场者；上场当拍不扣）。
    for (final unit in units) {
      if (unit.stage == SpawnUnitStage.active && unit.remainingGraceTicks > 0) {
        unit.remainingGraceTicks--;
        if (unit.remainingGraceTicks == 0) {
          events.add(
            SpawnDirectorEvent(
              SpawnDirectorEventType.graceExpired,
              unit.entry.entryId,
              unit.entry.enemyId,
              nextTick,
            ),
          );
        }
      }
    }

    // 2. 预警倒计时 → 上场（带满额攻击宽限，本拍不扣）。
    for (final unit in units) {
      if (unit.stage == SpawnUnitStage.warning) {
        unit.remainingWarningTicks--;
        if (unit.remainingWarningTicks <= 0) {
          unit.stage = SpawnUnitStage.active;
          unit.enteredTick = nextTick;
          unit.remainingGraceTicks = config.attackGraceTicks;
          events.add(
            SpawnDirectorEvent(
              SpawnDirectorEventType.entered,
              unit.entry.entryId,
              unit.entry.enemyId,
              nextTick,
            ),
          );
        }
      }
    }

    // 3. 补兵：达到阈值且管道未满时，按 reserve 顺序补入至管道满。
    var activeCount = units
        .where((unit) => unit.stage == SpawnUnitStage.active)
        .length;
    var warningCount = units
        .where((unit) => unit.stage == SpawnUnitStage.warning)
        .length;
    if (activeCount <= config.reinforcementThreshold) {
      for (final unit in units) {
        if (unit.stage != SpawnUnitStage.pending) continue;
        if (activeCount + warningCount >= config.activeLimit) break;
        unit.stage = SpawnUnitStage.warning;
        unit.remainingWarningTicks = config.entryWarningTicks;
        if (config.entryWarningTicks == 0) {
          unit.stage = SpawnUnitStage.active;
          unit.enteredTick = nextTick;
          unit.remainingGraceTicks = config.attackGraceTicks;
          events.add(
            SpawnDirectorEvent(
              SpawnDirectorEventType.entered,
              unit.entry.entryId,
              unit.entry.enemyId,
              nextTick,
            ),
          );
          activeCount++;
        } else {
          events.add(
            SpawnDirectorEvent(
              SpawnDirectorEventType.warningStarted,
              unit.entry.entryId,
              unit.entry.enemyId,
              nextTick,
            ),
          );
          warningCount++;
        }
      }
    }

    return SpawnAdvanceResult(SpawnDirector._(config, units, nextTick), events);
  }

  /// 标记一个 active 单位离场（击杀/撤退/目标完成）。
  /// 未知 entryId、非 active 单位（pending/warning/removed）一律 fail closed。
  /// 不推进 tick；补兵在下一拍 advance 时按阈值触发。
  SpawnDirector markExited(String entryId) {
    final units = _units.map((unit) => unit.copy()).toList();
    var found = false;
    for (final unit in units) {
      if (unit.entry.entryId != entryId) continue;
      found = true;
      if (unit.stage != SpawnUnitStage.active) {
        throw ArgumentError.value(
          entryId,
          'entryId',
          'only active units may exit',
        );
      }
      unit.stage = SpawnUnitStage.removed;
      unit.remainingGraceTicks = 0;
      unit.removedTick = _tick;
      break;
    }
    if (!found) {
      throw ArgumentError.value(entryId, 'entryId', 'unknown entryId');
    }
    return SpawnDirector._(config, units, _tick);
  }

  static int _byEntryId(_SpawnUnit a, _SpawnUnit b) =>
      a.entry.entryId.compareTo(b.entry.entryId);

  static int _byActiveOrder(_SpawnUnit a, _SpawnUnit b) {
    final byTick = (a.enteredTick ?? 0).compareTo(b.enteredTick ?? 0);
    return byTick != 0 ? byTick : _byEntryId(a, b);
  }

  static int _byRemovedOrder(_SpawnUnit a, _SpawnUnit b) {
    final byTick = (a.removedTick ?? 0).compareTo(b.removedTick ?? 0);
    return byTick != 0 ? byTick : _byEntryId(a, b);
  }
}

/// 内部可变单位槽（外部只见不可变快照，永不泄漏）。
final class _SpawnUnit {
  _SpawnUnit(
    this.entry, {
    this.stage = SpawnUnitStage.pending,
    this.remainingWarningTicks = 0,
    this.remainingGraceTicks = 0,
    this.enteredTick,
    this.removedTick,
  });

  final SpawnEntry entry;
  SpawnUnitStage stage;
  int remainingWarningTicks;
  int remainingGraceTicks;
  int? enteredTick;
  int? removedTick;

  _SpawnUnit copy() => _SpawnUnit(
    entry,
    stage: stage,
    remainingWarningTicks: remainingWarningTicks,
    remainingGraceTicks: remainingGraceTicks,
    enteredTick: enteredTick,
    removedTick: removedTick,
  );

  SpawnUnitSnapshot snapshot() => SpawnUnitSnapshot(
    entryId: entry.entryId,
    enemyId: entry.enemyId,
    stage: stage,
    remainingWarningTicks: stage == SpawnUnitStage.warning
        ? remainingWarningTicks
        : 0,
    remainingGraceTicks: stage == SpawnUnitStage.active
        ? remainingGraceTicks
        : 0,
    enteredTick: enteredTick,
    removedTick: removedTick,
  );
}
