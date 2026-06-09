# 音频系统设计 spec(2026-06-09 · xhigh)

## 目标 / 范围
搭音频**引擎 + 接好全部 hook**,**零素材也能跑通**(缺文件 no-op)。素材来源后定(已选 shared_preferences 存设置)。
- **本版做**:SoundManager 引擎 / 资产槽位 enum + manifest / 音频设置(音量·静音,shared_preferences) / 设置面板 UI / 三类 hook(战斗 SFX·UI SFX·BGM 按屏) / 测试。
- **本版不做(YAGNI)**:配音 voice(引擎已支持 clip 播放,enum 留位不接线)/ 复杂 crossfade(用 stop+start 或快速 fade)/ app 后台暂停(桌面跳过)/ 实际音频素材文件。

## 红线合规
- **不碰 domain/battle 逻辑**:战斗 SFX 走 battle_screen 现有 `actionLog` 边沿检测(同 `hit_flash.dart` 体例),纯表现层,**不写 BattleState**。
- **不引游戏数值硬编码**:音量是用户设置(shared_preferences),非 §5.4 战斗数值,不进 numbers.yaml。
- **不引第三方游戏引擎**:用 `audioplayers`(纯音频库,非 Flame)。
- **文案**:设置面板中文走 UiStrings。

## 架构与组件

### 1. 引擎 `lib/shared/audio/sound_manager.dart`
- `audioplayers: ^6.x` 加 pubspec。
- BGM:1 个常驻 `AudioPlayer`(ReleaseMode.loop),`playBgm(track)` 切轨(同轨 no-op;换轨 stop+play,可选 200ms fade)。
- SFX:4-6 个 `AudioPlayer` 池,round-robin,允许叠播一次性音。
- **缺素材降级**:play 包 try/catch,asset 不存在 → 静默 no-op(debugPrint 记一次),保证零素材跑通。
- API:`playBgm(BgmTrack)` / `stopBgm()` / `playSfx(SfxId)` / `setMasterVolume(d)` / `setBgmVolume(d)` / `setSfxVolume(d)` / `setMuted(bool)`。
- **可测性**:抽 `AudioBackend` 接口(play/stop/setVolume)包住 audioplayers,测试注入 fake,不碰真音频。

### 2. 资产槽位 `lib/shared/audio/audio_assets.dart`
- `enum BgmTrack { mainMenu, battle, seclusion, ... }` → `assets/audio/bgm/<id>.mp3`
- `enum SfxId { uiTap, uiPageTurn, battleAttack, battleHit, battleCrit, battleDeath, battleUlt, reward, ... }` → `assets/audio/sfx/<id>.mp3`
- pubspec 注册 `assets/audio/bgm/`、`assets/audio/sfx/`(放 `.gitkeep` 占空目录)。
- `docs/handoff/audio_slot_manifest.md`:每槽位用途 + 风格(水墨克制:古琴/箫/雨/竹,SFX 轻),供找素材。

### 3. 设置 `lib/features/settings/`
- `AudioSettings`(masterVolume/bgmVolume/sfxVolume: double 0-1 · muted: bool · 默认 0.8/0.7/0.9/false)。
- `AudioSettingsService`:shared_preferences 读写(key 前缀 `audio.`)。
- Riverpod provider 暴露当前设置;改动即存 + 应用到 SoundManager。
- 设置面板 `SettingsPanel`(PaperDialog/PaperPanel · 3 滑条 + 静音开关 · UiStrings)。入口:main_menu 加「设置」入口(沿现有 _MenuButton 体例)。

### 4. Hook 接线
- **战斗 SFX**:`battle_screen` 现有 actionLog 边沿监听处,加 `SoundManager.playSfx(sfxForAction(newAction))`。抽纯函数 `SfxId? sfxForAction(BattleAction)`(attack/hit/crit/death/ult 映射,可测)。
- **UI SFX**:`PlaqueButton`/`PlaqueTab` onTap 包一层 `SoundManager.playSfx(SfxId.uiTap)`(集中,所有按钮受益)。`PaperDialog` 翻页/出现可选 uiPageTurn。
- **BGM 按屏**:`BgmScope({required BgmTrack track, required Widget child})` widget,initState 调 playBgm(track)。主菜单/战斗/闭关(+主线/爬塔可选)关键屏各包。无中央路由表 → 声明式最干净。

### 5. 生命周期
- `main()` / app 启动初始化 SoundManager(load 设置 → 应用音量)。ProviderScope 注入。

## 测试计划
- `sound_manager_test`:fake AudioBackend → 缺素材不抛 / 音量·静音应用 / 同轨 no-op。
- `audio_assets_test`:enum → 路径拼接正确。
- `sfx_for_action_test`:`sfxForAction(BattleAction)` 纯函数映射全分支。
- `audio_settings_service_test`:shared_preferences mock 读写往返 + 默认值。
- 不测真音频播放(无素材 + 桌面音频不进 CI)。

## 文件清单(新增/改)
- 新:`lib/shared/audio/{sound_manager,audio_assets,audio_backend}.dart` · `lib/features/settings/{application/audio_settings_service,domain/audio_settings,presentation/settings_panel}.dart` · 测试若干 · `assets/audio/{bgm,sfx}/.gitkeep` · `docs/handoff/audio_slot_manifest.md`
- 改:`pubspec.yaml`(audioplayers + shared_preferences + assets/audio 注册)· `battle_screen`(SFX hook)· `wuxia_ui` 的 `plaque_button`/`plaque_tab`(UI SFX)· `main_menu`(设置入口 + BgmScope)· 战斗/闭关屏(BgmScope)· `lib/shared/strings.dart`(设置文案)· `main.dart`(init)

## 验收
- analyze 0 / 全量测试过(含新音频测)。
- 零素材下:游戏正常跑、所有 hook 调到 SoundManager 不报错(静默)。
- 设置面板可调音量/静音并持久化(重启保留)。
- 战斗/UI/换屏 hook 在正确触发点调用(测试覆盖映射 + 边沿)。
