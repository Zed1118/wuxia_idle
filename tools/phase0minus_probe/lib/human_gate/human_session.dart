const phase0aHumanSessionSchema = 'phase0a-human-session-v1';

final class HumanSessionValidation {
  const HumanSessionValidation(this.errors);

  final List<String> errors;
  bool get isValid => errors.isEmpty;
}

HumanSessionValidation validateHumanSession(Map<String, Object?> session) {
  final errors = <String>[];
  const required = {
    'schema',
    'study_id',
    'package_id',
    'participant_id',
    'participant_session_id',
    'player_type',
    'order',
    'slot',
    'ratings',
    'pairwise',
    'mechanical_evidence',
    'core_action_roles',
    'readability_trials',
    'observations',
    'integrity',
    'direct_veto',
    'validity',
  };
  const forbidden = {
    'name',
    'real_name',
    'email',
    'account',
    'phone',
    'device_owner',
  };
  for (final key in required) {
    if (!session.containsKey(key)) errors.add('missing $key');
  }
  for (final key in forbidden) {
    if (session.containsKey(key)) errors.add('forbidden identity key $key');
  }
  if (session['schema'] != phase0aHumanSessionSchema) {
    errors.add('schema must be $phase0aHumanSessionSchema');
  }
  _anonymousSlug(session, 'study_id', errors);
  _anonymousSlug(session, 'package_id', errors);
  _anonymousSlug(session, 'participant_session_id', errors);
  final participant = session['participant_id'];
  if (participant is! String || !RegExp(r'^P0[1-6]$').hasMatch(participant)) {
    errors.add('participant_id must be P01..P06');
  }
  if (!{'idle', 'arpg', 'mixed'}.contains(session['player_type'])) {
    errors.add('player_type must be idle, arpg, or mixed');
  }
  if (!{'AB', 'BA'}.contains(session['order'])) errors.add('order invalid');
  final slot = session['slot'];
  if (slot is! int || slot < 1 || slot > 6) errors.add('slot must be 1..6');

  final ratings = _map(session, 'ratings', errors);
  for (final key in const ['release', 'readability', 'active_intent']) {
    final value = ratings[key];
    if (value is! int || value < 1 || value > 5) {
      errors.add('ratings.$key must be 1..5');
    }
  }
  _booleans(
    _map(session, 'pairwise', errors),
    const [
      'verbal_replay_willing',
      'app_replay_clicked',
      'clearly_better_than_production',
      'qr_noninterchangeable_explained',
    ],
    'pairwise',
    errors,
  );
  final mechanical = _map(session, 'mechanical_evidence', errors);
  _anonymousSlug(mechanical, 'raw_report_run_id', errors);
  if (!{'victory', 'defeat'}.contains(mechanical['terminal_outcome'])) {
    errors.add('mechanical_evidence.terminal_outcome invalid');
  }
  if (mechanical['replay_clicked_after_victory'] is! bool) {
    errors.add(
      'mechanical_evidence.replay_clicked_after_victory must be boolean',
    );
  }
  final pairwise = session['pairwise'];
  if (pairwise is Map && pairwise['app_replay_clicked'] == true) {
    if (mechanical['terminal_outcome'] != 'victory' ||
        mechanical['replay_clicked_after_victory'] != true) {
      errors.add('app replay intent must be a click after victory');
    }
  }
  _booleans(
    _map(session, 'core_action_roles', errors),
    const ['dash', 'gather', 'break'],
    'core_action_roles',
    errors,
  );
  _booleans(
    _map(session, 'observations', errors),
    const [
      'frequently_lost_protagonist',
      'frequently_lost_danger',
      'single_skill_judged_optimal',
    ],
    'observations',
    errors,
  );
  final trials = session['readability_trials'];
  if (trials is! List || trials.length != 5) {
    errors.add('readability_trials must contain exactly 5 trials');
  } else {
    for (var index = 0; index < trials.length; index++) {
      final trial = trials[index];
      if (trial is! Map) {
        errors.add('readability_trials[$index] must be an object');
        continue;
      }
      if (trial['frame'] != index + 1) {
        errors.add('readability_trials[$index].frame must be ${index + 1}');
      }
      final stimulusId = trial['stimulus_id'];
      if (stimulusId is! String ||
          stimulusId != phase0aReadabilityStimulusIds[index]) {
        errors.add(
          'readability_trials[$index].stimulus_id does not match frozen suite',
        );
      }
      final stimulusHash = trial['sha256'];
      if (stimulusHash is! String ||
          stimulusHash != phase0aReadabilityStimulusHashes[index]) {
        errors.add(
          'readability_trials[$index].sha256 does not match frozen suite',
        );
      }
      for (final key in const ['protagonist_within_1s', 'danger_correct']) {
        if (trial[key] is! bool) {
          errors.add('readability_trials[$index].$key must be boolean');
        }
      }
    }
  }
  _booleans(
    _map(session, 'integrity', errors),
    const [
      'completed_three_waves',
      'implementer_assisted',
      'same_package',
      'optimal_answer_disclosed_before_run',
      'external_event_polluted',
      'questionnaire_complete',
      'participant_had_input_control',
      'facilitator_is_primary_implementer',
      'app_overlap',
      'scheduled_order_followed',
      'comparison_continue_pressed',
      'stimulus_hashes_verified',
      'stimulus_rewatch',
    ],
    'integrity',
    errors,
  );
  _booleans(
    _map(session, 'direct_veto', errors),
    const [
      'stationary_or_cooldown_only_is_optimal',
      'two_core_actions_lack_role',
      'density_20_plus_1_unreadable',
      'spectacle_not_grouping_or_timing',
      'requires_forbidden_mechanic',
      'production_storage_or_reward_touched',
      'mac_performance_unrecoverable',
    ],
    'direct_veto',
    errors,
  );
  final validity = _map(session, 'validity', errors);
  if (validity['valid'] is! bool) errors.add('validity.valid must be boolean');
  final invalidReasons = validity['invalid_reasons'];
  if (invalidReasons is! List ||
      invalidReasons.any((value) => value is! String)) {
    errors.add('validity.invalid_reasons must be a string array');
  } else if (validity['valid'] == true && invalidReasons.isNotEmpty) {
    errors.add('valid session cannot have invalid_reasons');
  } else if (validity['valid'] == false && invalidReasons.isEmpty) {
    errors.add('invalid session must have at least one invalid_reason');
  }
  final integrity = session['integrity'];
  if (integrity is Map && validity['valid'] == true) {
    if (integrity['same_package'] != true ||
        integrity['participant_had_input_control'] != true ||
        integrity['facilitator_is_primary_implementer'] == true ||
        integrity['app_overlap'] == true ||
        integrity['scheduled_order_followed'] != true ||
        integrity['comparison_continue_pressed'] == true ||
        integrity['stimulus_hashes_verified'] != true ||
        integrity['stimulus_rewatch'] == true ||
        integrity['optimal_answer_disclosed_before_run'] == true ||
        integrity['external_event_polluted'] == true ||
        integrity['questionnaire_complete'] != true) {
      errors.add('validity.valid contradicts integrity flags');
    }
  }
  return HumanSessionValidation(errors);
}

const phase0aReadabilityStimulusIds = <String>[
  'frame1_wave2_peak',
  'frame2_wave3_peak',
  'frame3_gather',
  'frame4_break_window',
  'frame5_clear',
];

const phase0aReadabilityStimulusHashes = <String>[
  'ea86def982f4883b1b683b84c359eab8d12d50a4c1e6539185c72c77d5c57b5c',
  '8728204a904e0b9ee2c0645cb4c43c69ecfdc6714c32ebc02601d779705ef0bb',
  '235a34eb58ff87472bf99258ce1af9a7e38d46f8334b51c2a2716c944c07b889',
  '82b645e8ce29a81e2bbb84c03f55eb1f562712d3f9d199a48640c451b56d5bce',
  '381b83e761a397787c52d9c0ba3dd744befbe73b8492ce104d674d76e75f9f7f',
];

void _anonymousSlug(
  Map<String, Object?> source,
  String key,
  List<String> errors,
) {
  final value = source[key];
  if (value is! String ||
      !RegExp(r'^[a-z0-9][a-z0-9_-]{2,63}$').hasMatch(value)) {
    errors.add('$key must be an anonymous slug');
  }
}

Map<String, Object?> _map(
  Map<String, Object?> source,
  String key,
  List<String> errors,
) {
  final value = source[key];
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.cast<String, Object?>();
  errors.add('$key must be an object');
  return const {};
}

void _booleans(
  Map<String, Object?> source,
  List<String> keys,
  String prefix,
  List<String> errors,
) {
  for (final key in keys) {
    if (source[key] is! bool) errors.add('$prefix.$key must be boolean');
  }
}
