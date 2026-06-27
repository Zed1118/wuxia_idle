import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_exit.dart';
import '../../../shared/strings.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../save_management/application/save_management_providers.dart';
import '../../save_management/application/save_management_service.dart';
import '../../save_management/domain/save_management_status.dart';
import '../application/audio_settings_provider.dart';
import '../application/display_settings_providers.dart';
import '../application/gameplay_settings_provider.dart';
import '../domain/display_settings.dart';
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
      error: (e, _) =>
          Padding(padding: const EdgeInsets.all(24), child: Text('$e')),
      data: (s) => ConstrainedBox(
        // L1-2 回归:加显示设置段后内容变高,720p 窄高度下底部 overflow。
        // 限高 80% 屏 + 可滚动,内容超高时滚动而非溢出。
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
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
              const Divider(height: 1),
              const _DisplaySettingsSection(),
              const Divider(height: 1),
              const _SaveManagementSection(),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text(UiStrings.settingsAbout),
                subtitle: Text(
                  UiStrings.settingsVersionValue(UiStrings.appVersion),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.power_settings_new),
                title: const Text(UiStrings.settingsQuit),
                onTap: () => AppExit.confirmAndQuit(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveManagementSection extends ConsumerWidget {
  const _SaveManagementSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(saveManagementStatusProvider);
    final service = ref.watch(saveManagementServiceProvider);
    return async.when(
      loading: () => const ListTile(
        leading: Icon(Icons.save_outlined),
        title: Text(UiStrings.saveManagementTitle),
        subtitle: Text(UiStrings.saveManagementLoading),
      ),
      error: (e, _) => ListTile(
        leading: const Icon(Icons.save_outlined),
        title: const Text(UiStrings.saveManagementTitle),
        subtitle: Text(UiStrings.loadFailed(e)),
      ),
      data: (status) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.save_outlined),
            title: const Text(UiStrings.saveManagementTitle),
            subtitle: Text(
              UiStrings.saveManagementSummary(
                status.slotId,
                status.saveVersion,
                status.backupCount,
              ),
            ),
          ),
          _SaveStatusLine(
            label: UiStrings.saveManagementCreatedAt,
            value: UiStrings.saveManagementDateTime(status.createdAt),
          ),
          _SaveStatusLine(
            label: UiStrings.saveManagementLastSavedAt,
            value: UiStrings.saveManagementDateTime(status.lastSavedAt),
          ),
          _SaveStatusLine(
            label: UiStrings.saveManagementLastOnlineAt,
            value: UiStrings.saveManagementDateTime(status.lastOnlineAt),
          ),
          if (status.latestBackup != null)
            _SaveStatusLine(
              label: UiStrings.saveManagementLatestBackup,
              value: status.latestBackup!.fileName,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text(UiStrings.saveManagementCreateBackup),
                  onPressed: service == null
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final backup = await service.createBackup();
                            ref.invalidate(saveManagementStatusProvider);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  UiStrings.saveManagementBackupCreated(
                                    backup.fileName,
                                  ),
                                ),
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(UiStrings.loadFailed(e))),
                            );
                          }
                        },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.restore_outlined),
                  label: const Text(UiStrings.saveManagementRestore),
                  onPressed: null,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text(UiStrings.saveManagementDeleteLatest),
                  onPressed: service == null || status.latestBackup == null
                      ? null
                      : () => _confirmDeleteLatest(
                          context,
                          ref,
                          service,
                          status.latestBackup!,
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                UiStrings.saveManagementRestoreTodo,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _confirmDeleteLatest(
    BuildContext context,
    WidgetRef ref,
    SaveManagementService service,
    SaveBackupInfo backup,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(UiStrings.saveManagementDeleteConfirmTitle),
        content: Text(
          UiStrings.saveManagementDeleteConfirmMessage(backup.fileName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(UiStrings.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(UiStrings.saveManagementDeleteConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await service.deleteBackup(backup);
      ref.invalidate(saveManagementStatusProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(UiStrings.saveManagementBackupDeleted(backup.fileName)),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(UiStrings.loadFailed(e))));
    }
  }
}

class _SaveStatusLine extends StatelessWidget {
  const _SaveStatusLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 84, child: Text(label)),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
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

/// L1 显示设置段:全屏开关 + 窗口分辨率下拉（端机本地偏好,SharedPreferences）。
/// 全屏时分辨率下拉禁用（全屏忽略尺寸）。改动即存即应用到窗口。
class _DisplaySettingsSection extends ConsumerWidget {
  const _DisplaySettingsSection();

  static String _resolutionLabel(WindowSizePreset p) => switch (p) {
    WindowSizePreset.hd720 => UiStrings.settingsResolutionHd720,
    WindowSizePreset.hd900 => UiStrings.settingsResolutionHd900,
    WindowSizePreset.hd1080 => UiStrings.settingsResolutionHd1080,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(displaySettingsProvider);
    final s = async.maybeWhen(
      data: (d) => d,
      orElse: () => const DisplaySettings(),
    );
    final ctl = ref.read(displaySettingsControllerProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: const Text(UiStrings.settingsFullscreen),
          subtitle: const Text(UiStrings.settingsFullscreenHint),
          value: s.fullscreen,
          onChanged: (v) async {
            await ctl.apply(s.copyWith(fullscreen: v));
            ref.invalidate(displaySettingsProvider);
          },
        ),
        ListTile(
          title: const Text(UiStrings.settingsResolution),
          trailing: DropdownButton<WindowSizePreset>(
            value: s.sizePreset,
            onChanged: s.fullscreen
                ? null
                : (p) async {
                    if (p == null) return;
                    await ctl.apply(s.copyWith(sizePreset: p));
                    ref.invalidate(displaySettingsProvider);
                  },
            items: [
              for (final p in WindowSizePreset.values)
                DropdownMenuItem(value: p, child: Text(_resolutionLabel(p))),
            ],
          ),
        ),
      ],
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
          child: Slider(value: value, onChanged: enabled ? onChanged : null),
        ),
      ],
    );
  }
}
