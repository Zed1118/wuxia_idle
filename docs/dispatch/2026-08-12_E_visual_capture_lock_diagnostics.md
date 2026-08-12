# 派单 E · 视觉截图管线锁屏态可诊断化 + 硬失败(BACKLOG 二#11 修复)

- **执行端**:qoderclicn · **性质**:shell/python 工具层修复 + 测试,**只改 `tools/visual_capture/`**
- **worktree**:待派单方创建后填入 · **分支**:`fix/visual-capture-lock-diagnostics`
- **日期**:2026-08-12
- **前置阅读(必读,本单的事实源)**:`docs/audit/visual_capture_lock_rect_failure_2026-08-12.md`——派单方本人做的两组实验与全部原始读数都在里面。**本单不要重做那些实验**,直接用其结论。

## 一、背景与已定论的事实

`tools/visual_capture/visual_capture.sh` 是本仓的视觉验收截图管线:起 app → 等就绪 → 摆窗口 → 截图 → 裁剪。

它在**无人值守时段**(会话锁屏)会失败,现象是一句 `could not create image from rect`,紧接着 `crop_window_content.py` 抛 `FileNotFoundError`,读日志的人**完全看不出这跟锁屏有关**。

派单方 2026-08-12 已做实验定论(证据见前置文档,勿重做):

1. **锁屏时 `screencapture -R`(区域截图)必然失败**,报错串就是它发的。8 个采样完美相关:`-R` 失败 ⟺ 锁屏。
2. **锁屏时 `screencapture -o -l<wid>`(窗口截图)照常成功**,即便该窗口是锁屏期间才新启动的 app 创建的。
3. **锁屏时全屏 `screencapture` 也成功**。
4. 生产链路里 `-R` 只是 **fallback**(`visual_capture.sh:214` → `:177`);主路径是窗口截图(`:210`)。

## 二、本单的修复方向(派单方已拍板,不要自行改方向)

**一个必须先理解的推论**——它决定了本单不做什么:

`-R"0,0,W,H"` 这个 fallback 能对上画面,靠的是 `:376` 那次 `osascript` 把窗口摆到左上角并 resize。**锁屏时 osascript 操不了窗口**,几何前提本就不成立。而主路径(窗口截图)锁屏时是活的 ⇒ **一旦走到 fallback,就说明窗口是真的没找到/截不出,此时并不存在"正确的画面"可供抢救**。

所以:**不要试图把 fallback 改成"全屏截图+裁剪"来抢救出图**。那样会在锁屏场景下产出一张**看似成功、内容却是错的**图——比现在明着失败更糟(本仓有过"错拍"事故:`docs/audit/` 与 memory 里都记着 720 版整张错拍的教训)。

**本单要做的是让这个失败变得可诊断、可定位、且立刻停住**:

### 2.1 截图失败时输出锁屏态与分模式结果

`capture_visual_window()`(`visual_capture.sh:203-216`)在主路径失败、准备走 fallback 时,必须把下列事实写进该路由的 log:

- 会话是否锁屏。**判据(派单方实测可用,直接用)**:
  ```
  ioreg -n Root -d1 -w0 | grep -o 'IOConsoleUsers.*' | grep -q 'CGSSessionScreenIsLocked'
  ```
  命中 = 已锁。**注意**:未锁时该键**整个不存在**(不是 `=No`),所以只能判「键是否存在」,不要去比值。
- `window_id()` 到底返回了什么(空 / `-1` / 具体 id)——现在这个信息完全没留痕,是排查时最缺的一条。
- 若拿到了 wid,窗口截图的退出码与产出字节数。

### 2.2 fallback 保留但必须标明性质

`-R` 这条 fallback 在**未锁屏**时仍是有效兜底(实测未锁时 RC=0 正常出图),**不要删掉它**。但:

- 若 `-R` 也失败 → **立刻以非零码结束该路由的采集**,并打印一行人能看懂的结论,例如:
  「窗口截图与区域截图均失败;会话锁屏=是 ⇒ 无人值守时段无法采集视觉证据,请在解锁会话下重跑」
- **不要**让流程继续走到 `crop_window_content.py`。现状是 PNG 不存在还硬往下走,于是用户看到的是一个 PIL 的 `FileNotFoundError` traceback,与真实原因隔了三层。

### 2.3 状态串扩充

`capture_visual_window` 现在只 `printf` 两种状态:`window_id:<id>` / `fallback_region`。请扩成能区分:窗口截图成功 / 走了区域 fallback 且成功 / 全失败(并带锁屏态)。该状态串被 `:387` 写进 log,**不要改它的写入位置与既有前缀 `VISUAL_CAPTURE:`**(下游与既有 4 份终拍日志按此前缀解析)。

## 三、测试(硬要求)

bash 逻辑难直测,所以**把可判定的部分抽成 python 并测它**:

1. 新增一个小 python 助手(路径 `tools/visual_capture/` 下,命名自定),职责:**判定当前会话是否锁屏**,并可被脚本调用。它必须能在测试里**注入 `ioreg` 输出**(不要在测试里真跑 `ioreg`),覆盖三种输入:
   - 含 `CGSSessionScreenIsLocked` → 判已锁
   - 不含该键(正常未锁的真实输出形态)→ 判未锁
   - `ioreg` 失败/空输出 → 判「未知」,**不得默认判成未锁**(错报未锁会把锁屏事故误导成别的问题)
2. 上述三类各至少一例,**用真实形态的 `ioreg` 输出片段**做样例——派单方实测的未锁态真实片段(可直接抄用):
   ```
   "IOConsoleUsers" = ({"kCGSSessionOnConsoleKey"=Yes,"kSCSecuritySessionID"=100002,...,"kCGSSessionUserIDKey"=502})
   ```
   已锁态请在实现时自行构造(在该字典里加入 `"CGSSessionScreenIsLocked"=Yes`)。
3. **破坏证红是交付条件**:每类断言实测「改坏 → 必红 → 还原 → 复绿」,三态输出贴进交付说明。自检判据:**「破坏那行,这条断言必然红吗?」**

## 四、真机验证(本单唯一允许的真机动作,且有严格边界)

你**可以**用下列方式验证锁屏判定确实工作:

```
pmset displaysleepnow      # 锁定态约维持 10 秒(本机 Amphetamine 持 PreventUserIdleDisplaySleep,会很快顶醒)
```

在这 10 秒窗口内调用你的判定助手,确认它报「已锁」;解锁后确认报「未锁」。**把两次实际输出贴进交付说明。**

**严禁**:
- 不许跑 `flutter build macos`、`flutter run`、`visual_capture.sh` 的真实采集流程。理由:现成构建是 2026-08-08 产物(saveVersion `0.38.0`),而用户存档已是 `0.39.0`,跑它会碰生产存档且必然抛版本异常。
- 不许读写 `~/Library/Containers/com.pen.wuxia.wuxiaIdle/` 下任何文件。
- 不许 `kill` 用户的任何 GUI 应用(尤其 Amphetamine)。

## 五、验收标准

1. `shellcheck tools/visual_capture/visual_capture.sh`(若本机有)结果贴出;没有则说明。
2. python 测试单独跑,贴通过数。
3. 破坏证红三态输出。
4. §四 两次真机判定输出。
5. **必须回答**:未锁屏场景下,本单改动是否让既有行为发生任何变化?(期望答案是「不变」——主路径与未锁的 `-R` fallback 都应原样工作。若你的改动使其变化,说明清楚为什么。)

## 六、边界约束(硬)

- **禁区文件,一个都不许碰**:`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`
- **只改 `tools/visual_capture/` 下的文件**。**不许碰 `tools/README.md`**(今晚另有任务在动 `tools/` 顶层,且该文件里有待用户拍板的条目);要写说明就写 `tools/visual_capture/README.md`。
- **不许改 `lib/`、`test/`、`data/`、`docs/`**。
- **不许删 `-R` fallback**、不许改主路径(窗口截图)的行为、不许动 `window_id.swift`。
- **不许改 `crop_window_content.py` 的裁剪算法**(只允许:不再在 PNG 不存在时被调用)。
- **禁 push、禁 merge、禁碰 main、禁 revert**。
- commit message 用**中文动宾**结构。
- 交付时工作区干净,tip commit 消息以 `[READY]` 开头。

## 七、[BLOCKED] 出口

以下任一情况立刻停下,tip 打 `[BLOCKED]`:

- 你认为 §二 的修复方向不对(例如你有证据表明 fallback 确实该抢救出图)——**写清证据,不要自行改方向**
- 锁屏判定在你手上无法可靠工作(如 `ioreg` 输出形态与派单包不符)
- 改动无法做到「未锁场景行为不变」
- 任何你拿不准是否越过 §六 边界的动作
