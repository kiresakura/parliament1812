import SpriteKit
import SwiftUI

// MARK: - Custom Transitions
struct MapPanTransition: ViewModifier {
    let isActive: Bool
    let direction: Edge

    func body(content: Content) -> some View {
        content
            .offset(x: isActive ? (direction == .leading ? 100 : -100) : 0)
            .opacity(isActive ? 0 : 1)
            .animation(.easeInOut(duration: 0.5), value: isActive)
    }
}

extension AnyTransition {
    static var mapPan: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        )
    }
}

// MARK: - Particle Systems
class DustScene: SKScene {
    override func didMove(to view: SKView) {
        scene?.backgroundColor = .clear
        view.allowsTransparency = true

        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark")  // Asset needs to exist
        emitter.particleBirthRate = 20
        emitter.particleLifetime = 10.0
        emitter.particlePositionRange = CGVector(dx: size.width, dy: size.height)
        emitter.particleSpeed = 10
        emitter.particleSpeedRange = 5
        emitter.particleAlpha = 0.5
        emitter.particleAlphaRange = 0.2
        emitter.particleScale = 0.1
        emitter.particleScaleRange = 0.05
        emitter.particleColor = .init(red: 0.83, green: 0.68, blue: 0.21, alpha: 1.0)  // Gold

        emitter.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(emitter)
    }
}

struct ParticleOverlay: View {
    var body: some View {
        SpriteView(scene: DustScene(), options: [.allowsTransparency])
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}
