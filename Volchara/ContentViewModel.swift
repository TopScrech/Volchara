import SwiftUI

@MainActor
@Observable
final class ContentViewModel {
    var selectedMode: SoundMode = .pain
    var minAmplitude = 0.3
    var isListening = false
    var statusText = "Ready"
    var lastSlapText = "No slaps yet"
    
    private let engine = SpankEngine()
    
    init() {
        engine.onStatus = { [weak self] text in
            self?.statusText = text
        }
        
        engine.onSlap = { [weak self] text in
            self?.lastSlapText = text
        }
    }
    
    func toggleListening() {
        if isListening {
            engine.stop()
            isListening = false
            return
        }
        
        do {
            try engine.start(mode: selectedMode, minAmplitude: minAmplitude)
            isListening = true
        } catch {
            statusText = error.localizedDescription
            isListening = false
        }
    }
    
    func sensitivityChanged(to value: Double) {
        minAmplitude = value
        engine.updateSensitivity(value)
    }
    
    func modeChanged(to mode: SoundMode) {
        selectedMode = mode
        
        guard isListening else { return }
        
        do {
            try engine.start(mode: selectedMode, minAmplitude: minAmplitude)
        } catch {
            statusText = error.localizedDescription
            isListening = false
            engine.stop()
        }
    }
    
    func triggerTestSlap() {
        engine.triggerManualSlap()
    }
    
    func copyStatusToClipboard() {
        let text = """
        Status: \(statusText)
        Last slap: \(lastSlapText)
        """
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        statusText = "Status copied to clipboard"
    }
}
