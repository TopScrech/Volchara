import Foundation

final class EscalationTracker {
    private let halfLifeSeconds = 30.0
    private let cooldownSeconds: Double
    private let maxIndex: Int
    private let scale: Double
    
    private var score = 0.0
    private var total = 0
    private var lastTime: Date?
    
    init(fileCount: Int, cooldown: TimeInterval) {
        cooldownSeconds = cooldown
        maxIndex = max(0, fileCount - 1)
        
        let ssMax = 1.0 / (1.0 - pow(0.5, cooldownSeconds / halfLifeSeconds))
        let denominator = log(Double(fileCount + 1))
        scale = denominator > 0 ? (ssMax - 1) / denominator : 1
    }
    
    func reset() {
        score = 0
        total = 0
        lastTime = nil
    }
    
    func nextIndex(now: Date) -> Int {
        if let lastTime {
            let elapsed = now.timeIntervalSince(lastTime)
            score *= pow(0.5, elapsed / halfLifeSeconds)
        }
        
        score += 1
        total += 1
        self.lastTime = now
        
        let mapped = Int(Double(maxIndex + 1) * (1 - exp(-(score - 1) / max(scale, 0.0001))))
        return min(mapped, maxIndex)
    }
}
