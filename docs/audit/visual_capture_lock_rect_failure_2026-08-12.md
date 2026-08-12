# `could not create image from rect` 根因定位(BACKLOG 二#11)

- **日期**:2026-08-12 · **执行**:协调者本人实验(非执行端自报)
- **结论一句话**:锁屏时 `screencapture -R` **必然失败**,而窗口截图与全屏截图**照常成功**;该报错是 fallback 路径的症状,不是根因。
- **复现成本从「跑一次完整 `flutter build macos` + 视觉管线」降到「5 秒、零构建」**。

## 一、登记状态 vs 实测

`BACKLOG.md` 二#11 登记:两轮夜批复现,假设①显示器休眠、②后台拿不到 GUI session **均已证伪**,③锁屏「仍存疑未验」,④已知白天可用。

本次把 ③ 验掉了,并且**推翻了「锁屏使窗口不可截」这一自然推论**(该推论是本次实验开始前协调者自己的假设,被自己的数据证伪)。

## 二、实验一:强制睡屏后分模式测 screencapture

**为什么此前没人做过这个实验**:上一轮的对照组是「手动睡屏 + 跑 `visual_capture.sh`」,而该脚本内部 `focus_visual_app()` 用 `osascript` 置前窗口,**osascript 会瞬间唤醒显示器**(上一轮自己实测 off→on 同一秒)——等于把要测的条件当场消掉。本实验全程不碰 osascript。

方法:`pmset displaysleepnow` 后按 5/15/30/60/90s 采样,每次独立测三种截图模式。

| 时点 | LOCK | `-l<wid>` 窗口 | `-R` 区域 | 全屏 |
|---|---|---|---|---|
| T0 睡屏前 | NO | RC=0 · 3,030,239 B | RC=0 · 1,348,091 B | RC=0 · 10,475,122 B |
| **T+5s** | **YES** | **RC=0 · 4,235,367 B** | **RC=1 · 0 B · `could not create image from rect`** | **RC=0 · 23,626,735 B** |
| T+15s | NO | RC=0 | RC=0 · 1,761,257 B | RC=0 |
| T+30s / +60s / +90s | NO | RC=0 | RC=0 | RC=0 |

**报错串逐字复现**。三种模式里只有 `-R` 死。

## 三、实验二:锁屏期间「新启动」的 app 能否被截

实验一用的是解锁期就存在的窗口,不能排除「锁屏时新建的窗口进不了 CGWindowList」。故追加:先 `pmset displaysleepnow`,**立刻** `open -g -a TextEdit`(用 `-g` 不置前,类比生产脚本把 app 作为后台子进程直接起;不带 `-g` 的激活会自己唤醒显示器造成混淆),然后每 2s 采样。

用 TextEdit 而非 `wuxia_idle.app` 的理由:现成构建是 2026-08-08 02:12 产物(PR #119 之前,`_currentSaveVersion=0.38.0`),而用户存档已被顶到 `0.39.0`,跑它必抛 `UnsupportedSaveVersionException` **且会碰生产存档**(BACKLOG 二#12,隔离修复当时尚未合)。本问题属 macOS 平台语义,与具体 app 无关。

| t | LOCK | WID | `-l<wid>` | `-R` |
|---|---|---|---|---|
| +2s | **YES** | 159564 | RC=0 · 42,145 B | **RC=1 · 0 B** |
| +4s | **YES** | 159564 | RC=0 · 42,145 B | **RC=1 · 0 B** |
| +6s | **YES** | 159564 | RC=0 · 42,145 B | **RC=1 · 0 B** |
| +8s | **YES** | 159564 | RC=0 · 42,145 B | **RC=1 · 0 B** |
| +10s | NO | 159564 | RC=0 | RC=0 · 1,403,482 B |
| +12s / +14s / +16s | NO | 159564 | RC=0 | RC=0 |

**8 个采样完美相关:`-R` 失败 ⟺ `LOCK=YES`。** 锁屏期新启动的 app 照样拿到 window id、照样能被窗口截图截到。

## 四、机制

生产调用链(`tools/visual_capture/visual_capture.sh`):

```
:362 terminate_visual_app
:364 起 app(后台子进程,记 pid)
:367 wait_for_route_ready          ← 等 VISUAL_ROUTE_READY
:373-380 若非 --background:
     :374 focus_visual_app         ← osascript 置前
     :376 resize_visual_window     ← osascript 移到 {0,0} 并 resize 成 WxH
     :378 focus_visual_app
:382 capture_visual_window
       └ :209 window_id            ← 拿不到 wid,或
         :210 screencapture -l<wid> 失败/产出 0 字节
         → :214 capture_region     ← :177 screencapture -R"0,0,W,H"   ★ 锁屏时必死
:383 crop_window_content.py        ← PNG 不存在 → FileNotFoundError(用户看到的那个 traceback)
```

`-R"0,0,W,H"` 之所以能对上画面,靠的是 `:376` 那次 osascript 把窗口摆到左上角并调成同尺寸。**锁屏时 System Events 操不了窗口,这个几何前提本就不成立**;而 `-R` 自身又在锁屏时必然返回 null 图像。两者叠加 ⇒ **无人值守时段这条管线没有任何可用兜底**:主路径一旦有任何瞬时失手,就直接变成一个报错串莫名其妙的硬失败。

2026-08-08 那晚的实际链路:顶层日志(`cap_recruit2.log`)显示 `✓ Built ...wuxia_idle.app` 之后直接 `could not create image from rect`,**没有** `Route did not become ready` —— 即 app 正常启动并发出了就绪信号,是**就绪之后**才截不到。

## 五、掩蔽因素(为什么现在等到天亮也复现不了)

`pmset -g assertions` 实测:

```
pid 950(Amphetamine): PreventUserIdleDisplaySleep  已持续 95:13:10
```

Amphetamine 连续 95 小时持着「阻止息屏」断言 ⇒ 显示器不会 idle 休眠 ⇒ 屏保不起 ⇒ 会话永不自动锁。**只要它在跑,本缺陷就不可能自然复现**(实验里强制 `displaysleepnow` 后锁定态也仅维持约 10 秒即被顶醒)。这也是「白天怎么跑都绿」的一个充分解释,不必再去查显示器休眠日志。

## 六、修法建议(未实装,留待拍板/派单)

1. **把 `capture_region` 的 `-R` 换成「全屏截图 + 按几何裁剪」**。全屏截图在锁屏时实测**是活的**(实验一 `LOCK=YES` 下 23,626,735 B 成功),换掉即让 fallback 也扛得住锁屏。
2. **失败时报锁屏态,不要把 PNG 缺失甩给下游**。现状是 `crop_window_content.py:14` 抛 `FileNotFoundError`,读日志的人完全看不出与锁屏有关。截图失败处直接打 `LOCK=YES/NO` 与三种模式各自 RC。
3. 顺带:`focus_visual_app` / `resize_visual_window` 在锁屏时会失败,脚本已用 WARN 容忍,但 **`-R` 的几何前提随之静默失效** —— 走窗口截图路径则不受影响,这也是第 1 点的附带收益。

## 七、仍未证明(如实标注)

- **主路径当晚为何失手**未定论:是 `window_id()` 返回空,还是窗口截图产出 0 字节。区分二者需要当晚的**每路由日志**(`$dir/$route.log`,含 `VISUAL_CAPTURE_WARN` 行),该目录 `build/visual_acceptance/rarity_smoke_20260808/` 已随 `build/` 清理消失,**无法回溯**。
- 上述不确定**不影响第六节的修法**:无论主路径因何失手,锁屏时 `-R` 必死是独立成立的硬事实,兜底该换。
- 本次未在真实 `wuxia_idle.app` 上复现(理由见 §三)。视觉路由存档隔离合入后可用新构建做一次确认跑。
