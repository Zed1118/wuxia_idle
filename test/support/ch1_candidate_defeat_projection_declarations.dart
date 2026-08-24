import 'package:wuxia_idle/features/battle/application/phase0a/'
    'phase0a_explicit_objective_event_source.dart';

// Candidate-only caller policy. Keep every declaration explicit and in
// encounter order; never derive objective meaning from content metadata.
// BEGIN EXPLICIT DEFEAT DECLARATIONS.
const ch1CandidateDefeatProjectionEntriesByStageId =
    <
      String,
      List<MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>>
    >{
      'stage_01_01': [
        MapEntry('candidate_ch1_s01_blade_01', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_blade_01'),
        ]),
        MapEntry('candidate_ch1_s01_blade_02', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_blade_02'),
        ]),
        MapEntry('candidate_ch1_s01_blade_03', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_blade_03'),
        ]),
        MapEntry('candidate_ch1_s01_blade_04', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_blade_04'),
        ]),
        MapEntry('candidate_ch1_s01_blade_05', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_blade_05'),
        ]),
        MapEntry('candidate_ch1_s01_blade_06', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_blade_06'),
        ]),
        MapEntry('candidate_ch1_s01_blade_07', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_blade_07'),
        ]),
        MapEntry('candidate_ch1_s01_blade_08', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_blade_08'),
        ]),
        MapEntry('candidate_ch1_s01_blade_09', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_blade_09'),
        ]),
        MapEntry('candidate_ch1_s01_blade_10', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_blade_10'),
        ]),
        MapEntry('candidate_ch1_s01_blade_11', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_blade_11'),
        ]),
        MapEntry('candidate_ch1_s01_blade_12', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_blade_12'),
        ]),
        MapEntry('candidate_ch1_s01_blade_13', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_blade_13'),
        ]),
        MapEntry('candidate_ch1_s01_blade_14', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_blade_14'),
        ]),
        MapEntry('candidate_ch1_s01_crossbow_01', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_crossbow_01'),
        ]),
        MapEntry('candidate_ch1_s01_crossbow_02', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_crossbow_02'),
        ]),
        MapEntry('candidate_ch1_s01_crossbow_03', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_crossbow_03'),
        ]),
        MapEntry('candidate_ch1_s01_crossbow_04', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_crossbow_04'),
        ]),
        MapEntry('candidate_ch1_s01_crossbow_05', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_crossbow_05'),
        ]),
        MapEntry('candidate_ch1_s01_crossbow_06', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_crossbow_06'),
        ]),
        MapEntry('candidate_ch1_s01_rope_01', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_rope_01'),
        ]),
        MapEntry('candidate_ch1_s01_rope_02', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_rope_02'),
        ]),
        MapEntry('candidate_ch1_s01_rope_03', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_rope_03'),
        ]),
        MapEntry('candidate_ch1_s01_rope_04', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_rope_04'),
        ]),
        MapEntry('candidate_ch1_s01_rope_05', [
          Phase0aTargetDefeatProjection('candidate_ch1_s01_rope_05'),
        ]),
      ],
      'stage_01_02': [
        MapEntry('candidate_ch1_s02_blade_01', []),
        MapEntry('candidate_ch1_s02_blade_02', []),
        MapEntry('candidate_ch1_s02_blade_03', []),
        MapEntry('candidate_ch1_s02_blade_04', []),
        MapEntry('candidate_ch1_s02_blade_05', []),
        MapEntry('candidate_ch1_s02_blade_06', []),
        MapEntry('candidate_ch1_s02_blade_07', []),
        MapEntry('candidate_ch1_s02_blade_08', []),
        MapEntry('candidate_ch1_s02_blade_09', []),
        MapEntry('candidate_ch1_s02_blade_10', []),
        MapEntry('candidate_ch1_s02_blade_11', []),
        MapEntry('candidate_ch1_s02_blade_12', []),
        MapEntry('candidate_ch1_s02_blade_13', []),
        MapEntry('candidate_ch1_s02_blade_14', []),
        MapEntry('candidate_ch1_s02_crossbow_01', []),
        MapEntry('candidate_ch1_s02_crossbow_02', []),
        MapEntry('candidate_ch1_s02_crossbow_03', []),
        MapEntry('candidate_ch1_s02_crossbow_04', []),
        MapEntry('candidate_ch1_s02_crossbow_05', []),
        MapEntry('candidate_ch1_s02_crossbow_06', []),
        MapEntry('candidate_ch1_s02_rope_01', []),
        MapEntry('candidate_ch1_s02_rope_02', []),
        MapEntry('candidate_ch1_s02_rope_03', []),
        MapEntry('candidate_ch1_s02_rope_04', []),
        MapEntry('candidate_ch1_s02_leader_01', [
          Phase0aCommanderDefeatProjection('candidate_ch1_s02_leader_01'),
        ]),
      ],
      'stage_01_03': [
        MapEntry('candidate_ch1_s03_blade_01', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_01'),
        ]),
        MapEntry('candidate_ch1_s03_blade_02', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_02'),
        ]),
        MapEntry('candidate_ch1_s03_blade_03', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_03'),
        ]),
        MapEntry('candidate_ch1_s03_blade_04', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_04'),
        ]),
        MapEntry('candidate_ch1_s03_blade_05', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_05'),
        ]),
        MapEntry('candidate_ch1_s03_blade_06', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_06'),
        ]),
        MapEntry('candidate_ch1_s03_blade_07', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_07'),
        ]),
        MapEntry('candidate_ch1_s03_blade_08', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_08'),
        ]),
        MapEntry('candidate_ch1_s03_blade_09', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_09'),
        ]),
        MapEntry('candidate_ch1_s03_blade_10', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_10'),
        ]),
        MapEntry('candidate_ch1_s03_blade_11', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_11'),
        ]),
        MapEntry('candidate_ch1_s03_blade_12', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_12'),
        ]),
        MapEntry('candidate_ch1_s03_blade_13', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_13'),
        ]),
        MapEntry('candidate_ch1_s03_blade_14', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_14'),
        ]),
        MapEntry('candidate_ch1_s03_blade_15', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_15'),
        ]),
        MapEntry('candidate_ch1_s03_blade_16', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_16'),
        ]),
        MapEntry('candidate_ch1_s03_blade_17', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_17'),
        ]),
        MapEntry('candidate_ch1_s03_blade_18', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_blade_18'),
        ]),
        MapEntry('candidate_ch1_s03_crossbow_01', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_crossbow_01'),
        ]),
        MapEntry('candidate_ch1_s03_crossbow_02', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_crossbow_02'),
        ]),
        MapEntry('candidate_ch1_s03_crossbow_03', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_crossbow_03'),
        ]),
        MapEntry('candidate_ch1_s03_crossbow_04', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_crossbow_04'),
        ]),
        MapEntry('candidate_ch1_s03_crossbow_05', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_crossbow_05'),
        ]),
        MapEntry('candidate_ch1_s03_crossbow_06', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_crossbow_06'),
        ]),
        MapEntry('candidate_ch1_s03_crossbow_07', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_crossbow_07'),
        ]),
        MapEntry('candidate_ch1_s03_crossbow_08', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_crossbow_08'),
        ]),
        MapEntry('candidate_ch1_s03_crossbow_09', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_crossbow_09'),
        ]),
        MapEntry('candidate_ch1_s03_crossbow_10', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_crossbow_10'),
        ]),
        MapEntry('candidate_ch1_s03_rope_01', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_rope_01'),
        ]),
        MapEntry('candidate_ch1_s03_rope_02', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_rope_02'),
        ]),
        MapEntry('candidate_ch1_s03_rope_03', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_rope_03'),
        ]),
        MapEntry('candidate_ch1_s03_rope_04', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_rope_04'),
        ]),
        MapEntry('candidate_ch1_s03_rope_05', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_rope_05'),
        ]),
        MapEntry('candidate_ch1_s03_rope_06', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_rope_06'),
        ]),
        MapEntry('candidate_ch1_s03_rope_07', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_rope_07'),
        ]),
        MapEntry('candidate_ch1_s03_rope_08', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_rope_08'),
        ]),
        MapEntry('candidate_ch1_s03_rope_09', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_rope_09'),
        ]),
        MapEntry('candidate_ch1_s03_rope_10', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_rope_10'),
        ]),
        MapEntry('candidate_ch1_s03_leader_01', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_leader_01'),
        ]),
        MapEntry('candidate_ch1_s03_leader_02', [
          Phase0aTargetDefeatProjection('candidate_ch1_s03_leader_02'),
        ]),
      ],
      'stage_01_04': [
        MapEntry('candidate_ch1_s04_blade_01', [
          Phase0aTargetDefeatProjection('candidate_ch1_s04_blade_01'),
        ]),
        MapEntry('candidate_ch1_s04_rope_01', [
          Phase0aTargetDefeatProjection('candidate_ch1_s04_rope_01'),
        ]),
        MapEntry('candidate_ch1_s04_leader_01', [
          Phase0aCommanderDefeatProjection('candidate_ch1_s04_leader_01'),
        ]),
      ],
      'stage_01_05': [
        MapEntry('candidate_ch1_s05_blade_01', []),
        MapEntry('candidate_ch1_s05_leader_01', [
          Phase0aCommanderDefeatProjection('candidate_ch1_s05_leader_01'),
        ]),
      ],
    };
// END EXPLICIT DEFEAT DECLARATIONS.
