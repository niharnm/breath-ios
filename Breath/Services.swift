import AVFoundation
import AudioToolbox
import Foundation

final class SpeechReader: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

final class CompressionMetronome: ObservableObject {
    @Published var isRunning = false
    @Published var pulse = false

    private var timer: Timer?

    func toggle() {
        isRunning ? stop() : start()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 60.0 / 110.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        pulse = false
    }

    private func tick() {
        pulse.toggle()
        AudioServicesPlaySystemSound(1104)
    }
}
