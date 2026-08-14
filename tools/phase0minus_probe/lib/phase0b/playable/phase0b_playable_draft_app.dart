import 'dart:async' as async;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:phase0minus_probe/phase0b/playable/boss_brain.dart';
import 'package:phase0minus_probe/phase0b/playable/draft_tuning.dart';
import 'package:phase0minus_probe/phase0b/playable/enemy_brain.dart';
import 'package:phase0minus_probe/phase0b/playable/style_profiles.dart';

/// NOT FINAL — Phase 0B playable draft entry.
///
/// Interactive text readout of the deterministic domain sims (enemy AI,
/// single boss, two styles). Deliberately not a Gate surface: no result
/// files, no manifests, [Phase0bPlayableDraftMetadata.gateEligible] is
/// false, and it must never replace Phase 0−/0A/0B observation matrices.
final class Phase0bPlayableDraftMetadata {
  Phase0bPlayableDraftMetadata._();

  static const modeId = 'phase0b_playable_draft';
  static const gateEligible = false;
  static const claim = 'phase0b_playable_draft_not_final_review_only';
}

final class Phase0bPlayableDraftApp extends StatefulWidget {
  const Phase0bPlayableDraftApp({super.key});

  @override
  State<Phase0bPlayableDraftApp> createState() =>
      Phase0bPlayableDraftAppState();
}

class Phase0bPlayableDraftAppState extends State<Phase0bPlayableDraftApp> {
  static const double _dt = 1 / 30;

  late DraftEnemyGroupSim _groupA = DraftEnemyGroupSim(count: 6, seed: 20260814);
  late DraftEnemyGroupSim _groupB =
      DraftEnemyGroupSim(count: 10, seed: 20260815);
  late DraftBossBrain _boss = DraftBossBrain(spawn: Vector2(3150, 505));
  DraftStyleKind _styleKind = DraftStyleKind.surgeCurrent;
  double _heroX = 420;
  final Vector2 _hero = Vector2(420, 505);
  double _health = PlayableDraftTuning.playerMaxHealth;
  double _qi = PlayableDraftTuning.playerStartingQi;
  double _basicRemaining = 0;
  double _elapsed = 0;
  int _strikesTaken = 0;
  bool _runOver = false;
  async.Timer? _timer;

  DraftStyleProfile get _profile => DraftStyleProfile.of(_styleKind);
  bool get _victory => _boss.defeated;

  @override
  void initState() {
    super.initState();
    _groupA.activate(cameraLeft: 0);
    _groupB.activate(cameraLeft: 1220);
    _timer = async.Timer.periodic(
      const Duration(milliseconds: 33),
      (_) => _tick(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (_runOver) return;
    setState(() {
      _elapsed += _dt;
      _basicRemaining -= _dt;
      _hero.setValues(_heroX, 500 + 40 * (_elapsed % 2 - 1));
      for (final strike in _groupA.advance(_dt, _hero)) {
        _health -= strike.damage;
        _strikesTaken++;
      }
      for (final strike in _groupB.advance(_dt, _hero)) {
        _health -= strike.damage;
        _strikesTaken++;
      }
      for (final event in _boss.advance(_dt, _hero)) {
        if (event.kind != DraftBossEventKind.phaseChanged && event.hitPlayer) {
          _health -= event.damage;
        }
      }
      if (_basicRemaining <= 0) _swing();
      if (_health <= 0) {
        _health = 0;
        _runOver = true;
      } else if (_victory) {
        _runOver = true;
      }
    });
  }

  void _swing() {
    _basicRemaining = _profile.basicInterval;
    final aim = Vector2(1, 0);
    var hitAny = false;
    for (final sim in [_groupA, _groupB]) {
      for (final enemy in sim.enemies) {
        if (!enemy.alive ||
            !enemy.hasEntered ||
            !draftInsideBasicArc(
              profile: _profile,
              origin: _hero,
              aim: aim,
              target: enemy.position,
            )) {
          continue;
        }
        sim.applyHit(enemy.id, _profile.basicDamage);
        hitAny = true;
      }
    }
    if (!_boss.defeated &&
        draftInsideBasicArc(
          profile: _profile,
          origin: _hero,
          aim: aim,
          target: _boss.position,
        )) {
      _boss.takeDamage(_profile.basicDamage);
      hitAny = true;
    }
    if (hitAny) {
      _qi = (_qi + _profile.basicQiGain).clamp(
        0,
        PlayableDraftTuning.playerQiCapacity,
      );
    }
  }

  void _castClear() {
    if (_runOver || _qi < PlayableDraftTuning.clearQiCost) return;
    setState(() {
      _qi -= PlayableDraftTuning.clearQiCost;
      final aim = Vector2(1, 0);
      for (final sim in [_groupA, _groupB]) {
        for (final enemy in sim.enemies) {
          if (!enemy.alive ||
              !enemy.hasEntered ||
              !draftInsideClearZone(
                profile: _profile,
                origin: _hero,
                aim: aim,
                point: enemy.position,
              )) {
            continue;
          }
          sim.applyHit(enemy.id, _profile.clearDamage);
        }
      }
      if (!_boss.defeated &&
          draftInsideClearZone(
            profile: _profile,
            origin: _hero,
            aim: aim,
            point: _boss.position,
          )) {
        _boss.takeDamage(_profile.clearDamage);
      }
    });
  }

  void _advanceHero(double delta) {
    if (_runOver) return;
    setState(() {
      _heroX = (_heroX + delta).clamp(
        80,
        PlayableDraftTuning.worldWidth - 80,
      );
    });
  }

  void _setStyle(DraftStyleKind kind) {
    if (_runOver) return;
    setState(() => _styleKind = kind);
  }

  void _reset() {
    setState(() {
      _groupA = DraftEnemyGroupSim(count: 6, seed: 20260814);
      _groupB = DraftEnemyGroupSim(count: 10, seed: 20260815);
      _boss = DraftBossBrain(spawn: Vector2(3150, 505));
      _groupA.activate(cameraLeft: 0);
      _groupB.activate(cameraLeft: 1220);
      _heroX = 420;
      _health = PlayableDraftTuning.playerMaxHealth;
      _qi = PlayableDraftTuning.playerStartingQi;
      _basicRemaining = 0;
      _elapsed = 0;
      _strikesTaken = 0;
      _runOver = false;
    });
  }

  String get _statusLine {
    if (_runOver) {
      return _victory
          ? 'RUN OVER · BOSS DOWN · press RESET'
          : 'RUN OVER · HERO DOWN · press RESET';
    }
    return 't=${_elapsed.toStringAsFixed(1)}s · hero x=${_heroX.round()} · '
        'strikes taken=$_strikesTaken · boss phase '
        '${_boss.phase == DraftBossPhase.one ? '1' : '2'} '
        '(${_boss.state.name})';
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF171815),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PHASE 0B PLAYABLE DRAFT · NOT FINAL · gate_eligible=false\n'
                'deterministic domain readout · placeholder entry · '
                'no Gate evidence is written',
                style: TextStyle(
                  color: Color(0xFFECE2CD),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _statusLine,
                style: const TextStyle(color: Color(0xFFECE2CD), fontSize: 13),
              ),
              const SizedBox(height: 8),
              _Bar(label: 'HP', value: _health / 100, color: 0xFF8A332E),
              _Bar(label: 'QI', value: _qi / 100, color: 0xFF3F6159),
              _Bar(
                label: 'BOSS',
                value: _boss.health / PlayableDraftTuning.bossMaxHealth,
                color: 0xFF6A2F2B,
              ),
              const SizedBox(height: 12),
              Text(
                'group A alive ${_groupA.aliveCount} · '
                'group B alive ${_groupB.aliveCount} · '
                'boss hp ${_boss.health.toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFFB9AF98), fontSize: 12),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _button('◀ MOVE WEST', () => _advanceHero(-160)),
                  _button('MOVE EAST ▶', () => _advanceHero(160)),
                  _button('CAST CLEAR (R)', _castClear),
                  _button(
                    'STYLE: ${_styleKind == DraftStyleKind.surgeCurrent ? '1 SURGE' : '2 SINISTER'}',
                    () => _setStyle(
                      _styleKind == DraftStyleKind.surgeCurrent
                          ? DraftStyleKind.sinisterDraft
                          : DraftStyleKind.surgeCurrent,
                    ),
                  ),
                  _button('RESET (ENTER)', _reset),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _button(String label, VoidCallback onPressed) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFECE2CD),
      side: const BorderSide(color: Color(0xFF57534A)),
    ),
    onPressed: onPressed,
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );
}

final class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final int color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFB9AF98), fontSize: 11),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 9,
            color: Color(color),
            backgroundColor: const Color(0x44ECE2CD),
          ),
        ),
      ],
    ),
  );
}
