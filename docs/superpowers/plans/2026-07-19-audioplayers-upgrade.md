# K2 · 目标 1:audioplayers 升级(Mac 侧收口)

> 任务日期:2026-07-19 · 执行者:Kimi(子代理) · 协作协议:CLAUDE.md §8.0/§8.2/§8.3

## 目标

升级 `audioplayers`(当前 `^6.0.0`,lock 解析 6.7.1)到上游支持 Windows Server 2025 + VS2026(MSVC 14.51)工具链的版本,为解除 Windows Release workflow 的 `windows-2022` 临时 pin 扫清依赖障碍。**本单只做 Mac 侧收口**:依赖升级 + 代码适配 + targeted 验证。Windows workflow 文件绝对不碰。

## 背景

audioplayers 6.x 的 `audioplayers_windows` 在 MSVC 14.51 下 `<experimental/coroutine>` STL1011 硬错。API 接触面收敛在 `lib/shared/audio/audio_players_backend.dart` 单文件(`audio_backend.dart` 抽象隔离,`sound_manager.dart` 等只依赖抽象),适配面预计很小。

## 分支 / Worktree

- 分支:`kimi/audioplayers-upgrade`(自 `main@28223a33` 切出)
- Worktree:`.worktrees/audioplayers-upgrade`

## 验收标准(§8.2 转写)

1. **生产接线证据**:改动仅 `pubspec.yaml` 授权行(audioplayers 版本行)+ `pubspec.lock` 随动 + 必要时的 `audio_players_backend.dart` 适配;lock diff 仅限 audioplayers 系及其传递依赖,hosted url 源零变化。
2. **targeted test 结果**:`flutter test --no-pub test/shared/audio/ test/features/settings/audio_settings_service_test.dart`(7 个测试文件)全绿,贴命令+通过数。
3. **红线影响说明**:不触数值/三系/在线=离线/反主流/文案硬编码;`audio_backend.dart` 抽象接口尽量不动,若必须动 → 倾向 [BLOCKED] 上报。
4. **残留风险**:Windows 侧未验证(留主会话)、真机听感未验(留批末真机 smoke)。
5. 另:`flutter analyze` 0 issue;`flutter build macos --debug` 成功;过程证据(测试/analyze/build 输出、lock diff 摘要)写进本文件。

## 任务切片

1. [x] 预热:worktree + pub get(PUB_HOSTED_URL)+ build_runner + 冒烟测试
2. [x] 评估:pub outdated + changelog 逐版本审 breaking + 确认 MSVC 14.51 支持起始版本 → 结论先写本文件
3. [x] 升级尝试:pubspec 改 `^6.8.1` → `flutter pub get` version solving 失败(Flutter ≥3.44.0 门槛)→ **命中 [BLOCKED] 出口,已还原**
4. [ ] 适配:(未执行,冻结)
5. [ ] 验证:(未执行,冻结)
6. [x] 收口:plan 证据齐 + tip 打 [BLOCKED]

## 升级评估(先写结论再动手)

**可升区间(2026-07-19 实测 `flutter pub outdated`)**:audioplayers 6.7.1 → **6.8.1**;传递依赖 audioplayers_windows 4.3.1 → **4.4.1**,audioplayers_darwin 6.4.0 → 6.5.0,audioplayers_android 5.2.1 → 5.3.0,audioplayers_web 5.2.1 → 5.3.0,audioplayers_linux 4.2.1 → 4.3.0,audioplayers_platform_interface 7.1.1 → 7.2.0。

**MSVC 14.51 / VS2026 支持起始版本(上游 changelog 证据)**:
- `audioplayers_windows` **4.4.0**:"FIX(windows): Update to C++23 & Windows Implementation Lib (#2004)" — 迁到 C++23 标准协程 + WIL,正是 `<experimental/coroutine>` STL1011 硬错的根治方向。
- `audioplayers_windows` **4.4.1**:"FIX(windows): Compatibility with Visual Studio 18 (2026) (#2011)" — 明确点名 VS 18 (2026) 兼容。即 **4.4.1 起** 支持新工具链。
- 来源:pub.dev changelog + github raw CHANGELOG(ae5f4b96 / faa84312)。

**新 Windows 平台要求(4.4.1 changelog 明示)**:`windows/CMakeLists.txt` 需 CMP0091 NEW policy(cmake_minimum_required 3.15 / cmake_policy VERSION 3.15...3.25,或 `cmake_policy(SET CMP0091 NEW)`)。→ 属 Windows 侧改动,**不在本单范围**,列入残留风险交主会话解除 pin 时一并处理。

**breaking 审查(6.7.1 → 6.8.1 区间)**:audioplayers 6.8.x changelog 无 BREAKING 标注(均为 fix/feat:StateError 修复、cache 检查、AudioPool duration、Swift 并发等)。项目 API 接触面(`audio_players_backend.dart`)仅用 `AudioPlayer()` / `play(AssetSource, volume:)` / `stop()` / `setVolume()` / `setReleaseMode(ReleaseMode.loop)` / `dispose()` —— 全部为 6.x 稳定 API,若可装上则预期零代码适配。

**SDK 门槛(致命,实测证伪初判)**:pub.dev API 实测各版本 `environment`:
- audioplayers **6.8.0 / 6.8.1**:`flutter: ">=3.44.0"`(6.7.1 无此门槛,本项目 lock 现装 6.7.1);
- audioplayers_windows **4.4.0 / 4.4.1**:`flutter: ">=3.44.0"`。
- 本地 Flutter SDK = **3.41.5**(stable),不满足。
- 实测 `flutter pub get`(pubspec 改 `^6.8.1` 后)version solving 失败,原文:
  ```
  Because wuxia_idle depends on audioplayers >=6.8.0 which requires Flutter SDK version >=3.44.0, version solving failed.
  You can try one of the following suggestions to make the pubspec resolve:
  * Try using the Flutter SDK version: 3.44.6.
  * Consider downgrading your constraint on audioplayers: flutter pub add audioplayers:^6.7.1
  Failed to update packages.
  ```
- 无中间版本可选:6.7.1 之后直接 6.8.0(无 6.7.2 补丁版携带 windows 4.4.x);即便用 dependency_overrides 单拉 audioplayers_windows 4.4.1,其自身同样要求 Flutter ≥3.44.0,绕不开(且 overrides 超出本单授权)。

**结论:[BLOCKED]**。命中任务书 [BLOCKED] 出口第二条——「升级需要连带升 Flutter SDK 或其他共享依赖」。VS2026 修复只存在于要求 Flutter ≥3.44.0 的版本里;要解除 windows-2022 pin,需先由用户拍板把开发/CI Flutter SDK 升到 ≥3.44.x(当前 3.41.5,pub 建议 3.44.6)。pubspec.yaml 已还原为 `^6.0.0`,pubspec.lock 已 `git checkout` 还原(曾出现失败解析留下的 pub.dev 源污染 diff,按规则立即还原,未留痕)。

**给主会话的解除 pin 前置清单**(本次调研副产物):
1. Flutter SDK 本地 + CI 升级到 ≥3.44.x;
2. `audioplayers: ^6.8.1` 后 lock 应解析 audioplayers_windows ≥4.4.1;
3. `windows/CMakeLists.txt` 按上游新平台要求加 CMP0091 NEW policy(见 audioplayers_windows 4.4.1 changelog / README requirements);
4. 之后才能在 Windows Server 2025 + VS2026 上复测并解除 windows-2022 pin。

## 验证证据(§8.2 四项)

因 [BLOCKED] 冻结于切片 3(依赖解析失败),四项证据状态:

1. **测试输出**:基线冒烟 `flutter test --no-pub test/shared/audio/sound_manager_test.dart` → `00:00 +5: All tests passed!`(6 项全绿,升级前基线;升级未落地,无升级后测试可跑)。
2. **analyze 输出**:未跑(代码零改动,无意义)。
3. **build 输出**:未跑(同上)。
4. **lock diff 摘要**:`flutter pub get`(`^6.8.1`)version solving 失败,lock 未发生合法升级 diff;失败解析一度留下全量 `url: pub.flutter-io.cn → pub.dev` 源污染 + uuid 4.5.3→4.6.0 漂移,已按规则 `git checkout -- pubspec.lock` 立即还原,终态 lock 与 main 一致(零 diff)。

**解析失败原文**(核心证据,见「升级评估」节代码块)。

## 当前恢复点(五项)

- **状态**:[BLOCKED] 冻结,待用户拍板 Flutter SDK 升级
- **最后完成**:升级评估完成——选定版本本应为 `^6.8.1`(携带 audioplayers_windows 4.4.1 VS2026 修复),实测其要求 Flutter ≥3.44.0,本地 3.41.5 不满足;pubspec.yaml / pubspec.lock 均已还原,worktree 仅有本 plan 文件变更
- **下一步**:用户拍板是否升 Flutter SDK 至 ≥3.44.x;若拍板升,resume 后重跑切片 3→6(改 pubspec → pub get → 核对 lock diff → targeted 7 文件测试 → analyze → build macos --debug → 收口)
- **已跑验证**:基线冒烟 `sound_manager_test.dart` 6/6 绿;`flutter pub outdated` 实测可升区间;pub.dev API 实测 6.8.0/6.8.1/4.4.0/4.4.1 的 flutter 环境约束;`flutter pub get` 失败原文存档
- **阻塞项**:Flutter SDK 3.41.5 < 3.44.0(audioplayers ≥6.8.0 与 audioplayers_windows ≥4.4.0 的硬约束);升级 SDK 属共享环境决策,命中 [BLOCKED] 出口,不硬闯
