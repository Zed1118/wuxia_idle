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
