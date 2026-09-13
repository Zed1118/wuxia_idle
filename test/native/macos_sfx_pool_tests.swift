// Standalone XCTest: compile this file together with macos/Runner/MacosSfxPool.swift.
import Foundation
import XCTest

private final class WeakPlayer {
  weak var value: FakePlayer?
  init(_ value: FakePlayer) { self.value = value }
}

private enum FakeError: Error { case factory }

private final class Trace {
  var events: [String] = []
  var mainThreadAccesses: [String] = []
  var alive = 0
  var peakAlive = 0
  func record(_ event: String) {
    events.append(event)
    if Thread.isMainThread { mainThreadAccesses.append(event) }
  }
}

private final class FakePlayer: MacosSfxPlayer {
  let id: Int
  let trace: Trace
  var playing = false
  var prepareSucceeds = true
  var playSucceeds = true
  var rawVolume: Float = 1
  var rawTime: TimeInterval = 19
  var prepareCount = 0
  var playCount = 0

  init(id: Int, trace: Trace) {
    self.id = id
    self.trace = trace
    trace.record("create:\(id)")
    trace.alive += 1
    trace.peakAlive = max(trace.peakAlive, trace.alive)
  }
  deinit {
    trace.record("release:\(id)")
    trace.alive -= 1
  }
  var isPlaying: Bool {
    trace.record("isPlaying:\(id)")
    return playing
  }
  var volume: Float {
    get { trace.record("volumeGet:\(id)"); return rawVolume }
    set { trace.record("volumeSet:\(id)"); rawVolume = newValue }
  }
  var currentTime: TimeInterval {
    get { trace.record("timeGet:\(id)"); return rawTime }
    set { trace.record("timeSet:\(id)"); rawTime = newValue }
  }
  func prepareToPlay() -> Bool {
    trace.record("prepare:\(id)")
    prepareCount += 1
    return prepareSucceeds
  }
  func pause() { trace.record("pause:\(id)"); playing = false }
  func play() -> Bool {
    trace.record("play:\(id)")
    playCount += 1
    playing = playSucceeds
    return playSucceeds
  }
}

private final class Factory {
  let trace = Trace()
  var paths: [String] = []
  var players: [WeakPlayer] = []
  var throwNext = false
  var prepareNext = true
  var playNext = true
  func make(_ url: URL) throws -> MacosSfxPlayer {
    trace.record("factory:\(url.lastPathComponent)")
    if throwNext { throwNext = false; throw FakeError.factory }
    let player = FakePlayer(id: players.count, trace: trace)
    player.prepareSucceeds = prepareNext
    player.playSucceeds = playNext
    prepareNext = true
    playNext = true
    paths.append(url.path)
    players.append(WeakPlayer(player))
    return player
  }
}

final class MacosSfxPoolTests: XCTestCase {
  private func play(
    _ pool: MacosSfxPool, _ path: String, cap: Int = 3,
    poolId: String = "test", volume: Double = 0.5
  ) -> Result<MacosSfxPlayResult, Error> {
    let done = expectation(description: "play completes on main")
    var outcome: Result<MacosSfxPlayResult, Error>?
    pool.play(poolId: poolId, maxVoices: cap, assetPath: path, volume: volume) {
      XCTAssertTrue(Thread.isMainThread)
      outcome = $0
      done.fulfill()
    }
    wait(for: [done], timeout: 3)
    return outcome ?? .failure(FakeError.factory)
  }

  private func dispose(_ pool: MacosSfxPool, _ id: String = "test") {
    let done = expectation(description: "dispose completes on main")
    pool.dispose(poolId: id) {
      XCTAssertTrue(Thread.isMainThread)
      done.fulfill()
    }
    wait(for: [done], timeout: 3)
  }

  private func assertFailure(_ result: Result<MacosSfxPlayResult, Error>) {
    if case .success = result { XCTFail("An actual playback failure must not report started") }
  }

  @objc func testLazyCapCursorAndReplacementLifetime() throws {
    let factory = Factory()
    let pool = MacosSfxPool(makePlayer: factory.make)
    defer { dispose(pool) }
    XCTAssertEqual(factory.paths.count, 0)
    for (i, path) in ["/A", "/B", "/C"].enumerated() {
      let result = try play(pool, path).get()
      XCTAssertTrue(result.started)
      XCTAssertEqual(result.voiceCount, i + 1)
      XCTAssertEqual(result.activeVoices, i + 1)
    }
    let result = try play(pool, "/D").get()
    XCTAssertEqual(result.voiceCount, 3)
    XCTAssertEqual(result.activeVoices, 3)
    XCTAssertNil(factory.players[0].value)
    XCTAssertNotNil(factory.players[1].value)
    XCTAssertEqual(factory.trace.peakAlive, 3)
    let release = try XCTUnwrap(factory.trace.events.firstIndex(of: "release:0"))
    let create = try XCTUnwrap(factory.trace.events.firstIndex(of: "create:3"))
    XCTAssertLessThan(release, create)
    dispose(pool)
    XCTAssertEqual(factory.trace.alive, 0)
    XCTAssertTrue(factory.trace.mainThreadAccesses.isEmpty)
  }

  @objc func testMatchingIdleWinsOverEarlierIdleAndResetsTime() throws {
    let factory = Factory()
    let pool = MacosSfxPool(makePlayer: factory.make)
    defer { dispose(pool) }
    for path in ["/A", "/B", "/C"] { _ = try play(pool, path).get() }
    factory.players[0].value?.playing = false
    factory.players[2].value?.playing = false
    _ = try play(pool, "/C", volume: 0.37).get()
    XCTAssertEqual(factory.paths.count, 3)
    XCTAssertEqual(factory.players[2].value?.prepareCount, 1)
    XCTAssertEqual(factory.players[2].value?.playCount, 2)
    XCTAssertEqual(factory.players[2].value?.rawTime, 0)
    XCTAssertEqual(factory.players[2].value?.rawVolume, Float(0.37))
    XCTAssertNotNil(factory.players[0].value)
    _ = try play(pool, "/D").get()
    XCTAssertNil(factory.players[0].value)
    XCTAssertTrue(factory.trace.mainThreadAccesses.isEmpty)
  }

  @objc func testIdleWinsOverPlayingAndAdvancesCursor() throws {
    let factory = Factory()
    let pool = MacosSfxPool(makePlayer: factory.make)
    defer { dispose(pool) }
    for path in ["/A", "/B", "/C"] { _ = try play(pool, path).get() }
    factory.players[1].value?.playing = false
    _ = try play(pool, "/D").get()
    XCTAssertNil(factory.players[1].value)
    XCTAssertNotNil(factory.players[0].value)
    _ = try play(pool, "/E").get()
    XCTAssertNil(factory.players[2].value)
    XCTAssertEqual(factory.trace.peakAlive, 3)
  }

  @objc func testPlayingSameSourceReusesOnlySelectedCursorVoice() throws {
    let factory = Factory()
    let pool = MacosSfxPool(makePlayer: factory.make)
    defer { dispose(pool) }
    _ = try play(pool, "/A", cap: 1).get()
    _ = try play(pool, "/A", cap: 1, volume: 0).get()
    XCTAssertEqual(factory.paths.count, 1)
    XCTAssertEqual(factory.players[0].value?.playCount, 2)
    XCTAssertEqual(factory.players[0].value?.rawTime, 0)
    XCTAssertEqual(factory.players[0].value?.rawVolume, 0)
  }

  @objc func testSameSourceCanOverlapBeforeIdleReuse() throws {
    let factory = Factory()
    let pool = MacosSfxPool(makePlayer: factory.make)
    defer { dispose(pool) }
    _ = try play(pool, "/A", cap: 2).get()
    let overlapping = try play(pool, "/A", cap: 2).get()
    XCTAssertEqual(overlapping.activeVoices, 2)
    XCTAssertEqual(factory.paths, ["/A", "/A"])
    XCTAssertEqual(factory.players[0].value?.playCount, 1)
    factory.players[0].value?.playing = false
    let replay = try play(pool, "/A", cap: 2, volume: 0.25).get()
    XCTAssertEqual(replay.activeVoices, 2)
    XCTAssertEqual(factory.paths.count, 2)
    XCTAssertEqual(factory.players[0].value?.playCount, 2)
    XCTAssertEqual(factory.players[0].value?.prepareCount, 1)
    XCTAssertEqual(factory.players[0].value?.rawTime, 0)
    XCTAssertEqual(factory.players[1].value?.playCount, 1)
    XCTAssertEqual(factory.trace.peakAlive, 2)
  }

  @objc func testPrepareFailureReleasesSlotAndRetryPreparesAgain() throws {
    let factory = Factory()
    let pool = MacosSfxPool(makePlayer: factory.make)
    defer { dispose(pool) }
    _ = try play(pool, "/A", cap: 1).get()
    factory.prepareNext = false
    assertFailure(play(pool, "/B", cap: 1))
    XCTAssertEqual(factory.trace.alive, 0)
    XCTAssertNil(factory.players[0].value)
    XCTAssertNil(factory.players[1].value)
    let result = try play(pool, "/B", cap: 1).get()
    XCTAssertEqual(factory.paths, ["/A", "/B", "/B"])
    XCTAssertEqual(result.voiceCount, 1)
    XCTAssertEqual(factory.trace.peakAlive, 1)
  }

  @objc func testPlayFailureDoesNotReportSuccessOrPoisonCache() throws {
    let factory = Factory()
    let pool = MacosSfxPool(makePlayer: factory.make)
    defer { dispose(pool) }
    factory.playNext = false
    assertFailure(play(pool, "/A", cap: 1))
    XCTAssertEqual(factory.trace.alive, 0)
    _ = try play(pool, "/A", cap: 1).get()
    XCTAssertEqual(factory.paths.count, 2)
    XCTAssertEqual(factory.trace.peakAlive, 1)
  }

  @objc func testFactoryFailurePropagatesAndPoolRecovers() throws {
    let factory = Factory()
    let pool = MacosSfxPool(makePlayer: factory.make)
    defer { dispose(pool) }
    factory.throwNext = true
    let result = play(pool, "/A")
    if case .failure(let error) = result {
      XCTAssertTrue(error is FakeError)
    } else { XCTFail("Underlying factory error was lost") }
    _ = try play(pool, "/A").get()
    XCTAssertEqual(factory.paths, ["/A"])
  }

  @objc func testValidationAndFixedLimitCannotGrowPool() throws {
    let factory = Factory()
    let pool = MacosSfxPool(makePlayer: factory.make)
    defer { dispose(pool) }
    assertFailure(play(pool, "relative/path"))
    assertFailure(play(pool, "/A", cap: 0))
    assertFailure(play(pool, "/A", poolId: ""))
    for volume in [Double.nan, .infinity, -0.01, 1.01] {
      assertFailure(play(pool, "/A", volume: volume))
    }
    XCTAssertEqual(factory.paths.count, 0)
    _ = try play(pool, "/A", cap: 1).get()
    assertFailure(play(pool, "/B", cap: 2))
    XCTAssertEqual(factory.paths.count, 1)
    XCTAssertEqual(factory.trace.alive, 1)
  }

  @objc func testDisposalIsSerialAndPoolsAreIndependent() throws {
    let factory = Factory()
    let pool = MacosSfxPool(makePlayer: factory.make)
    defer { dispose(pool, "other"); dispose(pool) }
    _ = try play(pool, "/other", cap: 1, poolId: "other").get()
    let played = expectation(description: "queued playback")
    let disposed = expectation(description: "queued disposal")
    var callbacks: [String] = []
    pool.play(poolId: "test", maxVoices: 1, assetPath: "/A", volume: 1) { result in
      XCTAssertTrue(Thread.isMainThread)
      if case .failure(let error) = result { XCTFail("Queued playback failed: \(error)") }
      callbacks.append("play")
      played.fulfill()
    }
    pool.dispose(poolId: "test") {
      XCTAssertTrue(Thread.isMainThread)
      callbacks.append("dispose")
      disposed.fulfill()
    }
    wait(for: [played, disposed], timeout: 3)
    XCTAssertEqual(callbacks, ["play", "dispose"])
    XCTAssertNil(factory.players[1].value)
    XCTAssertNotNil(factory.players[0].value)
    XCTAssertEqual(factory.trace.alive, 1)
    dispose(pool)
    let restarted = try play(pool, "/B", cap: 2).get()
    XCTAssertEqual(restarted.voiceCount, 1)
    dispose(pool)
    dispose(pool, "other")
    XCTAssertEqual(factory.trace.alive, 0)
    XCTAssertTrue(factory.trace.mainThreadAccesses.isEmpty)
  }

}

@main
struct NativePoolTestRunner {
  static func main() {
    let suite = XCTestSuite(forTestCaseClass: MacosSfxPoolTests.self)
    suite.run()
    guard let result = suite.testRun, result.executionCount == 10 else {
      fputs("Native pool test discovery did not execute all 10 cases.\n", stderr)
      exit(2)
    }
    exit(result.totalFailureCount == 0 ? 0 : 1)
  }
}
