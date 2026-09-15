// Standalone XCTest imports the actual app Swift sources as a dynamic library.
// Its @main function is never called: no nib, FlutterViewController, Dart or save
// is loaded. Windows are never ordered on screen; WindowManager is the real pod.
import Cocoa
import FlutterMacOS
import window_manager
import XCTest
@testable import WuxiaNativeExitUnderTest

private final class OtherWindowDelegate: NSObject, NSWindowDelegate {}

@MainActor
final class MacosWindowTerminationTests: XCTestCase {
  private func window() -> MainFlutterWindow {
    let result = MainFlutterWindow(
      contentRect: NSRect(x: 0, y: 0, width: 320, height: 180),
      styleMask: [.titled, .closable], backing: .buffered, defer: false
    )
    result.isReleasedWhenClosed = false
    return result
  }

  func testRealAppDelegateStopsLatePluginEventsAfterApprovedExit() {
    let application = NSApplication.shared
    let owned = window()
    defer { owned.close() }
    let manager = WindowManager()
    manager.mainWindow = owned
    XCTAssertTrue(owned.delegate === manager)
    XCTAssertNil(owned.contentViewController)
    XCTAssertFalse(owned.isVisible)
    XCTAssertTrue(application.windows.contains { $0 === owned })

    var events: [String] = []
    manager.onEvent = { events.append($0) }
    manager.windowDidMove(Notification(name: NSWindow.didMoveNotification, object: owned))
    XCTAssertEqual(events, ["moved"])

    // The real FlutterAppDelegate's unset termination handler returns .terminateNow.
    // This calls the actual AppDelegate override, not a test copy of its policy.
    let reply = AppDelegate().applicationShouldTerminate(application)
    XCTAssertEqual(reply, .terminateNow)
    manager.windowDidResignMain(
      Notification(name: NSWindow.didResignMainNotification, object: owned)
    )
    XCTAssertEqual(events, ["moved"], "An approved exit must disconnect late native plugin events")
    XCTAssertNil(manager.onEvent)
    XCTAssertTrue(owned.delegate === manager)
  }

  func testCancelAndLaterKeepRealPluginEventsAndClosePolicy() {
    for reply: NSApplication.TerminateReply in [.terminateCancel, .terminateLater] {
      let owned = window()
      defer { owned.close() }
      let manager = WindowManager()
      manager.mainWindow = owned
      manager.setPreventClose(["isPreventClose": true])
      var events: [String] = []
      manager.onEvent = { events.append($0) }

      AppDelegate.prepareOwnedWindowsForTermination(reply, windows: [owned])
      manager.windowDidMove(Notification(name: NSWindow.didMoveNotification, object: owned))
      manager.windowDidResignMain(
        Notification(name: NSWindow.didResignMainNotification, object: owned)
      )
      XCTAssertEqual(events, ["moved", "blur"])
      XCTAssertNotNil(manager.onEvent)
      XCTAssertTrue(owned.delegate === manager)
      XCTAssertTrue(manager.isPreventClose())
    }
  }

  func testFinalDecisionOnlyDetachesThisApplicationsWindowType() {
    let owned = window()
    let other = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 160, height: 90),
      styleMask: [.titled], backing: .buffered, defer: false
    )
    other.isReleasedWhenClosed = false
    defer { owned.close(); other.close() }
    let ownedManager = WindowManager()
    ownedManager.mainWindow = owned
    let otherManager = WindowManager()
    otherManager.mainWindow = other
    var ownedEvents = 0
    var otherEvents = 0
    ownedManager.onEvent = { _ in ownedEvents += 1 }
    otherManager.onEvent = { _ in otherEvents += 1 }

    // Use the actual AppDelegate path to cover sender.windows filtering.
    XCTAssertEqual(AppDelegate().applicationShouldTerminate(NSApplication.shared), .terminateNow)
    ownedManager.windowDidMove(Notification(name: NSWindow.didMoveNotification, object: owned))
    otherManager.windowDidMove(Notification(name: NSWindow.didMoveNotification, object: other))
    XCTAssertEqual(ownedEvents, 0)
    XCTAssertEqual(otherEvents, 1)
    XCTAssertNil(ownedManager.onEvent)
    XCTAssertNotNil(otherManager.onEvent)
    XCTAssertTrue(owned.delegate === ownedManager)
    XCTAssertTrue(other.delegate === otherManager)
  }

  func testUnexpectedDelegateIsPreservedInsteadOfAssumedToBeWindowManager() {
    let owned = window()
    defer { owned.close() }
    let previousManager = WindowManager()
    previousManager.mainWindow = owned
    var previousEvents = 0
    previousManager.onEvent = { _ in previousEvents += 1 }
    let otherDelegate = OtherWindowDelegate()
    owned.delegate = otherDelegate

    AppDelegate.prepareOwnedWindowsForTermination(.terminateNow, windows: [owned])
    XCTAssertTrue(owned.delegate === otherDelegate)
    previousManager.windowDidMove(Notification(name: NSWindow.didMoveNotification, object: owned))
    XCTAssertEqual(previousEvents, 1)
    XCTAssertNotNil(previousManager.onEvent)
  }

  func testRepeatedApprovedCleanupIsIdempotentAndKeepsClosePolicy() {
    let owned = window()
    defer { owned.close() }
    let manager = WindowManager()
    manager.mainWindow = owned
    manager.setPreventClose(["isPreventClose": true])
    var events = 0
    manager.onEvent = { _ in events += 1 }
    manager.windowDidMove(Notification(name: NSWindow.didMoveNotification, object: owned))
    XCTAssertEqual(events, 1)

    AppDelegate.prepareOwnedWindowsForTermination(.terminateNow, windows: [owned])
    AppDelegate.prepareOwnedWindowsForTermination(.terminateNow, windows: [owned])
    manager.windowDidMove(Notification(name: NSWindow.didMoveNotification, object: owned))
    XCTAssertEqual(events, 1)
    XCTAssertNil(manager.onEvent)
    XCTAssertTrue(owned.delegate === manager)
    XCTAssertTrue(manager.isPreventClose())
    XCTAssertNil(owned.contentViewController)
    XCTAssertFalse(owned.isVisible)
  }
}

@main
struct NativeWindowTerminationTestRunner {
  @MainActor static func main() {
    _ = NSApplication.shared
    let suite = XCTestSuite(forTestCaseClass: MacosWindowTerminationTests.self)
    suite.run()
    guard let result = suite.testRun, result.executionCount == 5 else {
      fputs("Native window termination discovery did not execute all 5 cases.\n", stderr)
      exit(2)
    }
    exit(result.totalFailureCount == 0 ? 0 : 1)
  }
}
