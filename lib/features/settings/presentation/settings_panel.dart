import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/strings.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../application/audio_settings_provider.dart';
import '../application/gameplay_settings_provider.dart';
import '../domain/gameplay_settings.dart';

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
    final async = ref.watch(audioSettingsProvider);
    final notifier = ref.read(audioSettingsProvider.notifier);
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
          const Divider(height: 1),
          const _AutoPlayDefaultTile(),
        ],
      ),
    );
  }
}

/// 半手动战斗 P0 步骤5-G2:全局「自动战斗」默认开关。
/// 已通关关卡是否默认走自动重演(每关可在选关屏覆盖)。
class _AutoPlayDefaultTile extends ConsumerWidget {
  const _AutoPlayDefaultTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gameplaySettingsProvider);
    final on = async.maybeWhen(
      data: (d) => d.autoPlayDefault,
      orElse: () => true,
    );
    return SwitchListTile(
      title: const Text(UiStrings.settingsAutoPlayDefault),
      subtitle: const Text(UiStrings.settingsAutoPlayDefaultHint),
      value: on,
      onChanged: (v) async {
        await ref
            .read(gameplaySettingsServiceProvider)
            .save(GameplaySettings(autoPlayDefault: v));
        ref.invalidate(gameplaySettingsProvider);
      },
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
