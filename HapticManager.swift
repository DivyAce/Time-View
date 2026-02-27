import CoreHaptics

@MainActor
class HapticManager {
    static let shared = HapticManager()
    
    private nonisolated(unsafe) var engine: CHHapticEngine?
    private let supportsHaptics: Bool
    
    private init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        setupEngine()
    }
    
    private func setupEngine() {
        guard supportsHaptics else { return }
        do {
            let hapticEngine = try CHHapticEngine()
            hapticEngine.isAutoShutdownEnabled = true
            hapticEngine.resetHandler = { [weak hapticEngine] in
                try? hapticEngine?.start()
            }
            hapticEngine.stoppedHandler = { _ in }
            try hapticEngine.start()
            engine = hapticEngine
        } catch {
            print("Haptic engine creation error: \(error)")
        }
    }
    
    private func playPattern(_ events: [CHHapticEvent]) {
        guard supportsHaptics, let engine = engine else { return }
        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Silently fail on simulator or unsupported hardware
        }
    }
    
    // MARK: - Interaction Haptics
    
    func playSliderTick() {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            ],
            relativeTime: 0
        )
        playPattern([event])
    }
    
    func playSelection() {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ],
            relativeTime: 0
        )
        playPattern([event])
    }
    
    func playBlockCollapse() {
        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.05,
                duration: 0.15
            )
        ]
        playPattern(events)
    }
    
    func playBlockGlow() {
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
            ],
            relativeTime: 0,
            duration: 0.4
        )
        playPattern([event])
    }
    
    func playTransition() {
        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.12
            )
        ]
        playPattern(events)
    }
    
    func playOpeningPulse() {
        var events: [CHHapticEvent] = []
        for i in 0..<10 {
            let intensity = Float(i + 1) / 10.0
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2 + intensity * 0.3)
                ],
                relativeTime: Double(i) * 0.12
            )
            events.append(event)
        }
        // Final sustained pulse
        events.append(CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ],
            relativeTime: 1.2,
            duration: 0.5
        ))
        playPattern(events)
    }
    
    func playCountdown() {
        var events: [CHHapticEvent] = []
        for i in 0..<3 {
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: Double(i) * 0.5
            ))
        }
        // Final strong beat
        events.append(CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            ],
            relativeTime: 1.5
        ))
        playPattern(events)
    }
    
    func playSuccess() {
        let events = [
            // Light tap
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0
            ),
            // Bright tap following immediately
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0.1
            )
        ]
        playPattern(events)
    }
    
    func playHeavyThud() {
        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1) // Low sharpness = thud/bass feel
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                ],
                relativeTime: 0.05,
                duration: 0.2
            )
        ]
        playPattern(events)
    }
}
