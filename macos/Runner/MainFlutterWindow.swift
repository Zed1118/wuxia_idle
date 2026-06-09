import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    var windowFrame = self.frame

    // 视觉验收用:VISUAL_WINDOW_W/H 环境变量强制初始窗口逻辑尺寸(居中)。
    // 仅两者都设时生效;production 不带 → 行为与原先完全一致。
    let env = ProcessInfo.processInfo.environment
    var forced: NSRect? = nil
    if let ws = env["VISUAL_WINDOW_W"], let hs = env["VISUAL_WINDOW_H"],
       let w = Double(ws), let h = Double(hs), w > 0, h > 0 {
      self.setFrameAutosaveName("")
      var frame = windowFrame
      frame.size = NSSize(width: w, height: h)
      if let screen = self.screen ?? NSScreen.main {
        let vis = screen.visibleFrame
        frame.origin = NSPoint(x: vis.origin.x + (vis.size.width - w) / 2,
                               y: vis.origin.y + (vis.size.height - h) / 2)
      }
      windowFrame = frame
      forced = frame
    }

    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // 锁死窗口尺寸:防 Flutter 引擎首帧后异步 resize 盖过(min==max 钳死)。
    if let f = forced {
      self.minSize = f.size
      self.maxSize = f.size
    }

    super.awakeFromNib()

    if let f = forced { self.setFrame(f, display: true) }
  }
}
