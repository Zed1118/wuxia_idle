import AVFAudio
import Foundation

/// The protocol keeps the production selection/lifetime algorithm testable
/// without an audio device. AVAudioPlayer remains the only shipping backend.
protocol MacosSfxPlayer: AnyObject {
  var isPlaying: Bool { get }
  var volume: Float { get set }
  var currentTime: TimeInterval { get set }
  func prepareToPlay() -> Bool
  func pause()
  func play() -> Bool
}

extension AVAudioPlayer: MacosSfxPlayer {}

enum MacosSfxPoolError: LocalizedError {
  case invalidArguments
  case changedVoiceLimit
  case preparationFailed(String)
  case playbackFailed(String)

  var errorDescription: String? {
    switch self {
    case .invalidArguments:
      return "Expected a nonempty pool ID, positive voice limit, absolute local path and volume in 0...1."
    case .changedVoiceLimit:
      return "An existing sound pool cannot change its voice limit."
    case .preparationFailed(let path):
      return "Could not prepare sound: \(path)"
    case .playbackFailed(let path):
      return "Could not start sound: \(path)"
    }
  }
}

struct MacosSfxPlayResult {
  let started: Bool
  let voiceCount: Int
  let activeVoices: Int
}

/// AVPlayer's media preparation and notifications can synchronously stall the
/// platform/UI thread. All short-sound player access, including destruction,
/// stays on this serial queue; Flutter-facing completions return on main.
final class MacosSfxPool {
  typealias PlayerFactory = (URL) throws -> MacosSfxPlayer

  private let queue = DispatchQueue(label: "com.pen.wuxia.macos_sfx", qos: .userInitiated)
  private let makePlayer: PlayerFactory
  private var pools: [String: Pool] = [:]

  init(makePlayer: @escaping PlayerFactory = { try AVAudioPlayer(contentsOf: $0) }) {
    self.makePlayer = makePlayer
  }

  func play(
    poolId: String,
    maxVoices: Int,
    assetPath: String,
    volume: Double,
    completion: @escaping (Result<MacosSfxPlayResult, Error>) -> Void
  ) {
    queue.async {
      let result = Result {
        guard !poolId.isEmpty, maxVoices > 0,
              (assetPath as NSString).isAbsolutePath,
              volume.isFinite, (0...1).contains(volume) else {
          throw MacosSfxPoolError.invalidArguments
        }
        let pool: Pool
        if let existing = self.pools[poolId] {
          guard existing.voices.count == maxVoices else {
            throw MacosSfxPoolError.changedVoiceLimit
          }
          pool = existing
        } else {
          pool = Pool(maxVoices: maxVoices)
          self.pools[poolId] = pool
        }
        return try pool.play(assetPath: assetPath, volume: volume, makePlayer: self.makePlayer)
      }
      DispatchQueue.main.async { completion(result) }
    }
  }

  func dispose(poolId: String, completion: @escaping () -> Void) {
    queue.async {
      self.pools.removeValue(forKey: poolId)?.dispose()
      DispatchQueue.main.async(execute: completion)
    }
  }

  deinit {
    // Window teardown may happen on main. Keep the final player references
    // alive until this queue has paused and released them.
    let remaining = pools
    queue.async {
      for pool in remaining.values { pool.dispose() }
    }
  }

  private final class Voice {
    var player: MacosSfxPlayer?
    var assetPath: String?

    func release() {
      player?.pause()
      player = nil
      assetPath = nil
    }
  }

  private final class Pool {
    let voices: [Voice]
    private var cursor = 0

    init(maxVoices: Int) {
      voices = (0..<maxVoices).map { _ in Voice() }
    }

    private func selectVoice(assetPath: String) -> Int {
      var idleIndex: Int?
      for offset in 0..<voices.count {
        let index = (cursor + offset) % voices.count
        let voice = voices[index]
        if voice.player?.isPlaying != true {
          if voice.assetPath == assetPath { return index }
          if idleIndex == nil { idleIndex = index }
        }
      }
      return idleIndex ?? cursor
    }

    func play(
      assetPath: String, volume: Double, makePlayer: PlayerFactory
    ) throws -> MacosSfxPlayResult {
      let index = selectVoice(assetPath: assetPath)
      cursor = (index + 1) % voices.count
      let voice = voices[index]
      do {
        if voice.assetPath != assetPath || voice.player == nil {
          // Release the old instance before allocating another, so even
          // preparation cannot temporarily exceed this pool's voice cap.
          voice.release()
          let player = try makePlayer(URL(fileURLWithPath: assetPath))
          voice.player = player
          guard player.prepareToPlay() else {
            throw MacosSfxPoolError.preparationFailed(assetPath)
          }
          voice.assetPath = assetPath
        } else {
          voice.player?.pause()
          voice.player?.currentTime = 0
        }
        guard let player = voice.player else {
          throw MacosSfxPoolError.preparationFailed(assetPath)
        }
        player.volume = Float(volume)
        guard player.play() else {
          throw MacosSfxPoolError.playbackFailed(assetPath)
        }
        return MacosSfxPlayResult(
          started: true,
          voiceCount: voices.filter { $0.player != nil }.count,
          activeVoices: voices.filter { $0.player?.isPlaying == true }.count
        )
      } catch {
        // A failed preparation/play never leaves a cached-success marker.
        voice.release()
        throw error
      }
    }

    func dispose() {
      for voice in voices { voice.release() }
    }
  }
}
