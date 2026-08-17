import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

final class JointPart {
  const JointPart({
    required this.id,
    required this.cell,
    required this.source,
    required this.parent,
    required this.layer,
    required this.offset,
    required this.size,
    required this.pivot,
  });

  final String id;
  final int cell;
  final Rect source;
  final String? parent;
  final int layer;
  final Offset offset;
  final Size size;
  final Offset pivot;
}

final class JointKeyframe {
  const JointKeyframe({
    required this.time,
    required this.rootOffset,
    required this.angles,
  });

  final double time;
  final Offset rootOffset;
  final Map<String, double> angles;
}

final class JointRig {
  const JointRig({
    required this.atlas,
    required this.columns,
    required this.rows,
    required this.root,
    required this.parts,
    required this.duration,
    required this.keys,
  });

  final String atlas;
  final int columns;
  final int rows;
  final String root;
  final List<JointPart> parts;
  final double duration;
  final List<JointKeyframe> keys;

  static Future<JointRig> load(String asset) async {
    final source = await rootBundle.loadString(asset);
    return parse(source);
  }

  static JointRig parse(String source) {
    final yaml = loadYaml(source) as YamlMap;
    final grid = yaml['atlas_grid'] as YamlMap;
    final partRows = yaml['parts'] as YamlList;
    final clip = yaml['clip'] as YamlMap;
    final keyRows = clip['keys'] as YamlList;
    final rig = JointRig(
      atlas: yaml['atlas'] as String,
      columns: grid['columns'] as int,
      rows: grid['rows'] as int,
      root: yaml['root'] as String,
      parts: partRows
          .map((row) {
            final map = row as YamlMap;
            return JointPart(
              id: map['id'] as String,
              cell: map['cell'] as int,
              source: _rect(map['source'] as YamlList),
              parent: map['parent'] as String?,
              layer: map['layer'] as int,
              offset: _offset(map['offset'] as YamlList),
              size: _size(map['size'] as YamlList),
              pivot: _offset(map['pivot'] as YamlList),
            );
          })
          .toList(growable: false),
      duration: (clip['duration_seconds'] as num).toDouble(),
      keys: keyRows
          .map((row) {
            final map = row as YamlMap;
            final angles = <String, double>{};
            for (final entry in map.entries) {
              final key = entry.key as String;
              if (key != 'time' && key != 'root_x' && key != 'root_y') {
                angles[key] = (entry.value as num).toDouble();
              }
            }
            return JointKeyframe(
              time: (map['time'] as num).toDouble(),
              rootOffset: Offset(
                (map['root_x'] as num).toDouble(),
                (map['root_y'] as num).toDouble(),
              ),
              angles: angles,
            );
          })
          .toList(growable: false),
    );
    rig.validate();
    return rig;
  }

  void validate() {
    if (columns <= 0 || rows <= 0 || duration <= 0 || keys.length < 2) {
      throw const FormatException('invalid rig dimensions or timeline');
    }
    final ids = parts.map((part) => part.id).toSet();
    if (ids.length != parts.length || !ids.contains(root)) {
      throw const FormatException('part ids must be unique and include root');
    }
    for (final part in parts) {
      if (part.cell < 0 || part.cell >= columns * rows) {
        throw FormatException('invalid atlas cell: ${part.id}');
      }
      if (part.parent != null && !ids.contains(part.parent)) {
        throw FormatException('missing parent: ${part.id}');
      }
      if (part.pivot.dx < 0 ||
          part.pivot.dx > 1 ||
          part.pivot.dy < 0 ||
          part.pivot.dy > 1) {
        throw FormatException('invalid pivot: ${part.id}');
      }
    }
    for (var index = 1; index < keys.length; index++) {
      if (keys[index].time <= keys[index - 1].time) {
        throw const FormatException('key times must increase');
      }
    }
    if (keys.first.time != 0 || keys.last.time != duration) {
      throw const FormatException('timeline must cover clip duration');
    }
  }

  JointPose sample(double time) {
    final wrapped = time % duration;
    var rightIndex = 1;
    while (rightIndex < keys.length && keys[rightIndex].time < wrapped) {
      rightIndex++;
    }
    final right = keys[rightIndex.clamp(1, keys.length - 1)];
    final left = keys[(rightIndex - 1).clamp(0, keys.length - 2)];
    final t = ((wrapped - left.time) / (right.time - left.time))
        .clamp(0, 1)
        .toDouble();
    final angleIds = <String>{...left.angles.keys, ...right.angles.keys};
    return JointPose(
      rootOffset: Offset.lerp(left.rootOffset, right.rootOffset, t)!,
      angles: {
        for (final id in angleIds)
          id: _lerpAngle(left.angles[id] ?? 0, right.angles[id] ?? 0, t),
      },
    );
  }

  static double _lerpAngle(double from, double to, double t) {
    var delta = (to - from) % (3.141592653589793 * 2);
    if (delta > 3.141592653589793) delta -= 3.141592653589793 * 2;
    return from + delta * t;
  }

  static Offset _offset(YamlList values) =>
      Offset((values[0] as num).toDouble(), (values[1] as num).toDouble());

  static Size _size(YamlList values) =>
      Size((values[0] as num).toDouble(), (values[1] as num).toDouble());

  static Rect _rect(YamlList values) => Rect.fromLTWH(
    (values[0] as num).toDouble(),
    (values[1] as num).toDouble(),
    (values[2] as num).toDouble(),
    (values[3] as num).toDouble(),
  );
}

final class JointPose {
  const JointPose({required this.rootOffset, required this.angles});

  final Offset rootOffset;
  final Map<String, double> angles;
}
