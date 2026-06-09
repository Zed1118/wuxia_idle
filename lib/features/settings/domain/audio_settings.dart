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
