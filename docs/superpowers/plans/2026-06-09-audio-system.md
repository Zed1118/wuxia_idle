# 音频系统 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 搭音频引擎并接好全部 hook，零素材也能跑通（缺文件静默 no-op），音量/静音设置持久化。

**Architecture:** 单例 `SoundManager` 持 `AudioBackend` 接口（真实现 `AudioPlayersBackend` 包 audioplayers，默认 `SilentAudioBackend` 让 widget 测不崩，测试注入 `FakeAudioBackend`）。设置走 `shared_preferences`（不碰 Isar）。三类 hook：战斗 SFX 走 `battle_screen._playAction` 边沿、UI SFX 集中在 wuxia_ui 三按钮、BGM 用声明式 `BgmScope` widget 包关键屏。

**Tech Stack:** Flutter / Riverpod codegen (`@riverpod` + build_runner) / audioplayers ^6 / shared_preferences ^2 / 测试用真 SharedPreferences mock + FakeAudioBackend。

**红线（来自 spec）：** 不写 BattleState（战斗 SFX 纯表现层读 actionLog）；音量非战斗数值不进 numbers.yaml；不引 Flame；设置中文走 UiStrings。

---

## File Structure

新增：
- `lib/shared/audio/audio_backend.dart` — `AudioBackend` 抽象 + `SilentAudioBackend`（默认 no-op）
- `lib/shared/audio/audio_players_backend.dart` — 真实现，薄包 audioplayers
- `lib/shared/audio/audio_assets.dart` — `BgmTrack` / `SfxId` enum + 路径映射 + `sfxForAction` 纯函数
- `lib/shared/audio/sound_manager.dart` — 单例引擎，guard try/catch、同轨 no-op、音量/静音
- `lib/shared/audio/bgm_scope.dart` — 声明式 BGM widget
- `lib/features/settings/domain/audio_settings.dart` — 不可变设置值对象
- `lib/features/settings/application/audio_settings_service.dart` — SharedPreferences 读写
- `lib/features/settings/application/audio_settings_provider.dart` — `@riverpod AudioSettingsNotifier`（+ .g.dart）
- `lib/features/settings/presentation/settings_panel.dart` — PaperDialog 设置面板
- `docs/handoff/audio_slot_manifest.md` — 槽位用途/风格清单
- `assets/audio/bgm/.gitkeep` `assets/audio/sfx/.gitkeep`
- 测试：`test/shared/audio/{audio_assets_test,sfx_for_action_test,sound_manager_test}.dart` · `test/features/settings/audio_settings_service_test.dart`

修改：
- `pubspec.yaml` — deps（audioplayers + shared_preferences）+ assets/audio 注册
- `lib/shared/widgets/wuxia_ui/plaque_button.dart` — onTap 包 uiTap
- `lib/shared/widgets/wuxia_ui/plaque_tab.dart` — onTap 包 uiTabSwitch
- `lib/shared/widgets/wuxia_ink_button.dart` — onTap 包 uiTap
- `lib/shared/widgets/wuxia_ui/paper_dialog.dart` — show 时 uiPaperOpen
- `lib/features/battle/presentation/battle_screen.dart` — `_playAction` 末尾接 SFX + body 包 BgmScope
- `lib/features/main_menu/presentation/main_menu.dart` — 设置入口 WuxiaInkButton + body 包 BgmScope
- `lib/features/seclusion/presentation/seclusion_map_list_screen.dart` — body 包 BgmScope
- `lib/shared/strings.dart` — 设置面板文案
- `lib/main.dart` — SoundManager init

---

## Task 0: 依赖与资产目录（无测试，编译门）

**Files:**
- Modify: `pubspec.yaml:8-26`（dependencies）+ `pubspec.yaml:43-72`（assets）
- Create: `assets/audio/bgm/.gitkeep` `assets/audio/sfx/.gitkeep`

- [ ] **Step 1: 加依赖**

`pubspec.yaml` dependencies 段 `cupertino_icons: ^1.0.8` 之后加：
```yaml
  audioplayers: ^6.0.0
  shared_preferences: ^2.2.0
```

- [ ] **Step 2: 注册资产目录**

`pubspec.yaml` flutter.assets 段 `- assets/techniques/` 之后加：
```yaml
    # E 音频系统
    - assets/audio/bgm/
    - assets/audio/sfx/
```

- [ ] **Step 3: 占空目录**

```bash
mkdir -p assets/audio/bgm assets/audio/sfx
touch assets/audio/bgm/.gitkeep assets/audio/sfx/.gitkeep
```

- [ ] **Step 4: pub get**

Run: `flutter pub get`
Expected: 成功，解析出 audioplayers / shared_preferences。

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock assets/audio
git commit -m "feat(audio): 加 audioplayers/shared_preferences 依赖 + assets/audio 目录"
```

---

## Task 1: AudioBackend 接口 + SilentAudioBackend

**Files:**
- Create: `lib/shared/audio/audio_backend.dart`

- [ ] **Step 1: 写接口与默认 no-op 实现**

```dart
import 'dart:async';

/// 抽象音频后端，包住具体播放库（audioplayers），便于测试注入 fake。
abstract class AudioBackend {
  /// 在常驻 BGM 声道循环播放 [assetPath]（相对 assets/，如 'audio/bgm/mainMenu.mp3'），替换当前轨。
  Future<void> playBgm(String assetPath, double volume);
  Future<void> stopBgm();
  void setBgmVolume(double volume);

  /// 一次性 SFX，池化可叠播。
  Future<void> playSfx(String assetPath, double volume);

  Future<void> dispose();
}

/// 默认后端：全部 no-op。让 widget 测/未初始化场景不崩（main 会换成真后端）。
class SilentAudioBackend implements AudioBackend {
  const SilentAudioBackend();
  @override
  Future<void> playBgm(String assetPath, double volume) async {}
  @override
  Future<void> stopBgm() async {}
  @override
  void setBgmVolume(double volume) {}
  @override
  Future<void> playSfx(String assetPath, double volume) async {}
  @override
  Future<void> dispose() async {}
}
```

- [ ] **Step 2: 编译验证**

Run: `flutter analyze lib/shared/audio/audio_backend.dart`
Expected: 0 issue。

- [ ] **Step 3: Commit**

```bash
git add lib/shared/audio/audio_backend.dart
git commit -m "feat(audio): AudioBackend 接口 + SilentAudioBackend 默认 no-op"
```

---

## Task 2: 资产槽位 enum + 路径映射

**Files:**
- Create: `lib/shared/audio/audio_assets.dart`
- Test: `test/shared/audio/audio_assets_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';

void main() {
  test('bgmAssetPath 拼接正确', () {
    expect(bgmAssetPath(BgmTrack.mainMenu), 'audio/bgm/mainMenu.mp3');
    expect(bgmAssetPath(BgmTrack.battle), 'audio/bgm/battle.mp3');
  });

  test('sfxAssetPath 拼接正确', () {
    expect(sfxAssetPath(SfxId.uiTap), 'audio/sfx/uiTap.mp3');
    expect(sfxAssetPath(SfxId.battleCrit), 'audio/sfx/battleCrit.mp3');
  });

  test('全枚举值都能拼出非空路径', () {
    for (final t in BgmTrack.values) {
      expect(bgmAssetPath(t), startsWith('audio/bgm/'));
    }
    for (final s in SfxId.values) {
      expect(sfxAssetPath(s), startsWith('audio/sfx/'));
    }
  });
}
```

> 注：`wuxia_idle` 为 pubspec name，确认 `head -1 pubspec.yaml` 一致；不一致按实际包名替换 import。

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/shared/audio/audio_assets_test.dart`
Expected: FAIL（audio_assets.dart 不存在 / 符号未定义）。

- [ ] **Step 3: 写实现**

```dart
/// BGM 轨道槽位。文件名用 enum.name（camelCase），manifest 同步登记。
enum BgmTrack { mainMenu, battle, seclusion }

/// SFX 槽位。battleDeath / reward 暂留位不接线（YAGNI）。
enum SfxId {
  uiTap,
  uiTabSwitch,
  uiPaperOpen,
  battleHit,
  battleCrit,
  battleUlt,
  battleDeath,
  reward,
}

String bgmAssetPath(BgmTrack track) => 'audio/bgm/${track.name}.mp3';
String sfxAssetPath(SfxId id) => 'audio/sfx/${id.name}.mp3';
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/shared/audio/audio_assets_test.dart`
Expected: PASS（3 测）。

- [ ] **Step 5: Commit**

```bash
git add lib/shared/audio/audio_assets.dart test/shared/audio/audio_assets_test.dart
git commit -m "feat(audio): BgmTrack/SfxId 槽位 enum + 路径映射"
```

---

## Task 3: sfxForAction 纯函数（战斗 SFX 映射）

**Files:**
- Modify: `lib/shared/audio/audio_assets.dart`（追加函数）
- Test: `test/shared/audio/sfx_for_action_test.dart`

> 依赖 `BattleAction`（`lib/features/battle/domain/battle_state.dart:23`）与 `AttackResult`（`lib/features/battle/domain/damage_calculator.dart:266`，字段 `isCritical` / `isDodged`）。死亡 SFX v1 不做（命中点拿不到 combatant HP），`battleDeath` 留位。

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';

BattleAction _action({AttackResult? result}) => BattleAction(
      tick: 0,
      actorId: 1,
      targetId: 2,
      attackResult: result,
      description: 'x',
    );

void main() {
  test('无 attackResult → null（非攻击 action 不出声）', () {
    expect(sfxForAction(action: _action(), isUltimate: false), isNull);
  });

  test('闪避 → null', () {
    final r = AttackResult.dodged();
    expect(sfxForAction(action: _action(result: r), isUltimate: false), isNull);
  });

  test('大招优先 → battleUlt', () {
    final r = AttackResult.normal(damage: 100, isCritical: true);
    expect(sfxForAction(action: _action(result: r), isUltimate: true), SfxId.battleUlt);
  });

  test('暴击 → battleCrit', () {
    final r = AttackResult.normal(damage: 100, isCritical: true);
    expect(sfxForAction(action: _action(result: r), isUltimate: false), SfxId.battleCrit);
  });

  test('普通命中 → battleHit', () {
    final r = AttackResult.normal(damage: 100, isCritical: false);
    expect(sfxForAction(action: _action(result: r), isUltimate: false), SfxId.battleHit);
  });
}
```

> **实装前必做**：`grep -n "factory AttackResult\|AttackResult(" lib/features/battle/domain/damage_calculator.dart` 确认构造方式。若无 `.dodged()` / `.normal()` 工厂，改用真实构造器/已有测试 fixture（参考 `test/features/battle/` 下现成 AttackResult 造法），保持测试能编过即可——**不要**新增生产代码工厂只为测试。

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/shared/audio/sfx_for_action_test.dart`
Expected: FAIL（sfxForAction 未定义）。

- [ ] **Step 3: 写实现（追加到 audio_assets.dart）**

```dart
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// 战斗动作 → SFX 纯映射。表现层用，不读/写 BattleState。
/// 优先级：大招 > 暴击 > 普通命中；闪避/无结果不出声。死亡 SFX v1 不做。
SfxId? sfxForAction({required BattleAction action, required bool isUltimate}) {
  final r = action.attackResult;
  if (r == null) return null;
  if (r.isDodged) return null;
  if (isUltimate) return SfxId.battleUlt;
  if (r.isCritical) return SfxId.battleCrit;
  return SfxId.battleHit;
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/shared/audio/sfx_for_action_test.dart`
Expected: PASS（5 测）。

- [ ] **Step 5: Commit**

```bash
git add lib/shared/audio/audio_assets.dart test/shared/audio/sfx_for_action_test.dart
git commit -m "feat(audio): sfxForAction 战斗动作→SFX 纯映射"
```

---

## Task 4: AudioSettings 值对象

**Files:**
- Create: `lib/features/settings/domain/audio_settings.dart`

- [ ] **Step 1: 写实现（值对象足够简单，随服务测覆盖，跳独立测）**

```dart
/// 音频设置值对象（不可变）。默认 0.8/0.7/0.9/false（spec §3）。
class AudioSettings {
  final double masterVolume;
  final double bgmVolume;
  final double sfxVolume;
  final bool muted;

  const AudioSettings({
    this.masterVolume = 0.8,
    this.bgmVolume = 0.7,
    this.sfxVolume = 0.9,
    this.muted = false,
  });

  AudioSettings copyWith({
    double? masterVolume,
    double? bgmVolume,
    double? sfxVolume,
    bool? muted,
  }) {
    return AudioSettings(
      masterVolume: masterVolume ?? this.masterVolume,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      muted: muted ?? this.muted,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AudioSettings &&
      other.masterVolume == masterVolume &&
      other.bgmVolume == bgmVolume &&
      other.sfxVolume == sfxVolume &&
      other.muted == muted;

  @override
  int get hashCode => Object.hash(masterVolume, bgmVolume, sfxVolume, muted);
}
```

- [ ] **Step 2: 编译验证**

Run: `flutter analyze lib/features/settings/domain/audio_settings.dart`
Expected: 0 issue。

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/domain/audio_settings.dart
git commit -m "feat(audio): AudioSettings 值对象"
```

---

## Task 5: AudioSettingsService（SharedPreferences 读写）

**Files:**
- Create: `lib/features/settings/application/audio_settings_service.dart`
- Test: `test/features/settings/audio_settings_service_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/features/settings/application/audio_settings_service.dart';
import 'package:wuxia_idle/features/settings/domain/audio_settings.dart';

void main() {
  test('空 prefs → 返回默认值', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await AudioSettingsService().load();
    expect(s.masterVolume, 0.8);
    expect(s.bgmVolume, 0.7);
    expect(s.sfxVolume, 0.9);
    expect(s.muted, false);
  });

  test('save → load 往返一致', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = AudioSettingsService();
    const written = AudioSettings(
      masterVolume: 0.5,
      bgmVolume: 0.4,
      sfxVolume: 0.3,
      muted: true,
    );
    await svc.save(written);
    final read = await svc.load();
    expect(read, written);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/settings/audio_settings_service_test.dart`
Expected: FAIL（service 不存在）。

- [ ] **Step 3: 写实现**

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/audio_settings.dart';

/// 音频设置持久化（shared_preferences，key 前缀 audio.）。设置≠存档，与 Isar 隔离。
class AudioSettingsService {
  static const _kMaster = 'audio.master';
  static const _kBgm = 'audio.bgm';
  static const _kSfx = 'audio.sfx';
  static const _kMuted = 'audio.muted';

  Future<AudioSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AudioSettings(
      masterVolume: p.getDouble(_kMaster) ?? 0.8,
      bgmVolume: p.getDouble(_kBgm) ?? 0.7,
      sfxVolume: p.getDouble(_kSfx) ?? 0.9,
      muted: p.getBool(_kMuted) ?? false,
    );
  }

  Future<void> save(AudioSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kMaster, s.masterVolume);
    await p.setDouble(_kBgm, s.bgmVolume);
    await p.setDouble(_kSfx, s.sfxVolume);
    await p.setBool(_kMuted, s.muted);
  }
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/settings/audio_settings_service_test.dart`
Expected: PASS（2 测）。

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/application/audio_settings_service.dart test/features/settings/audio_settings_service_test.dart
git commit -m "feat(audio): AudioSettingsService shared_preferences 读写"
```

---

## Task 6: SoundManager 引擎

**Files:**
- Create: `lib/shared/audio/sound_manager.dart`
- Test: `test/shared/audio/sound_manager_test.dart`

- [ ] **Step 1: 写失败测试（含 FakeAudioBackend）**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/audio/audio_backend.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/shared/audio/sound_manager.dart';
import 'package:wuxia_idle/features/settings/domain/audio_settings.dart';

class FakeAudioBackend implements AudioBackend {
  final List<String> bgmPlays = [];
  final List<String> sfxPlays = [];
  final List<double> bgmVolumes = [];
  int stopBgmCount = 0;
  Set<String> throwOnPaths = {};

  @override
  Future<void> playBgm(String assetPath, double volume) async {
    if (throwOnPaths.contains(assetPath)) throw Exception('missing asset');
    bgmPlays.add(assetPath);
  }
  @override
  Future<void> stopBgm() async => stopBgmCount++;
  @override
  void setBgmVolume(double volume) => bgmVolumes.add(volume);
  @override
  Future<void> playSfx(String assetPath, double volume) async {
    if (throwOnPaths.contains(assetPath)) throw Exception('missing asset');
    sfxPlays.add(assetPath);
  }
  @override
  Future<void> dispose() async {}
}

void main() {
  test('同轨重复 playBgm 只播一次', () async {
    final fake = FakeAudioBackend();
    final m = SoundManager(fake);
    await m.playBgm(BgmTrack.mainMenu);
    await m.playBgm(BgmTrack.mainMenu);
    expect(fake.bgmPlays.length, 1);
  });

  test('换轨 playBgm 再播', () async {
    final fake = FakeAudioBackend();
    final m = SoundManager(fake);
    await m.playBgm(BgmTrack.mainMenu);
    await m.playBgm(BgmTrack.battle);
    expect(fake.bgmPlays.length, 2);
  });

  test('缺素材 playSfx 不抛（静默 no-op）', () async {
    final fake = FakeAudioBackend()..throwOnPaths = {sfxAssetPath(SfxId.uiTap)};
    final m = SoundManager(fake);
    await m.playSfx(SfxId.uiTap); // 不应抛
    expect(fake.sfxPlays, isEmpty);
  });

  test('静音时 playSfx 不调后端', () async {
    final fake = FakeAudioBackend();
    final m = SoundManager(fake);
    await m.applySettings(const AudioSettings(muted: true));
    await m.playSfx(SfxId.uiTap);
    expect(fake.sfxPlays, isEmpty);
  });

  test('applySettings 把 master*bgm 应用到后端 bgm 音量', () async {
    final fake = FakeAudioBackend();
    final m = SoundManager(fake);
    await m.applySettings(const AudioSettings(masterVolume: 0.5, bgmVolume: 0.4));
    expect(fake.bgmVolumes.last, closeTo(0.2, 1e-9));
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/shared/audio/sound_manager_test.dart`
Expected: FAIL（SoundManager 未定义）。

- [ ] **Step 3: 写实现**

```dart
import 'package:flutter/foundation.dart';
import 'audio_assets.dart';
import 'audio_backend.dart';
import '../../features/settings/domain/audio_settings.dart';

/// 音频引擎单例。持后端 + 当前设置，算有效音量、同轨去重、缺素材 guard。
class SoundManager {
  SoundManager(this._backend);

  /// 全局单例。默认 SilentAudioBackend（widget 测/未 init 不崩）；main 换真后端。
  static SoundManager instance = SoundManager(const SilentAudioBackend());

  final AudioBackend _backend;
  AudioSettings _settings = const AudioSettings();
  BgmTrack? _currentBgm;
  bool _warned = false;

  double get _bgmEffective =>
      _settings.muted ? 0.0 : _settings.masterVolume * _settings.bgmVolume;
  double get _sfxEffective =>
      _settings.muted ? 0.0 : _settings.masterVolume * _settings.sfxVolume;

  /// 应用一份设置（load 后 / 用户改动后调）。
  Future<void> applySettings(AudioSettings s) async {
    _settings = s;
    _backend.setBgmVolume(_bgmEffective);
  }

  Future<void> playBgm(BgmTrack track) async {
    if (_currentBgm == track) return;
    _currentBgm = track;
    await _guard(() => _backend.playBgm(bgmAssetPath(track), _bgmEffective));
  }

  Future<void> stopBgm() async {
    _currentBgm = null;
    await _guard(_backend.stopBgm);
  }

  Future<void> playSfx(SfxId id) async {
    if (_settings.muted) return;
    await _guard(() => _backend.playSfx(sfxAssetPath(id), _sfxEffective));
  }

  void setMasterVolume(double v) {
    _settings = _settings.copyWith(masterVolume: v);
    _backend.setBgmVolume(_bgmEffective);
  }
  void setBgmVolume(double v) {
    _settings = _settings.copyWith(bgmVolume: v);
    _backend.setBgmVolume(_bgmEffective);
  }
  void setSfxVolume(double v) {
    _settings = _settings.copyWith(sfxVolume: v);
  }
  void setMuted(bool m) {
    _settings = _settings.copyWith(muted: m);
    _backend.setBgmVolume(_bgmEffective);
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!_warned) {
        debugPrint('[SoundManager] 音频播放失败（素材缺失？）: $e');
        _warned = true;
      }
    }
  }
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/shared/audio/sound_manager_test.dart`
Expected: PASS（5 测）。

- [ ] **Step 5: Commit**

```bash
git add lib/shared/audio/sound_manager.dart test/shared/audio/sound_manager_test.dart
git commit -m "feat(audio): SoundManager 引擎(同轨去重+缺素材guard+音量/静音)"
```

---

## Task 7: AudioPlayersBackend 真实现（薄包，无单测）

**Files:**
- Create: `lib/shared/audio/audio_players_backend.dart`

> audioplayers 6.x：`AudioPlayer` + `AssetSource(path)`（path 相对 assets/）。BGM 用 1 个 player 设 `ReleaseMode.loop`；SFX 用 round-robin 池叠播。**实装前**确认 6.x API：`grep -rn "class AudioPlayer\|AssetSource\|ReleaseMode" ~/.pub-cache/hosted/pub.dev/audioplayers-*/lib/ | head` 或看 pub.dev 文档，按实际签名微调。

- [ ] **Step 1: 写实现**

```dart
import 'package:audioplayers/audioplayers.dart';
import 'audio_backend.dart';

/// audioplayers 真后端。BGM 单 player 循环；SFX 池 round-robin 叠播。
class AudioPlayersBackend implements AudioBackend {
  AudioPlayersBackend({int sfxPoolSize = 5})
      : _sfxPool = List.generate(sfxPoolSize, (_) => AudioPlayer());

  final AudioPlayer _bgm = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  final List<AudioPlayer> _sfxPool;
  int _sfxCursor = 0;

  @override
  Future<void> playBgm(String assetPath, double volume) async {
    await _bgm.stop();
    await _bgm.setVolume(volume);
    await _bgm.play(AssetSource(assetPath), volume: volume);
  }

  @override
  Future<void> stopBgm() async => _bgm.stop();

  @override
  void setBgmVolume(double volume) {
    _bgm.setVolume(volume);
  }

  @override
  Future<void> playSfx(String assetPath, double volume) async {
    final p = _sfxPool[_sfxCursor];
    _sfxCursor = (_sfxCursor + 1) % _sfxPool.length;
    await p.stop();
    await p.play(AssetSource(assetPath), volume: volume);
  }

  @override
  Future<void> dispose() async {
    await _bgm.dispose();
    for (final p in _sfxPool) {
      await p.dispose();
    }
  }
}
```

- [ ] **Step 2: 编译验证**

Run: `flutter analyze lib/shared/audio/audio_players_backend.dart`
Expected: 0 issue（若 API 签名不符，按 audioplayers 6.x 实际调整）。

- [ ] **Step 3: Commit**

```bash
git add lib/shared/audio/audio_players_backend.dart
git commit -m "feat(audio): AudioPlayersBackend audioplayers 真后端"
```

---

## Task 8: AudioSettingsNotifier provider（codegen）

**Files:**
- Create: `lib/features/settings/application/audio_settings_provider.dart`（+ 生成 `.g.dart`）

> 体例参考 `lib/core/application/battle_providers.dart`（`@riverpod` + `part '*.g.dart'`）。provider 单测从略（spec 测试计划未列；逻辑已由 service + SoundManager 测覆盖）。

- [ ] **Step 1: 写 provider**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/audio_settings.dart';
import 'audio_settings_service.dart';
import '../../../shared/audio/sound_manager.dart';

part 'audio_settings_provider.g.dart';

@riverpod
class AudioSettingsNotifier extends _$AudioSettingsNotifier {
  final AudioSettingsService _service = AudioSettingsService();

  @override
  Future<AudioSettings> build() async {
    final s = await _service.load();
    await SoundManager.instance.applySettings(s);
    return s;
  }

  Future<void> _update(AudioSettings next) async {
    state = AsyncData(next);
    await _service.save(next);
    await SoundManager.instance.applySettings(next);
  }

  Future<void> setMasterVolume(double v) =>
      _update(state.requireValue.copyWith(masterVolume: v));
  Future<void> setBgmVolume(double v) =>
      _update(state.requireValue.copyWith(bgmVolume: v));
  Future<void> setSfxVolume(double v) =>
      _update(state.requireValue.copyWith(sfxVolume: v));
  Future<void> setMuted(bool m) =>
      _update(state.requireValue.copyWith(muted: m));
}
```

- [ ] **Step 2: 跑 build_runner 生成 .g.dart**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: 生成 `audio_settings_provider.g.dart`，无错误。

- [ ] **Step 3: 编译验证**

Run: `flutter analyze lib/features/settings/`
Expected: 0 issue。

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/application/audio_settings_provider.dart lib/features/settings/application/audio_settings_provider.g.dart
git commit -m "feat(audio): AudioSettingsNotifier provider(改动即存+应用到引擎)"
```

---

## Task 9: UI SFX hook（三按钮 + 对话框）

**Files:**
- Modify: `lib/shared/widgets/wuxia_ui/plaque_button.dart:42`
- Modify: `lib/shared/widgets/wuxia_ui/plaque_tab.dart:36`
- Modify: `lib/shared/widgets/wuxia_ink_button.dart:41`
- Modify: `lib/shared/widgets/wuxia_ui/paper_dialog.dart:24`

> 这些是无状态 kit 组件，用 `SoundManager.instance.playSfx(...)` 单例直调（不引 ref）。默认 SilentAudioBackend 让现有 widget 测不受影响。

- [ ] **Step 1: plaque_button onTap 包一层**

`plaque_button.dart` 顶部加 import：
```dart
import '../../audio/sound_manager.dart';
import '../../audio/audio_assets.dart';
```
把 `onTap: disabled ? null : onTap,` 改为：
```dart
onTap: disabled
    ? null
    : () {
        SoundManager.instance.playSfx(SfxId.uiTap);
        onTap?.call();
      },
```

- [ ] **Step 2: plaque_tab onTap 包一层**

`plaque_tab.dart` 加同样两条 import，把 `onTap: onTap,` 改为：
```dart
onTap: onTap == null
    ? null
    : () {
        SoundManager.instance.playSfx(SfxId.uiTabSwitch);
        onTap!();
      },
```

- [ ] **Step 3: wuxia_ink_button onTap 包一层**

`wuxia_ink_button.dart` 加 import（注意相对路径：此文件在 `lib/shared/widgets/`，audio 在 `lib/shared/audio/`）：
```dart
import '../audio/sound_manager.dart';
import '../audio/audio_assets.dart';
```
把 `onTap: disabled ? null : onTap,` 改为：
```dart
onTap: disabled
    ? null
    : () {
        SoundManager.instance.playSfx(SfxId.uiTap);
        onTap?.call();
      },
```

- [ ] **Step 4: paper_dialog show 时出声**

`paper_dialog.dart` 加 import + 在 `show` 内 `return showDialog<T>(` 之前加一行：
```dart
SoundManager.instance.playSfx(SfxId.uiPaperOpen);
```

- [ ] **Step 5: 编译 + 现有 widget 测不回归**

Run: `flutter analyze lib/shared/widgets/`
Run: `flutter test test/shared/widgets/`
Expected: analyze 0；现有 wuxia_ui widget 测全过（SilentAudioBackend 默认，SFX 调用 no-op 不崩）。

- [ ] **Step 6: Commit**

```bash
git add lib/shared/widgets/wuxia_ui/plaque_button.dart lib/shared/widgets/wuxia_ui/plaque_tab.dart lib/shared/widgets/wuxia_ink_button.dart lib/shared/widgets/wuxia_ui/paper_dialog.dart
git commit -m "feat(audio): UI SFX hook(三按钮 onTap + PaperDialog 出现)"
```

---

## Task 10: 战斗 SFX hook（_playAction）

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart:235-258`（`_playAction`）

- [ ] **Step 1: 确认 import + 接线点**

确认 `battle_screen.dart` 已能引用 audio：顶部加
```dart
import '../../../shared/audio/sound_manager.dart';
import '../../../shared/audio/audio_assets.dart';
```
（`audio_assets.dart` 已 export `sfxForAction` + `isUltimateCaptionSkill` 在本文件已可用。）

- [ ] **Step 2: 在 _playAction 末尾接 SFX**

在 `_playAction` 方法体最后（`if (isUltimateCaptionSkill(action.skill)) {...}` 块之后）加：
```dart
final sfx = sfxForAction(
  action: action,
  isUltimate: isUltimateCaptionSkill(action.skill),
);
if (sfx != null) {
  SoundManager.instance.playSfx(sfx);
}
```

- [ ] **Step 3: 编译 + 战斗屏现有测不回归**

Run: `flutter analyze lib/features/battle/`
Run: `flutter test test/features/battle/`
Expected: analyze 0；战斗测全过（SoundManager 单例默认 silent，不影响断言）。

- [ ] **Step 4: Commit**

```bash
git add lib/features/battle/presentation/battle_screen.dart
git commit -m "feat(audio): 战斗 SFX hook(_playAction 边沿映射 sfxForAction)"
```

---

## Task 11: BgmScope widget + 包关键屏

**Files:**
- Create: `lib/shared/audio/bgm_scope.dart`
- Modify: `lib/features/main_menu/presentation/main_menu.dart`（body 包 BgmScope.mainMenu）
- Modify: `lib/features/battle/presentation/battle_screen.dart`（body 包 BgmScope.battle）
- Modify: `lib/features/seclusion/presentation/seclusion_map_list_screen.dart`（body 包 BgmScope.seclusion）

- [ ] **Step 1: 写 BgmScope**

```dart
import 'package:flutter/widgets.dart';
import 'audio_assets.dart';
import 'sound_manager.dart';

/// 声明式 BGM 作用域：挂载即切到 [track]（同轨 no-op）。无中央路由表。
class BgmScope extends StatefulWidget {
  const BgmScope({super.key, required this.track, required this.child});
  final BgmTrack track;
  final Widget child;

  @override
  State<BgmScope> createState() => _BgmScopeState();
}

class _BgmScopeState extends State<BgmScope> {
  @override
  void initState() {
    super.initState();
    SoundManager.instance.playBgm(widget.track);
  }

  @override
  void didUpdateWidget(BgmScope old) {
    super.didUpdateWidget(old);
    if (old.track != widget.track) {
      SoundManager.instance.playBgm(widget.track);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

- [ ] **Step 2: 包主菜单**

`main_menu.dart` 加 import：
```dart
import '../../../shared/audio/bgm_scope.dart';
import '../../../shared/audio/audio_assets.dart';
```
找到 `build` 返回的最外层（Scaffold 或其 body 顶层 widget），用 `BgmScope(track: BgmTrack.mainMenu, child: <原 widget>)` 包住。
> **实装时**：`grep -n "Widget build\|return Scaffold\|body:" lib/features/main_menu/presentation/main_menu.dart` 定位 build 顶层，在最外层包 BgmScope（包整个返回值最稳）。

- [ ] **Step 3: 包战斗屏**

`battle_screen.dart` 加同样 import，build 顶层返回值包 `BgmScope(track: BgmTrack.battle, child: ...)`。

- [ ] **Step 4: 包闭关地图屏**

`seclusion_map_list_screen.dart` 加 import（相对路径按文件位置 `../../../shared/audio/...`），build 顶层包 `BgmScope(track: BgmTrack.seclusion, child: ...)`。

- [ ] **Step 5: 编译 + 相关屏测不回归**

Run: `flutter analyze lib/`
Run: `flutter test test/features/main_menu/ test/features/battle/ test/features/seclusion/`
Expected: analyze 0；相关 widget 测全过（BgmScope initState 调 silent 单例不崩）。

- [ ] **Step 6: Commit**

```bash
git add lib/shared/audio/bgm_scope.dart lib/features/main_menu/presentation/main_menu.dart lib/features/battle/presentation/battle_screen.dart lib/features/seclusion/presentation/seclusion_map_list_screen.dart
git commit -m "feat(audio): BgmScope 声明式 BGM + 包主菜单/战斗/闭关屏"
```

---

## Task 12: 设置面板 UI + 文案 + 主菜单入口

**Files:**
- Modify: `lib/shared/strings.dart`（追加文案）
- Create: `lib/features/settings/presentation/settings_panel.dart`
- Modify: `lib/features/main_menu/presentation/main_menu.dart`（设置入口 WuxiaInkButton）

- [ ] **Step 1: 加 UiStrings 文案**

`lib/shared/strings.dart` 主菜单段落追加：
```dart
  // 设置面板
  static const String mainMenuSettings = '设置';
  static const String mainMenuSettingsHint = '音量 · 静音';
  static const String settingsTitle = '设置';
  static const String settingsMasterVolume = '总音量';
  static const String settingsBgmVolume = '背景音乐';
  static const String settingsSfxVolume = '音效';
  static const String settingsMuted = '静音';
  static const String settingsClose = '关闭';
```

- [ ] **Step 2: 写设置面板**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/strings.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../application/audio_settings_provider.dart';
import '../domain/audio_settings.dart';

/// 设置面板：3 滑条 + 静音开关，改动即存（provider 内持久化 + 应用引擎）。
class SettingsPanel extends ConsumerWidget {
  const SettingsPanel({super.key});

  static Future<void> show(BuildContext context) {
    return PaperDialog.show<void>(
      context,
      title: UiStrings.settingsTitle,
      body: const SizedBox(width: 360, child: SettingsPanel()),
      actions: [
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(UiStrings.settingsClose),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(audioSettingsNotifierProvider);
    final notifier = ref.read(audioSettingsNotifierProvider.notifier);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text('$e'),
      ),
      data: (s) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _VolumeRow(
            label: UiStrings.settingsMasterVolume,
            value: s.masterVolume,
            enabled: !s.muted,
            onChanged: notifier.setMasterVolume,
          ),
          _VolumeRow(
            label: UiStrings.settingsBgmVolume,
            value: s.bgmVolume,
            enabled: !s.muted,
            onChanged: notifier.setBgmVolume,
          ),
          _VolumeRow(
            label: UiStrings.settingsSfxVolume,
            value: s.sfxVolume,
            enabled: !s.muted,
            onChanged: notifier.setSfxVolume,
          ),
          SwitchListTile(
            title: const Text(UiStrings.settingsMuted),
            value: s.muted,
            onChanged: notifier.setMuted,
          ),
        ],
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 72, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}
```

> **实装时核对** `PaperDialog.show` 签名（`paper_dialog.dart:24`：`show<T>(context, {required title, required body, required actions, bool showSeal, bool barrierDismissible})`），上面已按此签名写。

- [ ] **Step 3: 主菜单加设置入口**

`main_menu.dart` 加 import：
```dart
import '../../settings/presentation/settings_panel.dart';
```
在菜单项列表（`coreItems` 或合适分组，参考 `main_menu.dart:151+` 的 WuxiaInkButton 体例）加：
```dart
WuxiaInkButton(
  label: UiStrings.mainMenuSettings,
  hint: UiStrings.mainMenuSettingsHint,
  icon: Icons.settings_outlined,
  onTap: () => SettingsPanel.show(context),
),
```
> **实装时**：`grep -n "WuxiaInkButton(" lib/features/main_menu/presentation/main_menu.dart` 看现有项必填参数（label/hint/icon/thumbnailPath/status/onTap），按现成项补齐——thumbnailPath/status 若非必填可省，必填则按现有体例给值或确认可空。

- [ ] **Step 4: 编译 + 测**

Run: `flutter analyze lib/`
Run: `flutter test test/features/main_menu/`
Expected: analyze 0；主菜单测全过。

- [ ] **Step 5: Commit**

```bash
git add lib/shared/strings.dart lib/features/settings/presentation/settings_panel.dart lib/features/main_menu/presentation/main_menu.dart
git commit -m "feat(audio): 设置面板(3滑条+静音)+ 主菜单设置入口 + UiStrings"
```

---

## Task 13: main.dart 初始化

**Files:**
- Modify: `lib/main.dart:11-28`

- [ ] **Step 1: 接 SoundManager init**

`main.dart` 加 import：
```dart
import 'shared/audio/sound_manager.dart';
import 'shared/audio/audio_players_backend.dart';
import 'features/settings/application/audio_settings_service.dart';
```
在 `WidgetsFlutterBinding.ensureInitialized();` 之后、`if (!kReleaseMode)` VISUAL_ROUTE 分支之前加：
```dart
SoundManager.instance = SoundManager(AudioPlayersBackend());
await SoundManager.instance.applySettings(await AudioSettingsService().load());
```
> 放在 VISUAL_ROUTE 短路之前，保证截图模式也初始化（silent 时无碍）；放之后亦可——二选一，放之前更稳。

- [ ] **Step 2: 编译 + 全量冒烟**

Run: `flutter analyze lib/main.dart`
Expected: 0 issue。

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat(audio): main 启动初始化 SoundManager + load 设置"
```

---

## Task 14: 槽位 manifest + 全量验收

**Files:**
- Create: `docs/handoff/audio_slot_manifest.md`

- [ ] **Step 1: 写 manifest**

按 enum 实际值列每个 BGM/SFX 槽位：用途 + 期望文件名（`<enum.name>.mp3`）+ 风格提示（水墨克制：古琴/箫/雨/竹；SFX 轻）。供后续找素材。BgmTrack：mainMenu/battle/seclusion；SfxId：uiTap/uiTabSwitch/uiPaperOpen/battleHit/battleCrit/battleUlt/battleDeath(留位)/reward(留位)。

- [ ] **Step 2: 全量 analyze**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: 全量测试**

Run: `flutter test`
Expected: 全过（baseline 1763 + 新增音频测 ~15；记录新总数）。

- [ ] **Step 4: 零素材冒烟（手动）**

Run: `flutter run -d macos`（或现有 build 脚本）
确认：游戏正常启动、点按钮/切 tab/进战斗/进闭关均不报错（debugPrint 可能记一次 missing asset，属预期）。

- [ ] **Step 5: Commit**

```bash
git add docs/handoff/audio_slot_manifest.md
git commit -m "docs(audio): 音频槽位 manifest + 全量验收"
```

---

## Self-Review 结果

**Spec 覆盖：**
- 引擎 SoundManager ✅ Task 6 / AudioBackend 可测 ✅ Task 1 / 真后端 ✅ Task 7
- 资产槽位 enum + manifest ✅ Task 2 / Task 14
- 设置(shared_preferences) ✅ Task 4/5/8 / 设置面板 ✅ Task 12
- 三类 hook：战斗 SFX ✅ Task 10（走 actionLog 边沿 _playAction，不写 BattleState）/ UI SFX ✅ Task 9 / BGM BgmScope ✅ Task 11
- 测试 5 类 ✅ Task 2/3/5/6（真音频不测，符合 spec）
- 生命周期 main init ✅ Task 13

**红线核对：** 不写 BattleState（Task 10 只读 action 调单例）✅ / 音量不进 numbers.yaml（走 prefs）✅ / 不引 Flame（audioplayers 纯音频库）✅ / 中文走 UiStrings（Task 12）✅

**Spec 偏差（实装需知）：**
1. **死亡 SFX v1 不做** —— `_playAction` 命中点拿不到 combatant 死亡信号（AttackResult 无 isDead），强接需读 BattleState 内部违红线/加复杂度。`battleDeath` enum 留位，后续有信号再接。
2. **UI SFX 多包一个 WuxiaInkButton** —— spec 只提 PlaqueButton/PlaqueTab，但主菜单实际用 WuxiaInkButton（recon 证实），故一并包（Task 9 Step 3），覆盖更全。
3. **provider 用 codegen** —— 项目锁 `@riverpod` + build_runner（recon 证实），按此写（Task 8），需跑 build_runner。

**类型一致性：** `sfxForAction({action, isUltimate})` 签名 Task 3 定义、Task 10 调用一致 ✅；`SoundManager(_backend)` 构造 + `static instance` Task 6 定义、Task 9/10/11/13 引用一致 ✅；`AudioSettings.copyWith` Task 4 定义、Task 6/8 用一致 ✅；`PaperDialog.show` 签名 Task 12 按 recon 锚点 ✅。

**实装期 3 处必做 grep 校验（已在对应 task 标注）：** AttackResult 构造方式（Task 3）/ audioplayers 6.x API 签名（Task 7）/ WuxiaInkButton 必填参数 + main_menu build 顶层（Task 11/12）。
