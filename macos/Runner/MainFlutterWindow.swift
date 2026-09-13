import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private let sfxPool = MacosSfxPool()
  private var sfxChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    var windowFrame = self.frame

    // 视觉验收用:VISUAL_WINDOW_W/H 环境变量强制初始窗口逻辑尺寸(居中)。
    // 仅两者都设时生效;production 不带 → 行为与原先完全一致。
    let env = ProcessInfo.processInfo.environment
    var forced: NSRect? = nil
    var forcedContentSize: NSSize? = nil
    if let ws = env["VISUAL_WINDOW_W"], let hs = env["VISUAL_WINDOW_H"],
       let w = Double(ws), let h = Double(hs), w > 0, h > 0 {
      self.setFrameAutosaveName("")
      let contentSize = NSSize(width: w, height: h)
      let outerSize = self.frameRect(
        forContentRect: NSRect(origin: .zero, size: contentSize)
      ).size
      var frame = windowFrame
      frame.size = outerSize
      // Acceptance runs must not inherit an XIB/saved origin on another
      // monitor. `NSScreen.main` follows keyboard focus and can change between
      // launches; `screens.first` is the stable menu-bar display.
      if let screen = NSScreen.screens.first ?? self.screen {
        let vis = screen.visibleFrame
        frame.origin = NSPoint(
          x: vis.origin.x + (vis.size.width - outerSize.width) / 2,
          y: vis.origin.y + (vis.size.height - outerSize.height) / 2
        )
      }
      windowFrame = frame
      forced = frame
      forcedContentSize = contentSize
    }

    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerSfxChannel(flutterViewController)

    // 锁死窗口尺寸:防 Flutter 引擎首帧后异步 resize 盖过(min==max 钳死)。
    if let f = forced {
      self.minSize = f.size
      self.maxSize = f.size
    }
    if let contentSize = forcedContentSize {
      self.contentMinSize = contentSize
      self.contentMaxSize = contentSize
    }

    super.awakeFromNib()

    if let f = forced {
      self.setFrame(f, display: true)
      // Flutter 在 awakeFromNib 返回后的首个 run loop 会恢复 XIB 原点，
      // 尺寸因 min/max 仍被锁定，但窗口可被整体推出当前屏幕。
      // 在该恢复之后重申同一个居中 frame，仅影响视觉验收模式。
      DispatchQueue.main.async { [weak self] in
        self?.setFrame(f, display: true)
      }
    }
  }

  private func registerSfxChannel(_ controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "com.pen.wuxia/macos_sfx", binaryMessenger: controller.engine.binaryMessenger
    )
    let pool = sfxPool
    channel.setMethodCallHandler { call, result in
      guard let args = call.arguments as? [String: Any],
            let poolId = args["poolId"] as? String, !poolId.isEmpty else {
        result(FlutterError(code: "macos_sfx_arguments", message: "Missing poolId.", details: nil))
        return
      }
      switch call.method {
      case "play":
        guard let maxVoices = args["maxVoices"] as? Int,
              let assetPath = args["assetPath"] as? String,
              let volume = args["volume"] as? Double else {
          result(FlutterError(code: "macos_sfx_arguments", message: "Invalid play arguments.", details: nil))
          return
        }
        pool.play(poolId: poolId, maxVoices: maxVoices, assetPath: assetPath, volume: volume) { outcome in
          switch outcome {
          case .success(let value):
            result([
              "started": value.started,
              "voiceCount": value.voiceCount,
              "activeVoices": value.activeVoices,
            ])
          case .failure(let error):
            result(FlutterError(
              code: "macos_sfx_play_failed", message: error.localizedDescription,
              details: String(reflecting: error)
            ))
          }
        }
      case "dispose":
        pool.dispose(poolId: poolId) { result(nil) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    sfxChannel = channel
  }
}
