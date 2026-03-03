import Foundation

@MainActor
final class SpankEngine {
    static let cooldown = 0.75
    
    private let sensorService = SPUSensorService()
    private let detector = SlapDetector()
    private let audioPlayer = AudioPlayerService()
    private let library = SoundLibrary()
    
    private var currentPack: SoundPack?
    private var escalationTracker: EscalationTracker?
    private var minAmplitude = 0.3
    private var lastPlaybackTime: Date = .distantPast
    
    var onStatus: ((String) -> Void)?
    var onSlap: ((String) -> Void)?
    
    func start(mode: SoundMode, minAmplitude: Double) throws {
        let pack = try library.loadPack(for: mode)
        
        currentPack = pack
        escalationTracker = pack.mode.usesEscalation ? EscalationTracker(fileCount: pack.files.count, cooldown: Self.cooldown) : nil
        detector.reset()
        lastPlaybackTime = .distantPast
        self.minAmplitude = minAmplitude
        
        let started = sensorService.start { [weak self] sample in
            self?.handle(sample)
        }
        
        guard started else {
            currentPack = nil
            escalationTracker = nil
            throw NSError(domain: "volchara", code: 1, userInfo: [NSLocalizedDescriptionKey: "SPU accelerometer is unavailable"])
        }
        
        onStatus?("Listening in \(mode.title) mode")
    }
    
    func stop() {
        sensorService.stop()
        currentPack = nil
        escalationTracker = nil
        onStatus?("Stopped")
    }
    
    func updateSensitivity(_ minAmplitude: Double) {
        self.minAmplitude = minAmplitude
        onStatus?("Sensitivity: \(String(format: "%.2f", minAmplitude))")
    }
    
    func isRunning() -> Bool {
        sensorService.isRunning
    }
    
    func triggerManualSlap() {
        playResponse(for: Date.now, amplitude: minAmplitude)
    }
    
    private func handle(_ sample: SensorSample) {
        guard let event = detector.process(sample, minAmplitude: minAmplitude) else {
            return
        }
        
        let now = Date.now
        
        if now.timeIntervalSince(lastPlaybackTime) < Self.cooldown {
            return
        }
        
        playResponse(for: now, amplitude: event.amplitude)
    }
    
    private func playResponse(for now: Date, amplitude: Double) {
        guard let currentPack else { return }
        
        let index: Int
        if currentPack.mode.usesEscalation, let escalationTracker {
            index = escalationTracker.nextIndex(now: now)
        } else {
            index = Int.random(in: 0 ..< currentPack.files.count)
        }
        
        let file = currentPack.files[index]
        lastPlaybackTime = now
        
        audioPlayer.play(url: file)
        let message = "slap amp=\(String(format: "%.3f", amplitude)) -> \(file.lastPathComponent)"
        onSlap?(message)
        onStatus?("Playing \(file.lastPathComponent)")
    }
}
