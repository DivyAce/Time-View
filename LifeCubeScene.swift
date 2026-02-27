import SceneKit
import QuartzCore
#if canImport(UIKit)
import UIKit
public typealias SystemColor = UIColor
#elseif canImport(AppKit)
import AppKit
public typealias SystemColor = NSColor
#endif

class LifeCubeScene: SCNScene {
    
    nonisolated(unsafe) var blockNodes: [SCNNode] = []
    nonisolated(unsafe) var livedGeometry: SCNBox!
    nonisolated(unsafe) var remainingGeometry: SCNBox!
    nonisolated(unsafe) var screenTimeGeometry: SCNBox!
    nonisolated(unsafe) var sleepGeometry: SCNBox!
    nonisolated(unsafe) var healthGeometry: SCNBox!
    nonisolated(unsafe) var cubeRootNode: SCNNode!
    nonisolated(unsafe) var cameraNode: SCNNode!
    
    let gridSize = 10
    let blockSize: CGFloat = 0.07
    let blockSpacing: CGFloat = 0.09
    
    override init() {
        super.init()
        createGeometries()
        buildScene()
        setupLighting()
        setupCamera()
        addIdleAnimations()
        addParticles()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Materials & Geometries
    
    private func makeBox(
        diffuse: SystemColor, emission: SystemColor,
        roughness: CGFloat, metalness: CGFloat, transparency: CGFloat = 1.0,
        clearCoat: CGFloat = 1.0, clearCoatRoughness: CGFloat = 0.1
    ) -> SCNBox {
        let box = SCNBox(width: blockSize, height: blockSize, length: blockSize, chamferRadius: blockSize * 0.22)
        let material = SCNMaterial()
        material.diffuse.contents = diffuse
        material.emission.contents = emission
        material.lightingModel = .physicallyBased
        material.roughness.contents = roughness
        material.metalness.contents = metalness
        material.transparency = transparency
        material.clearCoat.contents = clearCoat
        material.clearCoatRoughness.contents = clearCoatRoughness
        material.fresnelExponent = 2.0
        box.firstMaterial = material
        return box
    }
    
    private func createGeometries() {
        // Lived: Rich soft violet — clearly visible, slightly smaller and matte
        livedGeometry = makeBox(
            diffuse: SystemColor(red: 0.56, green: 0.44, blue: 0.82, alpha: 1.0),
            emission: SystemColor(red: 0.2, green: 0.15, blue: 0.35, alpha: 1.0),
            roughness: 0.5, metalness: 0.3, transparency: 0.92, clearCoat: 0.6
        )
        
        // Remaining: Warm amber-gold — glowing possibilities
        remainingGeometry = makeBox(
            diffuse: SystemColor(red: 0.96, green: 0.75, blue: 0.2, alpha: 0.95),
            emission: SystemColor(red: 0.4, green: 0.3, blue: 0.05, alpha: 1.0),
            roughness: 0.15, metalness: 0.6, transparency: 0.9, clearCoat: 1.0
        )
        
        // Screen Time: Coral pink — Apple Screen Time style
        screenTimeGeometry = makeBox(
            diffuse: SystemColor(red: 0.95, green: 0.35, blue: 0.45, alpha: 0.95),
            emission: SystemColor(red: 0.4, green: 0.1, blue: 0.15, alpha: 1.0),
            roughness: 0.15, metalness: 0.5, transparency: 0.9, clearCoat: 1.0
        )
        
        // Sleep: Deep indigo blue
        sleepGeometry = makeBox(
            diffuse: SystemColor(red: 0.35, green: 0.34, blue: 0.84, alpha: 0.95),
            emission: SystemColor(red: 0.1, green: 0.1, blue: 0.35, alpha: 1.0),
            roughness: 0.2, metalness: 0.5, transparency: 0.92, clearCoat: 0.8
        )
        
        // Health: Vibrant emerald green
        healthGeometry = makeBox(
            diffuse: SystemColor(red: 0.2, green: 0.82, blue: 0.45, alpha: 0.95),
            emission: SystemColor(red: 0.05, green: 0.35, blue: 0.15, alpha: 1.0),
            roughness: 0.15, metalness: 0.5, transparency: 0.9, clearCoat: 1.0
        )
    }
    
    // MARK: - Scene Construction
    
    private func buildScene() {
        // Clean warm white background
        background.contents = SystemColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)
        
        // Subtle light fog for depth
        fogStartDistance = 3.0
        fogEndDistance = 7.0
        fogColor = SystemColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)
        fogDensityExponent = 1.0
        
        cubeRootNode = SCNNode()
        rootNode.addChildNode(cubeRootNode)
        
        let totalWidth = CGFloat(gridSize) * blockSpacing
        let offset = totalWidth / 2.0 - blockSpacing / 2.0
        
        for x in 0..<gridSize {
            for y in 0..<gridSize {
                for z in 0..<gridSize {
                    let node = SCNNode(geometry: remainingGeometry)
                    node.position = SCNVector3(
                        Float(CGFloat(x) * blockSpacing - offset),
                        Float(CGFloat(y) * blockSpacing - offset),
                        Float(CGFloat(z) * blockSpacing - offset)
                    )
                    cubeRootNode.addChildNode(node)
                    blockNodes.append(node)
                }
            }
        }
        
        cubeRootNode.eulerAngles = SCNVector3(Float.pi * 0.08, Float.pi * 0.25, Float.pi * 0.03)
    }
    
    // MARK: - Lighting
    
    private func setupLighting() {
        // Bright ambient fill
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 600
        ambientLight.light?.color = SystemColor(white: 0.95, alpha: 1.0)
        rootNode.addChildNode(ambientLight)
        
        // Warm key light from top-right
        let primaryLight = SCNNode()
        primaryLight.light = SCNLight()
        primaryLight.light?.type = .directional
        primaryLight.light?.intensity = 1000
        primaryLight.light?.castsShadow = true
        primaryLight.light?.shadowMode = .deferred
        primaryLight.light?.shadowSampleCount = 8
        primaryLight.light?.shadowRadius = 6
        primaryLight.light?.shadowColor = SystemColor(white: 0.0, alpha: 0.15)
        primaryLight.light?.color = SystemColor(white: 1.0, alpha: 1.0)
        primaryLight.position = SCNVector3(x: 5, y: 10, z: 5)
        primaryLight.look(at: SCNVector3(0, 0, 0))
        rootNode.addChildNode(primaryLight)
        
        // Cool fill light from below-left
        let rimLight = SCNNode()
        rimLight.light = SCNLight()
        rimLight.light?.type = .directional
        rimLight.light?.intensity = 400
        rimLight.light?.color = SystemColor(red: 0.6, green: 0.7, blue: 1.0, alpha: 1.0)
        rimLight.position = SCNVector3(x: -5, y: -2, z: -5)
        rimLight.look(at: SCNVector3(0, 0, 0))
        rootNode.addChildNode(rimLight)
    }
    
    // MARK: - Camera
    
    private func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 38
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 50
        
        // Subtle HDR for glass reflections
        cameraNode.camera?.wantsHDR = true
        cameraNode.camera?.bloomIntensity = 0.3
        cameraNode.camera?.bloomThreshold = 0.6
        cameraNode.camera?.bloomBlurRadius = 8
        cameraNode.camera?.wantsExposureAdaptation = false
        cameraNode.camera?.motionBlurIntensity = 0.02
        
        // Gentle depth of field
        cameraNode.camera?.wantsDepthOfField = true
        cameraNode.camera?.focusDistance = 2.2
        cameraNode.camera?.fStop = 3.5
        
        // Very subtle vignette for light theme
        cameraNode.camera?.vignettingIntensity = 0.15
        cameraNode.camera?.vignettingPower = 1.0
        
        cameraNode.camera?.colorGrading.contents = nil
        cameraNode.camera?.contrast = 0.02
        cameraNode.camera?.saturation = 1.15
        
        cameraNode.position = SCNVector3(0, 0.2, 2.2)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        rootNode.addChildNode(cameraNode)
    }
    
    // MARK: - Particles
    
    private func addParticles() {
        let particleSystem = SCNParticleSystem()
        particleSystem.particleSize = 0.012
        particleSystem.particleSizeVariation = 0.008
        particleSystem.birthRate = 40
        particleSystem.birthDirection = .random
        particleSystem.particleVelocity = 0.008
        particleSystem.particleVelocityVariation = 0.004
        particleSystem.particleColor = SystemColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 0.08)
        particleSystem.particleColorVariation = SCNVector4(0.1, 0.1, 0.1, 0.03)
        particleSystem.blendMode = .alpha
        particleSystem.isLightingEnabled = false
        
        let emitterNode = SCNNode()
        emitterNode.position = SCNVector3(0, 0, 0)
        emitterNode.addParticleSystem(particleSystem)
        rootNode.addChildNode(emitterNode)
    }
    
    // MARK: - Idle Animations
    
    private func addIdleAnimations() {
        let rotate = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 90)
        cubeRootNode.runAction(SCNAction.repeatForever(rotate))
        
        let breatheIn = SCNAction.scale(to: 1.012, duration: 3.5)
        breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SCNAction.scale(to: 0.988, duration: 3.5)
        breatheOut.timingMode = .easeInEaseOut
        let breathe = SCNAction.sequence([breatheIn, breatheOut])
        cubeRootNode.runAction(SCNAction.repeatForever(breathe))
    }
    
    // MARK: - Block Updates
    
    @MainActor
    func updateBlocks(model: LifeModel) {
        let total = blockNodes.count
        let lived = min(model.livedBlocks, total)
        let screenTime = min(model.screenTimeBlocks, total - lived)
        let sleep = min(model.sleepBlocks, total - lived - screenTime)
        let health = min(model.exerciseBonusBlocks, total - lived - screenTime - sleep)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.8
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        for (index, node) in blockNodes.enumerated() {
            if index < lived {
                node.geometry = livedGeometry
                node.scale = SCNVector3(0.85, 0.85, 0.85)
                node.opacity = 0.9
            } else if index < lived + screenTime {
                node.geometry = screenTimeGeometry
                node.scale = SCNVector3(0.75, 0.75, 0.75)
                node.opacity = 0.92
            } else if index < lived + screenTime + sleep {
                node.geometry = sleepGeometry
                node.scale = SCNVector3(0.9, 0.9, 0.9)
                node.opacity = 0.92
            } else if index >= total - health {
                node.geometry = healthGeometry
                node.scale = SCNVector3(1.08, 1.08, 1.08)
                node.opacity = 1.0
            } else {
                node.geometry = remainingGeometry
                node.scale = SCNVector3(1.0, 1.0, 1.0)
                node.opacity = 1.0
            }
        }
        
        SCNTransaction.commit()
    }
    
    // MARK: - Assembly Animation (Wave Pattern)
    
    func animateAssembly(completion: @MainActor @Sendable @escaping () -> Void) {
        var originalPositions: [SCNVector3] = []
        let totalWidth = CGFloat(gridSize) * blockSpacing
        let offset = totalWidth / 2.0 - blockSpacing / 2.0
        
        for (index, node) in blockNodes.enumerated() {
            originalPositions.append(node.position)
            
            // Scatter from center outward in a sphere
            let x = index / (gridSize * gridSize)
            let y = (index / gridSize) % gridSize
            let z = index % gridSize
            
            let dirX = Float(CGFloat(x) * blockSpacing - offset)
            let dirY = Float(CGFloat(y) * blockSpacing - offset)
            let dirZ = Float(CGFloat(z) * blockSpacing - offset)
            let dist = sqrt(dirX * dirX + dirY * dirY + dirZ * dirZ)
            let scale: Float = dist > 0 ? 5.0 / dist : 5.0
            
            node.position = SCNVector3(dirX * scale, dirY * scale, dirZ * scale)
            node.opacity = 0
            node.scale = SCNVector3(0.01, 0.01, 0.01)
        }
        
        let totalDuration = 2.5
        for (index, node) in blockNodes.enumerated() {
            let x = index / (gridSize * gridSize)
            let y = (index / gridSize) % gridSize
            let z = index % gridSize
            
            // Wave pattern: delay based on distance from corner
            let waveDistance = sqrt(Double(x * x + y * y + z * z))
            let maxDist = sqrt(Double(gridSize * gridSize * 3))
            let delay = (waveDistance / maxDist) * totalDuration * 0.5
            
            let originalPos = originalPositions[index]
            
            // SCNNode is not Sendable but safe to use from main queue
            nonisolated(unsafe) let unsafeNode = node
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1.0
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
                unsafeNode.position = originalPos
                unsafeNode.opacity = 1.0
                unsafeNode.scale = SCNVector3(1, 1, 1)
                SCNTransaction.commit()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 1.5) {
            completion()
        }
    }
    
    // MARK: - Block Info for Tap Interaction
    
    enum BlockCategory: String, Sendable {
        case lived = "Lived"
        case screenTime = "Screen Time"
        case sleep = "Sleep"
        case health = "Exercise Bonus"
        case remaining = "Remaining"
    }
    
    struct BlockInfo: Sendable {
        let category: BlockCategory
        let blockIndex: Int
        let totalInCategory: Int
    }
    
    @MainActor
    func blockInfo(for node: SCNNode, model: LifeModel) -> BlockInfo? {
        guard let index = blockNodes.firstIndex(of: node) else { return nil }
        let total = blockNodes.count
        let lived = Int(model.livedBlocks < total ? model.livedBlocks : total)
        let screen = Int(model.screenTimeBlocks < (total - lived) ? model.screenTimeBlocks : (total - lived))
        let slp = Int(model.sleepBlocks < (total - lived - screen) ? model.sleepBlocks : (total - lived - screen))
        let health = Int(model.exerciseBonusBlocks < (total - lived - screen - slp) ? model.exerciseBonusBlocks : (total - lived - screen - slp))
        
        if index < lived {
            return BlockInfo(category: .lived, blockIndex: Int(index), totalInCategory: lived)
        } else if index < lived + screen {
            return BlockInfo(category: .screenTime, blockIndex: Int(index - lived), totalInCategory: screen)
        } else if index < lived + screen + slp {
            return BlockInfo(category: .sleep, blockIndex: Int(index - lived - screen), totalInCategory: slp)
        } else if index >= total - health {
            return BlockInfo(category: .health, blockIndex: Int(index - (total - health)), totalInCategory: health)
        } else {
            let remainStart = lived + screen + slp
            return BlockInfo(category: .remaining, blockIndex: Int(index - remainStart), totalInCategory: Int(total - lived - screen - slp - health))
        }
    }
}
