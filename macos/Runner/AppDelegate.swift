import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    let reply = super.applicationShouldTerminate(sender)
    Self.prepareOwnedWindowsForTermination(reply, windows: sender.windows)
    return reply
  }

  static func prepareOwnedWindowsForTermination(
    _ reply: NSApplication.TerminateReply, windows: [NSWindow]
  ) {
    // Flutter may initially cancel while awaiting Dart's exit decision. Detach
    // only once exit is approved, before AppKit notifies engine shutdown and
    // closes the windows. A willTerminate observer has no safe ordering here.
    guard reply == .terminateNow else { return }
    for case let window as MainFlutterWindow in windows {
      window.prepareForApplicationTermination()
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
