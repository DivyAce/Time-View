import SwiftUI
import SceneKit

class SceneContainer: ObservableObject {
    let scene = LifeCubeScene()
}

struct ExperienceView: View {
    @EnvironmentObject var model: LifeModel
    @StateObject private var container = SceneContainer()
    @State private var isAssembled = false
    @State private var showControls = false
    @State private var showStats = false
    @State private var tappedBlockInfo: LifeCubeScene.BlockInfo? = nil
    @State private var showBlockPopup = false
    
    var body: some View {
        ZStack {
            SceneKitView(scene: container.scene, model: model, onBlockTap: { info in
                HapticManager.shared.playSliderTick()
                tappedBlockInfo = info
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    showBlockPopup = true
                }
            })
            .ignoresSafeArea()
            .onAppear {
                startAssembly()
            }
            
            VStack(spacing: 0) {
                if showStats {
                    topStatsBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                if showBlockPopup, let info = tappedBlockInfo {
                    blockInfoCard(info: info)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 8)
                }
                
                if showControls {
                    VStack(spacing: 8) {
                        legendBar
                        ControlPanelView()
                            .environmentObject(model)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            if !isAssembled {
                assemblyOverlay
            }
        }
        .onReceive(model.objectWillChange) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                container.scene.updateBlocks(model: model)
            }
        }
    }
    
    // MARK: - Block Info Card
    
    private func blockInfoCard(info: LifeCubeScene.BlockInfo) -> some View {
        let color: Color = {
            switch info.category {
            case .lived: return Color.tvLived
            case .screenTime: return Color.tvScreenTime
            case .sleep: return Color.tvSleep
            case .health: return Color.tvHealth
            case .remaining: return Color.tvRemaining
            }
        }()
        
        let icon: String = {
            switch info.category {
            case .lived: return "clock.arrow.circlepath"
            case .screenTime: return "iphone"
            case .sleep: return "moon.zzz.fill"
            case .health: return "heart.circle.fill"
            case .remaining: return "sparkles"
            }
        }()
        
        let message: String = {
            let daysPerBlock = model.expectedLifespan * 365.25 / Double(model.totalBlocks)
            switch info.category {
            case .lived:
                return "This block = ~\(Int(daysPerBlock)) days you've already lived. You've experienced \(model.daysLived) days so far — each one shaped who you are."
            case .screenTime:
                return "At \(Int(model.dailyScreenTime))h/day, screen time will consume ~\(String(format: "%.1f", model.screenTimeYears)) years of your remaining life. That's \(info.totalInCategory) blocks."
            case .sleep:
                return "Sleep takes ~\(Int(model.sleepYears)) years of your remaining life. But it's not wasted — it's essential fuel for everything else."
            case .health:
                return "Exercise bonus! Your \(Int(model.dailyExerciseMinutes)) min/day could add ~\(String(format: "%.1f", model.exerciseBonusYears)) years. That's \(info.totalInCategory) extra blocks of life."
            case .remaining:
                return "~\(Int(daysPerBlock)) days of pure possibility. How will you spend them? You have \(info.totalInCategory) free blocks remaining."
            }
        }()
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(color.opacity(0.12)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.category.rawValue)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(Color.tvPrimary)
                    Text("Block \(info.blockIndex + 1) of \(info.totalInCategory)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(color)
                }
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { showBlockPopup = false }
                }) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundStyle(Color.tvSecondary)
                }
            }
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.tvSecondary)
                .lineSpacing(2)
        }
        .padding(16)
        .glassCard(cornerRadius: 16, tint: color)
        .padding(.horizontal, 16)
    }
    
    private var assemblyOverlay: some View {
        ZStack {
            Color(.systemBackground).opacity(0.85).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Assembling Timeline...")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.tvPrimary)
                ProgressView().tint(Color.tvAccent).scaleEffect(1.2)
            }
        }
    }
    
    private var topStatsBar: some View {
        HStack(spacing: 12) {
            statBadge(value: "\(Int(model.yearsRemaining))", label: "years left", color: Color.tvRemaining)
            statBadge(value: "\(Int(model.freeYears))", label: "truly free", color: Color.tvAccent)
            statBadge(value: "\(Int(model.screenTimePercentage))%", label: "on screens", color: Color.tvScreenTime)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private func statBadge(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.tvSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 14)
    }
    
    private var legendBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 14) {
                legendDot(color: Color.tvLived, label: "Lived")
                legendDot(color: Color.tvRemaining, label: "Free")
                legendDot(color: Color.tvScreenTime, label: "Screen")
                legendDot(color: Color.tvSleep, label: "Sleep")
                legendDot(color: Color.tvHealth, label: "Health+")
            }
            Text("Tap any cube to explore • Each ≈ \(Int(model.daysPerBlock)) days")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.tvSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Color.tvPrimary)
        }
    }
    
    private func startAssembly() {
        HapticManager.shared.playOpeningPulse()
        SoundManager.shared.playAssemblyTone()
        container.scene.animateAssembly {
            container.scene.updateBlocks(model: model)
            withAnimation(.spring(response: 0.8, dampingFraction: 0.85).delay(0.3)) { isAssembled = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.8)) { showStats = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(1.2)) { showControls = true }
        }
    }
}

// MARK: - SceneKit UIViewRepresentable with Tap Support

struct SceneKitView: UIViewRepresentable {
    let scene: LifeCubeScene
    let model: LifeModel
    let onBlockTap: @MainActor @Sendable (LifeCubeScene.BlockInfo) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scene: scene, model: model, onBlockTap: onBlockTap)
    }
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.backgroundColor = .clear
        scnView.allowsCameraControl = true
        scnView.antialiasingMode = .multisampling4X
        scnView.isJitteringEnabled = true
        scnView.preferredFramesPerSecond = 60
        
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tap)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.model = model
    }
    
    @MainActor
    class Coordinator: NSObject {
        let scene: LifeCubeScene
        var model: LifeModel
        let onBlockTap: @MainActor @Sendable (LifeCubeScene.BlockInfo) -> Void
        
        init(scene: LifeCubeScene, model: LifeModel, onBlockTap: @MainActor @Sendable @escaping (LifeCubeScene.BlockInfo) -> Void) {
            self.scene = scene
            self.model = model
            self.onBlockTap = onBlockTap
        }
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let scnView = recognizer.view as? SCNView else { return }
            let location = recognizer.location(in: scnView)
            let results = scnView.hitTest(location, options: [
                .searchMode: SCNHitTestSearchMode.closest.rawValue
            ])
            if let hit = results.first {
                if let info = scene.blockInfo(for: hit.node, model: model) {
                    onBlockTap(info)
                }
            }
        }
    }
}
