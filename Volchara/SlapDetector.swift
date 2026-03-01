import Foundation

struct SlapEvent {
    let amplitude: Double
}

final class SlapDetector {
    private let highPassAlpha = 0.95
    private let cusumK = 0.0005
    private let cusumH = 0.01

    private var previousRaw = SensorSample(x: 0, y: 0, z: 0)
    private var previousOutput = SensorSample(x: 0, y: 0, z: 0)
    private var isInitialized = false
    private var rollingMean = 0.0
    private var cusumPositive = 0.0

    func reset() {
        previousRaw = SensorSample(x: 0, y: 0, z: 0)
        previousOutput = SensorSample(x: 0, y: 0, z: 0)
        isInitialized = false
        rollingMean = 0
        cusumPositive = 0
    }

    func process(_ sample: SensorSample, minAmplitude: Double) -> SlapEvent? {
        if !isInitialized {
            previousRaw = sample
            isInitialized = true
            return nil
        }

        let filtered = highPass(sample)
        let rawAmplitude = filtered.magnitude

        rollingMean += 0.005 * (rawAmplitude - rollingMean)
        cusumPositive = max(0, cusumPositive + rawAmplitude - rollingMean - cusumK)

        // Convert raw dynamic acceleration into 0...1 scale similar to spank threshold UX
        let normalizedAmplitude = min(1, rawAmplitude / 0.03)
        let passesThreshold = normalizedAmplitude >= minAmplitude
        let significantChange = cusumPositive >= cusumH || normalizedAmplitude >= min(1, minAmplitude * 1.3)

        if passesThreshold && significantChange {
            cusumPositive = 0
            return SlapEvent(amplitude: normalizedAmplitude)
        }

        return nil
    }

    private func highPass(_ sample: SensorSample) -> SensorSample {
        let x = highPassAxis(sample.x, previousRaw.x, previousOutput.x)
        let y = highPassAxis(sample.y, previousRaw.y, previousOutput.y)
        let z = highPassAxis(sample.z, previousRaw.z, previousOutput.z)

        previousRaw = sample
        previousOutput = SensorSample(x: x, y: y, z: z)

        return previousOutput
    }

    private func highPassAxis(_ current: Double, _ previousRaw: Double, _ previousOutput: Double) -> Double {
        highPassAlpha * (previousOutput + current - previousRaw)
    }
}
