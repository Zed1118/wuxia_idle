import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const _visualFidelityRegionByKey = <String, String>{
  'battle_header_surface': 'header',
  'battle_scene_stage_viewport': 'battlefield',
  'battle_command_desk': 'command_desk',
  'battle_desk_focus_region': 'focus',
  'battle_desk_skills_region': 'skills',
  'battle_desk_pouch_region': 'pouch',
};

@visibleForTesting
Map<String, Map<String, double>> collectVisualFidelityRegions(
  BuildContext context,
) {
  final regions = <String, Map<String, double>>{};

  void visit(Element element) {
    final key = element.widget.key;
    final rawKey = key is ValueKey<String> ? key.value : null;
    final regionName = rawKey == null
        ? null
        : _visualFidelityRegionByKey[rawKey];
    if (regionName != null) {
      final renderObject = element.findRenderObject();
      if (renderObject is RenderBox &&
          renderObject.attached &&
          renderObject.hasSize) {
        final rect = MatrixUtils.transformRect(
          renderObject.getTransformTo(null),
          Offset.zero & renderObject.size,
        );
        regions[regionName] = {
          'x': _roundVisualFidelityValue(rect.left),
          'y': _roundVisualFidelityValue(rect.top),
          'width': _roundVisualFidelityValue(rect.width),
          'height': _roundVisualFidelityValue(rect.height),
        };
      }
    }
    element.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
  return regions;
}

double _roundVisualFidelityValue(double value) =>
    (value * 1000).roundToDouble() / 1000;

/// Emits actual battle layout rectangles for screenshot manifest generation.
///
/// The probe is debug-only and opt-in through `VISUAL_FIDELITY_PROBE`. It does
/// not paint, intercept input, or participate in production builds.
class VisualFidelityRegionProbe extends StatefulWidget {
  const VisualFidelityRegionProbe({super.key, required this.child});

  final Widget child;

  static const bool enabledFromEnv = bool.fromEnvironment(
    'VISUAL_FIDELITY_PROBE',
  );

  static Widget maybeWrap(Widget child) {
    if (!kDebugMode || !enabledFromEnv) return child;
    return VisualFidelityRegionProbe(child: child);
  }

  @override
  State<VisualFidelityRegionProbe> createState() =>
      _VisualFidelityRegionProbeState();
}

class _VisualFidelityRegionProbeState extends State<VisualFidelityRegionProbe> {
  String? _lastPayload;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _scheduleProbe();
  }

  @override
  void didUpdateWidget(covariant VisualFidelityRegionProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleProbe();
  }

  void _scheduleProbe() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitRegions());
  }

  void _emitRegions() {
    if (!mounted) return;
    final regions = collectVisualFidelityRegions(context);
    const required = {'header', 'battlefield', 'command_desk'};
    if (!regions.keys.toSet().containsAll(required)) {
      if (_attempts < 40) {
        _attempts += 1;
        Future<void>.delayed(const Duration(milliseconds: 100), _scheduleProbe);
        return;
      }
      final incomplete = 'incomplete:${regions.keys.toList()..sort()}';
      if (incomplete != _lastPayload) {
        _lastPayload = incomplete;
        debugPrint('VISUAL_FIDELITY_REGIONS_INCOMPLETE: $incomplete');
      }
      return;
    }
    final payload = jsonEncode(regions);
    if (payload == _lastPayload) return;
    _lastPayload = payload;
    debugPrint('VISUAL_FIDELITY_REGIONS: $payload');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
