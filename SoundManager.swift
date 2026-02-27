import AVFoundation

@MainActor
class SoundManager {
    static let shared = SoundManager()
    
    private var audioEngine: AVAudioEngine
    private var playerNode: AVAudioPlayerNode
    private var mixerNode: AVAudioMixerNode
    private let sampleRate: Double = 44100
    private var isSetup = false
    
    private init() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        mixerNode = AVAudioMixerNode()
        setup()
    }
    
    private func setup() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            
            audioEngine.attach(playerNode)
            audioEngine.attach(mixerNode)
            
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            audioEngine.connect(playerNode, to: mixerNode, format: format)
            audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: format)
            
            mixerNode.outputVolume = 0.3
            
            try audioEngine.start()
            isSetup = true
        } catch {
            print("Audio setup error: \(error)")
        }
    }
    
    // MARK: - Sound Effects
    
    func playTick() {
        playTone(frequency: 1200, duration: 0.03, volume: 0.08, attack: 0.002, release: 0.01)
    }
    
    func playTransitionChime() {
        // Two-note chime: C5 → E5
        playTone(frequency: 523.25, duration: 0.2, volume: 0.12, attack: 0.005, release: 0.08)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { @MainActor [weak self] in
            self?.playTone(frequency: 659.25, duration: 0.3, volume: 0.1, attack: 0.005, release: 0.15)
        }
    }
    
    func playAssemblyTone() {
        // Rising frequency sweep
        playFrequencySweep(from: 200, to: 800, duration: 1.5, volume: 0.06)
    }
    
    func playWarningTone() {
        playTone(frequency: 300, duration: 0.15, volume: 0.1, attack: 0.005, release: 0.05)
    }
    
    func playPositiveTone() {
        // Major third interval
        playTone(frequency: 440, duration: 0.15, volume: 0.08, attack: 0.005, release: 0.06)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { @MainActor [weak self] in
            self?.playTone(frequency: 554.37, duration: 0.2, volume: 0.07, attack: 0.005, release: 0.1)
        }
    }
    
    // MARK: - Tone Generation
    
    private func playTone(frequency: Double, duration: Double, volume: Float, attack: Double, release: Double) {
        guard isSetup else { return }
        
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        guard let data = buffer.floatChannelData?[0] else { return }
        
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            // Envelope: attack → sustain → release
            let attackEnv = min(1.0, t / max(attack, 0.001))
            let releaseEnv = min(1.0, (duration - t) / max(release, 0.001))
            let envelope = Float(min(attackEnv, releaseEnv))
            // Sine wave with slight harmonic for warmth
            let fundamental = sin(2.0 * .pi * frequency * t)
            let harmonic = sin(2.0 * .pi * frequency * 2.0 * t) * 0.15
            data[i] = Float(fundamental + harmonic) * volume * envelope
        }
        
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        playerNode.play()
    }
    
    private func playFrequencySweep(from startFreq: Double, to endFreq: Double, duration: Double, volume: Float) {
        guard isSetup else { return }
        
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        guard let data = buffer.floatChannelData?[0] else { return }
        
        var phase: Double = 0
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let progress = t / duration
            let freq = startFreq + (endFreq - startFreq) * progress * progress // Exponential sweep
            let envelope = Float(sin(.pi * progress)) // Smooth bell envelope
            phase += freq / sampleRate
            data[i] = Float(sin(2.0 * .pi * phase)) * volume * envelope
        }
        
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        playerNode.play()
    }
}
